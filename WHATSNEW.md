# OpenMowerOS v2.x — What’s new (2026-05-20)

This document highlights the most relevant changes in the Raspberry Pi 4 NixOS rewrite.


## 🆕 New

- 🧊 A flake-based `NixOS` build now produces the Pi 4 SD-card image.
- 🧩 The repository exposes a single `nixosConfigurations.pi4` target plus a native `packages.aarch64-linux.pi4-sd-image` artifact.
- 📶 Hostname, SSH, Wi-Fi, OpenMower image settings, and mower parameters are now declared in NixOS options.
- 🐳 The OpenMower runtime is managed through declarative OCI containers for `open_mower_ros`, `Mosquitto`, and `OpenMowerApp`.
- 🗂️ Generated runtime configuration now lives under `/etc/openmower`, with persistent data under `/home/openmower`.


## ♻️ Changed / Improved

- 🎯 The initial rewrite is intentionally Pi-4-specific instead of trying to keep a universal multi-board image.
- 🔁 The default build path is native `aarch64-linux`; the flake no longer exposes an `x86_64` SD-image package path.
- 🔐 Wi-Fi provisioning is handled declaratively through NetworkManager instead of first-boot hotspot flows.
- 🧾 The image keeps lightweight revision metadata in `/etc/openmoweros/revision`.


## 🗑️ Removed from the NixOS image

- 🖥️ Dockge is no longer included.
- 🌐 The `ttyd` web terminal is no longer included.
- 📡 Comitup hotspot provisioning is no longer included.
- 📦 Preloaded Docker image archives are no longer part of the build.
- 🪝 Raspberry Pi Imager custom mutation hooks are no longer part of the image flow.


## 🛠️ Under the hood (for the curious)

- 🐧 The image is built from `nixos-25.05` instead of Debian `pi-gen`.
- 📶 Networking is handled by NetworkManager with evaluated Wi-Fi profiles.
- 🧰 Optional legacy features such as internal LAN, OpenOCD, extras, and `openmower-cli` are omitted by default in the first rewrite.
- ✅ CI now runs `nix flake check` and builds the SD image with `nix build` on an ARM runner.


---
If you spot issues or have suggestions, please open an issue or PR. 🙏
