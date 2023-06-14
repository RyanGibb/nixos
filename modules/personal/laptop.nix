{ pkgs, config, lib, self, ... }:

let cfg = config.personal; in
{
  options.personal.laptop = lib.mkEnableOption "laptop";
  
  config = lib.mkIf cfg.laptop {
    users.users.${config.custom.username}.extraGroups = [ "input" ];

    services.xserver.libinput.enable = true;

    services.tlp.enable = true;
    powerManagement.enable = true;

    systemd.sleep.extraConfig = ''
      HibernateDelaySec=1h
    '';

    services.logind.lidSwitch = "suspend-then-hibernate";

    environment.systemPackages = with pkgs; [
      fusuma
      kanshi
      acpi
    ];

    services.udev.extraRules =
      let bat-monitor = pkgs.writeTextFile {
        name = "bat_monitor";
        text = builtins.readFile ./home/wm/scripts/bat_monitor.sh;
        executable = true;
        destination = "/bat_monitor.sh";
      }; in ''
      ACTION=="change", SUBSYSTEM=="power_supply", RUN+="${pkgs.bash}/bin/bash ${bat-monitor}/bat_monitor.sh '%s{capacity}' '%s{status}'"
    '';
  };
}
