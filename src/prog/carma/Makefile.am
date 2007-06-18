
RATTY=../../tools/ratty

.for.f:
	$(RATTY) -I ../../inc $< $@

bin_PROGRAMS = ax axcor jyperk noiseglue

AM_CFLAGS = $CFLAGS @x_cflags@
AM_LDFLAGS = -L../../subs -L@pgplot_prefix@/lib -L../../../borrow/linpack
LDADD = -lmir_uvio -lmir_linpack -lmir -lpgplot @x_libs@

BUILT_SOURCES = ax.f axcor.f jyperk.f noiseglue.f
EXTRA_DIST = ax.for axcor.for jyperk.for noiseglue.for

nodist_ax_SOURCES = ax.f
nodist_axcor_SOURCES = axcor.f
nodist_jyperk_SOURCES = jyperk.f
nodist_noiseglue_SOURCES = noiseglue.f
