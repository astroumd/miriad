dnl Autoconf 2.59 was required before, but Automake 1.11 requires
dnl Autoconf 2.62 -- see discussion below.
AC_PREREQ(2.62)
AC_INIT([MIRIAD],[4.3.8],[miriad-dev-bugs@astro.berkeley.edu])
AC_REVISION([$Revision$])
AC_CONFIG_SRCDIR([src/subs/uvio.c])
AC_CONFIG_MACRO_DIR([src/sys/auto])
AC_CONFIG_AUX_DIR([src/sys/auto])

dnl FIXME! Require Automake 1.11 for now, since we currently need
dnl AM_DEFAULT_SOURCE_EXT to build all of the tasks. A lot
dnl of people don't have Automake this recent. We need to settle
dnl on a policy, but given the current Makefile.am code, 1.11 is
dnl what's required. If the requirement is downgraded, the
dnl silent-rules option must be removed.
AM_INIT_AUTOMAKE([1.11 -Wobsolete -Wgnu -Wunsupported -Wno-syntax
		  -Wno-portability foreign silent-rules])

dnl Libtool. Required version number is made-up.
LT_PREREQ([2.2.1])
LT_INIT([disable-static])


dnl If using automake 1.9 / autoconf 2.59 (which is not uncommon),
dnl 'docdir' isn't defined, and we need to define it ourselves.

if test x"$docdir" = x ; then
   docdir='${datadir}/doc/${PACKAGE}'
   AC_SUBST([docdir])
fi

catdir='${pkgdatadir}/cat'
AC_SUBST([catdir])


dnl Compilers. Check for F77 first, since that will trigger the
dnl autoconf check for usable compiler output, and Fortran is the one
dnl we're most likely to have problems with.

AC_PROG_F77
AC_PROG_FC([gfortran gfortran-mp-4.5 g95])
AC_PROG_CC

dnl Other programs

AC_PROG_AWK dnl for checking lex version
AC_PROG_LN_S
AC_PROG_SED dnl $(SED) used in cat/Makefile.am
AC_PROG_LEX

dnl Some basic compiler flags.
dnl
dnl -fno-globals keeps g77 from returning an error code when
dnl there are disagreements between subroutine parameter types and the
dnl subroutine call.  Warnings are still printed.

AC_LANG_PUSH([Fortran 77])
AX_CHECK_COMPILE_FLAG([-fno-globals],[AM_FFLAGS="$AM_FFLAGS -fno-globals"])

dnl If using a GNU Fortran compiler (g77 or gfortran), give
dnl -fno-backslash to interpret our backslashed strings
dnl correctly.

AX_CHECK_COMPILE_FLAG([-fno-backslash],[AM_FFLAGS="$AM_FFLAGS -fno-backslash"])

dnl Warning control

AC_ARG_ENABLE([warnings],
    [AS_HELP_STRING([--enable-warnings],
        [show verbose compiler/link warnings (default no)])],
    allwarningsok=$enableval, allwarningsok=no)

if test x"$allwarningsok" = xno; then
  AX_CHECK_COMPILE_FLAG([-w],[AM_FFLAGS="$AM_FFLAGS -w"],
    [AC_MSG_WARN([warning suppression requested but -w option not supported])])
else
  AX_CHECK_COMPILE_FLAG([-Wall],[AM_FFLAGS="$AM_FFLAGS -Wall"],
    [AC_MSG_WARN([extra warnings requested but -Wall option not supported])])
fi

AC_SUBST([AM_FFLAGS])
AC_LANG_POP([Fortran 77])

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

AC_LINK_IFELSE([
   AC_LANG_PROGRAM([[]],[[]])
],[
   AC_MSG_RESULT([yes])
],[
   AC_MSG_RESULT([no])
   LDFLAGS="$LDFLAGS_save"
])


dnl Large file support

AC_SYS_LARGEFILE
AC_FUNC_FSEEKO dnl used in wcslib


dnl Size of ptrdiff_t, used by ratty for Fortran memory routines

AC_CHECK_SIZEOF([ptrdiff_t],, [#include <stddef.h>])
if test x"ac_cv_sizeof_ptrdiff_t" = x0 ; then
   AC_MSG_ERROR([could not determine size of ptrdiff_t type])
fi
ptrdiff_ftype="INTEGER*$ac_cv_sizeof_ptrdiff_t"
AC_SUBST(ptrdiff_ftype)


dnl X windows and Xaw (for xpanel)

AC_PATH_XTRA

if test x"$no_x" = xyes; then
  AC_MSG_ERROR([X11 libraries are required to build MIRIAD])
fi

have_xaw=true
xawwhy=yes


dnl Readline, for the miriad and miriad_er mini-shells

AC_CHECK_LIB([readline], [read_history],
  [have_readline=true readlinewhy="yes"],
  [have_readline=false readlinewhy="no; libreadline not found or not linkable"])

AM_CONDITIONAL(HAVE_READLINE,$have_readline)


dnl Must set action-if-found to nonempty to avoid
dnl the default action of adding -lXaw to LIBS and
dnl defining HAVE_LIBXAW.
AC_CHECK_LIB([Xaw], [XawScrollbarSetThumb], [true],
  [have_xaw=false xawwhy="no; libXaw not found or not linkable"],
  [$X_PRE_LIBS $X_LIBS -lX11 $X_EXTRA_LIBS])

if $have_xaw ; then
  save_CPPFLAGS="$CPPFLAGS"
  CPPFLAGS="$CPPFLAGS $X_CFLAGS"
  AC_CHECK_HEADER([X11/Xresource.h],[],
    [have_xaw=false xawwhy="no; header X11/Xresource.h not found or not compilable"],)
  AC_CHECK_HEADER([X11/Xaw/Box.h],[],
    [have_xaw=false xawwhy="no; header X11/Xaw/Box.h not found or not compilable"],
    [#include <X11/Xresource.h>
     #include <X11/Intrinsic.h>])
  CPPFLAGS="$save_CPPFLAGS"
fi

AM_CONDITIONAL(HAVE_XAW,$have_xaw)

dnl Miscellaneous library functions, headers, etc
dnl
dnl Fortran linking means that we automatically get -lm, but
dnl it seems smart to set it up for C programs as well, and
dnl this allows the wcslib check for sincos to succeed later.

AC_CHECK_LIB(m, cos)
AC_CHECK_HEADERS([stdlib.h]) dnl doc_atnf.c
AC_CHECK_FUNCS([strerror dnl bug.c
		sincos dnl wcslib:wcstrig.c
])


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


dnl Telescope selection -- sets defaults for maxdim parameters

AC_ARG_WITH(telescope,
    [AS_HELP_STRING([--with-telescope=MIRTEL],[Telescope for maxdim selection])],
    TELESCOPE=$withval, TELESCOPE=carma)

def_maxdim=65536
def_maxdim2=8192
def_maxant=64
def_maxant2=28
def_maxbase=1058
def_maxbase2=1058
def_maxchan=4096
def_maxwin=16
def_maxwide=18
def_maxpnt=100000
def_maxnax=7
def_maxbuf=10000000

case $TELESCOPE in
     ata) ;;
     atnf) ;;
     bima) ;;
     carma)
	def_maxwin=32
	def_maxwide=32
	def_maxchan=8192 ;;
     lofar)
        def_maxant=2048
        def_maxbase=2096128 ;;
     fasr)
	def_maxant=128
	def_maxant2=128
        def_maxbase=8128 ;;
     gmrt)
	def_maxant=30 ;;
     sma)
        def_maxdim=4096
	def_maxant=30
	def_maxbase=435
	def_maxchan=12288
	def_maxwin=48
	def_maxwide=50 ;;
     jwst)
     	def_maxdim=65536
	def_maxdim2=8192
	def_maxant=512
	def_maxant2=512
	def_maxbase=1024
	def_maxbase2=1024
	def_maxchan=128
	def_maxwin=8
	def_maxwide=8 ;;
     test)
        def_maxdim=1024
	def_maxdim2=1024
	def_maxant=9
	def_maxbase=36
	def_maxbase2=36
	def_maxchan=1024
	def_maxwin=16
	def_maxwide=18 ;;
     wsrt) ;;
     apertif)
     	def_maxdim=65536
	def_maxdim2=8192
	def_maxant=12
	def_maxant2=12
	def_maxbase=66
	def_maxbase2=66
	def_maxchan=16384
	def_maxwin=8
	def_maxwide=8
	continue ;;
     big1)
        def_maxant=256
        def_maxant2=256
        def_maxbase=16384
	def_maxbase2=16384
	def_maxchan=512
	def_maxwin=64
	def_maxwide=64 ;;
     *)
	AC_MSG_ERROR([unknown telescope choice "$TELESCOPE"])
esac


dnl Fine-grained config and definition of maxdim parameters

AC_SUBST(TELESCOPE)
AC_SUBST(MAXDIM)
AC_SUBST(MAXDIM2)
AC_SUBST(MAXANT)
AC_SUBST(MAXANT2)
AC_SUBST(MAXBASE)
AC_SUBST(MAXBASE2)
AC_SUBST(MAXCHAN)
AC_SUBST(MAXWIN)
AC_SUBST(MAXWIDE)
AC_SUBST(MAXPNT)
AC_SUBST(MAXNAX)
AC_SUBST(MAXBUF)

