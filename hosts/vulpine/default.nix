{ pkgs, config, lib, ... }@inputs:

{
  imports = [ ./hardware-configuration.nix ];

  custom = {
    enable = true;
    tailscale = true;
    printing = true;
    gui.kde = true;
    gui.i3 = true;
    gui.sway = true;
    workstation = true;
    autoUpgrade.enable = true;
    homeManager.enable = true;
    zsa = true;
  };

  home-manager.users.${config.custom.username} = {
    services.kdeconnect.enable = true;
    services.spotifyd = {
      enable = true;
      settings.global = {
        username = "ryangibb321@gmail.com";
        password_cmd = "pass show spotify/ryangibb321@gmail.com";
        zeroconf_port = 1234;
      };
    };
    services.gpg-agent.pinentry.package = lib.mkForce pkgs.pinentry-tty;
    custom = {
      machineColour = "magenta";
      calendar.enable = true;
      battery.enable = true;
      gui.sway.idle = "suspend_long";
    };
    home.sessionVariables = {
      LEDGER_FILE = "~/vault/finances.ledger";
    };
  };

  boot.loader.grub = {
    enable = true;
    default = "saved";
    device = "nodev";
    efiSupport = true;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "ntfs" ];

  fileSystems."/mnt/ssd" = {
    device = "/dev/disk/by-uuid/481c5422-0311-4d51-a5d9-b7d7ac1d5fac";
    fsType = "ext4";
  };

  environment.systemPackages = with pkgs; [
    pciutils
    file-roller
    unzip
    cheese
    chromium
    calibre
    zotero
    element-desktop
    spotify
    gimp
    gthumb
    restic
    evince
    libreoffice
    obs-studio
    ffmpeg
    deploy-rs
    nix-prefetch-git
    tcpdump
    pandoc
    ledger
    nixd
    # jellyfin-media-player
    # stremio
  ];

  security.sudo.extraConfig = ''
    Defaults !tty_tickets
  '';

  services.avahi.enable = true;

  # Use kernel and nvidia driver from nixpkgs-nvidia (6.12.41 with nvidia 575)
  boot.kernelPackages = let nvidia-nixpkgs = import inputs.nixpkgs-nvidia {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  }; in nvidia-nixpkgs.linuxPackages_6_12;

  hardware.nvidia.package = (import inputs.nixpkgs-nvidia {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  }).linuxPackages_6_12.nvidia_x11_latest;

  specialisation.nvidia.configuration = {
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.nvidia.open = false;
  };

  networking.firewall.allowedTCPPorts = [ 1234 ];
  networking.firewall.allowedUDPPorts = [ 1234 ];

  # allow wake from USB
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/wakeup", ATTR{power/wakeup}="enabled"
  '';

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    gamescopeSession = {
      enable = true;
      env.MANGOHUD = "1";
    };
    dedicatedServer.openFirewall = true;
  };

  programs.gamescope = {
    enable = true;
    capSysNice = true;  # reduces stutter
    env.MANGOHUD = "1";
  };

  programs.gamemode.enable = true;

  system.stateVersion = "24.05";

  # Fix audio delay with low-latency configuration
  services.pipewire = {
    extraConfig.pipewire = {
      "10-low-latency" = {
        "context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.quantum" = 512;
          "default.clock.min-quantum" = 256;
          "default.clock.max-quantum" = 2048;
        };
      };
    };

    wireplumber.configPackages = [
      (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/disable-suspension.conf" ''
        monitor.alsa.rules = [
          {
            matches = [
              {
                # Matches all sources
                node.name = "~alsa_input.*"
              },
              {
                # Matches all sinks
                node.name = "~alsa_output.*"
              }
            ]
            actions = {
              update-props = {
                session.suspend-timeout-seconds = 0
              }
            }
          }
        ]
        # bluetooth devices
        monitor.bluez.rules = [
          {
            matches = [
              {
                # Matches all sources
                node.name = "~bluez_input.*"
              },
              {
                # Matches all sinks
                node.name = "~bluez_output.*"
              }
            ]
            actions = {
              update-props = {
                session.suspend-timeout-seconds = 0
              }
            }
          }
        ]
      '')
    ];
  };
}
