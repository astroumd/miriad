##
## $Id$
##

include $(top_srcdir)/mircommon.mak

AM_FFLAGS = @no_globals@
LDADD = $(prog_libs)

ftasks = \
  gildas phatrans schedobs smablflag smablsrc smacheck \
  smachunkglue smafix smaflux smagpplt smalod smamfcal smarewt \
  smatbpass smauvamp smauvplt smauvspec smavarfit smavarplt uvsort \
  vel2fel
bin_PROGRAMS = $(ftasks)
CLEANFILES = $(ftasks:=.f)
EXTRA_DIST = $(ftasks:=.for)

noinst_HEADERS = \
  gildas.h smablflag.h smablsrc.h smagpplt.h smatbpass.h \
  smauvspec.h uvsort.h

dist-hook:
	-rm -f $(distdir)/*.f

DOCINPUTS = $(EXTRA_DIST)
include $(top_srcdir)/mirdoc.mak
