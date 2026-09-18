{config, ...}: {
  networking.networkmanager.ensureProfiles = {
    profiles."Cencurut" = {
      connection = {
        id = "Cencurut";
        # Reuse the saved connection's identity instead of creating a duplicate.
        uuid = "fbdb310d-f0a5-4134-a036-32cc5c7dd237";
        type = "wifi";
        autoconnect = true;
        permissions = "";
      };
      wifi = {
        mode = "infrastructure";
        ssid = "Cencurut";
      };
      wifi-security = {
        key-mgmt = "wpa-psk";
        # Supplied by the system nm-file-secret-agent, not a desktop keyring.
        psk-flags = "1";
      };
      ipv4 = {method = "auto";};
    };

    secrets.entries = [
      {
        file = config.sops.secrets."wifi-home-password".path;
        key = "psk";
        matchId = "Cencurut";
        matchSetting = "wifi-security";
        matchType = "wifi";
      }
    ];
  };

  sops = {
    secrets = {
      "wifi-home-password" = {
      };
    };
  };
}
