include $(top_srcdir)/mircommon.mak

bin_PROGRAMS = detab doc doc_atnf docfmt docman flint ratty intf2c \
  tpcp trim

if HAVE_XAW
bin_PROGRAMS += xpanel
endif

if HAVE_READLINE
bin_PROGRAMS += miriad miriad_er
endif

AM_CFLAGS = -I$(top_srcdir)/src/subs

EXTRA_DIST = xpanel.icon

# Normally we wouldn't have to explicitly name the source files, but
# we've changed the default source extension to .f, so we must
# explicitly identify these programs as having C source.

detab_SOURCES = detab.c
doc_SOURCES = doc.c
doc_atnf_SOURCES = doc_atnf.c
docfmt_SOURCES = docfmt.c
docman_SOURCES = docman.c
flint_SOURCES = flint.c
intf2c_SOURCES = intf2c.c
ratty_SOURCES = ratty.c
tpcp_SOURCES = tpcp.c
trim_SOURCES = trim.c

xpanel_SOURCES = xpanel.c
xpanel_CFLAGS = $(X_CFLAGS)
xpanel_LDADD = $(X_PRE_LIBS) $(X_LIBS) -lX11 -lXt -lXaw $(X_EXTRA_LIBS)

miriad_SOURCES = miriad.c
miriad_LDADD = -lreadline

miriad_er_SOURCES = miriad_er.c
miriad_er_LDADD = -lreadline

DOCINPUTS = $(bin_PROGRAMS:=.c)
include $(top_srcdir)/mirdoc.mak
