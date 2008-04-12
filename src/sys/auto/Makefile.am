include $(top_srcdir)/mircommon.mak

# Mirmake

bin_SCRIPTS = mirmake

mirmake: mirmake.in
	sed -e 's,%libdir%,$(libdir),' <$< >$@

pkglib_DATA = Makefile.standalone

Makefile.standalone: Makefile.standalone.tmpl
	sed -e 's,%libdir%,$(libdir),' -e 's,%bindir%,$(bindir),' \
	    -e 's,%fincludedir%,$(fincludedir),' <$< >$@

DOCINPUTS = mirmake.clone
DOCFLAGS = -e

mirmake.clone: mirmake
	$(LN_S) $< $@

include $(top_srcdir)/mirdoc.mak
