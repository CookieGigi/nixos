{
  lib,
  pkgs,
  ...
}: let
  models = import ./models.nix;
  podmanMetrics = pkgs.writeShellScript "podman-textfile-metrics" ''
    set -euo pipefail
    output=/run/node-exporter/podman.prom
    tmp=$(mktemp /run/node-exporter/podman.prom.XXXXXX)
    stats=$(mktemp)
    trap 'rm -f "$tmp" "$stats"' EXIT
    ${pkgs.podman}/bin/podman stats --all --no-stream --format '{{.Name}} {{.CPUNano}} {{.MemUsageBytes}} {{.PIDs}}' > "$stats"
    {
      printf '# HELP homelab_podman_cpu_seconds_total Container CPU time in seconds.\n# TYPE homelab_podman_cpu_seconds_total counter\n'
      printf '# HELP homelab_podman_memory_bytes Container memory usage in bytes.\n# TYPE homelab_podman_memory_bytes gauge\n'
      printf '# HELP homelab_podman_pids Container process count.\n# TYPE homelab_podman_pids gauge\n'
      while read -r name cpu memory pids; do
        [[ "$name" =~ ^[a-zA-Z0-9_.-]+$ && "$cpu" =~ ^[0-9]+$ && "$memory" =~ ^[0-9]+$ && "$pids" =~ ^[0-9]+$ ]] || continue
        printf 'homelab_podman_cpu_seconds_total{container="%s"} %se-9\n' "$name" "$cpu"
        printf 'homelab_podman_memory_bytes{container="%s"} %s\n' "$name" "$memory"
        printf 'homelab_podman_pids{container="%s"} %s\n' "$name" "$pids"
      done < "$stats"
      printf 'homelab_podman_collection_success 1\n'
    } > "$tmp"
    chmod 0644 "$tmp"
    mv "$tmp" "$output"
  '';
in {
  virtualisation.containers.containersConf.settings.containers.log_driver = "journald";

  environment.persistence."/persist".directories = ["/var/lib/prometheus2" "/var/lib/alloy"];

  systemd = {
    tmpfiles.rules = ["d /run/node-exporter 0755 root root -"];
    services.podman-textfile-metrics = {
      description = "Collect rootful Podman container resource metrics";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = podmanMetrics;
      };
    };
    timers.podman-textfile-metrics = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = "1min";
      };
    };
  };

  services = {
    prometheus = {
      enable = true;
      listenAddress = "127.0.0.1";
      retentionTime = "30d";
      globalConfig.scrape_interval = "30s";
      exporters.node = {
        enable = true;
        listenAddress = "127.0.0.1";
        enabledCollectors = ["systemd" "textfile"];
        extraFlags = ["--collector.textfile.directory=/run/node-exporter"];
      };
      exporters.nvidia-gpu = {
        enable = true;
        listenAddress = "127.0.0.1";
      };
      scrapeConfigs = [
        {
          job_name = "node";
          static_configs = [{targets = ["127.0.0.1:9100"];}];
        }
        {
          job_name = "nvidia";
          static_configs = [{targets = ["127.0.0.1:9835"];}];
        }
        {
          job_name = "llama";
          metrics_path = "/metrics";
          params.autoload = ["false"];
          static_configs =
            map (model: {
              targets = ["127.0.0.1:8080"];
              labels.model = lib.removeSuffix ".gguf" model.file;
            })
            models;
          relabel_configs = [
            {
              source_labels = ["model"];
              target_label = "__param_model";
            }
          ];
        }
        {
          job_name = "prometheus";
          static_configs = [{targets = ["127.0.0.1:9090"];}];
        }
      ];
    };

    loki = {
      enable = true;
      dataDir = "/persist/loki";
      configuration = {
        auth_enabled = false;
        server = {
          http_listen_address = "127.0.0.1";
          http_listen_port = 3100;
          grpc_listen_address = "127.0.0.1";
        };
        common = {
          path_prefix = "/persist/loki";
          replication_factor = 1;
          ring.kvstore.store = "inmemory";
        };
        schema_config.configs = [
          {
            from = "2024-01-01";
            store = "tsdb";
            object_store = "filesystem";
            schema = "v13";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];
        storage_config.filesystem.directory = "/persist/loki/chunks";
        compactor = {
          working_directory = "/persist/loki/compactor";
          retention_enabled = true;
          delete_request_store = "filesystem";
        };
        limits_config.retention_period = "168h";
      };
    };

    alloy = {
      enable = true;
      extraFlags = ["--server.http.listen-addr=127.0.0.1:12345" "--disable-reporting"];
    };
    journald.settings.Journal.SystemMaxUse = "1G";
  };
  environment.etc."alloy/config.alloy".text = ''
    loki.relabel "journal" {
      forward_to = []
      rule {
        source_labels = ["__journal__systemd_unit"]
        target_label = "unit"
      }
      rule {
        source_labels = ["__journal_container_name"]
        target_label = "container"
      }
    }

    loki.source.journal "server" {
      labels = { host = "server" }
      relabel_rules = loki.relabel.journal.rules
      forward_to = [loki.write.local.receiver]
    }

    loki.write "local" {
      endpoint {
        url = "http://127.0.0.1:3100/loki/api/v1/push"
      }
    }
  '';
}
