##
## $Id$
##

include $(top_srcdir)/mircommon.mak

## leaving mirnewer out, new build system obsoletes its use

bin_PROGRAMS = detab doc doc_atnf docfmt docman flint ratty intf2c \
  miriad miriad_er tpcp trim

if HAVE_XAW
bin_PROGRAMS += xpanel
endif

AM_CFLAGS = -I$(top_srcdir)/src/subs

## dist_tools_DATA = xpanel.icon
EXTRA_DIST = xpanel.icon

detab_SOURCES = detab.c
doc_SOURCES = doc.c
doc_atnf_SOURCES = doc_atnf.c
docfmt_SOURCES = docfmt.c
docman_SOURCES = docman.c
flint_SOURCES = flint.c
intf2c_SOURCES = intf2c.c
miriad_SOURCES = miriad.c
miriad_er_SOURCES = miriad_er.c
ratty_SOURCES = ratty.c
tpcp_SOURCES = tpcp.c
trim_SOURCES = trim.c

xpanel_SOURCES = xpanel.c
xpanel_CFLAGS = $(X_CFLAGS)
xpanel_LDADD = $(X_PRE_LIBS) $(X_LIBS) -lX11 -lXt -lXaw $(X_EXTRA_LIBS)

DOCINPUTS = $(bin_PROGRAMS:=.c)
include $(top_srcdir)/mirdoc.mak
