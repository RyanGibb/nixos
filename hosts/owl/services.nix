{
  pkgs,
  config,
  lib,
  eon,
  ...
}:

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
    {
      name = "audiobookshelf.vpn.${config.networking.domain}.";
      type = "A";
      value = "100.64.0.9";
    }
  ];
in
{
  # eilean
  networking.domain = lib.mkDefault "freumh.org";
  eilean = {
    username = config.custom.username;
    serverIpv4 = "135.181.100.27";
    serverIpv6 = "2a01:4f9:c011:87ad:0:0:0:0";
    publicInterface = "enp1s0";
    fail2ban.enable = true;
  };

  # eon
  age.secrets.eon-capnp = {
    file = ../../secrets/eon-capnp.age;
    mode = "660";
    owner = "eon";
    group = "eon";
  };
  age.secrets.eon-sirref-primary = {
    file = ../../secrets/eon-sirref-primary.cap.age;
    mode = "660";
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

  # certificates
  eilean.acme-eon = true;
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
  security.acme-eon.nginxCerts = [
    "capybara.fn06.org"
    "shrew.freumh.org"
    "knot.freumh.org"
    "enki.freumh.org"
  ];

  # VPN
  eilean.headscale.enable = true;
  services.headscale.settings.dns = {
    extra_records = vpnRecords;
    base_domain = "vpn.freumh.org";
    nameservers.global = config.networking.nameservers;
  };
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # websites
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
    };
  };
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

  # mailserver
  eilean.mailserver.enable = true;
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

  # CalDAV calendar server
  eilean.radicale = {
    enable = true;
    users = null;
  };

  # matrix
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
  systemd.services.matrix-as-meta = {
    path = [ pkgs.ffmpeg ];
  };

  # mastodon
  eilean.mastodon.enable = true;
  services.mastodon = {
    webProcesses = lib.mkForce 1;
    webThreads = lib.mkForce 1;
    sidekiqThreads = lib.mkForce 1;
    streamingProcesses = lib.mkForce 1;
  };

  # restic
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

  # reverse proxy
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
      proxyPass = ''
        http://100.64.0.6:8123
      '';
      proxyWebsockets = true;
    };
  };

  # tangled
  age.secrets.tangled = {
    file = ../../secrets/tangled.age;
    mode = "660";
    owner = "git";
    group = "git";
  };
  services.tangled-knotserver = {
    enable = true;
    repo.mainBranch = "master";
    server.hostname = "knot.freumh.org";
    server = {
      secretFile = config.age.secrets.tangled.path;
      listenAddr = "127.0.0.1:5555";
      internalListenAddr = "127.0.0.1:5444";
    };
  };
  services.nginx.virtualHosts."knot.freumh.org" = {
    forceSSL = true;
    locations."/" = {
      proxyPass = ''
        http://${config.services.tangled-knotserver.server.listenAddr}
      '';
      proxyWebsockets = true;
    };
  };

  # minecraft server
  services.minecraft-server = {
    enable = true;
    package = pkgs.overlay-unstable.minecraft-server;
    eula = true;
    openFirewall = true;
  };

  services.nginx.virtualHosts."meands.org" = {
    forceSSL = true;
    enableACME = true;
    root = "/var/www/meands.org/_site";
    extraConfig = ''
      add_header Content-Security-Policy "
        style-src 'self' https://cdn.jsdelivr.net;
        font-src 'self' https://fonts.gstatic.com;
        script-src 'self' https://cdn.jsdelivr.net;
      ";
    '';
  };

  # DNS records
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
          type = "ns";
          value = "ns1.sirref.org.";
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

        {
          name = "knot";
          type = "CNAME";
          value = "vps";
        }

        {
          name = "enki";
          type = "CNAME";
          value = "hippo";
        }
        {
          name = "hippo";
          type = "A";
          value = "128.232.124.251";
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

        {
          name = "jellyfin";
          type = "CNAME";
          value = "elephant";
        }
        {
          name = "jellyseerr";
          type = "CNAME";
          value = "elephant";
        }
        {
          name = "calibre";
          type = "CNAME";
          value = "elephant";
        }
        {
          name = "photos";
          type = "CNAME";
          value = "elephant";
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
      ];
    };
  };
}
