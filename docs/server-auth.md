# Server Authentication

Authelia 4.39.22 is the local identity provider at
`https://auth.cookiegigi.com`. Blocky resolves the issuer to `192.168.1.49` and
Caddy terminates HTTPS using the existing Cloudflare DNS-01 configuration.

| Service | Integration | Access policy |
| --- | --- | --- |
| Authelia | Login, MFA enrollment, OIDC discovery | Private-network HTTPS |
| Blocky HTTP | Caddy forward authentication | `admins` group and two factors |
| FileFlows | Caddy forward authentication | `admins` group and two factors |
| Immich | Native OIDC, explicit account linking | Two-factor SSO; local login retained |
| Paperless | Native OIDC, explicit account linking | Two-factor SSO; local login retained |

Other services are unchanged. This does not add registry authentication to Zot or
API authentication to Llama, and does not replace Jellyfin/Home Assistant login.
Local application passwords bypass IdP MFA intentionally as a recovery path.

## Network Boundary

Caddy rejects non-private source addresses on all five hosts above, using
`remote_ip`, not a client-supplied forwarding header. This permits LAN, loopback,
RFC1918 container/routed VPN networks and IPv6 ULA. It does **not** provision a VPN
or allow CGNAT `100.64.0.0/10`, including typical Tailscale addresses. Review the
matcher for the actual VPN before relying on remote access.

Keep router port forwarding disabled and block public IPv6 ingress. A private
upstream proxy or router that source-NATs Internet requests can conceal their
origin from Caddy; the application matcher is not a replacement for perimeter
firewall policy. Do not put these routes behind a public tunnel. Split DNS and
LAN/VPN connectivity are required on browsers and mobile devices.

Authelia has an internal network shared only with Caddy and no published port.
Caddy reaches the four applications by container DNS. Ports 4000, 5000, 2283 and
8000 are no longer published, preventing direct backend access outside container
networks. Blocky's TCP/UDP DNS port 53 remains available. Container administrators
and containers sharing a backend network remain inside the trust boundary.

Immich and Paperless reach the HTTPS issuer through an explicit host mapping;
normal TLS verification stays enabled. Caddy strips incoming identity headers
before its auth request and copies them only from a successful Authelia response.
Native OIDC apps are not behind forward-auth, preserving API and mobile protocols.
FileFlows workers/API automation and direct Blocky HTTP clients now require a
separate non-browser authentication design; there is no unauthenticated exception.

## Bootstrap

Before switching, back up existing application data and confirm both local admin
passwords work. Export the current Immich system configuration from
**Administration > Settings**. File-based configuration makes the UI settings
read-only, so the export is needed to preserve non-default configuration.

From the repository root, run interactively:

```sh
nix run path:.#bootstrap-authelia
```

`path:.` includes new, untracked modules/scripts. The age key must be readable at
`/persist/var/lib/sops-nix/key.txt`, or set `SOPS_AGE_KEY_FILE` to an existing readable
key. Do not send credentials through chat, command arguments, or environment
variables. The command prompts privately for the initial admin and Immich export
path. Enter `NEW` only if Immich is a fresh installation with no settings to retain.

The command adds these encrypted entries to `secrets/secrets.yaml`:

| Key | Purpose |
| --- | --- |
| `authelia-users` | JSON file-backend database with an Argon2id password and `admins` membership |
| `authelia-session-secret` | Session key |
| `authelia-storage-encryption-key` | SQLite sensitive-data encryption |
| `authelia-oidc-hmac-secret` | OIDC token HMAC |
| `authelia-jwks` | RSA-4096 signing private key |
| `authelia-immich-client-secret` | Original confidential-client secret for Immich |
| `authelia-immich-client-digest` | PBKDF2 digest for Authelia |
| `authelia-paperless-client-secret` | Original confidential-client secret for Paperless |
| `authelia-paperless-client-digest` | PBKDF2 digest for Authelia |
| `immich-settings` | Complete exported baseline configuration as a JSON string |

It refuses existing identity/bootstrap keys rather than rotating them, preserves
unrelated entries, and writes only ciphertext to temporary files. The original
Immich export may contain secrets: protect it and remove it after confirming the
encrypted import. No credentials are embedded in Nix store configuration files.

Until these entries exist, the SOPS manifest build deliberately fails. After
bootstrap, verify:

