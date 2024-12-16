{
  pkgs,
  lib,
  config,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  custom = {
    enable = true;
    #tailscale = true;
    #laptop = true;
    #gui.i3 = true;
    #gui.sway = true;
    #workstation = true;
    #autoUpgrade.enable = true;
    homeManager.enable = true;
  };

  home-manager.users.${config.custom.username} = {
    custom = {
      machineColour = "blue";
      # nvim-lsps = true;
    };
  };

  environment.systemPackages = with pkgs; [
    coreutils
  ];

  networking.networkmanager.enable = true;
  # services.openssh.openFirewall = true;
}
