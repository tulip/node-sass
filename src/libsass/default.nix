{ lib
, stdenv
, autoreconfHook
, src ? ./.
}:
let
  version = src.version or "3.6.5";
in stdenv.mkDerivation {
  pname = "libsass";
  inherit version src;

  LIBSASS_VERSION = version;

  nativeBuildInputs = [autoreconfHook];

  meta = with lib; {
    description = "A C/C++ implementation of a Sass compiler";
    homepage = "https://github.com/sass/libsass";
    license = licenses.mit;
    maintainers = with maintainers; [ codyopel offline ];
    platforms = platforms.unix;
  };
}
