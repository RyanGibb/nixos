{ pkgs, config, lib, nixpkgs-unstable, ... }:

let cfg = config.personal.gui; in
{
  disabledModules = [ "services/system/localtime.nix" ];
  imports = [
    "${nixpkgs-unstable}/nixos/modules/services/system/localtimed.nix"
    "${nixpkgs-unstable}/nixos/modules/services/system/localtimed.nix"
  ];

  config = lib.mkIf cfg.enable {
    # used localtimed that is fixed in unstable
    # https://discourse.nixos.org/t/how-to-use-service-definitions-from-unstable-channel/14767
    # TODO use localtime package from unstable
    
    ids.uids.localtimed = 325;
    ids.gids.localtimed = 325;
    # once merged into 22.05 delete the above 9 lines
    services.localtimed.enable = true;
    services.geoclue2.enable = true;
  };
}
