_: {
  sops = {
    secrets = {
      "hf-token" = {
        owner = "root";
        group = "ai";
        mode = "0440";
      };

      "opencode-server-password" = {
        owner = "cookiegigi";
        mode = "0400";
      };
    };
  };
}
