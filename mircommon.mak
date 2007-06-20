RATTY=$(top_builddir)/src/tools/ratty

.for.f:
	$(RATTY) -I $(top_builddir)/src/inc -I $(top_srcdir)/src/inc -I $(srcdir) $< $@

F2C=$(top_builddir)/src/tools/intf2c

.f2c.c:
	$(F2C) -s f2c $< $@

prog_libs = \
  $(top_builddir)/src/subs/libmir.la \
  $(top_builddir)/src/subs/libmir_uvio.la \
  $(top_builddir)/borrow/linpack/libmir_linpack.la \
  $(top_builddir)/borrow/pgplot/libpgplot.la \
  $(x_libs)
