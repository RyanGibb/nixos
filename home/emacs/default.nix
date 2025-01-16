{
  pkgs,
  lib,
  config,
  ...
}:

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
    home.packages = with pkgs; [
      binutils
      emacs
      gnutls
      imagemagick
      pinentry-emacs
      # for undo-fu-session/undo-tree compression
      zstd
    ];

    programs.zsh.initExtra = lib.mkAfter ''
      PATH="''${XDG_CONFIG_HOME:-$HOME/.config}/emacs/bin":$PATH
    '';

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
