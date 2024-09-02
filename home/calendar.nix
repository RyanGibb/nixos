{ pkgs, config, lib, ... }:

let cfg = config.custom.calendar;
in {
  options.custom.calendar.enable = lib.mkEnableOption "calendar";

  config = lib.mkIf cfg.enable {
    programs = {
      password-store.enable = true;
      gpg.enable = true;
      vdirsyncer.enable = true;
      khal = {
        enable = true;
        locale = {
          timeformat = "%I:%M%p";
          dateformat = "%y-%m-%d";
          longdateformat = "%Y-%m-%d";
          datetimeformat = "%y-%m-%d %I:%M%p";
          longdatetimeformat = "%Y-%m-%d %I:%M%p";
        };
        settings = {
          default.default_calendar = "ryan_freumh_org";
          keybindings.external_edit = "ctrl e";
          keybindings.save = "ctrl s";
        };
      };
    };

    services = { gpg-agent.enable = true; };

    accounts.calendar = {
      basePath = "calendar";
      accounts = {
        "ryan_freumh_org" = {
          khal = {
            enable = true;
            color = "white";
          };
          vdirsyncer = { enable = true; };
          remote = {
            type = "caldav";
            url =
              "https://cal.freumh.org/ryan/f497c073-d027-2aa5-1e58-cbec1bf5a8c7/";
            passwordCommand =
              [ "${pkgs.pass}/bin/pass" "show" "calendar/ryan@freumh.org" ];
            userName = "ryan";
          };
          local = {
            type = "filesystem";
            fileExt = ".ics";
          };
        };
        "srg" = {
          khal = {
            enable = true;
            color = "#CC3333";
          };
          vdirsyncer = { enable = true; };
          remote = {
            type = "http";
            url = "https://talks.cam.ac.uk/show/ics/8316.ics";
          };
          local = {
            type = "filesystem";
            fileExt = ".ics";
          };
        };
      };
    };
  };
}
