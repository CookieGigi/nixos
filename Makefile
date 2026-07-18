# NixOS rebuild helpers
# Run any target with: make <target>

HOST = xps

.PHONY: switch build check fmt iso disko edit-secrets quickshell-dev update upgrade server-switch

# Rebuild and activate the system configuration
switch:
	sudo nixos-rebuild switch --flake .#$(HOST)

# Build the system configuration without activating it
build:
	sudo nixos-rebuild build --flake .#$(HOST)

# Rebuild and activate the server remotely over SSH
# (builds locally on the xps, copies the closure, activates on the server;
# prompts for the server's sudo password)
server-switch:
	nixos-rebuild switch --flake .#server --target-host server --ask-sudo-password

# Verify the flake for errors
check:
	nix flake check

# Format all .nix files with alejandra
fmt:
	nix fmt

# Build the installation ISO
iso:
	nix build .#nixosConfigurations.$(HOST)-iso.config.system.build.isoImage

# Run disk partitioning (installation only)
disko:
	sudo nix run .#disko -- --mode disko ./hosts/$(HOST)/disko.nix

# Open the encrypted secrets file for editing (via sops)
edit-secrets:
	sudo nix run .#edit-secrets

# Update flake inputs (nixpkgs, home-manager, etc.) — bumps flake.lock
update:
	nix flake update

# Update flake inputs and rebuild+activate the system
upgrade: update switch

# Run quickshell bar from repo source for instant hot-reload during development
quickshell-dev:
	@echo "Killing any running quickshell…"
	@pkill qs 2>/dev/null || true
	@echo "Launching quickshell from repo source (hot-reload enabled)…"
	qs -p ./modules/home/cookiegigi/programs/quickshell/shell.qml
