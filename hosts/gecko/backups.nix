{ pkgs, config, ... }:

{
  age.secrets.restic-gecko.file = ../../secrets/restic-gecko.age;
  services.restic.backups.${config.networking.hostName} = {
    repository = "rest:http://100.64.0.9:8000/${config.networking.hostName}/";
    passwordFile = config.age.secrets.restic-gecko.path;
    initialize = true;
    paths = [
      "/var/lib/"
      "/etc/"
      "/home/"
      "/etc/NetworkManager/system-connections"
    ];
    timerConfig = {
      OnCalendar = "03:00";
      Persistent = true;
    };
    extraBackupArgs = [ "-vv" ];
  };

  systemd.services."restic-backups-${config.networking.hostName}" = {
    # fail to start on metered connection
    preStart = ''
      DEVICE=$(${pkgs.iproute2}/bin/ip route list 0/0 | sed -r 's/.*dev (\S*).*/\1/g')
      METERED=$(${pkgs.networkmanager}/bin/nmcli -f GENERAL.METERED dev show "$DEVICE" | ${pkgs.gawk}/bin/awk '/GENERAL.METERED/ {print $2}')
      if [ "$METERED_STATUS" = "yes" ]; then
        echo "Connection is metered. Aborting start."
        exit 1
      fi
      systemctl start notify-backup-started
    '';
    unitConfig.OnFailure = "notify-backup-failed.service";
  };

  systemd.services."notify-backup-started" = {
    enable = true;
    description = "Notify on backup start";
    serviceConfig = {
      Type = "oneshot";
      User = config.users.users.${config.custom.username}.name;
    };
    script = ''
      export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u ${config.custom.username})/bus"
      ${pkgs.libnotify}/bin/notify-send "Starting backup..."
    '';
  };

  systemd.services."notify-backup-failed" = {
    enable = true;
    description = "Notify on failed backup";
    serviceConfig = {
      Type = "oneshot";
      User = config.users.users.${config.custom.username}.name;
    };
    script = ''
      export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u ${config.custom.username})/bus"
      ${pkgs.libnotify}/bin/notify-send --urgency=critical \
        "Backup failed" \
        "$(journalctl -u restic-backups-daily -n 5 -o cat)"
    '';
  };
}
