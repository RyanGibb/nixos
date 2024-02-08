{ pkgs, config, ... }:

{
  user.shell = "${pkgs.zsh}/bin/zsh";

  environment.packages = with pkgs; [
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
    fzf
  ];

  environment.etcBackupExtension = ".bak";
  
  home-manager = {
    useGlobalPkgs = true;
    config =
      { pkgs, lib, ... }:
      {
        # Use the same overlays as the system packages
        nixpkgs = { inherit (config.nixpkgs) overlays; };

        programs.zsh = {
          enable = true;
          history.size = 100000;
          enableAutosuggestions = true;
          enableSyntaxHighlighting = true;
          initExtraFirst = ''
            export ZSH_AUTOSUGGEST_STRATEGY=(match_prev_cmd completion history)
            export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=5"
            PROMPT='%(?..%F{red}%3?%f )%D{%I:%M:%S%p} %F{cyan}%n@%m%f:%F{cyan}%~%f%<<''${vcs_info_msg_0_}'" %#"$'\n'
          '';
          initExtra = builtins.readFile ../modules/personal/zsh.cfg + ''
            bindkey "^[[A" up-line-or-beginning-search
            bindkey "^[[B" down-line-or-beginning-search
          '';
        };

        programs.git = {
          enable = true;
          userEmail = "ryan@$freumh.org";
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
            l = "log";
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
          extraPackages = with pkgs; [
            ripgrep
            nixd
            alejandra
            # stop complaining when launching but a devshell is better
            ocamlPackages.ocaml-lsp
            ocamlPackages.ocamlformat
            marksman
            lua-language-server
            pyright
            black
          ];
          extraLuaConfig = builtins.readFile ../modules/personal/nvim/nvim.lua;
          plugins = 
            let obsidian-nvim =
              (pkgs.vimUtils.buildVimPlugin {
                pname = "obsidian.nvim";
                version = "2.6.0";
                src = pkgs.fetchFromGitHub {
                  owner = "epwalsh";
                  repo = "obsidian.nvim";
                  rev = "v2.6.0";
                  sha256 = "sha256-+w3XYoobuH17oinPfQxhrizbmQB5IbbulUK69674/Wg=";
                };
              });
            in with pkgs.vimPlugins; [
            vim-airline
            vim-airline-themes
            gruvbox-nvim

            telescope-nvim

            obsidian-nvim
            plenary-nvim
            pkgs.ripgrep

            {
              plugin = nvim-lspconfig;
              runtime = let
                ml-style = ''
                  setlocal expandtab
                  setlocal shiftwidth=2
                  setlocal tabstop=2
                  setlocal softtabstop=2
                '';
              in {
                "ftplugin/mail.vim".text = ''
                  let b:did_ftplugin = 1
                '';
                "ftplugin/nix.vim".text = ml-style;
                "ftplugin/ocaml.vim".text = ml-style;
                "after/ftplugin/markdown.vim".text = ''
                  set com-=fb:-
                  set com+=b:-
                  set formatoptions+=ro
                '';
              };
            }

            cmp-nvim-lsp
            cmp-nvim-lsp-signature-help
            cmp-path
            cmp-buffer
            cmp-spell
            nvim-cmp

            vimtex
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
          ".ssh/authorized_keys".source = ../modules/personal/authorized_keys;
        };

        home.stateVersion = "22.05";
      };
  };
  system.stateVersion = "22.05";
}
