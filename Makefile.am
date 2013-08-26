##
## $Id$
##

ACLOCAL_AMFLAGS = -I src/sys/auto

## For pdocdir / sdocdir.

include $(top_srcdir)/mircommon.mak

## The wcslib source tree includes a "GNUmakefile", which would override
## our Makefiles when using GNU make ... which we require. This flag
## will tell make to use the right Makefile when recursing into the wcslib
## directory.

AM_MAKEFLAGS = -f Makefile

## Build tools first to get the doc program ASAP.

SUBDIRS = \
  src/inc \
  src/tools \
  cat \
  borrow/pgplot \
  borrow/linpack \
  borrow/wcslib \
  borrow/rpfits \
  src/subs \
  src/scripts \
  src/scripts/ata/rapid \
  src/prog/analysis \
  src/prog/calib \
  src/prog/carma \
  src/prog/convert \
  src/prog/deconv \
  src/prog/disp \
  src/prog/map \
  src/prog/misc \
  src/prog/sma \
  src/prog/vis \
  src/prog/atnf \
  src/prog/wsrt \
  src/sys/auto \
  src

if BUILD_DOCS
SUBDIRS += manuals
endif

EXTRA_DIST = mircommon.mak mirdoc.mak \
  automiriad.csh.in automiriad.sh.in install.MIR \
  install/mir.test

# configure has an abs_srcdir substitution that we could use, but it
# can look like /path/to/srcdir/buildsubdir/.., so CD and PWD to
# get a pretty-looking absolute path to top_srcdir.

# Automake >~ 1.11.3 doesn't like SCRIPTS in pkglibdir (??)
mypkglibdir = $(pkglibdir)
mypkglib_SCRIPTS = automiriad.csh automiriad.sh libtool

automiriad.csh: automiriad.csh.in
	$(AM_V_GEN)abssrc=`cd $(top_srcdir) && pwd` ; \
	sed -e "s,%abs_srcdir%,$$abssrc," \
	    -e "s,%prefix%,$(prefix)," \
	    -e "s,%pkgdatadir%,$(pkgdatadir)," \
	    -e "s,%fincludedir%,$(fincludedir)," \
	    -e "s,%catdir%,$(catdir)," \
	    -e "s,%bindir%,$(bindir)," \
	    -e "s,%libdir%,$(libdir)," <$< >$@

automiriad.sh: automiriad.sh.in
	$(AM_V_GEN)abssrc=`cd $(top_srcdir) && pwd` ; \
	sed -e "s,%abs_srcdir%,$$abssrc," \
	    -e "s,%prefix%,$(prefix)," \
	    -e "s,%pkgdatadir%,$(pkgdatadir)," \
	    -e "s,%fincludedir%,$(fincludedir)," \
	    -e "s,%catdir%,$(catdir)," \
	    -e "s,%bindir%,$(bindir)," \
	    -e "s,%libdir%,$(libdir)," <$< >$@

CLEANFILES = automiriad.csh automiriad.sh

# Clean up the docs on uninstall.

uninstall-hook:
	rm -f $(DESTDIR)$(pdocdir)/*
	rm -f $(DESTDIR)$(sdocdir)/*

# "make distcheck" does a "distclean" and checks to see that there are
# no files left in the *build* directory when all of the files *to
# distribute* are ready to go. When doing this test for MIRIAD, we
# have (f)lex output files left in borrow/wcslib: we run (f)lex on
# modified versions of the original source files to work around a
# limitation in automake's "ylwrap" program, so the files are both
# "built" and "to be distributed". I don't quite understand how this
# is worked around in the case of normal (f)lex usage, but there are
# two ways make this problem go away:
#
# 1) Delete the (f)lex-generated .c files on distclean. Automake
# encourages that these files be distributed so that users don't need
# (f)lex to build the package, but its test seems to fall down here.
#
# 2) Do what we do below: override the test command
# "distcleancheck_listfiles" to hide the error. This is not recommended
# in general, but seeing as we're working around an Automake problem
# anyway, I don't feel bad.

distcleancheck_listfiles = find . -type f -print |$(GREP) -v amhack\.c
