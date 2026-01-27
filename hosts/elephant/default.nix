{
  pkgs,
  config,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./zfs.nix
    ./services.nix
    ./owntracks.nix
  ];

  nixpkgs.overlays = [
    (final: prev: {
      immich = final.overlay-unstable.immich;
    })
  ];

  custom = {
    enable = true;
    tailscale = true;
    autoUpgrade.enable = true;
    homeManager.enable = true;
    gui.sway = true;
  };

  home-manager.users.${config.custom.username}.config.custom.machineColour = "blue";

  environment.systemPackages = with pkgs; [
    smartmontools
    powertop
    hdparm
    restic
    (ffmpeg.overrideAttrs (_: {
      withVpl = true;
    }))
    #stig
    nixd
  ];

  eilean = {
    publicInterface = "enp1s0";
  };

  powerManagement = {
    powertop.enable = true;
    # spins down drives after 1hr
    powerUpCommands = ''
      sudo ${pkgs.hdparm}/sbin/hdparm -S 242 /dev/disk/by-id/ata-ST16000NM001G-2KK103_ZL28CDKQ
      sudo ${pkgs.hdparm}/sbin/hdparm -S 242 /dev/disk/by-id/ata-TOSHIBA_MG08ACA16TE_83E0A00UFVGG
    '';
  };

  # backblaze
  age.secrets."restic.env".file = ../../secrets/restic.env.age;
  age.secrets.restic-repo.file = ../../secrets/restic-repo.age;
  age.secrets.restic-elephant.file = ../../secrets/restic-elephant.age;
  services.restic.backups.elephant-backblaze = {
    environmentFile = config.age.secrets."restic.env".path;
    repositoryFile = config.age.secrets.restic-repo.path;
    passwordFile = config.age.secrets.restic-elephant.path;
    initialize = true;
    paths = [
      "/var/lib/"
      "/etc/"
      "/home/"
      "/tank/family/mp4/"
      "/tank/family/other/"
      "/tank/immich/"
    ];
    timerConfig = {
      OnCalendar = "monthly";
    };
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-yearly 10"
    ];
  };

  # local backup
  services.restic.backups.${config.networking.hostName} = {
    repository = "${config.services.restic.server.dataDir}/elephant";
    passwordFile = config.age.secrets.restic-elephant.path;
    initialize = true;
    paths = [
      "/var/lib/"
      "/etc/"
      "/home/"
    ];
    timerConfig = {
      OnCalendar = "03:00";
      randomizedDelaySec = "1hr";
    };
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 12"
      "--keep-yearly 10"
    ];
  };

  # Add hardware transcoding support to `ffmpeg_6` and derived packages (like jellyfin-ffmpeg)
  # for Intel Alder Lake N100's Quick Sync Video (QSV) using Intel OneVPL.
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      # Video Acceleration API (VA-API) user mode driver
      intel-media-driver
      # Intel Video Processing Library (VPL) API runtime implementation
      vpl-gpu-rt
    ];
  };
  nixpkgs.config.packageOverrides = prev: {
    jellyfin-ffmpeg = prev.jellyfin-ffmpeg.overrideAttrs (_: {
      withVpl = true;
    });
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  system.stateVersion = "24.05";
}
