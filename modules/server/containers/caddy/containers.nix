{pkgs, ...}: let
  caddyfile = pkgs.writeText "Caddyfile" ''
    {
      acme_dns cloudflare {env.CLOUDFLARE_API_TOKEN}
    }

    (private_only) {
      @outside not remote_ip private_ranges
      respond @outside "LAN/VPN access only" 403
    }

    (authelia) {
      # Never accept identity assertions supplied by a client.
      request_header -Remote-User
      request_header -Remote-Groups
      request_header -Remote-Email
      request_header -Remote-Name
      forward_auth authelia:9091 {
        uri /api/authz/forward-auth
        copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
      }
    }

    auth.cookiegigi.com {
      route {
        import private_only
        reverse_proxy authelia:9091
      }
    }

    *.cookiegigi.com {
      tls {
        dns cloudflare {env.CLOUDFLARE_API_TOKEN}
      }
    }

    llama-cpp.cookiegigi.com {
      route {
        import private_only
        import authelia
        reverse_proxy llama:8080
      }
    }

    openwebui.cookiegigi.com {
      route {
        import private_only
        import authelia
        reverse_proxy open-webui:8080
      }
    }

    hermes.cookiegigi.com {
      route {
        import private_only
        import authelia
        reverse_proxy hermes:9119
      }
    }

    search.cookiegigi.com {
      route {
        import private_only
        import authelia
        reverse_proxy searxng:8080
      }
    }

    zot.cookiegigi.com {
      route {
        import private_only
        import authelia
        reverse_proxy zot:5000
      }
    }

    blocky.cookiegigi.com {
      route {
        import private_only
        import authelia
        reverse_proxy blocky:4000
      }
    }

    fileflows.cookiegigi.com {
      route {
        import private_only
        import authelia
        reverse_proxy fileflows:5000
      }
    }

    photo.cookiegigi.com {
      route {
        import private_only
        reverse_proxy immich-server:2283
      }
    }

    bookorbit.cookiegigi.com {
      route {
        import private_only
        reverse_proxy bookorbit:3000
      }
    }

    homeassistant.cookiegigi.com {
      route {
        import private_only
        reverse_proxy 10.89.100.1:8123
      }
    }

    paperless.cookiegigi.com {
      route {
        import private_only
        reverse_proxy paperless:8000
      }
    }

    jellyfin.cookiegigi.com {
      route {
        import private_only
        reverse_proxy jellyfin:8096
      }
    }
  '';
in {
  environment.etc = {
    "containers/systemd/caddy.network".text = ''
      [Network]
      NetworkName=caddy
      Options=metric=10
    '';

    "containers/systemd/caddy.container".text = ''
      [Unit]
      Description=Caddy
      After=network-online.target

      [Container]
      Image=zot.cookiegigi.com:5050/caddy-cloudflare:2.11.4
      ContainerName=caddy
      # Keep a single default-route network for symmetric published-port replies.
      Network=caddy.network
      Network=authelia.network
      Network=blocky-proxy.network
      Network=bookorbit.network
      Network=fileflows-proxy.network
      Network=home-assistant-proxy.network:ip=10.89.100.2
      Network=jellyfin.network
      Network=zot.network
      PublishPort=80:80
      PublishPort=443:443
      PublishPort=443:443/udp
      Volume=${caddyfile}:/etc/caddy/Caddyfile:ro
      Volume=/persist/caddy/srv:/srv
      Volume=/persist/caddy/data:/data
      Volume=/persist/caddy/config:/config
      UserNS=keep-id:uid=80,gid=80
      Environment=TZ=Europe/Paris
      EnvironmentFile=/run/secrets/caddy-env

      [Service]
      Restart=always
      RestartSec=5

      [Install]
      WantedBy=multi-user.target
    '';
  };
}
