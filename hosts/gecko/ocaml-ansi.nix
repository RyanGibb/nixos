{
  lib,
  buildDunePackage,
  fetchurl,
  astring,
  fmt,
  tyxml,
}:

buildDunePackage rec {
  pname = "ansi";
  version = "0.7.0";

  minimalOCamlVersion = "4.10";

  src = fetchurl {
    url = "https://github.com/ocurrent/ansi/releases/download/${version}/ansi-${version}.tbz";
    hash = "sha256-ZytqEx7rx9EpGkrZrUQUqJ4lHhgeZ+g7TskMtXjkqKQ=";
  };

  propagatedBuildInputs = [
    astring
    fmt
    tyxml
  ];

  meta = {
    description = "ANSI escape sequence parser";
    homepage = "https://github.com/ocurrent/ansi";
    license = lib.licenses.asl20;
  };
}
