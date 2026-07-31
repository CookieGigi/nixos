{pkgs, ...}: {
  users = {
    groups = {
      ai = {
        gid = 202;
        members = ["cookiegigi" "llama"];
      };

      llama = {};
    };

    users = {
      llama = {
        isSystemUser = true;
        uid = 303;
        group = "llama";
        extraGroups = ["ai"];
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /media/ai                   0750 root ai -"
    "d /media/ai/llama-models      2770 root ai -"
    "d /media/ai/llama-mmproj      2770 root ai -"
  ];

  system.activationScripts.llama-ownership-migration = ''
    echo "[llama] Migrating ownership for llama model directories..."

    if [ -d /media/ai/llama-models/llama-models ]; then
      echo "[llama] Fixing nested llama model paths..."
      for f in /media/ai/llama-models/llama-models/*.gguf; do
        [ -e "$f" ] || continue
        basename=$(basename "$f")
        if [ ! -f "/media/ai/llama-models/$basename" ]; then
          ${pkgs.coreutils}/bin/mv "$f" "/media/ai/llama-models/$basename"
          echo "[llama] Moved $basename -> /media/ai/llama-models/"
        fi
      done
    fi

    if [ -d /media/ai/llama-models ]; then
      ${pkgs.coreutils}/bin/chown -R root:ai /media/ai/llama-models
      ${pkgs.coreutils}/bin/chmod 2770 /media/ai/llama-models
      echo "[llama] /media/ai/llama-models -> root:ai (2770)"
    fi

    if [ -d /media/ai/llama-mmproj ]; then
      ${pkgs.coreutils}/bin/chown -R root:ai /media/ai/llama-mmproj
      ${pkgs.coreutils}/bin/chmod 2770 /media/ai/llama-mmproj
      echo "[llama] /media/ai/llama-mmproj -> root:ai (2770)"
    fi

    if [ -d /media/ai ]; then
      ${pkgs.coreutils}/bin/chown root:ai /media/ai
      ${pkgs.coreutils}/bin/chmod 0750 /media/ai
      echo "[llama] /media/ai -> root:ai (0750)"
    fi
  '';
}
