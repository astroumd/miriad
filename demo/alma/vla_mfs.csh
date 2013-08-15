#!/bin/csh -f

echo "Performance tests for VLA imaging"

# mchw 27jun02
# 18apr03 added uvrange.
# 22mar05 added harange.
# 09may05 add more parameters to title.
# 27may09 added weighting options to input parameters.
# 18oct09 version with imsize=0 and shadow=12m for ALMA 
# 27oct09 clean up doc.
# 15apr10 select on parameter line allows  uvdata selection.
# 02dec10 fix some formats.
# 14aug13 vla_mfs version with imsize=0 and shadow=25m for VLA 

# Nyquist sample time = 12 x 3600 s x (dish_diam/2)/(pi*baseline)
# calc '12*3600*6/(pi*4000)' = 20s = 5.73E-3 hours for 4 km config
# 1 min = 0.01666 hours is Nyquist sample interval at 1.375 km
# PBFWHM = 24"
# field = 24/pixel
# old configurations:
# config   uvmin  uvmax(m)  fwhm   pixel(")  field(pixel) Nyquist
#   1       14.4    159     1.6    0.425        57        8.65 min
#  10       14.4    415     1.0    0.174       138        3.3
#  20       14.7   1046     0.36   0.067       358        1.3
#  30       36.6   2832     0.14   0.025       960        0.48 = 29s = 8.1E-3
#  35       36.6   4153     0.09   0.017      1412        0.33 = 20s = 5.73E-3 hrs

goto start
start:

# check inputs
  if($#argv<6) then
    echo " Usage:     $0   config   declination  harange  nchan  weighting" 
    echo " e.g:  vla_mfs.csh   vla_c     -30     -1,1,.1    1       sup=0"
    echo "   config"
    echo "          Antenna configuration. "
    echo "            e.g. config1    Omit the .ant. No default."
    echo "   declination"
    echo "          Source declination in degrees. No default."
    echo "   harange"
    echo "          HA range: start,stop,interval in hours. No default."
    echo "   nchan"                                                                 
    echo "          Number of spectral channels. No default."
    echo "   weighting"
    echo "          weighting options: 'sup=0',  'robust=0.5', uniform. No default."
    echo "   select"
    echo "          uvdata selection. e.g. '-shadow(25)'. No default."
    echo " "
    exit 1
  endif

set config    = $1
set dec       = $2
set harange   = $3
set nchan     = $4
set weighting = $5
set select    = $6
set antdiam   = 12
set freq      = 1.42
set imsize    = 1024
set imsize    = 0
set imsize    = 256
# imsize      = 0 lets invert choose the image size with ~ 1.5 x Nyquist sampling.
set systemp   = 35
set jyperk    = 8    ; # antdiam=25,0.7
set bandwidth = 0.07 ; # MHz = 14 km/s at 1.42 GHz
set baseunit  = -3.33564
set baseunit  = 1    ; # equatorial coordinates in nanosecs.

# echo "   ---  VLA Single Field Multichannel Imaging    ---   " > timing
echo "   ---  VLA Single Field MFS Imaging    ---   " > timing
echo " config    =  $config"            >> timing
echo " dec       =  $dec"               >> timing
echo " harange   =  $harange  hours"    >> timing
echo " select    =  $select"            >> timing
echo " nchan     =  $nchan"             >> timing
echo " weighting =  $weighting"         >> timing
echo " freq      =  $freq"              >> timing
echo " imsize    =  $imsize"            >> timing
echo " systemp   =  $systemp "          >> timing
echo " jyperk    =  $jyperk "           >> timing
echo " bandwidth =  $bandwidth "        >> timing
echo " "                                >> timing
echo "   ---  TIMING   ---   "          >> timing
echo START: `date` >> timing

goto continue
continue:

echo generate uv-data
rm -r $config.$dec.uv
uvgen ant=$config.ant baseunit=$baseunit radec=23:23:25.803,$dec lat=34 harange=$harange source=$MIRCAT/point.source telescop=alma systemp=$systemp jyperk=$jyperk freq=$freq corr=$nchan,1,1,$bandwidth out=$config.$dec.uv
# pnoise=30
echo UVGEN: `date` >> timing

#echo selfcal
#selfcal vis=$config.$dec.uv interval=1
#echo SELFCAL: `date` >> timing

# plot uv coverage
uvplt vis=$config.$dec.uv device=/xs axis=uc,vc options=nobase,equal

echo image
rm -r $config.$dec.bm $config.$dec.mp
set nvis = `invert options=mfs vis=$config.$dec.uv map=$config.$dec.mp beam=$config.$dec.bm imsize=$imsize $weighting select=$select | grep Visibilities | awk '{print $3}'`
# capture nvis from standard output stream. 
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
histo in=residual
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
#set Nvis = `calc "100*$nvis/$records" | awk '{printf("%.0f\n",$1)}'`
# line above for multichannel images. For mfs imaging we need to divide by nchan
set Nvis = `calc "100*$nvis/$records/$nchan" | awk '{printf("%.0f\n",$1)}'`
set uvrange = `uvcheck vis="$config.$dec.uv" | awk '{if(NR==6)print 0.3*$6, 0.3*$7}'`
# Nyquist sample time = 12 x 3600 s x (dish_diam/2)/(pi*baseline)
set baseline = `echo $uvrange | awk '{print $2}'`
set Nyquist = `calc "12*3600*($antdiam/2)/(pi*$baseline)" | awk '{printf("%.1f\n",$1)}'`
echo " " >> timing
echo "Config  DEC    HA  Nchan   Rms     Beam       Tb_rms     Sidelobe[%]    Nvis   uvrange  weighting"  >> timing
echo "        deg.   hrs.      [\muJy]    [arcsec]   [\muK]     Rms,Max,Min   %     #    [m]" >> timing
echo  "$config  $dec  $harange  $nchan    $RMS    $BMAJ  $BMIN   $TBRMS  $SRMS  $SMAX  $SMIN  $Nvis  $nvis  $uvrange"  $weighting >> timing
echo " "
echo  "$config  $dec  $harange  $nchan    $RMS    $BMAJ x $BMIN  $TBRMS    $SRMS  $SMAX  $SMIN  $Nvis  $nvis  $uvrange"  $weighting >> vla_beams.results
mv timing $config.$dec.$harange.$nchan.$imsize.$nvis
cat $config.$dec.$harange.$nchan.$imsize.$nvis

