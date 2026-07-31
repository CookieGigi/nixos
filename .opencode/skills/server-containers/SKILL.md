---
name: server-containers
description: Pattern for organizing server container services in modules/server/containers/<service>/
license: MIT
compatibility: opencode
metadata:
  audience: maintainers
  domain: system-administration
---

## What I do
- Define the standard directory structure for server container services
- Show how to separate concerns into `default.nix`, `container(s).nix`, and `users.nix`
- Document the Quadlet container definition patterns used on the server
- Guide adding a new containerized service

## Directory structure

Each service lives in its own directory under `modules/server/containers/`:

```
containers/
├── <service>/
│   ├── default.nix          # Aggregator: imports container(s).nix + users.nix
│   ├── container.nix        # (or containers.nix) Service definition: containers, networks, volumes, firewall
│   └── users.nix            # Service users, groups, tmpfiles, ownership migration
```

## File responsibilities

### `default.nix`
- Pure aggregator — imports `container.nix` (or `containers.nix`) and `users.nix`
- No logic, just wiring:
  ```nix
  {imports = [./containers.nix ./users.nix];}
  ```

### `container(s).nix`
- Quadlet container definitions (`environment.etc."containers/systemd/<name>.container"`)
- Podman container definitions (`virtualisation.oci-containers.containers.<name>`)
- Networks, volumes, sops secrets, firewall ports
- Derivation-based images (e.g., Proton Drive custom image)
- NO user declarations — those go in `users.nix`

### `users.nix`
- Dedicated service users (`users.users.<name>` with `isSystemUser = true`)
- Service-specific groups (`users.groups.<name>`)
- Shared access groups (e.g., `media`, `ai`) with `extraGroups`
- `systemd.tmpfiles.rules` for service-owned directories
- `system.activationScripts.<service>-ownership-migration` to fix permissions on deploy

## Conventions

1. **One user per service** — do not run containers as root. Each container gets its own `uid`.
2. **Shared groups for cross-service access** — e.g., `media` group (gid 200) lets Immich read `/media/pictures` while `cookiegigi` writes to it.
3. **Inter-service groups** — e.g., `immich-services` (gid 201) groups `immich` + `immich-db` so the DB secret can be `mode = "0440"` and `group = "immich-services"`.
4. **tmpfiles rules in users.nix** — service data directories (e.g., `/persist/immich/library`) are declared where the user is defined.
5. **Ownership migration activation scripts** — always include an activation script that `chown`s existing directories on deploy, so permission changes apply immediately.

## Adding a new containerized service

1. Create `modules/server/containers/<service>/` with the three files
2. In `users.nix`:
   - Pick a unique `uid` (check existing ones to avoid collisions)
   - Create the service user and group
   - Add `extraGroups` for any shared access (e.g., `"media"`)
   - Add tmpfiles rules for `/persist/<service>/...`
   - Add ownership migration activation script
3. In `container.nix`:
   - Define the Quadlet or Podman container
   - Set `User=<uid>` and `Group=<gid>` in the container spec
   - Mount volumes with correct paths
   - Open firewall ports if needed
4. In `default.nix`: import both
5. Add `./containers/<service>` to `modules/server/default.nix`
6. Run `nix fmt` and rebuild

## Example: minimal service

```nix
# containers/myapp/default.nix
{imports = [./container.nix ./users.nix];}

# containers/myapp/users.nix
{pkgs, ...}: {
  users.users.myapp = {
    isSystemUser = true;
    uid = 400;
    group = "myapp";
    extraGroups = ["media"];
  };
  users.groups.myapp = {};

  systemd.tmpfiles.rules = [
    "d /persist/myapp/data 0755 myapp myapp -"
  ];

  system.activationScripts.myapp-ownership-migration = ''
    if [ -d /persist/myapp/data ]; then
      ${pkgs.coreutils}/bin/chown -R myapp:myapp /persist/myapp/data
    fi
  '';
}

# containers/myapp/container.nix
{
  environment.etc."containers/systemd/myapp.container".text = ''
    [Container]
    Image=docker.io/myapp:latest
    User=400
    Group=400
    Volume=/persist/myapp/data:/data

    [Service]
    Restart=always
  '';
}
```

## Existing services

| Service | UID | GID | Shared groups | Container type |
|---------|-----|-----|---------------|----------------|
| immich | 300 | 300 | media, immich-services | Quadlet |
| immich-redis | 302 | 302 | — | Quadlet |
| immich-db | 999 | 999 | immich-services | Quadlet |
| llama | 303 | 303 | ai | Podman (oci-containers) |

## Key rules
- `storage-layout.nix` is for **shared infrastructure only** (media group, general tmpfiles)
- Never put service-specific users or tmpfiles in `storage-layout.nix`
- Always run `nix fmt` before committing
- Check `nix flake check` before rebuilding
