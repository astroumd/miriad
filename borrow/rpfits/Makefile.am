## The wcslib source tree includes a "GNUmakefile", which would override
## our Makefiles when using GNU make ... which we require. Automake
## recurses into the PWD for some operations, so we need to specify
## AM_MAKEFLAGS here the same way we do in the toplevel Makefile.am

AM_MAKEFLAGS = -f Makefile

lib_LTLIBRARIES = libmir_rpfits.la

rpfcincdir = $(includedir)/miriad-c/rpfits
rpffincdir = $(includedir)/miriad-f/rpfits

rpfcinc_HEADERS = code/RPFITS.h
rpffinc_HEADERS = code/rpfits.inc

libmir_rpfits_la_SOURCES = \
 $(rpfcinc_HEADERS) \
 $(rpffinc_HEADERS) \
 code/datfit.f \
 code/dconv.f \
 code/ljusty.f \
 code/nchar.f \
 code/rjusty.f \
 code/rpferr.f \
 code/rpfitsin.f \
 code/rpfitsout.f \
 code/rpfits_tables.f \
 code/utdate.c \
 code/linux/atio.f \
 code/linux/cvt_ieee.f
