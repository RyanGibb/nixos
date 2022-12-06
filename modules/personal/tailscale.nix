{ config, lib, ... }:

with lib;

let cfg = config.personal; in
{
  options.personal.tailscale = mkEnableOption "tailscale";

  config =
    let hosts = {
      "vps" = {
        ip = "100.88.115.118";
      };
      "dell-xps" = {
        ip = "100.92.111.117";
      };
      "pixel-4a" = {
        ip = "100.122.46.94";
      };
      "desktop" = {
        ip = "100.93.8.35";
      };
      "rasp-pi" = {
        ip = "100.92.63.87";
      };
    }; in
  mkIf cfg.tailscale {
    services.tailscale.enable = true;
    networking.firewall.checkReversePath = mkDefault "loose";

    dns.records = attrsets.mapAttrsToList (hostName: values: {
      name = "${hostName}.vpn";
      type = "A";
      data = values.ip;
    }) hosts;

    networking.extraHosts = builtins.concatStringsSep "\n" (
      attrsets.mapAttrsToList (
        hostName: values: "${values.ip} ${hostName}.vpn"
      ) hosts
    );
  };
}
