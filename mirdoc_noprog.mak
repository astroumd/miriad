## -*- makefile-automake -*-
##
## Include mirdoc.mak unless you're in src/tools/.
##
## Define a variable DOCINPUTS before including this Makefile
## fragment. It should list all of the files that are to be
## processed by the doc program.
##
## You can also define DOCFLAGS to give extra flags to pass to
## the doc program. This will almost never be necessary.

DOCSTAMPS = $(DOCINPUTS:=_ds)

%.for_ds: %.for $(doc_prog)
	$(AM_V_GEN)cat=`pwd`/$(doc_catsrc) ; \
	doc=`pwd`/$(doc_prog) ; \
	input=`pwd`/$< ; \
	$(mkdir_p) docwork ; \
	(cd docwork && MIRCAT=$$cat $$doc -p $(DOCFLAGS) $$input) && \
	touch $@

%.f2c_ds: %.f2c $(doc_prog)
	$(AM_V_GEN)cat=`pwd`/$(doc_catsrc) ; \
	doc=`pwd`/$(doc_prog) ; \
	input=`pwd`/$< ; \
	$(mkdir_p) docwork ; \
	(cd docwork && MIRCAT=$$cat $$doc -p $(DOCFLAGS) $$input) && \
	touch $@

%.c_ds: %.c $(doc_prog)
	$(AM_V_GEN)cat=`pwd`/$(doc_catsrc) ; \
	doc=`pwd`/$(doc_prog) ; \
	input=`pwd`/$< ; \
	$(mkdir_p) docwork ; \
	(cd docwork && MIRCAT=$$cat $$doc -p $(DOCFLAGS) $$input) && \
	touch $@

%.f_ds: %.f $(doc_prog)
	$(AM_V_GEN)cat=`pwd`/$(doc_catsrc) ; \
	doc=`pwd`/$(doc_prog) ; \
	input=`pwd`/$< ; \
	$(mkdir_p) docwork ; \
	(cd docwork && MIRCAT=$$cat $$doc -p $(DOCFLAGS) $$input) && \
	touch $@

# This is needed for scripts. Sigh.

%.clone_ds: %.clone $(doc_prog)
	$(AM_V_GEN)cat=`pwd`/$(doc_catsrc) ; \
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

# Hooking up all the rules ...

all-local: $(DOCSTAMPS)

install-data-local:
	$(mkdir_p) "$(DESTDIR)$(sdocdir)"
	$(mkdir_p) "$(DESTDIR)$(pdocdir)"
	if test "`echo docwork/*.sdoc`" = 'docwork/*.sdoc'; then \
	  : ; \
	else \
	  echo $(INSTALL_DATA) docwork/*.sdoc "$(DESTDIR)$(sdocdir)" ; \
	  $(INSTALL_DATA) docwork/*.sdoc "$(DESTDIR)$(sdocdir)" ; \
	fi
	for ext in doc cdoc tdoc kdoc ; do \
	  if test "`echo docwork/*.$$ext`" = 'docwork/*.'$$ext ; then \
	    : ; \
	  else \
	    echo $(INSTALL_DATA) docwork/*.$$ext "$(DESTDIR)$(pdocdir)" ; \
	    $(INSTALL_DATA) docwork/*.$$ext "$(DESTDIR)$(pdocdir)" ; \
	  fi ; \
	done

clean-local:
	rm -rf docwork 
	rm -f $(DOCSTAMPS)
