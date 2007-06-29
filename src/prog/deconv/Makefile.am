##
## $Id$
##

include $(top_srcdir)/mircommon.mak

bin_PROGRAMS = mirclean maxen mfclean mosmem mospsf mossdi mossdi2 mostess pmosmem restor tvcln

AM_CFLAGS = @x_cflags@
AM_FFLAGS = @no_globals@
LDADD = $(prog_libs)

BUILT_SOURCES = clean.f maxen.f mfclean.f mosmem.f mospsf.f mossdi.f mossdi2.f mostess.f pmosmem.f restor.f tvcln.f

noinst_HEADERS = restor.h tvcln.h

EXTRA_DIST = clean.for maxen.for mfclean.for mosmem.for mospsf.for mossdi.for mossdi2.for mostess.for pmosmem.for restor.for tvcln.for

nodist_mirclean_SOURCES = clean.f
nodist_maxen_SOURCES = maxen.f
nodist_mfclean_SOURCES = mfclean.f
nodist_mosmem_SOURCES = mosmem.f
nodist_mospsf_SOURCES = mospsf.f
nodist_mossdi_SOURCES = mossdi.f
nodist_mossdi2_SOURCES = mossdi2.f
nodist_mostess_SOURCES = mostess.f
nodist_pmosmem_SOURCES = pmosmem.f
nodist_restor_SOURCES = restor.f
nodist_tvcln_SOURCES = tvcln.f

DOCINPUTS = $(EXTRA_DIST)
include $(top_srcdir)/mirdoc.mak
