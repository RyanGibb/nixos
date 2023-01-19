{ config, lib, ... }:

{
  imports = [
    ./personal/default.nix
    ./personal/wireguard-hosts.nix
    ./personal/printing.nix
    ./personal/laptop.nix
    ./personal/nix-index.nix
    ./personal/ssh.nix
    ./personal/ocaml.nix
    ./personal/scripts.nix
    ./personal/gui/extra.nix
    ./personal/gui/kde.nix
    ./personal/gui/i3.nix
    ./personal/gui/default.nix
    ./personal/gui/sway.nix
    ./personal/tailscale.nix
    ./personal/shell.nix
    ./hosting/freumh.nix
    ./hosting/nix-cache.nix
    ./hosting/eeww.nix
    ./hosting/rmfakecloud.nix
  ];

  options.custom = {
    username = lib.mkOption {
      type = lib.types.str;
      default = "ryan";
    };
    secretsDir = lib.mkOption {
      type = lib.types.path;
      default = "/etc/nixos/secrets";
    };
  };

  config = {
    hosting = {
      username = config.custom.username;
      serverIpv4 = "135.181.100.27";
      serverIpv6 = "2a01:4f9:c011:87ad:0:0:0:0";
    };
    networking.domain = "freumh.org";

    time.timeZone = "Europe/London";

    i18n.defaultLocale = "en_GB.UTF-8";

    nix = {
      settings = {
        experimental-features = [ "nix-command" "flakes" ];
        auto-optimise-store = true;
        substituters = [
          "https://cache.nixos.org/"
          "https://binarycache.freumh.org"
        ];
        trusted-public-keys = [
          "binarycache.freumh.org:Go6ACovVBhR4P6Ug3DsE0p0DIRQtkIBHui1DGM7qK5c="
        ];
      };
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 90d";
      };
    };
  };
}
