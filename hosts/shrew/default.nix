{ config, pkgs, lib, nixos-hardware, eilean, ... }:

{
  imports = [
    ./hardware-configuration.nix
    "${nixos-hardware}/raspberry-pi/4"
  ];

  personal = {
    enable = true;
    tailscale = true;
    machineColour = "red";
  };

  networking.networkmanager.enable = true;

  dns = {
    zones.${config.networking.domain} = {
      soa.serial = lib.mkDefault 2018011626;
      records = [
        { name = "@"; type = "A"; data = "127.0.0.1"; }
      ];
    };
  };

  services = {
    eon = {
      enable = true;
      # TODO make this zonefile derivation a config parameter `services.eilean.services.dns.zonefile`
      # TODO add module in eilean for eon
      zoneFile = "${import "${eilean}/modules/services/dns/zonefile.nix" { inherit pkgs config lib; zonename = config.networking.domain; zone = config.eilean.services.dns.zones.${config.networking.domain}; }}/${config.networking.domain}";
      logLevel = 2;
      application = "tund";
    };
  };

  services.journald.extraConfig = ''
    SystemMaxUse=4G
  '';
}