```sh
nix build --no-link path:.#nixosConfigurations.server.config.system.build.sops-nix-manifest
nix flake check path:.
```

Only then schedule the normal server rebuild with explicit operator approval.
No rebuild or activation is performed by bootstrap. Quadlet files are generated
from `/etc/containers/systemd`; on an existing server, make sure changed units have
actually restarted, not merely that their source files changed. If necessary:

```sh
sudo systemctl daemon-reload
sudo systemctl restart authelia immich-server paperless blocky fileflows caddy
```

Restarting Blocky briefly interrupts DNS. Do this from a retained SSH session and
check service status/journals before closing that session.

## Enrollment And Linking

1. Open `https://auth.cookiegigi.com` over the LAN/VPN and log in with the bootstrap
   account. Enroll TOTP, or a supported WebAuthn security key.
2. The filesystem notifier does not send email. Retrieve enrollment verification
   codes/links privately on the server with
   `sudo less /persist/authelia/notification.txt`. Do not paste this file into logs,
   issues or chat. It is inside a mode-0700 directory owned by UID/GID 408.
3. Log in to Immich with the existing local password and explicitly link Authelia
   in user settings. Its client allows only `openid`: Immich v3.1.0 automatically
   links matching email addresses, so disclosing an email claim is intentionally
   prohibited. Do not broaden scopes or add an email claims policy.
4. Log in to Paperless locally, open **My Profile**, and connect Authelia. Email
   authentication and automatic local/social signups are disabled.
5. Verify linked web/mobile SSO, rejection of an unlinked identity, local password
   recovery during an IdP outage, and denial of non-admin access to gated services.

App-specific callbacks and source references are in
[`immich/OIDC.md`](../modules/server/containers/immich/OIDC.md) and
[`paperless/OIDC.md`](../modules/server/containers/paperless/OIDC.md).

The file backend is read-only and password change/reset endpoints are disabled.
Manage users and password hashes through encrypted `authelia-users`, then deploy;
do not edit the generated `/run/secrets` file. SMTP is a future change, not part of
this initial local-notifier deployment.

## Recovery And Rotation

Persisted identity state lives directly on the persistent filesystem at
`/persist/authelia`: SQLite contains MFA registrations and identity mappings.
Sessions use in-memory storage; an Authelia restart signs users out.

Back up the entire directory consistently while Authelia is stopped, together
with encrypted `secrets/secrets.yaml`, the configuration revision, and separately
protected age recovery keys. The SQLite database and storage encryption key must
be restored together. Test restoration before relying on SSO. This change does
not install an automated backup service.

Never rerun bootstrap to recover an existing IdP or randomly replace the storage
encryption key. Storage-key rotation requires Authelia's migration procedure;
signing-key/subject changes require an OIDC rotation plan. Client rotation must
update both the original client secret and matching digest. Use hexadecimal
client secrets because application template substitution is not JSON escaping.

Keep SSH key access and local Immich/Paperless administrator credentials outside
the IdP. If Authelia is unavailable, Blocky HTTP and FileFlows fail closed, but DNS
and the native application login paths remain independent. If restoring an older
configuration, review whether it republishes backend ports or removes MFA gates.

## Acceptance Checks

- Confirm private DNS, HTTPS certificates, and
  `https://auth.cookiegigi.com/.well-known/openid-configuration` from both a client
  and an application container. The issuer must exactly match the configured URL.
- Unauthenticated Blocky/FileFlows access must redirect to Authelia. Spoofing
  `Remote-User` or `X-Forwarded-For` must not grant access.
- From a separate LAN machine, confirm ports 4000, 5000, 2283, 8000 and 9091 cannot
  be reached directly; confirm DNS on 53 still works.
- Confirm non-private ingress is denied, including IPv6 and the real router/VPN
  path. Do not infer this from DNS records alone.
- Check actual token/userinfo claims, existing-account linking, MFA, web/mobile
  SSO and local recovery before considering rollout complete.

Offline checks passed with synthetic credentials: Authelia configuration parsing,
bootstrap encryption/hashing and overwrite refusal, Nix assertions, Quadlet
generation, Immich settings merge and Caddy handler ordering. Caddy testing used
the standard binary with only Cloudflare-specific configuration substituted;
the custom image, ACME issuance and live login flows still require deployment tests.
