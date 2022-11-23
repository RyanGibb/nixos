{ config, lib, nixpkgs, ... }:

{
  imports = [
    "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-base.nix"
    "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
    ../../modules/personal/default.nix
    ../../modules/personal/gui/sway.nix
    ../../modules/personal/gui/i3.nix
    ../../modules/wifi.nix
  ];

  services.openssh.permitRootLogin = lib.mkForce "no";
  networking.wireless.enable = lib.mkForce false;

  users.users.${config.custom.username} = {
    extraGroups = [ "wheel" "networkmanager" "video" ];
    initialHashedPassword = lib.mkForce "";
  };

  services.getty.autologinUser = lib.mkForce "${config.custom.username}";
  services.getty.helpLine = lib.mkForce "";
}
