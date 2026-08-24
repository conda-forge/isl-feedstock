#!/bin/bash

if [[ "$target_platform" == "win-64" ]]; then
  export CFLAGS="$CFLAGS -O3 -Dstrdup=_strdup"
  export ac_cv_have_decl__BitScanForward=yes
  export build_alias=x86_64-pc-mingw64
  export host_alias=x86_64-pc-mingw64
  export CC_FOR_BUILD=$CC
  # isl's configure.ac calls AX_PROG_CC_FOR_BUILD, which runs AM_PROG_CC_C_O
  # before the build compiler's OBJEXT has been determined. The probe therefore
  # compiles to `-o conftest2.` and checks `test -f conftest2.` -- a trailing-dot
  # filename that cannot exist on Windows. The probe "fails", and configure then
  # wraps CC_FOR_BUILD in automake's `compile` script. That wrapper moves the
  # linker output to the exact -o name, dropping the .exe suffix that clang
  # appends on its own, so the following "whether we are cross compiling" check
  # runs ./conftest.exe against a file that is named plain `conftest` and dies
  # with "cannot run C compiled programs". Pre-seed the cache to skip the probe.
  export am_cv_build_prog_cc_c_o=yes
  export ac_cv_build_objext=o
  export ac_cv_build_exeext=.exe
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
