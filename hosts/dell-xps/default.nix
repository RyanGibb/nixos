{ pkgs, lib, config, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  personal = {
    enable = true;
    tailscale = true;
    machineColour = "blue";
    laptop = true;
    printing = true;
    gui.i3 = true;
    gui.sway = true;
    gui.extra = true;
  };

  boot.loader.grub = {
    enable = true;
    default = "saved";
    device = "nodev";
    efiSupport = true;
    useOSProber = true;
  };

  boot.supportedFilesystems = [ "ntfs" ];

  environment.systemPackages = with pkgs; [
    cctk
    (python3.withPackages (p: with p; [
      numpy
      matplotlib
      pandas
    ]))
    python39Packages.pip
    jupyter
    #vagrant
    discord
    #teams
    wine64
    anki
    lsof
  ];

  systemd.extraConfig = ''
    DefaultTimeoutStopSec=30s
  '';

  programs.steam.enable = true;

  security.sudo.extraConfig = ''
    Defaults !tty_tickets
  '';

  # sometimes I want to keep the cache for operating without internet
  nix.gc.automatic = lib.mkForce false;

  

  systemd.services.backup = {
    description = "Backup service";
    script = let backup = pkgs.writeShellScript "backup.sh" ''
      LAST_RUN_FILE="/var/run/last_backup"
      DISK="/dev/disk/by-label/external-hdd"

      if [ -f "$LAST_RUN_FILE" ] && [ "$(( $(date +%s) - $(date +%s -r "$LAST_RUN_FILE") ))" -lt 86400 ]; then
          echo "<24hrs"
          exit 0
      fi

      # if no external-hdd
      if [ ! -e $DISK ]; then
        echo "No $DISK"
        exit 0
      fi

      ${pkgs.util-linux}/bin/mount /dev/disk/by-label/external-hdd /media/external-hdd/ || exit 1
      ${pkgs.rsync}/bin/rsync -va --exclude={".cache",".local/share/Steam/"} /home/${config.custom.username}/ /media/external-hdd/home/
      status=$?
      if [ $status -eq 0 ]; then
        touch "$LAST_RUN_FILE"
      fi
      ${pkgs.util-linux}/bin/umount /media/external-hdd/
      exit $status
    ''; in "${backup}";
    serviceConfig = {
      Type = "oneshot";
    };
    # trigger on wake
    wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" "suspend-then-hibernate.target" ];
  };
  # trigger backup on hard drive connection
  services.udev.extraRules =
    # NB could check device label with a trigger script that checks $0 and `RUN+="${trigger} /media/$env{ID_FS_LABEL}"`
    # but we just assume the Seagate Expansion Desk is the same as /dev/disk/by-label/external-hdd
    # UDEV has crap support for detecting devices
    ''
    ACTION=="add", SUBSYSTEM=="block", KERNEL=="sd[a-z]*[0-9]*", ATTRS{model}=="Expansion Desk  ", ATTRS{vendor}=="Seagate ", TAG+="systemd", ENV{SYSTEMD_WANTS}+="backup"
  '';
}
