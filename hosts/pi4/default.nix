{ lib, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
    ../../nix/modules/base.nix
    ../../nix/modules/networking.nix
    ../../nix/modules/openmower.nix
    ../../nix/modules/pi4-hardware.nix
  ];

  openmower = {
    hostname = lib.mkDefault "openmower";
    ssh.enable = lib.mkDefault true;
    wifi.enable = lib.mkDefault false;
    stack = {
      mower = lib.mkDefault "CUSTOM";
      firmware = lib.mkDefault "yardforce";
    };
  };

  image.baseName = "OpenMowerOS-pi4";
  sdImage.compressImage = false;

  system.stateVersion = "25.05";
}