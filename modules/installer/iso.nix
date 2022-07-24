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

  boot.loader.grub.enable = lib.mkForce false;
  services.openssh.permitRootLogin = lib.mkForce "no";
  networking.wireless.enable = lib.mkForce false;

  users.users.ryan = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" ];
    initialHashedPassword = "";
  };

  services.getty.autologinUser = lib.mkForce "ryan";
  services.getty.helpLine = lib.mkForce "";
}
