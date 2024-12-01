{
  nixpkgs,
  lib,
  pkgs,
  config,
  ...
}:

{
  imports = [ "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-raspberrypi.nix" ];

  # from hardware-configuration.nix
  # https://github.com/NixOS/nixpkgs/issues/141470#issuecomment-996202318
  boot.initrd.availableKernelModules = lib.mkForce [
    "xhci_pci"
    "usbhid"
  ];
  #boot.initrd.availableKernelModules = lib.mkForce [ ];

  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  swapDevices = [
    {
      device = "/var/swap";
      size = 4096;
    }
  ];

  networking.useDHCP = lib.mkDefault true;

  hardware.enableRedistributableFirmware = lib.mkDefault true;

  # https://discourse.nixos.org/t/building-libcamera-for-raspberry-pi/26133/7
  nixpkgs.hostPlatform = {
    system = "armv6l-linux";
    gcc = {
      arch = "armv6k";
      fpu = "vfp";
    };
  };
  # required removing ncdu, pandoc, nix-tree, and neovim for cross-compilation

  networking.hostName = "mouse";

  users =
    let
      hashedPassword = "$6$IPvnJnu6/fp1Jxfy$U6EnzYDOC2NqE4iqRrkJJbSTHHNWk0KwK1xyk9jEvlu584UWQLyzDVF5I1Sh47wQhSVrvUI4mrqw6XTTjfPj6.";
    in
    {
      mutableUsers = false;
      users.ryan = {
        isNormalUser = true;
        extraGroups = [
          "wheel" # enable sudo
        ];
        hashedPassword = hashedPassword;
        openssh.authorizedKeys.keyFiles = [ ../../modules/authorized_keys ];
      };
      users.root = {
        hashedPassword = hashedPassword;
        openssh.authorizedKeys.keyFiles = [ ../../modules/authorized_keys ];
      };
    };

  environment.systemPackages = with pkgs; [ vim ];

  services.tailscale = {
    enable = true;
    #authKeyFile = ../../headscale;
    extraUpFlags = [ "--login-server https://headscale.freumh.org" ];
  };
  networking.firewall = {
    checkReversePath = "loose";
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };

  services.openssh = {
    enable = true;
    openFirewall = lib.mkDefault false;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = false;
    };
  };
}
