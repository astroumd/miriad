#!/bin/csh -f

echo "Performance tests for CARMA imaging"

# mchw 27jun02
# 18apr03 added uvrange. 
# 22mar05 added harange. 
# 09may05 add more parameters to title.
# 20mar06 CARMA version.


# Nyquist sample time = 12 x 3600 s x (dish_diam/2)/(pi*baseline)
# calc '12*3600*3/(pi*700)' = 59s
# 1 min = 0.01666 hours is Nyquist sample interval at 700 m

goto start
start:

# check inputs
  if($#argv<4) then
    echo " Usage: $0  config  declination  harange  nchan" 
    echo "   config"
    echo "          Antenna configuration. "
    echo "            e.g. config1.ant. Omit the .ant. No default."
    echo "   declination"
    echo "          Source declination in degrees. No default."
    echo "   harange"
    echo "          HA range: start,stop,interval in hours. No default."
    echo "   nchan"                                                                 
    echo "          Number of spectral channels. No default."
    echo " "
    exit 1
  endif

set config     = $1
set dec        = $2
set harange    = $3
set nchan      = $4
set select     = '-shadow(6.1)'
set select     = '-shadow(10.4)'
set freq       = 230
set imsize     = 256 
set systemp    = 80,290,0.26 
set jyperk     = 73 
set bandwidth  = 4000
set weighting  = 'sup=0' 
set weighting  = 'robust=0.5' 
set region  =  'relpix,box(-30,-30,30,30)'


echo "   ---  CARMA Single Field MFS Imaging    ---   " > timing
echo " config    =  $config"            >> timing
echo " dec       =  $dec"               >> timing
echo " harange   =  $harange  hours"    >> timing
echo " nchan     =  $nchan"             >> timing
echo " select    =  $select"            >> timing
echo " freq      =  $freq"              >> timing
echo " imsize    =  $imsize"            >> timing
echo " systemp   =  $systemp"           >> timing
echo " jyperk    =  $jyperk"            >> timing
echo " bandwidth =  $bandwidth"         >> timing
echo " weighting =  $weighting"         >> timing
echo " " >> timing
echo "   ---  TIMING   ---   "          >> timing
echo START: `date` >> timing

goto continue
continue:

echo generate uv-data
rm -r $config.$dec.uv
uvgen ant=$config.ant baseunit=-3.33564 radec=23:23:25.803,$dec lat=37.233 harange=$harange source=$MIRCAT/point.source systemp=$systemp jyperk=$jyperk freq=$freq corr=$nchan,1,1,$bandwidth out=$config.$dec.uv
# pnoise=30
echo UVGEN: `date` >> timing

#echo selfcal
#selfcal vis=$config.$dec.uv interval=1
#echo SELFCAL: `date` >> timing

uvplt vis=$config.$dec.uv device=/xs axis=uc,vc options=nobase,equal


echo image
rm -r $config.$dec.bm $config.$dec.mp
set nvis = `invert options=mfs vis=$config.$dec.uv map=$config.$dec.mp beam=$config.$dec.bm imsize=$imsize $weighting select=$select | grep Visibilities | awk '{print $3}'`
echo INVERT: `date` >> timing

echo plotting
implot in=$config.$dec.bm device=/xs units=s conflag=l conargs=1.4
implot in=$config.$dec.bm device=/xs units=s conflag=an conargs=0.05 region=$region
echo IMPLOT: `date` >> timing

echo deconvolve
rm -r $config.$dec.cl $config.$dec.cm
clean map=$config.$dec.mp beam=$config.$dec.bm out=$config.$dec.cl
echo CLEAN: `date` >> timing
restor map=$config.$dec.mp beam=$config.$dec.bm out=$config.$dec.cm model=$config.$dec.cl
echo IMFIT: `date` >> timing

echo fit beam and get residual sidelobe levels
rm -r residual
imfit in=$config.$dec.bm object=gauss 'region=relpix,box(-10,-10,10,10)' out=residual options=residual
histo in=residual
echo FINISH: `date` >> timing
echo " " >> timing


echo print out results - summarize rms and beam sidelobe levels. RMS and TBRMS in mJy and mK
echo "   ---  RESULTS   ---   " >> timing
set RMS = `itemize in=$config.$dec.mp   | grep rms       | awk '{printf("%.2f   ", 1e3*$3)}'`
set BMAJ=`prthd in=$config.$dec.cm      | egrep Beam     | awk '{printf("%.2f   ", $3)}'`
set BMIN=`prthd in=$config.$dec.cm      | egrep Beam     | awk '{printf("%.2f   ", $5)}'`
set TBRMS = `calc "$RMS*.3/$freq*.3/$freq/2/1.38e3/(pi/(4*log(2))*$BMAJ*$BMIN/4.25e10)" | awk '{printf("%.1f ", $1)}'`
set SRMS = `histo in=residual | grep Rms       | awk '{printf("%.1f  ", 100*$4)}'`
set SMAX = `histo in=residual | grep Maximum   | awk '{printf("%.1f  ", 100*$3)}'`
set SMIN = `histo in=residual | grep Minimum   | awk '{printf("%.1f  ", 100*$3)}'`
grep records $config.$dec.uv/history >> timing
grep phases $config.$dec.uv/history >> timing
# get number of visibilities written and number unshadowed
set records = `grep records $config.$dec.uv/history | awk '{print $2}'`
set Nvis = `calc "100*$nvis/$records/$nchan" | awk '{printf("%.0f\n",$1)}'`
set uvrange = `uvcheck vis=$config.$dec.uv    | awk '{if(NR==6)print 0.3*$6, 0.3*$7}'`
echo " " >> timing
echo "Config  DEC  HA[hrs]  Nchan  Rms[mJy]  Beam[arcsec]  Tb_rms[mK]  Sidelobe[%]:Rms,Max,Min  Nvis[%] uvrange[m]  weighting" >> timing
echo  "$config  $dec  $harange  $nchan  $RMS  $BMAJ  $BMIN   $TBRMS  $SRMS  $SMAX  $SMIN  $Nvis  $nvis  $uvrange"  $weighting >> timing
echo " "
echo  "$config  $dec  $harange  $nchan  $RMS  $BMAJ x $BMIN  $TBRMS  $SRMS  $SMAX  $SMIN  $Nvis  $nvis  $uvrange"  $weighting >> beams.results
mv timing $config.$dec.$harange.$nchan.$imsize.$nvis
cat $config.$dec.$harange.$nchan.$imsize.$nvis
