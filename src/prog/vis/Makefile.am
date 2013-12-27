##
## $Id$
##

include $(top_srcdir)/mircommon.mak

LDADD = $(prog_libs)

## Removed mbanal, doesn't build in regular miriad anyway...
## CGK 12jun2007

ftasks = \
  antpol atmerge atxy blflag bootflux bwsel calred closure \
  conterr contsen csflag early fgflag im2uv mfflat mosgen offaxis \
  offpol opcal paraplot pgflag qvack sfunc sinpoly transfix uvaflag \
  uvamp uvarchdd uvaver uvbflag uvcal uvcal2 uvcat uvcheck uvclip uvcover \
  uvdecor uvdiff uvedit uvfft uvfit uvfix uvflag uvflux uvfmeas uvfstats \
  uvgains uvgen uvgenmodel uvglue uvimage uvindex uvlin uvlist uvmodel \
  uvphase uvplanet uvplot uvplt uvpnt uvputhd uvrandom uvratio uvredo \
  uvsector uvsfit uvspec uvspect uvsplit uvstat uvsub uvswap uvtcor uvtplt \
  uvtrack uvtriple uvtsub uvwide varfit varlist varmap varmaps varmerge \
  varplot varplt
bin_PROGRAMS = $(ftasks)
CLEANFILES = $(ftasks:=.f)
EXTRA_DIST = $(ftasks:=.for)

noinst_HEADERS = \
  atxy.h sinpoly.h uvaver.h uvdiff.h uvfit.h uvgains.h uvgen.h \
  uvgenmodel.h uvlist.h uvplot.h uvpnt.h uvputhd.h uvspec.h uvsfit.h \
  uvsplit.h uvtrack.h varplot.h

dist-hook:
	-rm -f $(distdir)/*.f

DOCINPUTS = $(EXTRA_DIST)
include $(top_srcdir)/mirdoc.mak
