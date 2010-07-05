##
## $Id$
##

include $(top_srcdir)/mircommon.mak

AM_CFLAGS = @x_cflags@ 
AM_CXXFLAGS = -I$(top_srcdir)/src/subs
AM_FFLAGS = @no_globals@
LDADD = $(prog_libs)

ftasks = \
  addhis atmosph calc copyhd corset \
  cotra delhd design dwell gethd hex itemize \
  j2000 julian listobs marstb mathd maxdim \
  mfplan moslst obsrms obstau planets pnt \
  pntgen prthd prthis puthd remove rmdata \
  rmsfit sinbad sinpoly solar tacos taco telepar \
  warpfit xcorr	xfcor
bin_PROGRAMS = $(ftasks) hexc mfile
CLEANFILES = $(ftasks:=.f)
EXTRA_DIST = $(ftasks:=.for)

noinst_HEADERS = atmosph.h calc.h design.h listobs.h mathd.h pnt.h sinpoly.h

hexc_SOURCES = hexc.c
mfile_SOURCES = mfile.cc mfilelib.h

dist-hook:
	-rm -f $(distdir)/*.f

DOCINPUTS = $(EXTRA_DIST)
include $(top_srcdir)/mirdoc.mak
