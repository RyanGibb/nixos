
{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    history.size = 100000;
    enableAutosuggestions = true;
    enableCompletion = true;
    enableSyntaxHighlighting = true;
    initExtra = builtins.readFile ./zsh.cfg;
  };

  programs.git = {
    enable = true;
    userEmail = "ryan@gibb.org";
    userName = "Ryan Gibb";
    aliases = {
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

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    extraConfig = builtins.readFile ./nvim.cfg;
    plugins = with pkgs.vimPlugins; [
      vimtex
      vim-auto-save
      vim-airline
      vim-airline-themes
      palenight-vim
      vim-nix
    ];
  };

  programs.tmux.enable = true;
}

