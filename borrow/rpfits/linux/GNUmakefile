# Linux Makefile for RPFITS.

# The RPFITS root directory.
RPFITSROOT := /nfs/atapplic/rpfits
 
# Only used for locating architecture-specific code in ./code/$(ARCH).
ARCH := linux

# C and FORTRAN compiler flags.
CFLAGS := -g -O -Wall
FFLAGS := -g -O -fno-automatic -Wall -Wno-globals
FC := g77
RANLIB := ranlib

LDFLAGS := -Xlinker -rpath .

#-----------------------------------------------------------------------------
# Include generic RPFITS makefile.
-include $(RPFITSROOT)/GNUmakefile
