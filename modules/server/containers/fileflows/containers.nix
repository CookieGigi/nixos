_: {
  environment.etc = {
    "containers/systemd/fileflows.container".text = ''
      [Unit]
      Description=FileFlows - file processing
      After=network-online.target

      [Container]
      Image=docker.io/revenz/fileflows:latest
      ContainerName=fileflows
      PublishPort=5000:5000
      Volume=/persist/fileflows/data:/app/Data
      Volume=/persist/fileflows/logs:/app/Logs
      Volume=/persist/fileflows/temp:/temp
      Volume=/downloads:/downloads
      Volume=/media:/media
      Environment=TZ=Europe/Paris
      Environment=TempPathHost=/persist/fileflows/temp
      AddDevice=nvidia.com/gpu=all
      Environment=NVIDIA_DRIVER_CAPABILITIES=compute,video,utility
      Environment=NVIDIA_VISIBLE_DEVICES=all

      [Service]
      Restart=always
      RestartSec=5

      [Install]
      WantedBy=multi-user.target
    '';
  };
}
