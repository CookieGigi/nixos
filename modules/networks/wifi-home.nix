{config, ...}: {
  networking.networkmanager.ensureProfiles = {
    environmentFiles = [config.sops.secrets."wifi-home-env".path];
    profiles."Home" = {
      connection = {
        id = "Home";
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
    };
  };
}
