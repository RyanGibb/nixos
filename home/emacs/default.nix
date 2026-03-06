{
  pkgs,
  lib,
  config,
  ...
}:

let
  cfg = config.custom.emacs;
  emacs = (pkgs.emacsPackagesFor pkgs.emacs30-pgtk).emacsWithPackages (
    epkgs: with epkgs; [
      # Evil (vim keybindings)
      evil
      evil-collection
      undo-tree

      # Snippets
      yasnippet
      yasnippet-snippets

      # Completion
      vertico
      vertico-posframe
      orderless
      marginalia
      consult
      embark
      embark-consult
      corfu
      cape

      # Workspaces
      perspective

      # Leader keys
      general

      # UI
      gruvbox-theme
      doom-modeline
      nerd-icons

      # Help
      helpful

      # Tools
      magit
      citar
      pdf-tools
      diff-hl
      envrc

      # Email
      mu4e

      # RSS
      elfeed
      elfeed-org

      # Debugger
      dape

      # Languages
      neocaml
      nix-mode
      ledger-mode

      # Tree-sitter
      treesit-grammars.with-all-grammars
    ]
  );
in
{
  options.custom.emacs.enable = lib.mkEnableOption "emacs";

  config = lib.mkIf cfg.enable {
    home.packages = [
      emacs
      pkgs.nerd-fonts.symbols-only
    ];

    home.file.".mailcap".text = ''
      application/pdf; xdg-open %s
    '';

    xdg.configFile."emacs/early-init.el".source = ./early-init.el;
    xdg.configFile."emacs/init.el".source = ./init.el;
    xdg.configFile."emacs/appearance.el".source = ./appearance.el;
    xdg.configFile."emacs/evil.el".source = ./evil.el;
    xdg.configFile."emacs/completion.el".source = ./completion.el;
    xdg.configFile."emacs/tools.el".source = ./tools.el;
    xdg.configFile."emacs/org.el".source = ./org.el;
    xdg.configFile."emacs/mu4e.el".source = ./mu4e.el;
    xdg.configFile."emacs/languages.el".source = ./languages.el;

    services.emacs = {
      enable = true;
      package = emacs;
      socketActivation.enable = true;
    };
  };
}
