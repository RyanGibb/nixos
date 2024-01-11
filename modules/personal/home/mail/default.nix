{ pkgs, config, ... }:

{
  home.packages = with pkgs; [
    maildir-rank-addr
    (pkgs.writeScriptBin "cam-ldap-addr" ''
      ${pkgs.openldap}/bin/ldapsearch -xZ -H ldaps://ldap.lookup.cam.ac.uk -b "ou=people,o=University of Cambridge,dc=cam,dc=ac,dc=uk" displayName mail\
      | ${pkgs.gawk}/bin/awk '/^dn:/{displayName=""; mail=""; next} /^displayName:/{displayName=$2; for(i=3;i<=NF;i++) displayName=displayName " " $i; next} /^mail:/{mail=$2; next} /^$/{if(displayName!="" && mail!="") print mail "\t" displayName}'\
      > ${config.accounts.email.maildirBasePath}/addressbook/cam-ldap
    '')
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
    aerc = {
      enable = true;
      extraConfig = {
        general.unsafe-accounts-conf = true;
        general.default-save-path = "~/downloads";
        ui.mouse-enabled = true;
        compose.address-book-cmd = "${pkgs.ugrep}/bin/ugrep -jPh -m 100 --color=never %s " +
          "${config.accounts.email.maildirBasePath}/addressbook/maildir " +
          "${config.accounts.email.maildirBasePath}/addressbook/cam-ldap";
        compose.file-picker-cmd = "${pkgs.ranger}/bin/ranger --choosefiles=%f";
        filters = {
          "text/plain" = "wrap -w 100 | colorize";
          "text/calendar" = "calendar";
          "message/delivery-status" = "colorize";
          "message/rfc822" = "colorize";
          "text/html" = "html | colorize";
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
        passwordCommand = "${pkgs.pass}/bin/pass show email/ryan@freumh.org";
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
            folders-sort = [ "Inbox" "Archive" "Drafts" "Sent" "Junk" "Trash" ];
            check-mail-cmd = "${pkgs.isync}/bin/mbsync ryan@freumh.org";
            check-mail-timeout = "1m";
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
            folders-sort = [ "Inbox" "Archive" "Drafts" "Sent" "Junk" "Trash" ];
            check-mail-cmd = "${pkgs.isync}/bin/mbsync misc@freumh.org";
            check-mail-timeout = "1m";
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
          onNotify = "${pkgs.isync}/bin/mbsync ryan.gibb@cl.cam.ac.uk";
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
            folders-sort = [ "Inbox" "Sidebox" "Archive" "Drafts" "Sent" "Spam" "Trash" ];
            check-mail-cmd = "${pkgs.isync}/bin/mbsync ryan.gibb@cl.cam.ac.uk";
            check-mail-timeout = "1m";
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
          onNotify = "${pkgs.isync}/bin/mbsync ryangibb321@gmail.com";
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
            folders-sort = [ "Inbox" "All Mail" "Sent Mail" "Drafts" "Bin" ];
            check-mail-cmd = "${pkgs.isync}/bin/mbsync ryangibb321@gmail.com";
            check-mail-timeout = "1m";
            check-mail = "10m";
            folder-map = "${pkgs.writeText "folder-map" ''
              * = [Gmail]/*
              Trash = Bin
            ''}";
          };
        };
      };
    };
  };
}