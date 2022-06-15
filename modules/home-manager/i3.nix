{ pkgs, lib, ... }:

let replacements = {
  wm = "i3";
  wmmsg = "i3msg";
  rofi = "rofi";
  polkit_gnome = "${pkgs.polkit_gnome}";
  wallpaper = ''
  '';
}; in
let util = import ./util.nix { pkgs = pkgs; lib = lib; }; in
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
        let src = ./dotfiles/wm/config.d; in
        let filenames = lib.attrsets.mapAttrsToList (name: value: "${src}/${name}") (builtins.readDir src); in
        (util.concatFilesReplace ([ ./dotfiles/wm/config ] ++ filenames) replacements);
      "i3blocks".source = ./dotfiles/i3blocks;
      "rofi/config.rasi".source = ./dotfiles/rofi.rasi;
    }; in
    (util.inDirReplace ./dotfiles/wm/scripts "i3/scripts" replacements) // entries;
}
