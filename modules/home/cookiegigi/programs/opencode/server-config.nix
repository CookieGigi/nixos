{pkgs, ...}: let
  base = import ./config.nix {inherit pkgs;};

  # Centralized model registry shared with llama-cpp.nix
  models = import ../../../../server/models.nix;

  modelStem = file: pkgs.lib.removeSuffix ".gguf" file;

  mkOpencodeModel = model: {
    inherit (model) name;
    value = {
      id = modelStem model.file;
      name = model.displayName;
      inherit (model) family reasoning;
      status = "active";
      temperature = true;
      tool_call = model.toolCall;
      limit = {
        context = model.ctxSize or 8192;
        output = 4096;
      };
      cost = {
        input = 0;
        output = 0;
      };
      modalities = {
        input =
          if model.vision
          then ["text" "image"]
          else ["text"];
        output = ["text"];
      };
    };
  };
in {
  config =
    base.config
    // {
      model = "local/qwen";
      small_model = "local/qwen";

      provider = {
        local = {
          id = "local";
          name = "Local llama.cpp";
          npm = "@ai-sdk/openai-compatible";
          options = {
            baseURL = "http://localhost:8080/v1";
            apiKey = "dummy";
          };
          models = pkgs.lib.listToAttrs (map mkOpencodeModel models);
        };
      };
    };
}
