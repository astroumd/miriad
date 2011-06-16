#! /bin/csh -f
#
#  IRAF and SPITZER maps are in MJy/sr, miriad typically uses JY/BEAM
#  this makes comparison a little harder between radio and IR/FIR.
#  Recall:   1 Jy = 1e-26 W/Hz/m^2
#
#  This script will convert the map and units. Warning: SPITZER maps
#  will come with a rotation, after fits the angle encoded in the
#  llrot item. If you loose this, regrid will not be able to
#  rotate your map easily.
#  regrid in=sp1 out=sp1_r tin=carma
#

#  in SPITZER maps you would sum the intensities, and multiply
#  by P^2 (P=pixel size in radians) and 1e6 and get Jy.
#  New version of HISTO now does this.
#  in MIRIAD maps you would sum the intensities and divide by
#  the number of points per beam, i.e. 1.1331 * B^2/P^2, where
#  B = FHWM of beam, and again P = pixelsize
#


# set the beam in arcsec
# formally, the beams in the 4 IRAC bands are 1.6, 1.6, 1.8 and 1.9"
set b=2.2

#
set in=SPITZER_I1_5524480_0000_6_E8755324_maic.fits
set out=sp1


foreach arg ($*)
  set $*
end

# scaling factor from Spitzer to Miriad to get jy/beam
set alpha=`calc "206265*206265/($b*$b*1.1331*1000000)"`

echo alpha=$alpha
echo Working on $in


# method 1, using maths


# clean
rm -rf $in.mir $out
# convert
fits in=$in out=$in.mir op=xyin
maths exp="<$in.mir>/$alpha" out=$out
puthd in=$out/bunit value=JY/BEAM   
puthd in=$out/bmaj  value=$b,arcsec type=real
puthd in=$out/bmin  value=$b,arcsec type=real
puthd in=$out/bpa   value=0.0       type=real

# check if the flux is now the same
histo in=$in.mir  | grep ^Mean
histo in=$out     | grep ^Mean



# method 2, using convol, but it needs to copy llrot for later regrid, if need
# this is more fishy, convol seems to do other things....



