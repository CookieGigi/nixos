{
  lib,
  pkgs,
  ...
}: {
  # Enable llama.cpp HTTP server with CUDA support for GPU inference.
  services.llama-cpp = {
    enable = true;

    # Use CUDA-enabled build for NVIDIA GPU acceleration.
    package = pkgs.llama-cpp.override {cudaSupport = true;};

    # Listen on all interfaces so the laptop can reach it.
    settings = {
      host = "0.0.0.0";
      port = 8080;

      # Default model path — place your .gguf here or override this path.
      # Example: model = "/var/lib/llama-cpp/models/mistral-7b-instruct-v0.2.Q4_K_M.gguf";
      model = "/var/lib/llama-cpp/models/default.gguf";

      # Offload as many layers as possible to the GPU.
      ngl = 999;

      # Context size.
      "ctx-size" = 8192;
    };

    openFirewall = true;
  };

  # llama.cpp uses DynamicUser by default, but with impermanence (ephemeral root)
  # we need a static user so /var/lib/llama-cpp survives reboots.
  systemd.services.llama-cpp.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = lib.mkForce "llama-cpp";
    Group = lib.mkForce "llama-cpp";
  };

  users.users.llama-cpp = {
    isSystemUser = true;
    group = "llama-cpp";
    home = "/var/lib/llama-cpp";
    createHome = true;
  };

  users.groups.llama-cpp = {};

  # Persist model and cache directories across reboots.
  environment.persistence."/persist".directories = [
    "/var/lib/llama-cpp"
    "/var/cache/llama-cpp"
  ];
}
