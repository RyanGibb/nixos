{ lib, stdenv, fetchFromGitHub, apacheHttpd, openssl }:

stdenv.mkDerivation rec {
  pname = "mod_ucam_webauth";
  version = "2.0.5";

  src = fetchFromGitHub {
    owner = "cambridgeuniversity";
    repo = "mod_ucam_webauth";
    rev = "6a246d5299171713c8680ef37c6ea6545bac948a";
    hash = "sha256-NbwHRy0SYXvpVBzJGhgI3IAAY+uVr9yRvFfMACKK4MU=";
  };

  buildInputs = [ openssl.dev ];

  buildPhase = ''
    make APXS=${apacheHttpd.dev}/bin/apxs
  '';

  installPhase = ''
    mkdir -p $out/modules/
    cp ./.libs/mod_ucam_webauth.so $out/modules/
  '';
}
