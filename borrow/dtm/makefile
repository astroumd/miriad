#	Master makefile

all:	dtm cserv examples

dtm::
	(cd libsrc; make all)

cserv::
	(cd server; make all)

examples::
	(cd examples;make all)

clean::
	(cd libsrc; make clean)
	(cd server; make clean)
	(cd examples; make clean)

install::
	(cd libsrc; make install DIR=$(DIR))


tar:: 
	-rm *.tar
	-rm *.tar.Z
	(cd ..; tar cf dtm/dtm.tar \
	dtm/README dtm/makefile \
	dtm/libsrc/*.c dtm/libsrc/*.f dtm/libsrc/*.h dtm/libsrc/makefile \
	dtm/cserv/*.c dtm/cserv/*.h dtm/cserv/*.l \
		dtm/cserv/*.y dtm/cserv/makefile \
	dtm/examples/README dtm/examples/makefile \
		dtm/examples/*.c dtm/examples/*.h \
	dtm/man dtm/tutorial)
	compress dtm.tar
