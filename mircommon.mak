# -*- makefile-automake -*-

RATTY=$(top_builddir)/src/tools/ratty

# The "borrow" inclusion here gets includes of wcslib/foo.inc to work.
.for.f:
	$(AM_V_GEN)$(RATTY) $(no_f90) -I $(top_builddir)/src/inc -I $(top_srcdir)/src/inc \
	  -I $(top_builddir)/borrow -I $(srcdir) $< $@

F2C=$(top_builddir)/src/tools/intf2c

.f2c.c:
	$(AM_V_GEN)$(F2C) -s f2c $< $@

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
# mdocdir = $(docdir)/misc : This seems to be basically unused.

# Utility.

prog_libs = $(top_builddir)/src/subs/libmir.la
