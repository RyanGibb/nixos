{ pkgs, config, lib, ... }@inputs:

let cfg = config.custom.autoUpgrade;
in {
  options.custom.autoUpgrade.enable = lib.mkEnableOption "autoUpgrade";

  config = lib.mkIf cfg.enable {
    system.autoUpgrade = {
      enable = true;
      allowReboot = true;
      flake = inputs.self.outPath;
      flags = [ "--update-input" "nixpkgs" "-L" ];
      dates = "03:00";
      randomizedDelaySec = "1hr";
      rebootWindow = {
        lower = "03:00";
        upper = "05:00";
      };
    };
    systemd.services.nixos-upgrade = with pkgs; {
      path = [ gnupg ];
      preStart = ''
        DIR=/etc/nixos
        ${sudo}/bin/sudo -u `stat -c "%U" $DIR` ${git}/bin/git -C $DIR pull || exit 0
        ${sudo}/bin/sudo -u `stat -c "%U" $DIR` ${git}/bin/git -C $DIR verify-commit HEAD
      '';
    };
  };
}
