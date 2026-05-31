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
      khal
      todoman
    ];

    programs = {
      password-store.enable = true;
      password-store.settings.PASSWORD_STORE_DIR = "$XDG_DATA_HOME/password-store";
      gpg.enable = true;
    };

    services = {
      gpg-agent.enable = true;
    };
  };
}
