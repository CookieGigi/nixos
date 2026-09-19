{config, ...}: {
  sops = {
    # Quadlet units are generated at runtime; restart them manually after switching.
    secrets = {
      "immich-db-password" = {
        owner = "root";
        group = "immich-services";
        mode = "0440";
      };

      "authelia-immich-client-secret" = {};
      "immich-settings" = {};
    };

    templates."immich-config.json" = {
      owner = "immich";
      mode = "0400";
      # Merged over the encrypted export of existing settings before startup.
      content = builtins.toJSON {
        passwordLogin.enabled = true;
        oauth = {
          enabled = true;
          autoLaunch = false;
          autoRegister = false;
          buttonText = "Login with Authelia";
          clientId = "immich";
          clientSecret = config.sops.placeholder."authelia-immich-client-secret";
          issuerUrl = "https://auth.cookiegigi.com";
          # v3.1.0 links by email unconditionally. Authelia must allow only openid
          # for this client and must not inject email into ID tokens or userinfo.
          # Users first log in locally and explicitly link in user settings.
          scope = "openid";
          defaultStorageQuota = null;
          endSessionEndpoint = "";
          mobileOverrideEnabled = false;
          mobileRedirectUri = "";
          prompt = "";
          profileSigningAlgorithm = "none";
          signingAlgorithm = "RS256";
          storageLabelClaim = "preferred_username";
          storageQuotaClaim = "immich_quota";
          roleClaim = "immich_role";
          tokenEndpointAuthMethod = "client_secret_post";
          timeout = 30;
          allowInsecureRequests = false;
        };
      };
    };
  };
}
