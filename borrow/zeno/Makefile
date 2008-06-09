########################################################################
# MAKEFILE: compile and link treesph code executable files             #
# Copyright (c) 1999 by Joshua E. Barnes, Tokyo, JAPAN.                #
#    revised for SPH calculation by Jin Koda, Tokyo, JAPAN. 2000       #
#    abbreviated and added to MIR/borrow/zeno by Peter Teuben. 2008    #
#    see also:  http://www.astro.caltech.edu/~koda/hkmiriad/           #
########################################################################


############################
### Compiler and Options ###
############################

# Linux, Sun:
#CC = fcc
CC = gcc
CCFLAGS = -O3
LDFLAGS = 

#########################################################
### Precision. [SINGLEPREC, MIXEDPREC, or DOUBLEPREC] ###
#########################################################

# Linux, Sun, Digital UNIX:
PRECISION = MIXEDPREC

#############
### Links ###
#############

X11_LIB = -L/usr/X11R6/lib -lX11

F2C_LIB = -lg2c

CPGPLOT_LIB = -L/usr/local/pgplot/ -lcpgplot -lpgplot -lpng -lgcc -lz\
         $(X11_LIB) $(F2C_LIB)

####################
### Zeno library ###
####################

libZeno.a: clib.o getparam.o mathfns.o
	ar ruv libZeno.a clib.o getparam.o mathfns.o
	ranlib libZeno.a

clib.o: clib.c stdinc.h
	$(CC) $(CCFLAGS) -D$(PRECISION) -c clib.c

getparam.o: getparam.c stdinc.h getparam.h
	$(CC) $(CCFLAGS) -D$(PRECISION) -c getparam.c

mathfns.o: mathfns.c stdinc.h mathfns.h
	$(CC) $(CCFLAGS) -D$(PRECISION) -c mathfns.c

###########################
### Remove object files ###
###########################

clean:;	rm -f *.o libZeno.a

install_miriad: miriad_install

miriad_install: libZeno.a
	cp libZeno.a $(MIRLIB)
