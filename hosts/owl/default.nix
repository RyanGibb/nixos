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

  eilean.publicInterface = "enp1s0";
  eilean.mailserver.enable = true;
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

        { name = "_25._tcp.mail"; type = "TLSA"; data = "3 1 1 1b52dcbd6121d6e88406eca208ff476fc7b3da575ddfd65516e5c88db128ddb8"; }
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
  '' +
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
    add_header Content-Security-Policy "default-src 'self' 'unsafe-inline' 'unsafe-eval'; base-uri 'self'; frame-src 'self'; frame-ancestors 'self'; form-action 'self';" always;
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
  services.nginx.virtualHosts."${config.services.ryan-website.domain}" = {
    locations."/phd/" = {
      basicAuthFile = config.age.secrets.website-phd.path;
    };
  };
  services.nginx.virtualHosts."capybara.fn06.org" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = ''
        http://100.64.0.10:8123
      '';
      proxyWebsockets = true;
    };
  };
  services.nginx.virtualHosts."shrew.freumh.org" = {
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

  services = {
    ryan-website = {
      enable = true;
      cname = "vps";
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
    eeww= {
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

  services.headscale.settings.dns_config.extra_records = [
    {
      name = "jellyfin.vpn.${config.networking.domain}";
      type = "A";
      value = "100.64.0.9";
    }
    {
      name = "nextcloud.vpn.${config.networking.domain}";
      type = "A";
      value = "100.64.0.9";
    }
    {
      name = "transmission.vpn.${config.networking.domain}";
      type = "A";
      value = "100.64.0.9";
    }
  ];

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
      options = lib.mkForce "--delete-older-than 3d";
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
    
        if header :contains ["to", "cc"] ["~rjarry/aerc-discuss@lists.sr.ht"] {
          fileinto :create "lists.aerc";
          stop;
        }
      '';
    };
    "misc@${config.networking.domain}" = {
      passwordFile = config.age.secrets.email-ryan.path;
      catchAll = [ "${config.networking.domain}" ];
    };
    "system@${config.networking.domain}" = {
      aliases = [
        "nas@${config.networking.domain}"
      ];
    };
  };
}
