{ config, pkgs, lib, ... }:
let
  fqdn =
    let
      join = hostName: domain: hostName + lib.optionalString (domain != null) ".${domain}";
    in join config.networking.hostName config.networking.domain;
in {
  services.postgresql.enable = true;
  services.postgresql.package = pkgs.postgresql_13;
  services.postgresql.initialScript = pkgs.writeText "synapse-init.sql" ''
    CREATE ROLE "matrix-synapse" WITH LOGIN PASSWORD 'synapse';
    CREATE DATABASE "matrix-synapse" WITH OWNER "matrix-synapse"
      TEMPLATE template0
      LC_COLLATE = "C"
      LC_CTYPE = "C";
  '';

  services.nginx = {
    enable = true;
    # only recommendedProxySettings and recommendedGzipSettings are strictly required,
    # but the rest make sense as well
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;

    virtualHosts = {
      # This host section can be placed on a different host than the rest,
      # i.e. to delegate from the host being accessible as ${config.networking.domain}
      # to another host actually running the Matrix homeserver.
      "${config.networking.domain}" = {
        enableACME = true;
        forceSSL = true;

        locations."= /.well-known/matrix/server".extraConfig =
          let
            # use 443 instead of the default 8448 port to unite
            # the client-server and server-server port for simplicity
            server = { "m.server" = "${fqdn}:443"; };
          in ''
            add_header Content-Type application/json;
            return 200 '${builtins.toJSON server}';
          '';
        locations."= /.well-known/matrix/client".extraConfig =
          let
            client = {
              "m.homeserver" =  { "base_url" = "https://${fqdn}"; };
              "m.identity_server" =  { "base_url" = "https://vector.im"; };
            };
          # ACAO required to allow element-web on any URL to request this json file
          in ''
            add_header Content-Type application/json;
            add_header Access-Control-Allow-Origin *;
            return 200 '${builtins.toJSON client}';
          '';
      };

      # Reverse proxy for Matrix client-server and server-server communication
      ${fqdn} = {
        enableACME = true;
        forceSSL = true;

        # Or do a redirect instead of the 404, or whatever is appropriate for you.
        # But do not put a Matrix Web client here! See the Element web section below.
        locations."/".extraConfig = ''
          return 404;
        '';

        # forward all Matrix API calls to the synapse Matrix homeserver
        locations."/_matrix" = {
          proxyPass = "http://[::1]:8008"; # without a trailing /
        };
      };
    };
  };

  services.matrix-synapse = {
    enable = true;
    settings = {
      server_name = config.networking.domain;
      listeners = [
        {
          port = 8008;
          bind_addresses = [ "::1" ];
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
    };
  };

}
