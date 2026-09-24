{pkgs, ...}: let
  model = "sd_xl_base_1.0.safetensors";
in {
  hardware.nvidia-container-toolkit.enable = true;
  virtualisation.podman.enable = true;

  systemd.tmpfiles.rules = [
    "d /persist/comfyui                    0700 root root -"
    "d /persist/comfyui/models             0700 root root -"
    "d /persist/comfyui/models/checkpoints 0700 root root -"
    "d /persist/comfyui/input              0700 root root -"
    "d /persist/comfyui/output             0700 root root -"
    "d /persist/comfyui/user               0700 root root -"
  ];

  systemd.services.comfyui-model-download = {
    description = "Download the SDXL image model";
    wantedBy = ["multi-user.target"];
    wants = ["network-online.target"];
    after = ["network-online.target" "systemd-tmpfiles-setup.service"];
    before = ["comfyui.service"];
    unitConfig.RequiresMountsFor = "/persist/comfyui";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = "infinity";
    };
    script = ''
      set -euo pipefail
      if [ ! -s /persist/comfyui/models/checkpoints/${model} ]; then
        ${pkgs.python3Packages.huggingface-hub}/bin/hf download \
          stabilityai/stable-diffusion-xl-base-1.0 ${model} \
          --local-dir /persist/comfyui/models/checkpoints
      fi
    '';
  };

  environment.etc."containers/systemd/comfyui.container".text = ''
    [Unit]
    Description=GPU ComfyUI image generation
    After=network-online.target comfyui-model-download.service
    Requires=comfyui-model-download.service
    RequiresMountsFor=/persist/comfyui

    [Container]
    Image=docker.io/yanwk/comfyui-boot:cu130-slim-v2
    ContainerName=comfyui
    Network=host
    AddDevice=nvidia.com/gpu=all
    Volume=/persist/comfyui/models:/root/ComfyUI/models
    Volume=/persist/comfyui/input:/root/ComfyUI/input
    Volume=/persist/comfyui/output:/root/ComfyUI/output
    Volume=/persist/comfyui/user:/root/ComfyUI/user
    Environment="CLI_ARGS=--listen 0.0.0.0"

    [Service]
    Restart=always
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
  '';

  # Only the server may call the unauthenticated ComfyUI API directly.
  networking.firewall.extraCommands = ''
    iptables -w -A nixos-fw -s 192.168.1.49 -p tcp --dport 8188 -j nixos-fw-accept
  '';
}
