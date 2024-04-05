{ config, lib, ... }:

let cfg = config.personal;
in {
  options.personal.machineColour = lib.mkOption {
    type = lib.types.str;
    default = "cyan";
  };

  config = lib.mkIf cfg.enable {
    programs.zsh = {
      enable = true;
      histSize = 100000;
      autosuggestions = {
        enable = true;
        highlightStyle = "fg=5";
      };
      syntaxHighlighting = { enable = true; };
      autosuggestions.strategy = [ "match_prev_cmd" "completion" "history" ];
      promptInit = ''
        PROMPT='%(?..%F{red}%3?%f )%F{${config.personal.machineColour}}%n@%m%f:%~ %#'$'\n'
      '';
      setOptions = [ "HIST_IGNORE_DUPS" "HIST_FCNTL_LOCK" ];
      interactiveShellInit = builtins.readFile ./zsh.cfg;
    };
    programs.bash.promptInit = ''
      PS1='\[\e[36m\]\u@\h:\W\[\e[0m\] $ '
    '';
  };
}
