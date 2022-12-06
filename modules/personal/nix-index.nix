{ pkgs, config, lib, ... }:

let cfg = config.personal; in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.nix-index ];
    programs.command-not-found.enable = false;
    programs.zsh.interactiveShellInit = ''
      source ${pkgs.nix-index}/etc/profile.d/command-not-found.sh
    '';
  };
}
