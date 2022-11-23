{ pkgs, ... }:

{
  users.users.${config.custom.username}.extraGroups = [ "input" ];

  services.xserver.libinput.enable = true;

  services.tlp.enable = true;
  powerManagement.enable = true;
  virtualisation.libvirtd.enable = true;

  systemd.sleep.extraConfig = ''
    HibernateDelaySec=1h
  '';

  services.logind.lidSwitch = "suspend-then-hibernate";

  environment.systemPackages = with pkgs; [
    fusuma
    kanshi
    acpi
  ];
}
