#
#	Makefile for 'hcconv', the conversion program from
#	HC data (VMS) to new Miriad format
#
#	Because main program is written in C, and linking with
#	fortran is needed, special FORLIBS macro is needed
#	This c-to-fortran linking technique is likely to fail
#	on some non-BSD Unix flavors, such as Unicos and Alliant.
#	where string passing is different.
#
#	Also the name 'FORLIBS' may differ on newer fortran on SUNOS 4.1
#	where it is '-lF77 -lm' only
#
#			Peter Teuben   - July 1990
#
#	Last upd:  16-dec-90	pjt
#		   18-nov-91    using FC to link C-main

CFLAGS	= -g
HOBJS	= hcconv.o vmsget.o put_hc.o gethcfiles.o
SOBJS	= solconv.o vmsget.o gethcfiles.o
FORLIBS	= -lF77 -lI77 -lU77 -lm		# BSD FORLIBS - won't work on SUNs anymore
MIRLIBS = `mirlibs`


#   Files which get installed from here to MIRIAD
INSFILES=Makefile hc_struct.h hc_var.h hcconv.c solconv.c put_hc.c \
 	vlist vlist.awk vmsget.c vmsget.h gethcfiles.c

#   Directory where INSFILES get submitted to
INSDIR=$(MIR)/src/spec/hcconv

help:
	@echo "===Conversion of data from HC format to new miriad format==="
	@echo " SUN-version"
	@echo "Targets: "
	@echo "     hcconv        The program itself"
	@echo "     solconv       special program for Solar stuff"
	@echo "     clean         Clean up all mess"
	@echo "     install       General install into Miriad"
	@echo "     submit        Sumbit source to Miriad"     
	@echo "     tar		  Make self consistent tar file"
	@echo ""
	@echo "INSDIR = $(INSDIR)"
	@echo "INSFILES = $(INSFILES)"
	@echo "FORLIBS = $(FORLIBS)"


install: hcconv
	mv hcconv $(MIRBIN)
	rm -f *.o core

clean:  cleanup

cleanup:
	rm -f *.o hcconv solconv core

all:	hcconv

hcconv:	$(HOBJS)
	$(FC) $(CFLAGS) -o hcconv $(HOBJS) $(MIRLIBS)
#	$(CC) $(CFLAGS) -o hcconv $(HOBJS) $(MIRLIBS) $(FORLIBS)

solconv: $(SOBJS)
	$(FC) $(CFLAGS) -o solconv $(SOBJS) $(MIRLIBS)
#	$(CC) $(CFLAGS) -o solconv $(SOBJS) $(MIRLIBS) $(FORLIBS)

put_hc.o: put_hc.c hc_var.h

hc_var.h: vlist
	sort vlist | awk -f vlist.awk > hc_var.h


submit: .submit

.submit: $(INSFILES)
	mir.submit $? $(INSDIR)
	@touch .submit

tar:
	tar cvf hcconv.tar $(INSFILES)

check:
	ls -lt  $(MIR)/src/prog/convert/unix/hcconv

dir:
	ls -lt $(INSFILES)
