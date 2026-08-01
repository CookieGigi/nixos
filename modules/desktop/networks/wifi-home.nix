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
      # Use systemd-resolved DNS exclusively; ignore DHCP-provided DNS.
      ipv4 = {
        ignore-auto-dns = true;
      };
    };
  };
}
