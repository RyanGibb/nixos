{ config, lib, pkgs, modulesPath, ... }:

{
  boot.initrd.availableKernelModules =
    [ "ata_piix" "uhci_hcd" "sr_mod" "xen_blkfront" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];
  boot.loader.grub.device = "/dev/xvda"; # or "nodev" for efi only

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/426b9528-ccde-4438-8338-10d35cea9d16";
    fsType = "ext4";
  };

  swapDevices = [{
    device = "/var/swap";
    size = 2048;
  }];

  networking = {
    useDHCP = false;
    interfaces."enX0" = {
      ipv4.addresses = [{
        address = "128.232.113.136";
        prefixLength = 23;
      }];
    };
    defaultGateway = {
      address = "128.232.112.1";
      interface = "enX0";
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
}
