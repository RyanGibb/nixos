{
  config,
  lib,
  ...
}:

let
  cfg = config.custom;
in
{
  options.custom.workstation = lib.mkEnableOption "custom";

  config = lib.mkIf cfg.workstation {
    services.localtimed.enable = true;
    services.geoclue2 = {
      enable = true;
      geoProviderUrl = "https://api.beacondb.net/v1/geolocate";
    };
  };
}
