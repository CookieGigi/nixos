{pkgs, ...}: let
  grafanaState = "/persist/grafana";
  bootstrap = pkgs.writeShellScript "grafana-local-secrets" ''
    set -euo pipefail
    umask 077
    if [ ! -s ${grafanaState}/secret_key ]; then
      ${pkgs.openssl}/bin/openssl rand -base64 48 > ${grafanaState}/secret_key
    fi
    if [ ! -s ${grafanaState}/admin_password ]; then
      ${pkgs.openssl}/bin/openssl rand -base64 48 > ${grafanaState}/admin_password
    fi
  '';
  alert = uid: title: expr: threshold: {
    inherit uid title;
    condition = "B";
    "for" = "5m";
    noDataState = "Alerting";
    execErrState = "Alerting";
    data = [
      {
        refId = "A";
        datasourceUid = "prometheus";
        relativeTimeRange = {
          from = 600;
          to = 0;
        };
        model = {
          editorMode = "code";
          inherit expr;
          instant = true;
          range = false;
          refId = "A";
        };
      }
      {
        refId = "B";
        datasourceUid = "__expr__";
        relativeTimeRange = {
          from = 0;
          to = 0;
        };
        model = {
          conditions = [
            {
              evaluator = {
                params = [threshold];
                type = "gt";
              };
              operator.type = "and";
              query.params = ["A"];
              reducer.type = "last";
              type = "query";
            }
          ];
          datasource = {
            type = "__expr__";
            uid = "__expr__";
          };
          expression = "A";
          refId = "B";
          type = "classic_conditions";
        };
      }
    ];
  };
in {
  systemd.services.grafana = {
    requires = ["home-assistant-proxy-network.service"];
    after = ["home-assistant-proxy-network.service"];
    serviceConfig.ExecStartPre = [bootstrap];
  };

  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -s 10.89.100.2 -p tcp --dport 3000 -j ACCEPT
  '';

  services.grafana = {
    enable = true;
    dataDir = grafanaState;
    settings = {
      server = {
        http_addr = "10.89.100.1";
        root_url = "https://grafana.cookiegigi.com/";
      };
      security = {
        secret_key = "$__file{${grafanaState}/secret_key}";
        admin_password = "$__file{${grafanaState}/admin_password}";
        cookie_secure = true;
      };
      "auth.proxy" = {
        enabled = true;
        header_name = "Remote-User";
        header_property = "username";
        auto_sign_up = true;
        whitelist = "10.89.100.2";
      };
      "auth.anonymous".enabled = false;
      "auth.basic".enabled = false;
      auth.disable_login_form = true;
      users.auto_assign_org_role = "Admin";
    };
    provision = {
      enable = true;
      datasources.settings = {
        apiVersion = 1;
        datasources = [
          {
            name = "Prometheus";
            uid = "prometheus";
            type = "prometheus";
            access = "proxy";
            url = "http://127.0.0.1:9090";
            isDefault = true;
            editable = false;
          }
          {
            name = "Loki";
            uid = "loki";
            type = "loki";
            access = "proxy";
            url = "http://127.0.0.1:3100";
            editable = false;
          }
        ];
      };
      dashboards.settings = {
        apiVersion = 1;
        providers = [
          {
            name = "Homelab";
            folder = "Homelab";
            folderUid = "homelab";
            type = "file";
            updateIntervalSeconds = 30;
            options.path = ./grafana-dashboards;
          }
        ];
      };
      alerting = {
        contactPoints.settings = {
          apiVersion = 1;
          contactPoints = [
            {
              orgId = 1;
              name = "ui-only-sink";
              receivers = [
                {
                  uid = "ui_only_sink";
                  type = "webhook";
                  settings.url = "http://127.0.0.1:9/";
                }
              ];
            }
          ];
        };
        rules.settings = {
          apiVersion = 1;
          groups = [
            {
              orgId = 1;
              name = "Server health";
              folder = "Homelab";
              interval = "1m";
              rules = [
                (alert "node_missing" "Node exporter unavailable" "up{job=\"node\"} == bool 0" 0)
                (alert "disk_low" "Persistent disk over 90%" "1 - node_filesystem_avail_bytes{mountpoint=~\"/persist|/media\",fstype=\"btrfs\"} / node_filesystem_size_bytes{mountpoint=~\"/persist|/media\",fstype=\"btrfs\"}" 0.9)
                (alert "memory_low" "Available memory below 10%" "1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes" 0.9)
                (alert "cpu_high" "CPU busy over 90%" "1 - avg(rate(node_cpu_seconds_total{mode=\"idle\"}[5m]))" 0.9)
                (alert "gpu_missing" "NVIDIA exporter unavailable" "up{job=\"nvidia\"} == bool 0" 0)
                (alert "llama_missing" "llama.cpp server stopped" "1 - node_systemd_unit_state{name=\"podman-llama.service\",state=\"active\"}" 0)
                (alert "podman_missing" "Podman stats collector stale" "time() - node_textfile_mtime_seconds{file=\"/run/node-exporter/podman.prom\"}" 180)
              ];
            }
          ];
        };
        muteTimings.settings = {
          apiVersion = 1;
          muteTimes = [
            {
              orgId = 1;
              name = "ui-only";
              time_intervals = [
                {
                  times = [
                    {
                      start_time = "00:00";
                      end_time = "24:00";
                    }
                  ];
                }
              ];
            }
          ];
        };
        policies.settings = {
          apiVersion = 1;
          policies = [
            {
              orgId = 1;
              receiver = "ui-only-sink";
              routes = [
                {
                  receiver = "ui-only-sink";
                  object_matchers = [["alertname" "=~" ".+"]];
                  mute_time_intervals = ["ui-only"];
                }
              ];
            }
          ];
        };
      };
    };
  };
}
