#-----------------------------------------------------------------------------
# Template GNU makefile for compiling the RPFITS library.  This makefile is
# intended to be included from a GNU makefile (usually in a subdirectory)
# which contains architecture-specific variable definitions for:
#
#    RPFITSROOT ...The RPFITS root directory.
#    ARCH       ...Architecture name (alpha, linux, sgi, sun4, sun4sol, etc.)
#                  used only for locating architecture-specific source code.
#    CFLAGS     ...C compiler flags.
#    FFLAGS     ...Fortran compiler flags.
#    RANLIB     ...Command used to "ranlib" object libraries (set to ":" if
#                  ranlib is not needed.
#    LDFLAGS    ...Linker flags.
#
# $Id$
#-----------------------------------------------------------------------------
ifndef RPFITSROOT
   RPFITSROOT := $(shell pwd)
endif

# Where gmake finds the source code.
COMMSRC := $(RPFITSROOT)/code
ARCHSRC := $(COMMSRC)/$(ARCH)
TESTSRC := $(RPFITSROOT)/test
VPATH   := .:$(ARCHSRC):$(COMMSRC):$(TESTSRC)

# Include paths etc.
INCLUDES := -I. -I$(ARCHSRC) -I$(COMMSRC)
CFLAGS   += -c $(INCLUDES)
FFLAGS   += $(INCLUDES)

# First check out any new sources.
FIRST  := $(shell $(MAKE) -C $(COMMSRC))

# Lists of object library members.
FSUBS  := $(filter-out *.f, \
            $(notdir \
               $(wildcard ./*.f $(COMMSRC)/*.f $(ARCHSRC)/*.f)))
FOBJS  := $(FSUBS:.f=.o)

CSUBS  := $(filter-out *.c, \
            $(notdir \
               $(wildcard ./*.c $(COMMSRC)/*.c $(ARCHSRC)/*.c)))
COBJS  := $(CSUBS:.c=.o)

RPFITSLIB  := librpfits.a
MEMBERS := $(patsubst %,$(RPFITSLIB)(%),$(FOBJS) $(COBJS))


# Static rules.
.PRECIOUS : $(RPFITSLIB)
.PHONY : all clean lib realclean show test

all : lib
	-@ $(RM) *.o

lib : $(RPFITSLIB) ;

$(RPFITSLIB) : $(MEMBERS)
	$(RANLIB) $(RPFITSLIB)
	chmod 664 $@

install : lib
	-@ $(RM) /usr/local/lib/librpfits.*
	   cp $(RPFITSLIB) /usr/local/lib
	-@ $(RM) /usr/local/include/rpfits.inc
	   cp $(COMMSRC)/rpfits.inc /usr/local/include

clean :
	-$(RM) *.o core test.tmp

realclean : clean
	-$(RM) $(RPFITSLIB) tfits

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
$(RPFITSLIB)(rpfitsin.o) : rpfits.inc
$(RPFITSLIB)(rpfitsout.o) : rpfits.inc
$(RPFITSLIB)(rpfits_tables.o) : rpfits.inc

show :
	-@echo "RPFITSROOT=$(RPFITSROOT)"
	-@echo "ARCH    =$(ARCH)"
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
