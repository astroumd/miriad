#  reminder Makefile for MIRIAD


TIME = /usr/bin/time

## help:       This Help for given HOST
help : Makefile
	@echo "HOST: `hostname`"
	@sed -n 's/^##//p' $<

## bench:   standard quick benchmark
bench:
	(cd install; $(TIME) ./mir.bench)

## start:   make new miriad_start files for this location
start:
	./install/make_miriad_starts
