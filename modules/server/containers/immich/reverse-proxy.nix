{
  config,
  lib,
  ...
}: {
  services.reverseProxy.upstreams = lib.mkIf config.services.reverseProxy.enable [
    {
      subdomain = "photos";
      port = 2283;
      systemdService = "podman-immich-server";
    }
  ];
}
