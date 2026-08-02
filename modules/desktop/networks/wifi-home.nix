{config, ...}: {
  networking.networkmanager.ensureProfiles = {
    environmentFiles = [config.sops.secrets."wifi-home-env".path];
    profiles."Cencurut" = {
      connection = {
        id = "Cencurut";
        type = "wifi";
        autoconnect = true;
      };
      wifi = {
        mode = "infrastructure";
        ssid = "@WIFI_HOME_SSID@";
      };
      wifi-security = {
        key-mgmt = "wpa-psk";
        psk = "@WIFI_HOME_PASSWORD@";
      };
      ipv4 = {
      };
    };
  };
}
