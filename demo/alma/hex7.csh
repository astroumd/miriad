#!/bin/csh -vf
echo "   ---  ALMA Mosaicing (Cas A model)   ---   "
echo "   mchw. 20sep02 version"

# History:
#  june 02 mchw. ALMA script.
#  15aug02 mchw. CARMA version edited from ALMA script.
#  23aug02 mchw. calculate region from source size.
#  20sep02 mchw. Re-import CARMA improvements for ALMA.
#  26sep02 mchw. Increase imsize from 129 to 257.

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

set config  = $1
set dec     = $2
set cell    = $3
# Nyquist sample rate for each pointing.
calc '6/(pi*250)*12'
set harange = -1,1,.013
set select  = '-shadow(12)'
set freq    = 230
set nchan   = 1
set imsize  = 257
set region  = 'arcsec,box(20,-20,-20,20)'
set region = `calc "$cell*500" | awk '{printf("arcsec,box(%.2f,-%.2f,-%.2f,%.2f)",$1,$1,$1,$1)}'`

echo "   ---  ALMA Mosaicing (Cas A model)   ---   " > timing
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
continue:

echo "Generate mosaic grid"
#  lambda/2*antdiam (arcsec)
calc "300/$freq/2/12e3*2e5"

echo "Using hex7 mosaic with 12'' spacing" >> casa.results


echo "Generate uv-data. Tsys=40K, bandwidth=8 GHz " >> timing
rm -r $config.uv
uvgen ant=$config.ant baseunit=-3.33564 radec=23:23:25.803,$dec lat=-23.02 harange=$harange source=$MIRCAT/no.source systemp=40 jyperk=40 freq=$freq corr=$nchan,1,0,8000 out=$config.uv telescop=alma center=@hex7
echo UVGEN: `date` >> timing
uvindex vis=$config.uv

echo "Scale model size. from pixel 0.4 to $cell arcsec" >> timing
# with 0.4 arcsec pixel size Cas A is about 320 arcsec diameter; image size 1024 == 409.6 arcsec
# scale model size. eg. cell=0.1 arcsec -> 80 arcsec cell=.01 -> 8 arcsec diameter
rm -r single.$dec.cas.$cell
cp -r casc.vla single.$dec.cas.$cell
puthd in=single.$dec.cas.$cell/crval2 value=$dec,dms
puthd in=single.$dec.cas.$cell/crval3 value=$freq
puthd in=single.$dec.cas.$cell/cdelt1 value=-$cell,arcsec
puthd in=single.$dec.cas.$cell/cdelt2 value=$cell,arcsec

echo "Make model images for each pointing center" >> timing
rm -r $config.cas.$cell.demos*
demos map=single.$dec.cas.$cell vis=$config.uv out=$config.cas.$cell.demos

echo "Make model uv-data using VLA image of Cas A as a model (the model has the VLA primary beam)" >> timing
  rm -r $config.$dec.cas.$cell.uv*
  foreach i ( 1 2 3 4 5 6 7 )
    cgdisp device=/xs labtyp=arcsec range=0,0,lin,8 in=$config.cas.$cell.demos$i
    uvmodel vis=$config.uv model=$config.cas.$cell.demos$i options=add,selradec out=$config.$dec.cas.$cell.uv$i
  end
echo UVMODEL: `date` add the model to the noisy sampled uv-data >> timing

rm -r $config.$dec.cas.$cell.mp $config.$dec.cas.$cell.bm
invert "vis=$config.$dec.cas.$cell.uv*" map=$config.$dec.cas.$cell.mp beam=$config.$dec.cas.$cell.bm imsize=$imsize sup=0 options=mosaic,double select=$select
echo INVERT: `date` >> timing
implot in=$config.$dec.cas.$cell.mp device=/xs units=s region=$region
imlist in=$config.$dec.cas.$cell.mp options=mosaic

