#!/bin/csh -f

# $Date$ $Author$
# mchw 12jun02 - Single Field Imaging
# mchw 09aug02 - version for CARMA
# mchw 14aug02 - reduce size of region in imfit which was including sidelobes in relpix +/- 10
# mchw 20aug02 - hetero.csh This script assumes that the first 6 antennas are OVRO and the next 9 are hatcreek
# mchw 26sep02 - decrease Nyquist sample interval for 2 km configuration.
# mchw 17dec02 - print uvrange in results summary.
# mchw 21mar03 - clean up.
# mchw 02mar05 - Modified hetero.csh to also evaluate subarrays
# mchw 17jul07 - added harange.
# mwp  04jan08 - added systemp,  ellim, freq inputs (defaults as previous version)
# mwp  08jan08 - Added outputs: SNR relative to maxHARange track, Tsys (zenith), Elev minimum.
#                Fixed uvrange calculation (output of uvcheck changed).   Allowed device to vary. 
# mwp  07feb08 - added airmass output.

# Nyquist sample time = 12 x (dish_diam/2)/(pi*baseline)
# calc '12*(10.4/2)/(pi*2000)' = 0.01 hours = 36 sec.
# calc '12*(6.1/2)/(pi*1150)'  = 0.01 hours = 36 sec.

echo "   ---  CARMA Heterogenous Array Beams  ---   "
echo "   $0 This script assumes that the first 6 antennas are OVRO and the next 9 are hatcreek"
echo "   mchw. 20aug2002"

goto start
start:

