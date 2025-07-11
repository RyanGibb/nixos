{
  pkgs,
  config,
  lib,
  ...
}:

let
  tmux-sessionizer = pkgs.writeScriptBin "tmux-sessionizer" ''
    #!/usr/bin/env bash

    hist_file=~/.cache/sessionizer.hist

    if [[ $# -eq 1 ]]; then
        selected=$1
    else
        selected=$((tac "$hist_file"
            find ~/ ~/projects -mindepth 1 -maxdepth 1 -type d -not -path '*/[.]*'
            awk '{print "ssh " $1}' ~/.ssh/known_hosts 2>/dev/null | sort -u
            echo /etc/nixos) | awk '!seen[$0]++' | fzf --print-query | tail -n 1)
    fi

    if [[ -z $selected ]]; then
        exit 0
    fi

    echo "$selected" >> $hist_file

    selected_name=$(basename "$selected" | tr . _)
    tmux_running=$(pgrep tmux)

    if [[ $selected == ssh\ * ]]; then
        if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
            tmux new-session -s "$selected_name" "$selected"
            exit 0
        fi

        if ! tmux has-session -t="$selected_name" 2> /dev/null; then
            tmux new-session -ds "$selected_name" "$selected"
        fi
    else
        if [[ -z $TMUX ]] && [[ -z "$tmux_running" ]]; then
            tmux new-session -s "$selected_name" -c "$selected"
            exit 0
        fi

        if ! tmux has-session -t="$selected_name" 2> /dev/null; then
            tmux new-session -ds "$selected_name" -c "$selected"
        fi
    fi


    tmux switch-client -t "$selected_name"
  '';
in
{
  imports = [
    ./mail.nix
    ./calendar.nix
    ./gui/default.nix
    ./nvim/default.nix
    ./emacs/default.nix
    ./battery.nix
  ];

  options.custom.machineColour = lib.mkOption {
    type = lib.types.str;
    default = "cyan";
  };

  config = {
    home.sessionVariables = {
      EDITOR = "nvim";
      NIX_AUTO_RUN = "y";
      NIX_AUTO_RUN_INTERACTIVE = "y";
      GOPATH = "$HOME/.go";
    };
    home.packages = with pkgs; [
      htop
      gnumake
      inetutils
      dig
      fzf
      jq
      bc
      openssh
      # multicore rust command line utils
      dua
      fd
      ripgrep
      tmux-sessionizer
      bfs
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
      nix-stray-roots = "nix-store --gc --print-roots | egrep -v '^(/nix/var|/run|/proc|{censored})'";
    };

    # https://github.com/nix-community/home-manager/issues/1439#issuecomment-1106208294
    home.activation = {
      linkDesktopApplications = {
        after = [
          "writeBoundary"
          "createXdgUserDirectories"
        ];
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
        size = 10000000000;
        path = "$HOME/.histfile";
        share = false;
      };
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      enableCompletion = true;
      initContent =
        let
          zshConfigEarlyInit = lib.mkOrder 500 ''
            export ZSH_AUTOSUGGEST_STRATEGY=(match_prev_cmd completion history)
            export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=5"
            PROMPT='%(?..%F{red}%3?%f )%F{${config.custom.machineColour}}%n@%m%f:%~ %#'$'\n'
          '';
          zshConfig = lib.mkOrder 1000 (builtins.readFile ./zsh.cfg);
        in
          lib.mkMerge [ zshConfigEarlyInit zshConfig ];
    };

    programs.bash.initExtra = ''
      PS1='\[\e[36m\]\u@\h:\W\[\e[0m\] $ '
    '';

    programs.gpg = {
      enable = true;
      publicKeys = [
        {
          text = ''
            -----BEGIN PGP PUBLIC KEY BLOCK-----

            mDMEZZ1zrBYJKwYBBAHaRw8BAQdA8Zeb1OFbzEWx3tM7ylO0ILCnDCG2JoA/iay6
            iWXmB7G0G1J5YW4gR2liYiA8cnlhbkBmcmV1bWgub3JnPoiUBBMWCgA8FiEE67lV
            Y2amyVrqUoWjGfnbY35Mq3QFAmWdc6wCGwMFCQPCZwAECwkIBwQVCgkIBRYCAwEA
            Ah4FAheAAAoJEBn522N+TKt0mwcA/AvuKD4dTPj4hJ/cezEWDOFELMaVYZqDS3V1
            LmRJrdIHAQDYgST8awabyd2Y3PRTFf9ZcWRRompeg0v7c2hCc9/3A7g4BGWdc6wS
            CisGAQQBl1UBBQEBB0AdJP8T3mGR7SUp9DBlIaVU1ESRC7sLWbm4QFCR1JTfSgMB
            CAeIfgQYFgoAJhYhBOu5VWNmpsla6lKFoxn522N+TKt0BQJlnXOsAhsMBQkDwmcA
            AAoJEBn522N+TKt07KwA/10R+ejRZeW0cYScowHAsnDZ09A43bZvdp1X7KeQHMl+
            AQD+TbceHh393VFc4tkl5pYHfrmkCXMdN0faVWolkc7GCA==
            =EfP/
            -----END PGP PUBLIC KEY BLOCK-----
          '';
          trust = "ultimate";
        }
      ];
    };
    services.gpg-agent.pinentry.package = pkgs.pinentry-qt;

    programs.git = {
      enable = true;
      extraConfig = {
        init = {
          defaultBranch = "main";
        };
        user = {
          email = "ryan@freumh.org";
          name = "Ryan Gibb";
          signingKey = "19F9DB637E4CAB74";
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
          lola = "log --graph --decorate --pretty=oneline --abbrev-commit --all";
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
      extraConfig =
        let
          toggle-status-bar = pkgs.writeScript "toggle-status-bar.sh" ''
            #!/usr/bin/env bash
            window_count=$(tmux list-windows | wc -l)
            if [ "$window_count" -ge "2" ]; then
                tmux set-option status on
            else
                tmux set-option status off
            fi
          '';
        in
        # https://github.com/ThePrimeagen/.dotfiles/blob/master/bin/.local/scripts/tmux-sessionizer
        ''
          # alternative modifier
          unbind C-b
          set-option -g prefix C-a
          bind-key C-a send-prefix
          set-window-option -g mode-keys vi
          set-option -g mouse on
          set-option -g set-titles on
          set-option -g set-titles-string "#T"
          bind-key t capture-pane -S -\; new-window '(tmux show-buffer; tmux delete-buffer) | nvim -c $'
          bind-key u capture-pane\; new-window '(tmux show-buffer; tmux delete-buffer) | ${pkgs.urlscan}/bin/urlscan'
          set-hook -g session-window-changed 'run-shell ${toggle-status-bar}'
          set-hook -g session-created 'run-shell ${toggle-status-bar}'
          # Fixes C-Up/Down in TUIs
          set-option default-terminal tmux
          # https://stackoverflow.com/questions/62182401/neovim-screen-lagging-when-switching-mode-from-insert-to-normal
          # locking
          set -s escape-time 0
          # for .zprofile display environment starting https://github.com/tmux/tmux/issues/3483
          set-option -g update-environment XDG_VTNR
          # Allow clipboard with OSC-52 work
          set -s set-clipboard on
          # toggle
          bind -r ^ last-window
          # vim copy
          bind -T copy-mode-vi v send-keys -X begin-selection
          bind -T copy-mode-vi y send-keys -X copy-selection-and-cancel
          # find
          bind-key -r f run-shell "tmux neww tmux-sessionizer"
          # reload
          bind-key r source-file ~/.config/tmux/tmux.conf
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
