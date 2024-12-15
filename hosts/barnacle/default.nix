{
  config,
  lib,
  pkgs,
  nixpkgs,
  ...
}:

{
  imports = [
    "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-base.nix"
    # installs nixpkgs channel for installation
    "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  custom = {
    enable = true;
    laptop = true;
    gui.i3 = true;
    gui.sway = true;
    homeManager.enable = true;
    username = "nixos";
  };
  users.users.nixos.hashedPassword = lib.mkForce null;
  users.users.root.hashedPassword = lib.mkForce null;

  services.openssh.settings.PermitRootLogin = lib.mkForce "no";
  services.getty.autologinUser = lib.mkForce "${config.custom.username}";
  services.getty.helpLine = lib.mkForce "";

  networking.wireless = {
    # so we can use NetworkManager
    enable = lib.mkForce false;
    # networks = { "SSID" = { psk = "password"; }; };
  };

  # build with:
  #   nix build /etc/nixos#nixosConfigurations.barnacle.config.system.build.isoImage
  isoImage.contents = [
    {
      source = ../..;
      target = "nixos";
    }
  ];

  # comment this out to make a smaller image
  isoImage.squashfsCompression = "gzip -Xcompression-level 1";
}
