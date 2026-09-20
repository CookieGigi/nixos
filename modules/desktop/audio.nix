{
  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber = {
      enable = true;
      extraConfig."51-momentum-tw4" = {
        "monitor.bluez.rules" = [
          {
            matches = [{"device.name" = "bluez_card.80_C3_BA_7C_C7_05";}];
            actions.update-props = {
              # Complete audio profile connections when the earbuds only partially reconnect.
              "bluez5.auto-connect" = ["a2dp_sink" "hfp_hf" "hsp_hs"];
            };
          }
        ];
      };
    };
  };
}
