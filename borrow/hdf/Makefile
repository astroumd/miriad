#*****************************************************************************
# 
#			  NCSA HDF version 3.10r2
#				Sept 20, 1990
#
# NCSA HDF Version 3.10r2 source code and documentation are in the public
# domain.  Specifically, we give to the public domain all rights for future
# licensing of the source code, all resale rights, and all publishing rights.
# 
# We ask, but do not require, that the following message be included in all
# derived works:
# 
# Portions developed at the National Center for Supercomputing Applications at
# the University of Illinois at Urbana-Champaign.
# 
# THE UNIVERSITY OF ILLINOIS GIVES NO WARRANTY, EXPRESSED OR IMPLIED, FOR THE
# SOFTWARE AND/OR DOCUMENTATION PROVIDED, INCLUDING, WITHOUT LIMITATION,
# WARRANTY OF MERCHANTABILITY AND WARRANTY OF FITNESS FOR A PARTICULAR PURPOSE
# 
#*****************************************************************************

# Makefile for compiling HDF routines, and installing the files
# produced

# Machine type: this can be set to ALLIANT, SUN, SUN386, UNICOS,
# IRIS4 or APOLLO.  (Note: If you have a DEC 3100, to not specify
# a machine type.)

MACHINE=SUN


# SRCDIR, INCDIR, LIBDIR and BINDIR must be set to the desired values
# then, make build will compile source files make install will move
# files to include, bin and lib directories make cleanup will delete
# the .o files produced A make dist is also defined.  This will move
# source files to SRCDIR However, it is expected that make will
# usually be run from SRCDIR Hence, install is provided separately
# directories to install source files, include files, libraries and
# utilities in Modify this line as appropriate for your system

SRCDIR=.
INCDIR=../include
LIBDIR=../lib
BINDIR=../bin

# graphics display library for hdfseq (if any), compile flags.
# Modify -I option if .h files elsewhere
# for non-SUNS :
#GLIBS=
GLIBS	= -lpixrect
LIBS	= libdf.a

CC	= cc
FC	= f77
AR	= ar
RM	= /bin/rm -f
RANLIB	= ranlib
#DEFS	= -D${MACHINE}
CFLAGS	= -O ${DEFS}
FFLAGS	= -O
ARFLAGS = r
LDFLAGS = 

HFILES= df.h dfi.h dfrig.h dfsd.h dfF.h dfan.h dfgr.h dfconvert.h
CFILES= df.c dfr8.c dfgroup.c dfcomp.c dfimcomp.c \
	dfsd.c dfF.c dfr8F.c dfsdF.c dfkit.c dfp.c dfan.c \
	dfgr.c df24.c df24F.c dfpF.c dfanF.c dfufptoim.c \
	dfutil.c dfutilF.c
FFILES= dfFf.f dfr8Ff.f dfsdFf.f dfanFf.f df24Ff.f dfpFf.f constants.f \
	cspck32.f scup32.f dfufptoimFf.f
UFILES= hdfcomp.c hdftotek.c tektohdf.c hdftor8.c hdfrseq.c \
	r8tohdf.c hdfls.c hdftopal.c paltohdf.c r24hdf8.c \
	hdf24hdf8.c showr24.c showr8.c
COBJS= df.o dfr8.o dfsd.o dfgroup.o dfcomp.o dfimcomp.o  \
	dfkit.o dfp.o dfan.o  dfgr.o df24.o dfufptoim.o dfutil.o
FOBJS=dfF.o dfr8F.o dfsdF.o dfanF.o dfFf.o dfr8Ff.o dfsdFf.o dfanFf.o \
	df24F.o df24Ff.o dfpFf.o dfpF.o dfufptoimFf.o dfutilF.o
OBJS=${COBJS} ${FOBJS}

UTILS= hdfrseq hdfls r8tohdf hdfcomp hdftotek tektohdf hdftor8 \
	paltohdf hdftopal r24hdf8 hdf24hdf8

all:	libdf.a utils install

allnostub: libnostub utils install

build:  libdf.a utils

buildnostub: libnostub utils

libdf.a: ${OBJS}
	-${RM} libdf.a libnostub
	${AR} ${ARFLAGS} libdf.a ${OBJS}
	${RANLIB} libdf.a

libnostub: ${COBJS}
	-${RM} libdf.a libnostub
	${AR} ${ARFLAGS} libdf.a ${COBJS}
	${RANLIB} libdf.a
	touch libnostub

utils: ${UTILS}

df.o dfgroup.o dfcomp.o dfimcomp.o dfkit.o: df.h dfi.h

dfr8.o: dfrig.h df.h dfi.h

dfsd.o: dfsd.h df.h dfi.h dfconvert.h

dfan.o: dfan.h df.h dfi.h

dfgr.o: dfgr.h df.h dfi.h

dfF.o: dfF.h df.h dfi.h

# this default rule is in here because the original default rule
# places the c-filename behind the LDFLAGS causing the brain-damaged
# ld to chock
$(UTILS)::  df.h dfi.h
	${CC} ${CFLAGS} $@.c ${LDFLAGS} ${LIBS} ${GLIBS} -o $@

# dist will move files from current directory to source directory
# install will move files from current dir to bin, lib and include directories
# It is expected that make will usually run in srcdir, so only install and
# cleanup will be necessary

dist: $(HFILES) $(CFILES) $(FFILES) Makefile
	cp $(HFILES) $(CFILES) $(FFILES) $(UFILES) Makefile $(SRCDIR)

install:
	-mkdir $(INCDIR)
	cp $(HFILES) $(INCDIR)
	-mkdir $(LIBDIR)
	cp $(LIBS) $(LIBDIR)
	ranlib $(LIBDIR)/*
	-mkdir $(BINDIR)
	cp $(UTILS) $(BINDIR)

clean:
	-${RM} *.o

cleanup:
	-${RM} $(OFILES) $(LIBS) $(UTILS)

lint:
	lint -u -D$(MACHINE) $(CFILES)

saber:
	#load -D$(MACHINE) $(CFILES)

.DEFAULT::
	hdfrcs src co $@

libsrc: $(HFILES) $(CFILES) $(FFILES)

src: libsrc $(UFILES)
