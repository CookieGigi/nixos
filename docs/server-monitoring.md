# Server monitoring

The server runs native Prometheus, node exporter, NVIDIA GPU exporter, Loki,
Alloy, and Grafana. Prometheus stores 30 days of metrics and Loki stores 7 days
of journal logs on the NVMe `/persist` filesystem. Journald is capped at 1 GiB.
There are no externally exposed scrape, Loki, or Alloy endpoints.

Grafana is available at `https://grafana.cookiegigi.com` through Blocky DNS,
Caddy's private-client check, and Authelia two-factor authentication for the
`admins` group. Caddy alone can reach Grafana at `10.89.100.1:3000`: the host
firewall allows only Caddy's fixed `10.89.100.2` address, and Grafana's auth
proxy accepts identity headers only from that address. Do not turn on
`services.grafana.openFirewall` or bypass Caddy; proxy headers are trusted
credentials. Approved Authelia admins are Grafana organization admins.

Grafana generates its encryption key and disabled built-in admin's password
on first startup in `/persist/grafana`. Keep this directory persistent and
private; losing or rotating `secret_key` can make encrypted Grafana data
unreadable. Prometheus data is persisted at `/var/lib/prometheus2` via
impermanence; Loki uses `/persist/loki`, and Alloy's journal cursor is
persisted at `/var/lib/private/alloy` via impermanence. Alloy uses systemd's
`DynamicUser`, so `/var/lib/alloy` must remain a systemd-managed symlink, not
an impermanence bind mount.

When upgrading from the original monitoring declaration, the old
`var-lib-alloy.mount` may still be mounted. If Alloy continues to fail with
`238/STATE_DIRECTORY` after switching, stop Alloy and the obsolete mount,
then start Alloy again: `sudo systemctl stop alloy.service var-lib-alloy.mount`
and `sudo systemctl start alloy.service`. If the unmounted public directory
still blocks migration, remove it with `sudo rmdir /var/lib/alloy` (only when
empty) before starting Alloy. Verify that `/var/lib/alloy` is a symlink and
`var-lib-private-alloy.mount` is active.

The dashboard shows host CPU, memory and filesystems, Podman container CPU,
memory and process counts, GPU utilization and VRAM, scrape health, alert
state, and recent journal logs. The `llama` scrape reads the `/metrics`
endpoint enabled by `--metrics` on llama.cpp; explore its available inference
series in the Prometheus datasource. Router-mode metrics are scraped for each
registered model with `autoload=false`: unloaded models return a failed scrape
instead of triggering model loads. The llama server alert checks its systemd
unit, not those expected unloaded-model scrape failures. Podman stats are
captured every minute into node exporter's textfile directory; if its timer
fails, the textfile age alert becomes active. The collector runs as root to
inspect rootful Podman containers but does not grant Grafana Podman socket access. Loki logs
may contain DNS queries, user information, or authentication events: restrict
Grafana accounts accordingly.

The server-wide Podman default log driver is journald. Newly started
containers use it; existing containers may need recreation for their logging
configuration to change. Alloy ships journal entries, not arbitrary files
under `/persist` (for example, FileFlows' own log directory).

Grafana evaluates provisioned disk, CPU, RAM, node exporter, GPU exporter,
llama, and collector staleness rules every minute. A permanent mute timing
suppresses notification delivery while leaving firing state visible in Grafana.
Do not add direct contact points or modify notification policies without
reviewing this choice. UI-only alerts cannot report a full host/Grafana failure
from the failed host.

After a user-approved deployment, check:

1. `systemctl status prometheus grafana loki alloy prometheus-node-exporter prometheus-nvidia-gpu-exporter podman-textfile-metrics.timer`
2. `curl -fsS http://127.0.0.1:9090/-/ready` and `curl -fsS http://127.0.0.1:3100/ready`
3. Grafana's Connections > Data sources, Dashboards > Homelab, and Alerting > Alert rules.
4. Prometheus targets `node`, `nvidia`, `llama`, `prometheus` and the `node_textfile_mtime_seconds{file="podman.prom"}` series. Unloaded llama models normally show as failed scrapes.
5. Grafana Explore with `{host="server"}` to confirm Alloy delivers journal entries.

If any target is down, check its systemd journal and exporter endpoint from
the server. Provisioned Grafana rules and dashboard panels cannot be edited
permanently in the UI: edit their Nix/JSON declarations instead. A restart of
the affected Quadlet services may be needed after changing Caddy, Blocky, or
Authelia configurations.
