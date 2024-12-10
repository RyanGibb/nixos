{
  nixpkgs-unstable,
  config,
  pkgs,
  lib,
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
      "nextcloud.vpn.freumh.org"
      "owntracks.vpn.freumh.org"
      "immich.vpn.freumh.org"
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
      "nextcloud.vpn.freumh.org" = {
        onlySSL = true;
        listenAddresses = [ "100.64.0.9" ];
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

  age.secrets.nextcloud = {
    file = ../../secrets/nextcloud.age;
    mode = "770";
    owner = "nextcloud";
    group = "nextcloud";
  };
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud29;
    hostName = "nextcloud.vpn.freumh.org";
    config.adminpassFile = config.age.secrets.nextcloud.path;
  };

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
    };
  };

  services.prowlarr.enable = true;
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
  # services.calibre-server.enable = true;

  age.secrets.restic-owl.file = ../../secrets/restic-owl.age;
  age.secrets.restic-gecko.file = ../../secrets/restic-gecko.age;
  age.secrets.restic-shrew.file = ../../secrets/restic-shrew.age;
  services.restic = {
    #backups.owl = {
    #  repository = "${config.services.restic.server.dataDir}/owl";
    #  passwordFile = "${config.custom.secretsDir}/restic-password-owl";
    #  timerConfig = {
    #    OnCalendar = "02:00";
    #  };
    #  pruneOpts = [
    #    "--keep-daily 7"
    #    "--keep-weekly 5"
    #    "--keep-monthly 12"
    #    "--keep-yearly 5"
    #  ];
    #};
    #backups.gecko = {
    #  repository = "${config.services.restic.server.dataDir}/gecko";
    #  passwordFile = "${config.custom.secretsDir}/restic-password-gecko";
    #  timerConfig = {
    #    OnCalendar = "02:00";
    #  };
    #  pruneOpts = [
    #    "--keep-daily 7"
    #    "--keep-weekly 5"
    #    "--keep-monthly 12"
    #    "--keep-yearly 5"
    #  ];
    #};
    server = {
      enable = true;
      listenAddress = "100.64.0.9:8000";
      dataDir = "/tank/backups/restic";
      appendOnly = true;
      extraFlags = [ "--no-auth" ];
    };
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
  };
}
