{pkgs, ...}: let
  comfyuiEnv = pkgs.writeText "open-webui-comfyui.env" ''
    COMFYUI_WORKFLOW=${builtins.toJSON (import ./comfyui-workflow.nix)}
    COMFYUI_WORKFLOW_NODES=${builtins.toJSON [
      {
        type = "model";
        key = "ckpt_name";
        node_ids = ["4"];
      }
      {
        type = "prompt";
        key = "text";
        node_ids = ["6"];
      }
      {
        type = "width";
        key = "width";
        node_ids = ["5"];
      }
      {
        type = "height";
        key = "height";
        node_ids = ["5"];
      }
      {
        type = "n";
        key = "batch_size";
        node_ids = ["5"];
      }
      {
        type = "steps";
        key = "steps";
        node_ids = ["3"];
      }
      {
        type = "seed";
        key = "seed";
        node_ids = ["3"];
      }
    ]}
  '';
in {
  # Generate the signing key once. Keeping it outside the container data prevents
  # image updates from invalidating existing Open WebUI sessions.
  systemd.services.open-webui-secret = {
    description = "Create the Open WebUI signing key";
    wantedBy = ["multi-user.target"];
    after = ["local-fs.target"];
    before = ["open-webui.service"];
    serviceConfig.Type = "oneshot";
    script = ''
      set -euo pipefail
      key_file=/persist/open-webui/open-webui.env

      if [ ! -e "$key_file" ]; then
        umask 0077
        printf 'WEBUI_SECRET_KEY=%s\n' "$( ${pkgs.openssl}/bin/openssl rand -hex 32)" > "$key_file"
      fi
    '';
  };

  environment.etc."containers/systemd/open-webui.container".text = ''
    [Unit]
    Description=Open WebUI
    After=network-online.target caddy-network.service podman-llama.service speaches.service speaches-model-download.service searxng.service open-webui-secret.service
    Requires=caddy-network.service podman-llama.service speaches.service speaches-model-download.service searxng.service open-webui-secret.service
    RequiresMountsFor=/persist/open-webui

    [Container]
    Image=ghcr.io/open-webui/open-webui:main
    ContainerName=open-webui
    Network=caddy.network
    AddHost=auth.cookiegigi.com:192.168.1.49
    User=411
    Group=411
    Volume=/persist/open-webui/data:/app/backend/data
    EnvironmentFile=/persist/open-webui/open-webui.env
    EnvironmentFile=/run/secrets/open-webui-oidc-env
    EnvironmentFile=${comfyuiEnv}
    Environment=ENABLE_OLLAMA_API=False
    Environment=ENABLE_OPENAI_API=True
    Environment=OPENAI_API_BASE_URLS=http://llama:8080/v1
    Environment=OPENAI_API_KEYS=none
    Environment=AUDIO_STT_ENGINE=openai
    Environment=AUDIO_STT_OPENAI_API_BASE_URL=http://speaches:8000/v1
    Environment=AUDIO_STT_OPENAI_API_KEY=not-needed
    Environment=AUDIO_STT_MODEL=Systran/faster-distil-whisper-large-v3
    Environment=AUDIO_TTS_ENGINE=openai
    Environment=AUDIO_TTS_OPENAI_API_BASE_URL=http://speaches:8000/v1
    Environment=AUDIO_TTS_OPENAI_API_KEY=not-needed
    Environment=AUDIO_TTS_MODEL=speaches-ai/Kokoro-82M-v1.0-ONNX
    Environment=AUDIO_TTS_VOICE=af_heart
    Environment=ENABLE_IMAGE_GENERATION=True
    Environment=IMAGE_GENERATION_ENGINE=comfyui
    Environment=IMAGE_GENERATION_MODEL=sd_xl_base_1.0.safetensors
    Environment=IMAGE_SIZE=768x768
    Environment=IMAGE_STEPS=25
    Environment=COMFYUI_BASE_URL=http://192.168.1.14:8188
    Environment=ENABLE_PERSISTENT_CONFIG=False
    Environment=ENABLE_VERSION_UPDATE_CHECK=False
    Environment=RAG_EMBEDDING_MODEL_AUTO_UPDATE=False
    Environment=ENABLE_WEB_SEARCH=True
    Environment=WEB_SEARCH_ENGINE=searxng
    Environment=SEARXNG_QUERY_URL=http://searxng:8080/search?q=<query>
    Environment=WEBUI_AUTH=True
    Environment=WEBUI_URL=https://openwebui.cookiegigi.com
    Environment=ENABLE_OAUTH_SIGNUP=True
    Environment=OAUTH_MERGE_ACCOUNTS_BY_EMAIL=False
    Environment=OAUTH_CLIENT_ID=open-webui
    Environment=OPENID_PROVIDER_URL=https://auth.cookiegigi.com/.well-known/openid-configuration
    Environment=OAUTH_PROVIDER_NAME=Authelia
    Environment="OAUTH_SCOPES=openid email profile"
    Environment=OAUTH_CODE_CHALLENGE_METHOD=S256
    Environment=OPENID_REDIRECT_URI=https://openwebui.cookiegigi.com/oauth/oidc/callback
    Environment=CORS_ALLOW_ORIGIN=https://openwebui.cookiegigi.com
    Environment=TZ=Europe/Paris

    [Service]
    UMask=0077
    Restart=always
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
  '';
}
