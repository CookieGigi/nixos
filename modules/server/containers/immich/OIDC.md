# Immich OIDC Rollout

Issuer: `https://auth.cookiegigi.com`. Client ID: `immich`.

Authelia client requirements:

- Confidential client; `token_endpoint_auth_method: client_secret_post`.
- `response_types: [code]`, `grant_types: [authorization_code]`.
- Require PKCE with `S256`.
- Allow **only** `scopes: [openid]`. Do not inject `email`, role or quota claims
  through a custom claims policy, either into the ID token or userinfo.
- ID token signing algorithm `RS256`; unsigned JSON userinfo
  (`userinfo_signed_response_alg: none`). TLS verification remains enabled.
- Exact redirect URIs: `https://photo.cookiegigi.com/auth/login`,
  `https://photo.cookiegigi.com/user-settings`, `app.immich:///oauth-callback`.

## Account Safety

Immich v3.1.0's OAuth callback automatically links by matching email even when
`autoRegister` is false. There is no configuration switch to disable this.
Requesting only `openid`, and restricting the Authelia client to that scope,
avoids disclosing an email and therefore avoids that code path. The pinned
implementation accepts a userinfo response containing only `sub`.

Verify both token/userinfo claims before production login: no email claim may be
present. Do not broaden scopes later without reviewing this behavior. An unlinked
SSO login must fail without creating or modifying an account. Log in with the
existing local password, then explicitly link Authelia in user settings. Subsequent
SSO logins identify the same account by `sub`. Keep a local administrator password.
Changing the issuer/client subject mapping later requires deliberate relinking.

## Deployment Prerequisites

- Populate `authelia-immich-client-secret` in the default `secrets/secrets.yaml`.
  Use a single-line random hexadecimal or base64url secret: sops templates perform
  literal substitution, not JSON escaping. Authelia needs the corresponding digest,
  while Immich needs the original secret.
- **Before deploying, export and review Administration > Settings.**
  `IMMICH_CONFIG_FILE` replaces the saved database settings, merging unspecified
  keys with upstream defaults, not with existing UI settings. The bootstrap command
  imports this export into the encrypted `immich-settings` secret. Only use its
  `NEW` option for a fresh installation. Before every startup, jq overlays the
  declarative OAuth/local-login settings onto this baseline, preserving other
  settings. UI configuration becomes read-only; future baseline changes belong in
  `immich-settings`. No accounts or assets are deleted, and saved database
  configuration is not overwritten. Protect and remove the plaintext export after
  confirming the encrypted baseline is correct.
- The rendered config is read-only, owned by UID 300 with mode 0400, and mounted
  from `/run/immich-config/config.json`. Baseline and OAuth-template changes restart
  `immich-server.service`. The merged plaintext is never written to the Nix store.
- Containers resolve `auth.cookiegigi.com` to `192.168.1.49` via `AddHost` while
  retaining HTTPS hostname and certificate validation. Authelia's LAN HTTPS proxy
  must accept traffic from the container network. Browsers/mobile devices also
  need LAN/VPN access and DNS for that hostname.
- Port 2283 is no longer published. Web/mobile clients must use
  `https://photo.cookiegigi.com`; native APIs are not behind a browser auth gate.
- Test local login, explicit linking, web/mobile SSO, rejection of an unlinked
  account, and local login during an IdP outage. No rebuild or live login test was
  performed as part of these configuration edits.

## Verified Sources

- [v3.1.0 OAuth callback and explicit linking](https://github.com/immich-app/immich/blob/v3.1.0/server/src/services/auth.service.ts)
- [v3.1.0 userinfo handling](https://github.com/immich-app/immich/blob/v3.1.0/server/src/repositories/oauth.repository.ts)
- [v3.1.0 full OAuth schema](https://github.com/immich-app/immich/blob/v3.1.0/server/src/dtos/system-config.dto.ts)
- [v3.1.0 configuration precedence](https://github.com/immich-app/immich/blob/v3.1.0/server/src/utils/config.ts)