# check inputs
  if($#argv<3) then
    echo " Usage: $0  config  declination  harange  nchan"
    echo "   config"
    echo "          Antenna configuration. "
    echo "            e.g. config1.ant. Omit the .ant. No default."
    echo "   declination"
    echo "          Source declination in degrees. No default."
    echo "   harange"
    echo "          HA range: start,stop,interval in hours. No default."
    echo "   ellim "
    echo "          Elevation limit in degrees.  Default = 10.  Hour angles below the limit are not 'observed.'"
    echo "   systemp "
    echo "          System temperature parameters as in uvgen: Trx(DSB),Tsky,tau.  Default is 80,290,0.26"
    echo " "
    echo "   freq "
    echo "          Observing frequency, GHz.  Default = 230 "
    echo " "
    echo "   device "
    echo "          Plot device.  Default = /xs "
    echo " "
    exit 1
  endif

# set parameters
set config  = $1
set dec     = $2
set harange = $3
if ( $#argv >= 4 ) then
    set ellim   = $4
else 
    set ellim   = 10
endif
if ( $#argv >= 5 ) then
    set systemp = $5
else 
    set systemp = 80,290,0.26
endif 
if ( $#argv >= 6 ) then
    set freq = $6
else 
    set freq = 230
endif 
if ( $#argv == 7 ) then
    set device = $7
else 
    set device = /xs
endif 
set select = '-shadow(10.4)'
set select = '-shadow(6.1)'
set freq    = $freq
set nchan   = 1
set imsize  = 256
set region  =  'relpix,box(-10,-10,10,10)'
# 'relpix,box(-30,-30,30,30)'
set ha = `echo $harange|tr , " "|awk '{print $1","$2}'`
echo $ha
set maxHaRange="-10,10"

set seen = 0

echo "   ---  CARMA Single Field Imaging    ---   " > timing
echo " config           = $config"             >> timing
echo " declination      = $dec"                >> timing
echo " Hour Angle range = $harange  hours"     >> timing
echo " Elevation limit  = $ellim  degrees. "   >> timing
echo " Systemp          = $systemp  "          >> timing
echo " select           = $select"             >> timing
echo " frequency        = $freq"               >> timing
echo " nchan            = $nchan"              >> timing
echo " imsize           = $imsize"             >> timing
echo " " >> timing
echo "   ---  TIMING   ---   "        >> timing
echo START: `date` >> timing

goto continue
continue:

if ( ! -e beams.results ) then 
    echo "# Config  DEC  HA[hrs]  ObsTime[hrs] Rms[mJy]  Rel.SNR Beam[arcsec]  Tb_rms[mK]  Sidelobe[%]: Rms Max Min  Nvis[%]  uvrange[m]  Freq[GHz]  Elev.Cutoff[deg]  Avg.Airmass" > beams.results
endif

echo generate uv-data
# assume aperture efficiency 75% to get jyperk
echo "Generate uv-data. Tsys=40K, bandwidth=4 GHz " >> timing
rm -r carma.uv ovro.uv hatcreek.uv
uvgen ant=$config.ant baseunit=-3.33564 radec=23:23:25.803,$dec lat=37.02 harange=$harange source=$MIRCAT/no.source systemp=$systemp jyperk=73 freq=$freq corr=$nchan,1,0,4000 out=carma.uv telescop=carma ellim=$ellim 
uvgen ant=$config.ant baseunit=-3.33564 radec=23:23:25.803,$dec lat=37.02 harange=$harange source=$MIRCAT/no.source systemp=$systemp jyperk=43  freq=$freq corr=$nchan,1,0,4000 out=ovro.uv telescop=ovro ellim=$ellim 
uvgen ant=$config.ant baseunit=-3.33564 radec=23:23:25.803,$dec lat=37.02 harange=$harange source=$MIRCAT/no.source systemp=$systemp jyperk=126 freq=$freq corr=$nchan,1,0,4000 out=hatcreek.uv telescop=hatcreek ellim=$ellim 
echo UVGEN: `date` >> timing

# select data for heterogenous array
  rm -r carma.$dec.uv
  rm -r ovro.$dec.uv
  rm -r hatcreek.$dec.uv
uvcat vis=carma.uv    out=carma.$dec.uv    'select=ant(1,2,3,4,5,6)(7,8,9,10,11,12,13,14,15)' 
uvcat vis=ovro.uv     out=ovro.$dec.uv     'select=ant(1,2,3,4,5,6)(1,2,3,4,5,6)'
uvcat vis=hatcreek.uv out=hatcreek.$dec.uv 'select=-ant(1,2,3,4,5,6)'

#uvplt vis=carma.$dec.uv,ovro.$dec.uv,hatcreek.$dec.uv axis=uc,vc options=nobase,equal select=$select device=$device 
#uvplt vis=carma.$dec.uv,ovro.$dec.uv,hatcreek.$dec.uv axis=uc,vc options=nobase,equal select=$select device=$config.$dec.$select.cps/cps

/bin/rm -rf all.$dec.uv
uvcat vis=carma.$dec.uv,ovro.$dec.uv,hatcreek.$dec.uv  out=all.$dec.uv

foreach VIS ( all.$dec.uv  )
#foreach VIS ( all.$dec.uv  ovro.$dec.uv  hatcreek.$dec.uv )

   /bin/rm -rf junk
   smauvplt axis=time,el vis=$VIS log=junk device=/null select='ant(1)(2)' options=log
   set minElevation = `head -9 junk|tail -1 | awk '{ printf("%.2f",$2) }'`
   /bin/rm -rf junk
   smauvplt axis=time,airmass vis=$VIS log=junk device=/null select='ant(1)(2)' options=log average=100000
   set avgAirMass = `tail -1 junk | awk '{ printf("%.2f", $2) }'`
  
  echo image
  # natural weight
  rm -r $config.$dec.mp $config.$dec.bm
  set nvis = `invert options=systemp vis=$VIS map=$config.$dec.mp beam=$config.$dec.bm imsize=$imsize sup=0 select=$select | grep Visibilities | awk '{print $3}'`
  #set nvis = `invert options=systemp vis=carma.$dec.uv,ovro.$dec.uv,hatcreek.$dec.uv map=$config.$dec.mp beam=$config.$dec.bm imsize=$imsize sup=0 select=$select | grep Visibilities | awk '{print $3}'`

  echo INVERT: `date` >> timing
  
#  echo plotting
#  implot in=$config.$dec.bm device=$device units=s conflag=an conargs=0.05
#  implot in=$config.$dec.bm device=$device units=s conflag=an conargs=0.05 region=$region
#  echo IMPLOT: `date` >> timing
  
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
  
  echo print out results - summarize rms and beam sidelobe levels
  echo "   ---  RESULTS   ---   " >> timing
  set RMS = `itemize in=$config.$dec.mp   | grep rms       | awk '{printf("%.4f   ", 1e3*$3)}'`
  set BMAJ=`prthd in=$config.$dec.cm      | egrep Beam     | awk '{printf("%.2f   ", $3)}'`
  set BMIN=`prthd in=$config.$dec.cm      | egrep Beam     | awk '{printf("%.2f   ", $5)}'`
  set TBRMS = `calc "$RMS*.3/$freq*.3/$freq/2/1.38e3/(pi/(4*log(2))*$BMAJ*$BMIN/4.25e10)" | awk '{printf("%.1f ", $1)}'`
  set SRMS = `histo in=residual | grep Rms       | awk '{printf("%.1f  ", 100*$4)}'`
  set SMAX = `histo in=residual | grep Maximum   | awk '{printf("%.1f  ", 100*$3)}'`
  set SMIN = `histo in=residual | grep Minimum   | awk '{printf("%.1f  ", 100*$3)}'`
  # get number of visibilities written and number unshadowed
  set ncarma = `uvindex vis=carma.$dec.uv | grep "records of polarization I" | awk '{printf("%.0f\n",$3)}'`
  set novro  = `uvindex vis=ovro.$dec.uv | grep "records of polarization I" | awk '{printf("%.0f\n",$3)}'`
  set nhatcreek = `uvindex vis=hatcreek.$dec.uv | grep "records of polarization I" | awk '{printf("%.0f\n",$3)}'`
  set records = `calc $ncarma+$novro+$nhatcreek`
  set Nvis = `calc "100*$nvis/$records" | awk '{printf("%.0f\n",$1)}'`
  set uvrange = `uvcheck vis="$VIS" | grep uvrange | awk '{print 0.3*$6, 0.3*$7}'`
  set isAll = `echo $VIS |grep -c all`
  if ( $isAll == 1 ) then 
      set ObsTime = `uvindex vis="$VIS" | grep 'Total observing time'|awk '{print $5/3.0}'`
  else 
      set ObsTime = `uvindex vis="$VIS" | grep 'Total observing time'|awk '{print $5}'`
  endif
  if ( $ha == $maxHaRange && $isAll == 1 ) then
	  set minRMS = $RMS
	  echo $minRMS > minRMS.$dec
  else 
      if ( ! -e minRMS.$dec ) then 
          echo "#### ERROR: no minRMS file for dec $dec"
          exit 1
      endif
      set minRMS = `cat minRMS.$dec`
  endif
  echo " " >> timing
  echo "Config  DEC  HA[hrs]  ObsTime[hrs] Rms[mJy]  Rel.SNR  Beam[arcsec]  Tb_rms[mK]  Sidelobe[%]: Rms Max Min  Nvis[%]  uvrange[m]" >> timing
  set relSNR = `calc -f f8.4 $minRMS/$RMS`
  echo "$config  $dec  $harange  $ObsTime $RMS  $relSNR  $BMAJ x $BMIN    $TBRMS   $SRMS  $SMAX  $SMIN  $nvis  $uvrange" >> timing
  
  echo " "
  echo  "$config.$VIS   $dec   $harange $ObsTime  $RMS  $relSNR   $BMAJ x $BMIN   $TBRMS        $SRMS   $SMAX   $SMIN   $Nvis  $uvrange  $freq $minElevation $avgAirmass" >> beams.results
  mv timing $config.$dec.$harange.$nchan.$imsize.$nvis
  #cat $config.$dec.$harange.$nchan.$imsize.$nvis
  tail beams.results
  echo " ========================================================================================= "

#  echo "$config.$VIS  $dec  $harange $minElevation $avgAirMass" >> airmass.out
  goto Loop

  Loop:
end


