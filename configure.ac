dnl Autoconf 2.59 was required before, but Automake 1.11 requires
dnl Autoconf 2.62 -- see discussion below.
AC_PREREQ(2.62)
AC_INIT([MIRIAD],[4.1.7],[miriad-dev-bugs@astro.berkeley.edu])
AC_REVISION([$Revision$])

AC_CONFIG_SRCDIR([src/subs/uvio.c])
AC_CONFIG_MACRO_DIR([.])
AC_CONFIG_AUX_DIR([.])
dnl FIXME! Require Automake 1.11 for now, since we currently need 
dnl AM_DEFAULT_SOURCE_EXT to build all of the tasks. A lot
dnl of people don't have Automake this recent. We need to settle
dnl on a policy, but given the current Makefile.am code, 1.11 is
dnl what's required. If the requirement is downgraded, the
dnl silent-rules option must be removed.
AM_INIT_AUTOMAKE([1.11 -Wobsolete -Wgnu -Wunsupported -Wno-syntax 
		  -Wno-portability foreign silent-rules])

dnl If using automake 1.9 / autoconf 2.59 (which is not uncommon),
dnl 'docdir' isn't defined, and we need to define it ourselves.

if test x"$docdir" = x ; then
   docdir='${datadir}/doc/${PACKAGE}'
   AC_SUBST([docdir])
fi

catdir='${pkgdatadir}/cat'
AC_SUBST([catdir])

dnl Check for compilers. Check for F77 first, since that will trigger
dnl the autoconf check for usable compiler output, and Fortran is the
dnl one we're most likely to have problems with. The check for 'cc'
dnl allows the vendor C compiler to override GCC.

AC_PROG_F77
AC_CHECK_PROG(CC, cc, cc)
AC_PROG_CC
AC_PROG_SED dnl $(SED) used in cat/Makefile.am

AC_HEADER_STDC
AC_CHECK_FUNCS([strchr memcpy bcopy])

dnl This keeps g77 from returning an error code when 
dnl there are disagreements between subroutine parameter types and the
dnl subroutine call.  Warnings are still printed.
dnl FIXME: this test and the one below do not catch the case where
dnl the compiler is actually g77 but it is known under another name;
dnl e.g. /absolute/path/to/g77 or g77-x.y.z or cpu-os-mach-g77.

if test x"$F77" = xg77; then
  no_globals="-fno-globals"
else
  no_globals=""
fi

dnl If using a GNU Fortran compiler (g77 or gfortran), give
dnl -fno-backslash to interpret our backslashed strings
dnl correctly.

if test x"$G77" = xyes; then
   no_globals="$no_globals -fno-backslash"
fi

dnl Turn off all warnings (by default)
dnl The warnings are primarily useful for developers

AC_ARG_ENABLE([warnings],
    [AS_HELP_STRING([--enable-warnings],
        [show verbose compiler/link warnings (default no)])],
    allwarningsok=$enableval, allwarningsok=no)

if test x"$allwarningsok" = xno; then
  no_globals="$no_globals -w"
else
  no_globals="$no_globals -Wall"
fi

AC_SUBST(no_globals)

dnl end no_globals check

AC_F77_LIBRARY_LDFLAGS
AC_PROG_FC([g95 gfortran gfortran-mp-4.5])
## AM_FCFLAGS([-I$(srcdir)/inc])

AC_PROG_LIBTOOL

dnl OS X XCode >= 3.1 needs a special linker flag for dynamic libraries
dnl and main programs to share common blocks. This is a required feature
dnl for the MIRIAD 'mem' routines and possibly other parts of MIRIAD as well.
dnl We'll just blindly supply the flag if the linker accepts it. 
dnl
dnl OS X XCode = 3.0 has the default behavior of XCode 3.1, which breaks
dnl MIRIAD, but it doesn't have the flag that allows it to be overridden.
dnl (The change in behavior appears to have been an unintended side effect
dnl of some other changes). MIRIAD thus appears to be un-compilable with
dnl XCode 3.0. The culprit in particular seems to be OS X ld64 version 77.
dnl
dnl See http://software.intel.com/en-us/forums/intel-fortran-compiler-for-linux-and-mac-os-x/topic/56995/
dnl for related discussion.

