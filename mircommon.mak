# -*- makefile-automake -*-

RATTY=$(top_builddir)/src/tools/ratty

# The "borrow" inclusion here gets includes of wcslib/foo.inc to work.
%.f: %.for $(RATTY)
	$(AM_V_GEN)$(RATTY) -p "@ptrdiff_ftype@" -s gfortran \
	  -I $(top_builddir)/src/inc -I $(top_srcdir)/src/inc \
	  -I $(top_builddir)/borrow -I $(srcdir) $< $@

F2C=$(top_builddir)/src/tools/intf2c

%.c: %.f2c $(F2C)
	$(AM_V_GEN)$(F2C) -s f2c -a $< $@

# Default for building tasks

AM_DEFAULT_SOURCE_EXT = .f

# Include directories.

fincludedir = $(includedir)/miriad-f
cincludedir = $(includedir)/miriad-c

# Documentation variables.

doc_catsrc = $(top_srcdir)/cat
doc_prog = $(top_builddir)/src/tools/doc
DOC = MIRCAT=$(doc_catsrc) $(doc_prog)

mirdocdir = $(pkgdatadir)/doc
pdocdir = $(mirdocdir)/prog
sdocdir = $(mirdocdir)/subs

# Utility.

prog_libs = \
  $(top_builddir)/src/subs/libmir.la \
  $(top_builddir)/borrow/wcslib/libmir_wcs.la \
  $(top_builddir)/borrow/pgplot/libpgplot.la
