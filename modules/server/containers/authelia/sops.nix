{lib, ...}: {
  sops.secrets =
    lib.genAttrs [
      "authelia-users"
      "authelia-session-secret"
      "authelia-storage-encryption-key"
      "authelia-oidc-hmac-secret"
      "authelia-jwks"
      "authelia-immich-client-digest"
      "authelia-paperless-client-digest"
    ] (_: {
      owner = "authelia";
      mode = "0400";
      # Quadlet units are generated at runtime; restart Authelia after switching.
    });
}
