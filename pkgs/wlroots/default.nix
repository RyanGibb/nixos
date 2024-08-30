{ lib, stdenv, fetchFromGitLab, fetchpatch, meson, ninja, pkg-config
, wayland-scanner, libGL, wayland, wayland-protocols, libinput, libxkbcommon
, pixman, libcap, mesa, xorg, libpng, ffmpeg_4, ffmpeg, hwdata, seatd
, vulkan-loader, glslang, libliftoff, libdisplay-info, nixosTests

, enableXWayland ? true, xwayland ? null }:

stdenv.mkDerivation (finalAttrs: rec {
  pname = "wlroots";
  version = "0.18.0";

  inherit enableXWayland;

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "wlroots";
    repo = "wlroots";
    rev = "b80337a8f2bb5d032f533ed5e0feb6292670528f";
    hash = "sha256-EOkgmjRe4v7HtHjJRFplxPZRUzC9N8KgU72BU2JKqKo=";
  };

  # $out for the library and $examples for the example programs (in examples):
  outputs = [ "out" "examples" ];

  strictDeps = true;
  depsBuildBuild = [ pkg-config ];

  nativeBuildInputs = [ meson ninja pkg-config wayland-scanner glslang ];

  buildInputs = [
    libGL
    libcap
    libinput
    libpng
    libxkbcommon
    mesa
    pixman
    seatd
    vulkan-loader
    wayland
    wayland-protocols
    xorg.libX11
    xorg.xcbutilerrors
    xorg.xcbutilimage
    xorg.xcbutilrenderutil
    xorg.xcbutilwm
    ffmpeg
    hwdata
    libliftoff
    libdisplay-info
  ] ++ lib.optional finalAttrs.enableXWayland xwayland;

  mesonFlags = lib.optional (!finalAttrs.enableXWayland) "-Dxwayland=disabled";

  postFixup = ''
    # Install ALL example programs to $examples:
    # screencopy dmabuf-capture input-inhibitor layer-shell idle-inhibit idle
    # screenshot output-layout multi-pointer rotation tablet touch pointer
    # simple
    mkdir -p $examples/bin
    cd ./examples
    for binary in $(find . -executable -type f -printf '%P\n' | grep -vE '\.so'); do
      cp "$binary" "$examples/bin/wlroots-$binary"
    done
  '';

  # Test via TinyWL (the "minimum viable product" Wayland compositor based on wlroots):
  passthru.tests.tinywl = nixosTests.tinywl;

  meta = {
    description = "A modular Wayland compositor library";
    longDescription = ''
      Pluggable, composable, unopinionated modules for building a Wayland
      compositor; or about 50,000 lines of code you were going to write anyway.
    '';
    inherit (finalAttrs.src.meta) homepage;
    changelog =
      "https://gitlab.freedesktop.org/wlroots/wlroots/-/tags/${version}";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ primeos synthetica rewine ];
  };
})
