{ config, pkgs, lib, nixos-hardware, nixpkgs, ... }:

{
  imports = [ ./hardware-configuration.nix "${nixos-hardware}/raspberry-pi/4" ];

  custom = {
    enable = true;
    tailscale = true;
    gui.sway = true;
    autoUpgrade.enable = true;
    homeManager.enable = true;
  };

  home-manager.users.${config.custom.username}.config.custom.machineColour =
    "red";

  networking.networkmanager.enable = true;

  services.journald.extraConfig = ''
    SystemMaxUse=4G
  '';

  services.caddy = {
    enable = true;
    virtualHosts."http://shrew" = {
      listenAddresses = [ "100.64.0.6" ];
      extraConfig = "reverse_proxy http://127.0.0.1:15606";
    };
  };

  environment.systemPackages = with pkgs; [ mosquitto ];

  services.zigbee2mqtt = {
    enable = true;
    settings = {
      permit_join = true;
      mqtt = {
        server = "mqtt://shrew:1883";
        user = "zigbee2mqtt";
        password = "test";
      };
      serial = { port = "/dev/ttyUSB0"; };
      frontend = {
        port = 15606;
        url = "http://shrew";
      };
      homeassistant = true;
      advanced = { channel = 15; };
    };
  };

  services.mosquitto = {
    enable = true;
    listeners = [{
      users = {
        zigbee2mqtt = {
          acl = [ "readwrite #" ];
          hashedPassword =
            "$6$nuDIW/ZPVsrDHyBe$JffJJvvMG+nH8GH9V5h4FqJkU0nfiFkDzAsdYNTHeJMgBXEX9epPkQTUdLG9L47K54vMxm/+toeMAiKD63Dfkw==";
        };
        homeassistant = {
          acl = [ "readwrite #" ];
          hashedPassword =
            "$7$101$wGQZPdVdeW7iQFmH$bK/VOR6LXCLJKbb6M4PNeVptocjBAWXCLMtEU5fQNBr0Y5UAWlhVg8UAu4IkIXgnViI51NnhXKykdlWF63VkVQ==";
        };
      };
    }];
  };

  services.home-assistant = {
    enable = true;
    extraComponents = [
      "default_config"
      "esphome"
      "met"
      "rpi_power"
      "radio_browser"
      "mqtt"
      "zha"
      "stt"
      "tts"
      "whisper"
      "piper"
      "wyoming"
      "wake_word"
      "google_assistant"
      "google_translate"
    ];
    config = {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = { };
      automation = "!include automations.yaml";
      scene = "!include scenes.yaml";
      http = {
        use_x_forwarded_for = true;
        trusted_proxies = [ "100.64.0.2" ];
      };
      google_assistant = {
        project_id = "shrew-25325";
        service_account = "!include SERVICE_ACCOUNT.JSON";
        report_state = true;
        exposed_domains = [ "switch" "light" ];
        entity_config = {
          "light.room_bed_left" = {
            name = "BED_LEFT";
            aliases = [ "LEFT" ];
            room = "Bedroom";
          };
          "switch.room_bed_right" = {
            name = "BED_RIGHT";
            aliases = [ "RIGHT" ];
            room = "Bedroom";
          };
          "light.room_ceil" = {
            name = "CEIL";
            aliases = [ "CEILING" ];
            room = "Bedroom";
          };
          "switch.room_strip" = {
            name = "STRIP";
            room = "Bedroom";
          };
        };
      };
    };
  };

  #services.wyoming = {
  #  faster-whisper.servers.en = {
  #    enable = true;
  #    language = "en";
  #    uri = "tcp://0.0.0.0:10300";
  #  };
  #  piper.servers.en = {
  #    enable = true;
  #    voice = "en_GB-alba-medium";
  #    uri = "tcp://0.0.0.0:10200";
  #  };
  #  openwakeword = {
  #    enable = true;
  #    uri = "tcp://0.0.0.0:10400";
  #  };
  #};
}
