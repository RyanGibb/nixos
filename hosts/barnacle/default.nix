{
  config,
  lib,
  pkgs,
  nixpkgs,
  ...
}:

# build with:
#   nix build --impure /etc/nixos#nixosConfigurations.barnacle.config.system.build.isoImage

let
  # the agenix key and wallpaper are only read under --impure (the ISO build);
  # pure evaluation (nix flake check, deploy-rs) skips them
  impure = builtins ? currentSystem;
in
{
  warnings = lib.optional (!impure) "barnacle: pure eval, the ISO won't be able to decrypt its secrets";

  imports = [
    "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-base.nix"
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  # installer media has no root zfs pool; adopt the 26.11 default
  boot.zfs.forceImportRoot = false;

  custom = {
    enable = true;
    laptop = true;
    gui.niri = true;
    gui.extras = false;
    homeManager.enable = true;
    tailscale = true;
    dict = false;
    username = "nixos";
  };
  services.speechd.enable = lib.mkForce false;
  users.users.${config.custom.username}.hashedPassword = lib.mkForce null;
  users.users.root.hashedPassword = lib.mkForce null;
  # the installer's nixos user has an empty password
  security.pam.services.ly.allowNullPassword = true;

  # recovery tool: recreate the grub UEFI NVRAM entry after a firmware reset wipes it
  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "fix-uefi-boot";
      runtimeInputs = [ pkgs.efibootmgr ];
      text = builtins.readFile ./fix-uefi-boot.sh;
    })
  ];

  services.openssh.settings.PermitRootLogin = lib.mkForce "no";
  services.getty.autologinUser = lib.mkForce "${config.custom.username}";
  services.getty.helpLine = lib.mkForce "";

  # vulpine's BCM4360 needs the proprietary wl, but wl's alias claims every
  # wifi card, so only load it for that chip
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
  boot.blacklistedKernelModules = [ "wl" ];
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x14e4", ATTR{device}=="0x43a0", RUN+="${pkgs.kmod}/bin/modprobe -r b43 bcma ssb", RUN+="${pkgs.kmod}/bin/modprobe wl"
  '';

  # live ISO host keys are regenerated every boot; needs `nix build --impure`
  # from the store, as agenix decrypts before /etc is populated
  age.identityPaths = lib.mkIf impure [ "${/home/ryan/.config/barnacle/agenix-key}" ];
  age.secrets.headscale-barnacle.file = ../../secrets/headscale-barnacle.age;
  age.secrets.wifi-barnacle.file = ../../secrets/wifi-barnacle.age;

  networking.networkmanager.ensureProfiles = {
    environmentFiles = [ config.age.secrets.wifi-barnacle.path ];
    profiles.home = {
      connection = {
        id = "home";
        type = "wifi";
      };
      wifi.ssid = "$HOME_SSID";
      wifi-security = {
        key-mgmt = "wpa-psk";
        psk = "$HOME_PSK";
      };
    };
  };

  # reusable ephemeral preauth key, so each boot registers a fresh node and stale ones expire
  services.tailscale = {
    authKeyFile = config.age.secrets.headscale-barnacle.path;
    extraUpFlags = [
      "--login-server=https://headscale.freumh.org"
      "--hostname=barnacle"
    ];
  };
  systemd.services.tailscaled-autoconnect = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };

  home-manager.users.${config.custom.username}.config.home.file = {
    "install.sh".source = ./install.sh;
    ".cache/wallpaper" = lib.mkIf impure {
      source = /home/ryan/pictures/wallpapers/2025-10-24-mist.jpg;
    };
    "nixos" = {
      recursive = true;
      source = ../..;
    };
  };

  # uncomment for a faster build but a larger image
  # isoImage.squashfsCompression = "gzip -Xcompression-level 1";

  system.stateVersion = "24.05";
}
