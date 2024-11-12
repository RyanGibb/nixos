{ pkgs, config, lib, ... }:

let
  address-book = pkgs.writeScriptBin "address-book" ''
    #!/usr/bin/env bash
    ${pkgs.mu}/bin/mu cfind "$1" | sed -E 's/(.*) (.*@.*)/\2\t\1/'
    ${pkgs.ugrep}/bin/ugrep -jPh -m 100 --color=never "$1" cat ${config.accounts.email.maildirBasePath}/addressbook/cam-ldap)
  '';
  sync-mail = pkgs.writeScriptBin "sync-mail" ''
    #!/usr/bin/env bash
    ${pkgs.isync}/bin/mbsync "$1" || exit 1
    ${pkgs.procps}/bin/pkill -2 -x mu
    sleep 1
    ${pkgs.mu}/bin/mu index
  '';
  cfg = config.custom.mail;
in {
  options.custom.mail.enable = lib.mkEnableOption "mail";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      (pkgs.writeScriptBin "cam-ldap-addr" ''
        ${pkgs.openldap}/bin/ldapsearch -xZ -H ldaps://ldap.lookup.cam.ac.uk -b "ou=people,o=University of Cambridge,dc=cam,dc=ac,dc=uk" displayName mail\
        | ${pkgs.gawk}/bin/awk '/^dn:/{displayName=""; mail=""; next} /^displayName:/{displayName=$2; for(i=3;i<=NF;i++) displayName=displayName " " $i; next} /^mail:/{mail=$2; next} /^$/{if(displayName!="" && mail!="") print mail "\t" displayName}'\
        > ${config.accounts.email.maildirBasePath}/addressbook/cam-ldap
      '')
      address-book
      sync-mail
    ];

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
          compose.file-picker-cmd =
            "${pkgs.ranger}/bin/ranger --choosefiles=%f";
          compose.format-flowed = true;
          ui.index-columns = "date<=,name<50,flags>=,subject<*";
          ui.column-name = "{{index (.From | persons) 0}}";
          "ui:folder=Sent".index-columns = "date<=,to<50,flags>=,subject<*";
          "ui:folder=Sent".column-to = "{{index (.To | persons) 0}}";
          openers."text/html" = "firefox --new-window";
          hooks.mail-recieved = ''
            notify-send "[$AERC_ACCOUNT/$AERC_FOLDER] mail from $AERC_FROM_NAME" "$AERC_SUBJECT"'';
          filters = {
            "text/plain" = "wrap -w 90 | colorize";
            "text/calendar" = "calendar";
            "application/ics" = "calendar";
            "message/delivery-status" = "colorize";
            "message/rfc822" = "colorize";
            "text/html" = "html | colorize";
          };
        };
        extraBinds = import ./aerc-binds.nix { inherit pkgs; };
      };
      neomutt = {
        enable = true;
        extraConfig = ''
          # Macro to switch accounts
          macro index,pager <F1> '"<change-folder> ${config.accounts.email.maildirBasePath}/ryan@freumh.org/Inbox<enter>"'
          macro index,pager <F2> '"<change-folder> ${config.accounts.email.maildirBasePath}/ryangibb321@gmail.com/Inbox<enter>"'
          macro index,pager <F3> '"<change-folder> ${config.accounts.email.maildirBasePath}/ryan.gibb@cl.cam.ac.uk/Inbox<enter>"'

          # mutt macros for mu
          macro index <F8> "<shell-escape>mu find --clearlinks --format=links --linksdir=${config.accounts.email.maildirBasePath}/search " \
                                   "mu find"
          macro index <F9> "<change-folder-readonly>˜/Maildir/search" \
                                         "mu find results"
        '';
      };
      notmuch.enable = true;
    };

    services = {
      imapnotify.enable = true;
      gpg-agent.enable = true;
    };

    accounts.email = {
      maildirBasePath = "mail";
      order = [ "ryangibb321@gmail.com" "ryan.gibb@cl.cam.ac.uk" ];
      accounts = {
        "ryan@freumh.org" = rec {
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
            trash = "Trash";
          };
          imapnotify = {
            enable = true;
            boxes = [ "Inbox" ];
            onNotify = "${sync-mail}/bin/mbsync ryan@freumh.org";
          };
          mbsync = {
            enable = true;
            create = "both";
            expunge = "both";
            remove = "both";
          };
          msmtp = { enable = true; };
          aerc = {
            enable = true;
            extraAccounts = {
              check-mail-cmd = "${sync-mail}/bin/mbsync ryan@freumh.org";
              check-mail-timeout = "1m";
              check-mail = "1h";
              folders-sort =
                [ "Inbox" "Sent" "Drafts" "Archive" "Spam" "Trash" ];
              folder-map = "${pkgs.writeText "folder-map" ''
                Spam = Junk
                Bin = Trash
              ''}";
            };
          };
          neomutt = {
            enable = true;
            extraConfig = ''
              bind index g noop
              macro index gi "<change-folder>=${folders.inbox}<enter>"
              macro index gs "<change-folder>=${folders.sent}<enter>"
              macro index gd "<change-folder>=${folders.drafts}<enter>"
              macro index gt "<change-folder>=${folders.trash}<enter>"
            '';
          };
          notmuch.enable = true;
        };
        "misc@freumh.org" = rec {
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
            onNotify = "${sync-mail}/bin/mbsync misc@freumh.org";
          };
          mbsync = {
            enable = true;
            create = "both";
            expunge = "both";
            remove = "both";
          };
          msmtp = { enable = true; };
          neomutt = {
            enable = true;
            extraConfig = ''
              bind index g noop
              macro index gi "<change-folder>=${folders.inbox}<enter>"
              macro index gs "<change-folder>=${folders.sent}<enter>"
              macro index gd "<change-folder>=${folders.drafts}<enter>"
              macro index gt "<change-folder>=${folders.trash}<enter>"
            '';
          };
          notmuch.enable = true;
        };
        "ryan.gibb@cl.cam.ac.uk" = rec {
          userName = "rtg24@fm.cl.cam.ac.uk";
          address = "ryan.gibb@cl.cam.ac.uk";
          realName = "Ryan Gibb";
          passwordCommand =
            "${pkgs.pass}/bin/pass show email/ryan.gibb@cl.cam.ac.uk";
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
            onNotify = "${sync-mail}/bin/mbsync ryan.gibb@cl.cam.ac.uk";
          };
          mbsync = {
            enable = true;
            create = "both";
            expunge = "both";
            remove = "both";
          };
          msmtp = { enable = true; };
          aerc = {
            enable = true;
            extraAccounts = {
              check-mail-cmd = "${sync-mail}/bin/mbsync ryan.gibb@cl.cam.ac.uk";
              check-mail-timeout = "1m";
              check-mail = "1h";
              aliases = "rtg24@cam.ac.uk";
              folders-sort =
                [ "Inbox" "Sidebox" "Sent" "Drafts" "Archive" "Spam" "Trash" ];
              folder-map = "${pkgs.writeText "folder-map" ''
                Bin = Trash
              ''}";
            };
          };
          neomutt = {
            enable = true;
            extraConfig = ''
              bind index g noop
              macro index gi "<change-folder>=${folders.inbox}<enter>"
              macro index gs "<change-folder>=${folders.sent}<enter>"
              macro index gd "<change-folder>=${folders.drafts}<enter>"
              macro index gt "<change-folder>=${folders.trash}<enter>"
            '';
          };
          notmuch.enable = true;
        };
        "ryangibb321@gmail.com" = rec {
          userName = "ryangibb321@gmail.com";
          address = "ryangibb321@gmail.com";
          realName = "Ryan Gibb";
          passwordCommand =
            "${pkgs.pass}/bin/pass show email/ryangibb321@gmail.com";
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
            onNotify = "${sync-mail}/bin/mbsync ryangibb321@gmail.com";
          };
          mbsync = {
            enable = true;
            create = "both";
            expunge = "both";
            remove = "both";
          };
          msmtp = { enable = true; };
          aerc = {
            enable = true;
            extraAccounts = {
              check-mail-cmd = "${sync-mail}/bin/mbsync ryangibb321@gmail.com";
              check-mail-timeout = "1m";
              check-mail = "1h";
              folders-sort = [
                "Inbox"
                "Sidebox"
                "[Gmail]/Sent Mail"
                "[Gmail]/Drafts"
                "[Gmail]/All Mail"
                "[Gmail]/Spam"
                "[Gmail]/Trash"
              ];
              copy-to = "'[Gmail]/Sent Mail'";
              archive = "'[Gmail]/All Mail'";
              postpone = "[Gmail]/Drafts";
            };
          };
          neomutt = {
            enable = true;
            extraConfig = ''
              bind index g noop
              macro index gi "<change-folder>=${folders.inbox}<enter>"
              macro index gs "<change-folder>=${folders.sent}<enter>"
              macro index gd "<change-folder>=${folders.drafts}<enter>"
              macro index gt "<change-folder>=${folders.trash}<enter>"
            '';
          };
          notmuch.enable = true;
        };
        search = {
          maildir.path = "search";
          realName = "Search Index";
          address = "search@local";
          aerc.enable = true;
          aerc.extraAccounts = {
            source = "maildir://~/mail/search";
          };
          aerc.extraConfig = {
            ui = {
              index-columns = "flags>4,date<*,to<30,name<30,subject<*";
              column-to = "{{(index .To 0).Address}}";
            };
          };
        };
      };
    };
  };
}
