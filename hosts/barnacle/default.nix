{
  config,
  lib,
  pkgs,
  nixpkgs,
  ...
}:

# build with:
#   nix build --impure /etc/nixos#nixosConfigurations.barnacle.config.system.build.isoImage

{
  imports = [
    "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-base.nix"
    # installs nixpkgs channel for installation
    "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  # installer media has no root zfs pool; adopt the 26.11 default
  boot.zfs.forceImportRoot = false;

  custom = {
    enable = true;
    laptop = true;
    gui.niri = true;
    homeManager.enable = true;
    tailscale = true;
    username = "nixos";
  };
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

  # live ISO host keys are regenerated every boot; needs `nix build --impure`
  # from the store, as agenix decrypts before /etc is populated
  age.identityPaths = [ "${/home/ryan/.config/barnacle/agenix-key}" ];
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
    "nixos" = {
      recursive = true;
      source = ../..;
    };
  };

  # comment this out to make a smaller image
  isoImage.squashfsCompression = "gzip -Xcompression-level 1";

  system.stateVersion = "24.05";
}
