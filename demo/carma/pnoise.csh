#!/bin/csh -f

echo "Performance tests for CARMA imaging"

# mchw 15apr10
# 18apr03 added uvrange. 
# 22mar05 added harange. 
# 09may05 add more parameters to title.
# 20mar06 CARMA version.
# 27may09 added weighting options to input parameters.
# 27oct09 clean up doc.
# 15apr10 select on parameter line allows  uvdata selection.
# 18oct12 modified to print clean max, flux and rms with added pnoise


# Nyquist sample time = 12 x 3600 s x (dish_diam/2)/(pi*baseline)
# calc '12*3600*3/(pi*700)' = 59s
# 1 min = 0.01666 hours is Nyquist sample interval at 700 m

goto start
start:

# check inputs
  if($#argv<7) then
    echo " Usage:   $0   config   declination  harange  nchan  weighting pnoise"
    echo " e.g:   mfs.csh  carma_A     -30      0,.1,.1    1       sup=0   30"
    echo "   config"
    echo "          Antenna configuration. "
    echo "            e.g. carma_A   Omit the .ant. No default."
    echo "   declination"
    echo "          Source declination in degrees. No default."
    echo "   harange"
    echo "          HA range: start,stop,interval in hours. No default."
    echo "   nchan"                                                                 
    echo "          Number of spectral channels. No default."
    echo "   weighting"
    echo "          weighting options: 'sup=0',  'robust=0.5', uniform. No default."
    echo "   select"
    echo "          uvdata selection. e.g. '-shadow(6.1)'. No default."
    echo "   pnoise"
    echo "          phase noise in degrees  e.g. 30.  No default."
    echo " "
    exit 1
  endif

set config     = $1
set dec        = $2
set harange    = $3
set nchan      = $4
set weighting  = $5
set select     = $6
set pnoise     = $7
set freq       = 230
set imsize     = 256 
set systemp    = 80,290,0.26 
set jyperk     = 73 
set bandwidth  = 500
set region     = 'relpix,box(-30,-30,30,30)'


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
echo " pnoise    =  $pnoise"            >> timing
echo " " >> timing
echo "   ---  TIMING   ---   "          >> timing
echo START: `date` >> timing

goto continue
continue:

echo generate uv-data
rm -r $config.$dec.uv
uvgen ant=$config.ant baseunit=-3.33564 radec=23:23:25.803,$dec lat=37.233 harange=$harange source=$MIRCAT/point.source systemp=$systemp jyperk=$jyperk freq=$freq corr=$nchan,1,1,$bandwidth out=$config.$dec.uv ellim=10 pnoise=$pnoise
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
clean map=$config.$dec.mp beam=$config.$dec.bm out=$config.$dec.cl niters=1000
echo CLEAN: `date` >> timing
restor map=$config.$dec.mp beam=$config.$dec.bm out=$config.$dec.cm model=$config.$dec.cl
echo IMFIT: `date` >> timing

echo fit clean map and get Peak, Total Flux, FWHM, Rms.
imfit in=$config.$dec.cm object=gauss 'region=relpix,box(-10,-10,10,10)' > `pwd`/imfit.txt 
echo FINISH: `date` >> timing
echo " " >> timing


echo print out results - summarize Gaussian fit, RMS and TBRMS in mJy and mK
echo "   ---  RESULTS   ---   " >> timing
set RMS = `itemize in=$config.$dec.mp | grep rms | awk '{printf("%.2f   ", 1e3*$3)}'`
set BMAJ=` egrep "Major axis" imfit.txt  | awk '{printf("%.4f   ", $4)}'`
set BMIN=` egrep "Minor axis" imfit.txt  | awk '{printf("%.4f   ", $4)}'`
set SRMS=` egrep RMS          imfit.txt  | awk '{printf("%.4f   ", $4)}'`
set SMAX=` egrep Peak         imfit.txt  | awk '{printf("%.4f   ", $3)}'`
set SMIN=` egrep Total        imfit.txt  | awk '{printf("%.4f   ", $4)}'`
grep records $config.$dec.uv/history >> timing
grep phases $config.$dec.uv/history >> timing
# get number of visibilities written and number unshadowed
set records = `grep records $config.$dec.uv/history | awk '{print $2}'`
set Nvis = `calc "100*$nvis/$records/$nchan" | awk '{printf("%.0f\n",$1)}'`
set uvrange = `uvcheck vis=$config.$dec.uv    | awk '{if(NR==6)print 0.3*$6, 0.3*$7}'`
echo " " >> timing
echo "Config  DEC    HA  Nchan   Rms     FWHM      Gaussian fit     Nvis   uvrange  weighting pnoise"  >> timing
echo "        deg.   hrs.       [mJy]    [arcsec]      Rms , Max, Flux [Jy],   #   [m]" >> timing
echo  "$config  $dec  $harange  $nchan    $RMS    $BMAJ  $BMIN   $SRMS  $SMAX  $SMIN  $Nvis  $nvis  $uvrange $weighting  $pnoise" >> timing
echo " "
echo  "$config  $dec  $harange  $nchan    $RMS    $BMAJ x $BMIN   $SRMS  $SMAX  $SMIN  $Nvis  $nvis  $uvrange $weighting $pnoise" >> beams.results
mv timing $config.$dec.$harange.$nchan.$imsize.$nvis
cat $config.$dec.$harange.$nchan.$imsize.$nvis
