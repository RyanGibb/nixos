{ pkgs, config, lib, eilean, ... }:

let domain = "eeg.cl.cam.ac.uk"; in
{
  imports = [
    ./hardware-configuration.nix
  ];

  personal = {
    enable = true;
    machineColour = "green";
  };

  services.openssh.openFirewall = true;

  swapDevices = [ { device = "/var/swap"; size = 1024; } ];

  security.acme = {
    defaults.email = "${config.eilean.username}@${config.networking.domain}";
    acceptTerms = true;
  };

  environment.systemPackages = with pkgs; [
    xe-guest-utilities
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
    extraModules = let
      mod_ucam_webauth = pkgs.callPackage ./mod_ucam_webauth.nix { };
    in [ {
      name = "ucam_webauth";
      path = "${mod_ucam_webauth}/modules/mod_ucam_webauth.so";
    } ];

    virtualHosts."${domain}" = {
      forceSSL = true;
      enableACME = true;
      documentRoot = "/var/www/eeg/";
      locations."/bib/" = {
        proxyPass = "http://127.0.0.1:${builtins.toString config.services.hyperbib.port}/bib/";
      };
      extraConfig = let
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
        matrixServerConfig = pkgs.writeText "matrix-server-config.json" (builtins.toJSON {
          "m.server" = "${domain}:443";
        });
        matrixClientConfig = pkgs.writeText "matrix-server-config.json" (builtins.toJSON {
          "m.homeserver" =  { "base_url" = "https://${domain}"; };
          "m.identity_server" =  { "base_url" = "https://vector.im"; };
        });
      in ''
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
      '';
    };
  };

  services.postgresql.enable = true;
  services.postgresql.package = pkgs.postgresql_13;
  services.postgresql.initialScript = pkgs.writeText "synapse-init.sql" ''
    CREATE ROLE "matrix-synapse" WITH LOGIN PASSWORD 'synapse';
    CREATE DATABASE "matrix-synapse" WITH OWNER "matrix-synapse"
      TEMPLATE template0
      LC_COLLATE = "C"
      LC_CTYPE = "C";
  '';

  services.matrix-synapse = {
    enable = true;
    settings = lib.mkMerge [
      {
        server_name = domain;
        enable_registration = false;
        auto_join_rooms = [ "#EEG:eeg.cl.cam.ac.uk" ];
        password_config.enabled = false;
        listeners = [
          {
            port = 8008;
            bind_addresses = [ "::1" "127.0.0.1" ];
            type = "http";
            tls = false;
            x_forwarded = true;
            resources = [
              {
                names = [ "client" "federation" ];
                compress = false;
              }
            ];
          }
        ];
        max_upload_size = "100M";
        saml2_config = {
          sp_config = {
            metadata.remote = [ { url = "https://shib.raven.cam.ac.uk/shibboleth"; } ];
            description = [ "Energy and Environment Group Computer Lab Matrix Server" "en" ];
            name = [ "EEG CL Matrix Server" "en" ];
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
      }
    ];
  };

  networking.firewall.allowedTCPPorts = [
    80   # HTTP
    443  # HTTPS
  ];

  nix.settings.require-sigs = false;
}
