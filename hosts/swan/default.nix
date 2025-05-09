{
  pkgs,
  config,
  lib,
  hyperbib-eeg,
  ...
}:

let
  domain = "eeg.cl.cam.ac.uk";
in
{
  imports = [
    ./hardware-configuration.nix
    ./minimal.nix
    hyperbib-eeg.nixosModules.default
  ];

  security.acme = {
    defaults.email = "${config.custom.username}@${config.networking.domain}";
    acceptTerms = true;
  };

  environment.systemPackages = with pkgs; [ xe-guest-utilities ];

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICMmmaDFqSmbQLnPuTtg32wBdJs1xsituz3jrJBqlM1u avsm"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEl1IdWeuW+VmNdfAojJhjn3vVrNnZk4ukhxspeh4ikL avsm"
  ];

  services.hyperbib = {
    enable = true;
    domain = domain;
    # servicePath = "/bib/";
    # proxyPath = "/";
  };

  services.nginx.enable = lib.mkForce false;
  services.httpd = {
    enable = true;
    extraModules =
      let
        mod_ucam_webauth = pkgs.callPackage ./mod_ucam_webauth.nix { };
      in
      [
        {
          name = "ucam_webauth";
          path = "${mod_ucam_webauth}/modules/mod_ucam_webauth.so";
        }
      ];

    virtualHosts."${domain}" = {
      forceSSL = true;
      enableACME = true;
      documentRoot = "/var/www/eeg/";
      locations."/bib/" = {
        proxyPass = "http://127.0.0.1:${builtins.toString config.services.hyperbib.port}/bib/";
      };
      extraConfig =
        let
          keyfile = pkgs.writeTextFile {
            name = "raven-rsa-key";
            destination = "/pubkey2";
            text = ''
              -----BEGIN RSA PUBLIC KEY-----
              MIGJAoGBAL/2pwBbVcJKTRF8B+K6W9Oi4xkoPiOb32te0whw7Zuf7cTFCk5tvBa6
              CI7wM0R99LtvNLFmoantTps92LjF9fvrCBYZDqpaLnk5clXShKKqt3do4SykqYkq
              66kpc42jZ58C3omR0dUfQ7o7yTktVqnrDjLVb9P+vLhAfuSFHFa1AgMBAAE=
              -----END RSA PUBLIC KEY-----
            '';
          };
          matrixServerConfig = pkgs.writeText "matrix-server-config.json" (
            builtins.toJSON { "m.server" = "${domain}:443"; }
          );
          matrixClientConfig = pkgs.writeText "matrix-server-config.json" (
            builtins.toJSON {
              "m.homeserver" = {
                "base_url" = "https://${domain}";
              };
              "m.identity_server" = {
                "base_url" = "https://vector.im";
              };
            }
          );
        in
        ''
          AAKeyDir ${keyfile}
          AACookieKey file:/dev/urandom
          <Location "/bib/">
            AuthType Ucam-WebAuth
            Require valid-user
          </Location>

          SSLEngine on
          ServerName ${domain}

          ### Matrix config

          RequestHeader set "X-Forwarded-Proto" expr=%{REQUEST_SCHEME}
          AllowEncodedSlashes NoDecode
          ProxyPreserveHost on
          ProxyPass /_matrix http://127.0.0.1:8008/_matrix nocanon
          ProxyPassReverse /_matrix http://127.0.0.1:8008/_matrix
          ProxyPass /_synapse/client http://127.0.0.1:8008/_synapse/client nocanon
          ProxyPassReverse /_synapse/client http://127.0.0.1:8008/_synapse/client

          Alias /.well-known/matrix/server "${matrixServerConfig}"
          Alias /.well-known/matrix/client "${matrixClientConfig}"

          ### Calendar config

          RewriteEngine On
          RewriteRule ^/cal$ /cal/ [R,L]

          <Location "/cal/">
              ProxyPass        http://localhost:5232/ retry=0
              ProxyPassReverse http://localhost:5232/
              RequestHeader    set X-Script-Name /cal
              RequestHeader    set X-Forwarded-Port "%{SERVER_PORT}s"
              RequestHeader    set X-Forwarded-Proto expr=%{REQUEST_SCHEME}
          </Location>
        '';
    };
    virtualHosts."watch.${domain}" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        extraConfig = ''
          ProxyPass http://127.0.0.1:${builtins.toString config.services.peertube.listenHttp}/ upgrade=websocket
          ProxyPassReverse http://127.0.0.1:${builtins.toString config.services.peertube.listenHttp}/
        '';
      };
      extraConfig = ''
        ProxyPreserveHost On
      '';
    };
  };

  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    authentication = ''
      hostnossl peertube_local peertube_test 127.0.0.1/32 md5
    '';
    package = pkgs.postgresql_13;
    initialScript = pkgs.writeText "postgresql_init.sql" ''
      CREATE ROLE peertube_test LOGIN PASSWORD 'test123';
      CREATE DATABASE peertube_local TEMPLATE template0 ENCODING UTF8;
      GRANT ALL PRIVILEGES ON DATABASE peertube_local TO peertube_test;
      \connect peertube_local
      CREATE EXTENSION IF NOT EXISTS pg_trgm;
      CREATE EXTENSION IF NOT EXISTS unaccent;
    '';
    #initialScript = pkgs.writeText "synapse-init.sql" ''
    #  CREATE ROLE "matrix-synapse" WITH LOGIN PASSWORD 'synapse';
    #  CREATE DATABASE "matrix-synapse" WITH OWNER "matrix-synapse"
    #    TEMPLATE template0
    #    LC_COLLATE = "C"
    #    LC_CTYPE = "C";
    #'';
  };

  services.matrix-synapse = {
    enable = true;
    settings = lib.mkMerge [
      {
        server_name = domain;
        enable_registration = false;
        registration_shared_secret_path = "/var/lib/matrix-synapse/reigstration-shared-secret";
        auto_join_rooms = [ "#EEG:eeg.cl.cam.ac.uk" ];
        password_config.enabled = false;
        listeners = [
          {
            port = 8008;
            bind_addresses = [
              "::1"
              "127.0.0.1"
            ];
            type = "http";
            tls = false;
            x_forwarded = true;
            resources = [
              {
                names = [
                  "client"
                  "federation"
                ];
                compress = false;
              }
            ];
          }
        ];
        max_upload_size = "100M";
        saml2_config = {
          sp_config = {
            metadata.remote = [ { url = "https://shib.raven.cam.ac.uk/shibboleth"; } ];
            description = [
              "Energy and Environment Group Computer Lab Matrix Server"
              "en"
            ];
            name = [
              "EEG CL Matrix Server"
              "en"
            ];
            # generate keys with
            #   sudo nix shell nixpkgs#openssl nixpkgs#shibboleth-sp -c sh -c '`nix eval --raw nixpkgs#shibboleth-sp`/etc/shibboleth/keygen.sh -h matrix.eeg.cl.cam.ac.uk -o /secrets/matrix-shibboleth/'
            #   chown -R matrix-synapse /secrets/matrix-shibboleth/
            key_file = "/secrets/matrix-shibboleth/sp-key.pem";
            cert_file = "/secrets/matrix-shibboleth/sp-cert.pem";
            encryption_keypairs = [
              { key_file = "/secrets/matrix-shibboleth/sp-key.pem"; }
              { cert_file = "/secrets/matrix-shibboleth/sp-cert.pem"; }
            ];
            attribute_map_dir = pkgs.writeTextDir "map.py" ''
              MAP = {
                  "identifier": "urn:oasis:names:tc:SAML:2.0:attrname-format:uri",
                  "fro": {
                      'urn:oid:0.9.2342.19200300.100.1.1': 'uid',
                      'urn:oid:0.9.2342.19200300.100.1.3': 'email',
                      'urn:oid:2.16.840.1.113730.3.1.241': 'displayName',
                  },
                  "to": {
                      'uid': 'urn:oid:0.9.2342.19200300.100.1.1',
                      'email': 'urn:oid:0.9.2342.19200300.100.1.3',
                      'displayName': 'urn:oid:2.16.840.1.113730.3.1.241',
                  },
              }
            '';
          };
        };
        app_service_config_files = [ "/var/lib/heisenbridge/registration.yml" ];
      }
    ];
  };

  networking.firewall.allowedTCPPorts = [
    80 # HTTP
    443 # HTTPS
    6667
  ];

  nix.settings.require-sigs = false;

  environment.etc = {
    "peertube/password-posgressql-db".text = "test123";
    "peertube/password-redis-db".text = "test123";
  };

  services = {
    peertube = {
      enable = true;
      localDomain = "watch.eeg.cl.cam.ac.uk";
      listenWeb = 443;
      enableWebHttps = true;
      database = {
        host = "127.0.0.1";
        name = "peertube_local";
        user = "peertube_test";
        passwordFile = "/etc/peertube/password-posgressql-db";
      };
      redis = {
        host = "127.0.0.1";
        port = 31638;
        passwordFile = "/etc/peertube/password-redis-db";
      };
      settings = {
        listen.hostname = "0.0.0.0";
        instance.name = "PeerTube Test Server";
        storage.videos = "/tank/peertube/videos";
      };
      secrets.secretsFile = "/secrets/peertube";
      serviceEnvironmentFile = "/secrets/peertube.env";
      dataDirs = [ "/tank/peertube/videos" ];
    };

    redis.servers.peertube = {
      enable = true;
      bind = "0.0.0.0";
      requirePass = "test123";
      port = 31638;
    };
  };

  services.heisenbridge = {
    enable = true;
    address = "0.0.0.0";
    homeserver = "https://${domain}";
  };
  systemd.services.inspircd.serviceConfig.Group = "wwwrun";
  services.inspircd = {
    #enable = true;
    config = ''
      <module name="ssl_gnutls">

      <server
          name="eeg.cl.cam.ac.uk"
          description="EEG Lab IRC Server at Cambridge"
          network="EEGLabNetwork"
      >

      <admin
          name="Ryan Gibb"
          nick="rtg24"
          email="rtg24@eeg.cl.cam.ac.uk"
      >

      <bind
          address="128.232.98.96"
          port="6667"
          type="clients"
      >

      <oper
          name="RyanGibb"
          password="securepassword"
          host="*@*"
          type="NetAdmin"
      >

      <type
          name="NetAdmin"
          classes="ServerLink ClientLink"
      >

      <class
          name="ServerLink"
          commands="300"
          usermodes="300"
          maxtime="0"
      >

      <class
          name="ClientLink"
          commands="20"
          usermodes="20"
          maxtime="90"
      >

      <channels
          users="20"
          op="@"
          halfop="%"
          voice="+"
      >

      <log method="stdout"
         type="*"
         level="default"
         flush="1">
    '';
  };

  networking.domain = domain;
  services.radicale = {
    enable = true;
    settings = {
      server = { hosts = [ "0.0.0.0:5232" ]; };
      auth = {
        type = "htpasswd";
        htpasswd_filename = "/var/lib/radicale/users/passwd";
        htpasswd_encryption = "bcrypt";
      };
      storage = { filesystem_folder = "/var/lib/radicale/collections"; };
    };
  };
}
