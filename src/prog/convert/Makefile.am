##
## $Id$
##

include $(top_srcdir)/mircommon.mak

## keeping hatmap out of this, doesn't seem to build
## CGK 12june2007

bin_PROGRAMS = fits mir ppmtomir

AM_CFLAGS = @x_cflags@
AM_FFLAGS = @no_globals@
LDADD = $(prog_libs)

BUILT_SOURCES = fits.f mir.f ppmtomir.f
CLEANFILES = $(BUILT_SOURCES)

noinst_HEADERS = fits.h mir.h

EXTRA_DIST = fits.for mir.for ppmtomir.for

nodist_fits_SOURCES = fits.f
nodist_mir_SOURCES = mir.f
nodist_ppmtomir_SOURCES = ppmtomir.f

DOCINPUTS = $(EXTRA_DIST)
include $(top_srcdir)/mirdoc.mak
