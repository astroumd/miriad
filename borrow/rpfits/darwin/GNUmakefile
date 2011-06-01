# Darwin Intel x86 Makefile for RPFITS (pixie, MacOSX 10.6.2).

# The RPFITS root directory.
RPFITSROOT := ..

# Only used for locating architecture-specific code in ../code/$(RPARCH)
# (../code/darwin is currently symlink'd to ../code/linux).
RPARCH := darwin

# GNU Fortran and C compiler flags.  The definitions here are for the
# gfortran 4.5 compiler available from hpc.sourceforge.net.
FC      := /usr/local/bin/gfortran-4.5
FFLAGS  := -g -O -fimplicit-none -Wall
CC      := /usr/bin/gcc-4.0 -arch x86_64
CFLAGS  := -g -O -Wall
RANLIB  := /usr/bin/ranlib

# Where to install stuff.
PREFIX := /usr/local

#-----------------------------------------------------------------------------
# Include generic RPFITS makefile.
-include $(RPFITSROOT)/GNUmakefile
