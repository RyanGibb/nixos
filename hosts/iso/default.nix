{ config, lib, nixpkgs, ... }:

{
  imports = [
    "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-base.nix"
    "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
    ../../modules/common/default.nix
    ../../modules/gui/sway.nix
    ../../modules/gui/i3.nix
    ../../modules/wifi.nix
  ];

  services.openssh.permitRootLogin = lib.mkForce "no";
  networking.wireless.enable = lib.mkForce false;

  users.users.ryan = {
    extraGroups = [ "wheel" "networkmanager" "video" ];
    initialHashedPassword = lib.mkForce "";
  };

  services.getty.autologinUser = lib.mkForce "ryan";
  services.getty.helpLine = lib.mkForce "";
}
