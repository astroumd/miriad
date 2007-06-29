##
## $Id$
##

include $(top_srcdir)/mircommon.mak

bin_PROGRAMS = cgcurs cgdisp cginit cgrego cgslice cgspec sfind tvall tvclip tvcycle tvdisp tvflag tvinit tvset views

AM_CFLAGS = @x_cflags@
AM_FFLAGS = @no_globals@
LDADD = $(prog_libs)

BUILT_SOURCES = cgcurs.f cgdisp.f cginit.f cgrego.f cgslice.f cgspec.f sfind.f tvall.f tvclip.f tvcycle.f tvdisp.f tvflag.f tvinit.f tvset.f views.f

noinst_HEADERS = sfind.h tvclip.h tvflag.h

EXTRA_DIST = cgcurs.for cgdisp.for cginit.for cgrego.for cgslice.for cgspec.for sfind.for tvall.for tvclip.for tvcycle.for tvdisp.for tvflag.for tvinit.for tvset.for views.for

nodist_cgcurs_SOURCES = cgcurs.f
nodist_cgdisp_SOURCES = cgdisp.f
nodist_cginit_SOURCES = cginit.f
nodist_cgrego_SOURCES = cgrego.f
nodist_cgslice_SOURCES = cgslice.f
nodist_cgspec_SOURCES = cgspec.f
nodist_sfind_SOURCES = sfind.f
nodist_tvall_SOURCES = tvall.f
nodist_tvclip_SOURCES = tvclip.f
nodist_tvcycle_SOURCES = tvcycle.f
nodist_tvdisp_SOURCES = tvdisp.f
nodist_tvflag_SOURCES = tvflag.f
nodist_tvinit_SOURCES = tvinit.f
nodist_tvset_SOURCES = tvset.f
nodist_views_SOURCES = views.f

DOCINPUTS = $(EXTRA_DIST)
include $(top_srcdir)/mirdoc.mak
