{
  pkgs,
  lib,
  config,
  ...
}@inputs:

let
  cfg = config.custom.emacs;
  emacs = (pkgs.emacsPackagesFor pkgs.emacs29-pgtk).emacsWithPackages (
    epkgs: with epkgs; [
      treesit-grammars.with-all-grammars
      vterm
      mu4e
    ]
  );
in
{
  options.custom.emacs.enable = lib.mkEnableOption "emacs";

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      inputs.emacs-overlay.overlays.default
    ];

    home.packages = with pkgs; [
      binutils
      emacs
      gnutls
      imagemagick
      pinentry-emacs
      # for undo-fu-session/undo-tree compression
      zstd
    ];

    home.sessionPath = [ "$XDG_CONFIG_HOME/emacs/bin" ];

    # modules.shell.zsh.rcFiles = [ "${config.xdg.configHome}/emacs/aliases.zsh" ];

    home.file = {
      ".mail.cap".text = ''
        application/pdf; xdg-open %s
      '';
    };
  };
}
