{
  config,
  lib,
  ...
}:

let
  cfg = config.custom.atuin;
in
{
  options.custom.atuin.enable = lib.mkEnableOption "atuin";

  config = lib.mkIf cfg.enable {
    programs.atuin = {
      enable = true;
      enableZshIntegration = true;
      daemon.enable = true;
      flags = [ "--disable-up-arrow" ];
      settings = {
        sync_address = "https://atuin.freumh.org";
        auto_sync = true;
        sync_frequency = "5m";
        update_check = false;
        search_mode = "skim";
      };
    };
  };
}
