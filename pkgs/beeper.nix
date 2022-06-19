{
  appimageTools,
  fetchurl,
  makeDesktopItem
}:

let
  name = "beeper";
  src = fetchurl {
    url = "https://download.beeper.com/linux/appImage/x64";
    sha256 = "0kfigksacihr0cwjmh2lpijq3llgvfvxbj77yxm0q10x269yp422";
  };
in
let
  desktopItem = (makeDesktopItem {
    name = "Beeper";
    desktopName = "Beeper";
    exec = "beeper";
    type = "Application";
    icon = "beeper";
    comment = "Beeper: Unified Messenger";
    categories = [ "Utility" ];
  });
  appimageContents = appimageTools.extractType2 {
    inherit name src;
  };
in
appimageTools.wrapType2 rec {
  inherit name src;

  extraInstallCommands = ''
    mkdir -p $out/share/applications
    install -Dm644 ${appimageContents}/beeper.png $out/share/icons/hicolor/256x256/apps/beeper.png
    install -Dm644 ${desktopItem}/share/applications/* $out/share/applications
  '';

  # from nixpkgs/pkgs/build-support/appimage/default.nix#L77 multiPkgs
  # TODO figure out which of these is actually required
  extraPkgs = pkgs: with pkgs; [
    desktop-file-utils
    xorg.libXcomposite
    xorg.libXtst
    xorg.libXrandr
    xorg.libXext
    xorg.libX11
    xorg.libXfixes
    libGL

    gst_all_1.gstreamer
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-plugins-base
    libdrm
    xorg.xkeyboardconfig
    xorg.libpciaccess

    glib
    gtk2
    bzip2
    zlib
    gdk-pixbuf

    xorg.libXinerama
    xorg.libXdamage
    xorg.libXcursor
    xorg.libXrender
    xorg.libXScrnSaver
    xorg.libXxf86vm
    xorg.libXi
    xorg.libSM
    xorg.libICE
    gnome2.GConf
    freetype
    (curl.override { gnutlsSupport = true; opensslSupport = false; })
    nspr
    nss
    fontconfig
    cairo
    pango
    expat
    dbus
    cups
    libcap
    SDL2
    libusb1
    udev
    dbus-glib
    atk
    at-spi2-atk
    libudev0-shim

    xorg.libXt
    xorg.libXmu
    xorg.libxcb
    xorg.xcbutil
    xorg.xcbutilwm
    xorg.xcbutilimage
    xorg.xcbutilkeysyms
    xorg.xcbutilrenderutil
    libGLU
    libuuid
    libogg
    libvorbis
    SDL
    SDL2_image
    glew110
    openssl
    libidn
    tbb
    wayland
    mesa
    libxkbcommon

    flac
    freeglut
    libjpeg
    libpng12
    libsamplerate
    libmikmod
    libtheora
    libtiff
    pixman
    speex
    SDL_image
    SDL_ttf
    SDL_mixer
    SDL2_ttf
    SDL2_mixer
    libappindicator-gtk2
    libcaca
    libcanberra
    libgcrypt
    libvpx
    librsvg
    xorg.libXft
    libvdpau
    alsa-lib

    harfbuzz
    e2fsprogs
    libgpg-error
    keyutils.lib
    libjack2
    fribidi
    p11-kit

    gmp

    # libraries not on the upstream include list, but nevertheless expected
    # by at least one appimage
    libtool.lib # for Synfigstudio
    xorg.libxshmfence # for apple-music-electron
    at-spi2-core
  ];
}
