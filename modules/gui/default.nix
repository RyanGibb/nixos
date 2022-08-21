{ pkgs, nixpkgs-unstable, ... }:

{
  networking.networkmanager.enable = true;
  programs.nm-applet = {
    enable = true;
    indicator = true;
  };

  # used localtimed that is fixed in unstable
  # https://discourse.nixos.org/t/how-to-use-service-definitions-from-unstable-channel/14767
  disabledModules = [ "services/system/localtime.nix" ];
  imports = [
    "${nixpkgs-unstable}/nixos/modules/services/system/localtimed.nix"
    "${nixpkgs-unstable}/nixos/modules/services/system/localtimed.nix"
  ];
  ids.uids.localtimed = 325;
  ids.gids.localtimed = 325;
  # once merged into 22.05 delete the above 9 lines
  services.localtimed.enable = true;


  i18n.defaultLocale = "en_GB.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "uk";
  };

  # Needed for Keychron K2
  boot.extraModprobeConfig = ''
    options hid_apple fnmode=2
    options i915 enable_psr=0
  '';
  boot.kernelModules = [ "hid-apple" ];

  services.xserver = {
    desktopManager.xterm.enable = false;
    displayManager.startx.enable = true;
    layout = "gb";
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  nixpkgs.config.allowUnfree = true;

  home-manager = {
    useGlobalPkgs = true;
  };

  environment.systemPackages = with pkgs; [
    jq
    playerctl
    brightnessctl
    xdg-utils
    gnome.zenity
    networkmanagerapplet
    pavucontrol
    (xfce.thunar.override { thunarPlugins = with xfce; [
      thunar-archive-plugin
      xfconf
    ]; })
    gnome.file-roller
    # https://discourse.nixos.org/t/sway-wm-configuration-polkit-login-manager/3857/6
    polkit_gnome
    glib
    feh
    libnotify

    # https://nixos.wiki/wiki/PipeWire#pactl_not_found
    pulseaudio

    (firefox.override {
      cfg = {
        enableTridactylNative = true;
      };
    })
    tridactyl-native
    chromium
    gparted
    vlc
    pkgs.unstable.vscodium
  ];

  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-emoji
    (nerdfonts.override { fonts = [ "DroidSansMono" ]; })
    # for projects/cv latex package fontawesome
    font-awesome
    source-code-pro
    aileron
    vistafonts
  ];

  # thunar
  services.gvfs = {
    enable = true;
    package = pkgs.gvfs;
  };
  # thunar thumbnail support for images
  services.tumbler.enable = true;

  programs.kdeconnect.enable = true;
}
