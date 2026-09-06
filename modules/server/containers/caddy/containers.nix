{pkgs, ...}: let
  caddyfile = pkgs.writeText "Caddyfile" ''
    {
      acme_dns cloudflare {env.CLOUDFLARE_API_TOKEN}
    }

    *.cookiegigi.com {
      tls {
        dns cloudflare {env.CLOUDFLARE_API_TOKEN}
      }
    }

    zot.cookiegigi.com {
      reverse_proxy 192.168.1.49:5050
    }

    blocky.cookiegigi.com {
      reverse_proxy 192.168.1.49:4000
    }

    fileflows.cookiegigi.com {
      reverse_proxy 192.168.1.49:5000
    }

    photo.cookiegigi.com {
      reverse_proxy 192.168.1.49:2283
    }

    bookorbit.cookiegigi.com {
      reverse_proxy 192.168.1.49:3000
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
