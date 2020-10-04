#!/bin/bash

if [[ "$target_platform" == "win-64" ]]; then
  export CFLAGS="$CFLAGS -O3 -Dstrdup=_strdup"
  export ac_cv_have_decl__BitScanForward=yes
  autoreconf -iv
  ./configure --prefix=$PREFIX --with-gmp-prefix="${PREFIX}" --disable-static || (cat config.log && false)
  patch_libtool
else
  # Get an updated config.sub and config.guess
  cp $BUILD_PREFIX/share/libtool/build-aux/config.* .
  ./configure --prefix="$PREFIX" --with-gmp-prefix="$PREFIX" --disable-static
fi

make -j$CPU_COUNT V=1
if [[ "$CONDA_BUILD_CROSS_COMPILATION" != 1 ]]; then
  make check
fi
make install-strip
