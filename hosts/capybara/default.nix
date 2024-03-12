{ config, pkgs, lib, nix-rpi5, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  personal = {
    enable = true;
    tailscale = true;
    machineColour = "red";
  };

  networking.networkmanager.enable = true;

  boot.kernelPackages = nix-rpi5.legacyPackages.aarch64-linux.linuxPackages_rpi5;

  networking.firewall.enable = false;
  networking.firewall.allowedTCPPorts = [ 44 ];

  services.caddy = {
    enable = true;
    virtualHosts."http://capybara" = {
      extraConfig = "reverse_proxy http://127.0.0.1:15606";
    };
    virtualHosts."http://capybara.fn06.org" = {
      extraConfig = "reverse_proxy http://127.0.0.1:15606";
    };
    virtualHosts."http://128.232.86.23" = {
      extraConfig = "reverse_proxy http://127.0.0.1:15606";
    };
  };

  services.zigbee2mqtt = {
    enable = true;
    settings = {
      permit_join = true;
      mqtt = {
        server = "mqtt://capybara:1883";
        user = "zigbee2mqtt";
        password = "test";
      };
      serial = {
        port = "/dev/ttyUSB0";
      };
      frontend = {
        port = 15606;
      };
      homeassistant = true;
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
      # Components required to complete the onboarding
      "esphome"
      "met"
      "radio_browser"
      "mqtt"
      "zha"
    ];
    config = {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = {};
      http.use_x_forwarded_for = true;
      http.trusted_proxies = "100.64.0.2";
    };
  };
}
