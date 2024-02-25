{ pkgs, config, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./zfs.nix
    ./services.nix
  ];

  personal = {
    enable = true;
    tailscale = true;
    machineColour = "blue";
  };

  environment.systemPackages = with pkgs; [
    smartmontools
    powertop
    hdparm
    restic
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

  services.restic.backups.sync = {
    environmentFile = "${config.custom.secretsDir}/restic.env";
    repositoryFile = "${config.custom.secretsDir}/restic-repo";
    passwordFile = "${config.custom.secretsDir}/restic-password-elephant";
    initialize = true;
    paths = [
      "/tank/family/mp4/"
      "/tank/family/other/"
      "/tank/photos/"
    ];
    timerConfig = {
      OnCalendar = "03:00";
    };
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-yearly 10"
    ];
  };

  # Add hardware transcoding support to `ffmpeg_6` and derived packages (like jellyfin-ffmpeg)
  # for Intel Alder Lake N100's Quick Sync Video (QSV) using Intel OneVPL.
  # Remove once https://github.com/NixOS/nixpkgs/pull/264621 is merged.
  nixpkgs.config.packageOverrides = prev: {
    jellyfin-ffmpeg = prev.jellyfin-ffmpeg.overrideAttrs (old: rec {
      configureFlags =
        # Remove deprecated Intel Media SDK support
        (builtins.filter (e: e != "--enable-libmfx") old.configureFlags)
        # Add Intel Video Processing Library (VPL) support
        ++ [ "--enable-libvpl" ];
      buildInputs = old.buildInputs ++ [
        # VPL dispatcher
        pkgs.overlay-unstable.libvpl
      ];
    });
  };
  # The VPL dispatcher searches LD_LIBRARY_PATH for runtime implemenations
  environment.sessionVariables.LD_LIBRARY_PATH =
    lib.strings.makeLibraryPath (with pkgs; [
        # Intel oneVPL API runtime implementation for Intel Gen GPUs
        (pkgs.callPackage ../../pkgs/onevpl-intel-gpu.nix { })
    ]);
}
