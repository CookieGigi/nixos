_: {
  environment.etc = {
    "containers/systemd/adguardhome.container".text = ''
      [Unit]
      Description=AdguardHome
      After=network-online.target

      [Container]
      Image=docker.io/adguard/adguardhome
      ContainerName=adguardhome
      PublishPort=127.0.0.1:53:53/tcp
      PublishPort=127.0.0.1:53:53/udp
      PublishPort=192.168.1.49:53:53/tcp
      PublishPort=192.168.1.49:53:53/udp
      PublishPort=8053:80
      PublishPort=3053:3000
      Volume=/persist/adguardhome/opt/adguardhome/work:/opt/adguardhome/work
      Volume=/persist/adguardhome/opt/adguardhome/conf:/opt/adguardhome/conf
      Environment=TZ=Europe/Paris

      [Service]
      Restart=always
      RestartSec=5

      [Install]
      WantedBy=multi-user.target
    '';
  };
}
