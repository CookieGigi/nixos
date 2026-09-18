# Jellyfin

The server runs the official Jellyfin image as a Podman Quadlet, configured in
`modules/server/containers/jellyfin/`.

## First setup

Open `https://jellyfin.cookiegigi.com` after deployment and complete the setup
wizard immediately to create the administrator account. Blocky provides DNS
and Caddy terminates HTTPS, proxying to `192.168.1.49:8096`.

Add video libraries using paths under `/media/videos` and a music library at
`/media/music`. Both trees are mounted read-only; metadata stays in Jellyfin's
configuration directory rather than beside media files.

In Dashboard > Networking, configure Known Proxies with Caddy's actual source
IP before relying on forwarded client addresses or local/remote access rules.
Do not trust the whole LAN. Caddy's bridge address is dynamically allocated;
verify it again if that network is recreated.

## Storage

| Host path | Purpose | Access |
| --- | --- | --- |
| `/persist/jellyfin/config` | Database, settings and metadata | Read/write |
| `/persist/jellyfin/cache` | Cache and default transcoding workspace | Read/write |
| `/media/videos` | Video libraries | Read-only |
| `/media/music` | Music library | Read-only |

Jellyfin runs as UID 407 with the shared media group (GID 200). Back up the
configuration directory and media separately; no backup job is added here.
Monitor cache space when transcoding large files.

## Operations

```sh
sudo systemctl status jellyfin
sudo journalctl -u jellyfin -f
```

GPU passthrough, hardware transcoding, DLNA and UDP client discovery are not
enabled. Clients can connect using the HTTPS URL; transcoding uses the CPU.
The image follows the upstream `latest` tag. Review migration notes and back
up configuration before updating it.
