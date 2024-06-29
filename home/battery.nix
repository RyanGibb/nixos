{ config, lib, pkgs, ... }:

let cfg = config.custom.battery;
in {
  options.custom.battery.enable = lib.mkEnableOption "battery";

  config = lib.mkIf cfg.enable {
    systemd.user.services.battery_monitor = {
      Install = { WantedBy = [ "default.target" ]; };
      Service = {
        ExecStart = pkgs.writeScript "battery_monitor.sh" ''
          #!${pkgs.bash}/bin/bash

          battery=/sys/class/power_supply/BAT0

          while :
          do
          	status="$(${pkgs.coreutils}/bin/cat $battery/status)"
          	capacity="$(${pkgs.coreutils}/bin/cat $battery/capacity)"

          	if [ "$status" = Discharging -a "$capacity" -lt 5 ]; then
          		${pkgs.util-linux}/bin/logger "Critical battery threshold"
          		${pkgs.systemd}/bin/systemctl hibernate
          	elif [ "$status" = Discharging -a "$capacity" -lt 10 ]; then
          		${pkgs.libnotify}/bin/notify-send "warning: battery at $capacity%"
          	fi
          	${pkgs.coreutils}/bin/sleep 60
          done
        '';
        Restart = "always";
        RestartSec = 10;
        Type = "simple";
      };
    };
  };
}
