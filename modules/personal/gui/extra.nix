{ pkgs, config, lib, ... }:

let cfg = config.personal.gui; in
{
  options.personal.gui.extra = lib.mkEnableOption "extra";

  config.environment.systemPackages = with pkgs; lib.mkIf cfg.extra [
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