#  					------------------------
single:
echo "Make single dish image and beam"  `date` >> timing
set pbfwhm = `pbplot telescop=alma freq=$freq | grep FWHM | awk '{print 60*$3}'`
echo "Single dish FWHM = $pbfwhm arcsec at $freq GHz" >> timing

rm -r single.$dec.cas.$cell.bigger
imframe in=single.$dec.cas.$cell frame=-1024,1024,-1024,1024 out=single.$dec.cas.$cell.bigger
rm -r single.$dec.cas.$cell.bigger.map
convol map=single.$dec.cas.$cell.bigger fwhm=$pbfwhm,$pbfwhm out=single.$dec.cas.$cell.bigger.map
rm -r single.$dec.cas.$cell.map
regrid  in=single.$dec.cas.$cell.bigger.map tin=$config.$dec.cas.$cell.mp out=single.$dec.cas.$cell.map axes=1,2
rm -r single.$dec.cas.$cell.beam
imgen in=single.$dec.cas.$cell.map factor=0 object=gaussian spar=1,0,0,$pbfwhm,$pbfwhm,0 out=single.$dec.cas.$cell.beam
implot in=single.$dec.cas.$cell.map units=s device=/xs conflag=l conargs=2
puthd in=single.$dec.cas.$cell.map/rms value=7.32


goto mosmem

joint:
echo "Joint deconvolution of interferometer and single dish data" >> timing
echo "Joint deconvolution of interferometer and single dish data ; niters=200 rmsfac=200,1" >> casa.results
rm -r $config.$dec.cas.$cell.mem $config.$dec.cas.$cell.cm
 mosmem  map=$config.$dec.cas.$cell.mp,single.$dec.cas.$cell.map beam=$config.$dec.cas.$cell.bm,single.$dec.cas.$cell.beam out=$config.$dec.cas.$cell.mem niters=200 region=$region rmsfac=200,1
goto restor
 
mosmem:
echo " MOSMEM Interferometer only" >> timing
echo " MOSMEM Interferometer only with niters=200 flux=732.063 rmsfac=200." >> casa.results
rm -r $config.$dec.cas.$cell.mem $config.$dec.cas.$cell.cm
mosmem  map=$config.$dec.cas.$cell.mp beam=$config.$dec.cas.$cell.bm out=$config.$dec.cas.$cell.mem region=$region niters=200 flux=732.063 rmsfac=200
goto restor

default:
echo "MOSMEM with default single dish image"  >> timing
echo "MOSMEM with default single dish image; niters=200 rmsfac=200"  >> casa.results
rm -r $config.$dec.cas.$cell.mem $config.$dec.cas.$cell.cm
mosmem map=$config.$dec.cas.$cell.mp default=single.$dec.cas.$cell.map beam=$config.$dec.cas.$cell.bm out=$config.$dec.cas.$cell.mem region=$region niters=200 rmsfac=200


restor:
restor map=$config.$dec.cas.$cell.mp beam=$config.$dec.cas.$cell.bm out=$config.$dec.cas.$cell.cm model=$config.$dec.cas.$cell.mem
echo MOSMEM: `date` >> timing 
implot device=/xs units=s in=$config.$dec.cas.$cell.cm region=$region
goto convolve

rm -r $config.$dec.cas.$cell.memrem
restor map=$config.$dec.cas.$cell.mp beam=$config.$dec.cas.$cell.bm out=$config.$dec.cas.$cell.memrem model=$config.$dec.cas.$cell.mem mode=residual
implot device=/xs units=s in=$config.$dec.cas.$cell.mem region=$region
mem_residual:
histo in=$config.$dec.cas.$cell.memrem region=$region | grep Rms
goto end

