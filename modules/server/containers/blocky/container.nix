{pkgs, ...}: let
  blockyConf = pkgs.writeText "blocky-config.yml" ''
    upstreams:
      groups:
        default:
          - https://dns10.quad9.net/dns-query
      timeout: 2s

    bootstrapDns:
      - tcp+udp:9.9.9.10
      - tcp+udp:149.112.112.10

    blocking:
      denylists:
        ads:
          - https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt
      clientGroupsBlock:
        default:
          - ads
      blockType: zeroIp
      blockTTL: 10s
      loading:
        refreshPeriod: 24h

    caching:
      minTime: 5m
      maxTime: 30m
      prefetching: true
      prefetchExpires: 2h
      prefetchThreshold: 5


    customDNS:
      mapping:
        photo.cookiegigi.com: 192.168.1.49
        zot.cookiegigi.com: 192.168.1.49
        blocky.cookiegigi.com: 192.168.1.49
        fileflows.cookiegigi.com: 192.168.1.49

    statistics:
      enable: true

    queryLog:
      type: console

    ports:
      dns: 53
      http: 4000

    log:
      level: info
      format: text
      timestamp: true
  '';
in {
  environment.etc = {
    "containers/systemd/blocky.network".text = ''
      [Network]
      NetworkName=blocky

      [Install]
      WantedBy=multi-user.target
    '';

    "containers/systemd/blocky.container".text = ''
      [Unit]
      Description=Blocky DNS
      After=network-online.target

      [Container]
      Image=ghcr.io/0xerr0r/blocky:latest
      Network=blocky.network
      ContainerName=blocky
      PublishPort=127.0.0.1:53:53/tcp
      PublishPort=127.0.0.1:53:53/udp
      PublishPort=192.168.1.49:53:53/tcp
      PublishPort=192.168.1.49:53:53/udp
      PublishPort=192.168.1.49:4000:4000
      Volume=${blockyConf}:/app/config.yml:ro
      UserNS=keep-id:uid=53,gid=53
      Environment=TZ=Europe/Paris

      [Service]
      Restart=always
      RestartSec=5

      [Install]
      WantedBy=multi-user.target
    '';
  };
}
