{ pkgs, config, lib, eilean, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  personal = {
    enable = true;
    machineColour = "green";
  };

  services.openssh.openFirewall = true;

  swapDevices = [ { device = "/var/swap"; size = 1024; } ];

  security.acme = {
    defaults.email = "${config.eilean.username}@${config.networking.domain}";
    acceptTerms = true;
  };

  environment.systemPackages = with pkgs; [
    xe-guest-utilities
  ];

  services.hyperbib = {
    enable = true;
    domain = "eeg.cl.cam.ac.uk";
    # servicePath = "/bib/";
    # proxyPath = "/";
  };

  nix.settings.require-sigs = false;
}
