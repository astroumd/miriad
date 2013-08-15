##
## $Id$
##

include $(top_srcdir)/mircommon.mak

LDADD = $(prog_libs)

ftasks = avmaths boxspec boxtest clfind clplot \
  clstats colden contsub convol demos \
  deproject ellint ellplt fft gaufit gaufit2 \
  hanning hatfft hermes histo imbin \
  imblob imblr imcat imcfn imcmp imcomb \
  imcorr imdiff imfit imframe imgen \
  imhead imheq imhist imhol imlist \
  imload immask immedian immerge imom \
  implot impol impoly impos imrm \
  imsad imsharp imspec imspect imstack imstat \
  imstore imsub imtab imwcs imwrite \
  linmos mafia maths maxfit mfspin minmax \
  moment mossen odnh3 pbplot pcsub polargrid \
  pops posvel potfft psrbl psrfix psrplt \
  regrid reorder rotcurmask shifty sigest \
  smooth vblank velcolor velfit velimage \
  velmodel velplot velsw xpeak zapchan \
  zeeeta zeefake zeemap zeesim zeestat
bin_PROGRAMS = $(ftasks)
CLEANFILES = $(ftasks:=.f)
EXTRA_DIST = $(ftasks:=.for)

noinst_HEADERS = clfind.h clpars.h clplot.h clstats.h hermes.h \
  imblob.h imdiff.h imfit.h imhist.h imsad.h imsad2.h imspec.h \
  imstat.h maths.h maxfld.h mfspin.h psrbl.h psrfix.h velplot.h 

dist-hook:
	-rm -f $(distdir)/*.f

DOCINPUTS = $(EXTRA_DIST)
include $(top_srcdir)/mirdoc.mak
