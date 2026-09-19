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

    ai.cookiegigi.com {
      reverse_proxy llama:8080
    }

    zot.cookiegigi.com {
      reverse_proxy 192.168.1.49:5050
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
      reverse_proxy 192.168.1.49:3000
    }

    homeassistant.cookiegigi.com {
      reverse_proxy 10.89.100.1:8123
    }

    paperless.cookiegigi.com {
      route {
        import private_only
        reverse_proxy paperless:8000
      }
    }

    jellyfin.cookiegigi.com {
      reverse_proxy 192.168.1.49:8096
    }
  '';
in {
  environment.etc = {
    "containers/systemd/caddy.network".text = ''
      [Network]
      NetworkName=caddy
    '';

    "containers/systemd/caddy.container".text = ''
      [Unit]
      Description=Caddy
      After=network-online.target

      [Container]
      Image=zot.cookiegigi.com:5050/caddy-cloudflare:2.11.4
      ContainerName=caddy
      Network=caddy.network
      Network=authelia.network
      Network=blocky.network
      Network=fileflows.network
      Network=home-assistant-proxy.network:ip=10.89.100.2
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
