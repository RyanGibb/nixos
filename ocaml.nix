{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    opam
    ocaml
    dune_2
    ocamlPackages.utop
    pkg-config
  ];

  programs.zsh.interactiveShellInit = "eval $(opam env)";
  programs.bash.shellInit = "eval $(opam env)";
}
