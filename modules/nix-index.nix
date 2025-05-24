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
  options.custom.useNixIndex = lib.mkOption {
    type = lib.types.bool;
    default = false;
  };

  config = lib.mkIf cfg.useNixIndex {
    environment.systemPackages = [ pkgs.nix-index ];
    programs.command-not-found.enable = false;
    home-manager.users.${config.custom.username} =
      { ... }:
      {
        programs.zsh.initContent = ''
          source ${pkgs.nix-index}/etc/profile.d/command-not-found.sh
        '';
      };
  };
}
