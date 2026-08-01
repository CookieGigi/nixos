{
  config,
  lib,
  ...
}: {
  services.reverseProxy.upstreams = lib.mkIf config.services.reverseProxy.enable [
    {
      subdomain = "opencode";
      port = 4096;
      systemdService = "opencode-serve";
    }
  ];
}
