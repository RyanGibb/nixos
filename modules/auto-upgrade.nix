{
  config,
  lib,
  pkgs,
  ...
}@inputs:

let
  cfg = config.custom.autoUpgrade;
in
{
  options.custom.autoUpgrade.enable = lib.mkEnableOption "autoUpgrade";

  config = lib.mkIf cfg.enable {
    system.autoUpgrade = {
      enable = true;
      # allowReboot = true;
      flake = inputs.self.outPath;
      # flags = [
      #   "--update-input"
      #   "nixpkgs"
      #   "-L"
      # ];
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
        # fail to start on metered connection
        DEVICE=$(${pkgs.iproute2}/bin/ip route list 0/0 | sed -r 's/.*dev (\S*).*/\1/g')
        METERED=$(${pkgs.networkmanager}/bin/nmcli -f GENERAL.METERED dev show "$DEVICE" | ${pkgs.gawk}/bin/awk '/GENERAL.METERED/ {print $2}')
        if [ "$METERED_STATUS" = "yes" ]; then
          echo "Connection is metered. Aborting start."
          exit 1
        fi

        DIR=/etc/nixos
        ${sudo}/bin/sudo -u `stat -c "%U" $DIR` ${git}/bin/git -C $DIR pull || exit 0
        ${sudo}/bin/sudo -u `stat -c "%U" $DIR` ${git}/bin/git -C $DIR verify-commit HEAD
      '';
    };
  };
}
