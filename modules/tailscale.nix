{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom;
in
{
  options.custom.tailscale = lib.mkEnableOption "tailscale";

  config = lib.mkIf cfg.tailscale {
    # set up with `tailscale up --login-server https://headscale.freumh.org --hostname`
    services.tailscale.enable = true;
    networking.firewall = {
      checkReversePath = "loose";
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ config.services.tailscale.port ];
    };

    systemd.services.tailscale-online = {
      description = "Wait for Tailscale interface to be online";
      after = [ "tailscaled.service" ];
      requires = [ "tailscaled.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "wait-for-tailscale" ''
          until ${pkgs.tailscale}/bin/tailscale status --peers=false 2>/dev/null; do
            sleep 1
          done
        '';
        RemainAfterExit = true;
        TimeoutStartSec = "60";
      };
    };
  };
}
