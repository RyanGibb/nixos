{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.dictation;
  whisper-cpp = pkgs.whisper-cpp;
  modelName = cfg.model;
  modelDir = "${config.home-manager.users.${config.custom.username}.home.homeDirectory}/.local/share/whisper-models";
  audioFile = "/tmp/dictation-recording.wav";
  dictation-toggle = pkgs.writeShellScript "dictation-toggle" ''
    PIDFILE="/tmp/dictation-record.pid"
    if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
      # Stop recording
      PID="$(cat "$PIDFILE")"
      kill "$PID"
      tail --pid="$PID" -f /dev/null
      rm -f "$PIDFILE"
      ${pkgs.libnotify}/bin/notify-send -t 2000 "Dictation" "Transcribing..."

      MODEL="${modelDir}/ggml-${modelName}.bin"
      text=$(${whisper-cpp}/bin/whisper-cli \
        --model "$MODEL" \
        --language ${cfg.language} \
        --threads ${toString cfg.threads} \
        --no-timestamps \
        --file "${audioFile}" \
        2>/dev/null \
      | sed 's/\[BLANK_AUDIO\]//g;s/^[[:space:]]*//;s/[[:space:]]*$//;s/[[:space:]]\+/ /g' \
      | tr -d '\n' \
      | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

      rm -f "${audioFile}"

      if [ -n "$text" ]; then
        if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
          ${pkgs.wtype}/bin/wtype -- "$text"
        else
          ${pkgs.xdotool}/bin/xdotool type --delay 0 -- "$text"
        fi
        ${pkgs.libnotify}/bin/notify-send -t 2000 "Dictation" "Done"
      else
        ${pkgs.libnotify}/bin/notify-send -t 2000 "Dictation" "No speech detected"
      fi
    else
      MODEL="${modelDir}/ggml-${modelName}.bin"
      if [ ! -f "$MODEL" ]; then
        ${pkgs.libnotify}/bin/notify-send -t 5000 "Dictation" "Model not found. Run: dictation-download-model"
        exit 1
      fi
      ${pkgs.libnotify}/bin/notify-send -t 2000 "Dictation" "Recording..."
      ${pkgs.ffmpeg}/bin/ffmpeg -y -f alsa -i default -ar 16000 -ac 1 "${audioFile}" </dev/null &
      echo $! > "$PIDFILE"
    fi
  '';
  dictation-download = pkgs.writeShellScript "dictation-download-model" ''
    mkdir -p "${modelDir}"
    ${whisper-cpp}/bin/whisper-cpp-download-ggml-model ${modelName}
    mv ggml-${modelName}.bin "${modelDir}/"
    echo "Model downloaded to ${modelDir}/ggml-${modelName}.bin"
  '';
in
{
  options.custom.dictation = {
    enable = lib.mkEnableOption "whisper-cpp dictation";
    model = lib.mkOption {
      type = lib.types.str;
      default = "base.en";
      description = "Whisper model to use (tiny.en, base.en, small.en, medium.en, large)";
    };
    language = lib.mkOption {
      type = lib.types.str;
      default = "en";
    };
    threads = lib.mkOption {
      type = lib.types.int;
      default = 8;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      whisper-cpp
      pkgs.xdotool
      pkgs.wtype
      pkgs.ffmpeg
      (pkgs.writeShellScriptBin "dictation-toggle" ''exec ${dictation-toggle}'')
      (pkgs.writeShellScriptBin "dictation-download-model" ''exec ${dictation-download}'')
    ];
  };
}
