{pkgs, ...}: let
  protonDriveBin = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "proton-drive-bin";
    version = "0.6.0";

    src = pkgs.fetchurl {
      url = "https://proton.me/download/drive/cli/${version}/linux-x64/proton-drive";
      sha256 = "04i0l3hcznd1vk6zaw56jsljcarxqrwmxl2wiz8y5xcwpxiqf9hc";
    };

    dontUnpack = true;

    nativeBuildInputs = [pkgs.patchelf];

    buildInputs = [pkgs.libsecret];

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      cp $src $out/bin/proton-drive
      chmod +wx $out/bin/proton-drive
      patchelf \
        --set-interpreter ${pkgs.glibc.out}/lib64/ld-linux-x86-64.so.2 \
        --set-rpath ${pkgs.lib.makeLibraryPath [pkgs.libsecret]} \
        $out/bin/proton-drive
      runHook postInstall
    '';
  };

  protonDriveEntrypoint = pkgs.writeShellScript "proton-drive-entrypoint" ''
    set -euo pipefail

    export GNUPGHOME=/root/.gnupg
    export GPG_TTY=$(${pkgs.coreutils}/bin/tty)
    export HOME=/root

    # Ensure GPG home exists with proper permissions
    ${pkgs.coreutils}/bin/mkdir -p "$GNUPGHOME"
    ${pkgs.coreutils}/bin/chmod 700 "$GNUPGHOME"

    # Overwrite agent config with container-local pinentry path
    ${pkgs.coreutils}/bin/echo "pinentry-program ${pkgs.pinentry-curses}/bin/pinentry-curses" > "$GNUPGHOME/gpg-agent.conf"

    # Remove any host-mounted agent socket so container starts its own agent
    ${pkgs.coreutils}/bin/rm -f "$GNUPGHOME/S.gpg-agent" "$GNUPGHOME/S.gpg-agent.extra" 2>/dev/null || true

    # Start gpg-agent daemon for this container
    ${pkgs.gnupg}/bin/gpg-agent --daemon --sh >/dev/null 2>&1 || true

    ${pkgs.coreutils}/bin/exec ${protonDriveBin}/bin/proton-drive "$@"
  '';

  protonDriveImage = pkgs.dockerTools.buildLayeredImage {
    name = "proton-drive";
    tag = "latest";
    contents = [
      protonDriveBin
      pkgs.pass
      pkgs.gnupg
      pkgs.pinentry-curses
      pkgs.coreutils
    ];
    config = {
      Entrypoint = [protonDriveEntrypoint];
      Env = ["PATH=${pkgs.lib.makeBinPath [pkgs.coreutils pkgs.gnupg pkgs.pass pkgs.pinentry-curses]}:/usr/bin:/bin"];
    };
  };

  protonDriveWrapper = pkgs.writeShellScriptBin "proton-drive" ''
    set -euo pipefail

    DATA_DIR="''${PROTON_DRIVE_DATA_DIR:-$HOME/.local/share/proton-drive-cli}"
    CACHE_DIR="''${PROTON_DRIVE_CACHE_DIR:-$HOME/.cache/proton-drive-cli}"
    STATE_DIR="''${PROTON_DRIVE_STATE_DIR:-$HOME/.local/state/proton-drive-cli}"
    PASS_DIR="''${PASSWORD_STORE_DIR:-$HOME/.password-store}"

    mkdir -p "$DATA_DIR" "$CACHE_DIR" "$STATE_DIR" "$PASS_DIR"

    # Ensure GPG keyring directory exists and configure pinentry
    if [ ! -d "$HOME/.gnupg" ]; then
      mkdir -p "$HOME/.gnupg"
      chmod 700 "$HOME/.gnupg"
    fi
    if [ ! -f "$HOME/.gnupg/gpg-agent.conf" ]; then
      echo "pinentry-program ${pkgs.pinentry-curses}/bin/pinentry-curses" > "$HOME/.gnupg/gpg-agent.conf"
    fi

    # Load image if not present
    if ! ${pkgs.podman}/bin/podman image exists localhost/proton-drive:latest 2>/dev/null; then
      echo "Loading proton-drive container image..."
      ${pkgs.podman}/bin/podman load -i ${protonDriveImage}
    fi

    exec ${pkgs.podman}/bin/podman run --rm -it \
      -v "$DATA_DIR:/root/.local/share/proton-drive-cli" \
      -v "$CACHE_DIR:/root/.cache/proton-drive-cli" \
      -v "$STATE_DIR:/root/.local/state/proton-drive-cli" \
      -v "$HOME/.gnupg:/root/.gnupg" \
      -v "$PASS_DIR:/root/.password-store" \
      -e "HOME=/root" \
      -e "PROTON_DRIVE_CACHE_DIR=/root/.cache/proton-drive-cli" \
      -e "PROTON_DRIVE_CREDENTIALS_STORE=pass" \
      -e "PASSWORD_STORE_DIR=/root/.password-store" \
      localhost/proton-drive:latest \
      "$@"
  '';

  passSetupScript = pkgs.writeShellScriptBin "proton-drive-init-pass" ''
    set -euo pipefail

    SOPS_KEY_FILE="/run/secrets/pass-gpg-key"

    if [ -f "$SOPS_KEY_FILE" ]; then
      echo "Found sops-managed GPG key at $SOPS_KEY_FILE"

      # Import into user's GPG keyring if not already present
      KEY_FP=$(${pkgs.gnupg}/bin/gpg --batch --with-colons --import-options show-only --import "$SOPS_KEY_FILE" 2>/dev/null | grep '^fpr' | head -1 | cut -d: -f10)

      if [ -z "$KEY_FP" ]; then
        echo "ERROR: Could not extract fingerprint from GPG key file."
        exit 1
      fi

      if ! ${pkgs.gnupg}/bin/gpg --batch --list-keys "$KEY_FP" >/dev/null 2>&1; then
        echo "Importing GPG key..."
        ${pkgs.gnupg}/bin/gpg --batch --import "$SOPS_KEY_FILE"
        echo "GPG key imported: $KEY_FP"
      else
        echo "GPG key already present: $KEY_FP"
      fi

      # Initialize pass store if not already done
      if [ ! -d "$HOME/.password-store" ]; then
        echo "Initializing password store..."
        ${pkgs.pass}/bin/pass init "$KEY_FP"
        echo "Password store initialized."
      else
        echo "Password store already exists at $HOME/.password-store"
      fi

      echo ""
      echo "Setup complete. You can now run:"
      echo "  proton-drive auth login"
    else
      echo "No sops-managed GPG key found at $SOPS_KEY_FILE."
      echo "You can still set up pass manually:"
      echo ""
      echo "  1. Generate a GPG key:"
      echo "     gpg --full-generate-key"
      echo "     (choose RSA, 4096 bits, no expiration)"
      echo ""
      echo "  2. Initialize pass:"
      echo "     pass init <KEY_ID>"
      echo ""
      echo "  3. Then run: proton-drive auth login"
      echo ""
      echo "Optional: manage the GPG key with sops-nix:"
      echo "  - Export key: gpg --export-secret-keys --armor <KEY_ID> > /tmp/key.asc"
      echo "  - Add to secrets/secrets.yaml under 'pass-gpg-key:'"
      echo "  - Enable the sops secret in proton-drive.nix"
    fi
  '';
