{ config, lib, nixpkgs, ... }:

{
  imports =
    [ "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix" ];

  nixpkgs.hostPlatform = "aarch64-linux";

  custom = { enable = true; };

  home-manager.users.${config.custom.username}.config.custom.machineColour =
    "red";

  networking.wireless = {
    enable = true;
    networks = { "SSID" = { psk = "password"; }; };
  };
}
