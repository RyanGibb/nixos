{ lib, nixpkgs, ... }:

{
  imports = [
    "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
    ../../modules/default.nix
    ../../modules/personal/default.nix
    ../../modules/wifi.nix
  ];

  networking.hostName = "sd-image";
  custom.machineColour = "red";

  networking.wireless.enable = true;
}
