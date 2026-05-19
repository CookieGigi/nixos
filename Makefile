# NixOS rebuild helpers
# Run any target with: make <target>

HOST = xps

.PHONY: switch build check fmt iso edit-secrets

# Rebuild and activate the system configuration
switch:
	sudo nixos-rebuild switch --flake .#$(HOST)

# Build the system configuration without activating it
build:
	sudo nixos-rebuild build --flake .#$(HOST)

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
