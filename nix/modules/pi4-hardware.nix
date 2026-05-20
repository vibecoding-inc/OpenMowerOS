{ lib, pkgs, ... }:

let
  openmowerFirmwareAddendum = pkgs.writeText "openmower-pi4-config.txt" ''
    [all]
    dtoverlay=disable-bt
    enable_uart=1
    dtoverlay=uart2
    dtoverlay=uart3
    dtoverlay=uart4
    dtoverlay=uart5
  '';
in
{
  boot.kernelParams = lib.mkForce [ "console=tty1" ];

  hardware.enableRedistributableFirmware = true;

  sdImage.populateFirmwareCommands = lib.mkAfter ''
    cat ${openmowerFirmwareAddendum} >> firmware/config.txt
  '';

  systemd.services."serial-getty@ttyAMA0".enable = false;
  systemd.services."serial-getty@ttyAMA1".enable = false;
  systemd.services."serial-getty@ttyAMA2".enable = false;
  systemd.services."serial-getty@ttyAMA3".enable = false;
  systemd.services."serial-getty@ttyAMA4".enable = false;
  systemd.services."serial-getty@ttyS0".enable = false;
  systemd.services."serial-getty@serial0".enable = false;
}