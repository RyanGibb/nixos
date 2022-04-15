{ pkgs, ... }:

{
  imports = [
    ./common.nix
    ./gui.nix
    ./kde.nix
    <home-manager/nixos> 
  ];

  boot.loader.grub = {
    enable = true;
    default = "saved";
    device = "nodev";
    efiSupport = true;
    extraEntries = ''
      menuentry 'Windows Boot Manager (on /dev/sda1)' --class windows --class os $menuentry_id_option 'osprober-efi-1A24-F5E7F' {
        savedefault
        insmod part_gpt
        insmod fat
        set root='hd1,gpt1'
        if [ x$feature_platform_search_hint = xy ]; then
          search --no-floppy --fs-uuid --set=root --hint-bios=hd1,gpt1 --hint-efi=hd1,gpt1 --hint-baremetal=ahci1,gpt1  1A24-F5E7
        else
          search --no-floppy --fs-uuid --set=root 1A24-F5E7
        fi
        chainloader /EFI/Microsoft/Boot/bootmgfw.efi
      }
    '';
  };

  networking = {
    hostName = "desktop";
    useDHCP = false;
  };

  users = {
    users.ryan.hashedPassword = "$6$tX0uyjRP0KEeHbCe$tz2MmUInPh/y/nE6Xy1am4OfNvffLvynb/tB9HskzmaGiatCzlSEcVnPkM6vCXNxzjU4dDgda85HG3kz/XZEs/";
    users.root.hashedPassword = "$6$tX0uyjRP0KEeHbCe$tz2MmUInPh/y/nE6Xy1am4OfNvffLvynb/tB9HskzmaGiatCzlSEcVnPkM6vCXNxzjU4dDgda85HG3kz/XZEs/";
  };

  # Needed for Keychron K2
  boot.extraModprobeConfig = ''
    options hid_apple fnmode=2
  '';
  boot.kernelModules = [ "hid-apple" ];

  boot.supportedFilesystems = [ "ntfs" ];

  fileSystems."/media/hdd" = { 
    device = "/dev/disk/by-label/HDD";
    options = [ "nofail" "x-systemd.device-timeout=1ms" "x-systemd.automount" "x-systemd.idle-timeout=10min" ];
  };

  swapDevices = [ { device = "/swapfile"; size = 8192; } ];

  services.avahi = {
    enable = true;
    publish.enable = true;
    publish.userServices = true;
    nssmdns = true;
  };

  environment.systemPackages = with pkgs; [
    pciutils
    tor-browser-bundle-bin
    discord
    ffmpeg
    audio-recorder
  ];

  programs.steam.enable = true;

  system.stateVersion = "21.11";
}
