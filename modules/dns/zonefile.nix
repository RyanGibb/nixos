{ pkgs, config, lib, ... }:

let cfg = config.dns; in pkgs.writeTextFile {
  name = "zonefile";
  text = ''
    
  '';
}
