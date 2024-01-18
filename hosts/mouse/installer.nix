{ lib, nixpkgs, ... }:

{
  imports = [
    "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-raspberrypi.nix"
  ];

  # https://discourse.nixos.org/t/building-libcamera-for-raspberry-pi/26133/7
  nixpkgs.hostPlatform = {
    system = "armv6l-linux";
    gcc = {
      arch = "armv6k";
      fpu = "vfp";
    };
  };
  # required removing ncdu, pandoc, nix-tree, and neovim for cross-compilation

  # https://github.com/NixOS/nixpkgs/issues/141470#issuecomment-996202318
  boot.initrd.availableKernelModules = lib.mkForce [ ];

  networking.hostName = "mouse";
  personal = {
    enable = true;
    machineColour = "red";
  };
}
