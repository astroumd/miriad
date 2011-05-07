##
## $Id$
##

include $(top_srcdir)/mircommon.mak

LDADD = $(prog_libs)

# We name the executable 'mirclean' so as not to conflict with the 'make clean'
# target; fix this up upon install and account for the fact that its source
# files have unusual names.

ftasks = \
  maxen mfclean mosmem mospsf mossdi mossdi2 \
  mostess pmosmem restor tvcln
bin_PROGRAMS = $(ftasks) mirclean
CLEANFILES = $(ftasks:=.f) clean.f
EXTRA_DIST = $(ftasks:=.for) clean.for

noinst_HEADERS = restor.h tvcln.h
mirclean_SOURCES = clean.f

install-exec-hook:
	cd $(DESTDIR)$(bindir) && rm -f clean && $(LN_S) mirclean clean

uninstall-hook:
	rm -f $(DESTDIR)$(bindir)/clean

dist-hook:
	-rm -f $(distdir)/*.f

DOCINPUTS = $(EXTRA_DIST) clean.for
include $(top_srcdir)/mirdoc.mak
