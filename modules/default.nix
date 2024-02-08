{ config, lib, pkgs, ... }@inputs:

{
  imports = [
    ./personal/default.nix
    ./personal/nvim/default.nix
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
    ./personal/backup.nix
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

  config = let nixPath = "/etc/nix-path"; in {
    eilean = {
      username = config.custom.username;
      secretsDir = config.custom.secretsDir;
      serverIpv4 = "135.181.100.27";
      serverIpv6 = "2a01:4f9:c011:87ad:0:0:0:0";
    };
    networking.domain = lib.mkDefault "freumh.org";

    services.localtimed.enable = true;
    services.geoclue2.enable = true;

    i18n.defaultLocale = "en_GB.UTF-8";

    nix = {
      buildMachines = [ {
        hostName = "rtg24@daintree.cl.cam.ac.uk";
        system = "x86_64-linux";
        protocol = "ssh-ng";
        maxJobs = 1;
        speedFactor = 2;
        supportedFeatures = [ "benchmark" "big-parallel" "kvm" ];
        mandatoryFeatures = [ ];
      }] ;
      distributedBuilds = true;
      extraOptions = ''
        builders-use-substitutes = true
      '';
      settings = lib.mkMerge [
        {
          experimental-features = [ "nix-command" "flakes" ];
          auto-optimise-store = true;
          trusted-users = [ config.custom.username ];
        }
        (lib.mkIf (config.networking.hostName != "vps") {
          substituters = [
            "https://cache.nixos.org?priority=100"
            "https://binarycache.${config.networking.domain}?priority=10"
          ];
          trusted-public-keys = [
            "binarycache.${config.networking.domain}:Go6ACovVBhR4P6Ug3DsE0p0DIRQtkIBHui1DGM7qK5c="
          ];
        })
      ];
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
      # https://discourse.nixos.org/t/do-flakes-also-set-the-system-channel/19798/16
      nixPath = [ "nixpkgs=${nixPath}" ];
    };
    systemd.tmpfiles.rules = [
      "L+ ${nixPath} - - - - ${pkgs.path}"
    ];

    system.autoUpgrade = {
      enable = true;
      flake = inputs.self.outPath;
      flags = [
        "--update-input"
        "nixpkgs"
        "-L"
      ];
      dates = "03:00";
      randomizedDelaySec = "1hr";
      rebootWindow = { lower = "03:00"; upper = "05:00"; };
    };
  };
}
