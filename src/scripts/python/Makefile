
# is there no better way to do this [other than via setup.py] ?
PYTHONINC = `python -c 'import sys; v=sys.version_info;print sys.prefix+"/include/python%d.%s" % (v[0],v[1])'`

CC = gcc
CFLAGS = -g -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -fPIC
LDFLAGS = -g 

#       useful diagnostics to see if you use the right python
help:
	@echo PYTHONINC=$(PYTHONINC)
	@if [ ! -f $(PYTHONINC)/Python.h ]; then\
          echo Python.h not found in PYTHONINC.... this is bad;\
	else\
	  echo Python.h also found, that is good;\
        fi

TMPDIR = $(MIR)/install/mirlib

#              setenv LD_LIBRARY_PATH $MIR/install/mirlib:...

uvio:
	swig -python uvio.i
	$(CC) $(CFLAGS) -I$(PYTHONINC) -I$(TMPDIR) -c uvio_wrap.c 
	$(CC) $(LDFLAGS) -shared -L$(TMPDIR) -lmir uvio_wrap.o -o _uvio.so 
	python -c 'import uvio'



#
#   this needs CFLAGS=-g
#              setenv LD_LIBRARY_PATH `pwd`/mirlib:...

LDIR = `pwd`/mirlib

test:
	swig -python uvio.i
	$(CC) $(CFLAGS) -I$(PYTHONINC) -I$(LDIR) -c uvio_wrap.c 
	$(CC) $(LDFLAGS) -shared $(LDIR)/libmir.so uvio_wrap.o -o _uvio.so 
	python -c 'import uvio'


# old style install
miriad-python:
	git clone https://github.com/pkgw/miriad-python
#

#       this one isn't working on old-style
bad:
	(cd miriad-python;  ACLOCAL="aclocal -I build-aux" autoreconf -fi; ./configure --with-miriad=$(MIR))
