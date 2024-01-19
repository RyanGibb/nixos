{ pkgs, config, ... }:

let
  address-book = pkgs.writeScriptBin "address-book" ''
    #!/usr/bin/env bash
    ${pkgs.ugrep}/bin/ugrep -jPh -m 100 --color=never "$1"\
      ${config.accounts.email.maildirBasePath}/addressbook/maildir\
      ${config.accounts.email.maildirBasePath}/addressbook/cam-ldap
    '';
  sync-mail = pkgs.writeScriptBin "sync-mail" (import ./sync-mail.nix config.accounts.email.maildirBasePath pkgs.isync);
in {
  home.packages = with pkgs; [
    maildir-rank-addr
    (pkgs.writeScriptBin "cam-ldap-addr" ''
      ${pkgs.openldap}/bin/ldapsearch -xZ -H ldaps://ldap.lookup.cam.ac.uk -b "ou=people,o=University of Cambridge,dc=cam,dc=ac,dc=uk" displayName mail\
      | ${pkgs.gawk}/bin/awk '/^dn:/{displayName=""; mail=""; next} /^displayName:/{displayName=$2; for(i=3;i<=NF;i++) displayName=displayName " " $i; next} /^mail:/{mail=$2; next} /^$/{if(displayName!="" && mail!="") print mail "\t" displayName}'\
      > ${config.accounts.email.maildirBasePath}/addressbook/cam-ldap
    '')
    address-book
    sync-mail
  ];

  xdg.configFile = {
    "maildir-rank-addr/config".text = with config.accounts.email; ''
      maildir = "${config.accounts.email.maildirBasePath}"
      outputpath = "${config.accounts.email.maildirBasePath}/addressbook/maildir"
      addresses = [
          "ryan@freumh.org",
          "misc@freumh.org",
          "ryan@gibbr.org",
          "misc@gibbr.org",
          "ryan.gibb@cl.cam.ac.uk",
          "rtg24@cam.ac.uk",
          "rtg2@st-andrews.ac.uk",
          "ryangibb321@gmail.com",
          "ryangibb@btconnect.com",
      ]
    '';
  };

  programs = {
    password-store.enable = true;
    gpg.enable = true;
    mbsync.enable = true;
    notmuch.enable = true;
    aerc = {
      enable = true;
      extraConfig = {
        general.unsafe-accounts-conf = true;
        general.default-save-path = "~/downloads";
        ui.mouse-enabled = true;
        compose.address-book-cmd = "${address-book}/bin/address-book '%s'";
        compose.file-picker-cmd = "${pkgs.ranger}/bin/ranger --choosefiles=%f";
        ui.index-columns = "date<=,name<50,flags>=,subject<*";
        ui.column-name = "{{index (.From | persons) 0}}";
        "ui:account=all".index-columns = "date<=,to<=,name<50,flags>=,subject<*";
        # assumes mail under /home/<use>/<mail>/<account>
        "ui:account=all".column-to = ''
          {{if eq .Filename ""}}{{"na"}}{{else}}{{index (.Filename | split ("/")) 4}}{{end}}
        '';
        "ui:account=all".column-name = "{{index (.From | persons) 0}}";
        filters = {
          "text/plain" = "colorize";
          "text/calendar" = "calendar";
          "message/delivery-status" = "colorize";
          "message/rfc822" = "colorize";
          "text/html" = "html | colorize";
        };
      };
      extraAccounts = {
        all = {
          from = "Ryan Gibb <ryan@freumh.org>";
          outgoing = "smtps+plain://ryan@freumh.org@mail.freumh.org:465";
          outgoing-cred-cmd = "${pkgs.pass}/bin/pass show email/ryan@freumh.org";
          check-mail-cmd = "${pkgs.notmuch}/bin/notmuch new";
          check-mail-timeout = "5m";
          check-mail = "1h";
          source = "notmuch://${config.accounts.email.maildirBasePath}";
          folders-sort = [ "inbox" "sidebox" "sent" "archive" "spam" "trash" ];
          query-map = "${pkgs.writeText "query-map" ''
            inbox   = tag:inbox
            sidebox = tag:sidebox
            sent    = tag:sent
            draft   = tag:sent
            archive = tag:archive
            spam    = tag:spam
            trash   = tag:trash
          ''}";
          auto-switch-account = true;
        };
      };
      extraBinds = import ./aerc-binds.nix;
    };
  };

  services = {
    imapnotify.enable = true;
    gpg-agent.enable = true;
  };

  accounts.email = {
    maildirBasePath = "mail";
    order = [ "ryangibb321@gmail.com" "ryan.gibb@cl.cam.ac.uk" ];
    accounts = {
      "ryan@freumh.org" = {
        primary = true;
        realName = "Ryan Gibb";
        userName = "ryan@freumh.org";
        address = "ryan@freumh.org";
        passwordCommand = "${pkgs.pass}/bin/pass show email/ryan@freumh.org";
        imap.host = "mail.freumh.org";
        smtp = {
          host = "mail.freumh.org";
          port = 465;
        };
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
        aerc = {
          enable = true;
          extraAccounts = {
            check-mail-cmd = "${pkgs.isync}/bin/mbsync ryan@freumh.org && ${pkgs.notmuch}/bin/notmuch new";
            check-mail-timeout = "1m";
            check-mail = "1h";
            folders-sort = [ "Inbox" "Sent" "Drafts" "Archive" "Spam" "Trash" ];
            folder-map = "${pkgs.writeText "folder-map" ''
              Spam = Junk
            ''}";
            #folders-sort = [ "inbox" "sidebox" "sent" "archive" "spam" "trash" ];
            query-map = "${pkgs.writeText "query-map" ''
              inbox   = folder:/ryan@freumh.org/ and tag:inbox
              sidebox = folder:/ryan@freumh.org/ and tag:sidebox
              sent    = folder:/ryan@freumh.org/ and tag:sent
              draft   = folder:/ryan@freumh.org/ and tag:sent
              archive = folder:/ryan@freumh.org/ and tag:archive
              spam    = folder:/ryan@freumh.org/ and tag:spam
              trash   = folder:/ryan@freumh.org/ and tag:trash
            ''}";
          };
          #notmuch.enable = true;
        };
        notmuch.enable = true;
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
        aerc = {
          enable = true;
          extraAccounts = {
            check-mail-cmd = "${pkgs.isync}/bin/mbsync ryan.gibb@cl.cam.ac.uk && ${pkgs.notmuch}/bin/notmuch new";
            check-mail-timeout = "1m";
            check-mail = "1h";
            aliases = "rtg24@cam.ac.uk";
            folders-sort = [ "Inbox" "Sidebox" "Sent" "Drafts" "Archive" "Spam" "Trash" ];
            #folders-sort = [ "inbox" "sidebox" "sent" "archive" "spam" "trash" ];
            query-map = "${pkgs.writeText "query-map" ''
              inbox   = folder:/ryan.gibb@cl.cam.ac.uk/ and tag:inbox
              sidebox = folder:/ryan.gibb@cl.cam.ac.uk/ and tag:sidebox
              sent    = folder:/ryan.gibb@cl.cam.ac.uk/ and tag:sent
              draft   = folder:/ryan.gibb@cl.cam.ac.uk/ and tag:sent
              archive = folder:/ryan.gibb@cl.cam.ac.uk/ and tag:archive
              spam    = folder:/ryan.gibb@cl.cam.ac.uk/ and tag:spam
              trash   = folder:/ryan.gibb@cl.cam.ac.uk/ and tag:trash
            ''}";
          };
          #notmuch.enable = true;
        };
        notmuch.enable = true;
      };
      "ryangibb321@gmail.com" = {
        userName = "ryangibb321@gmail.com";
        address = "ryangibb321@gmail.com";
        realName = "Ryan Gibb";
        passwordCommand = "${pkgs.pass}/bin/pass show email/ryangibb321@gmail.com";
        flavor = "gmail.com";
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
        aerc = {
          enable = true;
          extraAccounts = {
            check-mail-cmd = "${pkgs.isync}/bin/mbsync ryangibb321@gmail.com && ${pkgs.notmuch}/bin/notmuch new";
            check-mail-timeout = "1m";
            check-mail = "1h";
            folders-sort = [ "Inbox" "Sidebox" "Sent" "Drafts" "Archive" "Spam" "Trash" ];
            folder-map = "${pkgs.writeText "folder-map" ''
              * = [Gmail]/*
              Trash = Bin
              Archive = All Mail
              Sent = Sent Mail
            ''}";
            #folders-sort = [ "inbox" "sidebox" "sent" "archive" "spam" "trash" ];
            query-map = "${pkgs.writeText "query-map" ''
              inbox   = folder:/ryangibb321@gmail.com/ and tag:inbox
              sidebox = folder:/ryangibb321@gmail.com/ and tag:sidebox
              sent    = folder:/ryangibb321@gmail.com/ and tag:sent
              draft   = folder:/ryangibb321@gmail.com/ and tag:sent
              archive = folder:/ryangibb321@gmail.com/ and tag:archive
              spam    = folder:/ryangibb321@gmail.com/ and tag:spam
              trash   = folder:/ryangibb321@gmail.com/ and tag:trash
            ''}";
          };
          #notmuch.enable = true;
        };
        notmuch.enable = true;
      };
    };
  };
}
