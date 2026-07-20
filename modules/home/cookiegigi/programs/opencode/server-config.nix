{pkgs, ...}: let
  base = import ./config.nix {inherit pkgs;};
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
          models = {
            qwen = {
              id = "qwen";
              name = "Qwen 3.5 14B A3B (local)";
              family = "qwen";
              status = "active";
              temperature = true;
              reasoning = true;
              tool_call = true;
              limit = {
                context = 8192;
                output = 4096;
              };
              cost = {
                input = 0;
                output = 0;
              };
              modalities = {
                input = ["text"];
                output = ["text"];
              };
            };
          };
        };
      };
    };
}
