##
## $Id$
##

include $(top_srcdir)/mircommon.mak

bin_PROGRAMS = c2m uvcaldb

AM_CFLAGS = @x_cflags@
AM_FFLAGS = @no_globals@
LDADD = $(prog_libs)

BUILT_SOURCES = c2m.f

noinst_HEADERS = 

EXTRA_DIST = c2m.for

nodist_c2m_SOURCES = c2m.f
dist_uvcaldb_SOURCES = uvcaldb.f

