{ config, pkgs, ... }:

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
        ci = "commit";
       	cm = "commit --message";
       	ca = "commit --amend";
       	cu = "commit --message update";
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
    '';
    interactiveShellInit = ''
      setopt autocd nomatch notify interactive_comments
      unsetopt beep extendedglob

      autoload -Uz compinit
      compinit

      bindkey -v
      autoload -Uz edit-command-line
      zle -N edit-command-line
      bindkey -M vicmd V edit-command-line

      ZSH_AUTOSUGGEST_STRATEGY=(match_prev_cmd completion history)

      autoload zmv

      # fix right prompt indent
      ZLE_RPROMPT_INDENT=0

      # load version control information
      autoload -Uz vcs_info
      precmd() { vcs_info }

      setopt PROMPT_SUBST

      zstyle ':vcs_info:*' enable git
      zstyle ':vcs_info:*' check-for-changes true
      zstyle ':vcs_info:*' unstagedstr '*'
      zstyle ':vcs_info:*' stagedstr '!'
      zstyle ':vcs_info:git*+set-message:*' hooks git-untracked
      zstyle ':vcs_info:git*' formats $' %F{green}%.32b%m%u%c%f'

      +vi-git-untracked() {
        if [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) == 'true' ]] && \
           git status --porcelain | grep -m 1 '^??' &>/dev/null
        then
          hook_com[misc]='?'
        fi
      }

      # set window title
      # https://wiki.archlinux.org/title/zsh#xterm_title
      autoload -Uz add-zsh-hook

      function xterm_title_precmd () {
              print -Pn -- '\e]2;zsh %n@%m:%~\a'
      }

      function xterm_title_preexec () {
              print -Pn -- '\e]2;zsh %n@%m:%~ %# ' && print -n -- "''$\{(q)1\}\a"
      }

      if [[ "$TERM" != "linux" ]]; then
              add-zsh-hook -Uz precmd xterm_title_precmd
              add-zsh-hook -Uz preexec xterm_title_preexec
      fi

      autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
      zle -N up-line-or-beginning-search
      zle -N down-line-or-beginning-search

      typeset -g -A key
      
      key[Shift-Tab]="''${terminfo[kcbt]}"
      key[Control-Left]="''${terminfo[kLFT5]}"
      key[Control-Right]="''${terminfo[kRIT5]}"
      key[Control-Backspace]="^H"
      key[Control-Delete]="''${terminfo[kDC5]}"
      key[Control-R]="^R"

      bindkey "''${key[Home]}"              beginning-of-line
      bindkey "''${key[End]}"               end-of-line
      bindkey "''${key[Insert]}"            overwrite-mode
      bindkey "''${key[Up]}"                up-line-or-beginning-search
      bindkey "''${key[Down]}"              down-line-or-beginning-search
      bindkey "''${key[PageUp]}"            beginning-of-buffer-or-history
      bindkey "''${key[PageDown]}"          end-of-buffer-or-history
      bindkey "''${key[Shift-Tab]}"         reverse-menu-complete
      bindkey "''${key[Control-Left]}"      backward-word
      bindkey "''${key[Control-Right]}"     forward-word
      bindkey "''${key[Control-Backspace]}" backward-kill-word
      bindkey "''${key[Control-Delete]}"    kill-word
      bindkey "''${key[Control-R]}"         history-incremental-search-backward
    '';
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    configure = {
      customRC = ''
        let g:palenight_color_overrides = {
        \    'black': { 'gui': '#282d38', "cterm": "0", "cterm16": "0" },
        \}
        colorscheme palenight
        hi Normal ctermbg=NONE


        let g:airline#extensions#tabline#enabled = 1
        let g:airline_theme='bubblegum'

        set number
        set relativenumber

        set mouse=a
        set clipboard=unnamedplus

        set shiftwidth=4

        set tabstop=4
        set softtabstop=4

        set spelllang=en
        set spellfile=$HOME/.config/vim/spell.en.utf-8.add

        let g:auto_save_events = ["InsertLeave", "TextChanged"]
        let g:auto_save_silent = 0
      '';
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

  programs.mosh.enable = true;
}

