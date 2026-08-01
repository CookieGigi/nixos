{
  config,
  lib,
  pkgs,
  ...
}: let
  # Model registry — single source of truth for all served models.
  # Edit ../common/llama/models.nix to add, remove, or update models.
  models = import ../common/llama/models.nix;

  # Newer llama.cpp with Gemma 4 vision fixes (b10092 vs old b9747).
  # nixpkgs lags behind; overrideAttrs pins a recent release tag.

  mkDownloadService = model: {
    name = "llama-cpp-model-download-${model.name}";
    value = {
      description = "Download ${model.name} GGUF model for llama.cpp";
      wantedBy = ["multi-user.target"];
      before = ["podman-llama.service"];
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

  # Keep download services active so models are fetched before the
  # Podman container starts. The Podman container reads from /media/ai
  # after llama-model-migrate copies them over.
  systemd.services =
    downloadServices
    // {
      # Ensure model downloads finish before the Podman container starts.
      podman-llama = {
        after = modelDownloadServices;
        requires = modelDownloadServices;
      };
    };

  # Auto-cleanup: remove GGUF files on disk that are no longer in the registry.
  # This keeps /var/lib/llama-cpp in sync with the declarative model list.
  system.activationScripts.cleanup-llama-models = lib.mkIf (models != []) ''
    allowed_list=$(mktemp)
    trap "rm -f $allowed_list" EXIT

    ${lib.concatMapStrings (m: ''
        echo ${lib.escapeShellArg m.file} >> "$allowed_list"
        ${lib.concatMapStrings (f: ''
          echo ${lib.escapeShellArg f} >> "$allowed_list"
        '') (m.extraFiles or [])}
      '')
      models}

    if [ -d /var/lib/llama-cpp/models ]; then
      for f in /var/lib/llama-cpp/models/*.gguf; do
        [ -e "$f" ] || continue
        basename=$(basename "$f")
        if ! grep -qxF "$basename" "$allowed_list"; then
          echo "[cleanup-llama-models] Removing orphaned model: $basename"
          rm -f "$f"
        fi
      done
    fi

    if [ -d /var/lib/llama-cpp/mmproj ]; then
      for f in /var/lib/llama-cpp/mmproj/*.gguf; do
        [ -e "$f" ] || continue
        basename=$(basename "$f")
        if ! grep -qxF "$basename" "$allowed_list"; then
          echo "[cleanup-llama-models] Removing orphaned mmproj: $basename"
          rm -f "$f"
        fi
      done
    fi
  '';

  users.users.llama-cpp = {
    isSystemUser = true;
    group = "llama-cpp";
    home = "/var/lib/llama-cpp";
    createHome = true;
  };

  users.groups.llama-cpp = {};
}
