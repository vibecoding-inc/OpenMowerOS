{
  description = "OpenMowerOS NixOS SD image for Raspberry Pi 4";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = inputs@{ self, nixpkgs, ... }:
    let
      lib = nixpkgs.lib;
      supportedCheckSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllCheckSystems = lib.genAttrs supportedCheckSystems;
      mkPi4System = extraModules:
        lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = {
            inherit inputs self;
          };
          modules = [ ./hosts/pi4/default.nix ] ++ extraModules;
        };
      mkEvaluationCheck = checkSystem: name: system:
        nixpkgs.legacyPackages.${checkSystem}.writeText name system.config.system.build.toplevel.drvPath;
      pi4System = mkPi4System [ ];
      pi4WiFiSystem = mkPi4System [
        {
          openmower.wifi = {
            enable = true;
            ssid = "OpenMower";
            psk = "supersecretpassword";
          };
        }
      ];
    in
    {
      nixosConfigurations.pi4 = pi4System;

      packages.aarch64-linux = {
        default = pi4System.config.system.build.sdImage;
        pi4-sd-image = pi4System.config.system.build.sdImage;
      };

      checks = forAllCheckSystems (checkSystem: {
        pi4-eval = mkEvaluationCheck checkSystem "pi4-eval" pi4System;
        pi4-wifi-eval = mkEvaluationCheck checkSystem "pi4-wifi-eval" pi4WiFiSystem;
      });

      formatter = forAllCheckSystems (checkSystem: nixpkgs.legacyPackages.${checkSystem}.nixfmt-rfc-style);
    };
}