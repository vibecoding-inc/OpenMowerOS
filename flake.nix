{
  description = "OpenMowerOS NixOS SD image for Raspberry Pi 4";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = inputs@{ self, nixpkgs, ... }:
    let
      lib = nixpkgs.lib;
      supportedBuildSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = lib.genAttrs supportedBuildSystems;
      mkPi4System = buildSystem:
        lib.nixosSystem {
          system = buildSystem;
          specialArgs = {
            inherit inputs self;
          };
          modules = [
            ./hosts/pi4/default.nix
            {
              nixpkgs.buildPlatform = buildSystem;
              nixpkgs.hostPlatform = "aarch64-linux";
            }
          ];
        };
      mkEvaluationCheck = buildSystem: name: system:
        nixpkgs.legacyPackages.${buildSystem}.writeText name system.config.system.build.toplevel.drvPath;
      mkPi4WiFiSystem = buildSystem:
        lib.nixosSystem {
          system = buildSystem;
          specialArgs = {
            inherit inputs self;
          };
          modules = [
            ./hosts/pi4/default.nix
            {
              nixpkgs.buildPlatform = buildSystem;
              nixpkgs.hostPlatform = "aarch64-linux";

              openmower.wifi = {
                enable = true;
                ssid = "OpenMower";
                psk = "supersecretpassword";
              };
            }
          ];
        };
      pi4System = mkPi4System "x86_64-linux";
    in
    {
      nixosConfigurations.pi4 = pi4System;

      packages = forAllSystems (
        buildSystem:
        let
          system = mkPi4System buildSystem;
        in
        {
          default = system.config.system.build.sdImage;
          pi4-sd-image = system.config.system.build.sdImage;
        }
      );

      checks = forAllSystems (
        buildSystem:
        let
          system = mkPi4System buildSystem;
          wifiSystem = mkPi4WiFiSystem buildSystem;
        in
        {
          pi4-eval = mkEvaluationCheck buildSystem "pi4-eval" system;
          pi4-wifi-eval = mkEvaluationCheck buildSystem "pi4-wifi-eval" wifiSystem;
        }
      );

      formatter = forAllSystems (buildSystem: nixpkgs.legacyPackages.${buildSystem}.nixfmt-rfc-style);
    };
}