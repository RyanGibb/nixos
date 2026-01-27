{ pkgs, lib, ... }:

{
  listFilesInDir =
    src: lib.attrsets.mapAttrsToList (name: value: "${src}/${name}") (builtins.readDir src);
  inDirReplace =
    src: dst: replacements:
    lib.pipe src [
      # get filenames in src directory
      builtins.readDir
      (lib.attrsets.mapAttrsToList (name: value: "${name}"))
      # call `substituteAll` on all files
      (
        let
          substitutedSource =
            file:
            let
              fileContent = builtins.readFile "/${src}/${file}";
              # Filter replacements to only those that appear in the file
              usedReplacements = lib.filterAttrs (
                name: value: builtins.match ".*@${name}@.*" fileContent != null
              ) replacements;
            in
            {
              source = pkgs.writeScript (builtins.baseNameOf file) (
                lib.fold (
                  name: acc: builtins.replaceStrings [ "@${name}@" ] [ replacements.${name} ] acc
                ) fileContent (builtins.attrNames usedReplacements)
              );
            };
        in
        builtins.map (file: lib.attrsets.nameValuePair "${dst}/${file}" (substitutedSource file))
      )
      builtins.listToAttrs
    ];
  concatFilesReplace =
    filenames: replacements:
    let
      fromStrings = lib.attrsets.mapAttrsToList (name: value: "@${name}@") replacements;
    in
    let
      toStrings = lib.attrsets.mapAttrsToList (name: value: "${value}") replacements;
    in
    let
      fileToString = file: builtins.replaceStrings fromStrings toStrings (builtins.readFile file);
    in
    builtins.concatStringsSep "\n" (builtins.map fileToString filenames);
}
