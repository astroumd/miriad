# Makefile for export version for MIRIAD ($MIR/src/spec/velplotc)
#

EXE = velplotc


#	on linux, include files are copied to /usr/include
#forminc=/usr/local/inc/xforms
forminc=/usr/include

LIBFORMS = -lforms

OBJS = main.o mainform.o convert_miriad.o\
       sub_plot.o cut.o readimage.o \
       sub_implot.o implot.o sub_velplot.o velplot.o tool.o

HEADERS = header.h mem.h plot.h cut.h data.h pgplot.inc dim.h

$(EXE): $(OBJS) $(HEADERS) 
	f77  -O3 -s -o $(EXE) $(OBJS) \
	  `mirlibs` $(LIBFORMS)

mainform.o:mainform.c
	cc -I$(forminc) -c mainform.c

.SUFFIXES: .f

.f.o:$< $(HEADERS)
	@echo $< "=>" $*.o
	f77 -O3 -c $*.f
backup:
	tar -cvf velplot.tar *.[cfh] *.inc Makefile
	gzip velplot.tar

clean:
	rm -f *~ core *.o $(EXE)
