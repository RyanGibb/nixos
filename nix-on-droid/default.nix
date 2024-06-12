{ pkgs, config, lib, ... }:

{
  user.shell = "${pkgs.zsh}/bin/zsh";

  environment.packages = with pkgs; [
    util-linux # for whereis
  ];
  environment.etcBackupExtension = ".bak";

  # Tailscale nameserver https://github.com/nix-community/nix-on-droid/issues/2
  environment.etc."resolv.conf".text = lib.mkForce ''
    nameserver 100.100.100.100
    nameserver 1.1.1.1
    nameserver 8.8.8.8
  '';

  home-manager = {
    useGlobalPkgs = true;
    config = { pkgs, lib, ... }: {
      imports = [ ../home/default.nix ];

      # Use the same overlays as the system packages
      nixpkgs = { inherit (config.nixpkgs) overlays; };

      nix = {
        package = pkgs.nix;
        settings.experimental-features = [ "nix-command" "flakes" ];
      };

      # https://github.com/nix-community/nix-on-droid/issues/185
      home.shellAliases = {
        sshd = let
          config = pkgs.writeText "sshd_config" ''
            HostKey /data/data/com.termux.nix/files/home/.ssh/id_ed25519
            Port 9022
          '';
        in "$(readlink $(whereis sshd)) -f ${config}";
        ping = "/android/system/bin/linker64 /android/system/bin/ping";
      };

      home.file = {
        ".ssh/authorized_keys".source = ../modules/authorized_keys;
      };

      programs.ssh = {
        enable = true;
        extraConfig = ''
          User ryan
        '';
      };

      home.stateVersion = "22.05";
    };
  };
  system.stateVersion = "22.05";
}
