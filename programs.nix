{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    config = {
      user = {
        email = "ryan@gibb.org";
        name = "Ryan Gibb";
      };
      alias = {
        s = "status";
        c = "commit";
       	cm = "commit --message";
       	ca = "commit --amend --no-edit";
       	cu = "commit --message update";
       	ci = "commit --message initial";
       	br = "branch";
       	co = "checkout";
       	df = "diff";
       	lg = "log -p";
       	lol = "log --graph --decorate --pretty=oneline --abbrev-commit";
       	lola = "log --graph --decorate --pretty=oneline --abbrev-commit --all";
       	ls = "ls-files";
       	a = "add";
       	aa = "add --all";
       	au = "add -u";
       	ap = "add --patch";
       	ps = "push";
       	pf = "push --force";
      };
    };
  };

  programs.zsh = {
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
      PROMPT='%(?..%F{red}%3?%f )%D{%I:%M:%S%p} %F{blue}%n@%m%f:%F{cyan}%~%f%<<''${vcs_info_msg_0_}'$'\n'" %# "
      # workaround for https://github.com/NixOS/nixpkgs/pull/161701
      export ZSH_AUTOSUGGEST_STRATEGY=(match_prev_cmd completion history)
    '';
    setOptions = [ "HIST_IGNORE_DUPS" "HIST_FCNTL_LOCK" ];
    interactiveShellInit = builtins.readFile ./zsh.cfg;
  };

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    configure = {
      customRC = builtins.readFile ./nvim.cfg;
      packages.myVimPackage = with pkgs.vimPlugins; {
        start = [
          vimtex
          vim-auto-save
          vim-airline
          vim-airline-themes
          palenight-vim
          vim-nix
        ];
        opt = [ ];
      };
    };
  };

  programs.tmux = {
    enable = true;
    extraConfig = ''
      set -g mouse on
      set-window-option -g mode-keys vi
    '';
  };
}

