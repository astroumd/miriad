#! /bin/csh -f
#
# moment.csh - for moment maps
#
set version=04dec08
#
# Usage: moment.csh start=[straight/clip/mask/gaufit/cleanup] \
#   interact=[y/n] [vmin=] [vmax=] [xyreg=]
#
# Requires new routines: gaufit
#
#-------------------------------------------------------------------------

### REQUIRED PARAMETERS:
set file=               # input datacube
set rms=                # rms noise per channel

### OPTIONAL PARAMETERS:
set interact=y
set log=moment.log
set noisemap=           # Optional noise image, e.g. from MOSSEN
# Clipping levels are in units of rms
set clip0=2             # Clip level for mom0
set clip1=2.5           # Clip level for mom1
set clip1pk=4           # Clip level for vpeak
set clipsmo=3           # Clip level for masking by smoothed cube
set clip0smo=1          # Clip level for mom0 after smoothed mask
set fwhm=20             # fwhm of smoothing Gaussian for masking
# For gaufit
set estim=              # Can give initial estimates to use old gaufit2
set ampcut=3            # min allowed amp for Gaussian fits, in rms units
set fluxclip=4          # min allowed flux (Jy/bm km/s) for gaufits
set velclip=20          # max allowed velocity error (km/s) for gaufits

# velocity range of emission (defaults to all):
set vmin=
set vmax=

# region for display and flux calculation (default: inner quarter):
set xyregion=quarter

#-------------------------------------------------------------------------

# Override above parameters if given on command line
foreach a ( $* )
   set check=`echo $a | awk -F= '{print NF}'`
   if ( "$check" == 2 ) set $a
end

# Check parameters
if ($file == "") then
    echo "### FATAL ERROR: file= must be specified"
    exit 0
endif
if ($rms == "") then
    set rms=`gethd in=$file/rms`
    if ($rms == '') then
        echo "### Warning: rms= not specified"
    else
        echo "Using rms in header of $rms"
    endif
endif

# Get root of filename
if ($file:e == 'cm' || $file:e == 'sencm') then
    set base=$file:r
else
    set base=$file
endif

# convert ($vmin,$vmax) to pixel range
set delv=`gethd in=$file/cdelt3`
set nmaps=`gethd in=$file/naxis3`
set crval3=`gethd in=$file/crval3`
set crpix3=`gethd in=$file/crpix3`
set vel1=`calc -i "$crval3-($delv)*($crpix3-1)"`
set vel2=`calc -i "$crval3+($delv)*($nmaps-($crpix3))"`
if ($vmin == "" || $vmax == "") then
    if ($vel1 > $vel2) then
    set vmin=$vel2
    set vmax=$vel1
    else
    set vmin=$vel1
    set vmax=$vel2
    endif
    echo "Setting vmin=$vmin and vmax=$vmax"
    set vminpix=1
    set vmaxpix=$nmaps
else
    set vpix1=`calc -i "$crpix3+($vmin-($crval3))/($delv)"`
    set vpix2=`calc -i "$crpix3+($vmax-($crval3))/($delv)"`
    if ($vpix1 > $vpix2) then
    set vminpix=$vpix2
    set vmaxpix=$vpix1
    else
    set vminpix=$vpix1
    set vmaxpix=$vpix2
    endif
    if ($vmaxpix > $nmaps) set vmaxpix=$nmaps
    if ($vminpix < 1) set vminpix=1
    echo "Setting vminpix=$vminpix and vmaxpix=$vmaxpix"
endif
set vrange="image($vminpix,$vmaxpix)"

# calculate the beam area in pixels
set bmaj=`gethd in=$file/bmaj`
set bmin=`gethd in=$file/bmin`
set pixsize=`gethd in=$file/cdelt2`
set beampix=`calc -f f7.2 "1.133*$bmaj*$bmin/$pixsize**2"`

# if a noise image is given, normalize it and reduce it to a single plane
if ($noisemap != "") then
    if ($noisemap == $base.nse || $noisemap == $base.nse1) then
        rm -rf $noisemap.orig
        mv $noisemap $noisemap.orig
        set noisemap = $noisemap.orig
    endif
    rm -rf $base.nse $base.nse1
    set minval=`histo in=$noisemap region='arc,box(-30,-30,30,30)(1)'|grep Min|awk '{print $3}'`
    echo "Normalizing $noisemap by $minval"
    maths exp="$noisemap/$minval" region='image(1)' out=$base.nse1
    imblr in=$base.nse1 out=$base.nse value=1
    rm -rf $base.nse1
    if ($rms == '') set rms=$minval
endif

if ($interact == "n") then
    set device=/xs
else
    set device=/xw
endif

if !(-e $log) then
    echo "========== moment.csh version $version ==========" > $log
endif

if ($?start) then
    goto $start
endif

goto continue
continue:

#-------------------------------------------------------------------------
# Default. Make unclipped moment map and peak intensity & velocity images
#-------------------------------------------------------------------------

straight:
# Unclipped mom-0
rm -rf $base.dmom0
moment in=$file out=$base.dmom0 mom=0 region=$vrange
cgdisp in=$base.dmom0 device=$device nxy=1 options=full,beambl \
        range=0,0,lin,3 labtyp=arcsec region=$xyregion
echo "" | tee -a $log
echo "Making moment-0 map for $file with no clipping" | tee -a $log
set flux=`histo in=$base.dmom0 | grep Flux | awk '{print $6}'`
echo "### Total flux, no clipping (Jy km/s): $flux" | tee -a $log
if ($noisemap != "") then
    rm -rf $base.dmom0.nse
    maths exp="sqrt($nmaps)*$rms*$delv*$base.nse" out=$base.dmom0.nse
endif

# Peak intensity
echo ""
echo "Making peak intensity map"
rm -rf $base.peak
moment in=$file out=$base.peak mom=-2 region=$vrange
cgdisp in=$base.peak device=$device nxy=1 options=full,beambl \
        range=0,0,lin,3 labtyp=arcsec region=$xyregion

# Peak velocity
echo ""
echo "Making peak velocity map"
# Set clipping level:
set min1=`calc -f f10.5 "$rms*$clip1pk"`
echo "Clipping at $min1 for peak velocity"
if ($noisemap != "") then
    rm -rf $base.norm
    maths exp="<$file>/<$base.nse>" out=$base.norm options=grow
    set incube=$base.norm
else
    set incube=$file
endif
rm -rf $base.sub
imsub in=$incube out=$base.sub region=$vrange
rm -rf $base.tr
reorder in=$base.sub out=$base.tr mode=312
rm -rf $base.vpeak
moment in=$base.tr out=$base.vpeak mom=-3 axis=1 clip=-9999,$min1
cgdisp in=$base.vpeak device=$device nxy=1 options=full,beambl \
        range=$vmin,$vmax,lin,3 labtyp=arcsec region=$xyregion
rm -rf $base.sub $base.tr
goto end

#-------------------------------------------------------------------------
# Method 1. Reduce noise by clipping.
#   This is the quickest method but can screen out low-level emission.
#       The clipping level rises as the sensitivity declines @ edge of map.
#-------------------------------------------------------------------------

clip:
# SET CLIPPING LEVELS:
set min0=`calc -f f10.5 "$rms*$clip0"`  # Mom 0
set min1=`calc -f f10.5 "$rms*$clip1"`  # Mom 1

# MOMENT 0:
echo "" | tee -a $log
echo "Making moment maps for $file using clipping" | tee -a $log
echo "Clipping at $min0 for Moment 0" | tee -a $log
if ($noisemap != "") then
    rm -rf $base.senmsk0
    maths exp=$file mask="abs(<$file>/<$base.nse>).gt.$min0" \
        out=$base.senmsk0 options=grow
    rm -rf $base.mom0
    moment in=$base.senmsk0 out=$base.mom0 region=$vrange mom=0
    rm -rf $base.senmsk0
else
    rm -rf $base.mom0
    moment in=$file out=$base.mom0 region=$vrange clip=$min0 mom=0
endif
cgdisp in=$base.mom0 device=$device nxy=1 options=full,beambl \
        range=0,0,lin,3 labtyp=arcsec region=$xyregion

# Flux calculation
set flux=`histo in=$base.mom0 region=$xyregion | grep Flux | awk '{print $6}'`
echo "### Total flux, clip method (Jy km/s): $flux" | tee -a $log

# MOMENT 1 (clip all negative values):
echo "Clipping at $min1 for Moment 1" | tee -a $log
if ($noisemap != "") then
    rm -rf $base.senmsk1
    maths exp=$file mask="<$file>/<$base.nse>.gt.$min1" \
        out=$base.senmsk1 options=grow
    rm -rf $base.mom1
    moment in=$base.senmsk1 out=$base.mom1 region=$vrange mom=1 rngmsk=true
    rm -rf $base.senmsk1
else
    rm -rf $base.mom1
    moment in=$file out=$base.mom1 region=$vrange mom=1 rngmsk=true \
    clip=-9999,$min1
endif
cgdisp in=$base.mom1 device=$device nxy=1 options=full,beambl \
        range=$vmin,$vmax,lin,3 labtyp=arcsec region=$xyregion
goto end


#-------------------------------------------------------------------------
# Method 2. Reduce noise by masking with a smoothed dataset.
#   This eliminates most of the noise but not residual sidelobes.
#-------------------------------------------------------------------------

mask:

# Mask using 3 sigma level in smoothed dataset:
if ($noisemap != "") then
    rm -rf $base.norm
    maths exp="<$file>/<$base.nse>" out=$base.norm options=grow
    set incube=$base.norm
else
    set incube=$file
endif
rm -rf $base.smo
convol map=$incube fwhm=$fwhm pa=0 out=$base.smo 
echo "" | tee -a $log
echo "Making moment-0 map for $file using masking" | tee -a $log
echo "Smoothed $file by fwhm=$fwhm" | tee -a $log
set srms=`histo in=$base.smo region='image(1,3)'|grep Rms|awk '{print $4}'`
set clip=`calc -f f10.5 "$srms*$clipsmo"`
echo "Masking at value: $clip" | tee -a $log
rm -rf $base.msk
rm -rf $base.msk.res
maths exp="<$file>" out=$base.msk mask="<$base.smo>.gt.$clip"
maths exp="<$file>" out=$base.msk.res mask="<$base.smo>.lt.$clip"
if ($interact == "y") then
    cgdisp in=$base.msk device=$device region=$xyregion type=p \
        options=full,3value labtyp=arcsec nxy=4,3 range=0,0,lin,3
    cgdisp in=$base.msk.res device=$device region=$xyregion type=p \
        options=full,3value labtyp=arcsec nxy=4,3 range=0,0,lin,3
endif

# MOMENT 0
# Set clipping level.  2nd case for no clipping.
if ($clip0smo != '0') then
    set min0=`calc -f f10.5 "$rms*$clip0smo"`
    echo "Clipping at $min0 for Moment 0" | tee -a $log
    rm -rf $base.msk.clip $base.msk.unit
    if ($noisemap != "") then
        maths exp=$base.msk mask="abs(<$base.msk>/<$base.nse>).gt.$min0" \
            out=$base.msk.clip options=grow
        maths exp="$base.msk*0+1" mask="abs(<$base.msk>/<$base.nse>).gt.$min0" \
            out=$base.msk.unit options=grow
    else
        maths exp=$base.msk mask="abs(<$base.msk>).gt.$min0" \
            out=$base.msk.clip
        maths exp="$base.msk*0+1" mask="abs(<$base.msk>).gt.$min0" \
            out=$base.msk.unit
    endif
    delhd in=$base.msk.unit/mask
    rm -rf $base.mmom0
    moment in=$base.msk.clip out=$base.mmom0 region=$vrange mom=0
    rm -rf $base.mmom0.nch
    moment in=$base.msk.unit out=$base.mmom0.nch region=$vrange mom=0
    rm -rf $base.mmom0.nse
    # We only multiply by sqrt($delv) since .nch has an extra factor of $delv
    if ($noisemap != "") then
        maths exp="sqrt($base.mmom0.nch*$delv)*$rms*$base.nse" out=$base.mmom0.nse
    else
        maths exp="sqrt($base.mmom0.nch*$delv)*$rms" out=$base.mmom0.nse
    endif
    rm -rf $base.msk.clip $base.msk.unit
else
    rm -rf $base.msk.unit
    maths exp="$base.msk*0+1" out=$base.msk.unit
    delhd in=$base.msk.unit/mask
    rm -rf $base.mmom0
    moment in=$base.msk out=$base.mmom0 region=$vrange mom=0
    rm -rf $base.mmom0.nch
    moment in=$base.msk.unit out=$base.mmom0.nch region=$vrange mom=0
    rm -rf $base.mmom0.nse
    # We only multiply by sqrt($delv) since .nch has an extra factor of $delv
    if ($noisemap != "") then
        maths exp="sqrt($base.mmom0.nch*$delv)*$rms*$base.nse" out=$base.mmom0.nse
    else
        maths exp="sqrt($base.mmom0.nch*$delv)*$rms" out=$base.mmom0.nse
    endif
    rm -rf $base.msk.unit
endif

cgdisp in=$base.mmom0 device=$device nxy=1 options=full,beambl \
    range=0,0,lin,3 labtyp=arcsec region=$xyregion
set flux=`histo in=$base.mmom0 region=$xyregion | grep Flux | awk '{print $6}'`
echo "### Total masked flux (Jy km/s): $flux" | tee -a $log
goto end


#-------------------------------------------------------------------------
# Method 3, Part I. Fit Gaussians to all profiles.
#   This is the most time consuming but often gives good results.
#-------------------------------------------------------------------------

gaufit:

# SET PARAMETERS:
set cutoff=`calc -f f7.5 "$rms*$ampcut"`   # Min. allowed amplitude
set rmsest=$rms                            # Estimated rms noise

# Normalize to sensitivity map
if ($noisemap != "") then
    rm -rf $base.norm
    maths exp="<$file>/<$base.nse>" out=$base.norm options=grow
    set file=$base.norm
endif

# Deal with bug in gaufit that crashes if there is a Stokes axis
if (-e $file/mask || `gethd in=$file/naxis` == '4') then
    rm -rf $file.cp
    imblr in=$file out=$file.cp
    puthd in=$file.cp/naxis value=3
    set dogauss=$file.cp
else
    set dogauss=$file
endif
rm -rf $base.gaupar $base.gaures $base.gaumod $base.gaulog
echo "" | tee -a $log
if ($estim != "") then
    gaufit2 in=$dogauss params=$base.gaupar log=$base.gaulog rmsest=$rmsest \
        cutoff=$cutoff options=relax estim=$estim model=$base.gaumod
    echo "gaufit2 on $dogauss with estim=$estim cutoff=$cutoff" | tee -a $log
else
    gaufit in=$dogauss params=$base.gaupar log=$base.gaulog rmsest=$rmsest \
        cutoff=$cutoff options=findestim,abspix model=$base.gaumod
    echo "gaufit on $dogauss with cutoff=$cutoff" | tee -a $log
endif
rm -rf $file.cp

# AMPLITUDES (Jy/bm)
rm -rf $base.gauamp
imsub in=$base.gaupar out=$base.gauamp region='image(1)'
cgdisp in=$base.gauamp device=$device nxy=1 options=full,beambl,wedge \
    range=0,0,lin,3 labtyp=arcsec region=$xyregion

# VELOCITY CENTROIDS (km/s)
rm -rf $base.gauvel
imsub in=$base.gaupar out=$base.gauvel region='image(2)'
puthd in=$base.gauvel/bunit value='KM/S' type=ascii
puthd in=$base.gauvel/btype value='velocity' type=ascii
cgdisp in=$base.gauvel device=$device nxy=1 options=full,beambl,wedge \
    range=$vmin,$vmax,lin,3 labtyp=arcsec region=$xyregion

# DISPERSIONS (FWHM, km/s)
rm -rf $base.gaudis
imsub in=$base.gaupar out=$base.gaudis region='image(3)'
puthd in=$base.gaudis/bunit value='KM/S' type=ascii
puthd in=$base.gaudis/btype value='velocity' type=ascii
cgdisp in=$base.gaudis device=$device nxy=1 options=full,wedge \
    range=0,0,lin,3 labtyp=arcsec region=$xyregion

