include $(top_srcdir)/mircommon.mak

bin_PROGRAMS = invert

AM_CFLAGS = @x_cflags@
LDADD = $(prog_libs)

BUILT_SOURCES = invert.f
nodist_invert_SOURCES = invert.f
EXTRA_DIST = invert.for
noinst_HEADERS = invert.h

