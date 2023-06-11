{ pkgs, config, lib, ... }:

let cfg = config.personal.gui; in
{
  options.personal.gui.extra = lib.mkEnableOption "extra";

  config = lib.mkIf cfg.extra {
    environment.systemPackages = with pkgs; [
      thunderbird
      element-desktop
      signal-desktop
      zotero
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

      neomutt
      liferea
    ];
    environment.shellAliases = {
      mutt = "neomutt";
    };
    programs.kdeconnect.enable = true;
  };
}