convolve:
echo "convolve the model by the beam and subtract from the deconvolved image" >> timing
  set b1=`prthd in=$config.$dec.cas.$cell.cm | egrep Beam     | awk '{print $3}'`
  set b2=`prthd in=$config.$dec.cas.$cell.cm | egrep Beam     | awk '{print $5}'`
  set b3=`prthd in=$config.$dec.cas.$cell.cm | egrep Position | awk '{print $3}'`
  rm -r $config.$dec.cas.$cell.conv
  convol map=single.$dec.cas.$cell fwhm=$b1,$b2 pa=$b3 out=$config.$dec.cas.$cell.conv
  implot in=$config.$dec.cas.$cell.conv device=/xs units=s region=$region
echo "regrid the convolved model to the deconvolved image template" >> timing
  rm -r $config.$dec.cas.$cell.regrid
  regrid in=$config.$dec.cas.$cell.conv out=$config.$dec.cas.$cell.regrid tin=$config.$dec.cas.$cell.cm axes=1,2
  implot in=$config.$dec.cas.$cell.regrid device=/xs units=s region=$region
#  cgdisp range=0,0,lin,8 in=$config.$dec.cas.$cell.conv device=$config.$dec.cas.$cell.conv.gif/gif labtyp=arcsec,arcsec options=beambl,wedge  region=$region
#  mv $config.$dec.cas.$cell.conv.gif ~/public_html

  rm -r $config.$dec.cas.$cell.resid
  imdiff in1=$config.$dec.cas.$cell.cm in2=$config.$dec.cas.$cell.regrid resid=$config.$dec.cas.$cell.resid options=nox,noy,noex
  implot device=/xs units=s in=$config.$dec.cas.$cell.resid region=$region
  histo in=$config.$dec.cas.$cell.resid region=$region
echo FINISH: `date` >> timing
echo " " >> timing

echo print out results - summarize rms and beam sidelobe levels
echo "   ---  RESULTS   ---   " >> timing
set RMS = `itemize in=$config.$dec.cas.$cell.mp   | grep rms       | awk '{printf("%.3f   ", 1000*$3)}'`
set SRMS = `histo in=$config.$dec.cas.$cell.resid region=$region | grep Rms | awk '{printf("%.3f   ", $4)}'`
set SMAX = `histo in=$config.$dec.cas.$cell.resid region=$region | grep Maximum | awk '{printf("%.3f   ", $3)}'`
set SMIN = `histo in=$config.$dec.cas.$cell.resid region=$region | grep Minimum | awk '{printf("%.3f   ", $3)}'`
set Model_Flux = `histo in=$config.$dec.cas.$cell.conv region=$region | grep Flux | awk '{printf("%.3f   ", $6)}'`
set Model_Peak = `histo in=$config.$dec.cas.$cell.conv region=$region | grep Maximum | awk '{printf("%.3f   ", $3)}'`
set Flux = `histo in=$config.$dec.cas.$cell.cm region=$region | grep Flux | awk '{printf("%.3f   ", $6)}'`
set Peak = `histo in=$config.$dec.cas.$cell.cm region=$region | grep Maximum | awk '{printf("%.3f   ", $3)}'`
set Fidelity = `calc $Peak/$SRMS | awk '{printf("%.0f", $1)}'`

echo " Config  DEC  HA[hrs]    Beam[arcsec] scale Model_Flux,Peak  Image_Flux,Peak Residual:Rms,Max,Min[Jy] Fidelity" >> timing
echo  "$config  $dec  $harange  $RMS   $b1 $b2    $cell  $Model_Flux $Model_Peak  $Flux $Peak   $SRMS  $SMAX  $SMIN  $Fidelity" >> timing
echo  " "
echo  "$config  $dec  $harange  $RMS   $b1 $b2    $cell  $Model_Flux $Model_Peak  $Flux $Peak   $SRMS  $SMAX  $SMIN  $Fidelity" >> casa.results
mv timing hex7.$config.$dec.$harange.$nchan.$imsize
cat $config.$dec.$harange.$nchan.$imsize
cat casa.results
#enscript -r casa.results

end:
