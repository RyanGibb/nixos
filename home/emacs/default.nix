{
  pkgs,
  lib,
  config,
  ...
}:

let
  cfg = config.custom.emacs;
  emacs = pkgs.emacsWithDoom {
    emacs = pkgs.emacs30-pgtk;
    extraPackages =
      epkgs: with epkgs; [
        lsp-mode
        treesit-grammars.with-all-grammars
        vterm
        mu4e
        evil-collection
        gruvbox-theme
      ];
    doomDir = ./doom;
    doomLocalDir = "~/.local/share/nix-doom";
    extraBinPackages = with pkgs; [
      gnutls
      imagemagick
      pinentry-emacs
      zstd # for undo-fu-session/undo-tree compression
      git
      fd
      ripgrep
      nixd
    ];
  };
in
{
  options.custom.emacs.enable = lib.mkEnableOption "emacs";

  config = lib.mkIf cfg.enable {
    home.packages = [
      emacs
    ];

    home.file = {
      ".mail.cap".text = ''
        application/pdf; xdg-open %s
      '';
    };

    services.emacs = {
      enable = true;
      package = emacs;
      socketActivation.enable = true;
      # defaultEditor = true;
    };
  };
}
