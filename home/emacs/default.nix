{ pkgs, lib, config, ... }:

let cfg = config.custom.emacs;
in {
  options.custom.emacs.enable = lib.mkEnableOption "emacs";

  config = lib.mkIf cfg.enable {
    programs.emacs = {
      enable = true;
      package = pkgs.emacs29-pgtk;
      extraPackages = epkgs:
        with epkgs; [
          evil
          evil-leader
          # https://github.com/emacs-evil/evil-collection/pull/812/commits/149eacce58354f0ee3a55d4c12059148ef4ff953
          pkgs.overlay-unstable.emacsPackages.evil-collection
          evil-ledger
          evil-org
          undo-tree
          gruvbox-theme
          helm
          mu4e
          ledger-mode
          org
          org-evil
        ];
    };
    home.file = {
      ".emacs.d/init.el".source = ./init.el;
      ".emacs.d/config".source = ./config;
      ".mail.cap".text = ''
        application/pdf; xdg-open %s
      '';
    };
  };
}
