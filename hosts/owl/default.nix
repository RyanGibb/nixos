{
  pkgs,
  lib,
  ...
}@inputs:

{
  imports = [
    ./hardware-configuration.nix
    ./minimal.nix
    ./services.nix
    ../../modules/ryan-website.nix
    ../../modules/alec-website.nix
    ../../modules/fn06-website.nix
    inputs.tangled.nixosModules.knotserver
  ];

  environment.systemPackages = with pkgs; [
    nixd
    nixfmt-rfc-style
  ];

  nix = {
    gc = {
      automatic = true;
      dates = lib.mkForce "03:00";
      randomizedDelaySec = "1hr";
      options = lib.mkForce "--delete-older-than 2d";
    };
  };

  services.openssh.openFirewall = true;

  users.mutableUsers = lib.mkForce true;
}
