{
  config,
  lib,
  ...
}: {
  services.reverseProxy.upstreams = lib.mkIf config.services.reverseProxy.enable [
    {
      subdomain = "ai";
      port = 8080;
      systemdService = "podman-llama";
    }
  ];
}
