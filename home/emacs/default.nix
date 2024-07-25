{ pkgs, ... }:

{
  config = {
    programs.emacs = {
      enable = true;
      package = pkgs.emacs29-pgtk;
      extraPackages = epkgs: with epkgs; [
        evil
        evil-leader
        undo-tree
        gruvbox-theme
	mu4e
      ];
    };
    home.file = {
      ".emacs.d/init.el".source = ./init.el;
    };
  };
}
