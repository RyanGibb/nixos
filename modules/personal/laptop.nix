{ pkgs, config, lib, self, ... }:

let cfg = config.personal; in
{
  options.personal.laptop = lib.mkEnableOption "laptop";
  
  config = lib.mkIf cfg.laptop {
    users.users.${config.custom.username}.extraGroups = [ "input" ];

    services.xserver.libinput.enable = true;

    services.tlp.enable = true;
    powerManagement.enable = true;

    systemd.sleep.extraConfig = ''
      HibernateDelaySec=1h
    '';

    services.logind.lidSwitch = "suspend-then-hibernate";

    environment.systemPackages = with pkgs; [
      fusuma
      kanshi
      acpi
    ];

    services.udev.extraRules =
      let bat-monitor = pkgs.writeShellScript "bat_monitor.sh" ''
        capacity=$1
        status=$2

        if [ "$status" = Discharging -a "$capacity" -lt 5 ]; then
          logger "Critical battery threshold"
          systemctl hibernate
        elif [ "$status" = Discharging -a "$capacity" -lt 10 ]; then
          notify-send "warning: battery at $capacity%"
        fi

        ${pkgs.procps}/bin/pkill -RTMIN+2 i3blocks
      ''; in ''
      ACTION=="change", SUBSYSTEM=="power_supply", RUN+="${pkgs.bash}/bin/bash ${bat-monitor} '%s{capacity}' '%s{status}'"
    '';
  };
}
