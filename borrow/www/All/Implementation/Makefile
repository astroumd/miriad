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

# Need to get rid of includes -- not all the makes support it :-(
# include ../../All/$(WWW_MACH)/Makefile.include

WWW = ../..
WTMP = ../..

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
all :	$(LIBRARY) $(DAEMON) $(LINEMODE)
	@echo BUILD complete!

daemon : $(DAEMON)
	@echo BUILD complete!

linemode : $(LINEMODE)
	@echo BUILD complete!

library : $(LIBRARY)
	@echo BUILD complete!

others : $(VIOLA) $(MIDAS) 
	@echo BUILD complete!

$(LIBRARY) :
	@echo
	@echo '------ Building libwww ------'
	@echo
	@echo Object files of libwww will go to directory Library/$(WWW_MACH)
	@if [ ! -r $(WWW)/Library/$(WWW_MACH) ] ; \
	then	echo "	- creating"; \
		mkdir $(WWW)/Library/$(WWW_MACH); \
	else	echo "	- already exists"; \
	fi
	@echo
	@cat	$(WWW)/All/$(WWW_MACH)/Makefile.include \
		$(WWW)/Library/Implementation/Version.make \
		$(WWW)/Library/Implementation/CommonMakefile > \
		$(WWW)/Library/$(WWW_MACH)/Makefile;
	@(cd $(WWW)/Library/$(WWW_MACH); make)
	@echo
	@echo libwww compiled successfully and can be found in Library/$(WWW_MACH)
	@echo
	@echo Have fun! If you have any problems with this software feel free to
	@echo contact libwww@info.cern.ch.  Online documentation is available via
	@echo the URL: http://info.cern.ch/hypertext/WWW/Library/Status.html

$(LINEMODE) : $(LIBRARY)
	@echo
	@echo '------ Building CERN LineMode Browser ------'
	@echo
	@echo Object files and executable binary will go to directory LineMode/$(WWW_MACH)
	@if [ ! -r $(WWW)/LineMode/$(WWW_MACH) ] ; \
	then	echo "	- creating"; \
		mkdir $(WWW)/LineMode/$(WWW_MACH); \
	else	echo "	- already exists"; \
	fi
	@echo
	@cat	$(WWW)/All/$(WWW_MACH)/Makefile.include \
		$(WWW)/LineMode/Implementation/Version.make \
		$(WWW)/LineMode/Implementation/CommonMakefile > \
		$(WWW)/LineMode/$(WWW_MACH)/Makefile;
	@(cd $(WWW)/LineMode/$(WWW_MACH); make)
	@echo
	@echo LineMode browser built successfully and can be found in LineMode/$(WWW_MACH)
	@echo
	@echo
	@echo Have fun! If you have any problems with this software feel free to
	@echo contact www-bug@info.cern.ch.  Online documentation is available via
	@echo the URL: http://info.cern.ch/hypertext/WWW/LineMode/Status.html
	@echo

$(DAEMON) : $(LIBRARY)
	@echo
	@echo '------ Now building CERN httpd, htadm, htimage, cgiparse, cgiutils ------'
	@echo
	@echo Object files and binaries will go to directory Daemon/$(WWW_MACH)
	@if [ ! -r $(WWW)/Daemon/$(WWW_MACH) ] ; \
	then	echo "	- creating"; \
		mkdir $(WWW)/Daemon/$(WWW_MACH); \
	else	echo "	- already exists"; \
	fi
	@echo
	@cat	$(WWW)/All/$(WWW_MACH)/Makefile.include \
		$(WWW)/Daemon/Implementation/Version.make \
		$(WWW)/Daemon/Implementation/CommonMakefile > \
		$(WWW)/Daemon/$(WWW_MACH)/Makefile;
	@(cd $(WWW)/Daemon/$(WWW_MACH); make)
	@echo
	@echo CERN httpd, htadm, htimage, cgiparse and cgiutils built successfully
	@echo and can be found in directory Daemon/$(WWW_MACH).
	@echo
	@echo Have fun! If you have any problems with this software feel free to
	@echo contact httpd@info.cern.ch.  Online documentation is available via
	@echo the URL: http://info.cern.ch/httpd/
	@echo

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

