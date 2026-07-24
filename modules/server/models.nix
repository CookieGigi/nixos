# Centralized LLM model registry for the server.
# Edit this file to add, remove, or update models.
# Both llama.cpp (download + serving) and OpenCode (provider config)
# are generated from this single source of truth.
[
  {
    name = "qwen";
    repo = "brunopio/Qwen3.5-14B-A3B-Claude-4.6-Opus-Reasoning-Distilled-reap-Q4_K_M-GGUF";
    file = "qwen3.5-14b-a3b-claude-4.6-opus-reasoning-distilled-reap-q4_k_m.gguf";
    displayName = "Qwen 3.5 14B A3B (local)";
    family = "qwen";
    vision = false;
    toolCall = true;
    reasoning = true;
  }
  {
    name = "qwen-3.5-9b";
    repo = "bartowski/Qwen_Qwen3.5-9B-GGUF";
    file = "Qwen_Qwen3.5-9B-Q4_K_M.gguf";
    extraFiles = ["mmproj-Qwen_Qwen3.5-9B-f16.gguf"];
    displayName = "Qwen 3.5 9B (local)";
    family = "qwen";
    vision = true;
    toolCall = true;
    reasoning = true;
  }
  {
    name = "gemma-4-12b";
    repo = "bartowski/gemma-4-12B-it-GGUF";
    file = "gemma-4-12B-it-Q4_K_M.gguf";
    extraFiles = ["mmproj-gemma-4-12B-it-f16.gguf"];
    displayName = "Gemma 4 12B IT (local)";
    family = "gemma";
    vision = true;
    toolCall = true;
    reasoning = true;
  }
  {
    name = "phi-4-mini-reasoning";
    repo = "bartowski/microsoft_Phi-4-mini-reasoning-GGUF";
    file = "microsoft_Phi-4-mini-reasoning-bf16.gguf";
    displayName = "Phi-4 Mini Reasoning bf16 (local)";
    family = "phi";
    vision = false;
    toolCall = true;
    reasoning = true;
  }
  {
    name = "mistral-nemo";
    repo = "bartowski/Mistral-Nemo-Instruct-2407-GGUF";
    file = "Mistral-Nemo-Instruct-2407-Q4_K_M.gguf";
    displayName = "Mistral Nemo Instruct 2407 (local)";
    family = "mistral";
    vision = false;
    toolCall = true;
    reasoning = true;
  }
  {
    name = "llama-3.1-heretic";
    repo = "bartowski/p-e-w_Llama-3.1-8B-Instruct-heretic-GGUF";
    file = "p-e-w_Llama-3.1-8B-Instruct-heretic-Q4_K_M.gguf";
    displayName = "Llama 3.1 8B Heretic (local)";
    family = "llama";
    vision = false;
    toolCall = true;
    reasoning = true;
  }
  {
    name = "qwen3-8b";
    repo = "bartowski/Qwen_Qwen3-8B-GGUF";
    file = "Qwen_Qwen3-8B-Q4_K_M.gguf";
    displayName = "Qwen3 8B (local)";
    family = "qwen";
    vision = false;
    toolCall = true;
    reasoning = true;
  }
  {
    name = "phi-3.5-mini";
    repo = "bartowski/Phi-3.5-mini-instruct-GGUF";
    file = "Phi-3.5-mini-instruct-Q4_K_M.gguf";
    displayName = "Phi-3.5 Mini Instruct (local)";
    family = "phi";
    vision = false;
    toolCall = true;
    reasoning = true;
  }
  {
    name = "qwen2.5-vl-7b";
    repo = "bartowski/Qwen_Qwen2.5-VL-7B-Instruct-GGUF";
    file = "Qwen_Qwen2.5-VL-7B-Instruct-Q4_K_M.gguf";
    extraFiles = ["mmproj-Qwen_Qwen2.5-VL-7B-Instruct-f16.gguf"];
    displayName = "Qwen2.5 VL 7B Instruct (local)";
    family = "qwen";
    vision = true;
    toolCall = true;
    reasoning = true;
  }
]
