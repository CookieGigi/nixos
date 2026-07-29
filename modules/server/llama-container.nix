{
  config,
  lib,
  pkgs,
  ...
}: let
  # Centralized model registry.
  # Edit ../common/llama/models.nix to add, remove, or update models.
  models = import ../common/llama/models.nix;

  modelStem = file: lib.removeSuffix ".gguf" file;

  mmprojFor = model:
    lib.findFirst (f: lib.hasPrefix "mmproj" f) null (model.extraFiles or []);

  # Container-specific preset: paths inside the container mount namespace.
  containerPresetFile =
    pkgs.writeText "llama-container-preset.ini"
    (lib.concatMapStrings (model: let
        mmproj = mmprojFor model;
      in ''
        [${modelStem model.file}]
        model = /models/${model.file}
        ctx-size = ${toString (model.ctxSize or 8192)}
        n-gpu-layers = 999
        ${lib.optionalString (mmproj != null) "mmproj = /mmproj/${mmproj}"}

      '')
      models);

  # One-shot manual download script: downloads all missing models sequentially.
  # Usage: sudo llama-model-download-all
  downloadAllScript = pkgs.writeShellScriptBin "llama-model-download-all" ''
    set -euo pipefail
    export HF_TOKEN=$(cat ${config.sops.secrets."hf-token".path})
    mkdir -p /media/llama-models /media/llama-mmproj

    ${lib.concatMapStrings (model: ''
        # Main model file
        if [ -f "/media/llama-models/${model.file}" ]; then
          echo "[skip] ${model.name}: ${model.file} already exists"
        else
          echo "[download] ${model.name}: ${model.file}..."
          ${pkgs.python3Packages.huggingface-hub}/bin/hf download \
            ${model.repo} \
            ${model.file} \
            --local-dir /media/llama-models
          echo "[done] ${model.name}: ${model.file}"
        fi

        # Extra files (e.g. mmproj)
        ${lib.concatMapStrings (file: ''
          if [ -f "/media/llama-mmproj/${file}" ]; then
            echo "[skip] ${model.name}: ${file} already exists"
          else
            echo "[download] ${model.name}: ${file}..."
            ${pkgs.python3Packages.huggingface-hub}/bin/hf download \
              ${model.repo} \
              ${file} \
              --local-dir /media/llama-mmproj
            echo "[done] ${model.name}: ${file}"
          fi
        '') (model.extraFiles or [])}
      '')
      models}

    echo "All model downloads complete."
  '';
in {
  # huggingface-cli for downloading models and inject HF_TOKEN.
  environment = {
    systemPackages = [
      pkgs.python3Packages.huggingface-hub
      pkgs.opencode
      downloadAllScript
    ];

    shellInit = ''
      export HF_TOKEN=$(cat ${config.sops.secrets."hf-token".path})
    '';

    # Make OpenCode on the server automatically use the local llama.cpp endpoint.
    variables.LOCAL_ENDPOINT = "http://localhost:8080/v1";
  };

  # llama.cpp container with CUDA support for GPU inference.
  # Models live on /media (HDD) to save NVMe space.
  # Container images are cached under /var/lib/containers on NVMe for fast I/O.
  virtualisation.oci-containers.containers.llama = {
    image = "ghcr.io/ggml-org/llama.cpp:server-cuda";
    autoStart = true;
    ports = ["8080:8080"];
    volumes = [
      "/media/llama-models:/models:ro"
      "/media/llama-mmproj:/mmproj:ro"
      "${containerPresetFile}:/models/preset.ini:ro"
    ];
    cmd = [
      "--models-preset"
      "/models/preset.ini"
      "--host"
      "0.0.0.0"
      "--port"
      "8080"
      "--parallel"
      "1"
      "--ubatch-size"
      "4096"
      "--batch-size"
      "4096"
      "--jinja"
    ];
    extraOptions = ["--device=nvidia.com/gpu=all"];
    log-driver = "journald";
  };

  # One-shot migration: copy existing models from old /var/lib/llama-cpp to /media.
  systemd.services = {
    llama-model-migrate = {
      description = "Migrate llama models to /media HDD storage";
      wantedBy = ["multi-user.target"];
      before = ["podman-llama.service"];
      after = ["local-fs.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        set -euo pipefail
        mkdir -p /media/llama-models /media/llama-mmproj

        # Migrate main models
        if [ -d /var/lib/llama-cpp/models ] && [ "$(ls -A /var/lib/llama-cpp/models 2>/dev/null)" ]; then
          echo "Migrating models from /var/lib/llama-cpp/models..."
          for f in /var/lib/llama-cpp/models/*.gguf; do
            [ -e "$f" ] || continue
            basename=$(basename "$f")
            if [ ! -f "/media/llama-models/$basename" ]; then
              echo "Copying $basename to /media/llama-models..."
              cp -a "$f" "/media/llama-models/$basename"
            fi
          done
        fi

        # Migrate mmproj files
        if [ -d /var/lib/llama-cpp/mmproj ] && [ "$(ls -A /var/lib/llama-cpp/mmproj 2>/dev/null)" ]; then
          echo "Migrating mmproj files from /var/lib/llama-cpp/mmproj..."
          for f in /var/lib/llama-cpp/mmproj/*.gguf; do
            [ -e "$f" ] || continue
            basename=$(basename "$f")
            if [ ! -f "/media/llama-mmproj/$basename" ]; then
              echo "Copying $basename to /media/llama-mmproj..."
              cp -a "$f" "/media/llama-mmproj/$basename"
            fi
          done
        fi
      '';
    };

    podman-llama = {
      after = ["llama-model-migrate.service"];
      requires = ["llama-model-migrate.service"];
      environment = {
        TMPDIR = "/persist/tmp";
      };
    };
  };

  # Ensure /persist/tmp exists so Podman can use it for image pulls
  # (the tmpfs root is too small for multi-GB CUDA container images).
  systemd.tmpfiles.rules = [
    "d /persist/tmp 0755 root root -"
  ];

  # Open firewall for llama.cpp HTTP server.
  networking.firewall.allowedTCPPorts = [8080];

  # Auto-cleanup: remove GGUF files on /media that are no longer in the registry.
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

    if [ -d /media/llama-models ]; then
      for f in /media/llama-models/*.gguf; do
        [ -e "$f" ] || continue
        basename=$(basename "$f")
        if ! grep -qxF "$basename" "$allowed_list"; then
          echo "[cleanup-llama-models] Removing orphaned model: $basename"
          rm -f "$f"
        fi
      done
    fi

    if [ -d /media/llama-mmproj ]; then
      for f in /media/llama-mmproj/*.gguf; do
        [ -e "$f" ] || continue
        basename=$(basename "$f")
        if ! grep -qxF "$basename" "$allowed_list"; then
          echo "[cleanup-llama-models] Removing orphaned mmproj: $basename"
          rm -f "$f"
        fi
      done
    fi
  '';
}
