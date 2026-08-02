{config, ...}: {
  networking.networkmanager.ensureProfiles = {
    profiles."Cencurut" = {
      connection = {
        id = "Cencurut";
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
