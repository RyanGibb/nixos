{
  nixpkgs-unstable,
  config,
  pkgs,
  lib,
  nixpkgs-chromedriver,
  ...
}:

{
  custom.nix-cache.enable = true;

  age.secrets."eon-freumh.org.cap" = {
    file = ../../secrets/eon-freumh.org.cap.age;
    mode = "770";
    owner = "acme-eon";
    group = "acme-eon";
  };
  security.acme-eon = {
    acceptTerms = true;
    defaults.email = "${config.custom.username}@${config.networking.domain}";
    defaults.capFile = config.age.secrets."eon-freumh.org.cap".path;
    nginxCerts = [
      "nix-cache.vpn.freumh.org"
      "jellyfin.vpn.freumh.org"
      "jellyfin.freumh.org"
      "jellyseerr.freumh.org"
      "transmission.vpn.freumh.org"
      "owntracks.vpn.freumh.org"
      "immich.vpn.freumh.org"
      "photos.freumh.org"
      "calibre.freumh.org"
      "audiobookshelf.vpn.freumh.org"
    ];
  };

  services.nginx = {
    #requires = [ "tailscaled.service" ];
    clientMaxBodySize = "1g";
    virtualHosts = {
      "nix-cache.vpn.freumh.org" = {
        listenAddresses = [ "100.64.0.9" ];
      };
      "jellyfin.vpn.freumh.org" = {
        onlySSL = true;
        listenAddresses = [ "100.64.0.9" ];
        locations."/" = {
          proxyPass = ''
            http://localhost:8096
          '';
          proxyWebsockets = true;
        };
      };
      "jellyfin.freumh.org" = {
        onlySSL = true;
        locations."/" = {
          recommendedProxySettings = true;
          proxyPass = ''
            http://localhost:8096
          '';
          proxyWebsockets = true;
        };
      };
      "jellyseerr.freumh.org" = {
        onlySSL = true;
        locations."/" = {
          recommendedProxySettings = true;
          proxyPass = ''
            http://localhost:${builtins.toString config.services.jellyseerr.port}
          '';
          proxyWebsockets = true;
        };
      };
      "transmission.vpn.freumh.org" = {
        onlySSL = true;
        listenAddresses = [ "100.64.0.9" ];
        locations."/" = {
          proxyPass = with config.services.transmission.settings; ''
            http://localhost:${builtins.toString rpc-port}
          '';
        };
      };
      "owntracks.vpn.freumh.org" = {
        onlySSL = true;
        listenAddresses = [ "100.64.0.9" ];
      };
      "immich.vpn.freumh.org" = {
        onlySSL = true;
        listenAddresses = [ "100.64.0.9" ];
        locations."/" = {
          proxyPass = with config.services.immich; ''
            http://${host}:${builtins.toString port}
          '';
          proxyWebsockets = true;
        };
      };
      "photos.freumh.org" = {
        onlySSL = true;
        locations."/" = {
          proxyPass = with config.services.immich; ''
            http://${host}:${builtins.toString port}
          '';
          proxyWebsockets = true;
        };
      };
      "calibre.freumh.org" = {
        addSSL = true;
        locations."/" = {
          recommendedProxySettings = true;
          proxyPass = ''
            http://127.0.0.1:${builtins.toString config.services.calibre-web.listen.port}
          '';
          proxyWebsockets = true;
          extraConfig = ''
            proxy_buffer_size 128k;
            proxy_buffers 4 256k;
            proxy_busy_buffers_size 256k;
          '';
        };
      };
      "audiobookshelf.vpn.freumh.org" = {
        onlySSL = true;
        listenAddresses = [ "100.64.0.9" ];
        locations."/" = {
          proxyPass = ''
            http://localhost:${builtins.toString config.services.audiobookshelf.port}
          '';
          proxyWebsockets = true;
        };
      };
    };
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  services.minidlna = {
    enable = true;
    openFirewall = true;
    settings = {
      media_dir = [ "/tank/" ];
      notify_interval = 60;
      inofity = true;
    };
  };

  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };
  users.users.${config.services.jellyfin.user}.extraGroups = [
    config.services.transmission.user
    config.services.sonarr.user
    config.services.radarr.user
    config.services.bazarr.user
    config.services.lidarr.user
    config.services.readarr.user
  ];

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        workgroup = "WORKGROUP";
        "server string" = "${config.networking.hostName}";
        "netbios name" = "${config.networking.hostName}";
        "security" = "user";
        #"use sendfile" = "yes";
        #"max protocol" = "smb2";
        # note: localhost is the ipv6 localhost ::1
        "hosts allow" = "192.168.1. 192.168.0. 127.0.0.1 localhost 100.64.0.0/10";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };
      tank = {
        path = "/tank/";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
      };
    };
  };
  users.mutableUsers = lib.mkForce true;

  services.transmission = {
    enable = true;
    openRPCPort = true;
    package = pkgs.transmission_3;
    settings = {
      download-dir = "/tank/transmission";
      incomplete-dir-enabled = false;
      rpc-whitelist = "127.0.0.1,100.64.*.*,192.168.1.*";
      rpc-bind-address = "0.0.0.0";
      rpc-host-whitelist-enabled = false;
      ratio-limit-enabled = true;
      download-queue-size = 20;
    };
  };

  services.prowlarr.enable = true;
  services.flaresolverr.enable = true;
  services.sonarr.enable = true;
  services.radarr.enable = true;
  services.bazarr.enable = true;
  services.lidarr.enable = true;
  services.readarr.enable = true;
  services.nzbget.enable = true;
  services.jellyseerr.enable = true;
  users.users.${config.services.sonarr.user}.extraGroups = [
    config.services.transmission.user
    config.services.nzbget.user
  ];
  users.users.${config.services.radarr.user}.extraGroups = [
    config.services.transmission.user
    config.services.nzbget.user
  ];
  users.users.${config.services.bazarr.user}.extraGroups = [
    config.services.sonarr.user
    config.services.radarr.user
  ];
  users.users.${config.services.lidarr.user}.extraGroups = [
    config.services.transmission.user
    config.services.nzbget.user
  ];
  users.users.${config.services.readarr.user}.extraGroups = [
    config.services.transmission.user
    config.services.nzbget.user
  ];

  services.calibre-web = {
    enable = true;
    listen = {
      port = 8084;
      ip = "127.0.0.1";
    };
    options = {
      enableBookConversion = true;
      enableBookUploading = true;
      enableKepubify = true;
    };
  };
  users.users.${config.services.calibre-web.user}.extraGroups = [
    config.services.readarr.user
  ];

  services.restic.server = {
    enable = true;
    listenAddress = "100.64.0.9:8000";
    dataDir = "/tank/backups/restic";
    appendOnly = true;
    extraFlags = [ "--no-auth" ];
  };
  systemd.services.restic-rest-server = {
    after = [ "tailscaled.service" ];
    requires = [ "tailscaled.service" ];
  };

  services.owntracks-recorder = {
    enable = true;
    host = "100.64.0.9";
    domain = "owntracks.vpn.freumh.org";
  };

  services.immich = {
    enable = true;
    openFirewall = true;
    host = "100.64.0.9";
    mediaLocation = "/tank/immich";
  };

  services.audiobookshelf = {
    enable = true;
    port = 8001;
  };
  users.users.${config.services.audiobookshelf.user}.extraGroups = [
    config.services.readarr.user
  ];

  services.fail2ban = {
    enable = true;
    bantime = "24h";
    bantime-increment = {
      enable = true;
      multipliers = "1 2 4 8 16 32 64";
      maxtime = "168h";
      overalljails = true;
    };
    jails."jellyfin".settings = {
      backend = "auto";
      port = "80,443";
      protocol = "tcp";
      filter = "jellyfin";
      maxRetry = 3;
      bantime = "86400";
      findTime = "43200";
      logPath = "/var/lib/jellyfin/log/*.log";
    };
    # requires 'Enable Proxy Support' for jellyseerr
    jails."jellyseerr".settings = {
      backend = "auto";
      port = "80,443";
      protocol = "tcp";
      filter = "jellyseerr";
      maxRetry = 3;
      bantime = "86400";
      findTime = "43200";
      logPath = "/var/lib/jellyseerr/logs/overseerr.log";
    };
    # requires 'Enable Proxy Support' for jellyseerr
    jails."calibre-web".settings = {
      backend = "auto";
      port = "80,443";
      protocol = "tcp";
      filter = "calibre-web";
      maxRetry = 3;
      bantime = "86400";
      findTime = "43200";
      logPath = "/var/lib/calibre-web/log";
    };
  };
  environment.etc = {
    "fail2ban/filter.d/jellyfin.local".text = ''
      [Definition]
      failregex = ^.*Authentication request for .* has been denied \(IP: "<ADDR>"\)\.
    '';
    "fail2ban/filter.d/jellyseerr.local".text = ''
      [Definition]
      failregex = ^.*\[warn\]\[Auth\]: Failed login attempt from user with incorrect Jellyfin credentials {"account":{"ip":"<HOST>","email":
    '';
    "fail2ban/filter.d/calibre-web.local".text = ''
      [Definition]
      failregex = ^(?:\[\])?\s*WARN \{[^\}]*\} Login failed for user "<F-USER>[^"]*</F-USER>" IP-address: <ADDR>
    '';
  };

  systemd.services.ddns = {
    description = "Dynamic DNS";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      ExecStart = pkgs.writeShellScript "update-dns" ''
        while true; do
          IP="$(${pkgs.curl}/bin/curl https://ipinfo.io/ip 2> /dev/null)"
          echo $IP
          ${config.services.eon.package}/bin/capc update /run/agenix/eon-freumh.org.cap \
            -u "remove|elephant.freumh.org|A" \
            -u "add|elephant.freumh.org|A|$IP|60" \
            ;
          sleep 3600
        done
      '';
      Restart = "always";
      RestartSec = 5;
      User = "root";
    };
  };
}
