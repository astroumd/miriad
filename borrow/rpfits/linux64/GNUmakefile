# Linux Makefile for RPFITS (spitzer, Debian lenny).

# The RPFITS root directory.
RPFITSROOT := ..

# Only used for locating platform-specific code in
# $(RPFITSROOT)/code/$(RPARCH).
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

# Add extra actions for the generic targets, so that we can invoke
#   make ourextra target
# and have it do what's required.
# The 'force' means targets defined in this file will override any that
# are already defined; make may warn about this but should do what it's told.
%: force
	@$(MAKE) -f Makefile.shared $@
force: ;
# End Override

