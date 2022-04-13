# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    tree
    htop
    bind
    inetutils
    ncdu
    nix-prefetch-git
    gnumake
    bat
    killall
    ncat
  ];
}
