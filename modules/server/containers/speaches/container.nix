{
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
    Environment=PRELOAD_MODELS=[\"Systran/faster-distil-whisper-large-v3\",\"speaches-ai/Kokoro-82M-v1.0-ONNX\"]
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
