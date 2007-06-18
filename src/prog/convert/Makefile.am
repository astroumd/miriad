##
## $Id$
##

RATTY=../../tools/ratty

.for.f:
	$(RATTY) -I ../../inc $< $@

## keeping hatmap out of this, doesn't seem to build
## CGK 12june2007
	
bin_PROGRAMS = fits mir ppmtomir

AM_CFLAGS = $CFLAGS @x_cflags@
AM_FFLAGS = @no_globals@
AM_LDFLAGS = -L../../subs -L@pgplot_prefix@/lib -L../../../borrow/linpack
LDADD = -lmir_uvio -lmir_linpack -lmir -lpgplot @x_libs@

convertdir=.
BUILT_SOURCES = fits.f mir.f ppmtomir.f

noinst_HEADERS = fits.h mir.h

EXTRA_DIST = fits.for mir.for ppmtomir.for

nodist_fits_SOURCES = fits.f
nodist_mir_SOURCES = mir.f
nodist_ppmtomir_SOURCES = ppmtomir.f
