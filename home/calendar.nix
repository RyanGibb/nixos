{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.custom.calendar;
in
{
  options.custom.calendar.enable = lib.mkEnableOption "calendar";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      vdirsyncer
    ];

    programs = {
      password-store.enable = true;
      gpg.enable = true;
    };

    services = {
      gpg-agent.enable = true;
    };
  };
}
