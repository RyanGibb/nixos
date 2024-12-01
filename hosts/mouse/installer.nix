{
  nixpkgs,
  lib,
  pkgs,
  config,
  ...
}:

# A minimal config for a ARMv6-L Raspberry Pi 1 that can be built to an SD card image with:
#   `nix build .#nixosConfigurations.mouse-install.config.system.build.toplevel
#
# Some package can't be cross compiled to ARMv6-L Linux from x86_64 Linux in nixpkgs revision
# b8dd8be3c790215716e7c12b247f45ca525867e2 (e.g. nvim) so are excluded.
#
# To automatically join a Tailscale network at freumh.org add the secret in a `headscale` file
# in the project root.
{
  imports = [ "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-raspberrypi.nix" ];

  # from hardware-configuration.nix
  # https://github.com/NixOS/nixpkgs/issues/141470#issuecomment-996202318
  boot.initrd.availableKernelModules = lib.mkForce [ ];

  networking.useDHCP = lib.mkDefault true;

  hardware.enableRedistributableFirmware = lib.mkDefault true;

  console = {
    font = "Lat2-Terminus16";
    keyMap = "uk";
  };

  nixpkgs.hostPlatform = lib.systems.examples.raspberryPi;

  programs.bash.shellInit = ''
    export VISUAL=vim
    set -o vi
  '';

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

  environment.systemPackages = with pkgs; [
    vim
    tmux
  ];

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
