# Linux Makefile for RPFITS (spitzer, Debian lenny).

# The RPFITS root directory.
RPFITSROOT := ..

# Only used for locating architecture-specific code in ./code/$(RPARCH).
RPARCH := linux

# GNU Fortran and C compiler flags.
FC     := gfortran
FFLAGS := -g -O -fimplicit-none -Wall
CFLAGS := -g -O -Wall
RANLIB := ranlib

LDFLAGS :=

# Where to install stuff.
PREFIX := /usr/local

#-----------------------------------------------------------------------------
# Include generic RPFITS makefile.
-include $(RPFITSROOT)/GNUmakefile
