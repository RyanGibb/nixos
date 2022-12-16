{ config, lib, ... }:

let cfg = config.personal; in
{
  config = lib.mkIf cfg.enable {
    environment.interactiveShellInit = "export PATH=$PATH:/etc/nixos/scripts";
  };
}
