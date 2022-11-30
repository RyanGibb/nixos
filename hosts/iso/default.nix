{ config, lib, nixpkgs, ... }:

{
  imports = [
    "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-base.nix"
    "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
  ];

  personal = {
    enable = true;
    laptop = true;
    gui.i3 = true;
    gui.sway = true;
  };

  services.openssh.permitRootLogin = lib.mkForce "no";
  networking.wireless.enable = lib.mkForce false;

  users.users.${config.custom.username} = {
    extraGroups = [ "wheel" "networkmanager" "video" ];
    initialHashedPassword = lib.mkForce "";
  };

  services.getty.autologinUser = lib.mkForce "${config.custom.username}";
  services.getty.helpLine = lib.mkForce "";

  networking.wireless = {
    enable = true;
    networks = {
      "SSID" = {
        psk = "password";
      };
    };
  };
}
