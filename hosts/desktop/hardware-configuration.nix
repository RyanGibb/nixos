{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  # kvm for virtualisation, wl for broadcom_sta kernel module
  boot.kernelModules = [ "kvm-intel" "wl" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
  # loading bcma/b43 at the same time as wl seems to cause issues
  boot.blacklistedKernelModules = [ "bcma" "b43" ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/d2afdf21-7a3a-47f0-83e1-31e9cccdad84";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/43FD-8669";
      fsType = "vfat";
    };

  fileSystems."/media/hdd" =
    { device = "/dev/disk/by-label/HDD";
      options = [ "nofail" "x-systemd.device-timeout=1ms" "x-systemd.automount" "x-systemd.idle-timeout=10min" ];
    };

  swapDevices = [ ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp3s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.tailscale0.useDHCP = lib.mkDefault true;

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  # high-resolution display
  # hardware.video.hidpi.enable = lib.mkDefault true;

  nixpkgs.hostPlatform = "x86_64-linux";
}
