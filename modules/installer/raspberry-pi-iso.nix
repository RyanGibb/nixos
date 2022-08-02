{ lib, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/installer/sd-card/sd-image-aarch64.nix>
    ../common/default.nix
    ../../secret/wifi.nix
  ];

  machineColour = "red";

  networking.wireless.enable = true;

  networking = {
    hostName = "rasp-pi";
    useDHCP = false;
    interfaces.eth0.useDHCP = true;
    interfaces.wlan0.useDHCP = true;
  };
}
