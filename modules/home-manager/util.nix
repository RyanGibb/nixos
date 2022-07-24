{ pkgs, lib, ... }:

{
  listFilesInDir = src: lib.attrsets.mapAttrsToList (name: value: "${src}/${name}") (builtins.readDir src);
  inDirReplace = src: dst: replacements:
    let filenames = lib.attrsets.mapAttrsToList (name: value: "${name}") (builtins.readDir src); in
    let substitutedSource = file: { source = (pkgs.substituteAll ({src="/${src}/${file}"; isExecutable = true;} // replacements)); }; in
    let attrs = builtins.map (file: lib.attrsets.nameValuePair "${dst}/${file}" (substitutedSource file)) filenames; in
    builtins.listToAttrs attrs;
  concatFilesReplace = filenames: replacements:
    let fromStrings = lib.attrsets.mapAttrsToList (name: value: "@${name}@") replacements; in
    let toStrings =   lib.attrsets.mapAttrsToList (name: value: "${value}") replacements; in
    let fileToString = file: builtins.replaceStrings fromStrings toStrings (builtins.readFile file); in
    builtins.concatStringsSep "\n" (builtins.map fileToString filenames);
}