include $(top_srcdir)/mircommon.mak

bin_PROGRAMS = antconv bee blcal bldelay calapply calboot calfit \
  calflag calflux calib callist calmake calplot fitgains gapply \
  gfiddle gmakes gpaver gpboot gpbreak gpbuddy gpcal gpcopy gpedit \
  gperror gplist gpnorm gpplt gpscal gpshift linecal listpol \
  mfcal mselfcal panda passfit passmake pcal selfcal tgains tmcal \
  tmcvt tmgen tpgains uvpflag wvcal xyphase

AM_CFLAGS = @x_cflags@
AM_FFLAGS = @no_globals@
LDADD = $(prog_libs)

BUILT_SOURCES = antconv.f bee.f blcal.f bldelay.f calapply.f calboot.f \
  calfit.f calflag.f calflux.f calib.f callist.f calmake.f calplot.f \
  fitgains.f gapply.f gfiddle.f gmakes.f gpaver.f gpboot.f gpbreak.f \
  gpbuddy.f gpcal.f gpcopy.f gpedit.f gperror.f gplist.f gpnorm.f gpplt.f gpscal.f \
  gpshift.f linecal.f listpol.f mfcal.f mselfcal.f panda.f passfit.f passmake.f \
  pcal.f selfcal.f tgains.f tmcal.f tmcvt.f tmgen.f tpgains.f uvpflag.f \
  wvcal.f xyphase.f

CLEANFILES = $(BUILT_SOURCES)

noinst_HEADERS = bee.h blcal.h gfiddle.h gmakes.h gpcal.h gplist.h \
  gpplt.h gpscal.h mfcal.h mselfcal.h panda.h selfcal.h tmcvt.h

EXTRA_DIST = antconv.for bee.for blcal.for bldelay.for calapply.for \
  calboot.for calfit.for calflag.for calflux.for calib.for callist.for \
  calmake.for calplot.for fitgains.for gapply.for gfiddle.for gmakes.for \
  gpaver.for gpboot.for gpbreak.for gpbuddy.for gpcal.for gpcopy.for gpedit.for \
  gperror.for gplist.for gpnorm.for gpplt.for gpscal.for gpshift.for \
  linecal.for listpol.for mfcal.for mselfcal.for panda.for passfit.for passmake.for \
  pcal.for selfcal.for tgains.for tmcal.for tmcvt.for tmgen.for \
  tpgains.for uvpflag.for wvcal.for xyphase.for

nodist_antconv_SOURCES = antconv.f
nodist_bee_SOURCES = bee.f
nodist_blcal_SOURCES = blcal.f
nodist_bldelay_SOURCES = bldelay.f
nodist_calapply_SOURCES = calapply.f
nodist_calboot_SOURCES = calboot.f
nodist_calfit_SOURCES = calfit.f
nodist_calflag_SOURCES = calflag.f
nodist_calflux_SOURCES = calflux.f
nodist_calib_SOURCES = calib.f
nodist_callist_SOURCES = callist.f
nodist_calmake_SOURCES = calmake.f
nodist_calplot_SOURCES = calplot.f
nodist_fitgains_SOURCES = fitgains.f
nodist_gapply_SOURCES = gapply.f
nodist_gfiddle_SOURCES = gfiddle.f
nodist_gmakes_SOURCES = gmakes.f
nodist_gpaver_SOURCES = gpaver.f
nodist_gpboot_SOURCES = gpboot.f
nodist_gpbreak_SOURCES = gpbreak.f
nodist_gpbuddy_SOURCES = gpbuddy.f
nodist_gpcal_SOURCES = gpcal.f
nodist_gpcopy_SOURCES = gpcopy.f
nodist_gpedit_SOURCES = gpedit.f
nodist_gperror_SOURCES = gperror.f
nodist_gplist_SOURCES = gplist.f
nodist_gpnorm_SOURCES = gpnorm.f
nodist_gpplt_SOURCES = gpplt.f
nodist_gpscal_SOURCES = gpscal.f
nodist_gpshift_SOURCES = gpshift.f
nodist_linecal_SOURCES = linecal.f
nodist_listpol_SOURCES = listpol.f
nodist_mfcal_SOURCES = mfcal.f
nodist_mselfcal_SOURCES = mselfcal.f
nodist_panda_SOURCES = panda.f
nodist_passfit_SOURCES = passfit.f
nodist_passmake_SOURCES = passmake.f
nodist_pcal_SOURCES = pcal.f
nodist_selfcal_SOURCES = selfcal.f
nodist_tgains_SOURCES = tgains.f
nodist_tmcal_SOURCES = tmcal.f
nodist_tmcvt_SOURCES = tmcvt.f
nodist_tmgen_SOURCES = tmgen.f
nodist_tpgains_SOURCES = tpgains.f
nodist_uvpflag_SOURCES = uvpflag.f
nodist_wvcal_SOURCES = wvcal.f
nodist_xyphase_SOURCES = xyphase.f

DOCINPUTS = $(EXTRA_DIST)
include $(top_srcdir)/mirdoc.mak
