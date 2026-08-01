{...}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./disko.nix
    ./ssh.nix
    ./tpm-media.nix
    ../../modules/server
    ../../modules/home/default-server.nix
  ];

  networking.hostName = "server";
  networking.domain = "cookiegigi.com";

  # ---------------------------------------------------------------------------
  # Reverse proxy: Caddy + Let's Encrypt
  # ---------------------------------------------------------------------------
  # All backend services are bound to localhost only. Caddy terminates TLS
  # and routes subdomains:
  #   photos.cookiegigi.com  -> Immich   (localhost:2283)
  #   ai.cookiegigi.com      -> llama.cpp (localhost:8080)
  #   opencode.cookiegigi.com -> OpenCode serve (localhost:4096)
  #
  # REQUIREMENTS before switching on:
  # 1. Set acmeEmail to a real address (Let's Encrypt needs it).
  # 2. Forward ports 80 and 443 on your router to this server.
  # 3. Ensure DNS A/AAAA records for the subdomains point here.
  # ---------------------------------------------------------------------------
  services.reverseProxy = {
    enable = true;
    domain = "cookiegigi.com";
    acmeEmail = "CHANGEME@example.com"; # <-- CHANGE THIS
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
