include $(top_srcdir)/mircommon.mak

# Mirmake

bin_SCRIPTS = mirmake

EXTRA_DIST = mirmake.in
CLEANFILES = mirmake Makefile.standalone

mirmake: mirmake.in
	$(AM_V_GEN)sed -e 's,%libdir%,$(libdir),' <$< >$@

# Automake >~ 1.11.3 doesn't like DATA in pkglibdir (??)
mypkglibdir = $(pkglibdir)
mypkglib_DATA = Makefile.standalone

Makefile.standalone: Makefile.standalone.tmpl
	$(AM_V_GEN)sed -e 's,%libdir%,$(libdir),' -e 's,%bindir%,$(bindir),' \
	               -e 's,%fincludedir%,$(fincludedir),' <$< >$@

# Some miscellaneous utilities for checking the correctness
# of the interaction between CVS and the autotools build.
EXTRA_DIST += check_clobber.py check_overignore.py suggest_ignore.py

DOCINPUTS = mirmake.clone
CLEANFILES += $(DOCINPUTS)
DOCFLAGS = -e

mirmake.clone: mirmake
	$(AM_V_GEN)$(LN_S) $< $@

include $(top_srcdir)/mirdoc.mak
