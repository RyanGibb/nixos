{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    thunderbird
    element-desktop
    signal-desktop
    unstable.zotero
    unstable.obsidian
    spotify
    gimp
    texlive.combined.scheme-full
    evince
    pdfpc
    calibre
    transmission
    transmission-gtk
    drive
    libreoffice
    obs-studio

    xournalpp
    inkscape

    kdenlive
    tor-browser-bundle-bin
    zoom-us
    ffmpeg
    audio-recorder
    speechd
    krop

    bitwarden
  ];
}
