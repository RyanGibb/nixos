{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/ba914f8b-3910-430a-bf14-bd98db655d7d";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/64AB-A655";
      fsType = "vfat";
    };

  swapDevices = [ { device = "/swapfile"; size = 16384; } ];
  # https://discourse.nixos.org/t/is-it-possible-to-hibernate-with-swap-file/
  boot = {
    resumeDevice = "/dev/disk/by-label/nixos";
    # not very reproducible... could and extend swapDevices module
    kernelParams = [ "resume_offset=471040" ];
  };

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  # high-resolution display
  hardware.video.hidpi.enable = lib.mkDefault true;

  nixpkgs.hostPlatform = "x86_64-linux";
}
