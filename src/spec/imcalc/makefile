OBJECTS = imcalc.o fft.o convl.o miriadio.o function.o
LIBS = -lm $(MIRLIB)/libmir.a
CFLAGS = -DIMCALC
CC = cc -g
imcalc: $(OBJECTS)
	$(CC) $(OBJECTS) $(LIBS) -o imcalc

$(OBJECTS): header.h

