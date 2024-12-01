{ config, lib, ... }:

with lib;

let
  cfg = config.custom;
in
{
  options.custom.tailscale = mkEnableOption "tailscale";

  config = lib.mkIf cfg.tailscale {
    # set up with `tailscale up --login-server https://headscale.freumh.org --hostname`
    services.tailscale.enable = true;
    networking.firewall = {
      checkReversePath = "loose";
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ config.services.tailscale.port ];
    };
  };
}
