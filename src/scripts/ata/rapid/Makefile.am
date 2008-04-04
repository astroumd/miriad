include $(top_srcdir)/mircommon.mak

bin_SCRIPTS = automap.csh calcal.csh crosscal.csh crossmap.csh \
	eprms.csh quickrfi.csh rfisweep.csh rfisweep.wip rfi.wip rfisou.wip

# Documentation. We do some gross stuff here because portable make
# pattern matching rules are constrained to files with extensions in
# their names, and the above source files mostly don't have
# extensions. Bummer. Another side effect of this fact is that we give
# doc the -e flag here, which makes it not try to guess what to do with
# the input file based on its extension.

DOCINPUTS = $(bin_SCRIPTS:=.clone)
DOCFLAGS = -e

include $(top_srcdir)/mirdoc.mak

automap.csh.clone: automap.csh
	$(LN_S) $< $@
calcal.csh.clone: calcal.csh
	$(LN_S) $< $@
crosscal.csh.clone: crosscal.csh
	$(LN_S) $< $@
crossmap.csh.clone: crossmap.csh
	$(LN_S) $< $@
eprms.csh.clone: eprms.csh
	$(LN_S) $< $@
quickrfi.csh.clone: quickrfi.csh
	$(LN_S) $< $@
rfisweep.csh.clone: rfisweep.csh
	$(LN_S) $< $@
rfi.csh.clone: rfi.csh
	$(LN_S) $< $@
rfi32.csh.clone: rfi32.csh
	$(LN_S) $< $@
rfisweep.wip.clone: rfisweep.wip
	$(LN_S) $< $@
rfi.wip.clone: rfi.wip
	$(LN_S) $< $@
rfisou.wip.clone: rfisou.wip
	$(LN_S) $< $@
