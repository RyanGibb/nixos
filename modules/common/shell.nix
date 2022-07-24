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
    promptInit = ''
      PROMPT='%(?..%F{red}%3?%f )%D{%I:%M:%S%p} %F{${config.machineColour}}%n@%m%f:%F{cyan}%~%f%<<''${vcs_info_msg_0_}'" %#"$'\n'
      # workaround for https://github.com/NixOS/nixpkgs/pull/161701
      export ZSH_AUTOSUGGEST_STRATEGY=(match_prev_cmd completion history)
    '';
    setOptions = [ "HIST_IGNORE_DUPS" "HIST_FCNTL_LOCK" ];
    interactiveShellInit = builtins.readFile ./zsh.cfg;
  };
}
