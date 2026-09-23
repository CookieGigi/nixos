# Open WebUI OIDC Rollout

Open WebUI uses Authelia at `https://auth.cookiegigi.com` as a confidential
OIDC client (`open-webui`). The exact callback is
`https://openwebui.cookiegigi.com/oauth/oidc/callback`. The existing local
login remains enabled. `ENABLE_PERSISTENT_CONFIG=False` keeps the OAuth admin
screen read-only; its values come from the Quadlet environment instead.

## Before Deploying

- Add `authelia-open-webui-client-secret` and
  `authelia-open-webui-client-digest` to the encrypted `secrets/secrets.yaml`.
  Generate a unique, single-line random hexadecimal client secret and its
  matching PBKDF2-SHA512 digest using Authelia's `crypto hash generate pbkdf2
  --variant sha512 --random --random.charset numeric-hex --random.length 64`.
  Store `Random Password` as the secret and `Digest` as the digest. Do not put
  either value in Nix files, shell arguments, or chat. The SOPS manifest will
  fail to build until both encrypted keys exist.
- The container reaches the HTTPS issuer through Caddy at `192.168.1.49`;
  normal TLS verification stays enabled. Check DNS and HTTPS from the browser
  and the container before testing login.
- With `ENABLE_OAUTH_SIGNUP=True` and email merging disabled, a first OIDC
  login can create a new user, but it will not automatically link to an
  existing local account with the same email. Existing chats and admin
  permissions do not move automatically. Keep local admin credentials for
  recovery; decide how to migrate an existing account before relying on OIDC
  for that account. Do not enable email merging without first reviewing
  account-linking and email ownership.
- After the encrypted keys are in place and a separately approved server
  rebuild has completed, reload Quadlet units and restart `authelia.service`
  and `open-webui.service`. Verify the login button, callback, new-user role,
  local login, and an IdP outage. No rebuild or live login test was performed.

Sources: [Authelia's Open WebUI client guide](https://www.authelia.com/integration/openid-connect/clients/open-webui/),
[Open WebUI SSO documentation](https://docs.openwebui.com/features/sso).
