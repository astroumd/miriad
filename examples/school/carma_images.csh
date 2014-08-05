#!/bin/csh -fe

# Set calibrated visibility file and source to image
set vis = reduced/test.m51sn.1_wide.mir
set source =  m51sn
set region = "region=arcsec,box(-3,4,3,10)"
set cutoff = 0.5e-3  # Jansky's

# Set output images
set out = $source

# Remove any existing images since miriad will not overwrite them
rm -rf $out.{map,beam,cc,cm,snr,sen,gain,psf,psf.log}

# Make dirty map
invert vis=$vis map=$out.map beam=$out.beam \
       select="source($source)" cell=2 imsize=129 \
       robust=2 options=systemp,mfs,mosaic,double

# Get FWHM beam size
mospsf beam=$out.beam out=$out.psf
set log = $out.psf.log
imfit in=$out.psf object=beam 'region=arcsec,box(-5,-5,5,5)' > $log
set bmaj=`grep "Major axis" $log | awk '{print $4}'`
set bmin=`grep "Minor axis" $log | awk '{print $4}'`
set bpa=`grep "  Position angle" $log | awk '{print $4}'`
echo "Beam size = $bmaj x $bmin arcsec at PA = $bpa deg"

# Clean image
mossdi map=$out.map beam=$out.beam out=$out.cc cutoff=$cutoff $region niters=10000

# Restore image
restor map=$out.map beam=$out.beam model=$out.cc out=$out.cm fwhm=$bmaj,$bmin pa=$bpa

# Create theoretical noise image
rm -rf $out.sen $out.gain $out.snr
mossen in=$out.map sen=$out.sen gain=$out.gain
maths exp="<$out.cm>/<$out.sen>" out=$out.snr

# Display images
cgdisp device=1/xs in=$out.cm  options=full labtyp=arcsec beamtyp=b,l options=full,wedge
cgdisp device=2/xs in=$out.snr options=full labtyp=arcsec beamtyp=b,l options=full,wedge

