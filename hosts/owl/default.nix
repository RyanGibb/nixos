{
  pkgs,
  config,
  lib,
  eon,
  ...
}@inputs:

let
  vpnRecords = [
    {
      name = "nix-cache.vpn.${config.networking.domain}.";
      type = "A";
      value = "100.64.0.9";
    }
    {
      name = "jellyfin.vpn.${config.networking.domain}.";
      type = "A";
      value = "100.64.0.9";
    }
    {
      name = "nextcloud.vpn.${config.networking.domain}.";
      type = "A";
      value = "100.64.0.9";
    }
    {
      name = "transmission.vpn.${config.networking.domain}.";
      type = "A";
      value = "100.64.0.9";
    }
    {
      name = "owntracks.vpn.${config.networking.domain}.";
      type = "A";
      value = "100.64.0.9";
    }
    {
      name = "immich.vpn.${config.networking.domain}.";
      type = "A";
      value = "100.64.0.9";
    }
  ];
in
{
  imports = [
    ./hardware-configuration.nix
    ./minimal.nix
    ../../modules/colour-guesser.nix
    ../../modules/ryan-website.nix
    ../../modules/alec-website.nix
    ../../modules/fn06-website.nix
  ];

  environment.systemPackages = with pkgs; [
    # nix
    nixd
    nixfmt-rfc-style
  ];

  age.secrets.eon-capnp = {
    file = ../../secrets/eon-capnp.age;
    mode = "770";
    owner = "eon";
    group = "eon";
  };
  age.secrets.eon-sirref-primary = {
    file = ../../secrets/eon-sirref-primary.cap.age;
    mode = "770";
    owner = "eon";
    group = "eon";
  };
  services.eon = {
    capnpSecretKeyFile = config.age.secrets.eon-capnp.path;
    primaries = [ config.age.secrets.eon-sirref-primary.path ];
    prod = true;
    capnpAddress = "135.181.100.27";
    logLevel = 0;
  };

  security.acme-eon = {
    acceptTerms = true;
    package = eon.defaultPackage.${config.nixpkgs.hostPlatform.system};
    defaults.email = "${config.custom.username}@${config.networking.domain}";
    defaults.capFile = "/var/lib/eon/caps/domain/freumh.org.cap";
    certs = {
      "fn06.org".capFile = "/var/lib/eon/caps/domain/fn06.org.cap";
      "capybara.fn06.org".capFile = "/var/lib/eon/caps/domain/fn06.org.cap";
    };
  };

  eilean = {
    username = config.custom.username;
    serverIpv4 = "135.181.100.27";
    serverIpv6 = "2a01:4f9:c011:87ad:0:0:0:0";
    acme-eon = true;
    fail2ban.enable = true;
  };
  networking.domain = lib.mkDefault "freumh.org";
  eilean.publicInterface = "enp1s0";
  eilean.mailserver.enable = true;
  eilean.radicale = {
    enable = true;
    users = null;
  };
  age.secrets.matrix-shared-secret = {
    file = ../../secrets/matrix-shared-secret.age;
    mode = "770";
    owner = "${config.systemd.services.matrix-synapse.serviceConfig.User}";
    group = "${config.systemd.services.matrix-synapse.serviceConfig.Group}";
  };
  eilean.matrix = {
    enable = true;
    registrationSecretFile = config.age.secrets.matrix-shared-secret.path;
    bridges.whatsapp = true;
    bridges.signal = true;
    bridges.instagram = true;
    bridges.messenger = true;
  };
  eilean.turn.enable = true;
  eilean.mastodon.enable = true;
  eilean.headscale.enable = true;
  #eilean.dns.enable = lib.mkForce false;

  systemd.services.matrix-as-meta = {
    # voice messages need `ffmpeg`
    path = [ pkgs.ffmpeg ];
  };

  custom = {
    freumh.enable = true;
    rmfakecloud.enable = true;
    website = {
      ryan = {
        enable = true;
        cname = "vps";
      };
      alec = {
        enable = true;
        cname = "vps";
      };
      fn06 = {
        enable = true;
        cname = "vps";
        domain = "fn06.org";
      };
      colour-guesser = {
        # enable = true;
        cname = "vps";
      };
    };
  };

  eilean.dns.nameservers = [ "ns1" ];
  eilean.services.dns.zones = {
    ${config.networking.domain} = {
      ttl = 300;
      soa = {
        serial = 2018011660;
        refresh = 300;
      };
      records = [
        {
          name = "@";
          type = "TXT";
          value = "google-site-verification=rEvwSqf7RYKRQltY412qMtTuoxPp64O3L7jMotj9Jnc";
        }
        {
          name = "_atproto.ryan";
          type = "TXT";
          value = "did=did:plc:3lfhu6ehlynzjgehef6alnvg";
        }

        {
          name = "teapot";
          type = "CNAME";
          value = "vps";
        }

        {
          name = "@";
          type = "NS";
          value = "ns1.sirref.org.";
        }

        {
          name = "@";
          type = "A";
          value = config.eilean.serverIpv4;
        }
        {
          name = "@";
          type = "AAAA";
          value = config.eilean.serverIpv6;
        }
        {
          name = "vps";
          type = "A";
          value = config.eilean.serverIpv4;
        }
        {
          name = "vps";
          type = "AAAA";
          value = config.eilean.serverIpv6;
        }

        {
          name = "@";
          type = "LOC";
          value = "52 12 40.4 N 0 5 31.9 E 22m 10m 10m 10m";
        }

        {
          name = "ns.cl";
          type = "A";
          value = "128.232.113.136";
        }
        {
          name = "cl";
          type = "NS";
          value = "ns.cl";
        }

        {
          name = "ns1.eilean";
          type = "A";
          value = "65.109.10.223";
        }
        {
          name = "eilean";
          type = "NS";
          value = "ns1.eilean";
        }

        {
          name = "shrew";
          type = "CNAME";
          value = "vps";
        }

        # generate with
        #   sudo openssl x509 -in /var/lib/acme/mail.freumh.org/fullchain.pem -pubkey -noout | openssl pkey -pubin -outform der | sha256sum | awk '{print "3 1 1", $1}'
        {
          name = "_25._tcp.mail";
          type = "TLSA";
          value = "3 1 1 2f0fd413f063c75141937dd196a9f4ab66139d599e0dcf2a7ce6d557647e26a6";
        }
        # generate with
        #   for i in r3 e1 r4-cross-signed e2
        #   openssl x509 -in ~/downloads/lets-encrypt-$i.pem -pubkey -noout | openssl pkey -pubin -outform der | sha256sum | awk '{print "2 1 1", $1}'
        # LE R3
        {
          name = "_25._tcp.mail";
          type = "TLSA";
          value = "2 1 1 8d02536c887482bc34ff54e41d2ba659bf85b341a0a20afadb5813dcfbcf286d";
        }
        # LE E1
        {
          name = "_25._tcp.mail";
          type = "TLSA";
          value = "2 1 1 276fe8a8c4ec7611565bf9fce6dcace9be320c1b5bea27596b2204071ed04f10";
        }
        # LE R4
        {
          name = "_25._tcp.mail";
          type = "TLSA";
          value = "2 1 1 e5545e211347241891c554a03934cde9b749664a59d26d615fe58f77990f2d03";
        }
        # LE E2
        {
          name = "_25._tcp.mail";
          type = "TLSA";
          value = "2 1 1 bd936e72b212ef6f773102c6b77d38f94297322efc25396bc3279422e0c89270";
        }
      ] ++ vpnRecords;
    };
    "fn06.org" = {
      soa.serial = 1706745602;
      records = [
        {
          name = "@";
          type = "NS";
          value = "ns1";
        }
        {
          name = "@";
          type = "NS";
          value = "ns2";
        }

        {
          name = "ns1";
          type = "A";
          value = config.eilean.serverIpv4;
        }
        {
          name = "ns1";
          type = "AAAA";
          value = config.eilean.serverIpv6;
        }
        {
          name = "ns2";
          type = "A";
          value = config.eilean.serverIpv4;
        }
        {
          name = "ns2";
          type = "AAAA";
          value = config.eilean.serverIpv6;
        }

        {
          name = "@";
          type = "A";
          value = config.eilean.serverIpv4;
        }
        {
          name = "@";
          type = "AAAA";
          value = config.eilean.serverIpv6;
        }

        {
          name = "www.fn06.org.";
          type = "CNAME";
          value = "fn06.org.";
        }

        {
          name = "@";
          type = "LOC";
          value = "52 12 40.4 N 0 5 31.9 E 22m 10m 10m 10m";
        }

        {
          name = "capybara.fn06.org.";
          type = "CNAME";
          value = "fn06.org.";
        }

        {
          name = "jellyfin.${config.networking.domain}.";
          type = "AAAA";
          value = "2a00:23c6:aa22:e401:8dff:9b9a:cb3c:3fcb";
        }
        {
          name = "jellyseerr.${config.networking.domain}.";
          type = "AAAA";
          value = "2a00:23c6:aa22:e401:8dff:9b9a:cb3c:3fcb";
        }
        {
          name = "calibre.${config.networking.domain}.";
          type = "AAAA";
          value = "2a00:23c6:aa22:e401:8dff:9b9a:cb3c:3fcb";
        }
      ];
    };
  };
  services.bind.zones.${config.networking.domain}.extraConfig =
    ''
      dnssec-policy default;
      inline-signing yes;
      journal "${config.services.bind.directory}/${config.networking.domain}.signed.jnl";
    ''
    +
      # dig ns org +short | xargs dig +short
      # replace with `checkds true;` in bind 9.20
      ''
        parental-agents {
          199.19.56.1;
          199.249.112.1;
          199.19.54.1;
          199.249.120.1;
          199.19.53.1;
          199.19.57.1;
        };
      '';

  services.nginx.commonHttpConfig = ''
    add_header Strict-Transport-Security max-age=31536000 always;
    add_header X-Frame-Options SAMEORIGIN always;
    add_header X-Content-Type-Options nosniff always;
    add_header Content-Security-Policy "default-src 'self' 'unsafe-inline' 'unsafe-eval' blob:; base-uri 'self'; frame-src 'self'; frame-ancestors 'self'; form-action 'self';" always;
    add_header Referrer-Policy 'same-origin';
  '';
  services.nginx.virtualHosts."teapot.${config.networking.domain}" = {
    extraConfig = ''
      return 418;
    '';
  };
  age.secrets.website-phd = {
    file = ../../secrets/website-phd.age;
    mode = "770";
    owner = "${config.systemd.services.nginx.serviceConfig.User}";
    group = "${config.systemd.services.nginx.serviceConfig.Group}";
  };
  services.nginx.virtualHosts."${config.custom.website.ryan.domain}" = {
    locations."/phd/" = {
      basicAuthFile = config.age.secrets.website-phd.path;
    };
  };

  security.acme-eon.nginxCerts = [
    "capybara.fn06.org"
    "shrew.freumh.org"
  ];
  services.nginx.virtualHosts."capybara.fn06.org" = {
    forceSSL = true;
    locations."/" = {
      proxyPass = ''
        http://100.64.0.10:8123
      '';
      proxyWebsockets = true;
    };
  };
  services.nginx.virtualHosts."shrew.freumh.org" = {
    forceSSL = true;
    locations."/" = {
      # need to specify ip or there's a bootstrap problem with headscale
      proxyPass = ''
        http://100.64.0.6:8123
      '';
      proxyWebsockets = true;
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

  services.headscale.settings.dns = {
    extra_records = vpnRecords;
    base_domain = "vpn.freumh.org";
    nameservers.global = config.networking.nameservers;
  };

  age.secrets.restic-owl.file = ../../secrets/restic-owl.age;
  services.restic.backups.${config.networking.hostName} = {
    repository = "rest:http://100.64.0.9:8000/${config.networking.hostName}/";
    passwordFile = config.age.secrets.restic-owl.path;
    initialize = true;
    paths = [
      "/var/"
      "/run/"
      "/etc/"
    ];
    timerConfig = {
      OnCalendar = "03:00";
      randomizedDelaySec = "1hr";
    };
  };

  nix = {
    gc = {
      automatic = true;
      dates = lib.mkForce "03:00";
      randomizedDelaySec = "1hr";
      options = lib.mkForce "--delete-older-than 2d";
    };
  };

  age.secrets.email-ryan.file = ../../secrets/email-ryan.age;
  age.secrets.email-system.file = ../../secrets/email-system.age;
  eilean.mailserver.systemAccountPasswordFile = config.age.secrets.email-system.path;
  mailserver.loginAccounts = {
    "${config.eilean.username}@${config.networking.domain}" = {
      passwordFile = config.age.secrets.email-ryan.path;
      aliases = [
        "dns@${config.networking.domain}"
        "postmaster@${config.networking.domain}"
      ];
      sieveScript = ''
        require ["fileinto", "mailbox"];

        if header :contains ["to", "cc"] ["ai-control@ietf.org"] {
          fileinto :create "lists.aietf";
          stop;
        }
      '';
    };
    "misc@${config.networking.domain}" = {
      passwordFile = config.age.secrets.email-ryan.path;
      catchAll = [ "${config.networking.domain}" ];
    };
    "system@${config.networking.domain}" = {
      aliases = [ "nas@${config.networking.domain}" ];
    };
  };

  services.minecraft-server = {
    enable = true;
    package = pkgs.overlay-unstable.minecraft-server;
    eula = true;
    openFirewall = true;
  };

  networking.firewall.allowedTCPPorts = [ 7001 ];

  services.openssh.openFirewall = true;
}
