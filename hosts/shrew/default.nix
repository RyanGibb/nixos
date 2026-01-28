{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./minimal.nix
  ];

  networking.networkmanager.enable = true;

  services.caddy = {
    enable = true;
    virtualHosts."http://shrew" = {
      listenAddresses = [ "100.64.0.6" ];
      extraConfig = "reverse_proxy http://127.0.0.1:15606";
    };
  };

  environment.systemPackages = with pkgs; [
    mosquitto
  ];

  services.zigbee2mqtt = {
    enable = true;
    settings = {
      mqtt = {
        server = "mqtt://shrew:1883";
        user = "zigbee2mqtt";
        password = "test";
      };
      serial = {
        port = "/dev/ttyUSB0";
      };
      frontend = {
        port = 15606;
        url = "http://shrew";
      };
      advanced = {
        channel = 15;
      };
    };
  };

  services.mosquitto = {
    enable = true;
    listeners = [
      {
        users = {
          zigbee2mqtt = {
            acl = [ "readwrite #" ];
            hashedPassword = "$6$nuDIW/ZPVsrDHyBe$JffJJvvMG+nH8GH9V5h4FqJkU0nfiFkDzAsdYNTHeJMgBXEX9epPkQTUdLG9L47K54vMxm/+toeMAiKD63Dfkw==";
          };
          homeassistant = {
            acl = [ "readwrite #" ];
            hashedPassword = "$7$101$wGQZPdVdeW7iQFmH$bK/VOR6LXCLJKbb6M4PNeVptocjBAWXCLMtEU5fQNBr0Y5UAWlhVg8UAu4IkIXgnViI51NnhXKykdlWF63VkVQ==";
          };
        };
      }
    ];
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
    ];
    customComponents = with pkgs.overlay-unstable.home-assistant-custom-components; [
      adaptive_lighting
    ];
    config = null;
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

  age.secrets.restic-shrew.file = ../../secrets/restic-shrew.age;
  services.restic.backups.${config.networking.hostName} = {
    repository = "rest:http://100.64.0.9:8000/${config.networking.hostName}/";
    passwordFile = config.age.secrets.restic-shrew.path;
    initialize = true;
    paths = [ "/var/lib/hass" ];
    timerConfig = {
      OnCalendar = "monthly";
      randomizedDelaySec = "1hr";
    };
  };
}
