##
## $Id$
##

# We do not build 'mfile', which is written in C++ and has no
# documentation. Nor do we build 'hexc', which seems entirely
# redundant with 'hex' except that it's in C and has no
# documentation.

include $(top_srcdir)/mircommon.mak

LDADD = $(prog_libs)

ftasks = \
  addhis atmosph calc copyhd corset \
  cotra delhd design dwell gethd hex itemize \
  j2000 julian listobs marstb mathd maxdim \
  mfplan mirmax moslst obsrms obstau planets pnt \
  pntgen prthd prthis puthd remove rmdata \
  rmsfit sinbad sinpoly solar tacos taco telepar \
  warpfit xcorr	xfcor
bin_PROGRAMS = $(ftasks)
CLEANFILES = $(ftasks:=.f)
EXTRA_DIST = $(ftasks:=.for)

noinst_HEADERS = atmosph.h calc.h design.h listobs.h mathd.h pnt.h sinpoly.h

dist-hook:
	-rm -f $(distdir)/*.f

DOCINPUTS = $(EXTRA_DIST)
include $(top_srcdir)/mirdoc.mak
