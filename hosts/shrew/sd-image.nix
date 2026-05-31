{
  config,
  lib,
  nixpkgs,
  ...
}:

{
  imports = [ "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix" ];

  nixpkgs.hostPlatform = "aarch64-linux";

  # installer media has no root zfs pool; adopt the 26.11 default
  boot.zfs.forceImportRoot = false;

  custom = {
    enable = true;
  };

  networking.wireless = {
    enable = true;
    networks = {
      "SSID" = {
        psk = "password";
      };
    };
  };

  system.stateVersion = "24.05";
}
