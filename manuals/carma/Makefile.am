texname = miriad4

doc_DATA = $(texname)_US.ps.gz

EXTRA_DIST = $(texname).tex

CLEANFILES = $(doc_DATA) \
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

$(texname).dvi $(texname).idx: $(texname).tex
	$(INPUT_ENV) $(LATEX) $(LATEX_ARGS) $(srcdir)/$(texname)

$(texname)_US.ps.gz: $(texname).dvi
	$(INPUT_ENV) dvips -tletter -y940 -o $(texname)_US.ps $(texname)
	gzip -f --best $(texname)_US.ps
	rm -f $(texname)_US.ps
