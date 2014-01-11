texname = carmacookbook

doc_DATA = $(texname)_US.ps.gz

includes = \
  carmadata.inc \
  formularium.inc \
  future.inc \
  intro.inc \
  latexdefs.inc \
  miriad.inc \
  recipes.inc \
  scripting.inc \
  setup.inc \
  simple.inc \
  uvvars.inc \
  workflow.inc

samplescripts = \
  bandcal.csh \
  gcal.csh \
  mosaic.py \
  red.csh \
  simple0.csh \
  simple1a.csh \
  simple1b.csh

EXTRA_DIST = $(texname).tex $(includes) $(samplescripts) \
  3c273.ps \
  fig-systemp.ps \
  html.sty \
  titlepage.eps.in \
  verbatimfiles.sty

CLEANFILES = $(doc_DATA) titlepage.inc \
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

$(texname).dvi $(texname).idx: $(EXTRA_DIST)
	sed -e "s,%date%,`date +"%d %h %Y - %H:%M"`,g" <$(srcdir)/titlepage.eps.in >titlepage.inc
	$(INPUT_ENV) $(LATEX) $(LATEX_ARGS) $(srcdir)/$(texname)
	$(INPUT_ENV) $(LATEX) $(LATEX_ARGS) $(srcdir)/$(texname)
	$(INPUT_ENV) $(LATEX) $(LATEX_ARGS) $(srcdir)/$(texname)
	$(MAKEINDEX) $(texname).idx
	$(INPUT_ENV) $(LATEX) $(LATEX_ARGS) $(srcdir)/$(texname)

$(texname)_US.ps.gz: $(texname).dvi
	$(INPUT_ENV) dvips -tletter -y940 -o $(texname)_US.ps $(texname)
	gzip -f --best $(texname)_US.ps
	rm -f $(texname)_US.ps
