{ config, lib, pkgs, ... }:

{
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "sr_mod" "xen_blkfront" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/xvda"; # or "nodev" for efi only

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/a0a1f9cf-78b3-402d-996d-68950326e7d0";
      fsType = "ext4";
    };

  swapDevices = [ ];

  networking = {
   useDHCP = false;
   interfaces."enX0".ipv4.addresses = [{
     address = "128.232.98.96";
     prefixLength = 23;
   }];
   defaultGateway = {
     address = "128.232.98.1";
     interface = "enX0";
   };
   nameservers = [ "1.1.1.1" ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
