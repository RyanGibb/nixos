{ pkgs, config, ... }:

{
  programs.password-store.enable = true;
  programs.gpg.enable = true;
  services.gpg-agent.enable = true;

  xdg.configFile = {
    "aerc/binds.conf".source = ./aerc-binds.conf;
  };

  accounts.email = {
    maildirBasePath = "mail";
    accounts = {
      "ryan@freumh.org" = {
        primary = true;
        realName = "Ryan Gibb";
        userName = "ryan@freumh.org";
        address = "ryan@freumh.org";
        passwordCommand = "${pkgs.pass}/bin/pass show email/ryan@freumh.org";
        imap.host = "mail.freumh.org";
        smtp.host = "mail.freumh.org";
        imapnotify = {
          enable = true;
          boxes = [ "Inbox" ];
          onNotify = "${pkgs.isync}/bin/mbsync ryan@freumh.org && ${pkgs.notmuch}/bin/notmuch new";
        };
        mbsync = {
          enable = true;
          create = "both";
          expunge = "both";
          remove = "both";
        };
        notmuch.enable = true;
        aerc = {
          enable = true;
          extraAccounts = {
            folders-sort = [ "Inbox" "Archive" "Drafts" "Sent" "Junk" "Trash" ];
            check-mail-cmd = "${pkgs.isync}/bin/mbsync ryan@freumh.org";
            check-mail = "10m";
          };
        };
      };
      "misc@freumh.org" = {
        userName = "misc@freumh.org";
        address = "misc@freumh.org";
        realName = "Misc";
        passwordCommand = "${pkgs.pass}/bin/pass show email/misc@freumh.org";
        imap.host = "mail.freumh.org";
        smtp.host = "mail.freumh.org";
        imapnotify = {
          enable = true;
          boxes = [ "Inbox" ];
          onNotify = "${pkgs.isync}/bin/mbsync misc@freumh.org && ${pkgs.notmuch}/bin/notmuch new";
        };
        mbsync = {
          enable = true;
          create = "both";
          expunge = "both";
          remove = "both";
        };
        notmuch.enable = true;
        aerc = {
          enable = true;
          extraAccounts = {
            folders-sort = [ "Inbox" "Archive" "Drafts" "Sent" "Junk" "Trash" ];
            check-mail-cmd = "${pkgs.isync}/bin/mbsync misc@freumh.org";
            check-mail = "10m";
          };
        };
      };
      "ryan.gibb@cl.cam.ac.uk" = {
        userName = "rtg24@fm.cl.cam.ac.uk";
        address = "ryan.gibb@cl.cam.ac.uk";
        realName = "Ryan Gibb";
        passwordCommand = "${pkgs.pass}/bin/pass show email/ryan.gibb@cl.cam.ac.uk";
        flavor = "fastmail.com";
        imapnotify = {
          enable = true;
          boxes = [ "Inbox" ];
          onNotify = "${pkgs.isync}/bin/mbsync ryan.gibb@cl.cam.ac.uk && ${pkgs.notmuch}/bin/notmuch new";
        };
        mbsync = {
          enable = true;
          create = "both";
          expunge = "both";
          remove = "both";
        };
        notmuch.enable = true;
        aerc = {
          enable = true;
          extraAccounts = {
            folders-sort = [ "Inbox" "Sidebox" "Archive" "Drafts" "Sent" "Spam" "Trash" ];
            check-mail-cmd = "${pkgs.isync}/bin/mbsync ryan.gibb@cl.cam.ac.uk";
            check-mail = "10m";
          };
        };
      };
      "ryangibb321@gmail.com" = {
        userName = "ryangibb321@gmail.com";
        address = "ryangibb321@gmail.com";
        realName = "Ryan Gibb";
        passwordCommand = "${pkgs.pass}/bin/pass show email/ryangibb321@gmail.com";
        flavor = "gmail.com";
        folders = {
          sent = "Sent Mail";
          trash = "Trash";
        };
        imapnotify = {
          enable = true;
          boxes = [ "Inbox" ];
          onNotify = "${pkgs.isync}/bin/mbsync ryangibb321@gmail.com && ${pkgs.notmuch}/bin/notmuch new";
        };
        mbsync = {
          enable = true;
          create = "both";
          expunge = "both";
          remove = "both";
        };
        notmuch.enable = true;
        aerc = {
          enable = true;
          extraAccounts = {
            folders-sort = [ "Inbox" "All Mail" "Sent Mail" "Drafts" "Bin" ];
            check-mail-cmd = "${pkgs.isync}/bin/mbsync ryangibb321@gmail.com";
            check-mail = "10m";
            folder-map = "${pkgs.writeText "folder-map" ''
              * = [Gmail]/*
            ''}";
          };
        };
      };
    };
    order = [ "ryangibb321@gmail.com" "ryan.gibb@cl.cam.ac.uk" "misc@freumh.org" ];
  };
  programs.mbsync.enable = true;
  services.imapnotify.enable = true;
  programs.aerc.enable = true;
  programs.aerc.extraConfig = {
    general.unsafe-accounts-conf = true;
    general.default-save-path = "~/downloads";
    filters = {
      "text/plain" = "colorize";
      "text/calendar" = "calendar";
      "message/delivery-status" = "colorize";
      "message/rfc822" = "colorize";
      "text/html" = "html | colorize";
    };
  };
  programs.notmuch.enable = true;
}