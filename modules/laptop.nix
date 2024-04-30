{ pkgs, config, lib, ... }:

let cfg = config.custom;
in {
  options.custom.laptop = lib.mkEnableOption "laptop";

  config = lib.mkIf cfg.laptop {
    users.users.${config.custom.username}.extraGroups = [ "input" ];

    services.xserver.libinput.enable = true;

    services.tlp.enable = true;
    powerManagement.enable = true;

    systemd.sleep.extraConfig = ''
      HibernateDelaySec=1h
    '';

    services.logind.lidSwitch = "suspend-then-hibernate";

    environment.systemPackages = with pkgs; [
      fusuma
      kanshi
      v4l-utils # for qv4l2
    ];
  };
}
