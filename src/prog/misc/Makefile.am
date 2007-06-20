##
## $Id$
##

RATTY=../../tools/ratty

.for.f:
	$(RATTY) -I ../../inc $< $@

bin_PROGRAMS = addhis atmosph calc copyhd corset cotra delhd design dwell gethd hex itemize j2000 julian listobs mathd mfplan moslst obsrms obstau planets pnt pntgen prthd prthis puthd remove rmdata rmsfit sinbad sinpoly solar tac taco telepar warpfit xcorr xfcor

AM_CFLAGS = $CFLAGS @x_cflags@
AM_FFLAGS = @no_globals@
AM_LDFLAGS = -L../../subs -L../../../borrow/linpack
LDADD = -lmir_uvio -lmir_linpack -lmir $(PGPLOT_LIB) @x_libs@

BUILT_SOURCES = addhis.f atmosph.f calc.f copyhd.f corset.f cotra.f delhd.f design.f dwell.f gethd.f hex.f itemize.f j2000.f julian.f listobs.f mathd.f mfplan.f moslst.f obsrms.f obstau.f planets.f pnt.f pntgen.f prthd.f prthis.f puthd.f remove.f rmdata.f rmsfit.f sinbad.f sinpoly.f solar.f tac.f taco.f telepar.f warpfit.f xcorr.f xfcor.f

noinst_HEADERS = atmosph.h calc.h design.h listobs.h mathd.h pnt.h sinpoly.h

EXTRA_DIST = addhis.for atmosph.for calc.for copyhd.for corset.for cotra.for delhd.for design.for dwell.for gethd.for hex.for itemize.for j2000.for julian.for listobs.for mathd.for mfplan.for moslst.for obsrms.for obstau.for planets.for pnt.for pntgen.for prthd.for prthis.for puthd.for remove.for rmdata.for rmsfit.for sinbad.for sinpoly.for solar.for tac.for taco.for telepar.for warpfit.for xcorr.for xfcor.for

nodist_addhis_SOURCES = addhis.f
nodist_atmosph_SOURCES = atmosph.f
nodist_calc_SOURCES = calc.f
nodist_copyhd_SOURCES = copyhd.f
nodist_corset_SOURCES = corset.f
nodist_cotra_SOURCES = cotra.f
nodist_delhd_SOURCES = delhd.f
nodist_design_SOURCES = design.f
nodist_dwell_SOURCES = dwell.f
nodist_gethd_SOURCES = gethd.f
nodist_hex_SOURCES = hex.f
nodist_itemize_SOURCES = itemize.f
nodist_j2000_SOURCES = j2000.f
nodist_julian_SOURCES = julian.f
nodist_listobs_SOURCES = listobs.f
nodist_mathd_SOURCES = mathd.f
nodist_mfplan_SOURCES = mfplan.f
nodist_moslst_SOURCES = moslst.f
nodist_obsrms_SOURCES = obsrms.f
nodist_obstau_SOURCES = obstau.f
nodist_planets_SOURCES = planets.f
nodist_pnt_SOURCES = pnt.f
nodist_pntgen_SOURCES = pntgen.f
nodist_prthd_SOURCES = prthd.f
nodist_prthis_SOURCES = prthis.f
nodist_puthd_SOURCES = puthd.f
nodist_remove_SOURCES = remove.f
nodist_rmdata_SOURCES = rmdata.f
nodist_rmsfit_SOURCES = rmsfit.f
nodist_sinbad_SOURCES = sinbad.f
nodist_sinpoly_SOURCES = sinpoly.f
nodist_solar_SOURCES = solar.f
nodist_tac_SOURCES = tac.f
nodist_taco_SOURCES = taco.f
nodist_telepar_SOURCES = telepar.f
nodist_warpfit_SOURCES = warpfit.f
nodist_xcorr_SOURCES = xcorr.f
nodist_xfcor_SOURCES = xfcor.f
