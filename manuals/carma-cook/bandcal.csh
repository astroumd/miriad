#! /bin/csh -f
# 
# 1. Uses noise source for narrow-band channel to channel bandpass calibration
#    Conjugate LSB for USB
# 2. Uses astronomical source for wideband and low-order polynomical narrow-
#    band passband calibration
# 3. Uses hybrid mode data for band-offset phase calibration
# 4. Generates temporal phase calibration from phase calibrator using
#    super-wideband (average of all three bands from both sidebands)
# 5. Applies calibrations to each of the source data bands
# 6. Glues source bands back together
# 7. Flags bad channels in overlap region between bands.

# Assumes that a relatively bright quasar has been observed in the following
# modes:
# 1. 500/500/500
# 2. nb / nb/ nb   nb=narrowband
# 3. With 2 bands in narrowband and the other in 500.  aka "hybrid" mode
#     Note - easy mod to script to use 1 band in nb, others in hybrid.
#
# SNV 2/18/2007

# Assumes data properly flagged so that self cal solutions are good!!
# Make sure refant is a good choice!

# To-do list:
# 1. this script assumes just one visibility calibrator

# User parameters

set vis = c0064.jk_m51co_c.4.miriad  # visibility file
set refant=9                         # reference antenna
set cal = 3C279                      # passband calibrator
set viscal = 1153+495                # visibility calibrator
set source = M51MOS                  # source
set nb_array = ( 4 5 6 )             # spectral line bands to calibrate
set wide_array = ( 5 6 5 )           # hybrid band with wide setup
set superwidewin = "2,3,5,6"         # windows to use for super-wideband
set superwidechan = "1,1,60"         # Channels for superwide
set bw = 64                          # Spectral Line bandwidth
set wideline = "1,3,11,11"           # line type for 500 MHz
set narrowline = "1,3,58,58"         # line type for narrow band
set sideband = "usb"                 # Sideband (used for noise conjugation)
set calint = 0.1                     # passband calibration interval (minutes)
set vcalint = 42                     # visibility calibrator cal interval
set order = 1                        # polynomial order for smamfcal fit
set edge = 3                         # # of edge channels to discard in smamfcal
set badants = "2,3,5"                # bad antennas to flag
                                     # Do heavy uvflagging prior to script
set badchan1 = "6,61,1,1"            # bad overlap channels between 1st 2 bands
set badchan2 = "6,124,1,1"           # bad overlap channels between 2nd 2 bands
set restfreq = 115.271203            # rest frequency of line

# End user parameters

uvflag vis=$vis select=anten'('$badants')' flagval=flag

rm -rf all.wide all.nb all.hyb 
rm -rf $cal.wide* $cal.nb* $cal.hyb* 

# Select all-wideband and all-narrowband data
bwsel vis=$vis bw=500,500,500 nspect=6 out=all.wide 
bwsel vis=$vis bw=$bw,$bw,$bw nspect=6 out=all.nb

# First get super-wideband on passband calibrator and phase calibrator
rm -r $cal.wide $cal.wide.0 $viscal.v.wide $viscal.v.wide.0
uvcat vis=all.wide out=$cal.wide.0 \
        "select=-auto,source($cal)" options=nocal,nopass
uvcat vis=all.wide out=$viscal.v.wide.0 \
        "select=-auto,source($viscal)" options=nocal,nopass

# mfcal passband on superwideband 
# Don't bother using noise source for superwideband
mfcal vis=$cal.wide.0 interval=0.1 refant=$refant
echo "**** Plot super-wideband passband on $cal.wide.0 "
gpplt vis=$cal.wide.0 options=bandpass yaxis=phase nxy=4,4 yrange=-360,360 device=bp$cal.wide.0.ps/ps
gv bp$cal.wide.0.ps

# Inspect temporal phase variation on superwideband
echo "**** Check temporal phase variations on superwideband $cal.wide.0 "
gpplt vis=$cal.wide.0 yaxis=phase yrange=-360,360 nxy=4,4 device=p$cal.wide.0.ps/ps
gv p$cal.wide.0.ps

# Apply superwideband passband for later use in band offset cal
uvcat vis=$cal.wide.0 out=$cal.wide options=nocal

# Copy wideband passband to visibility calibrator
gpcopy vis=$cal.wide.0 out=$viscal.v.wide.0 options=nocal,nopol
uvcat vis=$viscal.v.wide.0 out=$viscal.v.wide options=nocal

# Determine phase gain variations on visibility calibrator using superwide
rm -r $viscal.v.wide.sw
uvcat vis=$viscal.v.wide out=$viscal.v.wide.sw select='win('$superwidewin')' 
selfcal vis=$viscal.v.wide.sw line=channel,$superwidechan \
     interval=$vcalint options=phase refant=$refant
echo "**** Phases on the superwideband visibility calibrator $viscal.v.wide.sw"
gpplt vis=$viscal.v.wide.sw device=p$viscal.v.wide.ps/ps yaxis=phase yrange=-360,360 nxy=4,4 
gv p$viscal.v.wide.sw.ps

# LOOP OVER EACH NARROW BAND

foreach i ( 1 2 3 )