in {
  # GPG agent with TUI pinentry for headless key generation
  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-curses;
  };

  environment.systemPackages = [
    protonDriveWrapper
    pkgs.pass
    pkgs.gnupg
    pkgs.pinentry-curses
    passSetupScript
  ];

  sops.secrets."pass-gpg-key" = {
    owner = "cookiegigi";
    mode = "0400";
  };

  system.activationScripts.proton-drive-pass-setup = ''
    GPG_KEY_FILE="/run/secrets/pass-gpg-key"
    if [ -f "$GPG_KEY_FILE" ]; then
      export HOME=/home/cookiegigi
      export GNUPGHOME=/home/cookiegigi/.gnupg

      mkdir -p "$GNUPGHOME"
      chmod 700 "$GNUPGHOME"

      KEY_FP=$(${pkgs.gnupg}/bin/gpg --batch --with-colons --import-options show-only --import "$GPG_KEY_FILE" 2>/dev/null | grep '^fpr' | head -1 | cut -d: -f10)
      if [ -n "$KEY_FP" ]; then
        if ! ${pkgs.gnupg}/bin/gpg --batch --list-keys "$KEY_FP" >/dev/null 2>&1; then
          ${pkgs.gnupg}/bin/gpg --batch --import "$GPG_KEY_FILE"
          echo "[proton-drive] Imported pass GPG key: $KEY_FP"
        fi

        if [ ! -d /home/cookiegigi/.password-store ]; then
          export PASS_DIR=/home/cookiegigi/.password-store
          ${pkgs.pass}/bin/pass init "$KEY_FP"
          echo "[proton-drive] Initialized password store with key: $KEY_FP"
        fi

        chown -R cookiegigi:users /home/cookiegigi/.gnupg /home/cookiegigi/.password-store
      fi
    fi
  '';

  # Pre-load the container image on boot
  systemd.services.proton-drive-image = {
    description = "Load proton-drive container image into podman";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.podman}/bin/podman load -i ${protonDriveImage}";
    };
    wantedBy = ["multi-user.target"];
    after = ["podman.service"];
  };
}
