{ config, lib, ... }:

let
  cfg = config.openmower;
  wifiProfileName = "openmower-wifi";
in
{
  options.openmower = {
    hostname = lib.mkOption {
      type = lib.types.str;
      default = "openmower";
      description = "System hostname for the OpenMower appliance.";
    };

    ssh.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether SSH access should be enabled for the appliance.";
    };

    wifi = {
      enable = lib.mkEnableOption "declarative Wi-Fi provisioning" // {
        default = true;
      };

      interface = lib.mkOption {
        type = lib.types.str;
        default = "wlan0";
        description = "Wireless interface used for the primary OpenMower Wi-Fi uplink.";
      };

      ssid = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Wi-Fi SSID configured at evaluation time.";
      };

      psk = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Wi-Fi passphrase configured at evaluation time.";
      };

      country = lib.mkOption {
        type = lib.types.strMatching "[A-Z][A-Z]";
        default = "DE";
        description = "Two-letter Wi-Fi regulatory domain.";
      };

      hidden = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether the configured SSID is hidden.";
      };
    };

    features.internalLan.enable = lib.mkEnableOption "legacy internal-LAN provisioning";
  };

  config = {
    assertions = [
      {
        assertion = (!cfg.wifi.enable) || (cfg.wifi.ssid != "" && cfg.wifi.psk != "");
        message = "`openmower.wifi.ssid` and `openmower.wifi.psk` must be set when Wi-Fi is enabled.";
      }
    ];

    networking.hostName = cfg.hostname;

    networking.networkmanager = {
      enable = true;
      ensureProfiles.profiles = lib.mkIf cfg.wifi.enable {
        "${wifiProfileName}" = {
          connection = {
            id = wifiProfileName;
            type = "wifi";
            "interface-name" = cfg.wifi.interface;
            autoconnect = true;
            permissions = "";
          };
          wifi = {
            mode = "infrastructure";
            ssid = cfg.wifi.ssid;
            hidden = cfg.wifi.hidden;
          };
          wifi-security = {
            auth-alg = "open";
            key-mgmt = "wpa-psk";
            psk = cfg.wifi.psk;
          };
          ipv4.method = "auto";
          ipv6.method = "auto";
        };
      };
    };

    services.openssh.enable = cfg.ssh.enable;

    networking.wireless.enable = false;

    boot.extraModprobeConfig = lib.mkIf cfg.wifi.enable ''
      options cfg80211 ieee80211_regdom=${cfg.wifi.country}
    '';

    warnings = lib.optional cfg.features.internalLan.enable ''
      `openmower.features.internalLan.enable` is not implemented in the initial Pi 4 rewrite yet.
      The old `stage-openmower/25-lan` behavior remains intentionally omitted by default.
    '';
  };
}