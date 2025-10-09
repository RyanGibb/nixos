{
  config,
  ...
}:

{
  imports = [ ./hardware-configuration.nix ];

  custom = {
    enable = true;
    tailscale = true;
    autoUpgrade.enable = true;
    homeManager.enable = true;
  };

  home-manager.users.${config.custom.username}.config.custom.machineColour = "yellow";

  boot.tmp.cleanOnBoot = true;

  services.journald.extraConfig = ''
    SystemMaxUse=4G
  '';
}
