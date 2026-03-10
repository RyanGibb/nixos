{
  pkgs,
  lib,
  config,
  caledonia,
  ...
}:

let
  cfg = config.custom.emacs;
  emacsPackages = pkgs.emacsPackagesFor pkgs.emacs30-pgtk;
  claude-code-ide = emacsPackages.trivialBuild {
    pname = "claude-code-ide";
    version = "0-unstable-2025-03-08";
    src = pkgs.fetchFromGitHub {
      owner = "manzaltu";
      repo = "claude-code-ide.el";
      rev = "5f12e60c6d2d1802c8c1b7944bbdf935d5db1364";
      hash = "sha256-tivRvgfI/8XBRImE3wuZ1UD0t2dNWYscv3Aa53BmHZE=";
    };
    packageRequires = with emacsPackages; [ vterm websocket transient web-server ];
  };
  caledonia-el = emacsPackages.trivialBuild {
    pname = "caledonia";
    version = "0-unstable";
    src = "${caledonia}/emacs";
    packageRequires = with emacsPackages; [ evil ];
  };
  emacs = emacsPackages.emacsWithPackages (
    epkgs: with epkgs; [
      # Evil (vim keybindings)
      evil
      evil-collection
      evil-surround
      evil-nerd-commenter
      evil-snipe
      evil-easymotion
      evil-org
      avy
      undo-tree

      # Snippets
      yasnippet
      yasnippet-snippets
      yasnippet-capf

      # Completion
      vertico
      vertico-posframe
      orderless
      marginalia
      consult
      embark
      embark-consult
      wgrep
      corfu
      cape

      # Workspaces
      persp-mode

      # Leader keys
      general

      # UI
      gruvbox-theme
      doom-modeline
      nerd-icons

      # Windows
      ace-window

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

      # Terminal
      vterm

      # AI
      claude-code-ide

      # Calendar
      caledonia-el

      # Debugger
      dape

      # Languages
      neocaml
      nix-mode
      ledger-mode
      auctex
      nael

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
    xdg.configFile."emacs/snippets".source = ./snippets;

    services.emacs = {
      enable = true;
      package = emacs;
      socketActivation.enable = true;
    };
  };
}
