##
## $Id$
##

include $(top_srcdir)/mircommon.mak

LDADD = $(prog_libs)

ftasks = invertf ivcFits tsysmed wsrtfits wsrtuvmodel
bin_PROGRAMS = $(ftasks)
CLEANFILES = $(ftasks:=.f)
EXTRA_DIST = $(ftasks:=.for)

noinst_HEADERS = invertf.h ivcFits.h wsrtfits.h

dist-hook:
	-rm -f $(distdir)/*.f

DOCINPUTS = $(EXTRA_DIST)
include $(top_srcdir)/mirdoc.mak
