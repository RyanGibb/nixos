{ pkgs, ... }:

{
  imports = [
    ../../hardware-configuration.nix
    ../common/default.nix
    ../common/laptop.nix
    ../gui/sway.nix
    ../gui/i3.nix
    ../ocaml.nix
    ../services/wireguard/default.nix
    <home-manager/nixos>
  ];

  services.tailscale.enable = true;

  networking.hostName = "dell-xps";
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
