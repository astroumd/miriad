# FIXME: our titlepage.inc is identical to the one in atnf-prog,
# with s/User/Programmer/. Well, and ours is called titlepage.eps,
# which is the better extension.

texname = userguide

doc_DATA = $(texname)_US.ps.gz

includes = \
  biblio.inc \
  cook.inc \
  glossary.inc \
  htmldefs.inc \
  iface.inc \
  image.inc \
  imanal.inc \
  imdisp.inc \
  latexdefs.inc \
  mm.inc \
  mosaic.inc \
  oldcal.inc \
  pltvcon.inc \
  pulsar.inc \
  setup.inc \
  spanal.inc \
  spdisp.inc \
  trouble.inc \
  uvvars.inc \
  viz.inc \
  xmtv.inc \
  html.sty

figs = \
  mmcal.fig \
  polcal1.fig \
  polcal2.fig \
  polcal3.fig \
  polcalnew.fig \
  selfcal.fig \
  strategy.fig 

gnuplots = immerge.g

psfigs = $(figs:.fig=.ps)
gfigs = $(gnuplots:.g=.ps)

EXTRA_DIST = $(texname).tex $(includes) $(figs) $(gnuplots) \
  titlepage.eps.in colours.eps

CLEANFILES = $(doc_DATA) $(psfigs) $(gfigs) titlepage.eps \
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

$(texname).dvi $(texname).idx: $(texname).tex titlepage.eps.in $(includes) $(psfigs) $(gfigs)
	sed -e "s,%date%,`date +"%d %h %Y"`,g" <$(srcdir)/titlepage.eps.in >titlepage.eps
	$(INPUT_ENV) $(LATEX) $(LATEX_ARGS) $(srcdir)/$(texname)
	$(INPUT_ENV) $(LATEX) $(LATEX_ARGS) $(srcdir)/$(texname)
	$(INPUT_ENV) $(LATEX) $(LATEX_ARGS) $(srcdir)/$(texname)
	$(MAKEINDEX) $(texname).idx
	$(INPUT_ENV) $(LATEX) $(LATEX_ARGS) $(srcdir)/$(texname)

$(texname)_US.ps.gz: $(texname).dvi
	$(INPUT_ENV) dvips -tletter -y940 -o $(texname)_US.ps $(texname)
	gzip -f --best $(texname)_US.ps
	rm -f $(texname)_US.ps

# Generating figures from .fig and .g(nuplot) files

.fig.ps:
	$(FIG2DEV) -L ps -p dummy_arg $< $@

.g.ps:
	$(GNUPLOT) $<
