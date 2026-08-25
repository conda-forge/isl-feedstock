#!/bin/bash

if [[ "$target_platform" == "win-64" ]]; then
  export CFLAGS="$CFLAGS -O3 -Dstrdup=_strdup"
  export ac_cv_have_decl__BitScanForward=yes
  export build_alias=x86_64-pc-mingw64
  export host_alias=x86_64-pc-mingw64
  export CC_FOR_BUILD=$CC
  # isl's configure.ac calls AX_PROG_CC_FOR_BUILD, which pushdefs EXEEXT ->
  # BUILD_EXEEXT and ac_exeext -> ac_build_exeext before re-running AC_PROG_CC.
  # Autoconf's `EXEEXT=$ac_cv_exeext; ac_exeext=$EXEEXT` tail only gets the RHS
  # rewritten, so the generated configure reads
  #
  #     EXEEXT=$ac_cv_build_exeext
  #     ac_build_exeext=$BUILD_EXEEXT   # empty until the very end of the macro
  #
  # leaving ac_build_exeext empty for the rest of the build-compiler pass. The
  # cross-compiling check then links `-o conftest$ac_build_exeext` (i.e. plain
  # `conftest`) but runs `./conftest$ac_cv_build_exeext` (i.e. `./conftest.exe`)
  # and dies with "cannot run C compiled programs" (exit 77). Seed BUILD_EXEEXT
  # and BUILD_OBJEXT so the two halves agree. Same story for OBJEXT.
  export BUILD_EXEEXT=.exe
  export BUILD_OBJEXT=o
  # Separately, AM_PROG_CC_C_O is expanded before the build compiler's OBJEXT is
  # known, so its probe compiles to `-o conftest2.` and checks `test -f
  # conftest2.`. Windows drops the trailing dot, the probe reports a false
  # negative, and configure wraps CC_FOR_BUILD in automake's `compile` script.
  # Pre-seed the cache to skip it and keep CC_FOR_BUILD unwrapped.
  export am_cv_build_prog_cc_c_o=yes
  autoreconf -iv
  ./configure --prefix=$PREFIX --with-int=$val_int_type --disable-shared CFLAGS="$CFLAGS" || (cat config.log && false)
  patch_libtool
else
  if [[ "$target_platform" == osx* ]]; then
    CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
  fi

  # Get an updated config.sub and config.guess
  cp $BUILD_PREFIX/share/libtool/build-aux/config.* .
  ./configure --prefix="$PREFIX" --with-int=$val_int_type --disable-static
fi

make -j$CPU_COUNT V=1
if [[ "$CONDA_BUILD_CROSS_COMPILATION" != 1 ]]; then
  make check
fi
make install-strip
