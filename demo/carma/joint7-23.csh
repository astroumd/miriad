#!/bin/csh -f

echo "   ---  Mosaicing with CARMA-23   ---   "
echo "   hex7.csh"
echo "This script assumes that antennas 1-6 are OVRO, 7-15 are HATCREEK, and 16-23 are SZA"
echo "   mchw. 15aug2002"
echo "   mchw. 02jul2004"

# History:
#  15aug02 mchw. edited from ALMA script.
#  23aug02 mchw. calculate region from source size.
#  02jul04 mchw. Version for CARMA-23
#  08jul04 mchw. Parameterize source model image, model_flux, and region


echo " "
echo " telescop   antdiam   jyperk"   
echo " ovro        10.4       43"
echo " hatcreek     6.1      126"
echo " carma        8.0       73"
echo " sza          3.5      383"
echo " sza10        6.0      128"
echo " sza6         4.6      220"
echo " "


# Nyquist sample time = 12 x (dish_diam/2)/(pi*baseline)/Npointings
# calc '12*(10.4/2)/(pi*2000)' = 0.01 hours = 36 sec/Npointings
# calc '12*(6.1/2)/(pi*1150)'  = 0.01 hours = 36 sec/Npointings
# Nyquist sample rate for each pointing. Using max baseline 250m.
# calc '12*(10.4/2)/(pi*250)' = 0.08 hours or 0.01 hours for 7 pointings.


goto start
start:

# check inputs
  if($#argv<3) then
    echo " Usage:  $0 array declination cell "
    echo "   e.g.  $0 config1 30 0.04"
    echo " Inputs :"
    echo "   array"
    echo "          Antenna array used by uvgen task."
    echo "            e.g. config1 . No default."
    echo "   declination"
    echo "          Source declination in degrees. No default."
    echo "   cell"
    echo "          scale size. No default."
    echo " "
    exit 1
  endif

# Cas A model, casc.vla, pixel=0.4", Cas A is about 320" diameter; image size 1024 == 409.6"
# scale model size. eg. cell=0.1 arcsec -> 80" diameter 

# Saturn model, sat1mm.modj2, pixel=0.1", Saturn's rings are ~ 50" diameter; imsize=603 == 60"

set model   = casc.vla
set model   = sat1mm.modj2
set config  = $1
set dec     = $2
set cell    = $3
set harange = -2,2,.008
set ellim   = 10
set select = '-shadow(3.5)'
set freq    = 230
set nchan   = 1
set imsize  = 129
set region  = 'arcsec,box(25,-25,-25,25)'
if($model == casc.vla)then
  set region = `calc "$cell*500" | awk '{printf("arcsec,box(%.2f,-%.2f,-%.2f,%.2f)",$1,$1,$1,$1)}'`
endif
if($model == sat1mm.modj2)then
  set region = `calc "$cell*250" | awk '{printf("arcsec,box(%.2f,-%.2f,-%.2f,%.2f)",$1,$1,$1,$1)}'`
endif

echo "   ---  Mosaicing with CARMA-23  -  $0 model=$model,  `date`   " >> $model.results

echo "   ---  Mosaicing with CARMA-23  ---   " > timing
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
echo " "                             >> timing
echo "   ---  TIMING   ---   "       >> timing
echo START: `date` >> timing

goto continue

echo "Generate mosaic grid for 10.4m (OVRO) antennas"
#  lambda/2*antdiam (arcsec)
# calc "300/$freq/2/10.4e3*2e5" = 12.5'' 

echo "Using $0 mosaic with 15'' spacing" >> $model.results

# assume aperture efficiency 75% to get jyperk
echo "Generate uv-data. Tsys=80,290,0.26, bandwidth=4 GHz " >> timing
rm -r carma.uv ovro.uv hatcreek.uv sza.uv sza10.uv sza6.uv
# CARMA
uvgen ant=$config.ant baseunit=-3.33564 radec=23:23:25.803,$dec lat=37.02 harange=$harange source=$MIRCAT/no.source systemp=80,290,0.26 jyperk=73 freq=$freq corr=$nchan,1,0,4000 out=carma.uv telescop=carma ellim=$ellim center=@hex7_15

# OVRO
uvgen ant=$config.ant baseunit=-3.33564 radec=23:23:25.803,$dec lat=37.02 harange=$harange source=$MIRCAT/no.source systemp=80,290,0.26 jyperk=43  freq=$freq corr=$nchan,1,0,4000 out=ovro.uv telescop=ovro ellim=$ellim center=@hex7_15

# HATCREEK
uvgen ant=$config.ant baseunit=-3.33564 radec=23:23:25.803,$dec lat=37.02 harange=$harange source=$MIRCAT/no.source systemp=80,290,0.26 jyperk=126 freq=$freq corr=$nchan,1,0,4000 out=hatcreek.uv telescop=hatcreek ellim=$ellim center=@hex7_15

# SZA
uvgen ant=$config.ant baseunit=-3.33564 radec=23:23:25.803,$dec lat=37.02 harange=$harange source=$MIRCAT/no.source systemp=80,290,0.26 jyperk=383 freq=$freq corr=$nchan,1,0,4000 out=sza.uv telescop=sza ellim=$ellim center=@hex7_15

# SZA-OVRO
uvgen ant=$config.ant baseunit=-3.33564 radec=23:23:25.803,$dec lat=37.02 harange=$harange source=$MIRCAT/no.source systemp=80,290,0.26 jyperk=128 freq=$freq corr=$nchan,1,0,4000 out=sza10.uv telescop=sza10 ellim=$ellim center=@hex7_15

# SZA-BIMA
uvgen ant=$config.ant baseunit=-3.33564 radec=23:23:25.803,$dec lat=37.02 harange=$harange source=$MIRCAT/no.source systemp=80,290,0.26 jyperk=220 freq=$freq corr=$nchan,1,0,4000 out=sza6.uv telescop=sza6 ellim=$ellim center=@hex7_15
echo UVGEN: `date` >> timing

uvindex vis=carma.uv


echo "Scale model size. from pixel 0.4 to $cell arcsec" >> timing
rm -r single.$dec.$model.$cell
cp -r $model single.$dec.$model.$cell
puthd in=single.$dec.$model.$cell/crval2 value=$dec,dms
puthd in=single.$dec.$model.$cell/crval3 value=$freq
puthd in=single.$dec.$model.$cell/cdelt1 value=-$cell,arcsec
puthd in=single.$dec.$model.$cell/cdelt2 value=$cell,arcsec

echo "Make model images for each pointing center and primary beam type" >> timing
rm -r carma.$model.$cell.demos*
rm -r ovro.$model.$cell.demos*
rm -r hatcreek.$model.$cell.demos*
rm -r sza*.$model.$cell.demos*
demos map=single.$dec.$model.$cell vis=carma.uv    out=carma.$model.$cell.demos
demos map=single.$dec.$model.$cell vis=ovro.uv     out=ovro.$model.$cell.demos
demos map=single.$dec.$model.$cell vis=hatcreek.uv out=hatcreek.$model.$cell.demos
demos map=single.$dec.$model.$cell vis=sza.uv      out=sza.$model.$cell.demos
demos map=single.$dec.$model.$cell vis=sza10.uv    out=sza10.$model.$cell.demos
demos map=single.$dec.$model.$cell vis=sza6.uv     out=sza6.$model.$cell.demos

echo "Make model uv-data using $model image model" >> timing
  rm -r carma.$dec.$model.$cell.uv*
  rm -r ovro.$dec.$model.$cell.uv*
  rm -r hatcreek.$dec.$model.$cell.uv*
  rm -r sza.$dec.$model.$cell.uv*
  rm -r sza10.$dec.$model.$cell.uv*
  rm -r sza6.$dec.$model.$cell.uv*
  foreach i ( 1 2 3 4 5 6 7 )
# OVRO
    cgdisp device=/xs labtyp=arcsec range=0,0,lin,8 in=ovro.$model.$cell.demos$i
    uvmodel vis=ovro.uv  model=ovro.$model.$cell.demos$i        options=add,selradec out=ovro.$dec.$model.$cell.uv$i     'select=ant(1,2,3,4,5,6)(1,2,3,4,5,6)'
# HATCREEK
    cgdisp device=/xs labtyp=arcsec range=0,0,lin,8 in=carma.$model.$cell.demos$i
    uvmodel vis=hatcreek.uv model=hatcreek.$model.$cell.demos$i options=add,selradec out=hatcreek.$dec.$model.$cell.uv$i 'select=ant(7,8,9,10,11,12,13,14,15)(7,8,9,10,11,12,13,14,15)'
# CARMA
    cgdisp device=/xs labtyp=arcsec range=0,0,lin,8 in=hatcreek.$model.$cell.demos$i
    uvmodel vis=carma.uv  model=carma.$model.$cell.demos$i  options=add,selradec out=carma.$dec.$model.$cell.uv$i  'select=ant(1,2,3,4,5,6)(7,8,9,10,11,12,13,14,15)'
# SZA
    cgdisp device=/xs labtyp=arcsec range=0,0,lin,8 in=sza.$model.$cell.demos$i
    uvmodel vis=sza.uv    model=sza.$model.$cell.demos$i    options=add,selradec out=sza.$dec.$model.$cell.uv$i    'select=ant(16,17,18,19,20,21,22,23)(16,17,18,19,20,21,22,23)'
# SZA-OVRO
    cgdisp device=/xs labtyp=arcsec range=0,0,lin,8 in=sza.$model.$cell.demos$i
    uvmodel vis=sza10.uv  model=sza10.$model.$cell.demos$i  options=add,selradec out=sza10.$dec.$model.$cell.uv$i  'select=ant(16,17,18,19,20,21,22,23)(1,2,3,4,5,6)'
# SZA-BIMA
    cgdisp device=/xs labtyp=arcsec range=0,0,lin,8 in=sza.$model.$cell.demos$i
    uvmodel vis=sza6.uv   model=sza6.$model.$cell.demos$i   options=add,selradec out=sza6.$dec.$model.$cell.uv$i   'select=ant(16,17,18,19,20,21,22,23)(7,8,9,10,11,12,13,14,15)'
  end
echo UVMODEL: `date` add the model to the noisy sampled uv-data >> timing

# catenate the uv-data so invert can handle the command line input
rm -r carma.$dec.$model.$cell.uv ovro.$dec.$model.$cell.uv hatcreek.$dec.$model.$cell.uv
rm -r sza.$dec.$model.$cell.uv sza10.$dec.$model.$cell.uv sza6.$dec.$model.$cell.uv
uvcat vis="carma.$dec.$model.$cell.uv*" out=carma.$dec.$model.$cell.uv
uvcat vis="ovro.$dec.$model.$cell.uv*"  out=ovro.$dec.$model.$cell.uv
uvcat vis="hatcreek.$dec.$model.$cell.uv*" out=hatcreek.$dec.$model.$cell.uv
uvcat vis="sza.$dec.$model.$cell.uv*"   out=sza.$dec.$model.$cell.uv
uvcat vis="sza10.$dec.$model.$cell.uv*" out=sza10.$dec.$model.$cell.uv
uvcat vis="sza6.$dec.$model.$cell.uv*"  out=sza6.$dec.$model.$cell.uv

rm -r $config.$dec.$model.$cell.mp $config.$dec.$model.$cell.bm
invert vis=carma.$dec.$model.$cell.uv,ovro.$dec.$model.$cell.uv,hatcreek.$dec.$model.$cell.uv,sza.$dec.$model.$cell.uv,sza10.$dec.$model.$cell.uv,sza6.$dec.$model.$cell.uv map=$config.$dec.$model.$cell.mp beam=$config.$dec.$model.$cell.bm imsize=$imsize sup=0 options=mosaic,double select=$select
echo INVERT: `date` >> timing
implot in=$config.$dec.$model.$cell.mp device=/xs units=s region=$region
imlist in=$config.$dec.$model.$cell.mp options=mosaic

#  					------------------------

single:
echo "Make single dish image and beam"  `date` >> timing
set pbfwhm = `pbplot telescop=ovro freq=$freq | grep FWHM | awk '{print 60*$3}'`
echo "Single dish FWHM = $pbfwhm arcsec at $freq GHz" >> timing

rm -r single.$dec.$model.$cell.bigger
imframe in=single.$dec.$model.$cell frame=-1024,1024,-1024,1024 out=single.$dec.$model.$cell.bigger
rm -r single.$dec.$model.$cell.bigger.map
convol map=single.$dec.$model.$cell.bigger fwhm=$pbfwhm,$pbfwhm out=single.$dec.$model.$cell.bigger.map
rm -r single.$dec.$model.$cell.map
regrid  in=single.$dec.$model.$cell.bigger.map tin=$config.$dec.$model.$cell.mp out=single.$dec.$model.$cell.map axes=1,2
rm -r single.$dec.$model.$cell.beam
imgen in=single.$dec.$model.$cell.map factor=0 object=gaussian spar=1,0,0,$pbfwhm,$pbfwhm,0 out=single.$dec.$model.$cell.beam
implot in=single.$dec.$model.$cell.map units=s device=/xs conflag=l conargs=2

puthd in=single.$dec.$model.$cell.map/rms value=7.32
# 1% noise

goto mosmem

continue:
joint:
echo "Joint deconvolution of interferometer and single dish data" >> timing
echo "Joint deconvolution of interferometer and single dish data ; niters=200 rmsfac=1,1" >> $model.results
rm -r $config.$dec.$model.$cell.mem $config.$dec.$model.$cell.cm
 mosmem  map=$config.$dec.$model.$cell.mp,single.$dec.$model.$cell.map beam=$config.$dec.$model.$cell.bm,single.$dec.$model.$cell.beam out=$config.$dec.$model.$cell.mem niters=200 region=$region rmsfac=1,1
goto restor

mosmem:
set flux = `histo in=$model | grep Flux | awk '{printf("%.3f   ", $6)}'`
echo " MOSMEM Interferometer only" >> timing
echo " MOSMEM Interferometer only with niters=200 flux=$flux rmsfac=1." >> $model.results 
rm -r $config.$dec.$model.$cell.mem $config.$dec.$model.$cell.cm
mosmem  map=$config.$dec.$model.$cell.mp beam=$config.$dec.$model.$cell.bm out=$config.$dec.$model.$cell.mem region=$region niters=200 flux=$flux rmsfac=1
goto restor

default:
echo "MOSMEM with default single dish image"  >> timing
echo "MOSMEM with default single dish image; niters=200 rmsfac=1"  >> $model.results
rm -r $config.$dec.$model.$cell.mem $config.$dec.$model.$cell.cm
mosmem map=$config.$dec.$model.$cell.mp default=single.$dec.$model.$cell.map beam=$config.$dec.$model.$cell.bm out=$config.$dec.$model.$cell.mem region=$region niters=200 rmsfac=1

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
set Model_Flux = `histo in=$config.$dec.$model.$cell.conv region=$region | grep Flux | awk '{printf("%.3f   ", $6)}'`
set Model_Peak = `histo in=$config.$dec.$model.$cell.conv region=$region | grep Maximum | awk '{printf("%.3f   ", $3)}'`
set Flux = `histo in=$config.$dec.$model.$cell.cm region=$region | grep Flux | awk '{printf("%.3f   ", $6)}'`
set Peak = `histo in=$config.$dec.$model.$cell.cm region=$region | grep Maximum | awk '{printf("%.3f   ", $3)}'`
set Fidelity = `calc $Peak/$SRMS | awk '{printf("%.0f", $1)}'`

echo "Config  DEC  HA[hrs]  scale  RMS  Beam[arcsec]  Model_Flux,Peak  Image_Flux,Peak Residual:Rms,Max,Min[Jy] Fidelity" >> timing
echo "$config  $dec  $harange  $cell  $RMS  $b1 $b2  $Model_Flux  $Model_Peak  $Flux $Peak  $SRMS  $SMAX  $SMIN  $Fidelity" >> timing
echo  " "
echo "$config  $dec  $harange  $cell  $RMS  $b1 $b2  $Model_Flux  $Model_Peak  $Flux $Peak  $SRMS  $SMAX  $SMIN  $Fidelity" >> $model.results
mv timing $config.$dec.$harange.$nchan.$imsize
cat $config.$dec.$harange.$nchan.$imsize
cat $model.results

end:
