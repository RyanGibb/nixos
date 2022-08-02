{ lib, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/installer/sd-card/sd-image-aarch64.nix>
    ../common/default.nix
    ../../secret/wifi.nix
  ];

  networking.hostName = "rasp-pi";
  machineColour = "red";

  networking.wireless.enable = true;
}
