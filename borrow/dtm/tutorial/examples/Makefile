##
## The DTM variable specifies which directory to find the libraries and
## include files.  This file is formatted with 1tab = 3spaces.
##
DTM		=	/usr/local/netdev
DTMINC	=	$(DTM)/include
DTMLIB	=	$(DTM)/lib/libdtm.a

CFLAGS	=	-g -I$(DTMINC)

LIBS	=	$(DTMLIB)

PROGS	=	MSGexample RISexample SDLexample SDSexample availRead availWrite	\
			ports ports2 readDataset readHeader readMultiple readVarious		\
			select version writeDataset writeError writeHeader writeMsg			\
			writeMultiple writeVarious


all:	$(PROGS)

version: version.c
	@echo
	@echo "	Making '"$@"' example..."
	$(CC) $(CFLAGS) -o $@ version.c $(LIBS)

ports: ports.c
	@echo
	@echo "	Making '"$@"' example..."
	$(CC) $(CFLAGS) -o $@ ports.c $(LIBS)

ports2: ports2.c
	@echo
	@echo "	Making '"$@"' example..."
	$(CC) $(CFLAGS) -o $@ ports2.c $(LIBS)

availRead: availRead.c
	@echo
	@echo "	Making '"$@"' example..."
	$(CC) $(CFLAGS) -o $@ availRead.c $(LIBS)

availWrite: availWrite.c
	@echo
	@echo "	Making '"$@"' example..."
	$(CC) $(CFLAGS) -o $@ availWrite.c $(LIBS)

readMultiple: readMultiple.c
	@echo
	@echo "	Making '"$@"' example..."
	$(CC) $(CFLAGS) -o $@ readMultiple.c $(LIBS)

readHeader: readHeader.c
	@echo
	@echo "	Making '"$@"' example..."
	$(CC) $(CFLAGS) -o $@ readHeader.c $(LIBS)

readDataset: readDataset.c
	@echo
	@echo "	Making '"$@"' example..."
	$(CC) $(CFLAGS) -o $@ readDataset.c $(LIBS)

writeError: writeError.c
	@echo
	@echo "	Making '"$@"' example..."
	$(CC) $(CFLAGS) -o $@ writeError.c $(LIBS)

writeDataset: writeDataset.c
	@echo
	@echo "	Making '"$@"' example..."
	$(CC) $(CFLAGS) -o $@ writeDataset.c $(LIBS)

select: select.c
	@echo
	@echo "	Making '"$@"' example..."
	$(CC) $(CFLAGS) -o $@ select.c $(LIBS)

readVarious: readVarious.c
	@echo
	@echo "	Making '"$@"' example..."
	$(CC) $(CFLAGS) -o $@ readVarious.c $(LIBS)

writeVarious: writeVarious.c
	@echo
	@echo "	Making '"$@"' example..."
	$(CC) $(CFLAGS) -o $@ writeVarious.c $(LIBS)

writeMultiple: writeMultiple.c
	@echo
	@echo "	Making '"$@"' example..."
	$(CC) $(CFLAGS) -o $@ writeMultiple.c $(LIBS)

writeMsg: writeMsg.c
	@echo
	@echo "	Making '"$@"' example..."
	$(CC) $(CFLAGS) -o $@ writeMsg.c $(LIBS)

writeHeader: writeHeader.c
	@echo
	@echo "	Making '"$@"' example..."
	$(CC) $(CFLAGS) -o $@ writeHeader.c $(LIBS)

SDSexample: SDSexample.c
	@echo
	@echo "	Making '"$@"' example..."
	$(CC) $(CFLAGS) -o $@ SDSexample.c $(LIBS)

SDLexample: SDLexample.c
	@echo
	@echo "	Making '"$@"' example..."
	$(CC) $(CFLAGS) -o $@ SDLexample.c $(LIBS)

RISexample: RISexample.c
	@echo
	@echo "	Making '"$@"' example..."
	$(CC) $(CFLAGS) -o $@ RISexample.c $(LIBS)

MSGexample: MSGexample.c
	@echo
	@echo "	Making '"$@"' example..."
	$(CC) $(CFLAGS) -o $@ MSGexample.c $(LIBS)


##
## "make clean" removes all of the executables created by this makefile.
##
clean:
	@echo Cleaning up...
	@echo
	/bin/rm -rf $(PROGS) *.o
