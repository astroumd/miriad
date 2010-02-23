## -*- makefile-automake -*-
##
## Define a variable DOCINPUTS before including this Makefile
## fragment. It should list all of the files that are to be
## processed by the doc program.
##
## You can also define DOCFLAGS to give extra flags to pass to
## the doc program. This will almost never be necessary.

DOCSTAMPS = $(DOCINPUTS:=_ds)

%.for_ds: %.for $(doc_prog)
	@echo Generating docs from $< ...
	@cat=`pwd`/$(doc_catsrc) ; \
	doc=`pwd`/$(doc_prog) ; \
	input=`pwd`/$< ; \
	$(mkdir_p) docwork ; \
	(cd docwork && MIRCAT=$$cat $$doc -p $(DOCFLAGS) $$input) && \
	touch $@

%.f2c_ds: %.f2c $(doc_prog)
	@echo Generating docs from $< ...
	@cat=`pwd`/$(doc_catsrc) ; \
	doc=`pwd`/$(doc_prog) ; \
	input=`pwd`/$< ; \
	$(mkdir_p) docwork ; \
	(cd docwork && MIRCAT=$$cat $$doc -p $(DOCFLAGS) $$input) && \
	touch $@

%.c_ds: %.c $(doc_prog)
	@echo Generating docs from $< ...
	@cat=`pwd`/$(doc_catsrc) ; \
	doc=`pwd`/$(doc_prog) ; \
	input=`pwd`/$< ; \
	$(mkdir_p) docwork ; \
	(cd docwork && MIRCAT=$$cat $$doc -p $(DOCFLAGS) $$input) && \
	touch $@

%.f_ds: %.f $(doc_prog)
	@echo Generating docs from $< ...
	@cat=`pwd`/$(doc_catsrc) ; \
	doc=`pwd`/$(doc_prog) ; \
	input=`pwd`/$< ; \
	$(mkdir_p) docwork ; \
	(cd docwork && MIRCAT=$$cat $$doc -p $(DOCFLAGS) $$input) && \
	touch $@

# This is needed for src/tools. Sigh.

%.clone_ds: %.clone $(doc_prog)
	@echo Generating docs from $< ...
	@cat=`pwd`/$(doc_catsrc) ; \
	doc=`pwd`/$(doc_prog) ; \
	input=`pwd`/$< ; \
	$(mkdir_p) docwork ; \
	(cd docwork && MIRCAT=$$cat $$doc -p $(DOCFLAGS) $$input) && \
	touch $@

# Silently do nothing for these. Lets us be a bit more liberal in what
# we say DOCINPUTS is in our Makefile.am's.

.h.h_ds:
	@touch $@

.inc.inc_ds:
	@touch $@

# Need a rule for how to build this ...

$(doc_prog):
	$(MAKE) -C $(dir $@) $(notdir $@)

# Hooking up all the rules ...

all-local: $(DOCSTAMPS)

install-data-hook:
	$(mkdir_p) "$(DESTDIR)$(sdocdir)"
	$(mkdir_p) "$(DESTDIR)$(pdocdir)"
	for f in docwork/* ; do \
	  if echo "$$f" |$(EGREP) '\*' 1>/dev/null 2>&1; then \
	    : ; \
	  elif echo "$$f" |$(EGREP) '\.sdoc' 1>/dev/null 2>&1; then \
	    echo $(INSTALL_DATA) "$$f" "$(DESTDIR)$(sdocdir)" ; \
	    $(INSTALL_DATA) "$$f" "$(DESTDIR)$(sdocdir)" ; \
	  else \
	    echo $(INSTALL_DATA) "$$f" "$(DESTDIR)$(pdocdir)" ; \
	    $(INSTALL_DATA) "$$f" "$(DESTDIR)$(pdocdir)" ; \
	  fi ; \
	done

clean-local:
	rm -rf docwork 
	rm -f $(DOCSTAMPS)
