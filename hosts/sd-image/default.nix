{ lib, nixpkgs, ... }:

{
  imports = [
    "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
    ../../modules/common/default.nix
    # TODO secrets repo
    # ../../secret/wifi.nix
  ];

  networking.hostName = "sd-image";
  machineColour = "red";

  networking.wireless.enable = true;
}
