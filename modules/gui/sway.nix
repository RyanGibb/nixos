{ pkgs, ... }:

{
  imports = [
    ./gui.nix
  ];
  
  home-manager.users.ryan = import ../home-manager/sway.nix;

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true; # so that gtk works properly
    extraPackages = with pkgs; [
      jq
      swaylock
      swayidle
      wl-clipboard
      clipman
      wtype
      playerctl
      brightnessctl
      xdg-utils
      gammastep
      waybar
      alacritty
      mako
      libnotify
      wofi
      wofi-emoji
      gnome.zenity
      feh
      gnome.networkmanagerapplet
      wdisplays
      pavucontrol
      (xfce.thunar.override { thunarPlugins = with xfce; [
        thunar-archive-plugin
        xfconf
      ]; })
      gnome.file-roller
      # https://discourse.nixos.org/t/sway-wm-configuration-polkit-login-manager/3857/6
      polkit_gnome
      wf-recorder
      grim
      slurp
      swappy
      glib
    ];
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    gtkUsePortal = false;
  };
}