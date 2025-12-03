{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.custom;
in
{
  options.custom.laptop = lib.mkEnableOption "laptop";

  config = lib.mkIf cfg.laptop {
    users.users.${config.custom.username}.extraGroups = [ "input" ];

    services.libinput.enable = true;

    services.power-profiles-daemon.enable = false;
    services.tlp.enable = true;
    powerManagement.enable = true;

    systemd.sleep.extraConfig = ''
      HibernateDelaySec=1h
    '';

    # https://github.com/systemd/systemd/issues/12001#issuecomment-1711464475
    services.logind.settings.Login.HandleLidSwitch = "ignore";

    environment.systemPackages = with pkgs; [
      fusuma
      kanshi
      v4l-utils # for qv4l2
    ];
  };
}
