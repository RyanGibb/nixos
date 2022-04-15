{ pkgs, ... }:

{
  imports = [
    ./common.nix
    ./gui.nix
    ./kde.nix
    <home-manager/nixos> 
  ];

  boot.loader.grub = {
    enable = true;
    default = "saved";
    device = "nodev";
    efiSupport = true;
    useOSProber = true;
  };

  networking = {
    hostName = "dell-xps";
    useDHCP = false;
    interfaces.wlp0s20f3.useDHCP = true;
  };

  users = {
    users.ryan = {
      hashedPassword = "$6$tX0uyjRP0KEeHbCe$tz2MmUInPh/y/nE6Xy1am4OfNvffLvynb/tB9HskzmaGiatCzlSEcVnPkM6vCXNxzjU4dDgda85HG3kz/XZEs/";
      extraGroups = [ "input" ];
    ]:
    users.root.hashedPassword = "$6$tX0uyjRP0KEeHbCe$tz2MmUInPh/y/nE6Xy1am4OfNvffLvynb/tB9HskzmaGiatCzlSEcVnPkM6vCXNxzjU4dDgda85HG3kz/XZEs/";
  };

  # Needed for Keychron K2
  boot.extraModprobeConfig = ''
    options hid_apple fnmode=2
  '';
  boot.kernelModules = [ "hid-apple" ];

  boot.supportedFilesystems = [ "ntfs" ];

  # printing
  networking.firewall = rec {
    allowedTCPPorts = [
      631 
    ]; 
    allowedUDPPorts = allowedTCPPorts;
  };
  services.printing = {
    enable = true;
    browsing = true;
    defaultShared = true;
  };
  services.avahi = {
    enable = true;
    publish.enable = true;
    publish.userServices = true;
    nssmdns = true;
  };

  services.tlp.enable = true;
  powerManagement.enable = true;
  virtualisation.libvirtd.enable = true;

  environment.systemPackages = with pkgs;
  let
    python-with-packages = pkgs.python3.withPackages (p: with p; [
      numpy
      matplotlib
      pandas
    ]);
  in [
    fusuma
    kanshi
    acpi
    python-with-packages
    python39Packages.pip
    jupyter
    vagrant
    (pkgs.callPackage ./pkgs/cctk.nix { })
    kdenlive
    tor-browser-bundle-bin
    zoom-us
    discord
    ffmpeg
    audio-recorder
    opam
    ocaml
    dune_2
  ];

  programs.steam.enable = true;

  system.stateVersion = "21.11";
}
