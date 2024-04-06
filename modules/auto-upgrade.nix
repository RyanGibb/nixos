{ pkgs, ... }@inputs: {
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
  systemd.services.nixos-upgrade.preStart = with pkgs; ''
    DIR=/etc/nixos
    ${sudo}/bin/sudo -u `stat -c "%U" $DIR` ${git}/bin/git -C $DIR pull || exit 0
  '';
}
