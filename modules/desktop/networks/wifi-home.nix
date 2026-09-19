{config, ...}: {
  networking.networkmanager.ensureProfiles = {
    profiles."Cencurut" = {
      connection = {
        id = "Cencurut";
        # Reuse the saved connection's identity instead of creating a duplicate.
        uuid = "2f1fecda-8f6f-4e37-8ba1-5262424a5eb8";
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
        # Secret requests use D-Bus names, not the keyfile aliases above.
        matchSetting = "802-11-wireless-security";
        matchType = "802-11-wireless";
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
