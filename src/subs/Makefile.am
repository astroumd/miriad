include $(top_srcdir)/mircommon.mak

## Deliberately excluding the following, because they don't
## even compile in the old miriad install...
## args.for ivfiddle.f ivmenu.f ivofm.f ivtext.f

## Note, dirs.c removed from list, deprecated, no more VMS
## support..

finclude_HEADERS = model.h

includes = -I$(top_builddir)/src/inc -I$(top_srcdir)/src/inc -I$(srcdir)

lib_LTLIBRARIES = \
  libmir_uvio.la \
  libmir.la

libmir_uvio_la_SOURCES = bug.c dio.c headio.c hio.c \
  interface.c jplread.c key.c maskio.c mir_io.c pack.c \
  scrio.c sma_csub.c sma_mirRead.c tabio.c uvio.c xyio.c \
  xyzio.c
libmir_uvio_la_CFLAGS = $(includes) @single_module@

libmir_la_CFLAGS = $(includes)
libmir_la_LDFLAGS = -dynamic @single_module@

AM_FFLAGS = @no_globals@

## argsHP.for compiles and links on Mac OS X, but not linux...
## should it stay in for Mac OS ?

nodist_libmir_la_SOURCES = \
  align.f amphase.f angles.f antennas.f \
  ari.f assert.f atjones.f axistype.f basant.f bessel.f \
  boxes.f bsrch.f btype.f calio.f callinp.f calphase.f \
  calpoly.f calsetio.f calstoke.f calsubs.f cgpgsubs.f \
  cgsubs.f cnvl.f co.f convl.f cosubs.f ctrl.f defsmodl.f \
  deghms.f ephem.f expun.f fftsubs.f fitsio.f fndaxnum.f \
  fullname.f gamma.f gaupar.f getbeam.f getfreq.f getpb.f \
  getxy.f grid.f gsubs.f hann.f hdtab.f headcopy.f \
  hisinput.f hsort.f imminmax.f inc.f intpio.f iscoords.f \
  j1xbyx.f julday.f \
  keyf.f keyline.f lagwt.f linetype.f log.f lsearch.f lsf.f \
  lspoly.f lsqfit.f lsqu.f lsqu1.f mapper.f match.f math.f \
  mc.f medfit.f median.f mem.f model.f modp.f mostab.f \
  nearest.f nextpow2.f nllsqu.f noise.f nswc.f numbpg.f \
  obspar.f ofm.f options.f pb.f pcvt.f pghline.f pkfit.f \
  plane.f planet.f plotone.f plproc.f pols.f poly.f \
  polyfit.f powell.f prime.f promptf.f r8tyx.f refract.f \
  rest.f rtfmt.f select.f sfetra.f shadowed.f si.f \
  sma_fsubs.f sort.f sortidx.f spaxsw.f spline.f strf.f \
  string.f tabflux.f tangle.f tin.f title.f trans.f trnio.f \
  tv.f tvsubs.f txtio.f utilities.f uvdat.f uvfitsubs.f \
  uvgetbl.f uvgn.f uvsubs.f var.f varmint.f velocity.f versan.f \
  win.f wpfit.f zed.f zeebin.f \
  bugwrap.c iface.c keywrap.c mirwrap.c mm.c oscalls.c \
  packwrap.c smawrap.c tabiowrap.c tcpio.c wrap.c xyziowrap.c

dist_libmir_la_SOURCES = \
  boxes.h co.h ctrl.h fitsio.h hdtab.h hio.h intpio.h io.h \
  log.h mapper.h mc.h miriad.h model.h modp.h mostab.h \
  obspar.h ofm.h pb.h pcvt.h plproc.h rest.h select.h \
  sma_data.h sysdep.h tabflux.h tin.h trnio.h tv.h uvdat.h \
  uvgn.h win.h

EXTRA_DIST = \
  align.for amphase.for angles.for antennas.for \
  ari.for assert.for atjones.for axistype.for basant.for bessel.for \
  boxes.for bsrch.for btype.for calio.for callinp.for calphase.for \
  calpoly.for calsetio.for calstoke.for calsubs.for cgpgsubs.for \
  cgsubs.for cnvl.for co.for convl.for cosubs.for ctrl.for defsmodl.for \
  deghms.for ephem.for expun.for fftsubs.for fitsio.for fndaxnum.for \
  fullname.for gamma.for gaupar.for getbeam.for getfreq.for getpb.for \
  getxy.for grid.for gsubs.for hann.for hdtab.for headcopy.for \
  hisinput.for hsort.for imminmax.for inc.for intpio.for iscoords.for \
  j1xbyx.for julday.for \
  keyf.for keyline.for lagwt.for linetype.for log.for lsearch.for lsf.for \
  lspoly.for lsqfit.for lsqu.for lsqu1.for mapper.for match.for math.for \
  mc.for medfit.for median.for mem.for model.for modp.for mostab.for \
  nearest.for nextpow2.for nllsqu.for noise.for nswc.for numbpg.for \
  obspar.for ofm.for options.for pb.for pcvt.for pghline.for pkfit.for \
  plane.for planet.for plotone.for plproc.for pols.for poly.for \
  polyfit.for powell.for prime.for promptf.for r8tyx.for refract.for \
  rest.for rtfmt.for select.for sfetra.for shadowed.for si.for \
  sma_fsubs.for sort.for sortidx.for spaxsw.for spline.for strf.for \
  string.for tabflux.for tangle.for tin.for title.for trans.for trnio.for \
  tv.for tvsubs.for txtio.for utilities.for uvdat.for uvfitsubs.for \
  uvgetbl.for uvgn.for uvsubs.for var.for varmint.for velocity.for versan.for \
  win.for wpfit.for zed.for zeebin.for \
  bugwrap.f2c iface.f2c keywrap.f2c mirwrap.f2c mm.f2c oscalls.f2c \
  packwrap.f2c smawrap.f2c tabiowrap.f2c tcpio.f2c wrap.f2c xyziowrap.f2c \
  boxes.h co.h ctrl.h fitsio.h hdtab.h hio.h intpio.h io.h \
  log.h mapper.h mc.h miriad.h model.h modp.h mostab.h \
  obspar.h ofm.h pb.h pcvt.h plproc.h rest.h select.h \
  sma_data.h sysdep.h tabflux.h tin.h trnio.h tv.h uvdat.h \
  uvgn.h win.h 

cinclude_HEADERS = hio.h io.h miriad.h sma_data.h sysdep.h

CLEANFILES = $(nodist_libmir_la_SOURCES)

## The inc files should probably end up in the top-level Makefile.am
## because they're part of the overall package/sortof API
## But since this is the primary library and it's built early on, they're
## here for now.

DOCINPUTS = $(EXTRA_DIST) $(libmir_uvio_la_SOURCES)
include $(top_srcdir)/mirdoc.mak
