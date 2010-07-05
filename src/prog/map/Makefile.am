include $(top_srcdir)/mircommon.mak

AM_CFLAGS = @x_cflags@
LDADD = $(prog_libs)

ftasks = invert
bin_PROGRAMS = $(ftasks)
CLEANFILES = $(ftasks:=.f)
EXTRA_DIST = $(ftasks:=.for)

noinst_HEADERS = invert.h

dist-hook:
	-rm -f $(distdir)/*.f

DOCINPUTS = $(EXTRA_DIST)
include $(top_srcdir)/mirdoc.mak
