# Paperless-ngx

The server runs Paperless-ngx, PostgreSQL 18, and Valkey 9 as Podman Quadlets.
The module lives in `modules/server/containers/paperless/`.

## Access

- URL: `https://paperless.cookiegigi.com` (Blocky DNS and Caddy HTTPS).
- The application is published on `192.168.1.49:8000`; the database and broker
  have no published ports.
- On first access, create the administrator account through the web interface.
  Complete this immediately after deployment, before giving others access.
- OCR uses French and English; the timezone is `Europe/Paris`.

## Storage

| Host path | Purpose |
| --- | --- |
| `/media/documents/archive` | Paperless-managed original documents |
| `/media/documents/inbox` | Import queue; successfully imported files are removed |
| `/persist/paperless/data` | Application state and search index |
| `/persist/paperless/media` | Generated archive PDFs and thumbnails |
| `/persist/paperless/export` | Destination for manual document exports |
| `/persist/paperless/postgres` | PostgreSQL database |
| `/persist/paperless/broker` | Valkey persistence |

Upload files through the UI or place them in the inbox. Do not move or edit
files in the managed archive directly. Existing books and other document
directories are not consumed. The `media` group can write to the inbox and
read originals; application, database, and broker processes use dedicated
UIDs 404, 405, and 406.

The originals directory is mounted inside the application's media directory
to keep originals on HDD and generated files on NVMe. Backups must include
both storage tiers and the PostgreSQL database. Persistence is not a backup;
this module does not schedule backups.

## Secrets

`secrets/paperless.yaml` contains a generated database password and application
secret key, encrypted for the existing SOPS recipients. Runtime environment
files are rendered by sops-nix with mode `0400`; secrets are not in the Nix store.

Edit the encrypted file using the existing helper:

```sh
nix run .#edit-secrets -- secrets/paperless.yaml
```

Changing the database secret does not change the password in an initialized
PostgreSQL database: coordinate password rotation with a database password
change. Keep the application secret key stable and backed up.

## Operations

```sh
sudo systemctl status paperless paperless-db paperless-broker
sudo journalctl -u paperless -f
```

Office document conversion via Tika/Gotenberg is not enabled. The application
uses the upstream `latest` image, while PostgreSQL and Valkey are pinned to
major versions. Review upstream migration notes before updating images.