AC_ARG_WITH(maxdim,
    [AS_HELP_STRING([--with-maxdim=MAXDIM],[1D access to images])],
    MAXDIM=$withval, MAXDIM="$def_maxdim")

AC_ARG_WITH(maxdim2,
    [AS_HELP_STRING([--with-maxdim2=MAXDIM2],[2D access to images])],
    MAXDIM2=$withval, MAXDIM2="$def_maxdim2")

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

AC_ARG_WITH(maxpnt,
    [AS_HELP_STRING([--with-maxpnt=MAXPNT],[Maximum number of pointings])],
    MAXPNT=$withval, MAXPNT="$def_maxpnt")

AC_ARG_WITH(maxnax,
    [AS_HELP_STRING([--with-maxnax=MAXNAX],[Maximum number of axis in images])],
    MAXNAX=$withval, MAXNAX="$def_maxnax")

AC_ARG_WITH(maxbuf,
    [AS_HELP_STRING([--with-maxbuf=MAXBUF],
       [Maximum size, in words, of blank common buffer])],
    MAXBUF=$withval, MAXBUF="$def_maxbuf")


dnl PGPLOT

AC_CONFIG_SUBDIRS(borrow/pgplot)


dnl WCSLIB needs sufficiently new flex, but casual users won't have
dnl it. If we're building from a tarball, flex isn't needed, so
dnl accommodate that situation.

if test x"$LEX" = x":" ; then
  flexnotok=true
  flexwhy="no; not installed"
else
  AC_MSG_CHECKING([if $LEX is flex >= 2.5.9])
  lexversion=`$LEX --version`

  if echo "$lexversion" |$GREP "^flex " >/dev/null ; then
    vcode=`echo "$lexversion" |sed -e "s/^flex //" |\
		$AWK -F. '{print $1*10000 + $2*100 + $3}'`
    if test $vcode -lt 20509 ; then
      AC_MSG_RESULT([version $lexversion too old])
      flexnotok=true
      flexwhy="no; need version >= 2.5.9"
    else
      AC_MSG_RESULT([yes])
      flexnotok=false
      flexwhy="yes"
    fi
  else
    AC_MSG_RESULT([not flex])
    flexnotok=true
    flexwhy="no; not GNU flex"
  fi
fi

if $flexnotok ; then
  LEX="$MISSING flex-2.5.9"
  AC_MSG_CHECKING([for pregenerated lexer source $srcdir/borrow/wcslib/wcsbth-amhack.c])
  if test -f $srcdir/borrow/wcslib/wcsbth-amhack.c ; then
    AC_MSG_RESULT([yes])
  else
    AC_MSG_RESULT([no])
    AC_MSG_ERROR([you need GNU flex 2.5.9 or newer to build from scratch (see README)])
  fi
fi


dnl Other setup for WCSLIB ...
AC_DEFINE([WCSLIB_VERSION], [4.5.1], [The version of WCSLIB])

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

AC_F77_WRAPPERS dnl wcslib uses F77_FUNC a lot

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


dnl Make the files.

AC_CONFIG_HEADERS([config.h borrow/wcslib/wcsconfig.h borrow/wcslib/wcsconfig_f77.h])

AC_CONFIG_FILES([
    Makefile
    cat/Makefile
    manuals/Makefile
    manuals/atnf-prog/Makefile
    manuals/atnf-user/Makefile
    manuals/carma/Makefile
    manuals/carma-cook/Makefile
    src/inc/Makefile
    src/tools/Makefile
    src/subs/Makefile
    src/scripts/Makefile
    src/scripts/ata/rapid/Makefile
    borrow/linpack/Makefile
    borrow/rpfits/Makefile
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

echo
echo "Telescope      : $TELESCOPE"
echo
echo "    MAXDIM(2)  : $MAXDIM ($MAXDIM2)"
echo "    MAXANT(2)  : $MAXANT ($MAXANT2)"
echo "    MAXBASE(2) : $MAXBASE ($MAXBASE2)"
echo "    MAXCHAN    : $MAXCHAN"
echo "    MAXWIN     : $MAXWIN"
echo "    MAXWIDE    : $MAXWIDE"
echo "    MAXNAX     : $MAXNAX"
echo "    MAXBUF     : $MAXBUF"
echo
echo "Building docs  : $docswhy"
echo "Building xpanel: $xawwhy"
echo "Building shells: $readlinewhy"
echo "F77 Warnings   : $allwarningsok (change with --(en|dis)able-warnings)"
echo "flex available : $flexwhy"
