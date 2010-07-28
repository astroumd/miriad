include $(top_srcdir)/mircommon.mak

finclude_HEADERS = calapply.h caldata.h caldefs.h calfit.h \
  calio.h calpass.h calpoly.h calsubs.h maxdim.h maxnax.h \
  mem.h mirconst.h rpfits.inc size.h tmpdim.h

cinclude_HEADERS = maxdimc.h 

# Configure generates cfg_maxdim{,c}.h . We clone these files
# to maxdim{,c}.h, but make sure not to update the timestamp
# if the file is unchanged. That way, a rerun of config.status
# won't require us to rebuild everything unless the config
# headers truly change.
#
# The AC_CONFIG_HEADERS mechanism has builtin support for this,
# but it doesn't use the usual @VAR@ substitution mechanism --
# it uses a weird thing based on lines starting with #undef
# that won't work for Fortran headers and would require large
# changes to the definitions of the MAXFOO variables in
# configure.ac.
#
# Right now, the machinery to not update maxdim.h is technically
# superfluous, since we don't have dependency information on files
# included via ratty. But hopefully that will change in the future.

maxdim.h: cfg_maxdim.h
	$(AM_V_at)if diff $< $@ >/dev/null 2>&1 ; then \
	   : ; \
	else \
	   cp -f $< $@ ; \
	fi

maxdimc.h: cfg_maxdimc.h
	$(AM_V_at)if diff $< $@ >/dev/null 2>&1 ; then \
	   : ; \
	else \
	   cp -f $< $@ ; \
	fi

CLEANFILES = maxdim.h maxdimc.h
