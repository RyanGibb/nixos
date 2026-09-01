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
    ./decluttarr.nix
    ./slskd.nix
    ./zomboid.nix
  ];

  nixpkgs.overlays = [
    (final: prev: {
      immich = final.overlay-unstable.immich;
      navidrome = prev.navidrome.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./navidrome-mediasession-directional.patch ];
      });
    })
  ];

  custom = {
    enable = true;
    tailscale = true;
    autoUpgrade.enable = true;
    homeManager.enable = true;
    gui.sway = true;
  };

  home-manager.users.${config.custom.username}.config = {
    custom.machineColour = "blue";
    xdg.userDirs.enable = lib.mkForce false;
  };

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
      "/tank/family/"
      "/tank/immich/"
    ];
    exclude = [
      "/var/lib/transmission"
      "/var/lib/jellyfin/metadata"
      "/tank/immich/encoded-video"
      "/tank/immich/thumbs"
      "*.trickplay"
    ];
    timerConfig = {
      OnCalendar = "monthly";
    };
    pruneOpts = [
      # group across all snapshots regardless of path-set, else retention
      # applies per historical path-set and never collapses old snapshots
      "--group-by host"
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
      "--keep-yearly 2"
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
      "--group-by host"
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
      # OpenCL runtime for Intel GPUs (required for HDR tonemapping)
      intel-compute-runtime
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
