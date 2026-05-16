# nixos-hardware — Dell XPS 15 9530 Integration

## Overview

The `nixos-hardware` repository is a community-maintained collection of NixOS modules that provide tested, hardware-specific configurations for various laptops, desktops, and devices. This repository abstracts away the complexity of researching kernel parameters, firmware settings, and driver configurations by shipping ready-made modules.

This document details what the `dell-xps-15-9530` module from `nixos-hardware` does for this PC, and how it integrates with the existing NixOS flake.

---

## How It Is Integrated

In `flake.nix`, the `nixos-hardware` input is declared and the specific module is imported into the `xps` system configuration:

```nix
# flake.nix
inputs = {
  nixos-hardware = {
    url = "github:NixOS/nixos-hardware/master";
  };
};

outputs = { self, nixpkgs, nixos-hardware, ... }: {
  nixosConfigurations.xps = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      # ... other modules ...
      nixos-hardware.nixosModules.dell-xps-15-9530
      # ...
    ];
  };
};
```

**Note:** The `xps-iso` configuration does **not** import this module, as the live environment has different hardware detection needs.

---

## What the Module Does

The `dell-xps-15-9530` module is not just a single file — it is a **composition** of multiple smaller modules that collectively configure the entire hardware stack. Here is the complete breakdown:

### 1. CPU & Firmware (Intel)

**Source:** `common/cpu/intel`

| Setting | Value | Purpose |
|---------|-------|---------|
| `hardware.cpu.intel.updateMicrocode` | `true` (if `enableRedistributableFirmware` is on) | Applies Intel microcode updates to fix CPU vulnerabilities and errata. |

**What it means for this PC:** The 13th Gen Intel Core i9-13900H receives security patches and stability fixes via microcode updates delivered through the NixOS firmware infrastructure.

---

### 2. Intel Graphics (iGPU)

**Source:** `common/gpu/intel`

| Setting | Value | Purpose |
|---------|-------|---------|
| `boot.initrd.kernelModules` | `["i915"]` | Loads the Intel GPU driver early in the boot process (initramfs). |
| `hardware.graphics.extraPackages` | `intel-vaapi-driver`, `intel-media-driver`, `intel-compute-runtime`, `vpl-gpu-rt` | Enables hardware-accelerated video decode/encode (VAAPI), media processing, and OpenCL compute. |
| `hardware.graphics.extraPackages32` | 32-bit variants of the above | Enables hardware acceleration for 32-bit applications (e.g., Steam, older games). |
| `hardware.intelgpu.driver` | `"i915"` | Uses the mature i915 driver. The newer `xe` driver is available but requires kernel >= 6.8. |
| `hardware.intelgpu.loadInInitrd` | `true` | Confirms the GPU module is loaded at stage 1 boot. |
| `hardware.intelgpu.vaapiDriver` | `null` (uses both drivers) | Tries both VAAPI drivers for maximum compatibility. |

**What it means for this PC:** The integrated Intel GPU is fully configured for hardware-accelerated video playback, screen compositing, and media workloads. The NVIDIA dGPU can be powered off when not needed, saving battery.

---

### 3. NVIDIA Discrete GPU (dGPU)

**Source:** `dell/xps/15-9530/nvidia/default.nix`

This sub-module configures the NVIDIA GeForce RTX 4070 Laptop GPU using **NVIDIA PRIME Offload**.

| Setting | Value | Purpose |
|---------|-------|---------|
| `services.xserver.videoDrivers` | `["nvidia"]` | Loads the proprietary NVIDIA driver for the dGPU. |
| `hardware.nvidia.prime.intelBusId` | `"PCI:0:2:0"` | PCI bus ID of the Intel iGPU. |
| `hardware.nvidia.prime.nvidiaBusId` | `"PCI:1:0:0"` | PCI bus ID of the NVIDIA dGPU. |
| `hardware.nvidia.prime.offload.enable` | `true` | Enables PRIME Offload: the NVIDIA GPU is off by default; applications must explicitly request it. |
| `hardware.nvidia.prime.offload.enableOffloadCmd` | `true` | Provides the `nvidia-offload` shell command to easily run apps on the dGPU. |
| `hardware.nvidia.open` | `true` (if supported by package) | Prefers the open-source NVIDIA kernel module if available. |

**How to use the NVIDIA GPU:**

```bash
# Run a specific application on the NVIDIA GPU
nvidia-offload glxgears
nvidia-offload nix-shell -p glxinfo --run 'glxinfo | grep renderer'
```

**What it means for this PC:** The powerful RTX 4070 is available on demand for gaming, CUDA workloads, or GPU-intensive applications, but it does not waste battery power when idle. The desktop and most apps run on the efficient Intel iGPU.

---

### 4. Thermal Management

**Source:** `dell/xps/15-9530/default.nix`

| Setting | Value | Purpose |
|---------|-------|---------|
| `services.thermald.enable` | `true` | Enables Intel's thermal daemon to prevent CPU overheating and thermal throttling. |

