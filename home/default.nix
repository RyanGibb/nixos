{ pkgs, config, lib, ... }:

let cfg = config.custom;
in {
  imports = [ ./mail.nix ./gui.nix ./i3.nix ./sway.nix ./nvim/default.nix ];

  options.custom.machineColour = lib.mkOption {
    type = lib.types.str;
    default = "cyan";
  };

  config = {
    home.sessionVariables = {
      EDITOR = "nvim";
      NIX_AUTO_RUN = "y";
      NIX_AUTO_RUN_INTERACTIVE = "y";
      BROWSER = "firefox"; # urlview
      GOPATH = "$HOME/.go";
    };
    home.packages = with pkgs; [
      tree
      htop
      bind
      inetutils
      dua
      fd
      nix-prefetch-git
      gnumake
      vlock
      bat
      killall
      nmap
      gcc
      fzf
      tcpdump
      sshfs
      nix-tree
      #atuin
      git-crypt
      jq
      bc
      pandoc
      w3m
      ranger
      bluetuith
      powertop
      ripgrep
      toot
      iamb
    ];

    home.shellAliases = {
      ls = "ls -p --color=auto";
      pls = "sudo $(fc -ln -1)";
      o = "xdg-open";
      se = "sudoedit";
      su = "su -p";
      ssh = "TERM=xterm ssh";
      nix-shell = "nix-shell --command zsh";
      inhibit-lid = "systemd-inhibit --what=handle-lid-switch sleep 1d";
      tmux = "tmux -2";
      feh = "feh --scale-down --auto-zoom";
      nix-stray-roots =
        "nix-store --gc --print-roots | egrep -v '^(/nix/var|/run|/proc|{censored})'";
    };

    # https://github.com/nix-community/home-manager/issues/1439#issuecomment-1106208294
    home.activation = {
      linkDesktopApplications = {
        after = [ "writeBoundary" "createXdgUserDirectories" ];
        before = [ ];
        data = ''
          rm -rf ${config.xdg.dataHome}/"applications/home-manager"
          mkdir -p ${config.xdg.dataHome}/"applications/home-manager"
          cp -Lr ${config.home.homeDirectory}/.nix-profile/share/applications/* ${config.xdg.dataHome}/"applications/home-manager/"
        '';
      };
    };

    programs.zsh = {
      enable = true;
      history = {
        size = 1000000;
        path = "$HOME/.histfile";
        share = false;
      };
      enableAutosuggestions = true;
      syntaxHighlighting.enable = true;
      enableCompletion = true;
      initExtraFirst = ''
        export ZSH_AUTOSUGGEST_STRATEGY=(match_prev_cmd completion history)
        export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=5"
        PROMPT='%(?..%F{red}%3?%f )%F{${config.custom.machineColour}}%n@%m%f:%~ %#'$'\n'
      '';
      initExtra = builtins.readFile ./zsh.cfg;
    };

    programs.bash.initExtra = ''
      PS1='\[\e[36m\]\u@\h:\W\[\e[0m\] $ '
    '';

    programs.git = {
      enable = true;
      extraConfig = {
        init = { defaultBranch = "main"; };
        user = {
          email = "ryan@freumh.org";
          name = "Ryan Gibb";
        };
        alias = {
          s = "status";
          c = "commit";
          cm = "commit --message";
          ca = "commit --amend";
          cu = "commit --message update";
          ci = "commit --message initial";
          br = "branch";
          co = "checkout";
          df = "diff";
          l = "log";
          lg = "log -p";
          lol = "log --graph --decorate --pretty=oneline --abbrev-commit";
          lola =
            "log --graph --decorate --pretty=oneline --abbrev-commit --all";
          ls = "ls-files";
          a = "add";
          aa = "add --all";
          au = "add -u";
          ap = "add --patch";
          ai = "add -i";
          ps = "push";
          pf = "push --force";
          pu = "push --set-upstream";
          pl = "pull";
          pr = "pull --rebase";
          acp = "!git add --all && git commit --message update && git push";
          d = "diff";
          dc = "diff --cached";
        };
      };
    };

    programs.tmux = {
      enable = true;
      extraConfig = let
        toggle-status-bar = pkgs.writeScript "toggle-status-bar.sh" ''
          #!/usr/bin/env bash
          window_count=$(tmux list-windows | wc -l)
          if [ "$window_count" -ge "2" ]; then
              tmux set-option status on
          else
              tmux set-option status off
          fi
        '';
      in ''
        set-window-option -g mode-keys vi
        set-option -g mouse on
        set-option -g set-titles on
        set-option -g set-titles-string "#T"
        bind-key t capture-pane -S -\; new-window '(tmux show-buffer; tmux delete-buffer) | nvim -c $'
        bind-key u capture-pane\; new-window '(tmux show-buffer; tmux delete-buffer) | ${pkgs.urlview}/bin/urlview'
        set-hook -g session-window-changed 'run-shell ${toggle-status-bar}'
        set-hook -g session-created 'run-shell ${toggle-status-bar}'
        # Fixes C-Up/Down in TUIs
        set-option default-terminal tmux
        # https://stackoverflow.com/questions/62182401/neovim-screen-lagging-when-switching-mode-from-insert-to-normal
        # locking
        set -s escape-time 0
        set -g lock-command vlock
        set -g lock-after-time 0 # Seconds; 0 = never
        bind L lock-session
        # for .zprofile display environment starting https://github.com/tmux/tmux/issues/3483
        set-option -g update-environment XDG_VTNR
        # Allow clipboard with OSC-52 work
        set -s set-clipboard on
      '';
    };

    programs.less = {
      enable = true;
      keys = ''
        #line-edit
        \e[1;5D  word-left
        \e[1;5C  word-right
      '';
    };

    programs.go.goPath = "~/.go";

    home.stateVersion = "22.05";
  };
}

