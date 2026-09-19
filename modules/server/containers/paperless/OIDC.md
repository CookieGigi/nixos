# Paperless OIDC Rollout

Issuer: `https://auth.cookiegigi.com`. Client ID: `paperless`.
Allauth provider ID: `authelia`.

Authelia client requirements:

- Confidential client; `token_endpoint_auth_method: client_secret_basic`.
- `response_types: [code]`, `grant_types: [authorization_code]`.
- Require PKCE with `S256` (enabled in the provider configuration).
- Scopes: `openid`, `profile`, `email`. No group/role synchronization is enabled.
- ID token signing algorithm `RS256`; unsigned JSON userinfo
  (`userinfo_signed_response_alg: none`). Preserve normal TLS verification.
- Exact redirect URI:
  `https://paperless.cookiegigi.com/accounts/oidc/authelia/login/callback/`.

## Deployment And Linking

- Populate `authelia-paperless-client-secret` in the default `secrets/secrets.yaml`,
  not `secrets/paperless.yaml`. Use a single-line random hexadecimal or base64url
  secret because runtime template substitution does not JSON-escape secrets.
  Authelia needs its digest; Paperless needs the original value.
- The existing root-only runtime `paperless-app-env` template supplies the provider
  JSON. Manually restart `paperless.service` after deploying changes. No plaintext secret is placed
  in the Nix store. As with existing DB credentials, the container environment is
  visible to privileged container administrators.
- Local login remains enabled. Local and social signups and automatic social
  signup are disabled. Provider email authentication is explicitly false, so an
  email match cannot authenticate or automatically connect a local account.
- Log in with the existing local credentials, open **My Profile**, and connect
  Authelia there. This preserves the existing user ID, permissions and documents.
  Test that an unlinked account is rejected and linked SSO succeeds; keep local
  administrator credentials for recovery.
- Containers use `AddHost=auth.cookiegigi.com:192.168.1.49`, retaining HTTPS
  certificate verification. The LAN HTTPS proxy must accept container traffic;
  browsers also need LAN/VPN access and working DNS for the issuer.
- The existing image is `latest`; verify the deployed image supports the settings
  before rollout. The current Authelia guide tests Paperless v3.0.5. No images,
  data volumes, account records or existing secret values were changed.
- Port 8000 is no longer published. Clients must use
  `https://paperless.cookiegigi.com`; native API/token authentication is preserved.
  No rebuild or live login test was performed.

## Verified Sources

- [Authelia Paperless integration](https://www.authelia.com/integration/openid-connect/clients/paperless/)
- [Paperless authentication settings](https://github.com/paperless-ngx/paperless-ngx/blob/dev/docs/configuration.md#authentication--sso)
- [Paperless explicit account linking](https://github.com/paperless-ngx/paperless-ngx/blob/dev/docs/advanced_usage.md#openid-connect-and-social-authentication)
- [Allauth email authentication policy](https://docs.allauth.org/en/latest/socialaccount/configuration.html)
