## The wcslib source tree includes a "GNUmakefile", which would override
## our Makefiles when using GNU make ... which we require. Automake
## recurses into the PWD for some operations, so we need to specify
## AM_MAKEFLAGS here the same way we do in the toplevel Makefile.am

AM_MAKEFLAGS = -f Makefile

lib_LTLIBRARIES = libmir_wcs.la libmir_pgsbox.la

wcscincdir = $(includedir)/miriad-c/wcslib
wcsfincdir = $(includedir)/miriad-f/wcslib

BUILT_SOURCES = wcsconfig.h wcsconfig_f77.h

wcscinc_HEADERS = \
 C/cel.h \
 C/fitshdr.h \
 C/lin.h \
 C/log.h \
 C/prj.h \
 C/spc.h \
 C/sph.h \
 C/spx.h \
 C/tab.h \
 C/wcserr.h \
 C/wcsfix.h \
 C/wcs.h \
 C/wcshdr.h \
 C/wcslib.h \
 C/wcsmath.h \
 C/wcsprintf.h \
 C/wcstrig.h \
 C/wcsunits.h \
 C/wcsutil.h \
 wcsconfig.h

libmir_wcs_la_CFLAGS = -I$(srcdir)/C
libmir_wcs_la_SOURCES = \
 $(wcscinc_HEADERS) \
 C/cel.c \
 C/lin.c \
 C/log.c \
 C/prj.c \
 C/spc.c \
 C/sph.c \
 C/spx.c \
 C/tab.c \
 C/wcs.c \
 C/wcserr.c \
 C/wcsfix.c \
 C/wcshdr.c \
 C/wcsprintf.c \
 C/wcstrig.c \
 C/wcsunits.c \
 C/wcsutil.c \
 $(amhack_lexes) \
 Fortran/cel_f.c \
 Fortran/fitshdr_f.c \
 Fortran/lin_f.c \
 Fortran/log_f.c \
 Fortran/prj_f.c \
 Fortran/spc_f.c \
 Fortran/sph_f.c \
 Fortran/spx_f.c \
 Fortran/tab_f.c \
 Fortran/wcs_f.c \
 Fortran/wcserr_f.c \
 Fortran/wcsfix_f.c \
 Fortran/wcshdr_f.c \
 Fortran/wcsunits_f.c

# Automake's 'ylwrap' program can't handle lexes which generate
# output files not named the classic lex.yy.c (even though GNU flex
# makes it easy to change this?!?) so we have to hack the source
# files to give it what it wants.
#
# For whatever bizarro reason, it doesn't work to list source_lexes
# explicitly and compute amhack_lexes from it; the opposite is fine.

amhack_lexes = \
 fitshdr-amhack.l \
 wcsbth-amhack.l \
 wcspih-amhack.l \
 wcsulex-amhack.l \
 wcsutrn-amhack.l

source_lexes = $(amhack_lexes:%-amhack.l=C/%.l)

%-amhack.l: C/%.l
	$(SED) -e 's/outfile=.*/outfile="lex.yy.c"/' <$< >$@

dist_noinst_DATA = $(source_lexes)

# The "PGSBOX" library - you could imagine merging this in with
# one of the other libraries in various ways if you wanted. For
# now, we just mirror the usual standalone-library setup.

libmir_pgsbox_la_CFLAGS = -Ipgsbox -I$(srcdir)/C
libmir_pgsbox_la_LIBADD = libmir_wcs.la
libmir_pgsbox_la_SOURCES = \
 pgsbox/cpgsbox.c \
 pgsbox/cpgsbox.h \
 pgsbox/fscan.f \
 pgsbox/lngvel.f \
 pgsbox/pgcrfn.f \
 pgsbox/pgcrvl.f \
 pgsbox/pgsbox.f \
 pgsbox/pgwcsl.c \
 pgsbox/pgwcsl.h

# We need to mirror the Fortran include files into the build directory
# so that the 'include wcslib/foo.inc' statements in the MIRIAD source
# code can succeed without modifying the code. Nice.

wcsfinc_HEADERS = \
 Fortran/cel.inc \
 Fortran/fitshdr.inc \
 Fortran/lin.inc \
 Fortran/log.inc \
 Fortran/prj.inc \
 Fortran/spc.inc \
 Fortran/sph.inc \
 Fortran/spx.inc \
 Fortran/tab.inc \
 Fortran/wcserr.inc \
 Fortran/wcsfix.inc \
 Fortran/wcshdr.inc \
 Fortran/wcs.inc \
 Fortran/wcsunits.inc \
 Fortran/wcserr.inc

mirrored_incs = $(wcsfinc_HEADERS:Fortran/%=%)

%.inc: Fortran/%.inc
	$(AM_V_GEN)$(LN_S) $< $@

all-local: $(mirrored_incs)

clean-local:
	-rm -f $(mirrored_incs) $(amhack_lexes)

DISTCLEANFILES = makedefs
