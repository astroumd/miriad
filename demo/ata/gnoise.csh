#!/bin/csh -f

echo "Synthesized beam forward gain and sidelobes levels as a function of gain and phase noise"

# mchw 27jun02

# Nyquist sample time = 12 x 3600 s x (dish_diam/2)/(pi*baseline)
# calc '12*3600*3/(pi*700)' = 59s
# 1 min = 0.01666 hours is Nyquist sample interval at 700 m

goto start
start:

# check inputs
  if($#argv<3) then
    echo " Usage: multichannel.csh   config   declination" 
    echo "   config"
    echo "          Antenna configuration. "
    echo "            e.g. config1.ant. Omit the .ant. No default."
    echo "   gnoise"
    echo "          Gain noise [%] . No default."
    echo "   pnoise"                                                                 
    echo "          Phase noise RMS [degrees]. No default."
    echo " "
    exit 1
  endif

set config  = $1
set gnoise  = $2
set pnoise  = $3
set nchan   = 1
set dec     = 30
set harange = 0.,0.016,0.016
set select = '-shadow(6.1)'
set freq    = 1.42
set imsize  = 0


echo "   ---  ATA Single Field Multichannel Imaging    ---   " > timing
echo "Synthesized beam forward gain and sidelobes levels as a function of gain and phase noise" >> timing
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
continue:

echo generate uv-data
rm -r $config.$dec.uv
uvgen ant=$config.ant baseunit=-3.33564 radec=23:23:25.803,$dec harange=$harange source=$MIRCAT/point.source telescop=hatcreek systemp=40 jyperk=150 freq=$freq corr=$nchan,1,1,100 out=$config.$dec.uv pnoise=$pnoise gnoise=$gnoise
echo UVGEN: `date` >> timing

#echo selfcal
#selfcal vis=$config.$dec.uv interval=1
#echo SELFCAL: `date` >> timing


echo image
rm -r $config.$dec.bm $config.$dec.mp
#set nvis = `invert options=mfs vis=$config.$dec.uv map=$config.$dec.mp beam=$config.$dec.bm imsize=$imsize sup=0 select=$select | grep Visibilities | awk '{print $3}'`
set nvis = `invert vis=$config.$dec.uv map=$config.$dec.mp beam=$config.$dec.bm imsize=$imsize sup=0 select=$select | grep Visibilities | awk '{print $3}'`
echo INVERT: `date` >> timing

echo plotting
implot in=$config.$dec.bm device=/xs units=s conflag=l conargs=1.6 region=quarter
implot in=$config.$dec.bm device=/xs units=s conflag=l conargs=1.6 'region=relpix,box(-25,-25,25,25)'
echo IMPLOT: `date` >> timing

echo deconvolve
rm -r $config.$dec.cl $config.$dec.cm
clean map=$config.$dec.mp beam=$config.$dec.bm out=$config.$dec.cl
echo CLEAN: `date` >> timing
restor map=$config.$dec.mp beam=$config.$dec.bm out=$config.$dec.cm model=$config.$dec.cl
echo IMFIT: `date` >> timing

echo fit map and get residual sidelobe levels
rm -r residual
imfit in=$config.$dec.mp object=gauss 'region=relpix,box(-25,-25,25,25)' out=residual options=residual
histo in=residual
echo FINISH: `date` >> timing
echo " " >> timing


echo print out results - summarize rms and beam sidelobe levels. RMS and TBRMS in mJy and mK
echo "   ---  RESULTS   ---   " >> timing
set RMS = `itemize in=$config.$dec.mp   | grep rms       | awk '{printf("%.2f   ", 1e3*$3)}'`
set BMAJ=`prthd in=$config.$dec.cm      | egrep Beam     | awk '{printf("%.2f   ", $3)}'`
set BMIN=`prthd in=$config.$dec.cm      | egrep Beam     | awk '{printf("%.2f   ", $5)}'`
set TBRMS = `calc "$RMS*.3/$freq*.3/$freq/2/1.38e3/(pi/(4*log(2))*$BMAJ*$BMIN/4.25e10)" | awk '{printf("%.0f ", $1)}'`
set PEAK = `histo in=$config.$dec.mp | grep Maximum   | awk '{printf("%.3f  ", $3)}'`
set SRMS = `histo in=residual | grep Rms       | awk '{printf("%.2f  ", 100*$4)}'`
set SMAX = `histo in=residual | grep Maximum   | awk '{printf("%.2f  ", 100*$3)}'`
set SMIN = `histo in=residual | grep Minimum   | awk '{printf("%.2f  ", 100*$3)}'`
grep records $config.$dec.uv/history >> timing
grep phases $config.$dec.uv/history >> timing
# get number of visibilities written and number unshadowed
set records = `grep records $config.$dec.uv/history | awk '{print $2}'`
# set nvis = `uvcheck vis=$config.$dec.uv select=$select | grep records | awk '{printf("%.0f\n",$4)}'`
calc "$nvis/$records"
set Nvis = `calc "100*$nvis/$records/$nchan" | awk '{printf("%.0f\n",$1)}'`
echo " " >> timing
echo "Synthesized beam forward gain and sidelobes levels as a function of gain and phase noise" >> timing
echo "Config DEC Gain Phase HA[hrs]  Rms[mJy]  Beam[arcsec] Tb_rms[mK]  Peak  Sidelobe[%]:Rms,Max,Min Nvis[%]" >> timing
echo  "$config $dec $gnoise $pnoise  $harange  $RMS   $BMAJ $BMIN  $TBRMS  $PEAK  $SRMS  $SMAX  $SMIN  $nvis" >> timing
echo " "
echo  "$config $dec $gnoise $pnoise $harange   $RMS   $BMAJ x $BMIN  $TBRMS  $PEAK  $SRMS  $SMAX  $SMIN  $Nvis" >> gnoise.results
mv timing $config.$dec.$harange.$nchan.$imsize.$nvis
cat $config.$dec.$harange.$nchan.$imsize.$nvis
cat gnoise.results
