# man 5 configuration.nix

{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./common.nix
      ./packages.nix
      ./programs.nix
    ];

    boot.loader.grub = {
      enable = true;
      version = 2;
      device = "/dev/vda";
    };

    networking.hostName = "vps";

    networking.useDHCP = false;
    networking.interfaces.enp1s0.useDHCP = true;

    time.timeZone = "Europe/London";

    users.users.ryan.hashedPassword = "$6$tX0uyjRP0KEeHbCe$tz2MmUInPh/y/nE6Xy1am4OfNvffLvynb/tB9HskzmaGiatCzlSEcVnPkM6vCXNxzjU4dDgda85HG3kz/XZEs/";
    users.users.root.hashedPassword = "$6$tX0uyjRP0KEeHbCe$tz2MmUInPh/y/nE6Xy1am4OfNvffLvynb/tB9HskzmaGiatCzlSEcVnPkM6vCXNxzjU4dDgda85HG3kz/XZEs/";

    system.stateVersion = "21.11";
  }

