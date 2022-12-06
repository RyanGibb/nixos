{ pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  personal = {
    enable = true;
    tailscale = true;
    machineColour = "green";
    laptop = true;
    gui.i3 = true;
    gui.sway = true;
    gui.extra = true;
  };

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
