#	Make all CERN-distributed WWW products
#
#	The local products are built using machine-specific
#	makefiles where they exist; the X products use xmkmf
#	and soft links to the sources in the source directories.
#
#	This master Makefile contains the inter-product dependecies
#	needed for a first build. I checks that the needed subproducts exist,
#	it does not check they are internally up-to-date.
#
# Weirdities:
#	*** On sgi and decstation SHELL can be set to /bin/csh which not
#	only screws up sh-isms in makefiles, but seems to override a setting
#	of SHELL in the Makefile itself.
#       *** BSD unix didn't have .include in make for someone, so
#	     we cat makefiles together. ALso gets round screwed up
#		relative filenames on include in OSF1 and NeXT makes.
#	*** decstation/GNUmake: Doesn't like an "if [ ...] then ... ; fi" because if
#	the "if" fails, error code 1 is returned, which stops the make. Funny sh?
#	Anyway, we put in "else echo OK ;" clauses for this.
#
# Pick up machine-specific bits:

include ../../All/$(WWW_MACH)/Makefile.include

#	These are the subproducts:

LIBRARY = $(WTMP)/Library/$(WWW_MACH)/libwww.a
LINEMODE = $(WWW)/LineMode/$(WWW_MACH)/www
DAEMON  = $(WWW)/Daemon/$(WWW_MACH)/httpd
VIOLA = $(WWW)/Viola/$(WWW_MACH)/viola
XPA = $(WWW)/XPA/$(WWW_MACH)/libXpa.a
XPM = $(WWW)/XPM/$(WWW_MACH)/libXpm.a
MIDAS = $(WWW)/MidasWWW/$(WWW_MACH)/midaswww

# Tools sometimes not available with X:
XMKMF = $(WWW)/Tools/bin/xmkmf
LNXMAKE = $(WWW)/Tools/bin/lnxmake

#	Default target -- remove things you don't want
#all : $(LIBRARY) $(LINEMODE) $(DAEMON)
#	echo done

#	Default build does full make
all :
	if [ ! -r $(WWW)/Library/$(WWW_MACH) ] ; then mkdir $(WWW)/Library/$(WWW_MACH); else echo OK; fi
	cat $(WWW)/All/$(WWW_MACH)/Makefile.include \
		$(WWW)/Library/Implementation/CommonMakefile >! \
		$(WWW)/Library/$(WWW_MACH)/Makefile;
	(cd $(WWW)/Library/$(WWW_MACH); make)
	if [ ! -r $(WWW)/LineMode/$(WWW_MACH) ] ; then mkdir $(WWW)/LineMode/$(WWW_MACH); else echo OK; fi
	cat $(WWW)/All/$(WWW_MACH)/Makefile.include \
		$(WWW)/LineMode/Implementation/CommonMakefile >! \
		$(WWW)/LineMode/$(WWW_MACH)/Makefile;
	(cd $(WWW)/LineMode/$(WWW_MACH); make)
	if [ ! -r $(WWW)/Daemon/$(WWW_MACH) ] ; then mkdir $(WWW)/Daemon/$(WWW_MACH);  else echo OK; fi
	cat $(WWW)/All/$(WWW_MACH)/Makefile.include \
		$(WWW)/Daemon/Implementation/CommonMakefile >! \
		$(WWW)/Daemon/$(WWW_MACH)/Makefile;
	(cd $(WWW)/Daemon/$(WWW_MACH); make)

daemon : $(DAEMON)
	echo done

others : $(VIOLA) $(MIDAS) 
	echo done

$(LIBRARY) :
	if [ ! -r $(WWW)/Library/$(WWW_MACH) ] ; then mkdir $(WWW)/Library/$(WWW_MACH); else echo OK; fi
	cat $(WWW)/All/$(WWW_MACH)/Makefile.include \
		$(WWW)/Library/Implementation/CommonMakefile >! \
		$(WWW)/Library/$(WWW_MACH)/Makefile;
	(cd $(WWW)/Library/$(WWW_MACH); make)


$(LINEMODE) : $(LIBRARY)
	if [ ! -r $(WWW)/LineMode/$(WWW_MACH) ] ; then mkdir $(WWW)/LineMode/$(WWW_MACH); else echo OK; fi
	cat $(WWW)/All/$(WWW_MACH)/Makefile.include \
		$(WWW)/LineMode/Implementation/CommonMakefile >! \
		$(WWW)/LineMode/$(WWW_MACH)/Makefile;
	(cd $(WWW)/LineMode/$(WWW_MACH); make)

$(DAEMON) : $(LIBRARY)
	if [ ! -r $(WWW)/Daemon/$(WWW_MACH) ] ; then mkdir $(WWW)/Daemon/$(WWW_MACH); else echo OK; fi
	cat $(WWW)/All/$(WWW_MACH)/Makefile.include \
		$(WWW)/Daemon/Implementation/CommonMakefile >! \
		$(WWW)/Daemon/$(WWW_MACH)/Makefile;
	(cd $(WWW)/Daemon/$(WWW_MACH); make)

$(VIOLA) : $(XPA) $(XPM) $(LIBRARY)
	-mkdir $(WWW)/Viola/$(WWW_MACH)
	(cd $(WWW)/Viola/$(WWW_MACH); $(LNXMAKE))

$(XPM) :
	-mkdir $(WWW)/XPM/$(WWW_MACH)
	(cd $(WWW)/XPM/$(WWW_MACH); $(LNXMAKE))

$(XPA) :
	-mkdir $(WWW)/XPA/$(WWW_MACH)
	(cd $(WWW)/XPA/$(WWW_MACH); $(LNXMAKE))

$(MIDAS) :
	-mkdir $(WWW)/MidasWWW/$(WWW_MACH)
	(cd $(WWW)/MidasWWW/$(WWW_MACH); $(LNXMAKE))
