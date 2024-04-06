{ pkgs, config, lib, ... }@inputs:

let cfg = config.custom;
in {
  imports = [
    ./auto-upgrade.nix
    ./workstation.nix
    ./printing.nix
    ./freumh.nix
    ./scripts.nix
    ./ocaml.nix
    ./nix-cache.nix
    ./external-hdd-backup.nix
    ./laptop.nix
    ./nix-index.nix
    ./ssh.nix
    ./gui/extra.nix
    ./gui/kde.nix
    ./gui/i3.nix
    ./gui/default.nix
    ./gui/sway.nix
    ./rmfakecloud.nix
    ./tailscale.nix
    ./dict.nix
  ];

  options.custom = {
    enable = lib.mkEnableOption "custom";
    username = lib.mkOption {
      type = lib.types.str;
      default = "ryan";
    };
  };

  config = let nixPath = "/etc/nix-path";
  in lib.mkIf cfg.enable {
    console = {
      font = "Lat2-Terminus16";
      keyMap = "uk";
    };
    i18n.defaultLocale = "en_GB.UTF-8";

    networking.domain = "freumh.org";
    networking.extraHosts = ''
      eeg.cl.cam.ac.uk swan
    '';

    eilean.username = cfg.username;

    nix = {
      settings = lib.mkMerge [
        {
          experimental-features = [ "nix-command" "flakes" ];
          auto-optimise-store = true;
          trusted-users = [ cfg.username ];
        }
        (lib.mkIf (config.networking.hostName != "owl") {
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
    systemd.tmpfiles.rules = [ "L+ ${nixPath} - - - - ${pkgs.path}" ];

    users = let
      hashedPassword =
        "$6$IPvnJnu6/fp1Jxfy$U6EnzYDOC2NqE4iqRrkJJbSTHHNWk0KwK1xyk9jEvlu584UWQLyzDVF5I1Sh47wQhSVrvUI4mrqw6XTTjfPj6.";
    in {
      mutableUsers = false;
      groups.plugdev = { };
      users.${cfg.username} = {
        isNormalUser = true;
        extraGroups = [
          "wheel" # enable sudo
          "networkmanager"
          "video"
          "plugdev"
        ];
        shell = pkgs.zsh;
        # we let home manager manager zsh
        ignoreShellProgramCheck = true;
        hashedPassword = hashedPassword;
      };
      users.root.hashedPassword = hashedPassword;
    };

    environment.systemPackages = with pkgs; [ nix agenix ];

    networking = rec {
      # nameservers = [ "freumh.org" ];
      nameservers = [ "1.1.1.1" ];
      networkmanager.dns = "none";
    };

    home-manager = {
      useGlobalPkgs = true;
      users.${config.custom.username} = import ../home/default.nix;
    };
    # zsh completion
    environment.pathsToLink = [ "/share/zsh" ];
  };
}
