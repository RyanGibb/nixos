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

  services.restic.backups.daily = {
    environmentFile = "${config.custom.secretsDir}/restic.env";
    repositoryFile = "${config.custom.secretsDir}/restic-repo";
    passwordFile = "${config.custom.secretsDir}/restic-password";
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
}
