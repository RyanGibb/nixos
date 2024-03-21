{ pkgs, config, lib, eilean, ryan-website, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  personal = {
    enable = true;
    tailscale = true;
    machineColour = "green";
  };

  swapDevices = [ { device = "/var/swap"; size = 2048; } ];

  environment.systemPackages = with pkgs; [
    xe-guest-utilities
  ];

  eilean.services.dns = {
    zones."cl.freumh.org" = {
      soa.serial = lib.mkDefault 1;
      records =
        let
          ipv4 = "128.232.113.136";
          ipv6 = "2a05:b400:110:1101:d051:f2ff:fe13:3781";
        in [
          { name = "@";   type = "NS"; data = "ns"; }

          { name = "ns"; type = "A";    data = ipv4; }
          { name = "ns"; type = "AAAA"; data = ipv6; }

          { name = "@";   type = "A";    data = ipv4; }
          { name = "@";   type = "AAAA"; data = ipv6; }
          { name = "vps"; type = "A";    data = ipv4; }
          { name = "vps"; type = "AAAA"; data = ipv6; }
      ];
    };
  };

  security.acme = {
    defaults.email = "${config.eilean.username}@${config.networking.domain}";
    acceptTerms = true;
  };

  systemd.services.eeww = {
    enable = true;
    description = "eeww";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.eeww}/main.exe -p 80";
      WorkingDirectory = "${ryan-website.packages.${config.nixpkgs.hostPlatform.system}.default}";
      Restart = "always";
      RestartSec = "10s";
      AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
      User = "eeww";
      Group = "eeww";
    };
  };

  users.users."eeww" = {
    description = "eeww";
    useDefaultShell = true;
    group = "eeww";
    isSystemUser = true;
  };

  users.groups."eeww" = {};

  networking.firewall = {
    allowedTCPPorts = [
      80   # HTTP
      443  # HTTPS
    ];
    allowedUDPPorts = [
      80   # HTTP
    ];
  };

  services = {
    eon = {
      enable = true;
      # TODO make this zonefile derivation a config parameter `services.eilean.services.dns.zonefile`
      # TODO add module in eilean for eon
      zoneFile = "${import "${eilean}/modules/services/dns/zonefile.nix" { inherit pkgs config lib; zonename = "cl.freumh.org"; zone = config.eilean.services.dns.zones."cl.freumh.org"; }}/cl.freumh.org";
      logLevel = 1;
      application = "tund";
    };
  };
}
