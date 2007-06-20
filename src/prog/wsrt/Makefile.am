##
## $Id$
##

RATTY=../../tools/ratty

.for.f:
	$(RATTY) -I ../../inc $< $@

bin_PROGRAMS = tsysmed wsrtfits wsrtuvmodel

AM_CFLAGS = $CFLAGS @x_cflags@
AM_FFLAGS = @no_globals@
AM_LDFLAGS = -L../../subs -L../../../borrow/linpack
LDADD = -lmir_uvio -lmir_linpack -lmir $(PGPLOT_LIB) @x_libs@

BUILT_SOURCES = tsysmed.f wsrtfits.f wsrtuvmodel.f

noinst_HEADERS = wsrtfits.h

EXTRA_DIST = tsysmed.for wsrtfits.for wsrtuvmodel.for

nodist_tsysmed_SOURCES = tsysmed.f
nodist_wsrtfits_SOURCES = wsrtfits.f
nodist_wsrtuvmodel_SOURCES = wsrtuvmodel.f
