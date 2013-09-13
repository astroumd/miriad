include $(top_srcdir)/mircommon.mak

# Install and distribute everything in cat/ and subdirectories.  If
# we're using a Git checkout, use Git's knowledge to get the list of
# files to process; otherwise, just install everything we find, even
# though unnecessary files such as backups and personal junk files
# might get installed and disted.
#
# Implementation notes: find has a -delete option, but it will try
# to delete a potential CVS directory without deleting its contents,
# so that will fail.
#
# We have to make sure the installed files have the right mode since
# they'll inherit what they have in $srcdir, and in distcheck mode
# this is missing the write bit since distcheck makes $srcdir readonly;
# this causes the uninstall to fail and distcheck to barf, and is
# generally not the thing to do.
#
# Our "make dist" logic updates the timestamp of Makefile.am relative
# to what's in the source tree, which can cause problems because it
# triggers a regeneration of Makefile.in, which may not be possible.
# We therefore touch these two files in order to avoid this.
#
# Note that git archive will output what's been committed to the repo,
# not any uncommitted changes in the working tree, so those won't
# be captured when disting or installing. This seems like an awfully
# minor corner case though.

install-data-local:
	test -z "$(catdir)" || $(mkinstalldirs) "$(DESTDIR)$(catdir)"
	if test -d $(top_srcdir)/.git ; then \
	  command="git archive --format=tar HEAD" ; \
	else \
	  command="$(AMTAR) cf - ." ; \
	fi ; \
	(cd $(srcdir) && $$command) | (cd "$(DESTDIR)$(catdir)" && $(AMTAR) xf -)
	find "$(DESTDIR)$(catdir)" -type f -print0 |xargs -0 chmod 0644
	find "$(DESTDIR)$(catdir)" -type d -print0 |xargs -0 chmod 0755
	find "$(DESTDIR)$(catdir)" \( -name 'Makefile*' -o -name CVS \) -print0 |xargs -0 rm -rf

uninstall-local:
	-rm -rf $(DESTDIR)$(catdir)

dist-hook:
	$(mkinstalldirs) "$(distdir)"
	if test -d $(top_srcdir)/.git ; then \
	  command="git archive --format=tar HEAD" ; \
	else \
	  command="$(AMTAR) cf - ." ; \
	fi ; \
	(cd $(srcdir) && $$command) | (cd "$(distdir)" && $(AMTAR) xf -)
	find "$(distdir)" -type f -print0 |xargs -0 chmod 0644
	find "$(distdir)" -type d -print0 |xargs -0 chmod 0755
	find "$(distdir)" -name CVS -print0 |xargs -0 rm -rf
	touch "$(distdir)/Makefile.am"
	touch "$(distdir)/Makefile.in"

# Generate and install the keyword documentation files.

pdoc_DATA = device.kdoc in.kdoc line.kdoc options.kdoc out.kdoc \
  region.kdoc select.kdoc server.kdoc stokes.kdoc vis.kdoc \
  window.kdoc

$(pdoc_DATA): keyword-doc.stamp

keyword-doc.stamp: keywords.kdoc
	$(AM_V_GEN)$(DOC) -p $< ; touch $@

CLEANFILES = keyword-doc.stamp $(pdoc_DATA)
