{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom;
  clients = cfg.hysteria.clients;
  dropin = "/run/systemd/system/tailscaled.service.d/hysteria.conf";
  state = "/run/tailscale-via-hysteria";
  viaHysteria = pkgs.writeShellApplication {
    name = "tailscale-via-hysteria";
    runtimeInputs = with pkgs; [
      coreutils
      gnugrep
      iproute2
      systemd
    ];
    text = ''
      usage() {
        echo "usage: tailscale-via-hysteria <${lib.concatStringsSep "|" (lib.attrNames clients)}|off>" >&2
        exit 1
      }
      [ $# -eq 1 ] || usage
      if [ "$(id -u)" -ne 0 ]; then
        echo "tailscale-via-hysteria: must be run as root" >&2
        exit 1
      fi

      # $state names the client unit this script started, so off only stops that one
      started=""
      [ -r ${state} ] && started=$(cat ${state})

      case "$1" in
      ${lib.concatStrings (
        lib.mapAttrsToList (name: client: ''
          ${name}) port=${toString client.httpPort} ;;
        '') clients
      )}
      off)
        rm -f ${dropin}
        systemctl daemon-reload
        systemctl restart tailscaled
        echo "tailscaled restarted without a proxy"
        if [ -n "$started" ]; then
          systemctl stop "$started"
          echo "stopped $started"
        fi
        rm -f ${state}
        exit 0
        ;;
      *) usage ;;
      esac

      unit="hysteria-client-$1.service"
      if systemctl is-active --quiet "$unit"; then
        [ "$started" = "$unit" ] || rm -f ${state}
      else
        systemctl start "$unit"
        echo "$unit" > ${state}
        echo "started $unit"
      fi
      for _ in $(seq 40); do
        ss -Hltn "sport = :$port" | grep -q . && break
        sleep 0.5
      done
      ss -Hltn "sport = :$port" | grep -q . || echo "warning: nothing listening on 127.0.0.1:$port yet" >&2

      proxy="http://127.0.0.1:$port"
      mkdir -p "$(dirname ${dropin})"
      printf '[Service]\nEnvironment=HTTPS_PROXY=%s\nEnvironment=HTTP_PROXY=%s\nEnvironment=NO_PROXY=127.0.0.1,localhost\n' \
        "$proxy" "$proxy" > ${dropin}
      systemctl daemon-reload
      systemctl restart tailscaled
      echo "tailscaled restarted with HTTPS_PROXY=$proxy (${dropin})"

      if [ -n "$started" ] && [ "$started" != "$unit" ]; then
        systemctl stop "$started"
        echo "stopped $started"
      fi
    '';
  };
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

    environment.systemPackages = lib.mkIf (clients != { }) [ viaHysteria ];

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
