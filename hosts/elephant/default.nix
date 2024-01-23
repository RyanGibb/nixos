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
}
