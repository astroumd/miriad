#!/bin/csh -f

echo "L00k at defects in beam shape"

# mchw 27jun02

# 23sep02 increase image size and decrease Nyquist sample interval for config > 20
# 14dec02 plot imdiff instead of beam


# Nyquist sample time = 12 x 3600 s x (dish_diam/2)/(pi*baseline)
# calc '12*3600*6/(pi*4000)' = 20s = 5.73E-3 hours for 4 km config
# 1 min = 0.01666 hours is Nyquist sample interval at 1.375 km
# PBFWHM = 24"
# field = 24/pixel

goto start
start:

# check inputs
  if($#argv<3) then
    echo " Usage: residual.csh   config   declination" 
    echo "   config"
    echo "          Antenna configuration. "
    echo "            e.g. config1.ant. Omit the .ant. No default."
    echo "   declination"
    echo "          Source declination in degrees. No default."
    echo "   nchan"                                                                 
    echo "          Number of spectral channels. No default."
    echo " "
    exit 1
  endif

set config  = $1
set dec     = $2
set nchan   = $3
set harange = -0.001,0,0.01666
set harange = -1,1,0.0057
set harange = -1,1,0.016
set select = '-shadow(12),-ant(11,12,13,14,15,16)'
set freq    = 230
set imsize  = 0


echo "   ---  ALMA Single Field MFS Imaging    ---   " > timing
echo " config  = $config"             >> timing
echo " dec     =  $dec"               >> timing
echo " harange =  $harange  hours"    >> timing
echo " select  =  $select"            >> timing
echo " freq    =  $freq"              >> timing
echo " nchan   = $nchan"              >> timing
echo " imsize  = $imsize"             >> timing
echo " " >> timing
echo "   ---  TIMING   ---   "        >> timing
echo START: `date` >> timing

goto continue

echo generate uv-data
rm -r $config.$dec.uv
uvgen ant=$config.ant baseunit=-3.33564 radec=23:23:25.803,$dec lat=-23.02 harange=$harange source=$MIRCAT/point.source telescop=alma systemp=40 jyperk=40 freq=$freq corr=$nchan,1,1,8000 out=$config.$dec.uv
# pnoise=30
echo UVGEN: `date` >> timing

#echo selfcal
#selfcal vis=$config.$dec.uv interval=1
#echo SELFCAL: `date` >> timing

continue:

echo image
rm -r $config.$dec.bm $config.$dec.mp
set nvis = `invert options=mfs vis=$config.$dec.uv map=$config.$dec.mp beam=$config.$dec.bm imsize=$imsize sup=0 select=$select | grep Visibilities | awk '{print $3}'`
echo INVERT: `date` >> timing

echo plotting
implot in=$config.$dec.bm device=/xs units=s conflag=l conargs=1.4 region=quarter
echo IMPLOT: `date` >> timing

echo deconvolve
rm -r $config.$dec.cl $config.$dec.cm
clean map=$config.$dec.mp beam=$config.$dec.bm out=$config.$dec.cl
echo CLEAN: `date` >> timing
restor map=$config.$dec.mp beam=$config.$dec.bm out=$config.$dec.cm model=$config.$dec.cl

echo IMFIT: `date` >> timing

echo fit beam and get residual sidelobe levels
rm -r residual
imfit in=$config.$dec.bm object=gauss 'region=relpix,box(-25,-25,25,25)' out=residual options=residual
implot in=residual device=/xs units=s conflag=an conargs=0.025 'region=relpix,box(-25,-25,25,25)'
#histo in=residual
echo FINISH: `date` >> timing
echo " " >> timing


echo print out results - summarize rms and beam sidelobe levels. RMS and TBRMS in \muJy and  \muK
echo "   ---  RESULTS   ---   " >> timing
set RMS = `itemize in=$config.$dec.mp   | grep rms       | awk '{printf("%.1f   ", 1e6*$3)}'`
set BMAJ=`prthd in=$config.$dec.cm      | egrep Beam     | awk '{printf("%.2f   ", $3)}'`
set BMIN=`prthd in=$config.$dec.cm      | egrep Beam     | awk '{printf("%.2f   ", $5)}'`
set TBRMS = `calc "$RMS*.3/$freq*.3/$freq/2/1.38e3/(pi/(4*log(2))*$BMAJ*$BMIN/4.25e10)" | awk '{printf("%.0f ", $1)}'`
set SRMS = `histo in=residual | grep Rms       | awk '{printf("%.1f  ", 100*$4)}'`
set SMAX = `histo in=residual | grep Maximum   | awk '{printf("%.1f  ", 100*$3)}'`
set SMIN = `histo in=residual | grep Minimum   | awk '{printf("%.1f  ", 100*$3)}'`
grep records $config.$dec.uv/history >> timing
grep phases $config.$dec.uv/history >> timing
# get number of visibilities written and number unshadowed
set records = `grep records $config.$dec.uv/history | awk '{print $2}'`
calc "$nvis/$records"
set Nvis = `calc "100*$nvis/$records/$nchan" | awk '{printf("%.0f\n",$1)}'`
echo " " >> timing
echo " Config  DEC  Nchan HA[hrs]  Rms[\muJy]  Beam[arcsec] Tb_rms[\muK] Sidelobe[%]:Rms,Max,Min Nvis[%]" >> timing
echo  "$config  $dec  $nchan  $harange  $RMS   $BMAJ $BMIN    $TBRMS   $SRMS  $SMAX  $SMIN  $nvis" >> timing
echo " "
echo  "$config  $dec  $nchan  $harange   $RMS   $BMAJ x $BMIN   $TBRMS   $SRMS   $SMAX   $SMIN   $Nvis" >> beam_shape.results
mv timing $config.$dec.$harange.$nchan.$imsize.$nvis
cat $config.$dec.$harange.$nchan.$imsize.$nvis

end:
