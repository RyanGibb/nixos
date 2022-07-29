{ pkgs, config, ... }:

{
  user.shell = "${packageInfo.zsh}/bin/zsh";

  environment.packages = with pkgs; [
    neovim

    diffutils
    findutils
    utillinux
    tzdata
    hostname
    man
    gnugrep
    gnupg
    gnused
    gnutar
    bzip2
    gzip
    xz
    zip
    unzip

    which

    openssh
    iputils
    curl

    nix
    tree
    htop
    bind
    inetutils
    ncdu
    gnumake
    bat
    killall
    nmap
    gcc
    direnv
    fzf

    top
  ];

  environment.etcBackupExtension = ".bak";
  
  home-manager.config =
    { pkgs, lib, ... }:
    {
      # Use the same overlays as the system packages
      nixpkgs = { inherit (config.nixpkgs) overlays; };

      programs.zsh = {
        enable = true;
        history.size = 100000;
        enableAutosuggestions = true;
        enableSyntaxHighlighting = true;
        initExtraFirst = builtins.readFile ../common/zsh.cfg;
        initExtra = ''
          PROMPT='%(?..%F{red}%3?%f )%D{%I:%M:%S%p} %F{cyan}%n@%m%f:%F{cyan}%~%f%<<''${vcs_info_msg_0_}'" %#"$'\n'
          
          export ZSH_AUTOSUGGEST_STRATEGY=(match_prev_cmd completion history)
          export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=5"
        '';
      };

      programs.git = {
        enable = true;
        userEmail = "ryan@gibbr.org";
        userName = "Ryan Gibb";
        aliases = {
          s = "status";
          c = "commit";
          cm = "commit --message";
          ca = "commit --amend";
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
          pu = "push --set-upstream";
          pl = "pull";
          pr = "pull --rebase";
          acp = "!git add --all && git commit --message update && git push";
        };
      };

      programs.neovim = {
        enable = true;
        viAlias = true;
        vimAlias = true;
        extraConfig = builtins.readFile ../common/nvim.cfg;
        plugins = with pkgs.vimPlugins; [
          vimtex
          vim-auto-save
          vim-airline
          vim-airline-themes
          palenight-vim
          vim-nix
        ];
      };

      programs.tmux = {
        enable = true;
        extraConfig = ''
          set-option -g prefix `
          bind ` send-prefix
          set -g mouse on
          set-window-option -g mode-keys vi
          set -g lock-command vlock
          set -g lock-after-time 0 # Seconds; 0 = never
          bind L lock-session
        '';
      };

      home.file = {
        ".ssh/authorized_keys".source = ../common/authorized_keys;
      };
    };
  home-manager.useGlobalPkgs = true;
  system.stateVersion = "22.05";
}
