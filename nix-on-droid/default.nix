{ pkgs, config, lib, ... }:

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
    dua
    fd
    gnumake
    bat
    killall
    nmap
    gcc
    fzf
    netcat
    gawk
  ];

  environment.etcBackupExtension = ".bak";

  # Tailscale nameserver https://github.com/nix-community/nix-on-droid/issues/2
  environment.etc."resolv.conf".text = lib.mkForce ''
    nameserver 100.100.100.100
    nameserver 1.1.1.1
    nameserver 8.8.8.8
  '';

  home-manager = {
    useGlobalPkgs = true;
    config = { pkgs, lib, ... }: {
      # Use the same overlays as the system packages
      nixpkgs = { inherit (config.nixpkgs) overlays; };

      nix = {
        package = pkgs.nix;
        settings.experimental-features = [ "nix-command" "flakes" ];
      };

      # https://github.com/nix-community/nix-on-droid/issues/185
      home.shellAliases = {
        sshd = let
          config = pkgs.writeText "sshd_config" ''
            HostKey /data/data/com.termux.nix/files/home/.ssh/id_ed25519
            Port 9022
          '';
        in "$(readlink $(whereis sshd)) -f ${config}";
        ping = "/android/system/bin/linker64 /android/system/bin/ping";
      };

      programs.zsh = {
        enable = true;
        history.size = 100000;
        enableAutosuggestions = true;
        syntaxHighlighting.enable = true;
        initExtraFirst = ''
          export ZSH_AUTOSUGGEST_STRATEGY=(match_prev_cmd completion history)
          export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=5"
          PROMPT='%(?..%F{red}%3?%f )%F{blue}%n@%m%f:%~ %#'$'\n'
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
          lola =
            "log --graph --decorate --pretty=oneline --abbrev-commit --all";
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
          #ocamlPackages.ocaml-lsp
          #ocamlPackages.ocamlformat
          marksman
          lua-language-server
          #pyright
          #black
          ltex-ls
        ];
        extraLuaConfig = builtins.readFile ../modules/personal/nvim/nvim.lua;
        # undo transparent background
        # + "colorscheme gruvbox";
        plugins = let
          obsidian-nvim = (pkgs.vimUtils.buildVimPlugin {
            pname = "obsidian.nvim";
            version = "2.6.0";
            src = pkgs.fetchFromGitHub {
              owner = "epwalsh";
              repo = "obsidian.nvim";
              rev = "v2.6.0";
              sha256 = "sha256-+w3XYoobuH17oinPfQxhrizbmQB5IbbulUK69674/Wg=";
            };
          });
          ltex-ls-nvim = (pkgs.vimUtils.buildVimPlugin {
            pname = "ltex-ls.nvim";
            version = "2.6.0";
            src = pkgs.fetchFromGitHub {
              owner = "vigoux";
              repo = "ltex-ls.nvim";
              rev = "c8139ea6b7f3d71adcff121e16ee8726037ffebd";
              sha256 = "sha256-jY3ALr6h88xnWN2QdKe3R0vvRcSNhFWDW56b2NvnTCs=";
            };
          });
        in with pkgs.vimPlugins; [
          gruvbox-nvim

          telescope-nvim
          telescope-fzf-native-nvim
          trouble-nvim

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
          cmp-cmdline
          cmp-spell
          luasnip
          nvim-cmp

          vimtex
          nvim-surround
          comment-nvim

          ltex-ls-nvim
          nvim-jdtls
          # TODO nvim-dap

          copilot-vim
        ];
      };

      programs.tmux = {
        enable = true;
        extraConfig = ''
          set-window-option -g mode-keys vi
          set-option -g mouse on
          set-option -g set-titles on
          set-option -g set-titles-string "#T"
          bind-key t capture-pane -S -\; new-window '(tmux show-buffer; tmux delete-buffer) | nvim -c $'
          bind-key u capture-pane\; new-window '(tmux show-buffer; tmux delete-buffer) | ${pkgs.urlview}/bin/urlview'
          # Fixes C-Up/Down in TUIs
          set-option default-terminal tmux
          # https://stackoverflow.com/questions/62182401/neovim-screen-lagging-when-switching-mode-from-insert-to-normal
          set -s escape-time 0
          set -g lock-command vlock
          set -g lock-after-time 0 # Seconds; 0 = never
          bind L lock-session
        '';
      };

      home.file = {
        ".ssh/authorized_keys".source = ../modules/personal/authorized_keys;
      };

      programs.ssh = {
        enable = true;
        extraConfig = ''
          User ryan
        '';
      };

      home.stateVersion = "22.05";
    };
  };
  system.stateVersion = "22.05";
}
