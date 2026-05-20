{ lib, pkgs, self, ... }:

let
  sourceRevision =
    if self ? shortRev then self.shortRev
    else if self ? dirtyShortRev then self.dirtyShortRev
    else if self ? rev then lib.substring 0 8 self.rev
    else if self ? dirtyRev then lib.substring 0 8 self.dirtyRev
    else "dirty";
in
{
  documentation.enable = false;

  environment.etc."openmoweros/revision".text = "${sourceRevision}\n";

  i18n.defaultLocale = "en_GB.UTF-8";
  console.keyMap = "us";
  time.timeZone = "Europe/London";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  services.openssh.settings = {
    KbdInteractiveAuthentication = false;
    PasswordAuthentication = true;
    PermitRootLogin = "no";
  };

  networking.useDHCP = lib.mkDefault true;

  security.sudo.wheelNeedsPassword = false;

  users.users.openmower = {
    isNormalUser = true;
    description = "OpenMower user";
    extraGroups = [ "wheel" ];
    hashedPassword = "$6$openmower$gEPDdfEpeS7gMo02rxb/YHh9tuQkDuBRjgbOBF4/avNc0WhdVk/m8N1fOybgjImID/j2lBzFWKLY4bH31Rbw4/";
  };

  environment.systemPackages = with pkgs; [
    gitMinimal
    vim
  ];
}