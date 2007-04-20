#!/bin/csh -vf

echo "   ---  CARMA Mosaicing Sensitivity  ---   "
echo "   $0 This script assumes that the first 6 antennas are OVRO and the next 9 are hatcreek"
echo "   mchw. 20 april 2007"

# History:
#  15aug02 mchw. edited from ALMA script.
#  23aug02 mchw. calculate region from source size.
#  20apr07 mchw. plot sensitivity for CARMA mosaic

# Nyquist sample time = 12 x (dish_diam/2)/(pi*baseline)/Npointings
# calc '12*(10.4/2)/(pi*2000)' = 0.01 hours = 36 sec/Npointings
# calc '12*(6.1/2)/(pi*1150)'  = 0.01 hours = 36 sec/Npointings
# Nyquist sample rate for each pointing. Using max baseline 250m.
calc '12*(10.4/2)/(pi*250)' = 0.08 hours or 0.01 hours for 7 pointings.


goto start
start:

# check inputs
  if($#argv<2) then
    echo " Usage:  $0 array declination "
    echo "   e.g.  $0 config1 30 0.04"
    echo " Inputs :"
    echo "   array"
    echo "          Antenna array used by uvgen task."
    echo "            e.g. config1 . No default."
    echo "   declination"
    echo "          Source declination in degrees. No default."
    echo " "
    exit 1
  endif

set config  = $1
set dec     = $2
set harange = -2,2,.016
set harange = -2,2,.008
set ellim   = 10
set select = '-shadow(6.1)'
set freq    = 115
set nchan   = 1
set imsize  = 257

echo "   ---  CARMA Mosaicing (Cas A model)   ---   " > timing
echo " config  = $config"            >> timing
echo " dec     = $dec"               >> timing
echo " harange = $harange  hours"    >> timing
echo " select  = $select"            >> timing
echo " freq    = $freq"              >> timing
echo " nchan   = $nchan"             >> timing
echo " imsize  = $imsize"            >> timing
echo " "                             >> timing

echo "Generate mosaic grid for larger (OVRO) antennas"
#  lambda/2*antdiam (arcsec)
calc "300/$freq/2/10.4e3*2e5" = 12.5'' 

echo "Using hex19_50 mosaic with 50'' spacing"

# assume aperture efficiency 75% to get jyperk
echo "Generate uv-data. Tsys=80,290,0.26, bandwidth=4 GHz " >> timing
rm -r carma.uv ovro.uv hatcreek.uv
uvgen ant=$config.ant baseunit=-3.33564 radec=23:23:25.803,$dec lat=37.02 harange=$harange source=$MIRCAT/no.source systemp=80,290,0.26 jyperk=73 freq=$freq corr=$nchan,1,0,4000 out=carma.uv telescop=carma ellim=$ellim center=@hex19_50
uvgen ant=$config.ant baseunit=-3.33564 radec=23:23:25.803,$dec lat=37.02 harange=$harange source=$MIRCAT/no.source systemp=80,290,0.26 jyperk=43  freq=$freq corr=$nchan,1,0,4000 out=ovro.uv telescop=ovro ellim=$ellim center=@hex19_50
uvgen ant=$config.ant baseunit=-3.33564 radec=23:23:25.803,$dec lat=37.02 harange=$harange source=$MIRCAT/no.source systemp=80,290,0.26 jyperk=126 freq=$freq corr=$nchan,1,0,4000 out=hatcreek.uv telescop=hatcreek ellim=$ellim center=@hex19_50
uvindex vis=carma.uv

# select baselines for each antenna type

rm -r carma.$dec.uv ovro.$dec.uv hatcreek.$dec.uv
uvcat vis=carma.uv 'select=ant(1,2,3,4,5,6)(7,8,9,10,11,12,13,14,15)' out=carma.$dec.uv
uvcat vis=ovro.uv  'select=ant(1,2,3,4,5,6)(1,2,3,4,5,6)' out=ovro.$dec.uv
uvcat vis=hatcreek.uv  'select=ant(7,8,9,10,11,12,13,14,15)(7,8,9,10,11,12,13,14,15)' out=hatcreek.$dec.uv

# make image and list sensitivity for each field

rm -r $config.$dec.mp $config.$dec.bm
invert vis=carma.$dec.uv,ovro.$dec.uv,hatcreek.$dec.uv map=$config.$dec.mp beam=$config.$dec.bm imsize=$imsize sup=0 options=mosaic,double select=$select
echo INVERT: `date` >> timing
implot in=$config.$dec.mp device=/xs units=s
imlist in=$config.$dec.mp options=mosaic

# plot image and plot sensitivity for each field

rm -r $config.$dec.mp.sen $config.$dec.mp.gain
mossen in=$config.$dec.mp sen=$config.$dec.mp.sen gain=$config.$dec.mp.gain
cgdisp in=$config.$dec.mp,$config.$dec.mp.sen type=pix,con device=/xs labtyp=arcsec options=full
cgdisp in=$config.$dec.mp,$config.$dec.mp.sen type=pix,con device=/xs labtyp=arcsec options=full device=$config.$dec.mp.ps/ps

end:
