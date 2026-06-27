{
  config,
  lib,
  pkgs,
  nixpkgs,
  ...
}:

# build with:
#   nix build /etc/nixos#nixosConfigurations.barnacle.config.system.build.isoImage

{
  imports = [
    "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-base.nix"
    # installs nixpkgs channel for installation
    "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  # installer media has no root zfs pool; adopt the 26.11 default
  boot.zfs.forceImportRoot = false;

  custom = {
    enable = true;
    laptop = true;
    gui.i3 = true;
    gui.sway = true;
    homeManager.enable = true;
    username = "nixos";
  };
  users.users.${config.custom.username}.hashedPassword = lib.mkForce null;
  users.users.root.hashedPassword = lib.mkForce null;

  # recovery tool: recreate the grub UEFI NVRAM entry after a firmware reset wipes it
  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "fix-uefi-boot";
      runtimeInputs = [ pkgs.efibootmgr ];
      text = builtins.readFile ./fix-uefi-boot.sh;
    })
  ];

  services.openssh.settings.PermitRootLogin = lib.mkForce "no";
  services.getty.autologinUser = lib.mkForce "${config.custom.username}";
  services.getty.helpLine = lib.mkForce "";

  networking.wireless = {
    # so we can use NetworkManager
    enable = lib.mkForce false;
    # networks = { "SSID" = { psk = "password"; }; };
  };

  home-manager.users.${config.custom.username}.config.home.file = {
    "install.sh".source = ./install.sh;
    "nixos" = {
      recursive = true;
      source = ../..;
    };
  };

  # comment this out to make a smaller image
  isoImage.squashfsCompression = "gzip -Xcompression-level 1";

  system.stateVersion = "24.05";
}
