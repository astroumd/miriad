# Makefile for MXTV

#   This makefile has been tested on the following CPUs
#   baboon   - Sun Sparc Station 
#   lemur    - IBM RS 6000 model 530 (Running AIX)
#   colobus  - Decstation 
#
#   The environment (different) variables for these CPUs are
#   given in the comments.  
#   Note for VMS, xmtv.h must be modified to define VMS as 1
#
#   Destination for executable.  If you are building MXTV on a
#   system that has Miriad installed this should be the same as
#   the Miriad bin area.  Some implementations of MAKE allow the
#   use of an environmental variable as shown here: check your
#   system documentation.
DESTDIR = $(MIRBIN)
#
#   Destination for application defaults file.  If you are
#   building MXTV on a system that has Miriad installed this
#   should be the same as the Miriad CAT area.  Some
#   implementations of MAKE allow the use of an environmental
#   variable as shown here: check your system documentation.
APPDESTDIR = $(MIRCAT)
#
#   Additional include files.  Some X Window System
#   implementations do not place their include in the standard
#   Unix directory /usr/include.  The include directories should
#   be listed here, each preceded by -I.
#   CPU baboon: INCDIRS    = -I/local/include
INCDIRS    = -I/local/pkg/X11R5/include
#
#   Library search path.  Standard Unix libraries are usually
#   found in /usr/lib; some X Window System implementations
#   place their libraries in other locations.  These should
#   be listed here, each preceded by -L.
#   CPU baboon: LIBDIRS    = -L/local/lib
LIBDIRS    =  -L/local/pkg/X11R5/lib/$(HOSTTYPE)
#
#    Add local compiler/linker options here.  For example Sun 3s
#    will require a -f option to specify the floating point
#    hardware option.
LOCALOPTS = 
#
# Desired compilation flags
# CPU baboon: FLAGS = -fsingle -dalign -O
FLAGS = -O
#
# Your favourite C compiler
#CC=gcc
CC=cc
#
#    Do not alter anything below this line
#--------------------------------------------------------------------

.c.o :
	$(CC) $(CCOPTS) $<

CCOPTS = $(INCDIRS) $(FLAGS) $(LOCALOPTS) -c

# XLIBS = -lXaw -lXmu -lXt -lXext -lX11
XLIBS = -lXaw -lXmu -lXt -lX11

OBJECTS = xmtv.o colors.o comm.o cursor.o image.o \
	local.o menus.o process.o screen.o selectpt.o widgets.o

all : $(DESTDIR)/xmtv.exe $(DESTDIR)/xmtv $(APPDESTDIR)/XMtv

$(DESTDIR)/xmtv.exe : XMTV
	mv XMTV $(DESTDIR)/xmtv.exe

XMTV : $(OBJECTS)
	$(CC) $(LIBDIRS) $(FLAGS) $(LOCALOPTS) $(OBJECTS) $(XLIBS) -lm -o XMTV

$(DESTDIR)/xmtv : xmtv.csh
	cp xmtv.csh $(DESTDIR)/xmtv

$(APPDESTDIR)/XMtv : XMtv.ad
	cp XMtv.ad $(APPDESTDIR)/XMtv

xmtv.o    : xmtv.c      xmtv.h   xmtv.icon  version.h

colors.o  : colors.c    xmtv.h   ofms.h

comm.o    : comm.c      xmtv.h

cursor.o  : cursor.c    xmtv.h

image.o   : image.c     xmtv.h

local.o   : local.c     xmtv.h

menus.o   : menus.c     xmtv.h

process.o : process.c   xmtv.h

screen.o  : screen.c    xmtv.h

selectpt.o: selectpt.c  xmtv.h

widgets.o : widgets.c   xmtv.h
