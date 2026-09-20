{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.voxtype;
  format = pkgs.formats.toml { };
  models = {
    "tiny.en".hash = "sha256-kh5M+Ghv3Zk9zQgaXaW2w2W/3hFi5ysI11rHUomSCx8=";
    "base.en".hash = "sha256-oDd5yG3zMjB19eeWyyzlAp8A7Ihp7uP9+4l6/jbG0AI=";
    "small.en".hash = "sha256-xhONbVjsyDIgl+D5h8MvG+i7ChhTKj+I9zTRu/nEHl0=";
    "medium.en".hash = "sha256-zDfpNHgzjsdwAoGnrDChASiSnrj0J92i6GX6qPbaQ1Y=";
    "base".hash = "sha256-YO1bw90U7qhWST0zQ0m0BXgt3K8AKNS130CINF+6Lv4=";
    "small".hash = "sha256-G+OpsgY4Z7k35k4ux0gzZKeZF+FX+pjF2UtcH//qmHs=";
    "medium".hash = "sha256-bBTVre5fhjlAN7Tk6LWfFnO2zuEOPPCxG72+55wVYgg=";
    "large-v3".hash = "sha256-ZNGCtEC5jVIDxPm9VBVE2ExgUZbE97hF36EfsjWU0eI=";
    "large-v3-turbo".hash = "sha256-H8cPd0046xaZk6w5Huo1fvR8iHV+9y7llDh5t+jivGk=";
  };
  modelFile = pkgs.fetchurl {
    url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-${cfg.model}.bin";
    inherit (models.${cfg.model}) hash;
  };
  # voxtype rejects a partial config, so start from the defaults it ships
  defaultSettings = builtins.fromTOML (
    builtins.readFile "${cfg.package}/share/voxtype/default-config.toml"
  );
  configFile = format.generate "voxtype-config.toml" (
    lib.foldl' lib.recursiveUpdate defaultSettings [
      {
        # push-to-talk comes from the compositor binding, not evdev
        hotkey.enabled = false;
        # nixpkgs builds voxtype-osd without a frontend, so it just crash-loops
        osd.enabled = false;
        whisper = {
          model = "${modelFile}";
          language = cfg.language;
          # trims the 30s window for short clips; ~7x faster on base.en, but
          # upstream warns it can send large-v3* into repetition loops
          context_window_optimization = true;
        }
        // lib.optionalAttrs (cfg.threads != null) { threads = cfg.threads; };
      }
      cfg.settings
    ]
  );
in
{
  options.custom.voxtype = {
    enable = lib.mkEnableOption "voxtype voice-to-text daemon";
    package = lib.mkPackageOption pkgs "voxtype" { };
    model = lib.mkOption {
      type = lib.types.enum (lib.attrNames models);
      default = "base.en";
      description = "whisper.cpp ggml model, fetched from HuggingFace at build time";
    };
    language = lib.mkOption {
      type = lib.types.str;
      default = "en";
      description = ''language code, or "auto" to detect'';
    };
    threads = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = "inference threads; null leaves voxtype's autodetect, which caps at 4";
    };
    settings = lib.mkOption {
      type = format.type;
      default = { };
      description = "merged over the generated ~/.config/voxtype/config.toml";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    home-manager.users.${config.custom.username} = {
      xdg.configFile."voxtype/config.toml".source = configFile;

      systemd.user.services.voxtype = {
        Unit = {
          Description = "voxtype voice-to-text daemon";
          PartOf = [ "graphical-session.target" ];
          After = [
            "graphical-session.target"
            "pipewire.service"
          ];
        };
        Service = {
          ExecStart = "${lib.getExe cfg.package} -q daemon";
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
