{ config, pkgs, ... }:

{
  services.nginx = {
    virtualHosts = {
      "jellyfin.vpn.freumh.org" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = ''
            http://localhost:8096
          '';
          proxyWebsockets = true;
        };
      };
      "transmission.vpn.freumh.org" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = ''
            http://localhost:${config.services.transmission.settings.rpc-port}
          '';
        };
      };
    };
  };

  services.avahi = {
    enable = true;
    nssmdns = true;
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
      media_dir = [ "/tank/media/" ];
      notify_interval = 60;
      inofity = true;
    };
  };

  services.jellyfin.enable = true;

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
      hosts allow = 192.168.0. 127.0.0.1 localhost 100.64.0.0/10
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
        "force user" = "${config.custom.username}";
        "force group" = "users";
      };
    };
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud28;
    hostName = "nextcloud";
    config.adminpassFile = "${config.custom.secretsDir}/nextcloud";
  };

  services.transmission = {
    enable = true;
    settings = {
      download-dir = "/tank/media";
      incomplete-dir-enabled = false;
      rpc-bind-address = "100.64.0.9";
      rpc-whitelist = "127.0.0.1,100.64.*.*";
      rpc-host-whitelist-enabled = false;
      #bind-address-ipv4 = "100.64.0.9";
      #bind-address-ipv6 = "fe80::e66a:5de:9e2:611c";
    };
  };
}
