{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  personal = {
    enable = true;
    machineColour = "blue";
    laptop = true;
    printing = true;
    ocaml = true;
    gui.i3 = true;
    gui.sway = true;
    gui.extra = true;
  };

  services.tailscale.enable = true;

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