set nb = $nb_array[$i]
set wide = $wide_array[$i]

rm -r all.hyb
# Select hybrid data 
# NB:  assumes only 1 band is in wideband mode; if two bands are in wideband
#      mode, change hybrid selection to select on nb and modify bw=
if ( $wide == 1 || $wide == 4 ) \
    bwsel vis=$vis nspect=6 bw=500,$bw,$bw out=all.hyb
if ( $wide == 2 || $wide == 5 ) \
    bwsel vis=$vis nspect=6 bw=$bw,500,$bw out=all.hyb
if ( $wide == 3 || $wide == 6 ) \
    bwsel vis=$vis nspect=6 bw=$bw,$bw,500 out=all.hyb

echo "**** Be sure that one band is found by inspecting uvlist output!"
echo "**** If no frequency info is found, that bwsel parameters are wrong"
uvlist vis=all.hyb options=spectra

# Now we need to select single bands to process in this pass
# Select by source and band
# First get the two bands in all-wideband mode
# Note that we use super-wideband calibrated file for the wide mode
rm -rf $cal.win$nb* $cal.win$wide* $cal.wide.win$wide* $cal.wide.win$nb*
rm -rf $cal.hyb.win$nb* $cal.hyb.win$wide* noise.nb.win$nb*
uvcat vis=$cal.wide out=$cal.wide.win$wide "select=-auto,source($cal),win($wide)" \
	options=nocal,nopass
uvcat vis=$cal.wide out=$cal.wide.win$nb "select=-auto,source($cal),win($nb)" \
	options=nocal,nopass

# Now select hybrid wideband band
uvcat vis=all.hyb out=$cal.hyb.win$wide.0 "select=-auto,source($cal),win($wide)" \
	options=nocal,nopass
# Now select the hybrid and all-narrowband narrow bands
# nb bands require extra step (applying noise source)
# we did not bother with noise source for wideband
uvcat vis=all.hyb out=$cal.hyb.win$nb.00 "select=-auto,source($cal),win($nb)" \
	options=nocal,nopass
uvcat vis=all.nb out=$cal.nb.win$nb.00 "select=-auto,source($cal),win($nb)" \
	options=nocal,nopass  

# copy wideband passband determined from all-wideband mode to hybrid wideband
gpcopy vis=$cal.wide.0   out=$cal.hyb.win$wide.0 options=nocal,nopol
uvcat vis=$cal.hyb.win$wide.0  out=$cal.hyb.win$wide   options=nocal

# get the noise source data.  Use the noise source data obtained in all
# narrowband mode, and assume it also can be applied to hybrid narrowband

if ($sideband == "USB" || $sideband == "usb" ) then
  echo " **** PROCESSING USB"
  rm -r noise.lsb noise.usb
  @ lsbnb = $nb - 3
  uvcat vis=all.nb out=noise.lsb "select=-auto,source(NOISE),win($lsbnb)" \
        options=nocal,nopass
  uvcat vis=all.nb out=noise.usb "select=-auto,source(NOISE),win($nb)" \
        options=nocal,nopass
  set sdf = `uvio vis=noise.usb | grep sdf | grep DATA | awk '{print $5}'`
  set sfreq = `uvio vis=noise.usb | grep sfreq | grep DATA | awk '{if (NR==1) print $5}'`
  uvcal vis=noise.lsb out=noise.nb.win$nb.00 options=conjugate
  puthd in=noise.nb.win$nb.00/sfreq value=$sfreq type=d
  puthd in=noise.nb.win$nb.00/sdf value=$sdf type=d
else
  uvcat vis=all.nb out=noise.nb.win$nb.00 "select=-auto,source(NOISE),win($nb)" \
        options=nocal,nopass
endif

# For narrowband windows, first do a passband cal using noise source
mfcal vis=noise.nb.win$nb.00 refant=$refant
echo "**** Passband cal using noise source"
gpplt vis=noise.nb.win$nb.00 device=bpnoise.nb.win$nb.00.ps/ps options=bandpass yaxis=phase nxy=4,4 \
        yrange=-360,360
gv bpnoise.nb.win$nb.00.ps

# Copy noise passband to astronomical all-narrowband and hybrid narrowbands, 
# and apply
gpcopy vis=noise.nb.win$nb.00 out=$cal.nb.win$nb.00 options=nocal,nopol
gpcopy vis=noise.nb.win$nb.00 out=$cal.hyb.win$nb.00 options=nocal,nopol
uvcat vis=$cal.nb.win$nb.00 out=$cal.nb.win$nb.0 options=nocal
uvcat vis=$cal.hyb.win$nb.00 out=$cal.hyb.win$nb.0 options=nocal

# use smamfcal with 1st order polynomial to
# get passband on hybrid narrowband and copy to all narrowband
smamfcal vis=$cal.hyb.win$nb.0 interval=$calint refant=$refant edge=$edge options=opolyfit \
          polyfit=$order
echo "**** Hybrid narrowband passband on $cal.hyb.win$nb.0 "
gpplt vis=$cal.hyb.win$nb.0 options=bandpass yaxis=phase nxy=4,4 yrange=-360,360 \
    device=bp$cal.hyb.win$nb.0.ps/ps
