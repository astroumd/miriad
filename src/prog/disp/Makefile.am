##
## $Id$
##

include $(top_srcdir)/mircommon.mak

LDADD = $(prog_libs)

ftasks = \
  cgcurs cgdisp cginit cgrego cgslice cgspec sfind tvall \
  tvclip tvcycle tvdisp tvflag tvinit tvset views
bin_PROGRAMS = $(ftasks)
CLEANFILES = $(ftasks:=.f)
EXTRA_DIST = $(ftasks:=.for)

noinst_HEADERS = sfind.h tvclip.h tvflag.h

dist-hook:
	-rm -f $(distdir)/*.f

DOCINPUTS = $(EXTRA_DIST)
include $(top_srcdir)/mirdoc.mak
