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
  ];

  custom = {
    enable = true;
    autoUpgrade.enable = true;
    homeManager.enable = true;
  };

  home-manager.users.${config.custom.username}.config.custom.machineColour = "blue";

  networking.hostName = "iphito";

  services.openssh.openFirewall = true;
}
