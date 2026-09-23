{pkgs, ...}: {
  users.groups.comfyui.gid = 413;
  users.users.comfyui = {
    isSystemUser = true;
    uid = 413;
    group = "comfyui";
    extraGroups = ["ai"];
  };

  systemd.tmpfiles.rules = [
    "d /persist/comfyui                 0700 comfyui comfyui -"
    "d /media/ai/comfyui-checkpoints   2770 root ai -"
  ];

  system.activationScripts.comfyui-ownership-migration = ''
    if [ -d /persist/comfyui ]; then
      ${pkgs.coreutils}/bin/chown -R comfyui:comfyui /persist/comfyui
    fi
  '';
}
