{
  config,
  lib,
  pkgs,
  ...
}: let
  # Models to download and serve. Each entry:
  #   name  - friendly identifier used for service names
  #   repo  - HuggingFace repo ID containing the GGUF
  #   file  - GGUF filename to download
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
    }
  ];

  modelPath = model: "/var/lib/llama-cpp/models/${model.file}";

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
          mkdir -p /var/lib/llama-cpp/models
          chown llama-cpp:llama-cpp /var/lib/llama-cpp/models || true
          if [ ! -f "${modelPath model}" ]; then
            echo "Downloading model ${model.name} (${model.file})..."
            ${pkgs.python3Packages.huggingface-hub}/bin/huggingface-cli download \
              ${model.repo} \
              ${model.file} \
              --local-dir /var/lib/llama-cpp/models \
              --local-dir-use-symlinks False
            chown llama-cpp:llama-cpp "${modelPath model}"
            echo "Model ${model.name} download complete."
          else
            echo "Model ${model.name} already exists at ${modelPath model}."
          fi
        '';
      };
    };
  };

  downloadServices = lib.listToAttrs (map mkDownloadService models);

  modelDownloadServices = map (model: "llama-cpp-model-download-${model.name}.service") models;
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

    # Listen on all interfaces so remote clients can reach it.
    settings = {
      host = "0.0.0.0";
      port = 8080;

      # Router mode: all .gguf files in this dir are exposed via the API.
      # Do NOT set a hardcoded default `model` here so the server stays in
      # multi-model mode — any model in the directory can be selected at
      # runtime via the `model` parameter in API requests.
      "models-dir" = "/var/lib/llama-cpp/models";

      # Offload as many layers as possible to the GPU.
      "n-gpu-layers" = 999;

      # Context size.
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
