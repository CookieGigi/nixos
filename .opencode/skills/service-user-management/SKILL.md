---
name: service-user-management
description: Pattern for dedicated service users, shared groups, tmpfiles, and ownership migration in NixOS
license: MIT
compatibility: opencode
metadata:
  audience: maintainers
  domain: system-administration
---

## What I do
- Define the pattern for creating dedicated service users and groups
- Show how to use shared groups for cross-service and user-service access
- Document tmpfiles rules and ownership migration activation scripts
- Guide migrating from root-owned directories to service-owned directories

## The problem

Running all containers as root is insecure. But giving each service its own user creates access control questions:
- How does the human user (`cookiegigi`) write to `/media/`?
- How do multiple services read the same media library?
- How does one service (e.g., Immich server) access another service's secret (e.g., DB password)?

## The solution

Use a **three-layer permission model**:

1. **Dedicated service users** — one per container, minimal privileges
2. **Shared functional groups** — cross-service access (e.g., `media`, `ai`)
3. **Inter-service groups** — tightly-coupled service pairs (e.g., `immich-services`)

## Pattern

### 1. Service user declaration

```nix
users.users.<service> = {
  isSystemUser = true;
  uid = <unique-id>;
  group = "<service>";
  extraGroups = ["media"];  # Shared access groups
};
users.groups.<service> = {};
```

Rules:
- `isSystemUser = true` — no login, no home directory
- Pick a unique `uid` — check all existing service UIDs to avoid collisions
- `group` should match the username (primary group)
- `extraGroups` lists shared groups for cross-access

### 2. Shared groups

```nix
users.groups.media = {
  gid = 200;
  members = ["cookiegigi" "immich"];
};
```

- `gid` should be unique and consistent across the config
- `members` includes both human users and service users that need access
- Use `extraGroups` on service users to grant membership

### 3. Inter-service groups

For tightly-coupled services that share secrets:

```nix
users.groups.immich-services = {
  gid = 201;
  members = ["immich" "immich-db"];
};
```

Use this for sops secrets:
```nix
sops.secrets."immich-db-password" = {
  owner = "root";
  group = "immich-services";
  mode = "0440";  # Owner read + group read
};
```

### 4. tmpfiles rules

Always declare directories that must exist on boot:

```nix
systemd.tmpfiles.rules = [
  "d /persist/<service>/data 0755 <user> <group> -"
];
```

The `<type>` field meanings:
- `d` — create directory if it doesn't exist, set permissions
- `D` — create directory, clean up contents on boot (dangerous!)
- `Z` — recursively fix ownership (use in activation scripts, not tmpfiles)

### 5. Ownership migration activation script

When changing ownership from root to a service user, existing files won't be updated automatically. Add an activation script:

```nix
system.activationScripts.<service>-ownership-migration = ''
  echo "[<service>] Migrating ownership..."

  if [ -d /persist/<service>/data ]; then
    ${pkgs.coreutils}/bin/chown -R <user>:<group> /persist/<service>/data
    echo "[<service>] /persist/<service>/data -> <user>:<group>"
  fi
'';
```

This runs on every `nixos-rebuild switch`, ensuring permissions stay correct.

## UID/GID allocation

Reserve ranges to avoid collisions:

| Range | Purpose |
|-------|---------|
| 200-299 | Shared groups |
| 300-999 | Service users and their primary groups |

Current allocations:

| Name | ID | Type |
|------|-----|------|
| media | 200 | shared group |
| immich-services | 201 | shared group |
| ai | 202 | shared group |
| immich | 300 | user+group |
| immich-redis | 302 | user+group |
| immich-db | 999 | user+group |
| llama | 303 | user+group |

## Migration from root-owned directories

When switching a service from root to a dedicated user:

1. **Create the user and group** in `users.nix`
2. **Update tmpfiles rules** to use the new user/group
3. **Update container definitions** to set `User=<uid>` and `Group=<gid>`
4. **Add ownership migration activation script** to `chown` existing data
5. **Update shared group memberships** if the service needs access to `/media/`
6. **Rebuild and verify** containers start correctly

## Example: complete service user setup

```nix
# users.nix
{pkgs, ...}: {
  # Shared group
  users.groups.media = {
    gid = 200;
    members = ["cookiegigi" "myapp"];
  };

  # Service user
  users.users.myapp = {
    isSystemUser = true;
    uid = 400;
    group = "myapp";
    extraGroups = ["media"];
  };
  users.groups.myapp = {};

  # Directories
  systemd.tmpfiles.rules = [
    "d /persist/myapp/data 0755 myapp myapp -"
    "d /persist/myapp/cache 0755 myapp myapp -"
  ];

  # Migration
  system.activationScripts.myapp-ownership-migration = ''
    echo "[myapp] Migrating ownership..."
    for dir in /persist/myapp/data /persist/myapp/cache; do
      if [ -d "$dir" ]; then
        ${pkgs.coreutils}/bin/chown -R myapp:myapp "$dir"
        echo "[myapp] $dir -> myapp:myapp"
      fi
    done
  '';
}
```

## Common mistakes

1. **Forgetting activation scripts** — tmpfiles only creates directories; it doesn't `chown` existing trees
2. **UID collisions** — always check existing UIDs before adding a new service
3. **World-readable permissions** — use shared groups (`2775`) instead of `0755` for multi-user access
4. **Missing `extraGroups`** — the service user must be in the shared group to access group-owned files
5. **Container user mismatch** — Quadlet `User=` must match the NixOS `uid`, not just the username

## Verification checklist

After adding a new service user:
- [ ] `id <user>` shows correct uid, gid, and extraGroups
- [ ] `getent group <shared-group>` shows the service user as a member
- [ ] Container starts without permission errors
- [ ] Service can read/write its own data directories
- [ ] Service can read shared directories (e.g., `/media/*`)
- [ ] `nix fmt` passes
- [ ] `nix flake check` passes
