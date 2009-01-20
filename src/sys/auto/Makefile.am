include $(top_srcdir)/mircommon.mak

# Mirmake

bin_SCRIPTS = mirmake

EXTRA_DIST = mirmake.in
CLEANFILES = mirmake Makefile.standalone

mirmake: mirmake.in
	sed -e 's,%libdir%,$(libdir),' <$< >$@

pkglib_DATA = Makefile.standalone

Makefile.standalone: Makefile.standalone.tmpl
	sed -e 's,%libdir%,$(libdir),' -e 's,%bindir%,$(bindir),' \
	    -e 's,%fincludedir%,$(fincludedir),' <$< >$@

DOCINPUTS = mirmake.clone
CLEANFILES += $(DOCINPUTS)
DOCFLAGS = -e

mirmake.clone: mirmake
	$(LN_S) $< $@

include $(top_srcdir)/mirdoc.mak
