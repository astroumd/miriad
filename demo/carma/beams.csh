#!/bin/csh -f

# mchw 12jun02 - Single Field Imaging
# mchw 09aug02 - version for CARMA
# mchw 14aug02 - reduce size of region in imfit which was including sidelobes in relpix +/- 30
# mchw 26sep02 - decrease Nyquist sample interval for 2 km configuration.
# mchw 17dec02 - print uvrange in results summary.
# mchw 29jun04 - change jyperk to 73 for CARMA-15 with aperture efficiency 75%.
# mchw 30sep04 - N==7 in uvrange for /linux-apps4
# mchw 18nov04 - N==6 in uvrange for /linux-apps4

# Nyquist sample time = 12 x (dish_diam/2)/(pi*baseline)
# calc '12*(10.4/2)/(pi*2000)' = 0.01 hours = 36 sec.
# calc '12*(6.1/2)/(pi*1150)'  = 0.01 hours = 36 sec.


goto start
start:

# check inputs
  if($#argv<2) then
    echo " Usage:  $0 array declination "
    echo "   e.g.  $0 config1 30"
    echo " Inputs :"
    echo "   array"
    echo "          Antenna array used by uvgen task."
    echo "            e.g. config1 . No default."
    echo "   declination"
    echo "          Source declination in degrees. No default."
    echo " "
    exit 1
  endif

# set parameters
set config  = $1
set dec     = $2
set harange = -2,2,.01
set ellim   = 10
set select = '-shadow(6.1)'
set freq    = 230
set nchan   = 1
set imsize  = 256
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
echo " " >> timing
echo "   ---  TIMING   ---   "        >> timing
echo START: `date` >> timing


echo generate uv-data
rm -r $config.$dec.uv
uvgen ant=$config.ant baseunit=-3.33564 radec=23:23:25.803,$dec lat=37.233 harange=$harange source=$MIRCAT/point.source systemp=80,290,0.26 jyperk=73 freq=$freq corr=$nchan,1,0,4000 out=$config.$dec.uv pnoise=30 ellim=$ellim time=80JAN01.0
echo UVGEN: `date` >> timing

uvplt vis=$config.$dec.uv axis=uc,vc options=nobase,equal select=$select device=/xs

echo selfcal
selfcal vis=$config.$dec.uv interval=1 select=$select
echo SELFCAL: `date` >> timing

echo image
rm -r $config.$dec.bm $config.$dec.mp
set nvis = `invert options=systemp vis=$config.$dec.uv map=$config.$dec.mp beam=$config.$dec.bm imsize=$imsize sup=0 select=$select  | grep Visibilities | awk '{print $3}'`
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

continue:

echo print out results - summarize rms and beam sidelobe levels
echo "   ---  RESULTS   ---   " >> timing
set RMS = `itemize in=$config.$dec.mp   | grep rms       | awk '{printf("%.2f   ", 1e3*$3)}'`
set BMAJ=`prthd in=$config.$dec.cm      | egrep Beam     | awk '{printf("%.2f   ", $3)}'`
set BMIN=`prthd in=$config.$dec.cm      | egrep Beam     | awk '{printf("%.2f   ", $5)}'`
set TBRMS = `calc "$RMS*.3/$freq*.3/$freq/2/1.38e3/(pi/(4*log(2))*$BMAJ*$BMIN/4.25e10)" | awk '{printf("%.2f ", $1)}'`
set SRMS = `histo in=residual | grep Rms       | awk '{printf("%.1f  ", 100*$4)}'`
set SMAX = `histo in=residual | grep Maximum   | awk '{printf("%.1f  ", 100*$3)}'`
set SMIN = `histo in=residual | grep Minimum   | awk '{printf("%.1f  ", 100*$3)}'`
grep records $config.$dec.uv/history >> timing
grep phases $config.$dec.uv/history >> timing
# get number of visibilities written and number unshadowed
set records = `grep records $config.$dec.uv/history | awk '{print $2}'`
set Nvis = `calc "100*$nvis/$records" | awk '{printf("%.0f\n",$1)}'`
set uvrange = `uvcheck vis="$config.$dec.uv" | awk '{if(NR==6)print 0.3*$6, 0.3*$7}'`
echo " " >> timing
echo "Config  DEC  HA[hrs]  Rms[mJy]  Beam[arcsec]  Tb_rms[mK]  Sidelobe[%]: Rms Max Min  Nvis[%]  uvrange[m]" >> timing
echo "$config  $dec  $harange  $RMS   $BMAJ x $BMIN    $TBRMS   $SRMS  $SMAX  $SMIN  $nvis  $uvrange" >> timing

echo " "
echo  "$config   $dec   $harange   $RMS  $BMAJ x $BMIN   $TBRMS        $SRMS   $SMAX   $SMIN   $Nvis  $uvrange" >> beams.results
mv timing $config.$dec.$harange.$nchan.$imsize.$nvis
cat $config.$dec.$harange.$nchan.$imsize.$nvis
