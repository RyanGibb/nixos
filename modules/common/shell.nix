{ lib, config, ... }:

{
  options.machineColour = lib.mkOption {
    type = lib.types.str;
    default = "cyan";
  };
  
  config.programs.zsh = {
    enable = true;
    histSize = 100000;
    autosuggestions = {
      enable = true;
      highlightStyle = "fg=5";
    };
    syntaxHighlighting = {
      enable = true;
    };
    autosuggestions.strategy = [ "match_prev_cmd" "completion" "history" ];
    promptInit = ''
      PROMPT='%(?..%F{red}%3?%f )%D{%I:%M:%S%p} %F{${config.machineColour}}%n@%m%f:%F{cyan}%~%f%<<''${vcs_info_msg_0_}'" %#"$'\n'
    '';
    setOptions = [ "HIST_IGNORE_DUPS" "HIST_FCNTL_LOCK" ];
    interactiveShellInit = builtins.readFile ./zsh.cfg;
  };
}
