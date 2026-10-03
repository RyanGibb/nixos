{ config, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  custom = {
    enable = true;
    tailscale = true;
    hysteria = {
      enable = true;
      domain = "kiji.freumh.org";
      masqueradeUrl = "https://freumh.org/";
    };
    reality = {
      enable = true;
      dest = "docs.oracle.com:443";
      shortId = "c923b71f7ba75d03";
      publicKey = "659hamBoWkjGWHgC1Za-EZ8kW7teID_0ZdatSE0vVEo";
      port = 8443;
    };
  };

  age.secrets."eon-freumh.org.cap" = {
    file = ../../secrets/eon-freumh.org.cap.age;
    owner = "acme-eon";
    group = "acme-eon";
  };
  security.acme-eon = {
    acceptTerms = true;
    defaults.email = "${config.custom.username}@${config.networking.domain}";
    defaults.capFile = config.age.secrets."eon-freumh.org.cap".path;
    nginxCerts = [ "kiji.freumh.org" ];
  };

  # relay for headscale; region 998 in owl's derp map
  services.tailscale.derper = {
    enable = true;
    domain = "kiji.freumh.org";
  };
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.openssh.openFirewall = true;

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # oracle's console history captures ttyS0
  boot.kernelParams = [
    "console=ttyS0,115200"
    "console=tty0"
  ];

  # 1 GB of RAM
  zramSwap.enable = true;
  boot.tmp.cleanOnBoot = true;
  services.journald.extraConfig = ''
    SystemMaxUse=500M
  '';

  system.stateVersion = "25.11";
}
