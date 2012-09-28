## -*- makefile-automake -*-
##
## We want a rule to build the doc program since all of the
## doc-building depends on it. Inside src/tools/, however, the lack of
## dependencies in the rule below messes up highly parallel builds. So
## we keep the rule separate so that src/tools/ can include the logic
## without getting busted.

include $(top_srcdir)/mirdoc_noprog.mak

$(doc_prog):
	$(MAKE) -C $(dir $@) $(notdir $@)
