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
      gammastep
      waybar
      alacritty
      wofi
      wofi-emoji
      wdisplays
      wf-recorder
      grim
      slurp
      swappy
    ];
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    gtkUsePortal = false;
  };
}