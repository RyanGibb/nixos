{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules =
    [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/d1b7f032-9c43-4a57-b531-4b1d6f88c999";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/0CC6-561D";
    fsType = "vfat";
  };

  swapDevices = [{
    device = "/var/swap";
    size = 16384;
  }];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;

  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
  };
}
