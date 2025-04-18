{
  pkgs,
  config,
  lib,
  eilean,
  eon,
  ...
}:

{
  imports = [ ./hardware-configuration.nix ];

  custom = {
    enable = true;
    tailscale = true;
    autoUpgrade.enable = true;
    homeManager.enable = true;
  };

  home-manager.users.${config.custom.username}.config.custom.machineColour = "green";

  environment.systemPackages = with pkgs; [ xe-guest-utilities ];

  networking.domain = "cl.freumh.org";

  services = {
    eon = {
      enable = lib.mkForce true;
      # TODO make this zonefile derivation a config parameter `services.eilean.services.dns.zonefile`
      # TODO add module in eilean for eon
      zoneFiles = [
        "${
          import "${eilean}/modules/services/dns/zonefile.nix" {
            inherit pkgs config lib;
            zonename = "cl.freumh.org";
            zone = config.eilean.services.dns.zones."cl.freumh.org";
          }
        }/cl.freumh.org"
      ];
      logLevel = 1;
      application = "capd";
      capnpAddress = "cl.freumh.org";
      #prod = false;
    };
  };

  security.acme-eon = {
    acceptTerms = true;
    defaults.email = "${config.custom.username}@${config.networking.domain}";
    nginxCerts = [ config.networking.domain ];
    defaults.capFile = "/var/lib/eon/caps/domain/cl.freumh.org.cap";
  };

  services.nginx = {
    enable = true;
    virtualHosts."${config.networking.domain}" = {
      forceSSL = true;
      locations."/index.html".root = pkgs.writeTextFile {
        name = "freumh";
        text = ''
          <html>
          <body>
          <pre>
                ||
                \\
          _      ||    __
          \    / \\  /  \
            \__/   \\/
                    \\      __
              _    / \\    /  \_/
            _/ \  ||   \__/
                \//     \
                //       \
                ||        \_
          </html>
          </body>
          </pre>
        '';
        destination = "/index.html";
      };
    };
  };

  eilean.services.dns = {
    zones."cl.freumh.org" = {
      soa.serial = lib.mkDefault 3;
      records =
        let
          ipv4 = "128.232.113.136";
          ipv6 = "2a05:b400:110:1101:d051:f2ff:fe13:3781";
        in
        [
          {
            name = "@";
            type = "NS";
            value = "ns";
          }

          {
            name = "ns";
            type = "A";
            value = ipv4;
          }
          {
            name = "ns";
            type = "AAAA";
            value = ipv6;
          }

          {
            name = "@";
            type = "A";
            value = ipv4;
          }
          {
            name = "@";
            type = "AAAA";
            value = ipv6;
          }
          {
            name = "vps";
            type = "A";
            value = ipv4;
          }
          {
            name = "vps";
            type = "AAAA";
            value = ipv6;
          }
        ];
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      80 # HTTP
      443 # HTTPS
    ];
    allowedUDPPorts = [
      80 # HTTP
    ];
  };
}
