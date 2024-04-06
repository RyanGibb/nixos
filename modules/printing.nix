{ config, lib, ... }:

let cfg = config.custom;
in {
  options.custom.printing = lib.mkEnableOption "printing";

  config = lib.mkIf cfg.printing {
    networking.firewall = {
      allowedTCPPorts = [ 631 ];
      allowedUDPPorts = [ 631 ];
    };
    services.printing = {
      enable = true;
      browsing = true;
      defaultShared = true;
    };
    services.avahi = {
      enable = true;
      publish.enable = true;
      publish.userServices = true;
      nssmdns = true;
    };
  };
}
