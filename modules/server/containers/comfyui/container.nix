{pkgs, ...}: let
  model = "v1-5-pruned-emaonly.safetensors";
  modelPaths = pkgs.writeText "comfyui-model-paths.yaml" ''
    image-models:
      base_path: /models
      checkpoints: checkpoints
  '';
  startup = pkgs.writeShellScript "comfyui-start" ''
    set -euo pipefail
    if [ ! -f /root/ComfyUI/main.py ]; then
      mkdir -p /root/ComfyUI
      # The CPU image copies as root with --archive; copy as the service user instead.
      cp -R /default-comfyui-bundle/ComfyUI/. /root/ComfyUI/
    fi
    exec python3 /root/ComfyUI/main.py --cpu --listen 0.0.0.0 --port 8188
  '';
in {
  systemd.services.comfyui-model-download = {
    description = "Download the Stable Diffusion 1.5 CPU image model";
    wantedBy = ["multi-user.target"];
    wants = ["network-online.target"];
    after = ["network-online.target"];
    before = ["comfyui.service"];
    unitConfig.RequiresMountsFor = "/media/ai/comfyui-checkpoints";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = "infinity";
    };
    script = ''
      set -euo pipefail
      if [ ! -s /media/ai/comfyui-checkpoints/${model} ]; then
        ${pkgs.python3Packages.huggingface-hub}/bin/hf download \
          stable-diffusion-v1-5/stable-diffusion-v1-5 ${model} \
          --local-dir /media/ai/comfyui-checkpoints
      fi
    '';
  };

  environment.etc."containers/systemd/comfyui.container".text = ''
    [Unit]
    Description=CPU-only ComfyUI image generation and editing
    After=network-online.target caddy-network.service comfyui-model-download.service
    Requires=caddy-network.service comfyui-model-download.service
    RequiresMountsFor=/persist/comfyui /media/ai/comfyui-checkpoints

    [Container]
    Image=docker.io/yanwk/comfyui-boot:cpu
    ContainerName=comfyui
    Network=caddy.network
    User=413
    Group=413
    GroupAdd=202
    Volume=/persist/comfyui:/root
    Volume=/media/ai/comfyui-checkpoints:/models/checkpoints:ro
    Volume=${modelPaths}:/root/ComfyUI/extra_model_paths.yaml:ro
    Volume=${startup}:/run/comfyui-start:ro
    Exec=/bin/bash /run/comfyui-start
    Environment=HOME=/root
    Environment=PYTHONPYCACHEPREFIX=/root/.cache/pycache

    [Service]
    MemoryMax=6G
    CPUQuota=400%
    Restart=always
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
  '';
}
