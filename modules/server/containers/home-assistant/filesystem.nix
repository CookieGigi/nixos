{pkgs, ...}: {
  systemd.tmpfiles.rules = [
    "d /persist/home-assistant/config 0700 home-assistant home-assistant -"
    "f /persist/home-assistant/config/automations.yaml 0600 home-assistant home-assistant - []"
    "f /persist/home-assistant/config/scripts.yaml 0600 home-assistant home-assistant - {}"
    "f /persist/home-assistant/config/scenes.yaml 0600 home-assistant home-assistant - []"
  ];

  system.activationScripts.home-assistant-ownership-migration = ''
    if [ -d /persist/home-assistant/config ]; then
      ${pkgs.coreutils}/bin/chown -R home-assistant:home-assistant /persist/home-assistant/config
    fi
  '';
}
