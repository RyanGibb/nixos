{ pkgs, config, lib, ... }:

let cfg = config.personal;
in {
  options.personal.ocaml = lib.mkEnableOption "ocaml";

  config = lib.mkIf cfg.ocaml {
    environment.systemPackages = with pkgs; [
      ocaml
      opam
      dune_3
      ocamlPackages.utop
      pkg-config
      gcc
      gmp
      bintools-unwrapped
      libseccomp
      opam
      capnproto
      gmp
      sqlite
    ];

    programs.zsh.interactiveShellInit = "eval $(opam env)";
    programs.bash.shellInit = "eval $(opam env)";
  };
}
