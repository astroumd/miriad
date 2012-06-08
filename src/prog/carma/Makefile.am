include $(top_srcdir)/mircommon.mak

LDADD = $(prog_libs)

ftasks = ax axcor jyperk noiseglue uvblank xyauto
noinst_HEADERS = xyauto.h
bin_PROGRAMS = $(ftasks)
CLEANFILES = $(ftasks:=.f)
EXTRA_DIST = $(ftasks:=.for)

dist-hook:
	-rm -f $(distdir)/*.f

DOCINPUTS = $(EXTRA_DIST)
include $(top_srcdir)/mirdoc.mak
