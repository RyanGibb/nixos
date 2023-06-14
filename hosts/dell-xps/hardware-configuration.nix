{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usbhid" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/b949a6f8-8f30-4f68-9622-ae0f013bce8a";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/A49E-420F";
      fsType = "vfat";
    };

  fileSystems."/media/external-hdd" =
    { device = "/dev/disk/by-label/external-hdd";
      options = [ "nofail" "x-systemd.device-timeout=1ms" "x-systemd.automount" "x-systemd.idle-timeout=10min" ];
    };

  swapDevices = [ { device = "/var/swap"; size = 16384; } ];
  boot.resumeDevice = "/dev/disk/by-label/nixos";
  # https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate#Hibernation_into_swap_file
  boot.kernelParams = [ "mem_sleep_default=deep" "resume_offset=142587904" ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  nixpkgs.hostPlatform = "x86_64-linux";
}
