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
  options.custom.ocaml = lib.mkEnableOption "ocaml";

  config = lib.mkIf cfg.ocaml {
    environment.systemPackages = with pkgs; [
    ];
  };
}
