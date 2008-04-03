include $(top_srcdir)/mircommon.mak

# The mir.scripts script in src/sys/bin just copies every file in
# src/scripts into $bindir, so we don't want to put a Makefile there:
# the Makefile{,.in,.am} will get copied too. We could hack mir.scripts,
# or we could do this:

bin_SCRIPTS = scripts/antpat scripts/autocal scripts/beam \
  scripts/beamcheck scripts/beamgen scripts/beamgen2 scripts/debug \
  scripts/mir.bug.csh scripts/mir-config scripts/mirds9 scripts/mir.find \
  scripts/mir.help scripts/mir.index scripts/mirpgmr scripts/mirprogd \
  scripts/mirsao scripts/mir.sndex scripts/mirsubsd scripts/mirtng \
  scripts/mirupdate scripts/mosaical scripts/mrc scripts/passcal \
  scripts/pbcorr scripts/plot_swflux.py scripts/polcal scripts/replicate \
  scripts/robust.csh scripts/smoothtobm \
  scripts/ata/rapid/automap.csh scripts/ata/rapid/calcal.csh \
  scripts/ata/rapid/crosscal.csh scripts/ata/rapid/crossmap.csh \
  scripts/ata/rapid/eprms.csh scripts/ata/rapid/quickrfi.csh \
  scripts/ata/rapid/rfisweep.csh
