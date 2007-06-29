include $(top_srcdir)/mircommon.mak

bin_PROGRAMS = ax axcor jyperk noiseglue

AM_CFLAGS = @x_cflags@
LDADD = $(prog_libs)

BUILT_SOURCES = ax.f axcor.f jyperk.f noiseglue.f
EXTRA_DIST = ax.for axcor.for jyperk.for noiseglue.for

nodist_ax_SOURCES = ax.f
nodist_axcor_SOURCES = axcor.f
nodist_jyperk_SOURCES = jyperk.f
nodist_noiseglue_SOURCES = noiseglue.f

DOCINPUTS = $(EXTRA_DIST)
include $(top_srcdir)/mirdoc.mak
