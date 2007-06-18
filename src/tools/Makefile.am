##
## $Id$
##

## leaving mirnewer out, new build system obsoletes its use

bin_PROGRAMS = detab doc doc_atnf docfmt docman flint ratty intf2c \
  miriad miriad_er tpcp trim xpanel

AM_CFLAGS = $(CFLAGS) -I../subs

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
xpanel_CFLAGS = @x_cflags@ 
xpanel_LDADD = @x_libs@ -lXt

