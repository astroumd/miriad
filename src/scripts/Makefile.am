include $(top_srcdir)/mircommon.mak

bin_SCRIPTS = antpat autocal beam beamcheck beamgen beamgen2 \
  debug fringemap mbackup mir.bug.csh mir-config mirds9 mir.find mir.help \
  mir.index mirpgmr mirprogd mirsao mir.sndex mirsubsd mirtng \
  mirupdate mosaical mrc passcal pbcorr plot_swflux.py polcal \
  replicate robust.csh runmiriad smoothtobm uvshadow

EXTRA_DIST = $(bin_SCRIPTS) beamgen2.wip

# Documentation. We do some gross stuff here because portable make
# pattern matching rules are constrained to files with extensions in
# their names, and the above source files mostly don't have
# extensions. Bummer. Another side effect of this fact is that we give
# doc the -e flag here, which makes it not try to guess what to do with
# the input file based on its extension.

DOCINPUTS = $(bin_SCRIPTS:=.clone)
DOCFLAGS = -e

include $(top_srcdir)/mirdoc.mak

antpat.clone: antpat
	$(LN_S) $< $@
autocal.clone: autocal
	$(LN_S) $< $@
beam.clone: beam
	$(LN_S) $< $@
beamcheck.clone: beamcheck
	$(LN_S) $< $@
beamgen.clone: beamgen
	$(LN_S) $< $@
beamgen2.clone: beamgen2
	$(LN_S) $< $@
debug.clone: debug
	$(LN_S) $< $@
fringemap.clone: fringemap
	$(LN_S) $< $@
mbackup.clone: mbackup
	$(LN_S) $< $@
mir.bug.csh.clone: mir.bug.csh
	$(LN_S) $< $@
mir-config.clone: mir-config
	$(LN_S) $< $@
mirds9.clone: mirds9
	$(LN_S) $< $@
mir.find.clone: mir.find
	$(LN_S) $< $@
mir.help.clone: mir.help
	$(LN_S) $< $@
mir.index.clone: mir.index
	$(LN_S) $< $@
mirpgmr.clone: mirpgmr
	$(LN_S) $< $@
mirprogd.clone: mirprogd
	$(LN_S) $< $@
mirsao.clone: mirsao
	$(LN_S) $< $@
mir.sndex.clone: mir.sndex
	$(LN_S) $< $@
mirsubsd.clone: mirsubsd
	$(LN_S) $< $@
mirtng.clone: mirtng
	$(LN_S) $< $@
mirupdate.clone: mirupdate
	$(LN_S) $< $@
mosaical.clone: mosaical
	$(LN_S) $< $@
mrc.clone: mrc
	$(LN_S) $< $@
passcal.clone: passcal
	$(LN_S) $< $@
pbcorr.clone: pbcorr
	$(LN_S) $< $@
plot_swflux.py.clone: plot_swflux.py
	$(LN_S) $< $@
polcal.clone: polcal
	$(LN_S) $< $@
replicate.clone: replicate
	$(LN_S) $< $@
robust.csh.clone: robust.csh
	$(LN_S) $< $@
runmiriad.clone: runmiriad
	$(LN_S) $< $@
smoothtobm.clone: smoothtobm
	$(LN_S) $< $@
uvshadow.clone: uvshadow
	$(LN_S) $< $@
