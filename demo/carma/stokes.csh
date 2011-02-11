#!/bin/csh -f

echo "Polarization tests for CARMA"

# mchw 15apr10
# 18apr03 added uvrange. 
# 22mar05 added harange. 
# 09may05 add more parameters to title.
# 20mar06 CARMA version.
# 27may09 added weighting options to input parameters.
# 27oct09 clean up doc.
# 15apr10 select on parameter line allows  uvdata selection.
# 03feb2011 stokes.csh -- polarization imaging.


# Nyquist sample time = 12 x 3600 s x (dish_diam/2)/(pi*baseline)
# calc '12*3600*3/(pi*700)' = 59s
# 1 min = 0.01666 hours is Nyquist sample interval at 700 m

goto start
start:

# check inputs
  if($#argv<8) then
    echo " Usage:  $0 config declination  harange nchan  weighting select  source leakage"
    echo " e.g:  mfs.csh carma_A  -30   0,.1,.1    1  sup=0  -auto point.source  0"
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
    echo "   source"
    echo "          see uvgen doc: flux,dra,ddec,bmaj,bmin,bpa,iflux,ipa,vflux"
    echo "          Total flux, position offset in arcsec, FWHM, PA, Ip% pol_PA, V"
    echo "   leakage"
    echo "          Polarization leakage errors, given as a percent. No default,".
    echo " "
    exit 1
  endif

set config     = $1
set dec        = $2
set harange    = $3
set nchan      = $4
set weighting  = $5
set select     = $6
set source     = $7
set leakage    = $8
set freq       = 230
set imsize     = 256 
set systemp    = 80,290,0.26 
set jyperk     = 73 
set bandwidth  = 8000
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
echo " source    =  $source "           >> timing
echo " leakage   =  $leakage"           >> timing
echo " " >> timing
echo "   ---  TIMING   ---   "          >> timing
echo START: `date` >> timing

goto continue
continue:

echo generate uv-data
rm -r $config.$dec.uv
uvgen ant=$config.ant baseunit=-3.33564 radec=23:23:25.803,$dec lat=37.233 harange=$harange source=$source systemp=$systemp jyperk=$jyperk freq=$freq corr=$nchan,1,1,$bandwidth out=$config.$dec.uv ellim=10 stokes=rr,rl,ll,lr leakage=$leakage
# pnoise=30
echo UVGEN: `date` >> timing

uvplt vis=$config.$dec.uv device=/xs axis=uc,vc options=nobase,equal

echo image
rm -r $config.$dec.bm $config.$dec.mp*
set nvis = `invert options=mfs stokes=I,Q,U,V vis=$config.$dec.uv map=$config.$dec.mpI,$config.$dec.mpQ,$config.$dec.mpU,$config.$dec.mpV beam=$config.$dec.bm imsize=$imsize $weighting select=$select | grep Visibilities | awk '{print $3}'`
echo INVERT: `date` >> timing

echo plotting
implot in=$config.$dec.bm device=/xs units=s conflag=l conargs=1.4
implot in=$config.$dec.bm device=/xs units=s conflag=an conargs=0.05 region=$region
echo IMPLOT: `date` >> timing

echo deconvolve
rm -r $config.$dec.cl? $config.$dec.cm?
clean map=$config.$dec.mpI beam=$config.$dec.bm out=$config.$dec.clI
echo CLEAN: `date` >> timing
restor map=$config.$dec.mpI beam=$config.$dec.bm out=$config.$dec.cmI model=$config.$dec.clI
echo IMFIT: `date` >> timing

echo fit beam and get residual sidelobe levels
rm -r residual
imfit in=$config.$dec.bm object=gauss 'region=relpix,box(-10,-10,10,10)' out=residual options=residual
histo in=residual
echo FINISH: `date` >> timing
echo " " >> timing


echo print out results - summarize rms and beam sidelobe levels. RMS and TBRMS in mJy and mK
echo "   ---  RESULTS   ---   " >> timing
set RMS = `itemize in=$config.$dec.mpI   | grep rms       | awk '{printf("%.2f   ", 1e3*$3)}'`
set BMAJ=`prthd in=$config.$dec.cmI      | egrep Beam     | awk '{printf("%.2f   ", $3)}'`
set BMIN=`prthd in=$config.$dec.cmI      | egrep Beam     | awk '{printf("%.2f   ", $5)}'`
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
echo "Config  DEC    HA  Nchan   Rms     Beam       Tb_rms     Sidelobe[%]    Nvis   uvrange  weighting"  >> timing
echo "        deg.   hrs.       [mJy]    [arcsec]     [mK]     Rms,Max,Min   %     #    [m]" >> timing
echo  "$config  $dec  $harange  $nchan    $RMS    $BMAJ  $BMIN   $TBRMS  $SRMS  $SMAX  $SMIN  $Nvis  $nvis  $uvrange"  $weighting >> timing
echo " "
echo  "$config  $dec  $harange  $nchan    $RMS    $BMAJ x $BMIN  $TBRMS    $SRMS  $SMAX  $SMIN  $Nvis  $nvis  $uvrange"  $weighting >> beams.results
mv timing $config.$dec.$harange.$nchan.$imsize.$nvis
cat $config.$dec.$harange.$nchan.$imsize.$nvis

echo polarization calibration
gpcal vis=$config.$dec.uv options=circular,qusolve,noxy flux=1

echo  uvflux without polcal
uvflux vis=$config.$dec.uv options=nocal,nopol
uvflux vis=$config.$dec.uv stokes=i,q,u,v options=nocal,nopol

echo  uvflux with polcal
uvflux vis=$config.$dec.uv
uvflux vis=$config.$dec.uv stokes=i,q,u,v

echo  plot real,imag with and without polcal
uvplt device=1/xs vis=$config.$dec.uv options=equal,nobase,nocal,nopol axis=real,imag stokes=i,q,u,v
uvplt device=2/xs vis=$config.$dec.uv options=equal,nobase axis=real,imag stokes=i,q,u,v

echo  default xyphase=0. default refant=3. xyphase is put into y-gain-phase
gpcal vis=$config.$dec.uv options=circular,qusolve,noxy flux=1 xyphase=0,0,5
fitgains vis=$config.$dec.uv

echo  fitting xyphase copies refant xyphase to all antennas since uvdata has zero xyphase
gpcal vis=$config.$dec.uv options=circular,qusolve flux=1 xyphase=0,0,5
fitgains vis=$config.$dec.uv

