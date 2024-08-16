{ config, pkgs, lib, ... }:

{
  custom.nix-cache.enable = true;

  age.secrets."eon-vpn.freumh.org.cap" = {
    file = ../../secrets/eon-vpn.freumh.org.cap.age;
    mode = "770";
    owner = "acme-eon";
    group = "acme-eon";
  };
  security.acme-eon = {
    acceptTerms = true;
    defaults.email = "${config.custom.username}@${config.networking.domain}";
    defaults.capFile = config.age.secrets."eon-vpn.freumh.org.cap".path;
    nginxCerts = [
      "nix-cache.vpn.freumh.org"
      "jellyfin.vpn.freumh.org"
      "transmission.vpn.freumh.org"
      "nextcloud.vpn.freumh.org"
    ];
  };

  services.nginx = {
    #requires = [ "tailscaled.service" ];
    virtualHosts = {
      "nix-cache.vpn.freumh.org" = { listenAddresses = [ "100.64.0.9" ]; };
      "jellyfin.vpn.freumh.org" = {
        enableSSL = true;
        listenAddresses = [ "100.64.0.9" ];
        locations."/" = {
          proxyPass = ''
            http://localhost:8096
          '';
          proxyWebsockets = true;
        };
      };
      "transmission.vpn.freumh.org" = {
        enableSSL = true;
        listenAddresses = [ "100.64.0.9" ];
        locations."/" = {
          proxyPass = ''
            http://localhost:9091
          '';
        };
      };
      "nextcloud.vpn.freumh.org" = {
        enableSSL = true;
        listenAddresses = [ "100.64.0.9" ];
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
    hostName = "nextcloud.vpn.freumh.org";
    config.adminpassFile = config.age.secrets.nextcloud.path;
  };

  services.transmission = {
    enable = true;
    openRPCPort = true;
    settings = {
      download-dir = "/tank/media";
      incomplete-dir-enabled = false;
      rpc-whitelist = "127.0.0.1,100.64.*.*,192.168.1.*";
      rpc-bind-address = "0.0.0.0";
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
  systemd.services.restic-rest-server = {
    after = [ "tailscaled.service" ];
    requires = [ "tailscaled.service" ];
  };
}
