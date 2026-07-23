{
  config,
  lib,
  pkgs,
  ...
}: let
  # Models to download and serve. Each entry:
  #   name       - friendly identifier used for service names
  #   repo       - HuggingFace repo ID containing the GGUF
  #   file       - main GGUF filename to download
  #   extraFiles - optional additional files (e.g. mmproj) downloaded to mmproj/
  models = [
    {
      name = "qwen";
      repo = "brunopio/Qwen3.5-14B-A3B-Claude-4.6-Opus-Reasoning-Distilled-reap-Q4_K_M-GGUF";
      file = "qwen3.5-14b-a3b-claude-4.6-opus-reasoning-distilled-reap-q4_k_m.gguf";
    }
    {
      name = "gemma-4-12b";
      repo = "bartowski/gemma-4-12B-it-GGUF";
      file = "gemma-4-12B-it-Q4_K_M.gguf";
      extraFiles = ["mmproj-gemma-4-12B-it-f16.gguf"];
    }
  ];

  modelStem = file: lib.removeSuffix ".gguf" file;

  mmprojFor = model:
    lib.findFirst (f: lib.hasPrefix "mmproj" f) null (model.extraFiles or []);

  mkDownloadService = model: {
    name = "llama-cpp-model-download-${model.name}";
    value = {
      description = "Download ${model.name} GGUF model for llama.cpp";
      wantedBy = ["multi-user.target"];
      before = ["llama-cpp.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "download-${model.name}" ''
          set -euo pipefail
          export HF_TOKEN=$(cat ${config.sops.secrets."hf-token".path})
          mkdir -p /var/lib/llama-cpp/models /var/lib/llama-cpp/mmproj
          chown llama-cpp:llama-cpp /var/lib/llama-cpp/models /var/lib/llama-cpp/mmproj || true

          # Main model file
          if [ ! -f "/var/lib/llama-cpp/models/${model.file}" ]; then
            echo "Downloading model ${model.name} (${model.file})..."
            ${pkgs.python3Packages.huggingface-hub}/bin/hf download \
              ${model.repo} \
              ${model.file} \
              --local-dir /var/lib/llama-cpp/models
            chown llama-cpp:llama-cpp "/var/lib/llama-cpp/models/${model.file}"
            echo "Model ${model.name} download complete."
          else
            echo "Model ${model.name} already exists."
          fi

          # Extra files (e.g. mmproj)
          ${lib.concatMapStrings (file: ''
            if [ ! -f "/var/lib/llama-cpp/mmproj/${file}" ]; then
              echo "Downloading ${file} for model ${model.name}..."
              ${pkgs.python3Packages.huggingface-hub}/bin/hf download \
                ${model.repo} \
                ${file} \
                --local-dir /var/lib/llama-cpp/mmproj
              chown llama-cpp:llama-cpp "/var/lib/llama-cpp/mmproj/${file}"
              echo "Downloaded ${file}."
            else
              echo "${file} already exists."
            fi
          '') (model.extraFiles or [])}
        '';
      };
    };
  };

  downloadServices = lib.listToAttrs (map mkDownloadService models);

  modelDownloadServices = map (model: "llama-cpp-model-download-${model.name}.service") models;

  # Router preset INI: defines every served model and its specific flags
  # (e.g. mmproj for vision). Auto-discovery via --models-dir is disabled
  # so stray files (like mmproj GGUFs) are not exposed as broken models.
  modelsPresetFile =
    pkgs.writeText "llama-cpp-models-preset.ini"
    (lib.concatMapStrings (model: let
        mmproj = mmprojFor model;
      in ''
        [${modelStem model.file}]
        model = /var/lib/llama-cpp/models/${model.file}
        ctx-size = 8192
        n-gpu-layers = 999
        ${lib.optionalString (mmproj != null) "mmproj = /var/lib/llama-cpp/mmproj/${mmproj}"}

      '')
      models);
in {
  # Provide huggingface-cli for downloading models and inject HF_TOKEN.
  environment = {
    systemPackages = [
      pkgs.python3Packages.huggingface-hub
      pkgs.opencode
    ];

    # Set HF_TOKEN for both interactive and non-interactive shells.
    shellInit = ''
      export HF_TOKEN=$(cat ${config.sops.secrets."hf-token".path})
    '';

    # Make OpenCode on the server automatically use the local llama.cpp endpoint.
    variables.LOCAL_ENDPOINT = "http://localhost:8080/v1";

    persistence."/persist".directories = [
      "/var/lib/llama-cpp"
      "/var/cache/llama-cpp"
    ];
  };

  # Enable llama.cpp HTTP server with CUDA support for GPU inference.
  services.llama-cpp = {
    enable = true;

    # Use CUDA-enabled build for NVIDIA GPU acceleration.
    package = pkgs.llama-cpp.override {cudaSupport = true;};

    # Router mode using an explicit preset file instead of --models-dir.
    # This prevents mmproj files from being scanned as broken standalone models
    # and allows per-model flags (like mmproj) to be applied correctly.
    settings = {
      host = "0.0.0.0";
      port = 8080;
      "models-preset" = "${modelsPresetFile}";
      "n-gpu-layers" = 999;
      "ctx-size" = 8192;
    };

    openFirewall = true;
  };

  systemd.services =
    downloadServices
    // {
      # llama.cpp uses DynamicUser by default, but with impermanence (ephemeral root)
      # we need a static user so /var/lib/llama-cpp survives reboots.
      llama-cpp = {
        after = modelDownloadServices;
        requires = modelDownloadServices;
        serviceConfig = {
          DynamicUser = lib.mkForce false;
          User = lib.mkForce "llama-cpp";
          Group = lib.mkForce "llama-cpp";
        };
      };
    };

  users.users.llama-cpp = {
    isSystemUser = true;
    group = "llama-cpp";
    home = "/var/lib/llama-cpp";
    createHome = true;
  };

  users.groups.llama-cpp = {};
}
