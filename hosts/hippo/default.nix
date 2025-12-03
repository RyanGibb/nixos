{
  pkgs,
  config,
  lib,
  disko,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    disko.nixosModules.disko
    ./disk-config.nix
    ./services.nix
  ];

  custom = {
    enable = true;
    autoUpgrade.enable = true;
    homeManager.enable = true;
  };

  virtualisation.docker.enable = true;

  home-manager.users.${config.custom.username}.config.custom.machineColour = "blue";

  networking.hostName = "iphito";

  services.openssh.openFirewall = true;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA7UrJmBFWR3c7jVzpoyg4dJjON9c7t9bT9acfrj6G7i mtelvers"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICMmmaDFqSmbQLnPuTtg32wBdJs1xsituz3jrJBqlM1u avsm"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEl1IdWeuW+VmNdfAojJhjn3vVrNnZk4ukhxspeh4ikL avsm"
  ];

  environment.systemPackages = with pkgs; [
    cargo
    rustup
    python3Packages.pip
    python3
    nodejs
    overlay-unstable.claude-code
  ];

  system.stateVersion = "24.05";
}
