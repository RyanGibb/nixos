{ pkgs, config, lib, ... }:

let cfg = config.custom;
in {
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.nix-index ];
    programs.command-not-found.enable = false;
    home-manager.users.${config.custom.username} = { ... }: {
      programs.zsh.initExtra = ''
        source ${pkgs.nix-index}/etc/profile.d/command-not-found.sh
      '';
    };
  };
}
