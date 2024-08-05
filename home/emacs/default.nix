{ pkgs, ... }:

{
  config = {
    programs.emacs = {
      enable = true;
      package = pkgs.emacs29-pgtk;
      extraPackages = epkgs: with epkgs; [
        evil
        evil-leader
        evil-collection
        evil-ledger
        evil-org
        undo-tree
        gruvbox-theme
        helm
        mu4e
        ement
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

    services.pantalaimon = {
      enable = true;
      settings = {
        Default = {
          LogLevel = "Info";
          SSL = true;
          Notifications = "On";
        };
        Freumh = {
          Homeserver = "https://matrix.freumh.org";
          ListenAddress = "localhost";
          ListenPort = 8009;
          IgnoreVerification = true;
        };
      };
    };
  };
}
