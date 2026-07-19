{
  config,
  lib,
  pkgs,
  ...
}: let
  modelRepo = "brunopio/Qwen3.5-14B-A3B-Claude-4.6-Opus-Reasoning-Distilled-reap-Q4_K_M-GGUF";
  modelFile = "qwen3.5-14b-a3b-claude-4.6-opus-reasoning-distilled-reap-q4_k_m.gguf";
  modelPath = "/var/lib/llama-cpp/models/${modelFile}";
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

      # Default model loaded on startup for instant inference.
      model = modelPath;

      # Router mode: all .gguf files in this dir are exposed via the API.
      "models-dir" = "/var/lib/llama-cpp/models";

      # Offload as many layers as possible to the GPU.
      "n-gpu-layers" = 999;

      # Context size.
      "ctx-size" = 8192;
    };

    openFirewall = true;
  };

  systemd.services = {
    # Download the specific GGUF model before llama.cpp starts.
    llama-cpp-model-download = {
      description = "Download GGUF model for llama.cpp";
      wantedBy = ["multi-user.target"];
      before = ["llama-cpp.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "download-model" ''
          set -euo pipefail
          export HF_TOKEN=$(cat ${config.sops.secrets."hf-token".path})
          mkdir -p /var/lib/llama-cpp/models
          chown llama-cpp:llama-cpp /var/lib/llama-cpp/models || true
          if [ ! -f "${modelPath}" ]; then
            echo "Downloading model ${modelFile} (~8.7 GB)..."
            ${pkgs.python3Packages.huggingface-hub}/bin/huggingface-cli download \
              ${modelRepo} \
              ${modelFile} \
              --local-dir /var/lib/llama-cpp/models \
              --local-dir-use-symlinks False
            chown llama-cpp:llama-cpp "${modelPath}"
            echo "Model download complete."
          else
            echo "Model already exists at ${modelPath}."
          fi
        '';
      };
    };

    # llama.cpp uses DynamicUser by default, but with impermanence (ephemeral root)
    # we need a static user so /var/lib/llama-cpp survives reboots.
    llama-cpp = {
      after = ["llama-cpp-model-download.service"];
      requires = ["llama-cpp-model-download.service"];
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
