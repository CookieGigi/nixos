{pkgs, ...}: {
  systemd.services.speaches-model-download = {
    description = "Download the Speaches STT and TTS models";
    wantedBy = ["multi-user.target"];
    requires = ["speaches.service"];
    after = ["speaches.service"];
    before = ["open-webui.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = "infinity";
      Restart = "on-failure";
      RestartSec = "10s";
    };
    script = ''
      set -euo pipefail

      until ${pkgs.podman}/bin/podman exec speaches curl -fsS http://127.0.0.1:8000/health >/dev/null; do
        sleep 2
      done

      ${pkgs.podman}/bin/podman exec speaches curl -fsS -X POST \
        http://127.0.0.1:8000/v1/models/Systran/faster-distil-whisper-large-v3
      ${pkgs.podman}/bin/podman exec speaches curl -fsS -X POST \
        http://127.0.0.1:8000/v1/models/speaches-ai/Kokoro-82M-v1.0-ONNX
    '';
  };

  environment.etc."containers/systemd/speaches.container".text = ''
    [Unit]
    Description=Speaches OpenAI-compatible STT and TTS API
    After=network-online.target caddy-network.service
    Requires=caddy-network.service
    RequiresMountsFor=/persist/speaches

    [Container]
    Image=ghcr.io/speaches-ai/speaches:latest-cuda
    ContainerName=speaches
    Network=caddy.network
    Volume=/persist/speaches/cache:/models
    Environment=HF_HUB_CACHE=/models
    Environment=XDG_CACHE_HOME=/models
    Environment=WHISPER__INFERENCE_DEVICE=cuda
    Environment=WHISPER__COMPUTE_TYPE=float16
    Environment=STT_MODEL_TTL=300
    Environment=TTS_MODEL_TTL=300
    Environment=ENABLE_UI=false
    Environment=LOG_LEVEL=info
    AddDevice=nvidia.com/gpu=all

    [Service]
    Restart=always
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
  '';
}
