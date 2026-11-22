# Hermes tools

Hermes uses SearXNG for its native `web_search` tool over the private Podman
network (`http://searxng:8080`). JSON search is enabled in the SearXNG module.
Keyless web-provider fallback is disabled; SearXNG is search-only and does not
provide `web_extract`. The separate AnySearch credential remains available to
Hermes but does not replace this search selection.

The `image_generate` tool used the laptop GPU ComfyUI service through the
`comfyui-local` Hermes provider plugin. It has been removed: the laptop no
longer runs ComfyUI and no image generation backend is declared.

On each service start, `hermes-seed-config` merges these tool selections into
`/persist/hermes/config.yaml`, preserving other config values. Its YAML writer
may reformat the file on the first start. To verify after deploying on the
server, run `podman exec hermes hermes plugins list`, try a search in a new
Hermes session, and inspect `journalctl -u hermes.service -f` for errors. Test
SearXNG directly with
`podman exec hermes curl 'http://searxng:8080/search?q=test&format=json'`.
