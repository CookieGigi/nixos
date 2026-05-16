{...}: {
  programs.git = {
    enable = true;
    settings = {
      core.hooksPath = ".githooks";
    };
  };
}
