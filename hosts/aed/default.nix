{ pkgs, lib, config, ... }:

let
  disk = "/dev/disk/by-label/external-hdd";
  mountdir = "/media";
  mountname = "external-hdd";
in
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
    ocaml = true;
  };

  boot.loader.grub = {
    enable = true;
    default = "saved";
    device = "nodev";
    efiSupport = true;
    useOSProber = true;
  };

  boot.supportedFilesystems = [ "ntfs" ];

  boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_4;

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
    logseq
    wally-cli
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
    # NB udisks isn't viable as non-root due to:
    #   Error creating textual authentication agent: Error opening current controlling terminal for the process (`/dev/tty'): No such device or address (polkit-error-quark, 0)
    #   Error mounting /dev/sda1: GDBus.Error:org.freedesktop.UDisks2.Error.NotAuthorizedCanObtain: Not authorized to perform operation
    # And in order to communicate with GUI prompts, e.g. yad, we need to run as user
    # udisks is still use for on-demand mountin, but we'll use the autofs for mounting the backup disk
    script = let backup = pkgs.writeShellScript "backup.sh" ''
      # TODO make nixos module with options
      DISK="${disk}"
      LAST_RUN_FILE="$HOME/.cache/last_backup"

      if [ -f "$LAST_RUN_FILE" ] && [ "$(( $(date +%s) - $(date +%s -r "$LAST_RUN_FILE") ))" -lt 86400 ]; then
          echo "<24hrs"
          exit 0
      fi

      # if no external-hdd
      if [ ! -e $DISK ]; then
        echo "no $DISK"
        exit 0
      fi

      export DISPLAY=:0
      ${pkgs.xorg.xhost}/bin/xhost +local:${config.custom.username}
      export GTK_R2_FILES=$HOME/.gtkrc-2.0
      timeout 60 ${pkgs.yad}/bin/yad --question --title "backup" --text "Backup now? Will autostart in 60s."
      prompt_status=$?
      ${pkgs.xorg.xhost}/bin/xhost -local:${config.custom.username}
      # if not success or timeout
      if [ ! $prompt_status -eq 0 -a ! $prompt_status -eq 124 ]; then
        echo "backup cancelled"
        ${pkgs.libnotify}/bin/notify-send "backup cancelled"
        exit 0
      fi

      DIR="${mountdir}/${mountname}"
      cd "$DIR"
      TEST_DIR=`${pkgs.util-linux}/bin/findmnt -nr -o target -S $DISK`
      status=$?
      if [ ! $status -eq 0 ]; then
        echo "backup failed to find mount"
        ${pkgs.libnotify}/bin/notify-send "backup failed to find mount"
        exit $status
      fi 
      if [ "$DIR" != "$TEST_DIR" ]; then
        echo "backup disk mounted at unexpected path: $TEST_DIR"
        ${pkgs.libnotify}/bin/notify-send "backup disk mounted at unexpected path: $TEST_DIR"
        exit 1
      fi 
      ${pkgs.libnotify}/bin/notify-send "backup starting"
      ${pkgs.rsync}/bin/rsync -va --exclude={".cache",".local/share/Steam/"} ~/ $DIR/home/
      status=$?
      if [ $status -eq 0 ]; then
        touch "$LAST_RUN_FILE"
        echo "backup finished"
        ${pkgs.libnotify}/bin/notify-send "backup finished"
      else
        echo "backup failed"
        ${pkgs.libnotify}/bin/notify-send "backup failed"
      fi
      sudo ${pkgs.hd-idle} -t $DISK
      exit $status
    ''; in "${backup}";
    serviceConfig = {
      Type = "oneshot";
      User = config.custom.username;
    };
    # trigger on wake
    wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" "suspend-then-hibernate.target" ];
    environment.DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/1000/bus";
  };
  # trigger backup on hard drive connection
  services.udev.extraRules =
    # NB could check device label with a trigger script that checks $0 and `RUN+="${trigger} /media/$env{ID_FS_LABEL}"`
    # but we just assume the Seagate Expansion Desk is the same as /dev/disk/by-label/external-hdd
    # UDEV has crap support for detecting devices
    ''
    ACTION=="add", SUBSYSTEM=="block", KERNEL=="sd[a-z]*[0-9]*", ATTRS{model}=="Expansion Desk  ", ATTRS{vendor}=="Seagate ", TAG+="systemd", ENV{SYSTEMD_WANTS}+="backup"
  '';
  services.autofs = {
    enable = true;
    autoMaster = let
      map = pkgs.writeText "auto.media" ''
        ${mountname} -fstype=auto :${disk}
      '';
    in ''
      ${mountdir} file,sun:${map} -t 60
    '';
  };

  # for CL VPN
  networking.networkmanager.enableStrongSwan = true;

  services.kmonad = {
    # enable = true;
    keyboards.internal = {
      # todo find by-id
      device = "/dev/input/by-path/platform-i8042-serio-0-event-kbd";
      config = builtins.readFile ./kmonad.kbd;
    };
  };
}
