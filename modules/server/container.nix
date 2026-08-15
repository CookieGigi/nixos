_: {
  environment.etc."containers/registries.conf.d/zot-mirrors.conf".text = ''
    [[registry]]
    prefix = "docker.io"
    location = "docker.io"

    [[registry.mirror]]
    location = "localhost:5050/docker-images"
    insecure = true

    [[registry]]
    prefix = "ghcr.io"
    location = "ghcr.io"

    [[registry.mirror]]
    location = "localhost:5050/ghcr-images"
    insecure = true
  '';
}
