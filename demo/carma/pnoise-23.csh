#!/bin/csh -f

# mchw 12jun02 - Single Field Imaging
# mchw 09aug02 - version for CARMA
# mchw 14aug02 - reduce size of region in imfit which was including sidelobes in relpix +/- 10
# mchw 20aug02 - hetero.csh This script assumes that the first 6 antennas are OVRO and the next 9 are sza
# mchw 26sep02 - decrease Nyquist sample interval for 2 km configuration.
# mchw 17dec02 - print uvrange in results summary.
# mchw 21mar03 - clean up.
# mchw 09jun04 - all correlations with SZA.
# mchw 29jun04 - get uvmin from sza, uvmax from cross antennas. 
# mchw 04nov2011 - pnoise-23.csh.

# Nyquist sample time = 12 x (dish_diam/2)/(pi*baseline)
# calc '12*(10.4/2)/(pi*2000)' = 0.01 hours = 36 sec.
# calc '12*(6.1/2)/(pi*1150)'  = 0.01 hours = 36 sec.

echo "   ---  CARMA PACS for atmospheric phase noise  ---   "
echo "   $0 assumes that the first 15 antennas are 10.4 or 6.1 and the next 8 are SZA"
echo "   mchw. 20aug2002"

goto start
start:

# check inputs
  if($#argv<3) then
    echo " Usage:  $0 array declination "
    echo "   e.g.  $0 config1 30"
    echo " Inputs :"
    echo "   array"
    echo "          Antenna array used by uvgen task."
    echo "            e.g. config1 . No default."
    echo "   declination"
    echo "          Source declination in degrees. No default."
    echo "   pnoise"
    echo "          Phase noise, in degrees. Up to 4 values"
    echo " pnoise(1) + pnoise(2)*(baseline)**pnoise(3)*sinel**pnoise(4)"
    echo " baseline length in 100m units. Typical values:"
    echo " pnoise(2) are 1mm rms pathlength (e.g. 2 radians at 100 GHz),"
    echo " Kolmogorov turbulence pnoise(3)=5/6 for baseline < 100m"
    echo " 0.33 for baseline > 100m (outer scale of turbulence)."
    echo " pnoise(4)=-0.5 for thick turbulent screen, and -1 for thin layer."
    echo " Default is 0,0,0,0 (no phase error)."
Source declination in degrees. No default."
    echo " "
    exit 1
  endif

# set parameters
set config  = $1
set dec     = $2
set pnoise  = $3
set harange = -4,4,.1
set ellim   = 10
set select = '-shadow(10.4)'
set select = '-shadow(3.5)'
set select = '-shadow(6.1)'
set freq    = 230
set nchan   = 1
set imsize  = 256
set  baseunit = -3.33564
set  baseunit = 1
set region  =  'relpix,box(-30,-30,30,30)'

echo "   ---  CARMA Single Field Imaging    ---   " > timing
echo " config           = $config"             >> timing
echo " declination      = $dec"                >> timing
echo " Hour Angle range = $harange  hours"     >> timing
echo " Elevation limit  = $ellim  degrees. "   >> timing
echo " select           = $select"             >> timing
echo " frequency        = $freq"               >> timing
echo " nchan            = $nchan"              >> timing
echo " imsize           = $imsize"             >> timing
echo " pnoise           = $pnoise"             >> timing
echo " " >> timing
echo "$0 assumes that the first 15 antennas are 10.4 or 6.1 and the next 8 are SZA" >> timing
echo "Using 73 Jyperk for 10.4 and 6.1,  383 for SZA, and sqrt(383*73) = 167 for carma-sza correlations" >> timing

echo "   ---  TIMING   ---   "        >> timing
echo START: `date` >> timing

goto continue
continue:

echo generate uv-data
# assume aperture efficiency 75% to get jyperk
echo "Generate uv-data. Tsys=40K, bandwidth=4 GHz " >> timing
rm -r cross.uv carma.uv sza.uv
uvgen ant=$config.ant baseunit=$baseunit radec=23:23:25.803,$dec lat=37.02 harange=$harange source=$MIRCAT/point.source systemp=80,290,0.26 jyperk=167 freq=$freq corr=$nchan,1,0,4000 out=cross.uv telescop=ovro ellim=$ellim pnoise=$pnoise

uvgen ant=$config.ant baseunit=$baseunit radec=23:23:25.803,$dec lat=37.02 harange=$harange source=$MIRCAT/point.source systemp=80,290,0.26 jyperk=73  freq=$freq corr=$nchan,1,0,4000 out=carma.uv telescop=carma ellim=$ellim  pnoise=$pnoise

uvgen ant=$config.ant baseunit=$baseunit radec=23:23:25.803,$dec lat=37.02 harange=$harange source=$MIRCAT/point.source systemp=80,290,0.26 jyperk=383 freq=$freq corr=$nchan,1,0,4000 out=sza.uv telescop=sza ellim=$ellim pnoise=$pnoise

echo UVGEN: `date` >> timing

# select data for heterogenous array
  rm -r cross.$dec.uv
  rm -r carma.$dec.uv
  rm -r sza.$dec.uv
uvcat vis=cross.uv out=cross.$dec.uv 'select=ant(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15)(16,17,18,19,20,21,22,23)' 
uvcat vis=carma.uv  out=carma.$dec.uv  'select=-ant(16,17,18,19,20,21,22,23)'
uvcat vis=sza.uv out=sza.$dec.uv 'select=-ant(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15)'

uvplt vis=cross.$dec.uv,carma.$dec.uv,sza.$dec.uv axis=uc,vc options=nobase,equal select=$select device=/xs 
uvplt vis=cross.$dec.uv,carma.$dec.uv,sza.$dec.uv axis=uc,vc options=nobase,equal select=$select device=$config.$dec.ps/cps
uvplt vis=sza.$dec.uv,cross.$dec.uv,carma.$dec.uv axis=uvd,ph options=nobase select=$select device=/xs 

echo image
# natural weight
rm -r $config.$dec.mp $config.$dec.bm
set nvis = `invert options=systemp vis=cross.$dec.uv,carma.$dec.uv,sza.$dec.uv map=$config.$dec.mp beam=$config.$dec.bm imsize=$imsize sup=0 select=$select | grep Visibilities | awk '{print $3}'`

echo INVERT: `date` >> timing

echo plotting
implot in=$config.$dec.bm device=/xs units=s conflag=an conargs=0.05
implot in=$config.$dec.bm device=/xs units=s conflag=an conargs=0.05 region=$region
echo IMPLOT: `date` >> timing

echo deconvolve
rm -r $config.$dec.cl $config.$dec.cm
clean map=$config.$dec.mp beam=$config.$dec.bm out=$config.$dec.cl
echo CLEAN: `date` >> timing
restor map=$config.$dec.mp beam=$config.$dec.bm out=$config.$dec.cm model=$config.$dec.cl
implot in=$config.$dec.cm device=/xs units=s region=$region

echo IMFIT: `date` >> timing
#  Peak value:                 0.7320     +/-  7.3921E-03
#  Total integrated flux:      0.8500
#  Offset Position (arcsec):       0.000     0.000
#  Positional errors (arcsec):     0.001     0.001
#  Right Ascension:                23:23:25.803
#  Declination:                    30:00:00.000
#  Major axis (arcsec):           0.165 +/-  0.002
#  Minor axis (arcsec):           0.144 +/-  0.001


echo fit image and get Peak, Major and Minor axis
imfit in=$config.$dec.cm object=gauss 'region=relpix,box(-10,-10,10,10)' > imfit.txt
set FLUX = ` grep Total imfit.txt           | awk '{printf("%.3f  ", $4)}'`
set PEAK = ` grep  Peak imfit.txt           | awk '{printf("%.3f  ", $3)}'`
set SMAJ = ` grep "Major axis"  imfit.txt   | awk '{printf("%.3f  ", $4)}'`
set SMIN = ` grep "Minor axis"  imfit.txt   | awk '{printf("%.3f  ", $4)}'`

echo FINISH: `date` >> timing
echo " " >> timing

echo print out results - summarize rms and sidelobe levels
echo "   ---  RESULTS   ---   " >> timing
echo " pnoise(1) + pnoise(2)*(baseline)**pnoise(3)*sinel**pnoise(4)" >> timing
set RMS = `itemize in=$config.$dec.mp   | grep rms       | awk '{printf("%.2f   ", 1e3*$3)}'`
set BMAJ=`prthd in=$config.$dec.cm      | egrep Beam     | awk '{printf("%.2f   ", $3)}'`
set BMIN=`prthd in=$config.$dec.cm      | egrep Beam     | awk '{printf("%.2f   ", $5)}'`
set TBRMS = `calc "$RMS*.3/$freq*.3/$freq/2/1.38e3/(pi/(4*log(2))*$BMAJ*$BMIN/4.25e10)" | awk '{printf("%.2f ", $1)}'`
# get number of visibilities written and number unshadowed
set ncross = `uvindex vis=cross.$dec.uv | grep "records of polarization I" | awk '{printf("%.0f\n",$3)}'`
set ncarma  = `uvindex vis=carma.$dec.uv | grep "records of polarization I" | awk '{printf("%.0f\n",$3)}'`
set nsza = `uvindex vis=sza.$dec.uv | grep "records of polarization I" | awk '{printf("%.0f\n",$3)}'`
set records = `calc $ncross+$ncarma+$nsza`
set Nvis = `calc "100*$nvis/$records" | awk '{printf("%.0f\n",$1)}'`
#set uvrange = `uvcheck vis="cross.$dec.uv" | awk '{if(NR==6)print 0.3*$6, 0.3*$7}'`
set uvmax = `uvcheck vis="cross.$dec.uv" | awk '{if(NR==6)print 0.3*$7}'`
set uvmin = `uvcheck vis="sza.$dec.uv" | awk '{if(NR==6)print 0.3*$6}'`
echo " " >> timing
echo "Config    DEC    pnoise    HA[hrs]  Rms[mJy]  Beam[arcsec]  Flux    Peak   Major  Minor  Nvis[%]  uvrange[m]" >> timing
echo  "$config  $dec  $pnoise  $harange  $RMS   $BMAJ x $BMIN    $FLUX   $PEAK  $SMAJ  $SMIN  $nvis  $uvmin  $uvmax" >> timing

echo " "
echo  "$config  $dec  $pnoise  $harange  $RMS   $BMAJ x $BMIN    $FLUX   $PEAK  $SMAJ  $SMIN  $Nvis  $uvmin  $uvmax" >> beams.results
mv timing $config.$dec.$harange.$nchan.$imsize.$nvis
#cat $config.$dec.$harange.$nchan.$imsize.$nvis
tail beams.results
