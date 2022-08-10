{ pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common/default.nix
    ../../modules/common/laptop.nix
    ../../modules/gui/sway.nix
    ../../modules/gui/i3.nix
    ../../modules/ocaml.nix
  ];

  machineColour = "green";

  services.tailscale.enable = true;

  boot.loader.grub = {
    enable = true;
    default = "saved";
    device = "nodev";
  };

  environment.systemPackages = with pkgs; [
    slack

    (pkgs.callPackage ../../pkgs/opam2nix.nix { })
  ];

  # https://www.dell.com/community/Precision-Mobile-Workstations/WD19TBS-Issues-with-Thinkpad-X1-Carbon-Gen-6/td-p/8182725
  # https://wiki.archlinux.org/title/Thunderbolt#Automatically_connect_any_device
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{authorized}=="0", ATTR{authorized}="1"
  '';
}
