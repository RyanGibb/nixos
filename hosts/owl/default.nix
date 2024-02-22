{ pkgs, config, lib, eilean, ... }@inputs:

{
  imports = [
    ./hardware-configuration.nix
    ./minimal.nix
    inputs.colour-guesser.nixosModules.default
    inputs.ryan-website.nixosModules.default
    inputs.alec-website.nixosModules.default
    inputs.fn06-website.nixosModules.default
  ];

  eilean = {
    publicInterface = "enp1s0";

    mailserver.enable = true;
    matrix.enable = true;
    turn.enable = true;
    mastodon.enable = true;
    headscale.enable = true;
    #dns.enable = lib.mkForce false;
  };

  hosting = {
    freumh.enable = true;
    nix-cache.enable = true;
    rmfakecloud.enable = true;
  };

  eilean.services.dns.zones = {
    ${config.networking.domain} = {
      soa.serial = 2018011656;
      records = [
        { name = "@"; type = "TXT"; data = "google-site-verification=rEvwSqf7RYKRQltY412qMtTuoxPp64O3L7jMotj9Jnc"; }
        { name = "teapot"; type = "CNAME"; data = "vps"; }

        { name = "@";   type = "NS"; data = "ns1"; }
        { name = "@";   type = "NS"; data = "ns2"; }

        { name = "ns1"; type = "A";    data = config.eilean.serverIpv4; }
        { name = "ns1"; type = "AAAA"; data = config.eilean.serverIpv6; }
        { name = "ns2"; type = "A";    data = config.eilean.serverIpv4; }
        { name = "ns2"; type = "AAAA"; data = config.eilean.serverIpv6; }

        { name = "@";   type = "A";    data = config.eilean.serverIpv4; }
        { name = "@";   type = "AAAA"; data = config.eilean.serverIpv6; }
        { name = "vps"; type = "A";    data = config.eilean.serverIpv4; }
        { name = "vps"; type = "AAAA"; data = config.eilean.serverIpv6; }

        { name = "@"; type = "LOC"; data = "52 12 40.4 N 0 5 31.9 E 22m 10m 10m 10m"; }

        { name = "ns.cl"; type = "A"; data = "128.232.113.136"; }
        { name = "cl"; type = "NS"; data = "ns.cl"; }

        { name = "ns1.eilean"; type = "A"; data = "65.109.10.223"; }
        { name = "eilean"; type = "NS"; data = "ns1.eilean"; }

        { name = "shrew"; type = "CNAME"; data = "vps"; }

        { name = "_25._tcp.mail"; type = "TLSA"; data = "3 1 1 75db0cb2b465b417f0316b28f633e34858984dd0e88e79408fce7be1f7574047"; }
        # LE R3
        { name = "_25._tcp.mail"; type = "TLSA"; data = "2 1 1 67add1166b020ae61b8f5fc96813c04c2aa589960796865572a3c7e737613dfd"; }
        # LE E1
        { name = "_25._tcp.mail"; type = "TLSA"; data = "2 1 1 46494e30379059df18be52124305e606fc59070e5b21076ce113954b60517cda"; }
        # LE R4
        { name = "_25._tcp.mail"; type = "TLSA"; data = "2 1 1 5a8f16fda448d783481cca57a2428d174dad8c60943ceb28f661ae31fd39a5fa"; }
        # LE E2
        { name = "_25._tcp.mail"; type = "TLSA"; data = "2 1 1 bacde0463053ce1d62f8be74370bbae79d4fcaf19fc07643aef195e6a59bd578"; }
      ];
    };
    "fn06.org" = {
      soa.serial = 1706745601;
      records = [
        {
          name = "capybara.fn06.org";
          type = "CNAME";
          data = "fn06.org";
        }
      ];
    };
  };
  services.bind.zones.${config.networking.domain}.extraConfig = ''
    dnssec-policy default;
    inline-signing yes;
    journal "${config.services.bind.directory}/${config.networking.domain}.signed.jnl";
  '';

  services.nginx = {
    commonHttpConfig = ''
      add_header Strict-Transport-Security max-age=31536000 always;
      add_header X-Frame-Options SAMEORIGIN always;
      add_header X-Content-Type-Options nosniff always;
      add_header Content-Security-Policy "default-src 'self'; base-uri 'self'; frame-src 'self'; frame-ancestors 'self'; form-action 'self';" always;
      add_header Referrer-Policy 'same-origin';
    '';
    virtualHosts = {
      "teapot.${config.networking.domain}" = {
        extraConfig = ''
          return 418;
        '';
      };
      "${config.services.ryan-website.domain}" = {
        locations."/phd/" = {
          basicAuthFile= "${config.custom.secretsDir}/website-phd";
        };
      };
      "capybara.fn06.org" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = ''
            http://100.64.0.10:8123
          '';
          proxyWebsockets = true;
        };
      };
      "shrew.freumh.org" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          # need to specify ip or there's a bootstrap problem with headscale
          proxyPass = ''
            http://100.64.0.6:8123
          '';
          proxyWebsockets = true;
        };
      };
    };
  };

  services = {
    ryan-website = {
      enable = true;
      cname = "vps";
      cv = inputs.ryan-cv.defaultPackage.${pkgs.stdenv.hostPlatform.system};
      keys = pkgs.stdenv.mkDerivation {
        name = "ryan-keys";
        src = ../../modules/personal/authorized_keys;
        phases = [ "buildPhase" ];
        buildPhase = ''
          touch $out
          cat $src | cut -d' ' -f-2 > $out
        '';
      };
    };
    alec-website = {
      enable = true;
      cname = "vps";
    };
    fn06-website = {
      enable = true;
      cname = "vps";
      domain = "fn06.org";
    };
    colour-guesser = {
      enable = true;
      cname = "vps";
    };
    eeww = {
      #enable = true;
      domain = config.services.ryan-website.domain;
    };
    #eon = {
    #  enable = true;
    #  # TODO make this zonefile derivation a config parameter `services.eilean.services.dns.zonefile`
    #  # TODO add module in eilean for eon
    #  zoneFile = "${import "${eilean}/modules/services/dns/zonefile.nix" { inherit pkgs config lib; zonename = config.networking.domain; zone = config.eilean.services.dns.zones.${config.networking.domain}; }}/${config.networking.domain}";
    #  logLevel = 2;
    #};
  };

  services.signald.enable = true;
  systemd.services.matrix-as-signal = {
    requires = [ "signald.service" ];
    after = [ "signald.service" ];
    # voice messages need `ffmpeg`
    path = [ pkgs.ffmpeg ];
  };
  systemd.services.matrix-as-facebook = {
    # voice messages need `ffmpeg`
    path = [ pkgs.ffmpeg ];
  };

  services.matrix-appservices = {
    addRegistrationFiles = true;
    homeserverURL = "https://matrix.${config.networking.domain}";
    services = {
      whatsapp = {
        port = 29183;
        format = "mautrix-go";
        package = pkgs.mautrix-whatsapp;
        settings.bridge.personal_filtering_spaces = true;
        settings.bridge.displayname_template = "{{or .BusinessName .PushName .FullName .JID}} (WA)";
      };
      signal = {
        port = 29184;
        format = "mautrix-python";
        package = pkgs.mautrix-signal;
        serviceConfig = {
          StateDirectory = [ "matrix-as-signal" ];
          SupplementaryGroups = [ "signald" ];
        };
        settings.signal = {
          socket_path = config.services.signald.socketPath;
          outgoing_attachment_dir = "/var/lib/signald/tmp";
        };
      };
      facebook = {
        port = 29185;
        format = "mautrix-python";
        package = pkgs.mautrix-facebook;
        settings.bridge.space_support.enable = true;
        settings.bridge.backfill.enable = false;
      };
      instagram = {
        port = 29187;
        format = "mautrix-python";
        package = pkgs.mautrix-instagram;
      };
    };
  };

  services.mastodon = {
    webProcesses = lib.mkForce 1;
    webThreads = lib.mkForce 1;
    sidekiqThreads = lib.mkForce 1;
    streamingProcesses = lib.mkForce 1;
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  mailserver.loginAccounts."${config.custom.username}@${config.networking.domain}".sieveScript = ''
    require ["fileinto", "mailbox"];

    if header :contains ["to", "cc"] ["~rjarry/aerc-discuss@lists.sr.ht"] {
      fileinto :create "lists.aerc";
      stop;
    }
  '';

  services.headscale.settings.dns_config.extra_records = [
    {
      name = "jellyfin.vpn.${config.networking.domain}";
      type = "CNAME";
      value = "elephant.vpn.${config.networking.domain}";
    }
    {
      name = "nextcloud.vpn.${config.networking.domain}";
      type = "CNAME";
      value = "elephant.vpn.${config.networking.domain}";
    }
    {
      name = "transmission.vpn.${config.networking.domain}";
      type = "CNAME";
      value = "elephant.vpn.${config.networking.domain}";
    }
  ];
}
