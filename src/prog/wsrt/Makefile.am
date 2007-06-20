##
## $Id$
##

include $(top_srcdir)/mircommon.mak

bin_PROGRAMS = tsysmed wsrtfits wsrtuvmodel

AM_CFLAGS = @x_cflags@
AM_FFLAGS = @no_globals@
LDADD = $(prog_libs)

BUILT_SOURCES = tsysmed.f wsrtfits.f wsrtuvmodel.f

noinst_HEADERS = wsrtfits.h

EXTRA_DIST = tsysmed.for wsrtfits.for wsrtuvmodel.for

nodist_tsysmed_SOURCES = tsysmed.f
nodist_wsrtfits_SOURCES = wsrtfits.f
nodist_wsrtuvmodel_SOURCES = wsrtuvmodel.f
