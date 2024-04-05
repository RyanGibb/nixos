{ lib, nixpkgs, ... }:

{
  imports =
    [ "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix" ];

  nixpkgs.hostPlatform = "aarch64-linux";

  personal = {
    enable = true;
    machineColour = "red";
  };

  networking.wireless = {
    enable = true;
    networks = { "SSID" = { psk = "password"; }; };
  };
}
