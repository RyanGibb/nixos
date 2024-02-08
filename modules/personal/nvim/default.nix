{ pkgs, config, lib, ... }:

let cfg = config.personal; in
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
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
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
    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
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
      configure = {
        customRC = "luafile ${./nvim.lua}";
        packages.myVimPackage = with pkgs.vimPlugins; {
          start = [
            vim-airline
            vim-airline-themes
            gruvbox-nvim

            telescope-nvim

            obsidian-nvim
            plenary-nvim
            pkgs.ripgrep

            nvim-lspconfig

            cmp-nvim-lsp
            cmp-nvim-lsp-signature-help
            cmp-path
            cmp-buffer
            cmp-spell
            nvim-cmp

            indent-blankline-nvim

            vimtex
          ];
          opt = [ ];
        };
      };
    };
  };
}
