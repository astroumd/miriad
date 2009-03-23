AC_PREREQ(2.59)
AC_INIT([MIRIAD],[4.1.1],[miriad-dev-bugs@astro.berkeley.edu])
AC_REVISION([$Revision$])

AC_CONFIG_SRCDIR
AC_CONFIG_MACRO_DIR([.])
AM_INIT_AUTOMAKE([--warnings=obsolete  --warnings=gnu --warnings=unsupported --warnings=no-syntax --warnings=no-portability foreign])


dnl ---                 sizeof various data types
AC_CHECK_SIZEOF([float])
AC_CHECK_SIZEOF([double])
AC_CHECK_SIZEOF([int])
AC_CHECK_SIZEOF([long])
AC_CHECK_SIZEOF([long long])


AC_HEADER_STDC
AC_CHECK_FUNCS([strchr memcpy bcopy])

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

if test x"$F77" = xg77 -o x"$F77" = xf77; then
  no_f90="-D NOF90"
else
  no_f90=""
fi

AC_SUBST(no_f90)


dnl Turn off all warnings (by default)
dnl The warnings are primarily useful for developers

AC_ARG_ENABLE([warnings],
    [AS_HELP_STRING([--enable-all-warnings],
        [show verbose compiler/link warnings (default no)])],
    allwarnings=$enableval, allwarningsok=no)

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

dnl Documentation checks

AC_ARG_ENABLE([docs],
    [AS_HELP_STRING([--disable-docs],
        [disable building of documentation])],
    wantdocs=$enableval, wantdocs=detect)

if test x"$wantdocs" = xno ; then
    LATEX=notchecked
    MAKEINDEX=notchecked
    FIG2DEV=notchecked
    GNUPLOT=notchecked
    BUILD_DOCS=false
    docswhy="no ; disabled via --disable-docs"
else
    dnl We need these tools:

    AC_PATH_PROG(LATEX, latex, notfound)
    AC_PATH_PROG(MAKEINDEX, makeindex, notfound)
    AC_PATH_PROG(FIG2DEV, fig2dev, notfound)
    AC_PATH_PROG(GNUPLOT, gnuplot, notfound)

    dnl If --enable-docs is explicitly given and we can't build
    dnl docs, treat that as an error.
    dnl If neither --enable-docs nor --disable-docs is given,
    dnl just go with whatever result we get.

    if test x"$LATEX" = xnotfound ; then
      BUILD_DOCS=false
      docswhy="'latex' not found in PATH"
    elif test x"$MAKEINDEX" = xnotfound ; then
      BUILD_DOCS=false
      docswhy="'makeindex' not found in PATH"
    elif test x"$FIG2DEV" = xnotfound ; then
      BUILD_DOCS=false
      docswhy="'fig2dev' not found in PATH"
    elif test x"$GNUPLOT" = xnotfound ; then
      BUILD_DOCS=false
      docswhy="'gnuplot' not found in PATH"
    else
      BUILD_DOCS=true
      docswhy="yes"
    fi

    if test x"$BUILD_DOCS" = xtrue -a x"$wantdocs" = xdetect ; then
        docswhy="yes (autodetected; disable with --disable-docs)"
    fi

    if test x"$BUILD_DOCS" = xfalse ; then
        if test x"$wantdocs" = xyes ; then
            AC_MSG_ERROR([docs explicitly requested but $docswhy])
	else
	    docswhy="no ; $docswhy"
	fi
    fi
fi

AC_SUBST(LATEX)
AC_SUBST(MAKEINDEX)
AM_CONDITIONAL(BUILD_DOCS,$BUILD_DOCS)

## 
## AC_ARG_PROGRAM is unneeded after automake 0.20, removing CGK - 08jun07

dnl Large file support. AC_SYS_LARGEFILE introduces the option
dnl --disable-largefile ... I don't know if our custom code is
dnl necessary at all, given AC_SYS_LARGEFILE. If it is, we should
dnl ditch our own --enable flag and key off of $enable_largefile, but
dnl I don't want to make that change right now.

AC_ARG_ENABLE(lfs,
    [AS_HELP_STRING(--enable-lfs,[support large file sizes])],
    ok=$enableval, ok=yes)

if test x"$ok" = xyes; then
  CFLAGS="$CFLAGS -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE"
  echo "LFS selected, note that some filesystems may not support Large File anyways"
else
  echo "LFS not selected, be aware the largest filesize may be just 2GB"
fi

AC_SYS_LARGEFILE

AC_ARG_ENABLE(i8,
    [AS_HELP_STRING(--enable-i8,[use large integers, if compiler supported])],
    ok=$enableval, ok=no)

if test x"$ok" = xyes; then 
  integer_size=8
else
  integer_size=4
fi


dnl -- pick your default telescope, in the case statement below some default size
dnl -- parameters are changed for certain telescopes.
AC_ARG_WITH(telescope,
    [AS_HELP_STRING([--with-telescope=MIRTEL],[Telescope for maxdim selection])],
    TELESCOPE=$withval, TELESCOPE=carma)

dnl - reminder: the '2' and '3' versions are to be used in 2-dim and 3-dim arrays
dnl    with other size parameters
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
def_maxbuf=10000000     ##

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
     "ral512") echo "Selecting RAL simulation 512-array"
        def_maxiant=2048
        def_maxant=512
        def_maxant2=512
        def_maxbase=4096
	continue;;
     *) echo "Not a valid array"
esac

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

