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
    ocaml = true;
    nvim-lsps = true;
  };

  boot.loader.grub = {
    enable = true;
    default = "saved";
    device = "nodev";
    efiSupport = true;
    useOSProber = true;
  };

  environment.systemPackages = with pkgs; [
    dell-command-configure
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
    wally-cli
    gthumb
    restic
    jellyfin-media-player
  ];

  virtualisation.docker.enable = true;
  users.users.ryan.extraGroups = [ "docker" ];

  systemd.extraConfig = ''
    DefaultTimeoutStopSec=30s
  '';

  programs.steam.enable = true;

  security.sudo.extraConfig = ''
    Defaults !tty_tickets
  '';

  # sometimes I want to keep the cache for operating without internet
  nix.gc.automatic = lib.mkForce false;

  # for CL VPN
  networking.networkmanager.enableStrongSwan = true;

  services = {
    syncthing = {
      enable = true;
      user = config.custom.username;
      dataDir = "/home/ryan/syncthing";
      configDir = "/home/ryan/.config/syncthing";
    };
  };

  networking.hostId = "e768032f";

  #system.includeBuildDependencies = true;
  nix = {
    buildMachines = [ {
      hostName = "rtg24@daintree.cl.cam.ac.uk";
      system = "x86_64-linux";
      protocol = "ssh-ng";
      maxJobs = 1;
      speedFactor = 2;
      supportedFeatures = [ "benchmark" "big-parallel" "kvm" ];
      mandatoryFeatures = [ ];
    }] ;
    distributedBuilds = true;
    extraOptions = ''
      builders-use-substitutes = true
      '';
  };

  age.secrets.restic-gecko.file = ../../secrets/restic-gecko.age;
  services.restic.backups.${config.networking.hostName} = {
    repository = "rest:http://100.64.0.9:8000/${config.networking.hostName}/";
    passwordFile = config.age.secrets.restic-gecko.path;
    initialize = true;
    paths = [
      "/home/${config.custom.username}"
      "/etc/NetworkManager/system-connections"
    ];
    exclude = [
      "/home/${config.custom.username}/videos"
      "/home/${config.custom.username}/.thunderbird"
      "/home/${config.custom.username}/.cache"
      "/home/${config.custom.username}/.local/share/Steam"
    ];
    timerConfig = {
      OnUnitActiveSec = "1d";
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
    '';
    unitConfig.OnFailure = "notify-backup-failed.service";
  };

  systemd.services."notify-backup-failed" = {
    enable = true;
    description = "Notify on failed backup";
    serviceConfig = {
      Type = "oneshot";
      User = config.users.users.${config.custom.username}.name;
    };

    environment.DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/${
      toString config.users.users.${config.custom.username}.uid
    }/bus";

    script = ''
      ${pkgs.libnotify}/bin/notify-send --urgency=critical \
        "Backup failed" \
        "$(journalctl -u restic-backups-daily -n 5 -o cat)"
    '';
  };

  systemd.services.NetworkManager-wait-online.enable = false;
}
