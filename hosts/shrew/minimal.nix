{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
  ];

  custom = {
    enable = true;
    tailscale = true;
    # autoUpgrade.enable = true;
    homeManager.enable = true;
  };

  home-manager.users.${config.custom.username}.config.custom.machineColour = "red";

  services.journald.extraConfig = ''
    SystemMaxUse=4G
  '';
}
