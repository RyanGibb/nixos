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

  age.secrets.restic-owl.file = ../../secrets/restic-owl.age;
  services.restic.backups.${config.networking.hostName} = {
    repository = "rest:http://100.64.0.9:8000/${config.networking.hostName}/";
    passwordFile = config.age.secrets.restic-owl.path;
    initialize = true;
    paths = [
      "/var/lib/"
      "/etc/"
      "/home/"
    ];
    timerConfig = {
      OnCalendar = "03:00";
      randomizedDelaySec = "1hr";
    };
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 12"
      "--keep-yearly 10"
    ];
  };
}
