## The wcslib source tree includes a "GNUmakefile", which would override
## our Makefiles when using GNU make ... which we require. Automake
## recurses into the PWD for some operations, so we need to specify
## AM_MAKEFLAGS here the same way we do in the toplevel Makefile.am

AM_MAKEFLAGS = -f Makefile

lib_LTLIBRARIES = libmir_wcs.la libmir_pgsbox.la

libmir_wcs_la_CFLAGS = -I$(srcdir)/C
libmir_wcs_la_LDFLAGS = -dynamic @single_module@
libmir_wcs_la_SOURCES = \
 C/cel.c \
 C/cel.h \
 C/fitshdr.h \
 C/lin.c \
 C/lin.h \
 C/log.c \
 C/log.h \
 C/prj.c \
 C/prj.h \
 C/spc.c \
 C/spc.h \
 C/sph.c \
 C/sph.h \
 C/spx.c \
 C/spx.h \
 C/tab.c \
 C/tab.h \
 C/wcs.c \
 C/wcsfix.c \
 C/wcsfix.h \
 C/wcs.h \
 C/wcshdr.c \
 C/wcshdr.h \
 C/wcslib.h \
 C/wcsmath.h \
 C/wcstrig.c \
 C/wcstrig.h \
 C/wcsunits.c \
 C/wcsunits.h \
 C/wcsutil.c \
 C/wcsutil.h \
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
 Fortran/wcsfix_f.c \
 Fortran/wcshdr_f.c \
 Fortran/wcsunits_f.c

# Automake's 'ylwrap' program can't handle lexes which generate
# output files not named the classic lex.yy.c (even though GNU flex
# makes it easy to change this?!?) so we have to hack the source
# files to give it what it wants.
#
# Furthermore, the wcslib lex files redefine "exit", which can cause
# compilation problems when this redefinition precedes the actual
# prototype of exit. We fix this by splicing in an #include <stdlib.h>
# into the header stanzas, which come before the redefinition.
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
	$(SED) -e 's/outfile=.*/outfile="lex.yy.c"/' \
	       -e 's/#include <setjmp.h>/#include <setjmp.h>\n#include <stdlib.h>/' <$< >$@

dist_noinst_DATA = $(source_lexes)

# The "PGSBOX" library - you could imagine merging this in with
# one of the other libraries in various ways if you wanted. For
# now, we just mirror the usual standalone-library setup.

libmir_pgsbox_la_CFLAGS = -Ipgsbox -I$(srcdir)/C
libmir_pgsbox_la_LDFLAGS = -dynamic @single_module@
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

fortran_incs = \
 Fortran/cel.inc \
 Fortran/fitshdr.inc \
 Fortran/lin.inc \
 Fortran/log.inc \
 Fortran/prj.inc \
 Fortran/spc.inc \
 Fortran/sph.inc \
 Fortran/spx.inc \
 Fortran/tab.inc \
 Fortran/wcsfix.inc \
 Fortran/wcshdr.inc \
 Fortran/wcs.inc \
 Fortran/wcsunits.inc

mirrored_incs = $(fortran_incs:Fortran/%=%)

dist_noinst_DATA += $(fortran_incs)

%.inc: Fortran/%.inc
	$(AM_V_GEN)$(LN_S) $< $@

all-local: $(mirrored_incs)

clean-local:
	-rm -f $(mirrored_incs) $(amhack_lexes)

DISTCLEANFILES = makedefs
