texname = progguide

doc_DATA = $(texname)_US.ps.gz
EXTRA_DIST = $(texname).tex

includes = defs.inc image.inc install.inc uvvars.inc titlepage.inc.in

CLEANFILES = $(doc_DATA) $(includes) \
  $(texname).aux \
  $(texname).dvi \
  $(texname).idx \
  $(texname).ilg \
  $(texname).ind \
  $(texname).log \
  $(texname).lot \
  $(texname).out \
  $(texname).toc

LATEX_ARGS = -interaction scrollmode

$(texname).dvi $(texname).idx: $(texname).tex $(includes)
	sed -e "s,%date%,`date +"%d %h %Y"`,g" <$(srcdir)/titlepage.inc.in >titlepage.inc
	$(LATEX) $(LATEX_ARGS) $(srcdir)/$(texname)
	$(LATEX) $(LATEX_ARGS) $(srcdir)/$(texname)
	$(LATEX) $(LATEX_ARGS) $(srcdir)/$(texname)
	$(MAKEINDEX) $(texname).idx
	$(LATEX) $(LATEX_ARGS) $(srcdir)/$(texname)
	rm -f titlepage.inc

$(texname)_US.ps.gz: $(texname).dvi
	dvips -tletter -y940 -o $(texname)_US.ps $(texname)
	gzip --best $(texname)_US.ps
	rm -f $(texname)_US.ps

# Generating all the various include files. Should do something more
# elegant than just copying several files ...
# We regenerate titlepage.inc on every build since it records
# the current date, so keeping it around doesn't make sense.

install.inc: $(top_srcdir)/install.MIR
	echo "{\small\begin{verbatim}" >$@
	$(top_builddir)/src/tools/detab $< >>$@
	echo "\end{verbatim}}" >>$@

defs.inc: $(top_srcdir)/manuals/atnf-user/latexdefs.inc
	cp -f $< $@

uvvars.inc: $(top_srcdir)/manuals/atnf-user/uvvars.inc
	cp -f $< $@

image.inc: $(top_srcdir)/manuals/atnf-user/image.inc
	cp -f $< $@

