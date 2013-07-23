include $(top_srcdir)/mircommon.mak
doc_prog = doc

bin_PROGRAMS = doc docfmt docman flint intf2c ratty varsizes
noinst_PROGRAMS = detab # used in building docs

if HAVE_XAW
bin_PROGRAMS += xpanel
endif

AM_CPPFLAGS = -I$(top_srcdir)/src/subs

if HAVE_READLINE
bin_PROGRAMS += miriad
AM_CPPFLAGS += -DREADLINE=1
endif

EXTRA_DIST = xpanel.icon

# Normally we wouldn't have to explicitly name the source files, but
# we've changed the default source extension to .f, so we must
# explicitly identify these programs as having C source.

detab_SOURCES = detab.c
doc_SOURCES = doc.c
docfmt_SOURCES = docfmt.c
docman_SOURCES = docman.c
flint_SOURCES = flint.c
intf2c_SOURCES = intf2c.c
ratty_SOURCES = ratty.c
varsizes_SOURCES = varsizes.c

xpanel_SOURCES = xpanel.c
xpanel_CFLAGS = $(X_CFLAGS)
xpanel_LDADD = $(X_PRE_LIBS) $(X_LIBS) -lX11 -lXt -lXaw $(X_EXTRA_LIBS)

miriad_SOURCES = miriad.c
miriad_LDADD = -lreadline

# Skip programs that overwrite docs for existing versions or don't
# have docs:
DOCINPUTS = doc.c docfmt.c docman.c flint.c ratty.c intf2c.c xpanel.c miriad.c
include $(top_srcdir)/mirdoc_noprog.mak
