{ config, lib, pkgs, ... }:

let
  cfg = config.openmower;
  yamlFormat = pkgs.formats.yaml { };

  paramsFile = yamlFormat.generate "mower-params.yaml" cfg.params;
  stackEnvFile = pkgs.writeText "openmower-stack.env" ''
    VERSION=${cfg.stack.version}
    HARDWARE_PLATFORM=${toString cfg.stack.hardwarePlatform}
    MOWER=${cfg.stack.mower}
    FIRMWARE=${cfg.stack.firmware}
    ESC_TYPE=${cfg.stack.escType}
    DEBUG=${if cfg.stack.debug then "True" else "False"}
    HOSTNAME=${cfg.hostname}.local
  '';
  mosquittoConfig = pkgs.writeText "mosquitto.conf" ''
    log_type notice
    log_dest stdout

    listener 1883
    allow_anonymous true

    listener 9001 0.0.0.0
    protocol websockets
    allow_anonymous true
  '';
in
{
  options.openmower = {
    enable = lib.mkEnableOption "the OpenMower runtime stack" // {
      default = true;
    };

    stack = {
      version = lib.mkOption {
        type = lib.types.str;
        default = "latest";
        description = "Tag for the `open_mower_ros` container image.";
      };

      hardwarePlatform = lib.mkOption {
        type = lib.types.int;
        default = 2;
        description = "OpenMower hardware platform selector exposed to the ROS container.";
      };

      mower = lib.mkOption {
        type = lib.types.str;
        default = "CHANGE_ME";
        description = "OpenMower mower profile name.";
      };

      firmware = lib.mkOption {
        type = lib.types.str;
        default = "CHANGE_ME";
        description = "OpenMower firmware/robot target name.";
      };

      escType = lib.mkOption {
        type = lib.types.str;
        default = "xesc_mini";
        description = "ESC type exposed to the ROS container.";
      };

      debug = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether the ROS stack should run in debug mode.";
      };

      rosImage = lib.mkOption {
        type = lib.types.str;
        default = "ghcr.io/clemenselflein/open_mower_ros";
        description = "Base OCI image repository for the OpenMower ROS stack.";
      };

      appImage = lib.mkOption {
        type = lib.types.str;
        default = "ghcr.io/clemenselflein/openmowerapp:latest";
        description = "OCI image for the OpenMower web application.";
      };

      mosquittoImage = lib.mkOption {
        type = lib.types.str;
        default = "eclipse-mosquitto:2";
        description = "OCI image for the MQTT broker.";
      };
    };

    params = lib.mkOption {
      type = yamlFormat.type;
      default = {
        ll = {
          bind_ip = "172.16.78.1";
          services = {
            sound = {
              language = "en";
              volume = -1;
            };
            gps = {
              baud_rate = 921600;
              protocol = "UBX";
              datum_lat = 0.0;
              datum_long = 0.0;
            };
          };
        };
        ntrip_client = {
          host = "";
          port = 2101;
          username = "";
          password = "";
          mountpoint = "";
        };
        mower_logic = {
          automatic_mode = 0;
          docking_approach_distance = 1.0;
          docking_extra_time = 1.0;
          docking_retry_count = 3;
          docking_redock = false;
          outline_overlap_count = 1;
          mow_angle_offset = 0;
          mow_angle_offset_is_absolute = false;
          mow_angle_increment = 0;
          gps_wait_time = 5.0;
          gps_timeout = 5.0;
          rain_mode = 0;
          rain_delay_minutes = 30;
          rain_check_seconds = 20;
          undock_distance = 1.0;
          undock_angled_distance = 2.0;
          undock_angle = 0.0;
          undock_fixed_angle = false;
          undock_use_curve = true;
          enable_mower = false;
        };
      };
      description = "Rendered `mower_params.yaml` content for the OpenMower runtime.";
    };

    features.openmowerCli.enable = lib.mkEnableOption "packaging `openmower-cli` in the image";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.stack.mower != "CHANGE_ME";
        message = "`openmower.stack.mower` must be set to a real mower profile when the runtime is enabled.";
      }
      {
        assertion = cfg.stack.firmware != "CHANGE_ME";
        message = "`openmower.stack.firmware` must be set to a real firmware target when the runtime is enabled.";
      }
    ];

    warnings = lib.optional cfg.features.openmowerCli.enable ''
      `openmower-cli` is intentionally omitted from the initial NixOS rewrite until it is packaged in a pinned, reproducible way.
    '';

    virtualisation = {
      docker.enable = true;
      oci-containers = {
        backend = "docker";
        containers = {
          open_mower_ros = {
            image = "${cfg.stack.rosImage}:${cfg.stack.version}";
            dependsOn = [ "Mosquitto" ];
            environment = {
              RECORDINGS_PATH = "/data/recordings";
              PARAMS_PATH = "/data/params";
              ROS_HOME = "/data/ros";
            };
            environmentFiles = [ stackEnvFile ];
            volumes = [
              "/dev:/dev"
              "/home/openmower/ros:/data/ros"
              "/home/openmower/recordings:/data/recordings"
              "/home/openmower/params:/data/params"
            ];
            workdir = "/home/openmower";
            extraOptions = [
              "--network=host"
              "--privileged"
            ];
          };

          Mosquitto = {
            image = cfg.stack.mosquittoImage;
            user = "1883:1883";
            ports = [
              "1883:1883"
              "9001:9001"
            ];
            volumes = [
              "${mosquittoConfig}:/mosquitto/config/mosquitto.conf:ro"
            ];
          };

          OpenMowerApp = {
            image = cfg.stack.appImage;
            ports = [ "8080:8080" ];
          };
        };
      };
    };

    environment.etc."openmower/mower_params.yaml".source = paramsFile;
    environment.etc."openmower/stack.env".source = stackEnvFile;
    environment.etc."openmower/mosquitto.conf".source = mosquittoConfig;

    systemd.tmpfiles.rules = [
      "d /home/openmower 0775 openmower openmower -"
      "d /home/openmower/ros 0775 openmower openmower -"
      "d /home/openmower/recordings 0775 openmower openmower -"
      "d /home/openmower/params 0775 openmower openmower -"
      "d /data 0775 openmower openmower -"
      "L+ /data/ros - - - - /home/openmower/ros"
      "L+ /home/openmower/params/mower_params.yaml - - - - /etc/openmower/mower_params.yaml"
    ];
  };
}