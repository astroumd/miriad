
dnl TODO:    
dnl   - this file should be called configure.ac
dnl ------------------------------------------------------------------------------------

AC_MSG_CHECKING([MIRIAD4 config])

AC_INIT([MIRIAD], [4.1.0], [miriad-dev-bugs@astro.berkeley.edu])
AC_CONFIG_SRCDIR
AM_INIT_AUTOMAKE([-Wall -Werror foreign])


dnl -- checks for programs
dnl -- checks for libraries
dnl -- checks for header files
dnl -- checks for typedefs
dnl -- checks for structures
dnl -- checks for compiler characteristics
dnl -- checks for library functions
dnl -- checks for system services


dnl ---                 sizeof various data types
AC_CHECK_SIZEOF([float])
AC_CHECK_SIZEOF([double])
AC_CHECK_SIZEOF([int])
AC_CHECK_SIZEOF([long])
AC_CHECK_SIZEOF([long long])


AC_ARG_ENABLE(warnings,  [  --enable-all-warnings            verbose compiler/link warnings],
    allwarnings=yes, allwarningsok=no)

AC_HEADER_STDC
AC_CHECK_FUNCS([strchr memcpy])

dnl AC_PROG_CPP

# Use native cc if present
AC_MSG_CHECKING([for vendor's cc to be used instead of gcc])
AC_CHECK_PROG(CC, cc, cc)

AC_PROG_CC
AC_PROG_CXX
AC_PROG_CPP

AC_PROG_F77

dnl This keeps g77 from returning an error code when 
dnl there are disagreements between subroutine parameter types and the
dnl subroutine call.  Warnings are still printed.

if test x"$F77" = xg77; then
  no_globals="-fno-globals"
else
  no_globals=""
fi

dnl Turn off all warnings (by default)
dnl The warnings are primarily useful for developers

if test x"$allwarningsok" = xno; then
  no_globals="$no_globals -w -fno-backslash"
fi

AC_SUBST(no_globals)

dnl end no_globals check

AC_F77_LIBRARY_LDFLAGS
AC_PROG_FC([g95 gfortran gfortran-mp-4.2])
## AM_FCFLAGS([-I$(srcdir)/inc])

AC_PROG_LIBTOOL

AC_PROG_AWK
AC_PROG_INSTALL
AC_PROG_LN_S
AC_PROG_MAKE_SET
## RANLIB not needed when using libtool
## AC_PROG_RANLIB

## 
## AC_ARG_PROGRAM is unneeded after automake 0.20, removing CGK - 08jun07

AC_ARG_ENABLE(lfs,  [  --enable-lfs            large-file-size], ok=$enableval, ok=yes)
if test x"$ok" = xyes; then
  CFLAGS="$CFLAGS -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE"
  echo "LFS selected, note that some filesystems may not support Large File anyways"
else
  echo "LFS not selected, be aware the largest filesize may be just 2GB"
fi

AC_ARG_ENABLE(i8,  [  --enable-i8             use large-integers, if compiler supported], ok=$enableval, ok=no)
if test x"$ok" = xyes; then 
  integer_size=8
else
  integer_size=4
fi
dnl -- pick your default telescope, in the case statement below some default size
dnl -- parameters are changed for certain telescopes.
AC_ARG_WITH(telescope,  [  --with-telescope=MIRTEL    Default telescope (for maxdim)],
		    with_telescope=$withval, with_telescope="carma")
TELESCOPE=$with_telescope

dnl - reminder: the '2' and '3' versions are to be used in 2-dim and 3-dim arrays with other size parameters
def_maxdim=65536	##
def_maxdim2=8192
def_maxiant=256
def_maxant=64		##
def_maxant2=28
def_maxbase=1058	#
def_maxbase2=1058
def_maxchan=4096	# 
def_maxwin=16		# 
def_maxwide=18		# 
def_maxnax=7
def_maxbuf=4194304	##

case $TELESCOPE in
     "ata")  echo "Selecting ATA-350 array"
        def_maxiant=2048
	continue;;
     "atnf")  echo "Selecting ATNF array"
	continue;;
     "bima")  echo "Selecting old BIMA array"
	continue;;
     "carma")  echo "Selecting CARMA array"
	continue;;
     "lofar")  echo "Selecting LOFAR simulation 2048-array"
        def_maxiant=2048
        def_maxant=2048
        def_maxbase=2096128
	continue;;
     "fasr") echo "Selecting FASR simulation 128-array"
	def_maxant=128
	def_maxant2=128
        def_maxbase=8128
	continue;;
     "gmrt")  echo "Selecting GMRT array"
	def_maxant=30
	continue;;
     "sma")  echo "Selecting SMA array"
        def_maxdim=4096
	def_maxant=30
	def_maxbase=435
	def_maxchan=12288
	def_maxwin=48
	def_maxwide=50
	continue;;
     "wsrt")  echo "Selecting WSRT array"
	continue;;
     *) echo "Not a valid array"
