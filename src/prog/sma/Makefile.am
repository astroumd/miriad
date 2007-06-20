##
## $Id$
##

include $(top_srcdir)/mircommon.mak

bin_PROGRAMS = gildas phatrans schedobs smablflag smablsrc smacheck smachunkglue smafix smaflux smagpplt smalod smamfcal smarewt smatbpass smauvamp smauvplt smauvspec smavarfit smavarplt uvsort vel2fel

AM_CFLAGS = @x_cflags@
AM_FFLAGS = @no_globals@
AM_LDFLAGS = -L../../subs -L../../../borrow/linpack
LDADD = -lmir_uvio -lmir_linpack -lmir $(PGPLOT_LIB) @x_libs@

BUILT_SOURCES = gildas.f phatrans.f schedobs.f smablflag.f smablsrc.f smacheck.f smachunkglue.f smafix.f smaflux.f smagpplt.f smalod.f smamfcal.f smarewt.f smatbpass.f smauvamp.f smauvplt.f smauvspec.f smavarfit.f smavarplt.f uvsort.f vel2fel.f

noinst_HEADERS = gildas.h smablflag.h smablsrc.h smagpplt.h smatbpass.h smauvspec.h uvsort.h

EXTRA_DIST = gildas.for phatrans.for schedobs.for smablflag.for smablsrc.for smacheck.for smachunkglue.for smafix.for smaflux.for smagpplt.for smalod.for smamfcal.for smarewt.for smatbpass.for smauvamp.for smauvplt.for smauvspec.for smavarfit.for smavarplt.for uvsort.for vel2fel.for

nodist_gildas_SOURCES = gildas.f
nodist_phatrans_SOURCES = phatrans.f
nodist_schedobs_SOURCES = schedobs.f
nodist_smablflag_SOURCES = smablflag.f
nodist_smablsrc_SOURCES = smablsrc.f
nodist_smacheck_SOURCES = smacheck.f
nodist_smachunkglue_SOURCES = smachunkglue.f
nodist_smafix_SOURCES = smafix.f
nodist_smaflux_SOURCES = smaflux.f
nodist_smagpplt_SOURCES = smagpplt.f
nodist_smalod_SOURCES = smalod.f
nodist_smamfcal_SOURCES = smamfcal.f
nodist_smarewt_SOURCES = smarewt.f
nodist_smatbpass_SOURCES = smatbpass.f
nodist_smauvamp_SOURCES = smauvamp.f
nodist_smauvplt_SOURCES = smauvplt.f
nodist_smauvspec_SOURCES = smauvspec.f
nodist_smavarfit_SOURCES = smavarfit.f
nodist_smavarplt_SOURCES = smavarplt.f
nodist_uvsort_SOURCES = uvsort.f
nodist_vel2fel_SOURCES = vel2fel.f