**What it means for this PC:** The thin XPS 15 chassis benefits from active thermal management. `thermald` monitors temperatures and applies cooling policies to keep performance consistent and prevent hardware damage.

---

### 5. Power Management (Laptop)

**Source:** `common/pc/laptop`

| Setting | Value | Purpose |
|---------|-------|---------|
| `services.tlp.enable` | `true` (if `power-profiles-daemon` is disabled) | Enables the TLP power management daemon for laptops. |

**What it means for this PC:** TLP applies aggressive power-saving settings on battery (CPU frequency scaling, PCIe ASPM, USB autosuspend, etc.) and switches to performance mode on AC power. This extends battery life significantly.

---

### 6. WiFi (Intel AX211)

**Source:** `dell/xps/15-9530/default.nix`

| Setting | Value | Purpose |
|---------|-------|---------|
| `boot.extraModprobeConfig` | `options iwlwifi power_save=1` | Enables power saving for the Intel WiFi 6E AX211 card. |

**Historical context:** Earlier versions of this module disabled WiFi 6 (802.11ax) due to kernel driver bugs causing crashes and slow speeds (see [kernel bug 213381](https://bugzilla.kernel.org/show_bug.cgi?id=213381)). The current configuration only enables power saving, as the 802.11ax issues have been resolved in newer kernels.

**What it means for this PC:** The AX211 WiFi card works reliably with power saving enabled, extending battery life without sacrificing wireless performance.

---

### 7. SSD Optimizations

**Source:** `common/pc/ssd`

| Setting | Value | Purpose |
|---------|-------|---------|
| `services.fstrim.enable` | `true` | Enables periodic TRIM for SSDs. |

**What it means for this PC:** The 1TB NVMe SSD receives weekly TRIM commands, which inform the drive which blocks are no longer in use. This maintains write performance and extends SSD lifespan.

---

### 8. Optional: Battery Saver Specialisation

**Source:** `common/gpu/nvidia/prime.nix`

The module optionally supports a **NixOS specialisation** that completely disables the NVIDIA GPU for maximum battery life.

To enable it, set:

```nix
hardware.nvidia.primeBatterySaverSpecialisation = true;
```

This creates a boot entry labeled `battery-saver` that:
- Blacklists all NVIDIA kernel modules (`nouveau`, `nvidia`, `nvidia_drm`, `nvidia_modeset`)
- Removes NVIDIA PCI devices via udev rules
- Forces the system to use only the Intel iGPU

**What it means for this PC:** When you know you will be away from power for an extended period, you can boot into the `battery-saver` configuration to completely eliminate the NVIDIA GPU's power draw, potentially adding hours of battery life.

---

## Complete Dependency Tree

```
dell-xps-15-9530
├── common/cpu/intel
│   ├── common/cpu/intel/cpu-only.nix    → microcode updates
│   └── common/gpu/intel                 → iGPU driver, VAAPI, media, OpenCL
├── common/pc/laptop
│   └── common/pc                        → firmware blacklist safety
│   └── services.tlp                     → laptop power management
├── common/pc/ssd                        → fstrim for NVMe
├── services.thermald                    → thermal management
└── boot.extraModprobeConfig             → iwlwifi power_save

# Optional NVIDIA branch:
dell-xps-15-9530/nvidia
├── dell-xps-15-9530 (base above)
├── common/gpu/nvidia/prime
│   ├── common/gpu/nvidia                → xserver videoDrivers
│   ├── prime.offload.enable             → offload by default
│   └── specialisation battery-saver     → disable NVIDIA entirely
└── common/gpu/nvidia/ada-lovelace       → open driver preference
```

---

## What This PC Gets (Summary)

| Component | Benefit |
|-----------|---------|
| **CPU** | Microcode updates for security and stability |
| **Intel iGPU** | Full hardware acceleration for video, media, and compute |
| **NVIDIA RTX 4070** | Available on-demand via `nvidia-offload`; does not drain battery when idle |
| **Thermals** | Active thermal management prevents throttling and overheating |
| **Power** | TLP optimizes battery/AC profiles automatically |
| **WiFi** | Intel AX211 with power saving; stable 802.11ax support |
| **SSD** | TRIM enabled for sustained performance and longevity |
| **Boot options** | Optional battery-saver mode to disable NVIDIA completely |

---

## References

- [nixos-hardware repository](https://github.com/NixOS/nixos-hardware)
- [Dell XPS 15 9530 module source](https://github.com/NixOS/nixos-hardware/tree/master/dell/xps/15-9530)
- [NixOS Wiki — NVIDIA](https://wiki.nixos.org/wiki/NVIDIA)
- [NixOS Wiki — Intel Graphics](https://wiki.nixos.org/wiki/Intel_Graphics)
- [NixOS Specialisations](https://wiki.nixos.org/wiki/Specialisation)