ldver=`$LD -v 2>&1 |grep PROJECT:ld64-77`

if test x"$ldver" != x ; then
   AC_MSG_ERROR([your system appears to use the XCode 3.0 linker, which has a
bug that prevents MIRIAD from being built successfully. Please upgrade your
installation of XCode.])
fi

commonflag="-Wl,-commons -Wl,use_dylibs"
AC_MSG_CHECKING([if the linker accepts $commonflag])

LDFLAGS_save="$LDFLAGS"
LDFLAGS="$LDFLAGS $commonflag"

AC_LINK_IFELSE([int main (void) { return 0; }],[
   AC_MSG_RESULT([yes])
],[
   AC_MSG_RESULT([no])
   LDFLAGS="$LDFLAGS_save"
])

dnl Other programs

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
    LATEX2HTML=notchecked
    BUILD_DOCS=false
    docswhy="no ; disabled via --disable-docs"
else
    dnl We need these tools:

    AC_PATH_PROG(LATEX, latex, notfound)
    AC_PATH_PROG(MAKEINDEX, makeindex, notfound)
    AC_PATH_PROG(FIG2DEV, fig2dev, notfound)
    AC_PATH_PROG(GNUPLOT, gnuplot, notfound)
    AC_PATH_PROG(LATEX2HTML, latex2html, notfound)

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
    elif test x"$LATEX2HTML" = xnotfound ; then
      BUILD_DOCS=false
      docswhy="'latex2html' not found in PATH"
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

dnl This option is not currently hooked up to anything.
dnl The gfortran compiler has a '-fdefault-integer-8' option
dnl that may be of interest in implementing this.
dnl
dnl AC_ARG_ENABLE(i8,
dnl    [AS_HELP_STRING(--enable-i8,[use large integers, if compiler supported])],
dnl    ok=$enableval, ok=no)
dnl
dnl if test x"$ok" = xyes; then 
dnl   integer_size=8
dnl else
dnl   integer_size=4
dnl fi

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
	def_maxwin=32
	def_maxwide=32
	def_maxchan=8192
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


dnl ---------------------------------------------------------------------
dnl             Check for basic X windows stuff
AC_PATH_XTRA

if test x"$no_x" = xyes; then
  AC_MSG_ERROR([X11 libraries are required to build MIRIAD])
fi

dnl Check for Xaw: library and headers. For xpanel.

dnl Must set action-if-found to nonempty to avoid
dnl the default action of adding -lXaw to LIBS and
dnl defining HAVE_LIBXAW.
AC_CHECK_LIB([Xaw], [XawScrollbarSetThumb], [true],
dnl the previous line of output will indicate what was not
dnl found, so there is some context for this message:
[AC_MSG_ERROR([you need to install the Xaw library])],
[$X_PRE_LIBS $X_LIBS -lX11 $X_EXTRA_LIBS])

