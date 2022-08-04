{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    ocaml
    opam
    dune_2
    ocamlPackages.utop
    pkg-config
    gcc
    gmp
    bintools-unwrapped
    libseccomp
  ];

  programs.zsh.interactiveShellInit = "eval $(opam env)";
  programs.bash.shellInit = "eval $(opam env)";
}
