{ pkgs, config, lib, eilean, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./zfs.nix
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

  boot.loader.grub = {
    enable = true;
    default = "saved";
    device = "nodev";
    efiSupport = true;
  };

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;

  swapDevices = [ { device = "/var/swap"; size = 16384; } ];

  eilean = {
    publicInterface = "enp1s0";
  };

  services.avahi = {
    enable = true;
    nssmdns = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  services.minidlna = {
    enable = true;
    openFirewall = true;
    settings = {
      media_dir = [ "/mnt/hdd" ];
      notify_interval = 60;
      inofity = true;
    };
  };

  powerManagement.powertop.enable = true;
}
