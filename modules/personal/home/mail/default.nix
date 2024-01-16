{ pkgs, config, ... }:

let address-book = pkgs.writeScriptBin "address-book" ''
  #!/usr/bin/env bash
  ${pkgs.ugrep}/bin/ugrep -jPh -m 100 --color=never "$1"\
    ${config.accounts.email.maildirBasePath}/addressbook/maildir\
    ${config.accounts.email.maildirBasePath}/addressbook/cam-ldap
  '';
in {
  home.packages = with pkgs; [
    maildir-rank-addr
    (pkgs.writeScriptBin "cam-ldap-addr" ''
      ${pkgs.openldap}/bin/ldapsearch -xZ -H ldaps://ldap.lookup.cam.ac.uk -b "ou=people,o=University of Cambridge,dc=cam,dc=ac,dc=uk" displayName mail\
      | ${pkgs.gawk}/bin/awk '/^dn:/{displayName=""; mail=""; next} /^displayName:/{displayName=$2; for(i=3;i<=NF;i++) displayName=displayName " " $i; next} /^mail:/{mail=$2; next} /^$/{if(displayName!="" && mail!="") print mail "\t" displayName}'\
      > ${config.accounts.email.maildirBasePath}/addressbook/cam-ldap
    '')
    address-book
  ];

  xdg.configFile = {
    "aerc/binds.conf".source = ./aerc-binds.conf;
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
          check-mail-cmd = "${pkgs.isync}/bin/mbsync --all && ${pkgs.notmuch}/bin/notmuch new";
          check-mail-timeout = "5m";
          check-mail = "10m";
          source = "notmuch://${config.accounts.email.maildirBasePath}";
          folders-sort = [ "Inbox" "Sidebox" "Sent" "Drafts" "Archive" "Spam" "Trash" ];
          query-map = "${pkgs.writeText "query-map" ''
            Inbox=folder:ryan@freumh.org/Inbox folder:ryangibb321@gmail.com/Inbox folder:ryan.gibb@cl.cam.ac.uk/Inbox/
            Sidebox=folder:ryan@freumh.org/Sidebox folder:ryangibb321@gmail.com/Sidebox folder:ryan.gibb@cl.cam.ac.uk/Sidebox/
            Sent=folder:ryan@freumh.org/Sent folder:ryangibb321@gmail.com/Sent folder:ryan.gibb@cl.cam.ac.uk/Sent/
            Drafts=folder:ryan@freumh.org/Drafts folder:ryangibb321@gmail.com/Drafts folder:ryan.gibb@cl.cam.ac.uk/Drafts/
            Archive=folder:ryan@freumh.org/Archive folder:ryangibb321@gmail.com/Archive folder:ryan.gibb@cl.cam.ac.uk/Archive/
            Spam=folder:ryan@freumh.org/Spam folder:ryangibb321@gmail.com/Spam folder:ryan.gibb@cl.cam.ac.uk/Spam/
            Trash=folder:ryan@freumh.org/Trash folder:ryangibb321@gmail.com/Trash folder:ryan.gibb@cl.cam.ac.uk/Trash/
          ''}";
          auto-switch-account = true;
        };
      };
    };
  };

  services = {
    imapnotify.enable = true;
    gpg-agent.enable = true;
  };

  accounts.email = {
    maildirBasePath = "mail";
    order = [ "ryangibb321@gmail.com" "ryan.gibb@cl.cam.ac.uk" "misc@freumh.org" ];
    accounts = {
      "ryan@freumh.org" = {
        primary = true;
        realName = "Ryan Gibb";
        userName = "ryan@freumh.org";
        address = "ryan@freumh.org";
        passwordCommand = "${pkgs.pass}/bin/pass show email/ryan@freumh.org && ${pkgs.notmuch}/bin/notmuch new";
        imap.host = "mail.freumh.org";
        smtp.host = "mail.freumh.org";
        imapnotify = {
          enable = true;
          boxes = [ "Inbox" ];
          onNotify = "${pkgs.isync}/bin/mbsync ryan@freumh.org";
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
            folders-sort = [ "Inbox" "Sent" "Drafts" "Archive" "Spam" "Trash" ];
            check-mail-cmd = "${pkgs.isync}/bin/mbsync ryan@freumh.org && ${pkgs.notmuch}/bin/notmuch new";
            check-mail-timeout = "1m";
            check-mail = "10m";
            folder-map = "${pkgs.writeText "folder-map" ''
              Spam = Junk
            ''}";
          };
        };
        notmuch.enable = true;
      };
      "misc@freumh.org" = {
        userName = "misc@freumh.org";
        address = "misc@freumh.org";
        realName = "Misc";
        passwordCommand = "${pkgs.pass}/bin/pass show email/misc@freumh.org && ${pkgs.notmuch}/bin/notmuch new";
        imap.host = "mail.freumh.org";
        smtp.host = "mail.freumh.org";
        imapnotify = {
          enable = true;
          boxes = [ "Inbox" ];
          onNotify = "${pkgs.isync}/bin/mbsync misc@freumh.org";
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
            folders-sort = [ "Inbox" "Sent" "Drafts" "Archive" "Spam" "Trash" ];
            check-mail-cmd = "${pkgs.isync}/bin/mbsync misc@freumh.org && ${pkgs.notmuch}/bin/notmuch new";
            check-mail-timeout = "1m";
            check-mail = "10m";
            folder-map = "${pkgs.writeText "folder-map" ''
              Spam = Junk
            ''}";
          };
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
            folders-sort = [ "Inbox" "Sidebox" "Sent" "Drafts" "Archive" "Spam" "Trash" ];
            check-mail-cmd = "${pkgs.isync}/bin/mbsync ryan.gibb@cl.cam.ac.uk && ${pkgs.notmuch}/bin/notmuch new";
            check-mail-timeout = "1m";
            check-mail = "10m";
          };
        };
        notmuch.enable = true;
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
        aerc = {
          enable = true;
          extraAccounts = {
            folders-sort = [ "Inbox" "Sidebox" "Sent" "Drafts" "Archive" "Spam" "Trash" ];
            check-mail-cmd = "${pkgs.isync}/bin/mbsync ryangibb321@gmail.com && ${pkgs.notmuch}/bin/notmuch new";
            check-mail-timeout = "1m";
            check-mail = "10m";
            folder-map = "${pkgs.writeText "folder-map" ''
              * = [Gmail]/*
              Trash = Bin
              Archive = All Mail
              Sent = Sent Mail
            ''}";
          };
        };
        notmuch.enable = true;
      };
    };
  };
}
