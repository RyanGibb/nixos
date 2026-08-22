{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.custom.gui.niri;
  scriptDir = "$HOME/.config/niri/scripts";
in
{
  options.custom.gui.niri = {
    enable = lib.mkEnableOption "niri";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      wl-clipboard
      clipman
      wtype
      wl-kbptr
      wlrctl
      xwayland-satellite
    ];

    xdg.configFile."niri/scripts/workspace_notifier.sh" = {
      source = ./niri-scripts/workspace_notifier.sh;
      executable = true;
    };

    xdg.configFile."wlr-which-key/system.yaml".source = ./wlr-which-key/system.yaml;
    xdg.configFile."wlr-which-key/capture.yaml".source = ./wlr-which-key/capture.yaml;
    xdg.configFile."wlr-which-key/control.yaml".source = ./wlr-which-key/control.yaml;
    xdg.configFile."wlr-which-key/idle.yaml".source = ./wlr-which-key/idle.yaml;
    xdg.configFile."wlr-which-key/mouse.yaml".source = ./wlr-which-key/mouse.yaml;

    xdg.configFile."niri/config.kdl".source = ./niri/config.kdl;

    services = {
      gammastep = {
        enable = true;
        provider = "geoclue2";
        temperature.day = 6500;
      };
      playerctld.enable = true;
      dunst.enable = true;
      kanshi.enable = true;
      clipman.enable = true;
    };

    systemd.user.services.gammastep.Service.ExecStart =
      lib.mkForce "${pkgs.gammastep}/bin/gammastep -r";

    systemd.user.services.clipman.Service.ExecStart =
      lib.mkForce "${pkgs.wl-clipboard}/bin/wl-paste -t text --watch ${pkgs.clipman}/bin/clipman store --max-items=1000";

    systemd.user.services.dunst.Service.Type = lib.mkForce "simple";

    systemd.user.services.niri-workspace-notifier = {
      Unit = {
        Description = "Fire st workspace notification on niri workspace change";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "%h/.config/niri/scripts/workspace_notifier.sh";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    xdg.configFile = {
      "kanshi/config".source = ./kanshi;
      "dunst/dunstrc".source = ./dunst;
      "swaylock/config".source = ./swaylock;
      "wofi/style.css".source = ./wofi.css;
      "swappy/config".text = ''
        [Default]
        save_dir=$XDG_PICTURES_DIR/capture/
        save_filename_format=screenshot_%Y-%m-%dT%H:%M:%S%z.png
      '';
    };
  };
}