AC_ARG_WITH(maxdim,
    [AS_HELP_STRING([--with-maxdim=MAXDIM],[1D access to images])],
    MAXDIM=$withval, MAXDIM="$def_maxdim")

AC_ARG_WITH(maxdim2,
    [AS_HELP_STRING([--with-maxdim2=MAXDIM2],[2D access to images])],
    MAXDIM2=$withval, MAXDIM2="$def_maxdim2")

AC_ARG_WITH(maxiant,
    [AS_HELP_STRING([--with-maxiant=MAXIANT],[MAXIANT])],
    MAXIANT=$withval, MAXIANT="$def_maxiant")

AC_ARG_WITH(maxant,
    [AS_HELP_STRING([--with-maxant=MAXANT],[1D access to antenna based arrays])],
    MAXANT=$withval, MAXANT="$def_maxant")

AC_ARG_WITH(maxant2,
    [AS_HELP_STRING([--with-maxant2=MAXANT2],[2D access to antenna based arrays])],
    MAXANT2=$withval, MAXANT2="$def_maxant2")

AC_ARG_WITH(maxbase,
    [AS_HELP_STRING([--with-maxbase=MAXBASE],[MAXBASE])],
    MAXBASE=$withval, MAXBASE="$def_maxbase")

AC_ARG_WITH(maxbase2,
    [AS_HELP_STRING([--with-maxbase2=MAXBASE2],[MAXBASE2])],
    MAXBASE2=$withval, MAXBASE2="$def_maxbase2")

AC_ARG_WITH(maxchan,
    [AS_HELP_STRING([--with-maxchan=MAXCHAN],[Maximum number of spectral channels])],
    MAXCHAN=$withval, MAXCHAN="$def_maxchan")

AC_ARG_WITH(maxwin,
    [AS_HELP_STRING([--with-maxwin=MAXWIN],
       [Maximum number of spectral windows (BIMA)])],
    MAXWIN=$withval, MAXWIN="$def_maxwin")

AC_ARG_WITH(maxwide,
    [AS_HELP_STRING([--with-maxwide=MAXWIDE],[Maximum number of wideband channels])],
    MAXWIDE=$withval, MAXWIDE="$def_maxwide")

AC_ARG_WITH(maxnax,
    [AS_HELP_STRING([--with-maxnax=MAXNAX],[Maximum number of axis in images])],
    MAXNAX=$withval, MAXNAX="$def_maxnax")

AC_ARG_WITH(maxbuf,
    [AS_HELP_STRING([--with-maxbuf=MAXBUF],
       [Maximum size, in words, of blank common buffer])],
    MAXBUF=$withval, MAXBUF="$def_maxbuf")


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
AC_PATH_XTRA

if test x"$no_x" = xyes; then
  AC_MSG_WARN([Could not find X11 Window System Headers or Libraries!])
  if test x"$SLIB" = xmac; then
    AC_MSG_WARN([On Mac OS X, you must first install the X11 SDK])
  fi 
  AC_MSG_ERROR([Cannot proceed with build])
fi

x_libs="$X_PRE_LIBS $X_LIBS -lX11 -lXaw $X_EXTRA_LIBS"
x_cflags="$X_CFLAGS"

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
AC_CHECK_HEADERS([fcntl.h limits.h malloc.h sgtty.h strings.h sys/file.h])
AC_CHECK_HEADERS([sys/ioctl.h sys/time.h unistd.h])

dnl Checks for typedefs, structures, and compiler characteristics.
AC_C_CONST
AC_C_INLINE
AC_C_BIGENDIAN 
AC_TYPE_OFF_T
AC_TYPE_SIZE_T
AC_HEADER_TIME
AC_STRUCT_TM

AC_SYS_LONG_FILE_NAMES

dnl Checks for library functions.
AC_TYPE_GETGROUPS
AC_PROG_GCC_TRADITIONAL
AC_FUNC_MEMCMP
AC_FUNC_MMAP
AC_TYPE_SIGNAL
AC_FUNC_VFORK
AC_FUNC_VPRINTF
AC_CHECK_FUNCS([ftime gethostname gettimeofday getwd mkdir select])
AC_CHECK_FUNCS([strdup strtod strtol strtoul dprintf strerror])

dnl Initialize PGPLOT
AC_CONFIG_SUBDIRS(borrow/pgplot)
PGPLOT_LIB='$(top_builddir)/borrow/pgplot/libpgplot.la'
AC_SUBST(PGPLOT_LIB)

AC_SUBST(LINPACK_PREFIX)
AC_ARG_WITH(linpack,
    [AS_HELP_STRING([--with-linpack=DIR],[If not specified, uses internal linpack])],
    LINPACK_PREFIX=$withval, LINPACK_PREFIX=borrow/linpack)

AC_CONFIG_HEADER(config.h)
AC_CONFIG_FILES([
    Makefile
    cat/Makefile
    manuals/Makefile
    manuals/atnf-prog/Makefile
    manuals/atnf-user/Makefile
    manuals/carma/Makefile
    src/inc/Makefile
    src/tools/Makefile
    src/subs/Makefile
    src/scripts/Makefile
    src/scripts/ata/rapid/Makefile
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
    src/sys/auto/Makefile
    src/sys/auto/Makefile.standalone.tmpl
    src/Makefile
    src/inc/cfg_maxdim.h:src/inc/maxdim.h.in
    src/inc/cfg_maxdimc.h:src/inc/maxdimc.h.in
])


dnl Not used??
dnl    src/prog/eor/Makefile

AC_OUTPUT


dnl Summarize important configuration settings.

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
echo
echo "Building docs: $docswhy"
