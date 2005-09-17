# The RPFITS root directory.
RPFITSROOT := /nfs/atapplic/rpfits
 
# Only used for locating architecture-specific code in ./code/$(ARCH).
ARCH := sun4sol

# C and FORTRAN compiler flags.
CFLAGS := -O -xs
FFLAGS := -O -u -xs

RANLIB := ranlib

LDFLAGS := -R.

#-----------------------------------------------------------------------------
# Include generic RPFITS makefile.
-include $(RPFITSROOT)/GNUmakefile
