{ pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/personal/default.nix
    ../../modules/personal/laptop.nix
    ../../modules/personal/gui/sway.nix
    ../../modules/personal/gui/i3.nix
    ../../modules/personal/gui/extra.nix
    ../../modules/ocaml.nix
    ../../modules/services/wireguard/default.nix
  ];

  custom.machineColour = "green";

  services.tailscale.enable = true;

  boot.loader.grub = {
    enable = true;
    default = "saved";
    device = "nodev";
  };

  environment.systemPackages = with pkgs; [
    slack

    # (pkgs.callPackage ../../pkgs/opam2nix.nix { })
  ];

  # https://www.dell.com/community/Precision-Mobile-Workstations/WD19TBS-Issues-with-Thinkpad-X1-Carbon-Gen-6/td-p/8182725
  # https://wiki.archlinux.org/title/Thunderbolt#Automatically_connect_any_device
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{authorized}=="0", ATTR{authorized}="1"
  '';

  # https://github.com/swaywm/sway/issues/5315
  home-manager.users.${config.custom.username}.home.sessionVariables.WLR_DRM_NO_MODIFIERS = 1;
}
