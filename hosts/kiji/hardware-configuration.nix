{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  boot.loader = {
    efi.efiSysMountPoint = "/boot/efi";
    grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
      device = "nodev";
      # /boot is 1 GB
      configurationLimit = 10;
    };
  };
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/f8230db3-67ba-4101-8767-744d5d7463ef";
    fsType = "ext4";
  };
  # the cloud image's /boot partition, where grub's prefix points
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/dcb61405-90d2-4a62-90d6-afff72d2db24";
    fsType = "ext4";
  };
  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-uuid/35F6-9B39";
    fsType = "vfat";
  };
  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "xen_blkfront"
    "vmw_pvscsi"
  ];
  boot.initrd.kernelModules = [ "nvme" ];
  nixpkgs.hostPlatform = "x86_64-linux";
}
