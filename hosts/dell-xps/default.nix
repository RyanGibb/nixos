{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/default.nix
    ../../modules/personal/default.nix
    ../../modules/personal/laptop.nix
    ../../modules/personal/gui/sway.nix
    ../../modules/personal/gui/i3.nix
    ../../modules/personal/gui/extra.nix
    ../../modules/ocaml.nix
    ../../modules/personal/printing.nix
    ../../modules/hosting/wireguard/default.nix
  ];

  services.tailscale.enable = true;

  custom.machineColour = "blue";

  boot.loader.grub = {
    enable = true;
    default = "saved";
    device = "nodev";
    efiSupport = true;
    useOSProber = true;
  };

  boot.supportedFilesystems = [ "ntfs" ];

  environment.systemPackages = with pkgs; [
    cctk
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
