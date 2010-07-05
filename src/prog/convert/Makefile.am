##
## $Id$
##

include $(top_srcdir)/mircommon.mak

AM_FFLAGS = @no_globals@
LDADD = $(prog_libs)

## keeping hatmap out of this, doesn't seem to build
## CGK 12june2007

ftasks = fits mir ppmtomir
bin_PROGRAMS = $(ftasks)
CLEANFILES = $(ftasks:=.f)
EXTRA_DIST = $(ftasks:=.for)

noinst_HEADERS = fits.h mir.h

dist-hook:
	-rm -f $(distdir)/*.f

DOCINPUTS = $(EXTRA_DIST)
include $(top_srcdir)/mirdoc.mak
