##
## $Id$
##

include $(top_srcdir)/mircommon.mak

LDADD = $(prog_libs)

# Only two tasks, and one of them is special (uvcaldb is generated straight
# from a .f, not a .for), so just do this manually.

bin_PROGRAMS = c2m uvcaldb
CLEANFILES = c2m.f
EXTRA_DIST = c2m.for

dist-hook:
	-rm -f $(distdir)/c2m.f

DOCINPUTS = $(EXTRA_DIST)
include $(top_srcdir)/mirdoc.mak
