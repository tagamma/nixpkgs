{ lib, stdenv, fetchFromGitHub, substituteAll, jam, cctools, pkg-config
, SDL, SDL_mixer, SDL_sound, gtk2, libvorbis, smpeg }:

let

  jamenv = ''
    unset AR
  '' + (if stdenv.isDarwin then ''
    export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -I${lib.getDev SDL}/include/SDL"
    export GARGLKINI="$out/Applications/Gargoyle.app/Contents/Resources/garglk.ini"
  '' else ''
    export NIX_LDFLAGS="$NIX_LDFLAGS -rpath $out/libexec/gargoyle"
    export DESTDIR="$out"
    export _BINDIR=libexec/gargoyle
    export _APPDIR=libexec/gargoyle
    export _LIBDIR=libexec/gargoyle
    export GARGLKINI="$out/etc/garglk.ini"
  '');

in

stdenv.mkDerivation rec {
  pname = "gargoyle";
  version = "2019.1.1";

  src = fetchFromGitHub {
    owner = "garglk";
    repo = "garglk";
    rev = version;
    sha256 = "0w54avmbp4i4zps2rb4acmpa641s6wvwbrln4vbdhcz97fx48nzz";
  };

  nativeBuildInputs = [ jam pkg-config ] ++ lib.optional stdenv.isDarwin cctools;

  buildInputs = [ SDL SDL_mixer SDL_sound gtk2 ]
    ++ lib.optionals stdenv.isDarwin [ smpeg libvorbis ];

  buildPhase = jamenv + "jam -j$NIX_BUILD_CORES";

  installPhase =
  if stdenv.isDarwin then
  (substituteAll {
    inherit (stdenv) shell;
    isExecutable = true;
    src = ./darwin.sh;
  })
  else jamenv + ''
    jam -j$NIX_BUILD_CORES install
    mkdir -p "$out/bin"
    ln -s ../libexec/gargoyle/gargoyle "$out/bin"
    mkdir -p "$out/etc"
    cp garglk/garglk.ini "$out/etc"
    mkdir -p "$out/share/applications"
    cp garglk/gargoyle.desktop "$out/share/applications"
    mkdir -p "$out/share/icons/hicolor/32x32/apps"
    cp garglk/gargoyle-house.png "$out/share/icons/hicolor/32x32/apps"
  '';

  enableParallelBuilding = true;

  meta = with lib; {
    homepage = "http://ccxvii.net/gargoyle/";
    license = licenses.gpl2Plus;
    description = "Interactive fiction interpreter GUI";
    platforms = platforms.unix;
    maintainers = with maintainers; [ orivej ];
  };
}
