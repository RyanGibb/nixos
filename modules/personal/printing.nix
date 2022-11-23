 {
  networking.firewall = {
    allowedTCPPorts = [ 631 ];
    allowedUDPPorts = [ 631 ];
  };
  services.printing = {
    enable = true;
    browsing = true;
    defaultShared = true;
  };
  services.avahi = {
    enable = true;
    publish.enable = true;
    publish.userServices = true;
    nssmdns = true;
  };
}