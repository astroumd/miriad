
RATTY=../../tools/ratty

.for.f:
	$(RATTY) -I ../../inc $< $@

bin_PROGRAMS = invert

AM_CFLAGS = $CFLAGS @x_cflags@
AM_LDFLAGS = -L../../subs -L@pgplot_prefix@/lib -L../../../borrow/linpack
LDADD = -lmir_uvio -lmir_linpack -lmir -lpgplot @x_libs@

BUILT_SOURCES = invert.f
nodist_invert_SOURCES = invert.f
EXTRA_DIST = invert.for
noinst_HEADERS = invert.h

