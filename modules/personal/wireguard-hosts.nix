{ config, lib, ... }:

let cfg = config.personal;
in {
  config.wireguard.hosts = lib.mkIf cfg.enable {
    "vps" = {
      ip = "10.0.0.1";
      publicKey = "2nS3QA2XVG4IgRmtTsOQbpjbqKgRhoZ4gL8PeQhJLGE=";
      server = true;
      endpoint = config.eilean.serverIpv4;
    };
    "dell-xps" = {
      ip = "10.0.0.2";
      publicKey = "K9Lq7lQeueo4/fjCRBHOWQjcTHd5vhCHljI6m/ZOcUM=";
    };
    "pixel-4a" = {
      ip = "10.0.0.3";
      publicKey = "KPstJ3Dd8YgZ2vsu0RIzjxdZhv1RlAVw2PGqyV1+eX4=";
    };
    "desktop" = {
      ip = "10.0.0.4";
      publicKey = "aP0A0Lc7ABFvITmi9DIZiRKen3kBspMa6nsfrMrep2Y=";
    };
    "rasp-pi" = {
      ip = "10.0.0.5";
      publicKey = "xG1dOV/C/rvPUbAMp6F+cEAC3t1DxNFJLPF457RTmQ4=";
      persistentKeepalive = 25;
    };
  };
}
