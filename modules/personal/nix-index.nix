{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.nix-index ];
  programs.command-not-found.enable = false;
  programs.zsh.interactiveShellInit = ''
    source ${pkgs.nix-index}/etc/profile.d/command-not-found.sh
  '';
}
