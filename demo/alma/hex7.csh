#!/bin/csh -f
echo "   ---  ALMA Mosaicing (Cas A model)   ---   "
echo "   mchw. 12dec2012 version"

# History:
#  june 02 mchw. ALMA script.
#  15aug02 mchw. CARMA version edited from ALMA script.
#  23aug02 mchw. calculate region from source size.
#  20sep02 mchw. Re-import CARMA improvements for ALMA.
#  25sep02 mchw. Re-import improvements from hex7.csh to hex19.csh
#  26sep02 mchw. Increase imsize from 129 to 257.
#  24jun10 mchw. Added uv and image plots.
#  13jul10 mchw. Added default and joint deconvolutions.
#  16jul10 mchw. Added gif plots. Changed rmsfac=200 to 1, same as carma version.
#  29jul11 mchw. Added plot single dish and interferometer image
#  09dec12 mchw. Use imgen and regrid to make bigger single dish image instead of imframe.
#  12dec12 mchw. Remake hex7.csh from hex19.csh.

goto start
start:

# check inputs
  if($#argv<4) then
    echo " Usage:  $0 array declination cell "
    echo "   e.g.  $0 config1 -30 0.04 mosmem"
    echo " Inputs :"
    echo "   array"
    echo "          Antenna array used by uvgen task."
    echo "            e.g. config1 . No default."
    echo "   declination"
    echo "          Source declination in degrees. No default."
    echo "   cell"
    echo "          scale size. No default."
    echo "   method"
    echo "          Deconvolution method: mosmem, default,joint or plot. Default is mosmem"
    echo "          default and joint use the uvdata and images generated by mosmem"
    echo "          plot -- re- plots the last result"

    echo " "
    exit 1
  endif

# Cas A model, casc.vla, pixel=0.4", Cas A is about 320" diameter; image size 1024 == 409.6"
# scale model size. eg. cell=0.1 arcsec -> 80" diameter

# Saturn model, sat1mm.modj2, pixel=0.1", Saturn's rings are ~ 50" diameter; imsize=603 == 60"

set model   = sat1mm.modj2
set model   = Halo3.mp
set model   = casc.vla
set config  = $1
set dec     = $2
set cell    = $3
set method  = $4
# Nyquist sample rate for each pointing.
calc '6/(pi*250)*12'
set harange = -4,4,.013
set select  = '-shadow(12)'
set freq    = 230
set nchan   = 1
set imsize  = 257
set region  = 'arcsec,box(20,-20,-20,20)'
set region = `calc "$cell*500" | awk '{printf("arcsec,box(%.2f,-%.2f,-%.2f,%.2f)",$1,$1,$1,$1)}'`

echo "   ---  Mosaicing with ALMA  -  $0 model=$model,  `date`   " >> $0.$model.results
echo "   ---  Mosaicing with ALMA  -  $0 model=$model,  `date`   " > timing
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
echo " method  = $method"            >> timing
echo " "                             >> timing
echo "   ---  TIMING   ---   "       >> timing
echo START: `date` >> timing

if($method == plot) then
  goto plot
endif

if($method == default) then
  goto default
endif

if($method == joint) then
  goto joint
endif
:
echo "Generate mosaic grid"
#  lambda/2*antdiam (arcsec)
calc "300/$freq/2/12e3*2e5"

echo "Using hex7 mosaic with 12'' spacing" >> $0.$model.results


echo "Generate uv-data. Tsys=40K, bandwidth=8 GHz " >> timing
rm -r $config.uv
uvgen ant=$config.ant baseunit=-3.33564 radec=23:23:25.803,$dec lat=-23.02 harange=$harange source=$MIRCAT/no.source systemp=40 jyperk=40 freq=$freq corr=$nchan,1,0,8000 out=$config.uv telescop=alma center=@hex7
echo UVGEN: `date` >> timing
uvindex vis=$config.uv

echo "Scale model size. from pixel 0.4 to $cell arcsec" >> timing
# with 0.4 arcsec pixel size Cas A is about 320 arcsec diameter; image size 1024 == 409.6 arcsec
# scale model size. eg. cell=0.1 arcsec -> 80 arcsec cell=.01 -> 8 arcsec diameter
rm -r single.$dec.$model.$cell
cp -r casc.vla single.$dec.$model.$cell
puthd in=single.$dec.$model.$cell/crval2 value=$dec,dms
puthd in=single.$dec.$model.$cell/crval3 value=$freq
puthd in=single.$dec.$model.$cell/cdelt1 value=-$cell,arcsec
puthd in=single.$dec.$model.$cell/cdelt2 value=$cell,arcsec

echo "Make model images for each pointing center" >> timing
rm -r $config.$model.$cell.demos*
demos map=single.$dec.$model.$cell vis=$config.uv out=$config.$model.$cell.demos

echo "Make model uv-data using VLA image of Cas A as a model (the model has the VLA primary beam)" >> timing
  rm -r $config.$dec.$model.$cell.uv*
 foreach i ( 1 2 3 4 5 6 7 )
    cgdisp device=/xs labtyp=arcsec range=0,0,lin,8 in=$config.$model.$cell.demos$i
    uvmodel vis=$config.uv model=$config.$model.$cell.demos$i options=add,selradec out=$config.$dec.$model.$cell.uv$i
  end
echo UVMODEL: `date` add the model to the noisy sampled uv-data >> timing

uvplt vis=$config.$dec.$model.$cell.uv1 axis=uc,vc options=equal,nobase device=/xs
uvplt vis=$config.$dec.$model.$cell.uv1 axis=uc,vc options=equal,nobase device=uvplt.$config.$dec.$model.$cell.gif/gif

rm -r $config.$dec.$model.$cell.mp $config.$dec.$model.$cell.bm
invert "vis=$config.$dec.$model.$cell.uv*" map=$config.$dec.$model.$cell.mp beam=$config.$dec.$model.$cell.bm imsize=$imsize sup=0 options=mosaic,double select=$select
echo INVERT: `date` >> timing
implot in=$config.$dec.$model.$cell.mp device=/xs units=s region=$region
imlist in=$config.$dec.$model.$cell.mp options=mosaic

#  					------------------------
single:
echo "Make single dish image and beam"  `date` >> timing
set pbfwhm = `pbplot telescop=alma freq=$freq | grep FWHM | awk '{print 60*$3}'`
echo "Single dish FWHM = $pbfwhm arcsec at $freq GHz" >> timing

rm -r single.$dec.$model.$cell.bigger
#
# imframe is currently broken in the current, DEC 2012, Miriad install.
# imframe in=single.$dec.$model.$cell frame=-1024,1024,-1024,1024 out=single.$dec.$model.$cell.bigger
#
# so generate a bigger image using IMGEN and REGRID
rm -r imgen.map
imgen radec=23:23:25.803,$dec cell=$cell imsize=2048 object=level spar=0 out=imgen.map
regrid in=single.$dec.$model.$cell out=single.$dec.$model.$cell.bigger tin=imgen.map axes=1,2
rm -r single.$dec.$model.$cell.bigger.map
convol map=single.$dec.$model.$cell.bigger fwhm=$pbfwhm,$pbfwhm out=single.$dec.$model.$cell.bigger.map
rm -r single.$dec.$model.$cell.map
regrid  in=single.$dec.$model.$cell.bigger.map tin=$config.$dec.$model.$cell.mp out=single.$dec.$model.$cell.map axes=1,2
rm -r single.$dec.$model.$cell.beam
imgen in=single.$dec.$model.$cell.map factor=0 object=gaussian spar=1,0,0,$pbfwhm,$pbfwhm,0 out=single.$dec.$model.$cell.beam
implot in=single.$dec.$model.$cell.map units=s device=/xs conflag=l conargs=2
puthd in=single.$dec.$model.$cell.map/rms value=7.32

# plot single dish and interferometer image
cgdisp in=$config.$dec.$model.$cell.mp,single.$dec.$model.$cell.map region=$region device=/xs labtyp=arcsec

goto mosmem

joint:
echo "Joint deconvolution of interferometer and single dish data" >> timing
echo "Joint deconvolution of interferometer and single dish data ; niters=200 rmsfac=1,1" >> $0.$model.results
rm -r $config.$dec.$model.$cell.mem $config.$dec.$model.$cell.cm
 mosmem  map=$config.$dec.$model.$cell.mp,single.$dec.$model.$cell.map beam=$config.$dec.$model.$cell.bm,single.$dec.$model.$cell.beam out=$config.$dec.$model.$cell.mem niters=200 region=$region rmsfac=1,1
goto restor
 
mosmem:
echo " MOSMEM Interferometer only" >> timing
echo " MOSMEM Interferometer only with niters=200 flux=732.063 rmsfac=1." >> $0.$model.results
rm -r $config.$dec.$model.$cell.mem $config.$dec.$model.$cell.cm
mosmem  map=$config.$dec.$model.$cell.mp beam=$config.$dec.$model.$cell.bm out=$config.$dec.$model.$cell.mem region=$region niters=200 flux=732.063 rmsfac=1
goto restor

default:
echo "MOSMEM with default single dish image"  >> timing
echo "MOSMEM with default single dish image; niters=200 rmsfac=1"  >> $0.$model.results
rm -r $config.$dec.$model.$cell.mem $config.$dec.$model.$cell.cm
mosmem map=$config.$dec.$model.$cell.mp default=single.$dec.$model.$cell.map beam=$config.$dec.$model.$cell.bm out=$config.$dec.$model.$cell.mem region=$region niters=200 rmsfac=1
goto restor


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

  cgdisp range=0,0,lin,8 in=$config.$dec.$model.$cell.cm device=$config.$dec.$model.$cell.cm.gif/gif labtyp=arcsec,arcsec options=beambl,wedge  region=$region device=/xs
  cgdisp range=0,0,lin,8 in=$config.$dec.$model.$cell.cm device=$config.$dec.$model.$cell.cm.gif/gif labtyp=arcsec,arcsec options=beambl,wedge  region=$region
  cgdisp range=0,0,lin,8 in=$config.$dec.$model.$cell.regrid device=$config.$dec.$model.$cell.regrid.gif/gif labtyp=arcsec,arcsec options=beambl,wedge  region=$region device=/xs
  cgdisp range=0,0,lin,8 in=$config.$dec.$model.$cell.regrid device=$config.$dec.$model.$cell.regrid.gif/gif labtyp=arcsec,arcsec options=beambl,wedge  region=$region
rm -r $config.$dec.$model.$cell.imcat
imcat in=$config.$dec.$model.$cell.cm,$config.$dec.$model.$cell.regrid out=$config.$dec.$model.$cell.imcat options=relax
 cgdisp range=0,0,lin,8 in=$config.$dec.$model.$cell.imcat device=$config.$dec.$model.$cell.imcat.gif/gif labtyp=arcsec,arcsec options=beambl,wedge  region=$region device=/xs
 cgdisp range=0,0,lin,8 in=$config.$dec.$model.$cell.imcat device=$config.$dec.$model.$cell.imcat.gif/gif labtyp=arcsec,arcsec options=beambl,wedge region=$region


#  mv $config.$dec.$model.$cell.conv.gif ~/public_html


  rm -r $config.$dec.$model.$cell.resid
  imdiff in1=$config.$dec.$model.$cell.cm in2=$config.$dec.$model.$cell.regrid resid=$config.$dec.$model.$cell.resid options=nox,noy,noex
  implot device=/xs units=s in=$config.$dec.$model.$cell.resid region=$region
  histo in=$config.$dec.$model.$cell.resid region=$region

plot:
rm -r $config.$dec.$model.$cell.imcat
imcat in=$config.$dec.$model.$cell.cm,$config.$dec.$model.$cell.regrid options=relax out=$config.$dec.$model.$cell.imcat
cgdisp range=0,0,lin,8 in=$config.$dec.$model.$cell.imcat labtyp=arcsec,arcsec options=beambl,wedge region=$region device=/xs
cgdisp range=0,0,lin,8 in=$config.$dec.$model.$cell.imcat labtyp=arcsec,arcsec options=beambl,wedge region=$region device=$config.$dec.$model.$cell.imcat.gif/gif

if($method == plot) then
  goto end
endif

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

echo " Config  DEC  HA[hrs]    Beam[arcsec] scale Model_Flux,Peak  Image_Flux,Peak Residual:Rms,Max,Min[Jy] Fidelity" >> timing
echo  "$config  $dec  $harange  $RMS   $b1 $b2    $cell  $Model_Flux $Model_Peak  $Flux $Peak   $SRMS  $SMAX  $SMIN  $Fidelity" >> timing
echo  " "
echo  "$config  $dec  $harange  $RMS   $b1 $b2    $cell  $Model_Flux $Model_Peak  $Flux $Peak   $SRMS  $SMAX  $SMIN  $Fidelity" >> $0.$model.results
mv timing hex19.$config.$dec.$harange.$nchan.$imsize
cat $config.$dec.$harange.$nchan.$imsize
cat $0.$model.results
#enscript -r $0.$model.results

end:
