#! /bin/csh -fe
#
# moment.csh - for moment maps
#
#       Last update 21jul00 by tw
#               (Only write version into a new log)
set version="2010-Aug-27/mwp"
#
# Usage: moment.csh file=[file rootname (no extension) 
#        start=[straight/clip/mask/gaufit/gauclip/cleanup] \
#	     interact=[y/n] [vmin=] [vmax=] [xyreg=]
#
# Requires new routines: moment, vblank, gaufit
#	(moment needed only for median option)
#-------------------------------------------------------------------------

if ( $#argv == 0 ) goto usage
if ( $1 == "help") goto help

set path = ( $MIRBIN $HOME/mirbin $path )
echo " started program"
### REQUIRED PARAMETERS:
unset file          #root of filename (omit .$ext)
unset ext           # filename extension
unset rms           # rms noise per channel
# velocity range of emission (defaults to all):
unset vmin
unset vmax
unset start

### OPTIONAL PARAMETERS:
set interact=y
set mosaic=y
set fwhm=20  resolution of smoothed cube for masking
set vest=foo      # Name of input velocity image, which overrides
                  #   default VEL for gaufit when unblanked 
set fluxclip=3    # min allowed flux (Jy/bm km/s) for gaufits
set velclip=30    # max allowed velocity error (km/s) for gaufits
set log=moment.log
set vfwhm=1.5     # default velocity width estimate for gaufit.
set minvfwhm=1.5  # minimum allowed velocity width for gaufit.
set nxy=10,10


# spatial extent of emission (defaults to all):
set xyreg=
set vmask=

#-------------------------------------------------------------------------

# Override above parameters if given on command line
foreach a ( $* )
   set check=`echo $a | awk -F= '{print NF}'`
   if ( "$check" == 2 ) set $a
end

# Check parameters
if ( $?file == 0 ) then 
   echo "file= is required (file root) "
   exit 1
endif
if( $?ext == 0 ) then
   echo "ext= is required (file extension)"
   exit 1
endif
endif

if ( $?rms == 0 ) then  
   echo "rms= is required (rms noise per channel)"
   exit 1
endif

if ( $?vmin == 0 ) then
   echo "vmin= is required (lower velocity limit)"
   exit 1
endif

if ( $?vmax == 0 ) then
   echo "vmax= is required (upper velocity limit)"
   exit 1
endif

if ( $?start == 0 ) then
   echo "start= is required straight/clip/mask/gaufit/gauclip/cleanup]"
   exit 1
endif

# convert ($vmin,$vmax) to pixel range
set delv=`gethd in=$file.$ext/cdelt3`
set vi=`gethd in=$file.$ext/crval3`
set nmaps=`gethd in=$file.$ext/naxis3`
if ($vmin == "" && $vmax == "") then
    set vmin=$vi
    set vmax=`calc -i "$vi+($nmaps-1)*($delv)"`
    echo "Setting vmin=$vmin and vmax=$vmax"
endif
set vminpix=`calc -i "1+($vmin-($vi))/($delv)"`
set vmaxpix=`calc -i "1+($vmax-($vi))/($delv)"`
set vrange="image($vminpix,$vmaxpix)"
echo "=== VELOCITY RANGE is $vrange "

# calculate beam area in pixels
set bmaj=`gethd in=$file.$ext/bmaj`
set bmin=`gethd in=$file.$ext/bmin`
set pixsize=`gethd in=$file.$ext/cdelt2`
set beampix=`calc -f f7.2 "1.133*$bmaj*$bmin/$pixsize**2"`

# Generate normalized sensitivity cube (used in all methods):
if ($mosaic == "y")  then
    /bin/rm -rf $file.sen
    rm -rf $file.tmp
    mossen in=$file.$ext sen=$file.tmp
    set minval=`histo in=$file.tmp region='image(1)' |grep Min |awk '{printf "%.4f", $3}'`
    echo "Normalizing rms by $minval"
    maths exp="<$file.tmp>/$minval" out=$file.sen
    rm -rf $file.tmp
endif

#if ($interact == "n") then
set device=/xs
#else
#    set device=/xw
#endif

if !(-e $log) then
    echo "========== moment.csh version $version ==========" > $log
endif

if ($?start) goto $start

#-------------------------------------------------------------------------
# Method 0. Straight moment map with no clipping.  Useful for comparison.
#-------------------------------------------------------------------------

straight:
rm -rf $file.dmom0
moment in=$file.$ext out=$file.dmom0 mom=0 region=$vrange
cgdisp in=$file.dmom0 device=$device nxy=1 options=full,beambl \
        range=0,0,lin,3 labtyp=arcsec #region=$xyreg
echo "" | tee -a $log
echo "Making moment-0 map for $file with no clipping" | tee -a $log
set sum=`histo in=$file.dmom0 |grep Flux|awk '{printf "%.4f", $6}'`
echo -n "### Total flux, no clipping (Jy km/s):" | tee -a $log
calc -f f7.1 $sum/$beampix | tee -a $log

#-------------------------------------------------------------------------
# Method 1. Reduce noise by clipping.
#	This is the quickest method but can screen out low-level emission.
#       The clipping level rises as the sensitivity declines @ edge of map.
#-------------------------------------------------------------------------

clip:
### SET CLIPPING LEVELS:
set clip0=`calc -f f7.5 "$rms*2"`	# Mom 0
set clip1=`calc -f f7.5 "$rms*2.5"`	# Mom 1

# MOMENT 0:
echo "" | tee -a $log
echo "Making moment maps for $file using clipping" | tee -a $log
echo "Clipping at $clip0 for Moment 0" | tee -a $log
if ($mosaic == "y") then
    rm -rf $file.senmsk0
    maths exp="<$file.$ext>" mask="abs(<"$file.$ext">/<"$file.sen">).gt.$clip0" \
        out=$file.senmsk0
    rm -rf $file.mom0
    moment in=$file.senmsk0 out=$file.mom0 region=$vrange
else
    rm -rf $file.mom0
    moment in=$file.$ext out=$file.mom0 region=$vrange clip=$clip0
endif
mv $file.mom0/mask $file.mom0/mask1
cgdisp in=$file.mom0 device=$device nxy=1 options=full,beambl \
        range=0,0,lin,3 labtyp=arcsec #region=$xyreg
rm -rf $file.senmsk0

# Flux calculation
set sum=`histo in=$file.mom0 |grep Flux|awk '{printf "%.4f", $6}'`
echo -n "### Total flux, clip method (Jy km/s):" | tee -a $log
calc -f f7.1 $sum/$beampix | tee -a $log

momentOne:
# MOMENT 1:
echo "Clipping at $clip1 for Moment 1" | tee -a $log
if ($mosaic == "y") then
    rm -rf $file.senmsk1
    maths exp="<$file.$ext>" mask="abs(<$file.$ext>/<$file.sen>).gt.$clip1" \
        out=$file.senmsk1
    rm -rf $file.mom1tmp
    moment in=$file.senmsk1 out=$file.mom1tmp region=$vrange mom=1
else
    rm -rf $file.mom1tmp
    moment in=$file.$ext out=$file.mom1tmp region=$vrange mom=1 \
clip=$clip1
endif

rm -rf $file.mom1
maths mask="<$file.mom1tmp>.ge.$vmin.and.<$file.mom1tmp>.le.$vmax" \
    exp="<"$file.mom1tmp">" out=$file.mom1
mv $file.mom1/mask $file.mom1/mask1
cgdisp in=$file.mom1 device=$device nxy=1 options=full,beambl \
        range=$vmin,$vmax,lin,3 labtyp=arcsec #region=$xyreg
rm -rf $file.mom1tmp

momentTwo:
# MOMENT 2:
rm -rf $file.mom2
echo "Clipping at $clip1 for Moment 2" | tee -a $log
if ($mosaic == "y") then
    moment in=$file.senmsk1 out=$file.mom2 region=$vrange mom=2
else
    moment in=$file.$ext out=$file.mom2 region=$vrange mom=2 \
	clip=$clip1
endif
minmax in=$file.mom2
cgdisp in=$file.mom2 device=$device nxy=1 options=full,beambl \
        labtyp=arcsec #region=$xyreg

### OPTIONAL: Median method for mom1, more robust if poor S/N:
# options=median only exists in Tony Wong's special version
#if ($interact == "y") then
#    echo ""
#    echo -n "Make mom1 map using median method as well [y]? "
#    set resp = "$<"
#    if ($resp == "n") goto end
#    rm -rf $file.med.mom1
#    if ($mosaic == "y") then
#	moment in=$file.senmsk1 out=$file.med.mom1 mom=1 options=median region=$vrange
#    else
#        moment in=$file.$ext out=$file.med.mom1 mom=1 options=median
#    endif
#    mv $file.med.mom1/mask $file.med.mom1/mask1
#    cgdisp in=$file.med.mom1 device=$device nxy=1 options=full,beambl \
#	range=$vmin,$vmax,lin,3 labtyp=arcsec #region=$xyreg
#endif

goto end


#-------------------------------------------------------------------------
# Method 2. Reduce noise by masking with a smoothed dataset.
#	This eliminates most of the noise but not residual sidelobes.
#-------------------------------------------------------------------------

mask:
# Mask using 3 sigma level in smoothed dataset:
if ($mosaic == "y") then
    rm -rf $file.sen$ext
    maths exp="<"$file.$ext">/<"$file.sen">" out=$file.sen$ext
    set incube=sen$ext
else
    set incube=cm
endif
rm -rf $file.smo
convol map=$file.$incube fwhm=$fwhm pa=0 out=$file.smo 
echo "" | tee -a $log
echo "Making moment-0 map for $file using masking" | tee -a $log
echo "Smoothed $file.$ext by fwhm=$fwhm" | tee -a $log
if ($mosaic == "y") rm -rf $file.sen$ext

set srms=`histo $file.smo |grep Rms|awk '{printf "%.4f", $4}'`
set clip=`calc -f f7.5 "$srms*3"`
echo "Masking at value: $clip" | tee -a $log
rm -rf $file.msk
rm -rf $file.msk.res
maths exp="<"$file.$ext">" out=$file.msk mask="<"$file.smo">".gt.$clip
maths exp="<"$file.$ext">" out=$file.msk.res mask="<"$file.smo">".lt.$clip
if ($interact == "y") then
    cgdisp in=$file.msk device=$device type=p \
        options=full,3value labtyp=arcsec nxy=$nxy range=0,0,lin,3
    cgdisp in=$file.msk.res device=$device type=p \
        options=full,3value labtyp=arcsec nxy=$nxy range=0,0,lin,3
endif

### OPTIONAL: Require real emission to be in 2 or more consecutive 
### channels. (Note this may still leave sidelobes in).
if ($interact == "y") then
    echo ""
    echo -n "Use vblank to mask pixels isolated in velocity [n]? "
    set resp = "$<"
    if ($resp == "y") then
	echo "Used vblank to mask pixels isolated in velocity" >> $log
	rm -rf $file.mskr
	reorder in=$file.msk out=$file.mskr mode=312
	vblank in=$file.mskr tol=1
	rm -rf $file.msk
	reorder in=$file.mskr out=$file.msk mode=231
	cgdisp in=$file.msk device=$device region=$xyreg type=p \
	    options=full,3value labtyp=arcsec nxy=3,2 range=0,0,lin,3
    endif
endif

# MOMENT 0: use 1 sigma clipping
rm -rf $file.mmom0 $file.mmom1 $file.mmom2
set mrms=`histo $file.$ext region='quarter(1,2)' |grep Rms|awk '{printf "%.4f", $4}'`
set clip=`calc -f f7.5 "$mrms*$rms"`
moment in=$file.msk out=$file.mmom0 clip=$clip region=$vrange
moment in=$file.msk out=$file.mmom1 mom=1 clip=-99999,$clip region=$vrange 
set clip2=`calc -f f7.5 "$mrms*3"`	# Mom 1
moment in=$file.msk out=$file.mmom2 mom=2 clip=-99999,$clip2 region=$vrange 

mv $file.mmom0/mask $file.mmom0/mask1

#cgdisp in=$file.mmom0 device=$device nxy=1 options=full,beambl \
#	range=0,0,lin,3 labtyp=arcsec region=$xyreg
#set sum=`histo in=$file.mom0 |grep Flux|awk '{printf "%.4f", $6}'`
#echo -n "### Total masked flux (Jy km/s):" | tee -a $log
#calc -f f7.1 $sum/$beampix | tee -a $log

goto end


#-------------------------------------------------------------------------
# Method 3, Part I. Fit Gaussians to all profiles.
#	This is the most time consuming but often gives good results.
#-------------------------------------------------------------------------

gaufit:
# Since a single run of gaufit often leaves bad pixels, in this
# implementation there are two runs, with different initial estimates
# for the profile fwhm (30 and 60 km/s).  You can change the estimates
# by editing the script, or hash out the following line to just run once.
set step=1

# SET PARAMETERS:
set cutoff=`calc -f f7.5 "$rms*1.5"` # Min. allowed amplitude (>=1.5 sigma)
set wrange=$minvfwhm	# Min. allowed fwhm, in km/s
set rmsest=$rms		# Estimated rms noise
set estim=0,0,$vfwhm	# Default values for AMP,VEL,DISP.  Use 0 for AMP and
			#   VEL to put initial estimate at peak of profile.
			#   Best to give an estimate for DISP (fwhm in km/s).
set options=relax	# options=relax often gives better results,
			#   options=supbad only writes actual fits to log

dogaufit:
rm -rf $file.gaupar $file.gaures $file.gaumod $file.gaulog gaufit.$ext

if ($vmask == "") then
  set infile = $file.$ext
else
  maths exp="<"$file.$ext">" mask=$vmask out=gaufit.$ext
  set infile = gaufit.$ext
    
endif

gaufit in=$infile velest=$vest estim=$estim params=$file.gaupar \
	log=$file.gaulog rmsest=$rmsest cutoff=$cutoff \
	wrange=$wrange region=$xyreg options=$options 
#	model=$file.gaumod residual=$file.gaures
echo "" | tee -a $log
echo "gaufit on $file with estim=$estim cutoff=$cutoff vest=$vest" \
	| tee -a $log

# AMPLITUDES (Jy/bm)
split:
rm -rf $file.gauamp
imsub in=$file.gaupar out=$file.gauamp region='image(1)'
cgdisp in=$file.gauamp device=$device nxy=1 options=full,beambl,wedge \
	range=0,0,lin,3 labtyp=arcsec region=$xyreg

# VELOCITY CENTROIDS (km/s)
rm -rf $file.gauvel
imsub in=$file.gaupar out=$file.gauvel region='image(2)'
puthd in=$file.gauvel/bunit value='KM/S' type=ascii
puthd in=$file.gauvel/btype value='velocity' type=ascii
cgdisp in=$file.gauvel device=$device nxy=1 options=full,beambl,wedge \
	range=$vmin,$vmax,lin,3 labtyp=arcsec region=$xyreg

# DISPERSIONS (FWHM, km/s)
rm -rf $file.gaudis
imsub in=$file.gaupar out=$file.gaudis region='image(3)'
cgdisp in=$file.gaudis device=$device nxy=1 options=full,wedge \
	range=0,0,lin,3 labtyp=arcsec region=$xyreg

# VELOCITY ERROR (km/s)
rm -rf $file.gauerr
imsub in=$file.gaupar out=$file.gauerr region='image(5)'

# INTEGRATED INTENSITY (Jy/bm km/s)
rm -rf $file.gauint
maths exp="1.064*<$file.gauamp>*<$file.gaudis>" out=$file.gauint
puthd in=$file.gauint/bunit value='JY/BEAM.KM/S' type=ascii
mv $file.gauint/mask $file.gauint/mask1
cgdisp in=$file.gauint device=$device nxy=1 options=full,beambl,wedge \
       range=0,0,lin,3 labtyp=arcsec region=$xyreg
set sum=`histo in=$file.gauint |grep Flux|awk '{printf "%.4f", $6}'`
echo -n "### Flux prior to clipping (Jy km/s):" | tee -a $log
calc -f f7.1 $sum/$beampix | tee -a $log

# Planes 4-6 of $file.gaupar are formal errors in amp, centroid, width.
# Plane 7 of $file.gaupar is rms of residual cube.

# REPEAT WITH DIFFERENT PARAMETERS OR MERGE:
if ($?step) then
    set step = `expr $step + 1`
    if ($step == 2) then
        rm -rf $file.gaupar1
        mv $file.gaupar $file.gaupar1
        set estim=0,0,60
        goto dogaufit
    else if ($step == 3) then
        rm -rf $file.gaupar2
        mv $file.gaupar $file.gaupar2
        goto merge
    else
        goto end
    endif
else
    goto end
endif

merge:
echo "" | tee -a $log
echo "Consolidated two runs of gaufit" | tee -a $log
delhd in=$file.gaupar1/mask
delhd in=$file.gaupar2/mask
rm -rf $file.gaupar3
maths exp="<$file.gaupar2>" mask="<$file.gaupar1>.eq.0" out=$file.gaupar3
delhd in=$file.gaupar3/mask
rm -rf $file.gaupar
maths exp="<$file.gaupar1>+<$file.gaupar3>" out=$file.gaupar
goto split


#-------------------------------------------------------------------------
# Method 3, Part II.  Clip out Gaussians which were fitted to noise.
#-------------------------------------------------------------------------
# Clip out Gaussian fits with integrated fluxes less than fluxclip.
# This reduces positive noise bias resulting from all Gaussians being 
# positive, and is preferable to using a large amplitude cutoff in 
# GAUFIT which would preferentially remove broad emission lines.
# Also clip out Gaussians with large velocity errors.

gauclip:
# Define mask:
if ($mosaic == "y") then
    if !(-e $file.senmom0) moment in=$file.sen mom=-1 out=$file.senmom0
    set mask = $file.gauint/$file.senmom0.gt.$fluxclip.and.$file.gauerr.lt.$velclip
else
    set mask = $file.gauint.gt.$fluxclip.and.$file.gauerr.lt.$velclip
endif

rm -rf $file.gamp
maths exp="<$file.gauamp>" out=$file.gamp mask=$mask
cgdisp in=$file.gamp device=$device nxy=1 options=full,beambl,wedge \
        range=0,0,lin,3 labtyp=arcsec region=$xyreg
mv $file.gamp/mask $file.gamp/mask1

rm -rf $file.gmom0
maths exp="<$file.gauint>" out=$file.gmom0 mask=$mask
cgdisp in=$file.gmom0 device=$device nxy=1 options=full,beambl,wedge \
        range=0,0,lin,3 labtyp=arcsec region=$xyreg
mv $file.gmom0/mask $file.gmom0/mask1

rm -rf $file.gmom1
maths exp="<$file.gauvel>" out=$file.gmom1 mask=$mask
cgdisp in=$file.gmom1 device=$device nxy=1 options=full,beambl,wedge \
        range=$vmin,$vmax,lin,3 labtyp=arcsec region=$xyreg
mv $file.gmom1/mask $file.gmom1/mask1

rm -rf $file.gmom2
maths exp="<$file.gaudis>" out=$file.gmom2 mask=$mask
cgdisp in=$file.gmom2 device=$device nxy=1 options=full,wedge \
        range=0,0,lin,3 labtyp=arcsec region=$xyreg

rm -rf $file.gmom1err
maths exp="<$file.gauerr>" out=$file.gmom1err mask=$mask
cgdisp in=$file.gmom1err device=$device nxy=1 options=full,wedge \
        range=0,0,lin,3 labtyp=arcsec region=$xyreg

# to get the .gmom-1 file for determining the rotation curve
rm -rf $file.gmom-1
maths exp="<$file.gmom0>/<$file.gauvel>" out=$file.gmom-1 mask=$mask
cgdisp in=$file.gmom-1 device=$device nxy=1 options=full,wedge \
	range=0,0,lin,3 labtyp=arcsec region=$xyreg

# Flux calculation
set sum=`histo in=$file.gmom0 |grep Flux|awk '{printf "%.4f", $6}'`
echo "" | tee -a $log
echo "Clipped pixels with flux < $fluxclip and vel. error > $velclip" \
    | tee -a $log
echo -n "*** Flux after clipping (Jy km/s):" | tee -a $log
calc -f f7.1 $sum/$beampix | tee -a $log
#goto end


#===========================================================================
echo "reached plotting"

# Fancy plotting (contour levels must be set manually)

set plotfile=gmom0
cgdisp in=$file.$plotfile,$file.$plotfile type=c,p \
	slev=a,2 levs1=1,2,3,4,5,6,7,9,11,13,15 \
	range=0,40,lin labtyp=arcsec options=beambl,full \
	device=/vps nxy=1 region=$xyreg
mv pgplot.ps $file.$plotfile.ps
ghostview $file.$plotfile.ps &
#goto end

set plotfile=gmom1
cgdisp in=$file.$plotfile,$file.$plotfile type=p,c slev=a,10 \
	levs1=32,34,36,38,40,42,44,46,48,50,52,54,56,58,60,62,64,66,68,70,72 \
	range=$vmin,$vmax,lin,3 labtyp=arcsec options=beambl,wedge,full \
	region=$xyreg cols1=1 device=/vcps
mv pgplot.ps $file.$plotfile.ps
ghostview $file.$plotfile.ps &
goto end

#===========================================================================

cleanup:
rm -rf $file.gau*
rm -rf $file.msk*
rm -rf $file.sen*
rm -rf $file.smo*

end:
exit 0

help:
echo "This script is designed to compute 'intelligent' moments of mosaic data cubes. It will compute the moment map of a mosaic datacube in three different methods: "
echo "Method 0) Using moment with clipping level=0. Use start=straight"
echo "Method 1) Using a clipping level that varies as a function of map sensitivity as computed with mossen with a minimum of 2*rms for zero-th moment, 2.5*rms for first moment, and 3*rms for second moment. Use start=clip"
echo "Method 2) Reducing noise by masking with a smoothed version of the dataset. Use start=mask"
echo "Method 3) By fitting Gaussian profiles to the velocity data, and integrating the profiles rather than the data themselves. Use start=gaufit"
echo  " "
echo "The output files are: "
echo "For Methods 0 and 1:"
echo "<yourfile>.dmom0  -- the zero-th moment map with no clipping level"
echo "<yourfile>.mom0  -- the zero-th moment map with variable clipping level based on map rms"
echo "<yourfile>.mom1  -- the first moment map (velocity centroid) with variable clipping level"
echo "<yourfile>.mom1  -- the 2nd moment map (velocity dispersion) with variable clipping level"

echo " " 
echo "For Method 2:"
echo "<yourfile>.mmom0 -- zero-th moment via masking with smoothed dataset"
echo "<yourfile>.mmom1 -- first moment via masking with smoothed dataset"
echo "<yourfile>.mmom2 -- 2nd moment via masking with smoothed dataset"
echo " " 
echo "For Method 3:"
echo "<yourfile>.gmom0  -- zero-th moment of Gaussian fit"
echo "<yourfile>.gmom1  -- first moment of Gaussian fit"
echo "<yourfile>.gmom2  -- second moment (velocity dispersion) of Gaussian fit"
echo " "
echo "Note there are more hidden but less utilized options. Look at the code to investigate"

echo " "
usage:
echo "Usage: moment.csh file=[file root name (no extension)] ext=[extension] "
echo "       rms=[1 sigma rms]  start=[straight/clip/mask/gaufit/gauclip/cleanup] "
echo "	     [vmin=] [vmax=] [rms=] interact=[y/n]  [xyreg=]  ..."
echo " "
echo "FOR HELP: moment.csh help"
exit 1

