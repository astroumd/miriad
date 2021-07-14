# Darwin Intel x86 Makefile for RPFITS (pixie, macOS).

# The RPFITS root directory.
RPFITSROOT := ..

# Only used for locating architecture-specific code in
# $(RPFITSROOT)/code/$(RPARCH) (note that $(RPFITSROOT)/code/darwin is
# currently symlink'd to linux/).
RPARCH := darwin

# GNU Fortran and C compiler flags. 
FC      := /usr/local/bin/gfortran
FFLAGS  := -g -O -fimplicit-none -Wall
CC      := /usr/bin/gcc -arch x86_64
CFLAGS  := -g -O -Wall
RANLIB  := /usr/bin/ranlib

# Where to install stuff.
PREFIX := /usr/local

#-----------------------------------------------------------------------------
# Include generic RPFITS makefile.
-include $(RPFITSROOT)/GNUmakefile
