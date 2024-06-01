{ config, pkgs, lib, ... }:

{
  security.acme = {
    defaults.email = "${config.custom.username}@${config.networking.domain}";
    acceptTerms = true;
  };

  custom = {
    nix-cache = {
      enable = true;
      domain = "nix-cache";
    };
  };

  services.nginx = {
    virtualHosts = {
      "nix-cache" = { listenAddresses = [ "100.64.0.9" ]; };
      "jellyfin" = {
        listenAddresses = [ "100.64.0.9" ];
        locations."/" = {
          proxyPass = ''
            http://localhost:8096
          '';
          proxyWebsockets = true;
        };
      };
      "transmission" = {
        listenAddresses = [ "100.64.0.9" ];
        locations."/" = {
          proxyPass = ''
            http://localhost:9091
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

  services.samba = {
    enable = true;
    openFirewall = true;
    securityType = "user";
    extraConfig = ''
      workgroup = WORKGROUP
      server string = ${config.networking.hostName}
      netbios name = ${config.networking.hostName}
      security = user
      #use sendfile = yes
      #max protocol = smb2
      # note: localhost is the ipv6 localhost ::1
      hosts allow = 192.168.1. 192.168.0. 127.0.0.1 localhost 100.64.0.0/10
      hosts deny = 0.0.0.0/0
      guest account = nobody
      map to guest = bad user
    '';
    shares = {
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
    hostName = "nextcloud";
    config.adminpassFile = config.age.secrets.nextcloud.path;
  };

  services.transmission = {
    enable = true;
    settings = {
      download-dir = "/tank/media";
      incomplete-dir-enabled = false;
      rpc-whitelist = "127.0.0.1,100.64.*.*";
      rpc-host-whitelist-enabled = false;
      ratio-limit-enabled = true;
    };
  };

  age.secrets.restic-owl.file = ../../secrets/restic-owl.age;
  age.secrets.restic-gecko.file = ../../secrets/restic-gecko.age;
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
}
