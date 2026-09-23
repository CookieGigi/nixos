# Hermes tools

Hermes uses SearXNG for its native `web_search` tool over the private Podman
network (`http://searxng:8080`). JSON search is enabled in the SearXNG module.
Keyless web-provider fallback is disabled; SearXNG is search-only and does not
provide `web_extract`. The separate AnySearch credential remains available to
Hermes but does not replace this search selection.

The `image_generate` tool uses the local ComfyUI CPU service through the
`comfyui-local` Hermes provider plugin. It submits the same SD 1.5 workflow
used by Open WebUI and saves the resulting PNG under Hermes' persistent
`cache/images/` directory for gateway delivery. This workflow supports only
text-to-image; editing and reference images are not supported. CPU generation
may take several minutes, and requests time out after ten minutes.

On each service start, `hermes-seed-config` merges these tool selections into
`/persist/hermes/config.yaml`, preserving other config values. Its YAML writer
may reformat the file on the first start. To verify after deploying on the
server, run `podman exec hermes hermes plugins list`, try a search and an image
request in a new Hermes session, and inspect `journalctl -u hermes.service -f`
and `journalctl -u comfyui.service -f` if either fails. Test SearXNG directly
with `podman exec hermes curl 'http://searxng:8080/search?q=test&format=json'`.
