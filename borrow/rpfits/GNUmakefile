#-----------------------------------------------------------------------------
# GNUmakefile: Template GNU makefile for compiling the RPFITS library.
#-----------------------------------------------------------------------------
# The GNU makefile in this directory is intended to be included from another
# GNU makefile (usually in a subdirectory) that contains architecture-specific
# variable definitions for:
#
#    RPFITSROOT ...The RPFITS root directory (i.e. this directory).
#    RPARCH     ...Architecture name (alpha, darwin_ppc, darwin_x86, linux,
#                  linux64, sgi, sun4, sun4sol, etc.) used only for locating
#                  architecture-specific source code, e.g. in ../code/linux/.
#    FC,CC      ...Names of the Fortran and C compilers should be supplied
#                  by GNU make for your system but can also be redefined if
#                  required.
#    FFLAGS     ...Fortran compiler flags.
#    CFLAGS     ...C compiler flags.
#    RANLIB     ...Command used to "ranlib" object libraries (set to ":" if
#                  ranlib is not needed).
#    LDFLAGS    ...Linker flags.
#    PREFIX     ...Install location, e.g. /usr/local; files are actually
#                  installed in $(PREFIX)/{lib,include,bin}.
#
# If you are trying to install the RPFITS library, please chdir to either the
# darwin, linux, linux64, or sun4sol sub-directory and run GNU 'make' from
# there.  You may find it necessary to modify variable definitions (as above)
# in the GNUmakefile there to suit your purposes.
#
# $Id: GNUmakefile,v 1.18 2018/10/29 04:05:51 wie017 Exp $
#-----------------------------------------------------------------------------
ifndef RPFITSROOT
   RPFITSROOT := $(shell pwd)
endif

# Package version
VERS      := 2.25
MAJOR := $(shell echo $(VERS) | sed -e 's/\..*//')
MINOR := $(shell echo $(VERS) | sed -e 's/^.*\.//')

#all:
#	@echo VERS=$(VERS)
#	@echo MAJOR=$(MAJOR)
#	@echo MINOR=$(MINOR)
# Where gmake finds the source code.
COMMSRC := $(RPFITSROOT)/code
ARCHSRC := $(COMMSRC)/$(RPARCH)
TESTSRC := $(RPFITSROOT)/test
VPATH   := .:$(ARCHSRC):$(COMMSRC):$(TESTSRC)

# Include paths etc.
INCLUDES := -I. -I$(ARCHSRC) -I$(COMMSRC)
FFLAGS   += $(INCLUDES)
CFLAGS   += -c $(INCLUDES)

# First check out any new sources.
FIRST  := $(shell $(MAKE) -C $(COMMSRC))

