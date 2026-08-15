{config, ...}: {
  sops.secrets."cloudflare-dnszone-token" = {
    path = "/run/secrets/cloudflare-dnszone-token";
  };
  sops.templates."caddy-env" = {
    content = ''
      CLOUDFLARE_API_TOKEN=${config.sops.placeholder."cloudflare-dnszone-token"}
    '';
    path = "/run/secrets/caddy-env";
    mode = "0440";
    group = "caddy";
  };
}
