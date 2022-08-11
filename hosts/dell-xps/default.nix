{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common/default.nix
    ../../modules/common/laptop.nix
    ../../modules/gui/sway.nix
    ../../modules/gui/i3.nix
    ../../modules/gui/extra.nix
    ../../modules/ocaml.nix
    ../../modules/services/wireguard/default.nix
  ];

  services.tailscale.enable = true;

  machineColour = "blue";

  boot.loader.grub = {
    enable = true;
    default = "saved";
    device = "nodev";
    efiSupport = true;
    useOSProber = true;
  };

  boot.supportedFilesystems = [ "ntfs" ];

  environment.systemPackages = with pkgs; [
    (pkgs.callPackage ../../pkgs/cctk.nix { })
    (python3.withPackages (p: with p; [
      numpy
      matplotlib
      pandas
    ]))
    python39Packages.pip
    jupyter
    vagrant
    discord
    teams
  ];

  programs.steam.enable = true;
}
