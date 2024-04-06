{ config, lib, ... }:

let cfg = config.custom;
in {
  config = lib.mkIf cfg.enable {
    environment.interactiveShellInit = "export PATH=$PATH:/etc/nixos/scripts";
  };
}
