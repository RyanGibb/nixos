{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules =
    [ "xhci_pci" "ehci_pci" "ahci" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  # kvm for virtualisation, wl for broadcom_sta kernel module
  boot.kernelModules = [ "kvm-intel" "wl" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
  # loading bcma/b43 at the same time as wl seems to cause issues
  boot.blacklistedKernelModules = [ "bcma" "b43" ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/d2afdf21-7a3a-47f0-83e1-31e9cccdad84";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/2DD6-69F0";
    fsType = "vfat";
  };

  fileSystems."/media/hdd" = {
    device = "/dev/disk/by-label/HDD";
    options = [
      "nofail"
      "x-systemd.device-timeout=1ms"
      "x-systemd.automount"
      "x-systemd.idle-timeout=10min"
    ];
  };

  swapDevices = [{
    device = "/swapfile";
    size = 8192;
  }];

  networking.useDHCP = lib.mkDefault true;

  hardware.cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
  # high-resolution display
  # hardware.video.hidpi.enable = lib.mkDefault true;

  nixpkgs.hostPlatform = "x86_64-linux";
}
