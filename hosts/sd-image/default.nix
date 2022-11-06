{ lib, nixpkgs, ... }:

{
  imports = [
    "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
    ../../modules/common/default.nix
    ../../secrets/wifi.nix
  ];

  networking.hostName = "sd-image";
  machineColour = "red";

  networking.wireless.enable = true;
}
