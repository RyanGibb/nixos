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
      in ''
        AAKeyDir ${keyfile}
        AACookieKey file:/dev/urandom
        <Location "/bib/">
          AuthType Ucam-WebAuth
          Require valid-user
        </Location>
      '';
    };
  };

  networking.firewall.allowedTCPPorts = [
    80   # HTTP
    443  # HTTPS
  ];

  nix.settings.require-sigs = false;
}
