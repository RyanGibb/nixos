{ pkgs, config, lib, eilean, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "cl-vps";
  personal = {
    enable = true;
    tailscale = true;
    machineColour = "green";
  };

  swapDevices = [ { device = "/var/swap"; size = 2048; } ];

  dns = {
    zones."example.com" = {
      soa.serial = lib.mkDefault 2018011626;
      records = [
        { name = "@"; type = "A"; data = "127.0.0.1"; }
      ];
    };
  };

  services = {
    aeon = {
      enable = true;
      # TODO make this zonefile derivation a config parameter `services.dns.zonefile`
      # TODO add module in eilean for aeon
      zoneFile = "${import "${eilean}/modules/dns/zonefile.nix" { inherit pkgs config lib; zonename = "example.com"; zone = config.dns.zones."example.com"; }}/example.com";
      logLevel = 1;
      application = "tund";
    };
  };
}
