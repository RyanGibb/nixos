{ pkgs, lib, config, ... }:

let cfg = config.services.wireguard; in
{
  imports = [
    ./server.nix
  ];

  options.services.wireguard = {
    addresses = lib.mkOption {
      default = {
        "vps" = "10.0.0.1";
        "dell-xps" = "10.0.0.2";
        "pixel-4a" = "10.0.0.3";
        "desktop" = "10.0.0.4";
        "rasp-pi" = "10.0.0.5";
      };
    };
    enable = lib.mkOption {
      type = with pkgs.lib.types; bool;
      default = 
        # true if networking.hostName in wireguard.addresses
        let addressesList = lib.attrsets.mapAttrsToList (hostName: address: hostName) cfg.addresses; in
        (builtins.elem "${config.networking.hostName}" addressesList);
    };
    server = lib.mkOption {
      type = with pkgs.lib.types; bool;
      default = false;
    };
  };

  config.networking = lib.mkIf config.services.wireguard.enable {
    # populate /etc/hosts with wireguard.addresses
    extraHosts =
      let entryToString = hostName: address: "${address} ${hostName}"; in
      let entries = lib.attrsets.mapAttrsToList entryToString cfg.addresses; in
      builtins.concatStringsSep "\n" entries;

    firewall = {
      allowedUDPPorts = [ 51820 ];
      checkReversePath = false;
    };

    wireguard = {
      enable = true;
      interfaces.wg0 =
        let address = cfg.addresses.${config.networking.hostName}; in {
        ips = [ "${address}/24" ];
        listenPort = 51820;

        privateKeyFile = "/etc/nixos/secret/wireguard_key";

        peers = [
          {
            allowedIPs = [ "10.0.0.0/24" ];
            publicKey = "Jg/zcR6fUiyZAONqB0csIwaN8BYHa5ccfwmKN5INmA8=";
            endpoint = "45.77.205.198:51820";
            persistentKeepalive = 25;
          }
        ];
      };
    };
  };
}
