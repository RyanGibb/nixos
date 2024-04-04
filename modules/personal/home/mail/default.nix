{ pkgs, config, ... }:

let
  address-book = pkgs.writeScriptBin "address-book" ''
    #!/usr/bin/env bash
    ${pkgs.ugrep}/bin/ugrep -jPh -m 100 --color=never "$1"\
      ${config.accounts.email.maildirBasePath}/addressbook/maildir\
      ${config.accounts.email.maildirBasePath}/addressbook/cam-ldap
    '';
  sync-mail = pkgs.writeScriptBin "sync-mail" ''
    #!/usr/bin/env bash
    ${pkgs.isync}/bin/mbsync "$1"
    ${pkgs.mu}/bin/mu index
    ${pkgs.procps}/bin/pkill -RTMIN+13 i3block
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
    mu.enable = true;
    msmtp.enable = true;
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
        "ui:folder=Sent".index-columns = "date<=,to<50,flags>=,subject<*";
        "ui:folder=Sent".column-to = "{{index (.To | persons) 0}}";
        openers."text/html" = "firefox --new-window";
        hooks.mail-recieved = ''notify-send "[$AERC_ACCOUNT/$AERC_FOLDER] mail from $AERC_FROM_NAME" "$AERC_SUBJECT"'';
        filters = {
          "text/plain" = "colorize";
          "text/calendar" = "calendar";
          "message/delivery-status" = "colorize";
          "message/rfc822" = "colorize";
          "text/html" = "html | colorize";
        };
      };
      extraBinds = import ./aerc-binds.nix;
    };
    neomutt = {
      enable = true;
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
        folders = {
          drafts = "Drafts";
          inbox = "Inbox";
          sent = "Sent";
          trash = "Bin";
        };
        imapnotify = {
          enable = true;
          boxes = [ "Inbox" ];
          onNotify = "${pkgs.isync}/bin/mbsync ryan@freumh.org && ${pkgs.mu}/bin/mu index && ${pkgs.procps}/bin/pkill -RTMIN+13 i3blocks";
        };
        mbsync = {
          enable = true;
          create = "both";
          expunge = "both";
          remove = "both";
        };
        msmtp = {
          enable = true;
        };
        aerc = {
          enable = true;
          extraAccounts = {
            check-mail-cmd = "${pkgs.isync}/bin/mbsync ryan@freumh.org && ${pkgs.mu}/bin/mu index && ${pkgs.procps}/bin/pkill -RTMIN+13 i3blocks";
            check-mail-timeout = "1m";
            check-mail = "1h";
            folders-sort = [ "Inbox" "Sent" "Drafts" "Archive" "Spam" "Trash" ];
            folder-map = "${pkgs.writeText "folder-map" ''
              Spam = Junk
              Bin = Trash
            ''}";
          };
        };
        neomutt = {
          enable = true;
        };
      };
      "misc@freumh.org" = {
        userName = "misc@freumh.org";
        address = "misc@freumh.org";
        realName = "Misc";
        passwordCommand = "${pkgs.pass}/bin/pass show email/misc@freumh.org";
        imap.host = "mail.freumh.org";
        smtp = {
          host = "mail.freumh.org";
          port = 465;
        };
        folders = {
          drafts = "Drafts";
          inbox = "Inbox";
          sent = "Sent";
          trash = "Bin";
        };
        imapnotify = {
          enable = true;
          boxes = [ "Inbox" ];
          onNotify = "${pkgs.isync}/bin/mbsync misc@freumh.org && ${pkgs.mu}/bin/mu index && ${pkgs.procps}/bin/pkill -RTMIN+13 i3blocks";
        };
        mbsync = {
          enable = true;
          create = "both";
          expunge = "both";
          remove = "both";
        };
        msmtp = {
          enable = true;
        };
        neomutt = {
          enable = true;
        };
      };
      "ryan.gibb@cl.cam.ac.uk" = {
        userName = "rtg24@fm.cl.cam.ac.uk";
        address = "ryan.gibb@cl.cam.ac.uk";
        realName = "Ryan Gibb";
        passwordCommand = "${pkgs.pass}/bin/pass show email/ryan.gibb@cl.cam.ac.uk";
        flavor = "fastmail.com";
        folders = {
          drafts = "Drafts";
          inbox = "Inbox";
          sent = "Sent";
          trash = "Trash";
        };
        imapnotify = {
          enable = true;
          boxes = [ "Inbox" ];
          onNotify = "${pkgs.isync}/bin/mbsync ryan.gibb@cl.cam.ac.uk && ${pkgs.mu}/bin/mu index && ${pkgs.procps}/bin/pkill -RTMIN+13 i3blocks";
        };
        mbsync = {
          enable = true;
          create = "both";
          expunge = "both";
          remove = "both";
        };
        msmtp = {
          enable = true;
        };
        aerc = {
          enable = true;
          extraAccounts = {
            check-mail-cmd = "${pkgs.isync}/bin/mbsync ryan.gibb@cl.cam.ac.uk && ${pkgs.mu}/bin/mu index && ${pkgs.procps}/bin/pkill -RTMIN+13 i3blocks";
            check-mail-timeout = "1m";
            check-mail = "1h";
            aliases = "rtg24@cam.ac.uk";
            folders-sort = [ "Inbox" "Sidebox" "Sent" "Drafts" "Archive" "Spam" "Trash" ];
            folder-map = "${pkgs.writeText "folder-map" ''
              Bin = Trash
            ''}";
          };
        };
        neomutt = {
          enable = true;
        };
      };
      "ryangibb321@gmail.com" = {
        userName = "ryangibb321@gmail.com";
        address = "ryangibb321@gmail.com";
        realName = "Ryan Gibb";
        passwordCommand = "${pkgs.pass}/bin/pass show email/ryangibb321@gmail.com";
        flavor = "gmail.com";
        folders = {
          drafts = "Drafts";
          inbox = "Inbox";
          sent = "Sent Mail";
          trash = "Bin";
        };
        imapnotify = {
          enable = true;
          boxes = [ "Inbox" ];
          onNotify = "${pkgs.isync}/bin/mbsync ryangibb321@gmail.com && ${pkgs.mu}/bin/mu index && ${pkgs.procps}/bin/pkill -RTMIN+13 i3blocks";
        };
        mbsync = {
          enable = true;
          create = "both";
          expunge = "both";
          remove = "both";
        };
        msmtp = {
          enable = true;
        };
        aerc = {
          enable = true;
          extraAccounts = {
            check-mail-cmd = "${pkgs.isync}/bin/mbsync ryangibb321@gmail.com && ${pkgs.mu}/bin/mu index && ${pkgs.procps}/bin/pkill -RTMIN+13 i3blocks";
            check-mail-timeout = "1m";
            check-mail = "1h";
            folders-sort = [ "Inbox" "Sidebox" "Sent" "Drafts" "Archive" "Spam" "Trash" ];
            folder-map = "${pkgs.writeText "folder-map" ''
              * = [Gmail]/*
              Sent = 'Sent Mail'
              Archive = 'All Mail'
            ''}";
          };
        };
        neomutt = {
          enable = true;
        };
      };
    };
  };
}
