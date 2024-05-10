{ pkgs, config, lib, ... }:

let
  obsidian-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = "obsidian.nvim";
    version = "2.6.0";
    src = pkgs.fetchFromGitHub {
      owner = "epwalsh";
      repo = "obsidian.nvim";
      rev = "v2.6.0";
      sha256 = "sha256-+w3XYoobuH17oinPfQxhrizbmQB5IbbulUK69674/Wg=";
    };
  };
  ltex-ls-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = "ltex-ls.nvim";
    version = "2.6.0";
    src = pkgs.fetchFromGitHub {
      owner = "vigoux";
      repo = "ltex-ls.nvim";
      rev = "c8139ea6b7f3d71adcff121e16ee8726037ffebd";
      sha256 = "sha256-jY3ALr6h88xnWN2QdKe3R0vvRcSNhFWDW56b2NvnTCs=";
    };
  };
  cmp-spell = pkgs.vimUtils.buildVimPlugin {
    pname = "cmp-spell";
    version = "2024-05-07";
    src = pkgs.fetchFromGitHub {
      owner = "f3fora";
      repo = "cmp-spell";
      rev = "694a4e50809d6d645c1ea29015dad0c293f019d6";
      sha256 = "Gf7HSocvHmTleVQytNYmmN+fFX7kl5sYHQSpUJc0CGI=";
    };
    meta.homepage = "https://github.com/f3fora/cmp-spell/";
  };
  cfg = config.custom;
in {
  options.custom.nvim-lsps = lib.mkEnableOption "nvim-lsps";

  config = {
    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      extraPackages = with pkgs;
        [ ripgrep nixd ] ++ lib.lists.optionals cfg.nvim-lsps [
          nixfmt
          # stop complaining when launching but a devshell is better
          ocamlPackages.ocaml-lsp
          ocamlPackages.ocamlformat
          lua-language-server
          pyright
          black
          ltex-ls
          jdt-language-server
          nodejs_18
          clang-tools
          typst-lsp
        ];
      extraLuaConfig = builtins.readFile ./nvim.lua;
      # undo transparent background
      # + "colorscheme gruvbox";
      plugins = with pkgs.vimPlugins; [
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
            # format-flowed
            "ftplugin/mail.vim".text = ''
              setlocal tw=72
              set formatoptions+=w
            '';
            "ftplugin/nix.vim".text = ml-style;
            "ftplugin/ocaml.vim".text = ml-style;
            "after/ftplugin/markdown.vim".text = ''
              set com-=fb:-
              set com+=b:-\ [\ ],b:-\ [x],b:-
              set formatoptions+=ro
            '';
            "ftplugin/java.lua".text = ''
              local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
              local workspace_dir = '~/.cache/jdt/' .. project_name
              require('jdtls').start_or_attach {
              	on_attach = On_attach,
              	capabilities = Capabilities,
                cmd = { 'jdt-language-server', '-data', workspace_dir, },
                root_dir = vim.fs.dirname(vim.fs.find({'gradlew', '.git', 'mvnw'}, { upward = true })[1]),
              }
            '';
          };
        }
        gruvbox-nvim

        telescope-nvim
        telescope-fzf-native-nvim
        trouble-nvim
        vim-fugitive

        obsidian-nvim
        plenary-nvim
        pkgs.ripgrep

        cmp-nvim-lsp
        cmp-nvim-lsp-signature-help
        cmp-path
        cmp-buffer
        cmp-cmdline
        cmp-spell
        luasnip
        nvim-cmp

        vimtex
        cmp-omni

        nvim-surround
        comment-nvim
        undotree

        ltex-ls-nvim
        nvim-jdtls
        # TODO nvim-dap

        copilot-vim

        {
          plugin = pkgs.notmuch;
          runtime = let
            notmuch-style = ''
              let g:notmuch_date_format = '%Y-%m-%d'
              let g:notmuch_datetime_format = '%Y-%m-%d %I:%M%p'
            '';
          in {
            "ftplugin/notmuch-folders.vim".text = notmuch-style;
            "ftplugin/notmuch-search.vim".text = notmuch-style;
            "ftplugin/notmuch-show.vim".text = notmuch-style;
            "ftplugin/notmuch-compose.vim".text = notmuch-style;
          };
        }
      ];
    };
  };
}
