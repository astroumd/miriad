include $(top_srcdir)/mircommon.mak

# A few of these programs need the RPFITS library from borrow/rpfits.
#
# mfboot is temporarily disabled since it requires functions from the
# ATNF version of uvgn.for that have not yet been ported.

LDADD = $(prog_libs)
rpfits_libs = $(top_builddir)/borrow/rpfits/libmir_rpfits.la

ftasks = \
 at_mfcal at_moment at_uvlist at_uvplt atfix atlod atmos atrtfix atscfix \
 attsys atwvr elevcor fakeotf lagflg mbspect mopfix plboot plplt \
 wblod wbplt
bin_PROGRAMS = $(ftasks)
CLEANFILES = $(ftasks:=.f)
EXTRA_DIST = $(ftasks:=.for)

atlod_LDADD = $(prog_libs) $(rpfits_libs)
fakeotf_LDADD = $(prog_libs) $(rpfits_libs)
mopfix_LDADD = $(prog_libs) $(rpfits_libs)
wblod_LDADD = $(prog_libs) $(rpfits_libs)

noinst_HEADERS = \
  at_uvlist.h atfix.h atlod.h atmos.h mbspect.h mfcal.h wbcomm.h wblod.h

dist-hook:
	-rm -f $(distdir)/*.f

DOCINPUTS = $(EXTRA_DIST)
include $(top_srcdir)/mirdoc.mak
