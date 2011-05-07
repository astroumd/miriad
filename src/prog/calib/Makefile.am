include $(top_srcdir)/mircommon.mak

LDADD = $(prog_libs)

ftasks = \
  antconv bee blcal bldelay calapply calboot calfit \
  calflag calflux calib callist calmake calplot fitgains gapply \
  gfiddle gmakes gpaver gpboot gpbreak gpbuddy gpcal gpcopy gpedit \
  gperror gplist gpnorm gpplt gpscal gpshift linecal listpol \
  mfcal mselfcal panda passfit passmake pcal selfcal tgains tmcal \
  tmcvt tmgen tpgains uvpflag wvcal xyphase
bin_PROGRAMS = $(ftasks)
CLEANFILES = $(ftasks:=.f)
EXTRA_DIST = $(ftasks:=.for)

noinst_HEADERS = bee.h blcal.h gfiddle.h gmakes.h gpcal.h gplist.h \
  gpplt.h gpscal.h mfcal.h mselfcal.h panda.h selfcal.h tmcvt.h

dist-hook:
	-rm -f $(distdir)/*.f

DOCINPUTS = $(EXTRA_DIST)
include $(top_srcdir)/mirdoc.mak
