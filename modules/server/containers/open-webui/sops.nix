{config, ...}: {
  sops.secrets."authelia-open-webui-client-secret" = {};

  sops.templates."open-webui-oidc-env" = {
    mode = "0400";
    content = ''
      OAUTH_CLIENT_SECRET=${config.sops.placeholder."authelia-open-webui-client-secret"}
    '';
  };
}
