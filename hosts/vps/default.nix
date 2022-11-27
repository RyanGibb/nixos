{ pkgs, lib, config, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/default.nix
    ../../modules/personal/default.nix
    ../../modules/hosting/default.nix
    ../../modules/hosting/dns.nix
    ../../modules/hosting/wireguard/default.nix
    ../../modules/personal/tailscale.nix
    ../../modules/hosting/mailserver.nix
    ../../modules/hosting/matrix.nix
    ../../modules/hosting/gitea.nix
    ../../modules/hosting/mastodon.nix
    ../../modules/hosting/nix-cache.nix
    ../../modules/hosting/freumh.nix
  ];

  networking.hostName = "vps";
  custom.machineColour = "yellow";

  boot.cleanTmpDir = true;
  zramSwap.enable = true;

  services.tailscale.enable = true;

  swapDevices = [ { device = "/var/swap"; size = 2048; } ];
}
