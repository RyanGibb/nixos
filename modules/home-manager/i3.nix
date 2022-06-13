{ pkgs, lib, ... }:

{
  imports = [
    ./home.nix
  ];

  home.file = {
    ".xinitrc".text = ''
      export XDG_SESSION_TYPE=x11
      export GDK_BACKEND=x11
      export DESKTOP_SESSION=plasma
      exec i3
    '';
    ".zprofile".text = ''
      # Autostart at login on TTY 2
      if [ -z "''${DISPLAY}" ] && [ "''${XDG_VTNR}" -eq 2 ]; then
      	exec startx
      fi
    '';
  };

  xdg.configFile  =
    let entries = {
      "i3/config".text =
        let dir = ./dotfiles/wm/config; in
        let filenames = lib.attrsets.mapAttrsToList (name: value: "${dir}/${name}") (builtins.readDir dir); in
        builtins.concatStringsSep "\n" (builtins.map (builtins.readFile) filenames);
      "i3blocks".source = ./dotfiles/i3blocks;
      "rofi/config.rasi".source = ./dotfiles/rofi.rasi;
    }; in
    let dir = ./dotfiles/wm/scripts; in
    let filenames = lib.attrsets.mapAttrsToList (name: value: "${name}") (builtins.readDir dir); in
    let replacements = {
      wmmsg = "i3msg";
    }; in
    let substitutedSource = file: { source = (pkgs.substituteAll ({src=/${dir}/${file}; isExecutable = true;} // replacements)); }; in
    let attrs = builtins.map (file: lib.attrsets.nameValuePair "i3/scripts/${file}" (substitutedSource file)) filenames; in
    builtins.listToAttrs attrs // entries;
}
