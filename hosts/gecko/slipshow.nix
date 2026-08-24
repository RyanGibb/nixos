{
  lib,
  ocamlPackages,
  fetchFromGitHub,
}:

let
  # linol 0.11 does not compile against yojson 3, and slipshow links it
  # alongside dream/ppx_deriving_yojson, so the whole closure must agree.
  ocamlPackages' = ocamlPackages.overrideScope (
    _: _: {
      inherit (ocamlPackages) yojson_2;
      yojson = ocamlPackages.yojson_2;
    }
  );
in
ocamlPackages'.buildDunePackage rec {
  pname = "slipshow";
  version = "0.12.0";

  src = fetchFromGitHub {
    owner = "panglesd";
    repo = "slipshow";
    tag = "v${version}";
    hash = "sha256-z/RL2+3ZRxy+4LKl7bRYip1u9+MqXIteKvdir9sub7U=";
  };

  # https://github.com/panglesd/slipshow/pull/273: the table of contents lists the
  # step that enters a slide under the previous slide's title. Drop once merged.
  patches = [ ./slipshow-toc-slide-grouping.patch ];

  postPatch = ''
    substituteInPlace ./src/version/slipshow_version.ml \
      --replace-fail '%%VERSION%%' '${version}'
  '';

  nativeBuildInputs = with ocamlPackages'; [
    js_of_ocaml
  ];

  buildInputs = with ocamlPackages'; [
    ansi
    astring
    base64
    bos
    cmdliner
    dream
    fmt
    fpath
    grace
    inotify
    js_of_ocaml-lwt
    linol
    linol-lwt
    logs
    lwt
    magic-mime
    ppx_blob
    ppx_deriving_yojson
    ppx_sexp_conv
    sexplib
  ];

  doCheck = false;

  meta = {
    description = "Engine for displaying slips, the next-gen version of slides";
    homepage = "https://slipshow.readthedocs.io/en/latest/index.html";
    license = lib.licenses.gpl3Only;
    mainProgram = "slipshow";
  };
}
