##
## $Id$
##

RATTY=../../tools/ratty

.for.f:
	$(RATTY) -I ../../inc $< $@

bin_PROGRAMS = c2m uvcaldb

AM_CFLAGS = $CFLAGS @x_cflags@
AM_FFLAGS = @no_globals@
AM_LDFLAGS = -L../../subs -L@pgplot_prefix@/lib -L../../../borrow/linpack
LDADD = -lmir_uvio -lmir_linpack -lmir -lpgplot @x_libs@

BUILT_SOURCES = c2m.f

noinst_HEADERS = 

EXTRA_DIST = c2m.for

nodist_c2m_SOURCES = c2m.f
dist_uvcaldb_SOURCES = uvcaldb.f

