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

          while :
          do
          	echo "$(${pkgs.coreutils}/bin/date -Ins) $(${pkgs.acpi}/bin/acpi -b)"\
          		| ${pkgs.coreutils}/bin/tee -a ~/.bat_hist\
          		| ${pkgs.gawk}/bin/awk -F'[,:%]' '{print $6; print $7}' | {
          		read -r status
          		read -r capacity
          
          		#if [ "$status" = Charging -o "$status" = Full ]; then
          		#	~/.config/sway/scripts/swayidle_lock.sh
          		#fi
          
          		if [ "$status" = Discharging -a "$capacity" -lt 5 ]; then
          			logger "Critical battery threshold"
          			systemctl hibernate
          		elif [ "$status" = Discharging -a "$capacity" -lt 10 ]; then
          			notify-send "warning: battery at $capacity%"
          		fi
          	}
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
