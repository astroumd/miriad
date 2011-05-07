include $(top_srcdir)/mircommon.mak

# We do not build atlod, mopfix, or wblod, because they require the
# rpfits library. This resides in borrow/rpfits/, but I don't feel
# like hooking it up to autotools right now. If someone needs one
# of these tasks, I'll look into hooking it up.

AM_FFLAGS = @no_globals@
LDADD = $(prog_libs)

ftasks = \
  atfix atmos atrtfix atscfix attsys atwvr elevcor lagflg \
  mbspect mfboot plboot plplt wbplt
bin_PROGRAMS = $(ftasks)
CLEANFILES = $(ftasks:=.f)
EXTRA_DIST = $(ftasks:=.for)

noinst_HEADERS = \
  atfix.h atmos.h mbspect.h wbcomm.h

EXTRA_DIST += atlod.for atlod.h mopfix.for wblod.for wblod.h

dist-hook:
	-rm -f $(distdir)/*.f

DOCINPUTS = $(EXTRA_DIST)
include $(top_srcdir)/mirdoc.mak
