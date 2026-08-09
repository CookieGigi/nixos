{pkgs, ...}: let
  zotConf = pkgs.writeText "config.json" ''
    {
      "storage": {
        "rootDirectory": "/var/lib/registry"
      },
      "http": {
        "address": "0.0.0.0",
        "port": "5000",
        "compat": ["docker2s2"]
      },
      "log": {
        "level": "debug"
      },
      "extensions": {
        "sync": {
          "enable": true,
          "registries": [
            {
              "urls": ["https://docker.io/library"],
              "content": [
                {
                  "prefix": "**",
                  "destination": "/docker-images"
                }
              ],
              "onDemand": true,
              "tlsVerify": true
            }
          ]
        },
        "search": {
          "enable": true,
          "cve": {
            "updateInterval": "2h"
          }
        },
        "ui": {
          "enable": true
        },
        "mgmt": {
          "enable": true
        }
      }
    }
  '';
in {
  environment.etc."containers/systemd/zot.container".text = ''
    [Unit]
    Description=Zot OCI registry
    After=network-online.target

    [Container]
    Image=ghcr.io/project-zot/zot:latest
    ContainerName=zot
    PublishPort=5050:5000
    Volume=${zotConf}:/etc/zot/config.json:ro
    Volume=/persist/zot/registry:/var/lib/registry
    UserNS=keep-id:uid=50,gid=50
    Environment=TZ=Europe/Paris

    [Service]
    Restart=always
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
  '';
}
