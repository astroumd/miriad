texname = progguide

doc_DATA = $(texname)_US.ps.gz
EXTRA_DIST = $(texname).tex titlepage.inc.in html.sty

includes = defs.inc image.inc install.inc uvvars.inc

CLEANFILES = $(doc_DATA) $(includes) titlepage.inc \
  $(texname).aux \
  $(texname).dvi \
  $(texname).idx \
  $(texname).ilg \
  $(texname).ind \
  $(texname).log \
  $(texname).lot \
  $(texname).out \
  $(texname).toc

# -halt-on-error is useful but not supported by all flavors of LaTeX
LATEX_ARGS = -interaction scrollmode
INPUT_ENV = TEXINPUTS=:$(srcdir)$${TEXINPUTS:+:}$$TEXINPUTS 

$(texname).dvi $(texname).idx: $(texname).tex titlepage.inc.in html.sty $(includes)
	sed -e "s,%date%,`date +"%d %h %Y"`,g" <$(srcdir)/titlepage.inc.in >titlepage.inc
	$(INPUT_ENV) $(LATEX) $(LATEX_ARGS) $(srcdir)/$(texname)
	$(INPUT_ENV) $(LATEX) $(LATEX_ARGS) $(srcdir)/$(texname)
	$(INPUT_ENV) $(LATEX) $(LATEX_ARGS) $(srcdir)/$(texname)
	$(MAKEINDEX) $(texname).idx
	$(INPUT_ENV) $(LATEX) $(LATEX_ARGS) $(srcdir)/$(texname)

$(texname)_US.ps.gz: $(texname).dvi
	$(INPUT_ENV) dvips -tletter -y940 -o $(texname)_US.ps $(texname)
	gzip -f --best $(texname)_US.ps
	rm -f $(texname)_US.ps

# Generating all the various include files. Should do something more
# elegant than just copying several files ...
# We regenerate titlepage.inc on every build since it records
# the current date, so keeping it around doesn't make sense.

# When run in a MacPorts build, an 'echo' command here somehow
# interprets the backslashes as escape characters and mangles
# the latex code. (Running sh -c 'echo q\br' demonstrates this
# too). I am led to believe the printf is essentially universal
# and has more consistent semantics, so use that instead.
install.inc: $(top_srcdir)/install.MIR
	printf '{\\small\\begin{verbatim}\n' >$@
	$(top_builddir)/src/tools/detab $< >>$@
	printf '\\end{verbatim}}\n' >>$@

defs.inc: $(top_srcdir)/manuals/atnf-user/latexdefs.inc
	cp -f $< $@

uvvars.inc: $(top_srcdir)/manuals/atnf-user/uvvars.inc
	cp -f $< $@

image.inc: $(top_srcdir)/manuals/atnf-user/image.inc
	cp -f $< $@
