{
  # Install git
  programs.git = {
    enable = true;
    config = {
      core.hooksPath = ".githooks";
    };
  };
}
