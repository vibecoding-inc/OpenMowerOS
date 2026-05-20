# OpenMowerOS

[![OpenMower header](.github/img/open_mower_header.jpg)](https://github.com/ClemensElflein/OpenMower)

This repository contains the flake-based OpenMowerOS image for running the [OpenMower](https://github.com/ClemensElflein/OpenMower) project on a Raspberry Pi 4.

➡️ What’s new in the latest release? See [WHATSNEW.md](./WHATSNEW.md).

## Reference/Default Information

- **target board**: Raspberry Pi 4
- **hostname**: `openmower` (default)
- **username**: `openmower` (fixed)
- **password**: `openmower` ***CHANGE IT! (use `passwd` for that)***
- **ssh**: enabled by default
- **Wi-Fi**: configured declaratively from NixOS options when enabled

***

## How to Get Started

Tip: Click a section title to expand/collapse.

<details>
<summary><b>Build and flash the Pi 4 image</b></summary>

1. Build the SD image on an `aarch64-linux` machine or on a host that executes `aarch64-linux` builds natively via `binfmt`:
   ```sh
   nix build .#packages.aarch64-linux.pi4-sd-image
   ```
2. Copy the resulting `.img` artifact to your SD card with your preferred flashing tool.
3. If you want machine-specific values, import an additional local Nix module and set `openmower.hostname`, `openmower.wifi`, `openmower.stack`, and `openmower.params` there before building.

</details>

<details>
<summary><b>First boot and network setup</b></summary>

1. After flashing the image, insert the SD card into the mower’s Raspberry Pi 4 and power it on.
2. Wait for the first boot to finish, then connect via SSH using `ssh openmower@openmower` or the hostname configured in `openmower.hostname`.
3. If `openmower.wifi.enable = true`, the configured SSID/PSK is applied declaratively through NetworkManager during the image build.
4. If Wi-Fi is disabled, connect through Ethernet or any other network you configured in NixOS.
5. Change the default password after the first login with `passwd`.

 </details>



<details>
<summary><b>Manage the OpenMower runtime</b></summary>

1. The runtime is defined declaratively by `nix/modules/openmower.nix` and started as NixOS-managed OCI containers.
2. The three main services are `open_mower_ros`, `Mosquitto`, and `OpenMowerApp`.
3. Generated configuration lives under `/etc/openmower`, while persistent state lives under `/home/openmower`.
4. Open the web UI at `http://openmower:8080` or the configured hostname once the system is up.
5. Adjust mower-specific values by editing `openmower.stack` and `openmower.params` in Nix, then rebuild the image.

</details>

