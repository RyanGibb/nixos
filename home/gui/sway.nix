{
  pkgs,
  config,
  lib,
  ...
}@inputs:

let
  i3-workspace-history =
    inputs.i3-workspace-history.packages.${pkgs.stdenv.hostPlatform.system}.default;
  cfg = config.custom.gui.sway;
  wmCommon = import ./wm-config.nix {
    inherit pkgs lib i3-workspace-history;
  };
  scriptDir = null;
in
{
  options.custom.gui.sway = {
    enable = lib.mkEnableOption "sway";
    idle = lib.mkOption {
      type = lib.types.str;
      default = "lock";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      i3-workspace-history
      # https://todo.sr.ht/~scoopta/wofi/73
      (stdenv.mkDerivation {
        name = "xterm-compat";
        buildInputs = [ pkgs.bash ];
        dontUnpack = true;
        installPhase = ''
          mkdir -p $out/bin
          cat > $out/bin/xterm <<EOF
          #!/usr/bin/env bash
          exec \$TERMINAL "\$@"
          EOF
          chmod +x $out/bin/xterm
        '';
      })
      wl-kbptr
      wlrctl
    ];

    wayland.systemd.target = "wayland-session.target";

    systemd.user.targets.sway-session.Unit.Wants = [ "wayland-session.target" ];

    wayland.windowManager.sway = {
      systemd.enable = true;
      enable = true;
      package = null;
      config = {
        modifier = "Mod4";
        terminal = "alacritty -e tmux";
        menu = "wofi -i --show drun --allow-images -a";
        bars = [ ];
        fonts = wmCommon.fonts;
        colors = wmCommon.wmColors;
        gaps = wmCommon.gaps;
        window = wmCommon.window // {
          commands = wmCommon.windowCommands.sway;
        };
        floating = wmCommon.floating // {
          criteria = wmCommon.floatingCriteria.sway;
        };
        focus = wmCommon.focus;
        input = {
          "type:keyboard" = {
            xkb_layout = "gb";
            xkb_numlock = "enable";
          };
          "type:pointer" = {
            accel_profile = "flat";
            pointer_accel = "0";
          };
          "type:touchpad" = {
            tap = "enabled";
            natural_scroll = "enabled";
            dwt = "enabled";
            pointer_accel = "0.2";
            click_method = "clickfinger";
            scroll_factor = "0.5";
          };
        };
        # https://github.com/swaywm/sway/issues/8958
        # seat."seat0".hide_cursor = "when-typing enable";
        keybindings = lib.mkForce (
          (wmCommon.commonKeybindings scriptDir)
          // (wmCommon.mediaKeybindings true)
          // (wmCommon.swayKeybindings scriptDir)
        );
        modes = wmCommon.commonModes // (wmCommon.swayModes scriptDir);
        startup = wmCommon.commonStartup ++ (wmCommon.swayStartup cfg.idle scriptDir "wm-wall");
      };
      extraConfig = ''
        focus_on_window_activation smart
        bindswitch --reload --locked lid:on exec wm-lock-if-solo; exec wm-clamshell
        bindswitch --reload --locked lid:off exec wm-lock-if-solo; exec wm-clamshell
      '';
    };

    xdg.configFile = {
      "fusuma/config.yml".source = ./fusuma.yml;
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

    systemd.user.services = {
      i3-workspace-history = {
        Unit = {
          Description = "i3 workspace history tracker";
          PartOf = [ "sway-session.target" ];
          After = [ "sway-session.target" ];
        };
        Service = {
          ExecStart = "${i3-workspace-history}/bin/i3-workspace-history -sway";
          Restart = "on-failure";
        };
        Install.WantedBy = [ "sway-session.target" ];
      };
    };
  };
}
