#!/bin/csh -vf


# MOSAIC Image Cas A at x-band with 40 X sized Cas A model  with added thermal noise.

set config  = L8a_2
set dec     = 28:48:58.300
set freq    = 1.42
set harange = 0,0.16,0.016
set nchan   = 20

echo "   ---  ATA Mosaicing (Cas A model)   ---   " > timing
echo " config  = $config"            >> timing
echo " dec     = $dec"               >> timing
echo " freq    = $freq"              >> timing
echo " harange = $harange  hours"    >> timing
echo " nchan   = $nchan"             >> timing
echo " "                             >> timing
echo "   ---  TIMING   ---   "       >> timing
echo START: `date` >> timing


goto start
start:

# Generate a hex7 grid for source declination
grid spacing lambda/2 antdiam = 3442 arcsec

# Generate a uv-snapshot at the declination of the model image
# observing center changes every integration so make stop time = number of pointings
echo "Generate uv-data. Tsys=40K, bandwidth=400 MHz " >> timing
rm -r hex7.uv
uvgen ant=L8a_2.ant baseunit=-3.33564 radec=23:23:25.803,28:48:58.300 baseunit=-3.33564 pnoise=0 out=hex7.uv\
 harange=$harange source=$MIRCAT/no.source systemp=40 freq=$freq corr=20,1,0,400  center=@hex7
echo UVGEN: `date` >> timing


# Make beam for ATA
  rm -r hex7.mp hex7.bm hex7.cl hex7.cm
  invert vis=hex7.uv map=hex7.mp beam=hex7.bm cell=0 imsize=129 sup=0 options=mosaic,mfs,double 'select=dra(0),ddec(0)'
# Visibilities accepted: 1221500  Theoretical rms noise: 8.108E-05
  clean map=hex7.mp beam=hex7.bm niters=1 out=hex7.cl
  restor map=hex7.mp beam=hex7.bm model=hex7.cl out=hex7.cm
  implot in=hex7.cm device=/xs units=s conflag=l conargs=1.7
  rm -r residual
  imfit in=hex7.bm object=gauss 'region=relpix,box(-30,-30,30,30)' out=residual options=residual
  histo in=residual


# Primary beam and field of view
pbplot telescop=hatcreek freq=  1.42  4.4149  11.2 GHz
#  FWHM (arcmin):              135    43.41   17.11 
#  Cutoff Radius:              140    45.13   17.79
#  Cutoff Value:              0.050
#  lambda/2*antdiam (arcmin):   59.2  19       7.5			  
#  lambda/2*uvmax (arcsec):	   28.8    9.25    3.6

# Make model uv-data using VLA image of Cas A as a model (the model has the VLA primary beam)
# change the pixel size to scale the image size ; 
# original pixel size =0.4 '' at crval3  : 4.4149    cdelt1  : -0:00:00.400   cdelt2  : 0:00:00.400
# CasA is about 5 arcmin diameter
  puthd in=cas40.vla/crval3 value=$freq
  puthd in=cas40.vla/cdelt1 value=-0:00:16.0,dms
  puthd in=cas40.vla/cdelt2 value=0:00:16.0,dms
  puthd in=cas40.vla/crval2 value=28:48:58.300,dms

# demosaic the model image
rm -r cas40.demos*
demos vis=hex7.uv map=cas40.vla out=cas40.demos
cgdisp in=cas40.demos1 device=/xs labtyp=hms,dms range=0,0,lin,8 options=wedge,beambl
cgdisp in=cas40.demos1 device=cas40.demos1.gif/gif labtyp=hms,dms range=0,0,lin,8 options=wedge,beambl
cgdisp in=cas40.demos7 device=cas40.demos7.gif/gif labtyp=hms,dms range=0,0,lin,8 options=wedge,beambl
mv cas40.demos1.gif /falcon/wright/public_html
mv cas40.demos7.gif /falcon/wright/public_html


# add the model to the uvdata

  foreach i ( 1 2 3 4 5 6 7 )
	rm -r cas40.uv$i
    uvmodel vis=hex7.uv model=cas40.demos$i options=add,mfs,selradec out=cas40.uv$i
  end
#Fatal Error:  No visibility data selected, in Model(map) for top and bottom rows
# image is 1024 x 16 arcsec/pixel, pointing grid is

#  -3416.84,2980.86
#   3416.84,2980.86
#  -6644.44,0.00
#      0.00,0.00
#   6644.44,0.00
#  -3233.58,-2980.86
#   3233.58,-2980.86

# The same grid works if I set the source declination to 28 instead of 58 degrees.


  rm -r cas40.mp cas40.bm
  invert "vis=cas40.uv*" map=cas40.mp beam=cas40.bm cell=0 imsize=1025 sup=0 options=mfs,double,mosaic
#  implot in=cas40.mp device=/xs units=s
#  cgdisp in=cas40.mp device=/xs labtyp=hms,dms options=beambl,wedge range=0,0,lin,8
# Theoretical rms noise: 8.11E-05
# Iter =100 RmsFac = 7.637E+00 Flux = 7.537E+02 NormGrd = 0.069
# Failed to converge in NITERS iterations

  rm -r cas40.mem cas40.memcm
  mosmem map=cas40.mp beam=cas40.bm out=cas40.mem niters=200 rmsfac=5
  restor map=cas40.mp beam=cas40.bm model=cas40.mem out=cas40.memcm
  implot in=cas40.memcm device=/xs units=s
  implot in=cas40.memcm device=/ps units=s
#lp -d p433 pgplot.ps
  cgdisp range=0,0,lin,8 in=cas40.memcm device=cas40.ata.mfs.gif/gif labtyp=hms,dms options=beambl,wedge
  mv cas40.ata.mfs.gif ~/public_html

# convolve the model by the beam and substract from the deconvolved image
  set b1=`prthd in=cas40.memcm | egrep Beam     | awk '{print $3}'`
  set b2=`prthd in=cas40.memcm | egrep Beam     | awk '{print $5}'`
  set b3=`prthd in=cas40.memcm | egrep Position | awk '{print $3}'`
  rm -r cas40.conv
  convol map=cas40.vla fwhm=$b1,$b2 pa=$b3 out=cas40.conv
  rm -r cas40.regrid
  regrid in=cas40.conv out=cas40.regrid tin=cas40.memcm axes=1,2
  implot in=cas40.conv device=/xs units=s
  cgdisp range=0,0,lin,8 in=cas40.conv device=cas40.ata.vla.gif/gif labtyp=hms,dms options=beambl,wedge
  mv cas40.ata.vla.gif ~/public_html

# residual with MAXEN deconvolution
  rm -r cas40.resid
  imdiff in1=cas40.memcm in2=cas40.regrid resid=cas40.resid
  implot device=/xs units=s in=cas40.resid
  histo in=cas40.resid 
  cgdisp range=0,0,lin,8 in=cas40.resid device=cas40.ata-vla.gif/gif labtyp=hms,dms options=beambl,wedge
  mv cas40.ata-vla.gif ~/public_html
goto end

# mosmem 7 fields
# residual rms=4.86 max/min=55/-22 mJy.  Flux in memcm=497, in cas40.conv=732 Jy

end:
