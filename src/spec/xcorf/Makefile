#	Makefile for Motif XCORF
#	26-feb-94 jm
#	22-nov-96 jm  Modified for X11R5/6

XBIN = xcorf
CFLAGS = -g

INC5 = -I/usr/openwin/include -I/usr/dt/include
INC6 = -I/usr/include

RFLAGS5 = -R /usr/openwin/lib:/usr/dt/lib
LFLAGS5 = -L/usr/openwin/lib -L/usr/dt/lib
LDFLAG5 = $(RFLAGS5) $(LFLAGS5)

RFLAGS6 = -R /usr/Local/lib/X11R6:/local/lib/X11R6
LFLAGS6 = -L/usr/Local/lib/X11R6 -L/local/lib/X11R6
LDFLAG6 = $(RFLAGS6) $(LFLAGS6)

XLIBS5 = -lXm -lXmu -lXt -lXext -lX11 -lm
XLIBS6 = -lXm -lXmu -lXt -lSM -lICE -lXext -lX11 -lm

SOLARISLIBS = -lsocket -lnsl -lgen

SUBS =	xcorf.o actions.o corfs.o draw.o file.o help.o rulers.o \
	setup.o slider.o widgets.o work.o

#
help:
	@echo "Makefile for XCORF task in `pwd`"
	@echo 'Use: make sunos or make Sunos (for static) [X11R5].'
	@echo 'Use: make sunos6 or make Sunos6 (for static) [X11R6].'
	@echo 'Use: make sol or make Sol (for static) [X11R5].'
	@echo 'Use: make sol6 or make Sol6 (for static) [X11R6].'
	@echo ' '
	@echo "XBIN=$(XBIN)"
	@echo "SUBS=$(SUBS)"
	@echo ' '
	@echo 'You can use one of the following pre-defined includes:'
	@echo "INC5=$(INC5)"
	@echo "INC6=$(INC6)"
	@echo 'by adding it to the command line as:'
	@echo "	make sol CFLAGS='-g $$(INC6)'"

.c.o:
	$(CC) $(CFLAGS) -c $<

cleanup:
	rm -f *.o $(XBIN)

sunos:	$(SUBS)
	$(CC) $(CFLAGS) -o $(XBIN) $(SUBS) $(LFLAGS5) $(XLIBS5)
 
Sunos:	$(SUBS)
	$(CC) $(CFLAGS) -o $(XBIN) -Bstatic $(SUBS) $(LFLAGS5) \
	$(XLIBS5) -Bdynamic
 
sunos6:	$(SUBS)
	$(CC) $(CFLAGS) -o $(XBIN) $(SUBS) $(LFLAGS6) $(XLIBS6)
 
Sunos6:	$(SUBS)
	$(CC) $(CFLAGS) -o $(XBIN) -Bstatic $(SUBS) $(LFLAGS6) \
	$(XLIBS6) -Bdynamic
 
sol:	$(SUBS)
	$(CC) $(CFLAGS) -o $(XBIN) $(SUBS) $(LDFLAG5) $(XLIBS5) $(SOLARISLIBS)
 
Sol:	$(SUBS)
	$(CC) $(CFLAGS) -o $(XBIN) -Bstatic $(SUBS) $(LDFLAG5) $(XLIBS5) \
	-Bdynamic $(SOLARISLIBS)

sol6:	$(SUBS)
	$(CC) $(CFLAGS) -o $(XBIN) $(SUBS) $(LDFLAG6) $(XLIBS6) $(SOLARISLIBS)
 
Sol6:	$(SUBS)
	$(CC) $(CFLAGS) -o $(XBIN) -Bstatic $(SUBS) $(LDFLAG6) $(XLIBS6) \
	-Bdynamic $(SOLARISLIBS)
 
#
# Include file dependancies.
#

$(SUBS):	xcorf.h

$(XBIN).o:	xcorf.h icon.h

xcorf.h:	declare.h version.h
