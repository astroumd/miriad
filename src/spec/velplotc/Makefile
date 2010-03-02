# Makefile for export version for MIRIAD ($MIR/src/spec/velplotc)
#

EXE = velplotc

FC = f77
OFLAGS = -O3

#	on linux, include files are copied to /usr/include
#forminc=/usr/local/inc/xforms
#forminc=/usr/include

LIBFORMS = -lforms
INCFORMS = /usr/include

# note: we need $(PGPLOT_DIR) to point to the location where pgplot.inc lives

OBJS = main.o mainform.o convert_miriad.o\
       sub_plot.o cut.o readimage.o \
       sub_implot.o implot.o sub_velplot.o velplot.o tool.o

HEADERS = header.h mem.h plot.h cut.h data.h dim.h

$(EXE): $(OBJS) $(HEADERS) 
	$(FC) $(OFLAGS) -o $(EXE) $(OBJS) `mirlibs` $(LIBFORMS)

#  mainform needs to be triggered what compiler we're using
#  since gfortran does not need the _ to __ macro trick g77/ifort
#  needs by default. Or else use the -fno-second-underscore for g77
mainform.o:mainform.c
	$(CC) $(OFLAGS) -I$(INCFORMS) -Duse_$(FC) -c mainform.c

.SUFFIXES: .f

.f.o:$< $(HEADERS)
	@echo $< "=>" $*.o
	$(FC) $(OFLAGS) -I$(PGPLOT_DIR) -c $*.f
backup:
	tar -cvf velplot.tar *.[cfh] *.inc Makefile
	gzip velplot.tar

clean:
	rm -f *~ core *.o $(EXE)