# VELOCITY ERROR (km/s)
rm -rf $base.gauerr
imsub in=$base.gaupar out=$base.gauerr region='image(5)'
puthd in=$base.gauerr/bunit value='KM/S' type=ascii
puthd in=$base.gauerr/btype value='velocity' type=ascii

# INTEGRATED INTENSITY (Jy/bm km/s)
rm -rf $base.gauint
maths exp="1.064*$base.gauamp*$base.gaudis" out=$base.gauint
puthd in=$base.gauint/bunit value='JY/BEAM.KM/S' type=ascii
mv $base.gauint/mask $base.gauint/mask1
cgdisp in=$base.gauint device=$device nxy=1 options=full,beambl,wedge \
    range=0,0,lin,3 labtyp=arcsec region=$xyregion
set flx=`histo in=$base.gauint region=$xyregion | grep Flux | awk '{print $6}'`
echo "### Flux prior to clipping (Jy km/s): $flx" | tee -a $log

# Planes 4-6 of $base.gaupar are formal errors in amp, centroid, width.
# Plane 7 of $base.gaupar is rms of residual cube.


#-------------------------------------------------------------------------
# Clip out Gaussians which were fitted to noise.
#-------------------------------------------------------------------------
# Clip out Gaussian fits with integrated fluxes less than fluxclip.
# This reduces positive noise bias resulting from all Gaussians being 
# positive, and is preferable to using a large amplitude cutoff in 
# GAUFIT which would preferentially remove broad emission lines.
# Also clip out Gaussians with large velocity errors.

gauclip:
# Define mask:
set mask = $base.gauint.gt.$fluxclip.and.$base.gauerr.lt.$velclip

# Amplitude and integral require renormalization
rm -rf $base.gamp
if ($noisemap != "") then
    maths exp="<$base.gauamp>*<$base.nse>" out=$base.gamp mask=$mask
else
    maths exp=$base.gauamp out=$base.gamp mask=$mask
endif
cgdisp in=$base.gamp device=$device nxy=1 options=full,beambl,wedge \
        range=0,0,lin,3 labtyp=arcsec region=$xyregion
mv $base.gamp/mask $base.gamp/mask1

rm -rf $base.gmom0
if ($noisemap != "") then
    maths exp="<$base.gauint>*<$base.nse>" out=$base.gmom0 mask=$mask
else
    maths exp=$base.gauint out=$base.gmom0 mask=$mask
endif
cgdisp in=$base.gmom0 device=$device nxy=1 options=full,beambl,wedge \
        range=0,0,lin,3 labtyp=arcsec region=$xyregion
mv $base.gmom0/mask $base.gmom0/mask1

rm -rf $base.gmom1
maths exp=$base.gauvel out=$base.gmom1 mask=$mask
cgdisp in=$base.gmom1 device=$device nxy=1 options=full,beambl,wedge \
        range=$vmin,$vmax,lin,3 labtyp=arcsec region=$xyregion
mv $base.gmom1/mask $base.gmom1/mask1

rm -rf $base.gmom2
maths exp=$base.gaudis out=$base.gmom2 mask=$mask
cgdisp in=$base.gmom2 device=$device nxy=1 options=full,wedge \
        range=0,0,lin,3 labtyp=arcsec region=$xyregion

rm -rf $base.gmom1err
maths exp=$base.gauerr out=$base.gmom1err mask=$mask
cgdisp in=$base.gmom1err device=$device nxy=1 options=full,wedge \
        range=0,0,lin,3 labtyp=arcsec region=$xyregion

# Flux calculation
set flx=`histo in=$base.gmom0 region=$xyregion | grep Flux | awk '{print $6}'`
echo "Clipped pixels with flux < $fluxclip and vel. error > $velclip" \
    | tee -a $log
echo "*** Flux after clipping (Jy km/s): $flx" | tee -a $log
goto end

#===========================================================================

cleanup:
rm -rf $base.nse
rm -rf $base.gaupar
rm -rf $base.msk $base.msk.res
rm -rf $base.norm
rm -rf $base.smo

end:
