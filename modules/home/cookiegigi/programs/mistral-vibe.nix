{
  inputs,
  pkgs,
  ...
}: {
  home.packages = [
    inputs.mistral-vibe.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  home.persistence."/persist" = {
    directories = [
      ".vibe"
    ];
  };
}