save_CPPFLAGS="$CPPFLAGS"
CPPFLAGS="$CPPFLAGS $X_CFLAGS"
AC_CHECK_HEADERS([X11/Xresource.h],[],
dnl there is similarly context for this message.
[AC_MSG_ERROR([you may need to install X11 development files])],)
AC_CHECK_HEADERS([X11/Xaw/Box.h],[],
dnl there is similarly context for this message.
[AC_MSG_ERROR([you may need to install Xaw development files])],[#include <X11/Xresource.h>
#include <X11/Intrinsic.h>])
CPPFLAGS="$save_CPPFLAGS"

x_libs="$X_PRE_LIBS $X_LIBS -lX11 -lXaw $X_EXTRA_LIBS"
x_cflags="$X_CFLAGS"

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

dnl flex, needed by WCSLIB.
AM_PROG_LEX

AC_MSG_CHECKING([if $LEX is flex >= 2.5.9])
lexversion=`$LEX --version`

if echo "$lexversion" |$GREP "^flex " >/dev/null ; then
   :
else
   AC_MSG_RESULT([not flex])
   AC_MSG_ERROR([wcslib in MIRIAD requires flex to be installed])
fi

vcode=`echo "$lexversion" |sed -e "s/^flex //" |\
	    $AWK -F. '{print $1*10000 + $2*100 + $3}'`

if test $vcode -lt 20509 ; then
   AC_MSG_RESULT([version $lexversion too old])
   AC_MSG_ERROR([wcslib in MIRIAD requires flex of version at least 2.5.9])
fi

dnl LIBS="$LIBS $LEXLIB"
AC_MSG_RESULT([yes])

dnl Other stuff needed by WCSLIB
AC_DEFINE([WCSLIB_VERSION], [4.5.1], [The version of WCSLIB])
AC_CHECK_FUNCS([sincos])
dnl Copied from wcslib configure.ac:
AC_CHECK_SIZEOF([int])
AC_CHECK_SIZEOF([long int])
AC_CHECK_SIZEOF([long long int])
if test "x$ac_cv_sizeof_long_long_int" = x8; then
  AC_DEFINE([WCSLIB_INT64], [long long int], [64-bit integer data type.])
elif test "x$ac_cv_sizeof_long_int" = x8; then
  AC_DEFINE([WCSLIB_INT64], [long int], [64-bit integer data type.])
elif test "x$ac_cv_sizeof_int" = x8; then
  AC_DEFINE([WCSLIB_INT64], [int], [64-bit integer data type.])
fi
dnl End copying.
dnl We ignore #defines needed by wcsconfig_utils and wcsconfig_tests.
AC_F77_WRAPPERS
dnl Make sure that, since we're using the autotools-based build system,
dnl the user can't accidentally invoke wcslib's builtin build system.
dnl It'd be nice to override it completely, but I can't figure out a
dnl way to do that completely reliably without modifying files kept
dnl in CVS, which is a no-no.
AC_CONFIG_COMMANDS([borrow/wcslib/makedefs],[
  cat <<'EOF' >borrow/wcslib/makedefs
# Due to technical tradeoffs that aren't really worth going into,
# you cannot simply run "make" directly in the borrow/wcslib
# directory when using the autoconf-based MIRIAD build system.
# Simply run "make -f Makefile" instead (with whatever other
# arguments you wish to provide). We apologize for the inconvenience
# and weird behavior.
include You_must_run_"make_-f_Makefile"_in_wcslib.
include See_the_file_borrow/wcslib/makedefs_for_more_information.
EOF
])

AC_CONFIG_HEADERS([config.h borrow/wcslib/wcsconfig.h borrow/wcslib/wcsconfig_f77.h])
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
    borrow/wcslib/Makefile
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
    src/prog/atnf/Makefile
    src/prog/wsrt/Makefile
    src/sys/auto/Makefile
    src/sys/auto/Makefile.standalone.tmpl
    src/Makefile
    src/inc/cfg_maxdim.h:src/inc/maxdim.h.in
    src/inc/cfg_maxdimc.h:src/inc/maxdimc.h.in
])

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
echo "MAXBASE      : $MAXBASE"
echo "MAXBASE2     : $MAXBASE2"
echo "MAXCHAN      : $MAXCHAN"
echo "MAXWIN       : $MAXWIN"
echo "MAXWIDE      : $MAXWIDE"
echo "MAXNAX       : $MAXNAX"
echo "MAXBUF       : $MAXBUF"
echo
echo "Building docs: $docswhy"
echo "F77 Warnings : $allwarningsok (change with --(en|dis)able-warnings)"
