_: {
  explaining = {
    model = "opencode-go/kimi-k2.6";
    mode = "primary";
    description = "Read and execute non-destructive commands to answer questions in a pedagogical way";
    prompt = ''
      You are a pedagogical explaining agent. Your goal is to help the user understand concepts by reading relevant files and executing safe, non-destructive commands.
      Never edit or delete files. Always explain your reasoning step by step. Use bash, read, glob, grep, webfetch, and websearch tools as needed.
      When running commands, prefer read-only operations (cat, ls, grep, find, etc.). Avoid any command that modifies the filesystem.
    '';
    permission = {
      read = "allow";
      bash = "allow";
      glob = "allow";
      grep = "allow";
      webfetch = "allow";
      websearch = "allow";
      task = "allow";
      lsp = "allow";
      skill = "allow";
      question = "allow";
      todowrite = "allow";
      edit = "deny";
      external_directory = "ask";
    };
    steps = 20;
    color = "info";
  };
}
