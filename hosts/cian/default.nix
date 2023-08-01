{ pkgs, config, lib, eilean, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./minimal.nix
  ];

  eilean = {
    publicInterface = "enp1s0";

    mailserver.enable = true;
    matrix.enable = true;
    turn.enable = true;
    mastodon.enable = true;
    gitea.enable = true;
    headscale.enable = true;
    # dns.enable = true;
  };

  hosting = {
    freumh.enable = true;
    nix-cache.enable = true;
    rmfakecloud.enable = true;
  };

  dns = {
    zones.${config.networking.domain} = {
      soa.serial = lib.mkDefault 2018011627;
      records = [
        { name = "@"; type = "TXT"; data = "google-site-verification=rEvwSqf7RYKRQltY412qMtTuoxPp64O3L7jMotj9Jnc"; }
        { name = "teapot"; type = "CNAME"; data = "vps"; }

        { name = "@";   type = "NS"; data = "ns1"; }
        { name = "@";   type = "NS"; data = "ns2"; }

        { name = "ns1"; type = "A";    data = config.eilean.serverIpv4; }
        { name = "ns1"; type = "AAAA"; data = config.eilean.serverIpv6; }
        { name = "ns2"; type = "A";    data = config.eilean.serverIpv4; }
        { name = "ns2"; type = "AAAA"; data = config.eilean.serverIpv6; }

        { name = "www"; type = "CNAME"; data = "@"; }

        { name = "@";   type = "A";    data = config.eilean.serverIpv4; }
        { name = "@";   type = "AAAA"; data = config.eilean.serverIpv6; }
        { name = "vps"; type = "A";    data = config.eilean.serverIpv4; }
        { name = "vps"; type = "AAAA"; data = config.eilean.serverIpv6; }

        { name = "@"; type = "LOC"; data = "52 12 40.4 N 0 5 31.9 E 22m 10m 10m 10m"; }

        { name = "ns.cl"; type = "A"; data = "128.232.113.136"; }
        { name = "cl"; type = "NS"; data = "ns.cl"; }
      ];
    };
  };

  services.nginx.virtualHosts."teapot.${config.networking.domain}" = {
    extraConfig = ''
      return 418;
    '';
  };

  services = {
    ryan-website = {
      enable = true;
      cname = "vps";
    };
    twitcher = {
      enable = true;
      cname = "vps";
      dotenvFile = "${config.custom.secretsDir}/twitcher.env";
    };
    colour-guesser = {
      enable = true;
      cname = "vps";
    };
    eeww = {
      #enable = true;
      domain = config.services.ryan-website.domain;
    };
    aeon = {
      enable = true;
      # TODO make this zonefile derivation a config parameter `services.dns.zonefile`
      # TODO add module in eilean for aeon
      zoneFile = "${import "${eilean}/modules/dns/zonefile.nix" { inherit pkgs config lib; zonename = config.networking.domain; zone = config.dns.zones.${config.networking.domain}; }}/${config.networking.domain}";
      logLevel = 2;
    };
  };

  networking.firewall =
    let
      turn-range = with config.services.coturn; {
        from = min-port;
        to = max-port;
      };
    in {
      # keep tight control over open ports
      allowedTCPPorts = lib.mkForce [
        22   # SSH
        config.eilean.gitea.sshPort
        25   # SMTP
        465  # SMTP TLS
        53   # DNS (over TCP)
        80   # HTTP
        443  # HTTPS
        993  # IMAP
        3478 # STUN
      ];
      allowedTCPPortRanges = [ turn-range ];
      allowedUDPPorts = lib.mkForce [
        53    # DNS
        51820 # wireguard
        3478  # STUN
      ];
      allowedUDPPortRanges = [ turn-range ];
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
        settings.bridge.personal_filtering_spaces = true;
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

  # boot.kernel.sysctl = {
  #   "net.ipv4.ip_forward" = 1;
  #   "net.ipv6.conf.all.forwarding" = 1;
  # };
}