esac

echo "DEBUG: def_maxdim=$def_maxdim"

dnl ---------------------------------------------------------------------
dnl All the MAXDIM related stuff

AC_SUBST(TELESCOPE)
AC_SUBST(MAXDIM)
AC_SUBST(MAXDIM2)
AC_SUBST(MAXIANT)
AC_SUBST(MAXANT)
AC_SUBST(MAXANT2)
AC_SUBST(MAXBASE)
AC_SUBST(MAXBASE2)
AC_SUBST(MAXCHAN)
AC_SUBST(MAXWIN)
AC_SUBST(MAXWIDE)
AC_SUBST(MAXNAX)
AC_SUBST(MAXBUF)

AC_ARG_WITH(maxdim,  [  --with-maxdim=MAXDIM       1D access to images],
		    with_maxdim=$withval, with_maxdim="$def_maxdim")
MAXDIM=$with_maxdim

AC_ARG_WITH(maxdim2, [  --with-maxdim2=MAXDIM2     2D access to images],
		    with_maxdim2=$withval, with_maxdim2="$def_maxdim2")
MAXDIM2=$with_maxdim2

AC_ARG_WITH(maxiant, [  --with-maxiant=MAXIANT     MAXIANT],
		    with_maxiant=$withval, with_maxiant="$def_maxiant")
MAXIANT=$with_maxiant

AC_ARG_WITH(maxant,  [  --with-maxant=MAXANT       1D access to antenna based arrays],
		    with_maxant=$withval, with_maxant="$def_maxant")
MAXANT=$with_maxant

AC_ARG_WITH(maxant2, [  --with-maxant2=MAXANT2     2D access to antenna based arrays],
		    with_maxant2=$withval, with_maxant2="$def_maxant2")
MAXANT2=$with_maxant2

AC_ARG_WITH(maxbase, [  --with-maxbase=MAXBASE     MAXBASE],
		    with_maxbase=$withval, with_maxbase="$def_maxbase")
MAXBASE=$with_maxbase

AC_ARG_WITH(maxbase2,[  --with-maxbase2=MAXBASE2   MAXBASE2],
		    with_maxbase2=$withval, with_maxbase2="$def_maxbase2")
MAXBASE2=$with_maxbase2

AC_ARG_WITH(maxchan, [  --with-maxchan=MAXCHAN     Maximum number of spectral channels],
		    with_maxchan=$withval, with_maxchan="$def_maxchan")
MAXCHAN=$with_maxchan

AC_ARG_WITH(maxwin,  [  --with-maxwin=MAXWIN       Maximum number of spectral windows (BIMA)],
		    with_maxwin=$withval, with_maxwin="$def_maxwin")
MAXWIN=$with_maxwin

AC_ARG_WITH(maxwide, [  --with-maxwide=MAXWIDE     Maximum number of wideband channels],
		    with_maxwide=$withval, with_maxwide="$def_maxwide")
MAXWIDE=$with_maxwide

AC_ARG_WITH(maxnax,  [  --with-maxnax=MAXNAX       Maximum number of axis in images],
		    with_maxnax=$withval, with_maxnax="$def_maxnax")
MAXNAX=$with_maxnax

AC_ARG_WITH(maxbuf,  [  --with-maxbuf=MAXBUF       Maximum size, in words, of blank common buffer],
		    with_maxbuf=$withval, with_maxbuf="$def_maxbuf")
MAXBUF=$with_maxbuf


dnl --
dnl 

AC_SUBST(WARNING)
WARNING="Warning: do not edit this file, it has been generated by configure"

AC_SUBST(SLIB)
case $host_os in
  linux*|Linux*)
    SLIB=linux
    ;;
  darwin*)
    SLIB=mac
    ;;
  sol*)
    SLIB=linux
    ;;
  *)
    SLIB=none
    ;;
esac

dnl ---------------------------------------------------------------------
dnl             Check for important libtool/linker flag

dnl TO DO, Find out how to do this using straight autoconf, it seems
dnl to be aware of the need for this, dunno why it doesn't do it properly
dnl in later libtool commands...

if test x"$SLIB" = xmac; then
  single_module="-Wl,-single_module"
else
  single_module=""
fi
AC_SUBST(single_module)

dnl             done checking for important libtool/linker flag
dnl ---------------------------------------------------------------------

dnl ---------------------------------------------------------------------
dnl             Check for basic X windows stuff
AC_PATH_X
AC_PATH_XTRA

