RATTY=$(top_builddir)/src/tools/ratty

.for.f:
	$(RATTY) -I $(top_srcdir)/src/inc -I $(srcdir) $< $@

F2C=$(top_builddir)/src/tools/intf2c

.f2c.c:
	$(F2C) -s f2c $< $@