gv bp$cal.hyb.win$nb.0.ps

# Copy narrowband passband from hybrid to all-narrowband mode
gpcopy vis=$cal.hyb.win$nb.0    out=$cal.nb.win$nb.0 options=nocal,nopol

#Check that all-narrowband passband is flat
rm -r test.pass
uvcat vis=$cal.nb.win$nb.0 out=test.pass
mfcal vis=test.pass refant=$refant
echo "**** Narrowband passband (should be flat!)  on $cal.hyb.win$nb.0 "
gpplt vis=test.pass options=bandpass yaxis=phase nxy=4,4 yrange=-180,180 \
      device=bptest.ps/ps
gvplt bptest.ps

# Apply astronomical narrowband passband to hybrid and all-narrowband
uvcat vis=$cal.hyb.win$nb.0    out=$cal.hyb.win$nb     options=nocal
uvcat vis=$cal.nb.win$nb.0    out=$cal.nb.win$nb     options=nocal

# Selfcal on hybrid wideband to remove temporal variations 
# prior to band offset calibration
selfcal vis=$cal.hyb.win$wide line=channel,$wideline \
     interval=$calint options=phase refant=$refant

# Copy selfcal solution over to narrow hybrid band and apply
copyhd in=$cal.hyb.win$wide out=$cal.hyb.win$nb items=gains,ngains,nsols,interval
uvcat vis=$cal.hyb.win$nb out=$cal.hyb.win$nb.a

# Selfcal on narrow band of hybrid to determine band offset
selfcal vis=$cal.hyb.win$nb.a line=channel,$narrowline \
    interval=9999 options=phase refant=$refant
echo "**** Band offset between hybrid-narrowband $cal.hyb.win$nb.a"
echo "****  and hybrid-wideband $cal.hyb.win$nb"
gplist vis=$cal.hyb.win$nb.a options=phase
# Also copy band offset to text file
gplist vis=$cal.hyb.win$nb.a options=phase >! mnband_offset.$cal.hybwin$nb.txt

# Test by applying to calibrator observed in all-narrowband mode
copyhd in=$cal.hyb.win$nb.a out=$cal.nb.win$nb items=gains,ngains,nsols,interval
uvcat vis=$cal.nb.win$nb out=$cal.nb.win$nb.a

# Remove antenna phase gain using super-wideband
rm -r $cal.wide.sw
uvcat vis=$cal.wide out=$cal.wide.sw select='win('$superwidewin')'
selfcal vis=$cal.wide.sw line=channel,$superwidechan \
    interval=9999 options=phase refant=$refant
# Copy super-wideband gain to narrowband and apply
copyhd in=$cal.wide.sw out=$cal.nb.win$nb.a items=gains,ngains,nsols,interval
uvcat vis=$cal.nb.win$nb.a out=$cal.nb.win$nb.a.sc

# Selfcal to check that phases are roughly zero
# to within amount expected given temporal variations over interval
# between superwideband and all-narrowband observerations
selfcal vis=$cal.nb.win$nb.a.sc line=channel,$narrowline \
     interval=9999 options=phase refant=$refant

# List gains, which should be near zero except for temporal variations
# over interval between wideband and narrow band observations of cal
echo "**** Phase offset between super-wideband $cal.wide.sw "
echo "**** and all-narrow narrow band $cal.nb.win$nb.a.sc "
echo "**** Check that phases are near zero, limited by atmospheric flucatuations"
gplist  vis=$cal.nb.win$nb.a.sc options=phase 

# Now apply calibrations to source data
rm -r  $source.win$nb* $source.win$nb.bcal
# First select source data
uvcat vis=all.nb out=$source.win$nb.00 \
   "select=-auto,source($source),win($nb)"  options=nocal,nopass
# Copy and apply noise passband to source
gpcopy vis=noise.nb.win$nb.00 out=$source.win$nb.00 options=nocal,nopol
uvcat vis=$source.win$nb.00 out=$source.win$nb.0 options=nocal
# Copy and apply astronomical passband
gpcopy vis=$cal.hyb.win$nb.0 out=$source.win$nb.0 options=nocal,nopol
uvcat vis=$source.win$nb.0 out=$source.win$nb options=nocal
# Copy band offset to source
copyhd in=$cal.hyb.win$nb.a out=$source.win$nb items=gains,ngains,nsols,interval
rm -r $source.win_$i
# Apply band offset using smachunkglue naming convention
uvcat vis=$source.win$nb out=$source.win_$i

# end nb loop
end

# glue together 3 bands
set cfile=$source.$nb_array[1]$nb_array[2]$nb_array[3]
rm -r $cfile
smachunkglue vis=$source.win nfiles=3 out=$cfile

# flag bad overlap channels
uvflag vis=$cfile line=channel,$badchan1 flagval=flag
uvflag vis=$cfile line=channel,$badchan2 flagval=flag

# put in restfreq
puthd in=$cfile/restfreq type=double value=$restfreq

# copy super-wideband gains to source
copyhd in=$viscal.v.wide.sw out=$cfile items=gains,ngains,nsols,interval

