DTM = ../../..
DTMINC = $(DTM)/include
DTMLIB = $(DTM)/lib/libdtm.a

CC = cc
LIBS = -lm
CFLAGS = -I$(DTMINC)

OBJS = demos.o messages.o matrices.o

all: simple_reader simple_writer demos transforms gravity circle

simple_reader: simple_reader.c
	$(CC) $(CFLAGS) -o $@ simple_reader.c $(DTMLIB)

simple_writer: simple_writer.c
	$(CC) $(CFLAGS) -o $@ simple_writer.c $(DTMLIB)

demos: ${OBJS}
	$(CC) -o demos ${OBJS} $(DTMLIB) $(LIBS)

transforms: transforms.c matrices.c
	$(CC) -I$(DTMINC) transforms.c matrices.c -o transforms $(DTMLIB) $(LIBS)

gravity: gravity.c
	$(CC) $(CFLAGS) gravity.c -o gravity $(DTMLIB) $(LIBS)

circle: circle.c
	$(CC) $(CFLAGS) circle.c -o circle $(DTMLIB) $(LIBS)


clean:
	-rm -f  simple_reader simple_writer
	-rm -f *.o demos transforms gravity circle core

install:
	cp simple_reader $(BIN)
	cp simple_writer $(BIN)
	cp demos $(BIN)
	cp transforms $(BIN)
	cp gravity $(BIN)
	cp circle $(BIN)
