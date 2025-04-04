#!/bin/csh -f

echo "   ---  Mosaicing with ATA  $0  ---   "

# History:
#  15aug02 mchw. edited from ALMA script.
#  23aug02 mchw. calculate region from source size.
#  02jul04 mchw. Version for CARMA-23
#  08jul04 mchw. Parameterize source model image, model_flux, and region
#  09may05 mchw. Parameterized version of original hex7.csh.
#  26may05 mchw. Added harange to input parameters.
#  31may05 mchw. Parameterize sd_ant, sd_flux, sd_diam, sd_rms.


# Nyquist sample time = 12 x (dish_diam/2)/(pi*baseline)/Npointings
# calc '12*(10.4/2)/(pi*2000)' = 0.01 hours = 36 sec/Npointings
# calc '12*(6.1/2)/(pi*1150)'  = 0.01 hours = 36 sec/Npointings
# Nyquist sample rate for each pointing. Using max baseline 250m.
# calc '12*(10.4/2)/(pi*250)' = 0.08 hours or 0.01 hours for 7 pointings.


goto start
start:

# check inputs
  if($#argv<6) then
    echo " Usage:  $0 array declination cell sd_ant sd_rms "
    echo "   e.g.  $0 config1   30       16 hatcreek 0.01"
    echo " Inputs :"
    echo "   array"
    echo "          Antenna array used by uvgen task."
    echo "            e.g. config1 . No default."
    echo "   declination"
    echo "          Source declination in degrees. No default."
    echo "   harange"
    echo "          HA range: start,stop,interval in hours. No default."
    echo "   cell"
    echo "          scale size. No default."
    echo "   sd_ant"
    echo "          single dish antenna. e.g. hatcreek ovro alma. No default."
    echo "   sd_rms"
    echo "          single dish RMS noise as fraction of total flux. e.g. 0.01 No default."
    echo " "
    exit 1
  endif

# Cas A model, casc.vla, pixel=0.4", Cas A is about 320" diameter; image size 1024 == 409.6"
# scale model size. eg. cell=0.1 arcsec -> 80" diameter 

# Saturn model, sat1mm.modj2, pixel=0.1", Saturn's rings are ~ 50" diameter; imsize=603 == 60"

set config  = $1
set dec     = $2
set harange = $3
set cell    = $4
set sd_ant  = $5
set sd_rmsp = $6
set model   = sat1mm.modj2
set model   = casc.vla
set ellim   = 10
set select = '-shadow(6.1)'
set freq    = 1.42
set nchan   = 1
set imsize  = 257
set region  = 'arcsec,box(25,-25,-25,25)'
if($model == casc.vla)then
  set region = `calc "$cell*500" | awk '{printf("arcsec,box(%.2f,-%.2f,-%.2f,%.2f)",$1,$1,$1,$1)}'`
endif
if($model == sat1mm.modj2)then
  set region = `calc "$cell*250" | awk '{printf("arcsec,box(%.2f,-%.2f,-%.2f,%.2f)",$1,$1,$1,$1)}'`
endif

# get total flux in model and set single dish rms noise level.
set sd_flux = `histo in=$model | grep Flux | awk '{printf("%.3f   ", $6)}'`
set sd_rms   = `calc "$sd_flux*$sd_rmsp"`
set sd_diam = `telepar telescop=$sd_ant | grep "Antenna diameter" | awk '{print $3}'`

echo "   ---  Mosaicing with ATA  -  $0 model=$model,  `date`   " > timing
echo " model   = $model"             >> timing
echo " config  = $config"            >> timing
echo " dec     = $dec"               >> timing
echo " scale   = $cell"              >> timing
echo " harange = $harange  hours"    >> timing
echo " select  = $select"            >> timing
echo " freq    = $freq"              >> timing
echo " nchan   = $nchan"             >> timing
echo " imsize  = $imsize"            >> timing
echo " region  = $region"            >> timing
echo " sd_ant  = $sd_ant"            >> timing
echo " sd_diam = $sd_diam"           >> timing
echo " sd_rmsp = $sd_rmsp"           >> timing
echo " "                             >> timing
echo "   ---  TIMING   ---   "       >> timing
echo START: `date` >> timing

echo "  " >> $model.results
echo "   ---  Mosaicing with ATA  -  $0 model=$model,  `date`   " >> $model.results
echo " sd_ant  = $sd_ant"            >> $model.results
echo " sd_diam = $sd_diam"           >> $model.results
echo " sd_rmsp = $sd_rmsp"           >> $model.results

goto continue
continue:

echo "Generate mosaic grid for 6.1m (ATA) antennas"
#  lambda/2*antdiam (arcsec)
hex rings=2 cell=3600 | awk '{printf("%.2f,%.2f\n", $1,$2)}' > hex7
echo "Using hex7 mosaic with 3600'' spacing" >>  $model.results

echo "Generate uv-data. Tsys=40K, Jy/K=150,  bandwidth=100 MHz " >> timing
rm -r $config.uv
set tsys=0
uvgen ant=$config.ant baseunit=-3.33564 radec=23:23:25.803,$dec harange=$harange \
source=$MIRCAT/no.source systemp=$tsys jyperk=150 freq=$freq corr=$nchan,1,0,100   \
out=$config.uv telescop=hatcreek center=@hex7
echo UVGEN: `date` >> timing
uvindex vis=$config.uv

goto end

echo "Scale model size. from pixel 0.4 to $cell arcsec" >> timing
# with 0.4 arcsec pixel size Cas A is about 320 arcsec diameter; image size 1024 == 409.6 arcsec
# scale model size. eg. 10x Cas A ~ 50 arcmin and image size is 68 arcmin
# Primary beamwidth 2.5 degrees.  Closest antenna spacing 10.8 m = 1.1 degrees at 1.42 GHz
rm -r single.$dec.$model.$cell
cp -r $model single.$dec.$model.$cell
puthd in=single.$dec.$model.$cell/crval2 value=$dec,dms
puthd in=single.$dec.$model.$cell/crval3 value=$freq
puthd in=single.$dec.$model.$cell/cdelt1 value=-$cell,arcsec
puthd in=single.$dec.$model.$cell/cdelt2 value=$cell,arcsec

echo "Make model images for each pointing center" >> timing
rm -r $config.$model.$cell.demos*
rm -r sza*.$model.$cell.demos*
demos map=single.$dec.$model.$cell vis=$config.uv out=$config.$model.$cell.demos

echo "Make model uv-data using model image" >> timing
  rm -r $config.$dec.$model.$cell.uv*
  foreach i ( 1 2 3 4 5 6 7 )
    cgdisp device=/xs labtyp=arcsec range=0,0,lin,8 in=$config.$model.$cell.demos$i
    uvmodel vis=$config.uv model=$config.$model.$cell.demos$i options=add,selradec out=$config.$dec.$model.$cell.uv$i
  end
echo UVMODEL: `date` add the model to the noisy sampled uv-data >> timing

rm -r $config.$dec.$model.$cell.mp $config.$dec.$model.$cell.bm
invert vis="$config.$dec.$model.$cell.uv*" map=$config.$dec.$model.$cell.mp beam=$config.$dec.$model.$cell.bm imsize=$imsize sup=0 options=mosaic,double select=$select
echo INVERT: `date` >> timing
implot in=$config.$dec.$model.$cell.mp device=/xs units=s region=$region
imlist in=$config.$dec.$model.$cell.mp options=mosaic

#  					------------------------

single:
echo "Make single dish image and beam using telecop=$sd_ant"  `date` >> timing
echo "Make single dish image and beam using telecop=$sd_ant"  `date` >> $model.results
set sd_fwhm = `pbplot telescop=$sd_ant freq=$freq | grep FWHM | awk '{print 60*$3}'`
echo "Single dish FWHM = $sd_fwhm arcsec at $freq GHz" >> timing
echo "Single dish RMS noise = $sd_rms Jy, $sd_rmsp of peak for $model" >> timing
echo "Single dish RMS noise = $sd_rms Jy, $sd_rmsp of peak for $model" >> $model.results

rm -r single.$dec.$model.$cell.bigger
imframe in=single.$dec.$model.$cell frame=-1024,1024,-1024,1024 out=single.$dec.$model.$cell.bigger
rm -r single.$dec.$model.$cell.bigger.map
convol map=single.$dec.$model.$cell.bigger fwhm=$sd_fwhm,$sd_fwhm out=single.$dec.$model.$cell.bigger.map
rm -r single.$dec.$model.$cell.map
regrid  in=single.$dec.$model.$cell.bigger.map tin=$config.$dec.$model.$cell.mp out=single.$dec.$model.$cell.map axes=1,2
rm -r single.$dec.$model.$cell.beam
imgen in=single.$dec.$model.$cell.map factor=0 object=gaussian spar=1,0,0,$sd_fwhm,$sd_fwhm,0 out=single.$dec.$model.$cell.beam
implot in=single.$dec.$model.$cell.map units=s device=/xs conflag=l conargs=2

puthd in=single.$dec.$model.$cell.map/rms value=$sd_rms

goto mosmem

joint:
echo "Joint deconvolution of interferometer and single dish data" >> timing
echo "Joint deconvolution of interferometer and single dish data ; niters=200 rmsfac=1,1" >> $model.results
rm -r $config.$dec.$model.$cell.mem $config.$dec.$model.$cell.cm
 mosmem  map=$config.$dec.$model.$cell.mp,single.$dec.$model.$cell.map beam=$config.$dec.$model.$cell.bm,single.$dec.$model.$cell.beam out=$config.$dec.$model.$cell.mem niters=200 region=$region rmsfac=1,1
goto restor

mosmem:
echo " MOSMEM Interferometer only" >> timing
echo " MOSMEM Interferometer only with niters=200 flux=$sd_flux rmsfac=1." >> $model.results 
rm -r $config.$dec.$model.$cell.mem $config.$dec.$model.$cell.cm
mosmem  map=$config.$dec.$model.$cell.mp beam=$config.$dec.$model.$cell.bm out=$config.$dec.$model.$cell.mem region=$region niters=200 flux=$sd_flux rmsfac=1
goto restor

default:
echo "MOSMEM with default single dish image"  >> timing
echo "MOSMEM with default single dish image; niters=200 rmsfac=1"  >> $model.results
rm -r $config.$dec.$model.$cell.mem $config.$dec.$model.$cell.cm
mosmem map=$config.$dec.$model.$cell.mp default=single.$dec.$model.$cell.map beam=$config.$dec.$model.$cell.bm out=$config.$dec.$model.$cell.mem region=$region niters=200 rmsfac=1.

restor:
restor map=$config.$dec.$model.$cell.mp beam=$config.$dec.$model.$cell.bm out=$config.$dec.$model.$cell.cm model=$config.$dec.$model.$cell.mem
echo MOSMEM: `date` >> timing 
implot device=/xs units=s in=$config.$dec.$model.$cell.cm region=$region
goto convolve

rm -r $config.$dec.$model.$cell.memrem
restor map=$config.$dec.$model.$cell.mp beam=$config.$dec.$model.$cell.bm out=$config.$dec.$model.$cell.memrem model=$config.$dec.$model.$cell.mem mode=residual
implot device=/xs units=s in=$config.$dec.$model.$cell.mem region=$region
mem_residual:
histo in=$config.$dec.$model.$cell.memrem region=$region | grep Rms
goto end

convolve:
echo "convolve the model by the beam and subtract from the deconvolved image" >> timing
  set b1=`prthd in=$config.$dec.$model.$cell.cm | egrep Beam     | awk '{print $3}'`
  set b2=`prthd in=$config.$dec.$model.$cell.cm | egrep Beam     | awk '{print $5}'`
  set b3=`prthd in=$config.$dec.$model.$cell.cm | egrep Position | awk '{print $3}'`
  rm -r $config.$dec.$model.$cell.conv
  convol map=single.$dec.$model.$cell fwhm=$b1,$b2 pa=$b3 out=$config.$dec.$model.$cell.conv
  implot in=$config.$dec.$model.$cell.conv device=/xs units=s region=$region
echo "regrid the convolved model to the deconvolved image template" >> timing
  rm -r $config.$dec.$model.$cell.regrid
  regrid in=$config.$dec.$model.$cell.conv out=$config.$dec.$model.$cell.regrid tin=$config.$dec.$model.$cell.cm axes=1,2
  implot in=$config.$dec.$model.$cell.regrid device=/xs units=s region=$region
#  cgdisp range=0,0,lin,8 in=$config.$dec.$model.$cell.conv device=$config.$dec.$model.$cell.conv.gif/gif labtyp=arcsec,arcsec options=beambl,wedge  region=$region
#  mv $config.$dec.$model.$cell.conv.gif ~/public_html

  rm -r $config.$dec.$model.$cell.resid
  imdiff in1=$config.$dec.$model.$cell.cm in2=$config.$dec.$model.$cell.regrid resid=$config.$dec.$model.$cell.resid options=nox,noy,noex
  implot device=/xs units=s in=$config.$dec.$model.$cell.resid region=$region
  histo in=$config.$dec.$model.$cell.resid region=$region
  cgdisp range=0,0,lin,8 in=$config.$dec.$model.$cell.cm device=/xs labtyp=arcsec,arcsec options=beambl,wedge region=$region
echo FINISH: `date` >> timing
echo " " >> timing

echo print out results - summarize rms and beam sidelobe levels
echo "   ---  RESULTS   ---   " >> timing
set RMS = `itemize in=$config.$dec.$model.$cell.mp   | grep rms       | awk '{printf("%.3f   ", 1000*$3)}'`
set SRMS = `histo in=$config.$dec.$model.$cell.resid region=$region | grep Rms | awk '{printf("%.3f   ", $4)}'`
set SMAX = `histo in=$config.$dec.$model.$cell.resid region=$region | grep Maximum | awk '{printf("%.3f   ", $3)}'`
set SMIN = `histo in=$config.$dec.$model.$cell.resid region=$region | grep Minimum | awk '{printf("%.3f   ", $3)}'`
set Model_Flux = `histo in=$config.$dec.$model.$cell.regrid region=$region | grep Flux | awk '{printf("%.3f   ", $6)}'`
set Model_Peak = `histo in=$config.$dec.$model.$cell.regrid region=$region | grep Maximum | awk '{printf("%.3f   ", $3)}'`
set Flux = `histo in=$config.$dec.$model.$cell.cm region=$region | grep Flux | awk '{printf("%.3f   ", $6)}'`
set Peak = `histo in=$config.$dec.$model.$cell.cm region=$region | grep Maximum | awk '{printf("%.3f   ", $3)}'`
set Fidelity = `calc $Peak/$SRMS | awk '{printf("%.0f", $1)}'`

echo   "Config  DEC  HA[hrs]  scale  RMS  Beam[arcsec]  Model_Flux,Peak  Image_Flux,Peak Residual:Rms,Max,Min[Jy] Fidelity" >> timing
echo "$config  $dec  $harange  $cell  $RMS  $b1 $b2  $Model_Flux  $Model_Peak  $Flux $Peak  $SRMS  $SMAX  $SMIN  $Fidelity" >> timing
echo  " "
echo "$config  $dec  $harange  $cell  $RMS  $b1 $b2  $Model_Flux  $Model_Peak  $Flux $Peak  $SRMS  $SMAX  $SMIN  $Fidelity" >> $model.results
mv timing $config.$dec.$harange.$nchan.$imsize
cat $config.$dec.$harange.$nchan.$imsize
cat $model.results

end:
