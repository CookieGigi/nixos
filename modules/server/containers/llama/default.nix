{...}: {
  imports = [
    ./container.nix
    ./users.nix
  ];

  # HuggingFace token for model downloads (used by both llama-cpp and container)
  sops.secrets."hf-token" = {
    owner = "root";
    group = "ai";
    mode = "0440";
  };
}