# Lists of object library members.
FSUBS  := $(filter-out *.f, \
            $(notdir \
               $(wildcard ./*.f $(COMMSRC)/*.f $(ARCHSRC)/*.f)))
FOBJS  := $(FSUBS:.f=.o)

CSUBS  := $(filter-out rpfhdr.c rpfex.c *.c, \
            $(notdir \
               $(wildcard ./*.c $(COMMSRC)/*.c $(ARCHSRC)/*.c)))
COBJS  := $(CSUBS:.c=.o)

RPFITSLIB  := librpfits.a
MEMBERS := $(patsubst %,$(RPFITSLIB)(%),$(FOBJS) $(COBJS))

# Shared (dynamic) library  (Copied from WCSLIB's makedefs)
SHRLIB   := librpfits.so.$(VERS)
SONAME   := librpfits.so.$(MAJOR)
SHRFLAGS := -fPIC
SHRLD    := $(CC) $(SHRFLAGS) -shared -Wl,-h$(SONAME)
SHRLN    := librpfits.so
# End Shared (dynamic) library addition

ifndef PREFIX
   PREFIX := /usr/local
endif


# Static rules.
.PRECIOUS : $(RPFITSLIB) $(SHRLIB)
.PHONY : all clean cleaner cleanest lib realclean show test tar

ifeq "$(RPARCH)" ""
all :
	-@ echo ""
	-@ head -29 ./GNUmakefile
	-@ echo ""
else
all : lib rpfhdr rpfex
	-@ $(RM) *.o

lib : $(RPFITSLIB) $(SHRLIB) ;

$(RPFITSLIB) : $(MEMBERS)
ifneq "$(RANLIB)" ""
	$(RANLIB) $(RPFITSLIB)
endif
	chmod 664 $@

# Shared (dynamic) library (Copied from WCSLIB's GNUmakefile)

PICLIB := librpfits-PIC.a
PICMEMBERS := $(patsubst %,$(PICLIB)(%),$(FOBJS) $(COBJS))

$(PICLIB)(%.o) : %.c
	-@ echo ''
	   $(CC) $(CPPFLAGS) $(CFLAGS) $(SHRFLAGS) -c $<
	   $(AR) r $(PICLIB) $%
	-@ $(RM) $%

$(PICLIB)(%.o) : %.f
	-@ echo ''
	   $(FC) $(CPPFLAGS) $(FCFLAGS) $(SHRFLAGS) -c $<
	   $(AR) r $(PICLIB) $%
	-@ $(RM) $%

$(SHRLIB) : $(PICLIB)
	-@ echo ''
	-@ $(RM) -r tmp
	   mkdir tmp && \
	     cd tmp && \
	     trap 'cd .. ; $(RM) -r tmp' 0 1 2 3 15 ; \
	     $(AR) x ../$(PICLIB) && \
	     $(SHRLD) -o $@ *.o $(LDFLAGS) $(LIBS) && \
	     mv $@ ..

$(PICLIB) : $(PICMEMBERS)

# End Shared (dynamic) library addition

rpfhdr : rpfhdr.c
	$(CC) -c $(CFLAGS) -o $@.o $<
	$(CC) -o $@ $(LDFLAGS) $@.o

rpfex : rpfex.c
	$(CC) -c $(CFLAGS) -o $@.o $<
	$(CC) -o $@ $(LDFLAGS) $@.o

install : all
	-@ mkdir -p $(PREFIX)/lib $(PREFIX)/include $(PREFIX)/bin
	-@ $(RM) $(PREFIX)/lib/librpfits.*
	   cp -p $(RPFITSLIB) $(PREFIX)/lib
	   if [ "X" != "X$(SHRLIB)" ]; then \
	     cp -p $(SHRLIB) $(PREFIX)/lib; \
	     ln -s $(SHRLIB) $(PREFIX)/lib/$(SONAME); \
	     ln -s $(SHRLIB) $(PREFIX)/lib/$(SHRLN); \
	   fi
	-@ $(RM) -f $(PREFIX)/include/rpfits.inc
	   cp -p $(COMMSRC)/rpfits.inc $(PREFIX)/include
	-@ $(RM) -f $(PREFIX)/include/RPFITS.h
	   cp -p $(COMMSRC)/RPFITS.h $(PREFIX)/include
	-@ $(RM) -f $(PREFIX)/bin/rpfhdr $(PREFIX)/bin/rpfex
	   cp -p rpfhdr rpfex $(PREFIX)/bin

clean cleaner :
	-$(RM) *.o core test.tmp

realclean cleanest : clean
	-$(RM) $(RPFITSLIB) $(SHRLIB) $(PICLIB) tfits rpfex rpfhdr

tar:
	-@ echo FIXME

# Compile and execute the test program.
test : tfits
	   $(RM) test.tmp
	-@ echo "Running tfits to write RPFITS data..."
	 @ echo w | ./tfits
	-@ echo "Running tfits to read RPFITS data..."
	 @ echo r | ./tfits

tfits : tfits.o $(RPFITSLIB)
	$(FC) -o $@ $(LDFLAGS) $< -L. -lrpfits
	$(RM) $<

# Include file dependencies.
$(RPFITSLIB)(rpferr.o) : rpfits.inc
$(RPFITSLIB)(rpfitsin.o) : rpfits.inc
$(RPFITSLIB)(rpfitsout.o) : rpfits.inc
$(RPFITSLIB)(rpfits_tables.o) : rpfits.inc

show :
	-@echo "RPFITSROOT=$(RPFITSROOT)"
	-@echo "VERS    =$(VERS)"
	-@echo "MAJOR   =$(VERS)"
	-@echo "MINOR   =$(VERS)"
	-@echo "RPARCH  =$(RPARCH)"
	-@echo ""
	-@echo "RPFITSLIB=$(RPFITSLIB)"
	-@echo ""
	-@echo "COMMSRC =$(COMMSRC)"
	-@echo "ARCHSRC =$(ARCHSRC)"
	-@echo "INCLUDES=$(INCLUDES)"
	-@echo ""
	-@echo "FC      =$(FC)"
	-@echo "FFLAGS  =$(FFLAGS)"
	-@echo "FSUBS   =$(FSUBS)"
	-@echo "FOBJS   =$(FOBJS)"
	-@echo ""
	-@echo "CC      =$(CC)"
	-@echo "CFLAGS  =$(CFLAGS)"
	-@echo "CSUBS   =$(CSUBS)"
	-@echo "COBJS   =$(COBJS)"
	-@echo ""
	-@echo "MEMBERS =$(MEMBERS)"
	-@echo ""
	-@echo "RANLIB  =$(RANLIB)"
	-@echo "LDFLAGS =$(LDFLAGS)"
	-@echo "PREFIX  =$(PREFIX)"
endif
