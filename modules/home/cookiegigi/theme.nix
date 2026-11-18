{lib, ...}: {
  options.cookiegigi.theme.backgroundColor = lib.mkOption {
    type = lib.types.str;
    default = "#0d1117";
    description = "Shared background color for CookieGigi's themed applications.";
  };
}
