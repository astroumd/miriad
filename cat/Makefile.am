include $(top_srcdir)/mircommon.mak

EXTRA_DIST = 0.122.ant 0.122b.ant 0.375.ant 0.75a.ant 0.75b.ant \
  0.75c.ant 0.75d.ant 1.5a.ant 1.5b.ant 1.5c.ant 1.5d.ant \
  3.0a.ant 3.0b.ant 3.0c.ant 3.0d.ant 3km_min_red_1.ant \
  3km_min_red_2.ant 3km_min_red_3.ant 3km_min_red_4.ant \
  a.ary a++.ary ary.doc at.corr.1 at.corr.32 at.corr.mfs \
  atmos.1997 b.ary beamgen.source bima9_a96.ant.equ bima9_a.ant \
  bima9_ab.ant bima9_b.ant bima9_c.ant.equ bima_a1mm.ant \
  bima_a99.ant bima_a.ant bima_a++.ant bima_a.antpos bima_ab.ant \
  bima_b.ant bima_b.antpos bima_c.ant bima_c.antpos bima_d.ant \
  bima_d.antpos cals.fluxes cals.pfluxes carma_A.ant \
  carma_ABCDE.ant carma_B.ant carma_BCDE.ant carma_C.ant carma_CDE.ant \
  carma_CZ.ant carma_D.ant carma_DE.ant carma_de.04oct.ant \
  carma_DZ.ant carma_E.ant carma_EZ.ant c.ary ew214.ant ew352.ant \
  ew367.ant h168.ant h214.ant h75.ant hc.pad hermes.in hermes.txt \
  keywords.kdoc lovas.1mm lovas.3mm lovas3mm.dat miriad.pgmrs \
  no.source ns214.ant ovro_phase.1996 poff.source point.source \
  qpoint.source recom.lis select.kdoc spiral.source stations.1985 \
  stations.1986 stations.1987 stations.1988 stations.1989 \
  stations.1990 stations.1991 stations.list stations.pl \
  stations.txt target.stn uvctlg uvgen.corr uvgen.def.at \
  uvgen.def.at.mfs uvgen.def.vla uvgen.source vla_a.ant \
  vla_b.ant vla_c.ant vla_d.ant walpol.9ant wishlist

# Generate and install the keyword documentation files.

pdoc_DATA = device.kdoc in.kdoc line.kdoc options.kdoc out.kdoc \
  region.kdoc select.kdoc server.kdoc stokes.kdoc vis.kdoc \
  window.kdoc

$(pdoc_DATA): keyword-doc.stamp

keyword-doc.stamp: keywords.kdoc
	$(DOC) -p $<
	touch $@

