#!/bin/csh -fe

# Set calibrated visibility file and source to observe
set vis = reduced/cs070.1E_110NGC106.2_narrow.mir
set source =  ngc1068
set region = "region=arcsec,box(-5,-5,5,5)"
set cutoff = 1.0  # Cutoff flux for cleaning image in Jy

# Set output images
set out = $source
rm -rf $out.{map,beam,cc,cm}

# Make dirty map. 
invert vis=$vis map=$out.map beam=$out.beam \
       select="source($source),win(6)" cell=2 imsize=129 \
       robust=2 options=systemp,double,mosaic,mfs

# Clean image.
mossdi map=$out.map beam=$out.beam out=$out.cc cutoff=1 $region niters=100

# Restore image
restor map=$out.map beam=$out.beam model=$out.cc out=$out.cm

# Display cleaned image
cgdisp device=/xs in=$out.cm options=full labtyp=arcsec beamtyp=b,l \
       options=full,wedge chan=4,4 region="arcsec,box(-50,-50,50,50)"

