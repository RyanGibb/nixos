{ config, lib, ...}:

{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-base.nix>
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
    ../common/default.nix
    ../gui/sway.nix
    ../gui/i3.nix
    ../../secret/wifi.nix
    <home-manager/nixos>
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