if test x"$no_x" = xyes; then
  AC_MSG_WARN([Could not find X11 Window System Headers or Libraries!])
  if test x"$(SLIB)" = xmac; then
    AC_MSG_WARN([On Mac OS X, you must first install the X11 SDK])
  fi 
  AC_MSG_ERROR([Cannot proceed with build])
fi

x_libs="-L$x_libraries $X_PRE_LIBS $X_EXTRA_LIBS -lX11 -lXaw"
x_cflags="-I$x_includes $X_CFLAGS"

## if test x"$SLIB" = xmac; then
## else
## dnl "$X_LIBS $X_PRE_LIBS -lXext -lX11 $X_EXTRA_LIBS"
## fi

AC_SUBST(x_libs)
AC_SUBST(x_cflags)

AC_CHECK_LIB(readline, read_history)

AC_CHECK_LIB(z, inflate)
AC_CHECK_LIB(c, strtoll)
AC_CHECK_LIB(c, strtoull)

AC_SEARCH_LIBS(sin, m)

dnl Checks for header files.

AC_HEADER_DIRENT
AC_HEADER_STDC
AC_HEADER_SYS_WAIT
AC_CHECK_HEADERS(fcntl.h limits.h malloc.h sgtty.h strings.h sys/file.h sys/ioctl.h sys/time.h unistd.h)

dnl Checks for typedefs, structures, and compiler characteristics.
AC_C_CONST
AC_C_INLINE
AC_C_BIGENDIAN 
AC_TYPE_OFF_T
AC_TYPE_SIZE_T
AC_HEADER_TIME
AC_STRUCT_TM

AC_SYS_LONG_FILE_NAMES
dnl  next one can disable with --disable-largefile
AC_SYS_LARGEFILE

dnl Checks for library functions.
AC_TYPE_GETGROUPS
AC_PROG_GCC_TRADITIONAL
AC_FUNC_MEMCMP
AC_FUNC_MMAP
AC_TYPE_SIGNAL
AC_FUNC_VFORK
AC_FUNC_VPRINTF
AC_CHECK_FUNCS(ftime gethostname gettimeofday getwd mkdir select strdup strtod strtol strtoul dprintf strerror)

dnl Initialize PGPLOT
AC_CONFIG_SUBDIRS(borrow/pgplot)
PGPLOT_LIB='$(top_builddir)/borrow/pgplot/libpgplot.la'
AC_SUBST(PGPLOT_LIB)

AC_ARG_ENABLE(lfs,  [  --enable-lfs            large-file-size], ok=$enableval, ok=yes)

AC_SUBST(LINPACK_PREFIX)
AC_ARG_WITH(linpack, [  --with-linpack=DIR  If not specified, uses internal linpack],
    with_linpack=$withval, with_linpack=borrow/linpack)
LINPACK_PREFIX=$with_linpack

AC_CONFIG_HEADER(config.h)
AC_CONFIG_FILES([
    Makefile
    cat/Makefile
    src/inc/Makefile
    src/tools/Makefile
    src/subs/Makefile
    src/scripts/Makefile
    borrow/linpack/Makefile
    src/prog/analysis/Makefile
    src/prog/calib/Makefile
    src/prog/carma/Makefile
    src/prog/convert/Makefile
    src/prog/deconv/Makefile
    src/prog/disp/Makefile
    src/prog/map/Makefile
    src/prog/misc/Makefile
    src/prog/sma/Makefile
    src/prog/vis/Makefile
    src/prog/wsrt/Makefile
    src/Makefile
    src/../install/mirdefs
    src/inc/maxdim.h
    src/inc/maxdimc.h
])


dnl Not used??
dnl    src/prog/eor/Makefile

AC_OUTPUT


dnl It is beyond me why 'mirdefs' is not kept executable.... like mirdefs.in

chmod +x install/mirdefs


dnl 'maxdim' report:

echo ""
echo "TELESCOPE    : $TELESCOPE"
echo ""
echo "MAXDIM       : $MAXDIM"
echo "MAXDIM2      : $MAXDIM2"
echo "MAXIANT      : $MAXIANT"
echo "MAXANT       : $MAXANT"
echo "MAXANT2      : $MAXANT2"
dnl echo "MAXBASE      : (MAXANT2*(MAXANT2-1))/2  (hardcoded)"
echo "MAXBASE      : $MAXBASE"
echo "MAXBASE2     : $MAXBASE2"
echo "MAXCHAN      : $MAXCHAN"
echo "MAXWIN       : $MAXWIN"
echo "MAXWIDE      : $MAXWIDE"
echo "MAXNAX       : $MAXNAX"
echo "MAXBUF       : $MAXBUF"
