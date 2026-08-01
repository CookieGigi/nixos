{...}: {
  imports = [
    ./container.nix
    ./users.nix
    ./reverse-proxy.nix
  ];

  # HuggingFace token for model downloads (used by both llama-cpp and container)
  sops.secrets."hf-token" = {
    owner = "root";
    group = "ai";
    mode = "0440";
  };
}
