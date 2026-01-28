{
  pkgs,
  config,
  lib,
  ...
}@inputs:

{
  imports = [
    ./hardware-configuration.nix
    ./minimal.nix
    ./services.nix
  ];

  nixpkgs.overlays = [
    (final: prev: {
      mautrix-whatsapp = final.overlay-unstable.mautrix-whatsapp;
    })
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

  age.secrets.restic-owl.file = ../../secrets/restic-owl.age;
  services.restic.backups.${config.networking.hostName} = {
    repository = "rest:http://100.64.0.9:8000/${config.networking.hostName}/";
    passwordFile = config.age.secrets.restic-owl.path;
    initialize = true;
    paths = [
      "/var/"
      "/etc/"
      "/home/"
    ];
    timerConfig = {
      OnCalendar = "03:00";
      randomizedDelaySec = "1hr";
    };
  };

  services.postgresql.package = pkgs.postgresql_17;
}
