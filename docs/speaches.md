# Speaches

Speaches provides the server's internal, OpenAI-compatible speech API. It uses
CUDA for both transcription and synthesis and persists downloaded models in
`/persist/speaches/cache`.

The API is deliberately private: only containers attached to `caddy.network`
can reach it at `http://speaches:8000/v1`. It is not exposed through Caddy or
the firewall.

| Capability | Model | Endpoint |
| --- | --- | --- |
| STT | `Systran/faster-distil-whisper-large-v3` | `POST /audio/transcriptions` |
| TTS | `speaches-ai/Kokoro-82M-v1.0-ONNX` | `POST /audio/speech` |

Open WebUI is configured to use this API automatically. Other internal clients
should use the base URL above with any non-empty API key, unless API key
authentication is explicitly enabled in the Speaches container.
