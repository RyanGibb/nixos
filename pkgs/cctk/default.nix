{
  stdenv,
  lib,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  patchelf,
  openssl,
}:

# Use techniques described in https://web.archive.org/web/20220904051329/https://tapesoftware.net/replace-symbol/
# Uses patchelf-raphi to do this

# Adapted from https://github.com/KenMacD/etc-nixos/blob/d3d28085586358a62b2bb4b427eb21aad05b5b23/dcc/default.nix

# Used https://github.com/NixOS/nixpkgs/pull/84926 as a template
# then converted to use autoPatchelfHook instead, and link with
# the dependencies from other pkgs.

let
  version = "4.8.0-494";

  unpacked = stdenv.mkDerivation rec {
    inherit version;
    pname = "dell-command-configure-unpacked";
  
    src = fetchurl {
      url =
        "https://dl.dell.com/FOLDER08911312M/1/command-configure_${version}.ubuntu20_amd64.tar.gz";
      # The CDN blocks the Curl user-agent, so set to blank instead.
      curlOpts = ''-A=""'';
      sha256 = "sha256-l5oHgDkFBF6llNsHufTmuDzjkhGmXHYXlOJ4hvZfRoE=";
    };

    dontBuild = true;
  
    nativeBuildInputs = [ dpkg ];
  
    unpackPhase = ''
      tar -xzf ${src}
      dpkg-deb -x command-configure_${version}.ubuntu20_amd64.deb command-configure
      dpkg-deb -x srvadmin-hapi_9.5.0_amd64.deb srvadmin-hapi
    '';

    installPhase = ''
      mkdir $out
      cp -r . $out
    '';
  };


  # Contains a fopen() wrapper for finding the firmware package
  wrapperLibName = "wrapper-lib.so";
  wrapperLib = stdenv.mkDerivation {
    pname = "dell-command-configure-unpacked-wrapper-lib";
    inherit version;

    src = ./.;

    dontUnpack = true;
    buildPhase = ''
      substitute ${./wrapper-lib.c} lib.c \
        --subst-var-by to "${unpacked}/srvadmin-hapi/opt/dell/srvadmin/etc/omreg.d/omreg-hapi.cfg"
      cc -fPIC -shared lib.c -o ${wrapperLibName}
    '';
    installPhase = ''
      mkdir -p $out/lib
      cp ${wrapperLibName} $out/lib/
    '';
  };

in stdenv.mkDerivation rec {
  inherit version;
  pname = "dell-command-configure";

  buildInputs = [ openssl stdenv.cc.cc.lib ];
  nativeBuildInputs = [ autoPatchelfHook ];
  dontConfigure = true;

  src = unpacked;

  installPhase = ''
    mkdir -p $out/bin $out/lib
    install -t $out/lib -m644 -v command-configure/opt/dell/dcc/libhapiintf.so
    install -t $out/lib -m644 -v command-configure/opt/dell/dcc/libsmbios_c.so.2
    install -t $out/bin -m755 -v command-configure/opt/dell/dcc/cctk
    install -t $out/bin -m755 -v srvadmin-hapi/opt/dell/srvadmin/sbin/dchcfg
    for lib in $(find srvadmin-hapi/opt/dell/srvadmin/lib64 -type l); do
        install -t $out/lib -m644 -v $lib
    done
  '';

  postFixup = ''
    echo fopen fopen_wrapper > fopen_name_map
    echo access access_wrapper > access_name_map
    ${patchelf}/bin/patchelf \
      --rename-dynamic-symbols fopen_name_map \
      --rename-dynamic-symbols access_name_map \
      --add-needed ${wrapperLibName} \
      --set-rpath ${lib.makeLibraryPath [ wrapperLib ]} \
      $out/lib/*
  '';

  meta = with lib; {
    description = "Configure BIOS settings on Dell laptops.";
    homepage =
      "https://www.dell.com/support/article/us/en/19/sln311302/dell-command-configure";
    # license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}
