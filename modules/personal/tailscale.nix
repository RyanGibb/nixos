{ lib, ... }:

{
  dns.records = lib.mkIf (config ? dns) [
    {
      name = "pixel-4a.vpn";
      type = "A";
      data = "100.122.46.94";
    }
    {
      name = "dell-xps.vpn";
      type = "A";
      data = "100.92.111.117";
    }
    {
      name = "hp-pavilion.";
      type = "A";
      data = "100.91.12.120";
    }
    {
      name = "vps.vpn";
      type = "A";
      data = "100.88.115.118";
    }
    {
      name = "desktop.vpn";
      type = "A";
      data = "100.93.8.35";
    }
    {
      name = "rasp-pi.vpn";
      type = "A";
      data = "100.92.63.87";
    }
  ];
}
