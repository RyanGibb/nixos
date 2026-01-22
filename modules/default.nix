{
  pkgs,
  config,
  lib,
  agenix,
  ...
}:

let
  cfg = config.custom;
in
{
  imports = [
    ./auto-upgrade.nix
    ./dict.nix
    ./external-hdd-backup.nix
    ./freumh.nix
    ./gui/default.nix
    ./gui/i3.nix
    ./gui/kde.nix
    ./gui/sway.nix
    ./home-manager.nix
    ./laptop.nix
    ./nix-cache.nix
    ./nix-index.nix
    ./printing.nix
    ./rmfakecloud.nix
    ./scripts.nix
    ./ssh.nix
    ./tailscale.nix
    ./use-nix-cache.nix
    ./workstation.nix
    ./zsa.nix
  ];

  options.custom = {
    enable = lib.mkEnableOption "custom";
    username = lib.mkOption {
      type = lib.types.str;
      default = "ryan";
    };
  };

  config =
    let
      nixPath = "/etc/nix-path";
    in
    lib.mkIf cfg.enable {
      console = {
        font = "Lat2-Terminus16";
        keyMap = "uk";
      };
      i18n.defaultLocale = "en_GB.UTF-8";

      networking.domain = lib.mkDefault "freumh.org";

      eilean.username = cfg.username;

      nix = {
        settings = lib.mkMerge [
          {
            experimental-features = [
              "nix-command"
              "flakes"
            ];
            auto-optimise-store = true;
            trusted-users = [ cfg.username ];
          }
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

      users =
        let
          hashedPassword = "$6$IPvnJnu6/fp1Jxfy$U6EnzYDOC2NqE4iqRrkJJbSTHHNWk0KwK1xyk9jEvlu584UWQLyzDVF5I1Sh47wQhSVrvUI4mrqw6XTTjfPj6.";
        in
        {
          mutableUsers = false;
          groups.plugdev = { };
          users.${cfg.username} = {
            isNormalUser = true;
            extraGroups = [
              "wheel" # enable sudo
              "networkmanager"
              "video"
              "plugdev"
              "dialout"
            ];
            shell = pkgs.zsh;
            # we let home manager manager zsh
            ignoreShellProgramCheck = true;
            hashedPassword = hashedPassword;
          };
          users.root.hashedPassword = hashedPassword;
        };

      environment.systemPackages = with pkgs; [
        nix
        git
        agenix.packages.${system}.default
      ];

      networking = rec {
        # nameservers = [ "freumh.org" ];
        nameservers = [ "1.1.1.1" ];
        # uncomment to stop using DHCP nameservers
        #networkmanager.dns = "none";
      };
    };
}
