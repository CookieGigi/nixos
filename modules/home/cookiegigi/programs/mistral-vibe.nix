{pkgs, ...}: {
  home.packages = with pkgs; [
    mistral-vibe
  ];

  home.persistence."/persist" = {
    directories = [
      ".vibe"
    ];
  };
}
