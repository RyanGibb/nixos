{ pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  nixpkgs.hostPlatform.system = "x86_64-linux";

  personal = {
    enable = true;
    tailscale = true;
    machineColour = "white";
  };

  services.logind.lidSwitch = "ignore";

  boot.loader.grub = {
    enable = true;
    default = "saved";
    device = "nodev";
  };
}
