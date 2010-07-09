#!/bin/csh -f

#
#   this is a special 'hardcoded' version of the STING ccalib.csh
#   script for a N4254 (M99) dataset which was used for the 2010
#   NRAO summerschool and used in a comparison study
#
# Runtime:
#   nemo:  519.483u 12.802s 10:11.97 86.9%
#   chara: 273.210u  5.238s  4:42.11 98.6%

#  1) the use of 'tail +5' in this script requires this on linux:
setenv _POSIX2_VERSION 1
#  2) region= error ?? i.e. no region specified
#  3) A BAD gv ngc4254.cmaps.ps near the end makes it use X


# -----------------------------------------------------------------------

#!/bin/csh -f
#
# ccalib.csh - CARMA STING calibration script (Tony Wong, UIUC)
#
# All parameters can be set on the command line:
#   ccalib.csh source= phasecal= refant= [device=] [refant=] [start=]
#
# This script is designed to be run interactively.
# For automode execution, set device=/null:
# e.g. ccalib.csh source=ngc4321 phasecal=3c273 device=/null refant=7
#
# Future improvements:
#   1. flag based on tracking errors
#   2. multi-window calibration
#
# History
#  2008may09: Support for hybrid mode and antpos file
#  2008may25: Hanning option
#  2008jun21: More flexible inputs for custom flagging
#  2008jul11: Revised abs calibration.  Src name in map plot filenames.
#  2008jul16: No mfboot plot in triple mode.
#  2008aug07: pcalwide variable (hybrid mode with source degeneracies)
#  2009mar01: mergesrc to deal with multiple targets to be imaged together
#  2009mar24: allow flagging using line keyword
#  2010mar24: flag based on tsys; report apriori flux value
#  2010apr18: winselect parameter
#--------------------------------------------------------------------------

set version=2010apr18
set log=ccalib.log

### INFORMATION ABOUT THIS TRACK (REQUIRED)
set file=           # several may be specified
set source=         # more than one allowed if mergesrc= keyword is given
set phasecals=      # more than one allowed
set testcal=        # only one allowed
set fluxcal=        # only one allowed
set passcal=        # only one allowed
set obsgrade=       # Observer's grade
set wide=4          # spectral window for phase calibration
set restfreq=       # rest frequencies, if not originally set
set apfile=         # antenna position file, if correction required

### CUSTOM FLAGGING
# Example: 
#     flagsrc=all,3C84
#     flagsel='ant(1)'+'time(10:00,11:00)'
# will flag ant(1) for all data and times 10:00-11:00 for 3C84.
set flagsrc=        # optional source(s) for extra flagging
set flagsel=        # optional selection(s) for extra flagging
set flaglin=all     # optional linetype specification, default is all channels

### USER PREFERENCES
set mergesrc=       # New source name into which all sources are merged
set device=/xs      # display device; "/null" for automode
set dolinecal=y     # Apply linelength calibration?
set hanning=n       # Hanning smooth the data?
set winselect=      # Window selection to be performed at start of reduction
set tsyslim=1000    # Flag data with Tsys larger than this
set bpedge=0        # Edge channels to drop during mfcal, use 0 for hybrid
set polyfit=0       # Order of polynomial fit to bandpass if >0
set edge=2          # Edge channels to flag on source & testcal
set refant=8        # Ref ant for selfcal (first available if unset)
set pcalint=6       # selfcal interval (mins) for phasecal
set pcalwide=0      # bwsel parameter for phasecals: use 468,468,468 for hybrid
set apriori=1       # initial gain solution based on cals.fluxes
set vfirst=         # velocity of first map in cube
set nmaps=24        # number of maps to generate
set delv=10         # channel spacing in km/s
set imsize=129      # for INVERT
set cell=2          # for INVERT
set rmsfacd=2       # default rmsfac for mossdi or clean
set xyreg=          # region for deconvolution (entire field if unset)
set exinvert=

### Optional flux calibration parameters (planet bootstrapping)
# interval to average ampgains over before applying to planet
set fluxavint=
# optional time range where cal has similar elev/Tsys to planet
set gainsel=
# Flux of primary fluxcal, if not a planet:
set fluxflux=

### AUTORUN VARIABLES: need only be set in automode; defaults in []
set smooth_int=     # Time interval to smooth linelengths [unset]
set zero_ants=      # Antennas to zero linelengths [unset]
set std_flag=y      # apply standard flagging? [y]
set do_deconv=n     # deconvolve maps? [n]
set flagredo=n      # Remake datasets after custom flagging? [n]

### LOCAL SETTINGS
alias date 'date "+%m/%d/%y %T %Z"'
alias xspause 'if ($device == "/xs") set tmpr=$<'



# these are the hardcoded parameters for N4254:
set    file=c0104I.8D_115NGC4254.2.miriad 
set    source=ngc4254 
set    phasecals=3c273 
set    testcal=3c274 
set    fluxcal=mars 
set    passcal=3c273 
set    obsgrade=B 
set    wide=4 
set    restfreq=115.2712 
set    edge=2 
set    refant=9 
set    pcalint=4 
set    apriori=1 
set    rmsfacd=3 
set    nmaps=28 
set    do_deconv=y 
set    hanning=y 
set    device=/xs
set    device=/null

### OVERRIDE ABOVE PARAMETERS IF GIVEN ON COMMAND LINE
foreach par ( $* )
   set check=`echo $par | awk -F= '{print NF}'`
   if ( "$check" >= 2 ) set $par
end

#============================================================================

# CHECK INPUTS

if ($file == "") then
    echo "### Fatal Error: file= must be specified"
    exit 1
endif
if ($source == "") then
    echo "### Fatal Error: source= must be specified"
    exit 1
endif
if ($phasecals == "") then
    echo "### Fatal Error: phasecals= must be specified"
    exit 1
endif
if ($fluxcal == "") echo "### Warning: keyword fluxcal not specified"
if ($obsgrade == "") echo "### Warning: keyword obsgrade not specified"

#============================================================================


# OPEN LOGFILE IF NEEDED
echo ""
if (-e $log && $device != "/null") then
    echo -n "$log exists.  Overwrite (o) or append (a) [default=a]? "
    set resp = $<
    if ($resp == "o") rm -f $log
    echo ""
endif

# BEGIN EXECUTION
goto continue
# MOVE 'continue:' around to where you want to work.
# Shouldn't be necessary in standard operation.
continue:

# MAIN MENU
if !($?start) then
  if ($device == "/null") then
    set start=1
  else
    echo "Where would you like to start?"
    echo "  1. Diagnostics, fix baseline/restfreq"
    echo "  2. Linelength calibration"
    echo "  3. Data flagging"
    echo "  4. Passband calibration"
    echo "  5. Phase vs. time calibration"
    echo "  6. Absolute flux calibration"
    echo "  7. Apply calibration to source data"
    echo "  8. Produce dirty maps"
    echo "  9. Display dirty maps"
    echo " 10. Deconvolution"
    echo " 11. Examine the test calibrator"
    echo " 12. Purge non-essential files (when done)"
    echo ""
    echo -n "? "
    set start = $<
  endif
endif
switch ($start)
    case 2: 
    goto dolinecal
    case 3: 
    goto doflag
    case 4: 
    goto dopass
    case 5: 
    goto docal
    case 6: 
    goto doflux
    case 7: 
    goto doapply
    case 8: 
    goto domaps
    case 9: 
    goto showmaps
    case 10: 
    goto doclean
    case 11:
    goto dotest
    case 12:
    goto dorm
endsw

#--------------------------------------------------------------------------
# 1. Diagnostics:
#--------------------------------------------------------------------------

# Generate the chronology of observations
listobs vis=$file log=listobs
cat listobs
set obsdate=`awk '/Chronology/ {print $5}' listobs`

# Choose a new reference antenna if default is unavailable
set reffound = 0
set beglin=`awk '/Sys Temps/ {print NR}' listobs`
@ beglin ++
set ants=`sed -n "${beglin}p" listobs | sed 's/\(.*[deg,mode]\)//'`
foreach ant ($ants)
    if ($refant == $ant) then
        set reffound = 1
    endif
end
if ($reffound == 0) then
    echo "*** WARNING: Requested reference antenna $refant not found"
    echo "*** WARNING: Using antenna $ants[1] instead"
    set refant = $ants[1]
endif

# Output some interesting information
if !(-e $log) then
    echo ""
    echo "ccalib.csh $version executed by $user on `date`" | tee $log
    echo "" | tee -a $log
    echo "Project: $file" | tee -a $log
    echo "Obs Date: $obsdate  Obs Grade: $obsgrade" | tee -a $log
    echo "" | tee -a $log
    echo "Source: $source  Phasecals: $phasecals  Testcal: $testcal" \
        | tee -a $log
    echo "Flux cal: $fluxcal   Passband cal: $passcal" | tee -a $log
    if ($fluxflux != "") echo "Flux of $fluxcal set to $fluxflux" | tee -a $log
    echo "" | tee -a $log
    echo "===============================================================" \
        >> $log
endif

# Get the elapsed project time, note this includes NOISE integrations
echo "" | tee -a $log
echo "------ diagnostics run on `date`" >> $log
set startlin=`awk '/hhmmss/ {print NR+1}' listobs`
set endlin=`wc listobs | awk '{print $1-1}'`
set starttime=`sed -n "${startlin}p" listobs | awk '{print $2}'`
set stoptime=`sed -n "${endlin}p" listobs | awk '{print $2}'`
set starthours=`echo $starttime | awk '{split ($1,h,""); print h[1] h[2]}'`
set startminutes=`echo $starttime | awk '{split ($1,h,""); print h[3] h[4]}'`
set stophours=`echo $stoptime | awk '{split ($1,h,""); print h[1] h[2]}'`
set stopminutes=`echo $stoptime | awk '{split ($1,h,""); print h[3] h[4]}'`
set addminutes=`sed -n "${endlin}p" listobs | awk '{print $4}'`
set starttime = `calc -f f6.3 "$starthours+$startminutes/60.0"`
set stoptime  = `calc -f f6.3 "$stophours+($stopminutes+$addminutes)/60.0"`
set stoptime  = `echo $starttime $stoptime | awk '{if ($1 > $2) print ($2 + 24); else print $2}'`
set totaltime = `calc -f f6.1 "$stoptime-$starttime"`
echo "Total project time $totaltime hrs from start to finish" | tee -a $log

# Fix the rest frequencies and/or baselines
rm -rf uvputhd.mir uvdata.mir
if ($restfreq != "" || $apfile != "") then
	set nfiles=`echo $file | awk -F, '{print NF}'`
    if ($restfreq != "") then
        if ($nfiles > 1) then
            set allfiles = `echo "$file" | sed 's/,/ /g'`
            set i = 1
		    foreach subfile ($allfiles)
			    rm -rf uvputhd.$i.mir
    		    uvputhd vis=$subfile out=uvputhd.$i.mir hdvar=restfreq varval=$restfreq
    		    set i = `expr $i + 1`
    	    end
		    if ($apfile != "") then
		        rm -rf uvputhd.*.mir_c
		        uvedit vis="uvputhd.*.mir" apfile=$apfile
                echo "Applied antenna position file $apfile" | tee -a $log
                uvcat vis="uvputhd.*.mir_c" out=uvdata.mir
		    else
           	    uvcat vis="uvputhd.*.mir" out=uvdata.mir
		    endif
        else  # nfiles=1
    	    uvputhd vis=$file out=uvputhd.mir hdvar=restfreq varval=$restfreq
		    if ($apfile != "") then
		        uvedit vis=uvputhd.mir apfile=$apfile out=uvdata.mir
                echo "Applied antenna position file $apfile" | tee -a $log
		    else
             	uvcat vis=uvputhd.mir out=uvdata.mir
		    endif
        endif
        echo "Entered restfreq(s) of $restfreq" | tee -a $log
    else  # antenna position correction only
        uvedit vis=$file apfile=$apfile out=uvdata.mir
        echo "Applied antenna position file $apfile" | tee -a $log
    endif
else  # no corrections needed
    uvcat vis=$file out=uvdata.mir
endif

# Window selection if requested
if ($winselect != '') then
    rm -rf uvdata.wins
    uvcat vis=uvdata.mir out=uvdata.wins select="win($winselect)" \
        options=nowide
    set wins=`echo "$winselect" | sed 's/,/ /g'`
    set nwide=$#wins
    rm -rf uvdata.mir
    uvwide vis=uvdata.wins out=uvdata.mir nwide=$nwide
    echo "Selected spectral windows $winselect" | tee -a $log
endif

# Hanning smooth if requested
if ($hanning == 'y') then
    rm -rf uvdata.hann
    uvcal vis=uvdata.mir options=hanning out=uvdata.hann
    rm -rf uvdata.mir
    mv uvdata.hann uvdata.mir
    echo "Applied hanning smoothing to all data" | tee -a $log
endif

# FREQUENCY SETUP
uvlist vis=uvdata.mir select="source($source),-auto" options=spectra \
	log=spectra.log
cat spectra.log
prthd in=uvdata.mir options=full log=tmp.prthd 
set beglin=`awk '/Bandwidth/ {print NR}' tmp.prthd`
@ beglin ++
set endlin=`awk '/J2000/ {print NR}' tmp.prthd`
set endlin=`expr $endlin - 3`
sed -n "$beglin,${endlin}p" tmp.prthd > tmp.corr2
set bandwsrc = `cat tmp.corr2 | awk '{printf "%5d", 1000*sqrt($3*$3)}'`
echo "Correlator setup:" | tee -a $log
cat tmp.corr2 | tee -a $log
echo "Using window $wide for calibration" | tee -a $log

# DETERMINE MEAN RMSPATH, TAU230
varplt vis=uvdata.mir yaxis=tau230 device=$device log=tau.log
if (-e tau.log) then
  set tauavg=`cat tau.log | tail +5 | awk '{s += $3} END {print s/NR}'`
  echo "Mean value of tau230 is $tauavg" | tee -a $log
  rm -f tau.log
endif
varplt vis=uvdata.mir yaxis=rmspath device=$device log=rmp.log
if (-e rmp.log) then
  set rmpavg=`cat rmp.log | tail +5 | awk '{s += $3} END {print s/NR}'`
  echo "Mean value of rmspath is $rmpavg" | tee -a $log
  rm -f rmp.log
endif
smavarplt vis=uvdata.mir yaxis=systemp nxy=5,3 device=tsys1.ps/cps 
if ($device != "/null") gv tsys1.ps &
smavarplt vis=uvdata.mir yaxis=systemp nxy=5,3 device=tsys2.ps/cps \
    yrange=0,1000
if ($device != "/null") gv tsys2.ps &

if ($device == "/null") then
    if ($dolinecal == 'y') then
        goto dolinecal
    else
        goto doflag
    endif
endif

# LOOK AT CALIBRATORS, UV COVERAGE
echo ""
echo "UV-coverage on source:"
uvplt vis=uvdata.mir select="source($source),-auto" axis=uc,vc \
    device=$device options=nobase,equal nxy=1
echo "Calibrator amps and phases:"
smauvplt vis=uvdata.mir select="source($phasecals),-auto" device=$device \
    line=wide,1,$wide axis=time,amp nxy=5,3 title=BL
xspause
smauvplt vis=uvdata.mir select="source($phasecals),-auto" device=$device \
    line=wide,1,$wide axis=time,phase nxy=5,3 yrange=-180,180 title=BL
xspause

# LOOK AT SOURCE SPECTRA
echo ""
echo "Uncalibrated source spectra:"
uvspec vis=uvdata.mir select="source($source),-auto" interval=1000 \
    nxy=3,3 device=$device 
xspause

echo ""
echo "GENERAL COMMENTS ON THIS TRACK (1 line only): "
set resp = "$<"
echo "COMMENT: $resp" >> $log

end_diag:
echo ""
echo -n "Continue with linecal [y]? "
set resp = $<
if ($resp != "n") then
    goto dolinecal
else
    goto end
endif

#--------------------------------------------------------------------------
# 2. Linelength calibration:
#--------------------------------------------------------------------------

dolinecal:

# GET AND EXAMINE LINELENGTHS:
linecal vis=uvdata.mir
gpplt vis=uvdata.mir yaxis=phase yrange=-180,180 options=wrap,dots \
    device=linecal.ps/ps nxy=3,5
if ($device != "/null") gv linecal.ps &

# LOG ENTRY:
echo "" | tee -a $log
echo "------ linecal run on `date`" >> $log
if ($device != "/null") then
    echo ""
    echo "ENTER COMMENTS FOR LOG (1 line only): "
    set resp = "$<"
    echo "COMMENT: $resp" >> $log
    echo ""
# PROMPT USER TO APPLY LL OR MAKE FURTHER CHANGES:
    echo -n "Apply these linelengths to the data [y]? "
    set resp = $<
    if ($resp != "n") goto end_lcal
else if ($smooth_int == "" && $zero_ants == "") then
    goto doflag
endif

# TIME SMOOTHING OF LINELENGTHS (OPTIONAL):
if ($device != "/null" && $smooth_int == "") then
    echo -n "Apply time smoothing to linelengths? [n] "
    set aresp = $<
    if ($aresp == "y") then
      echo -n "Enter time interval in minutes to use: "
      set smooth_int = "$<"
    endif
endif
if ($smooth_int != "") then
    gpaver vis=uvdata.mir interval=$smooth_int
    gpplt vis=uvdata.mir device=$device yaxis=ph nxy=3,5 yrange=-180,180 \
        options=wrap,dots
    echo "Smoothed linelengths over $smooth_int minute interval" | tee -a $log
    echo ""
endif

# NULLIFY BAD LINELENGTHS (OPTIONAL):
if ($device != "/null" && $zero_ants == "") then
    echo -n "Use gpedit to nullify bad gains? [n] "
    set bresp = $<
    if ($bresp == "y") then
      echo "Enter list of antennas (use commas to separate):"
      set zero_ants = "$<"
    endif
endif
if ($zero_ants != "") then
    gpedit vis=uvdata.mir select="ant($zero_ants)" options=replace
    echo "Zeroed phases for antennas $zero_ants" | tee -a $log
    echo ""
    gpplt vis=uvdata.mir device=$device yaxis=ph nxy=3,5 yrange=-180,180 \
        options=wrap,dots
endif

# APPLY THE CHANGES?
if ($device != "/null") then
    echo -n "Apply these linelengths to the data [y]? "
    set resp = $<
    if ($resp == "n") then
      echo "NO LINELENGTH CALIBRATION APPLIED." | tee -a $log
      delhd in=uvdata.mir/gains
      goto end_lcal
    endif
else
    goto doflag
endif

end_lcal:
echo ""
echo -n "Continue with data flagging [y]? "
set resp = $<
if ($resp != "n") then
    goto doflag
else
    goto end
endif

#--------------------------------------------------------------------------
# 3. Data flagging:
#--------------------------------------------------------------------------

doflag:

# STANDARD FLAGGING
echo "" | tee -a $log
echo "------ uvflag run on `date`" >> $log
if ($device != "/null") then
  echo -n "Flag shadowed and high Tsys data [y]? "
  set std_flag = $<
endif
if ($std_flag != "n") then 
  echo ""
  echo "Flagging shadowed data..."
  csflag vis=uvdata.mir carma=true
  echo "Shadowed data flagged with csflag." >> $log
  echo ""
  echo "Flagging high Tsys data..."
  uvflag vis=uvdata.mir tsys=$tsyslim flagval=f
  echo "High Tsys data flagged with uvflag." >> $log
endif

# CUSTOM FLAGGING SPECIFIED IN SCRIPT
set flagsrc=`echo "$flagsrc" | sed 's/,/ /g'`
set flagsel=`echo "$flagsel" | sed 's/+/ /g'`
set flaglin=`echo "$flaglin" | sed 's/+/ /g'`
set i = $#flagsrc
if ($i > 0) then
    if ($device != "/null") then
        echo ""
        echo -n "Apply custom flagging [y]? "
        set resp = $<
        if ($resp == "n") goto extract
    endif
else
    goto extract
endif
echo ""
echo "There are $i flag sources"
if ($#flagsrc > $#flagsel) then
    set j=$#flagsel
    while ($j < $i)
	    set flagsel = ($flagsel $flagsel[$j])
	    set j=`expr $j + 1`
    end
endif
if ($#flagsrc > $#flaglin) then
    set j=$#flaglin
    while ($j < $i)
	    set flaglin = ($flaglin $flaglin[$j])
	    set j=`expr $j + 1`
    end
endif
echo "Flag sources: $flagsrc"
echo "Flag selection: $flagsel"
echo "Line selection: $flaglin"
while ($i > 0)
    if ($flaglin[$i] == 'all') then
        set extra=
	else
	    set extra="line=$flaglin[$i]"
	endif
    if ($flagsrc[$i] == 'all') then
	    echo ""
	    echo "Flagging data for all srcs, select=$flagsel[$i] $extra" \
	        | tee -a $log
        uvflag vis=uvdata.mir select="$flagsel[$i]" flagval=f $extra
    else if ($flagsrc[$i] != "") then
	    echo ""
	    echo "Flagging data for $flagsrc[$i] select=$flagsel[$i] $extra" \
	        | tee -a $log
	    uvflag vis=uvdata.mir select="source($flagsrc[$i]),$flagsel[$i]" \
	        flagval=f $extra
    endif
    set i = `expr $i - 1`
end

extract:
# EXTRACT INDIVIDUAL SOURCE DATA
echo ""
if ($mergesrc != '') then
    echo "Extracting data for $source into file $mergesrc"
    rm -rf $mergesrc
    uvcat vis=uvdata.mir out=$mergesrc select="-auto,source($source)"
    set source=$mergesrc
else
    echo "Extracting data for $source"
    rm -rf $source
    uvcat vis=uvdata.mir out=$source select="-auto,source($source)"
endif
echo "Extracting data for $phasecals"
rm -rf phasecals
uvcat vis=uvdata.mir out=phasecals select="-auto,source($phasecals)"
if ($passcal != "") then
	echo "Extracting data for $passcal"
	rm -rf $passcal
	uvcat vis=uvdata.mir out=$passcal select="-auto,source($passcal)"
endif
if ($testcal != "") then
	echo "Extracting data for $testcal"
	rm -rf $testcal
	uvcat vis=uvdata.mir out=$testcal select="-auto,source($testcal)"
endif
if ($fluxcal != "") then
	echo "Extracting data for $fluxcal"
	rm -rf $fluxcal
	uvcat vis=uvdata.mir out=$fluxcal select="-auto,source($fluxcal)"
endif

# FLAG EDGE CHANNELS ON SOURCE AND TESTCAL (does not have the edge bug)
if ($edge != "") then
    uvflag vis=$source flagval=f edge=$edge
    echo "Flagged $edge edge channels on $source" >> $log
    if ($testcal != "") then
        uvflag vis=$testcal flagval=f edge=$edge
        echo "Flagged $edge edge channels on $testcal" >> $log
    endif
endif
echo ""

# Exclude hybrid data from phasecals set if necessary
if ($pcalwide != '0') then
    rm -rf phasecals.wid
    bwsel vis=phasecals out=phasecals.wid bw=$pcalwide
    rm -rf phasecals
    mv phasecals.wid phasecals
endif

# Remake the visibility sets if desired:
if ($flagredo == 'y') then
    foreach flgsrc ($source $fluxcal phasecals)
        uvcat vis=$flgsrc out=$flgsrc.tmp options=unflagged
        rm -rf $flgsrc
        mv $flgsrc.tmp $flgsrc
    end
endif

end_flag:
if ($passcal != "") then
    if ($device == "/null") goto dopass
    echo ""
    echo -n "Calibrate the passband [y]? "
    set resp = $<
    if ($resp != "n") then
        goto dopass
    else
        goto end
    endif
else
    if ($device == "/null") goto docal
    goto end_pass
endif

#--------------------------------------------------------------------------
# 4. Calibrate passband, if available.
#--------------------------------------------------------------------------

dopass:

if ($passcal == "") then
    echo "You must specify a passband calibrator in the script."
    goto end
endif

# INSPECT PHASE AND AMPLITUDE ACROSS PASSBAND:
if ($device != "/null") then
    echo "Plotting the amps and phases of the pb calibrator vs. chan..."
    uvspec vis=$passcal interval=600 device=$device nxy=5,3 axis=chan,amp
    xspause
    uvspec vis=$passcal interval=600 device=$device nxy=5,3 axis=chan,pha \
        yrange=-180,180
    xspause
    echo -n "Do you wish to calibrate the passband [y]? "
    set resp = $<
    if ($resp == "n") goto end
endif

# LOG ENTRY:
echo "" | tee -a $log
echo "------ passband cal using $passcal on `date`" >> $log
echo "Used antenna $refant as reference for selfcal." >> $log
echo "Edge channels to ignore in each window: $bpedge" >> $log

# CALIBRATE THE PASSBAND:
if ($polyfit != '0' && $polyfit != '') then
    smamfcal vis=$passcal refant=$refant interval=1 edge=$bpedge \
        options=opolyfit polyfit=$polyfit
else
    mfcal vis=$passcal refant=$refant interval=1 edge=$bpedge    
endif
smagpplt vis=$passcal options=bandpass,nofit device=bpamp.ps/cps xaxis=chan \
    yrange=0,2 nxy=3,5
if ($device != "/null") gv bpamp.ps &
smagpplt vis=$passcal options=bandpass,nofit,wrap device=bpph.ps/cps xaxis=chan \
    yaxis=phase yrange=-180,180 nxy=3,5
if ($device != "/null") gv bpph.ps &

# PROMPT USER ON WHETHER TO APPLY CALIBRATION:
if ($device != "/null") then
    echo ""
    echo "ENTER COMMENTS FOR LOG:"
    set resp = "$<"
    echo "COMMENT: $resp" >> $log
    echo ""
    echo -n "Do you wish to apply the passband calibration [y]? "
    set resp = $<
    if ($resp == "n") then
        echo "Passband calibration NOT applied to source." >> $log
        goto end
    endif
endif

# APPLY PASSBAND CALIBRATION TO ALL SOURCES
foreach obj ($source $testcal phasecals)
    if ($passcal != $obj) then
        gpcopy vis=$passcal out=$obj options=nocal
        echo "Passband gains copied to $obj" | tee -a $log
        uvlist vis=$obj options=var,full log=uvlist.tmp
        grep sdf uvlist.tmp > sdf1.tmp
        cut -c 10-80 sdf1.tmp | sed 's/[ ]/\n/g' | sed '/^$/d;s/^-//' | sort \
            | uniq > sdf2.tmp
        set delf=`awk '{printf "%4.2f,", $1*1e3}' sdf2.tmp | sed 's/,$//'`
#        set delf=`grep sdf uvlist.tmp | tail -1 | awk '{print 1e3*sqrt($3**2)}'`
        set nchan=`grep nchan uvlist.tmp | sed 's/.*nchan[ ]*://' | awk '{print $1}'`
        set npass=`gethd in=$obj/nchan0`
        echo "nchan for data, bandpass: $nchan $npass"
        if ($nchan < $npass) then
            bpsel vis=$obj fmhz=$delf tol=0.1
            echo "Selected gains with freq resolution $delf MHz" | tee -a $log
            echo ""
        endif
    endif
end

# APPLY THE PASSBAND GAINS TO THE PHASECAL SET:
#rm -rf phasecals.nw
#uvwide vis=phasecals out=phasecals.nw
rm -rf phasecals.pb
uvcat vis=phasecals out=phasecals.pb options=nocal
#uvcat vis=phasecals out=phasecals.pb options=nocal,unflagged
if ($device == "/null") goto docal

end_pass:
echo ""
echo -n "Continue with gains vs. time calibration [y]? "
set resp = $<
if ($resp != "n") then
    goto docal
else
    goto end
endif

#--------------------------------------------------------------------------
# 5. Phase calibration
#--------------------------------------------------------------------------

docal:

if ($passcal != "") then
	set phcalfile=phasecals.pb
else
	set phcalfile=phasecals
endif

# LOG ENTRY:
echo "" | tee -a $log
echo "------ phase cal using $phasecals run on `date`" >> $log
echo "Reference antenna: $refant" >> $log
echo "Solution interval: $pcalint min" >> $log

# SOLVE FOR GAINS:
if ($apriori == 1) then
    mselfcal vis=$phcalfile refant=$refant line=wide,1,$wide interval=$pcalint \
        options=amp,apriori,noscale | tee mselfcal.tmp
    set phflux=`grep CalGet mselfcal.tmp | sed 's/.*Flux=//'`
    echo "Using apriori flux of $phflux for $phasecals"  >> $log
else
    mselfcal vis=$phcalfile refant=$refant line=wide,1,$wide interval=$pcalint \
        options=amp
endif
puthd in=$phcalfile/senmodel value='GSV' type=ascii
gpplt vis=$phcalfile device=gainph.ps/ps yrange=-180,180 nxy=5,3 \
    yaxis=phase options=wrap
if ($device != "/null") gv gainph.ps &
gpplt vis=$phcalfile device=gainamp.ps/ps yrange=0,4 nxy=5,3
if ($device != "/null") gv gainamp.ps &
echo "Mean amplitude gains, window ${wide}:" | tee -a $log
gplist vis=$phcalfile | grep Means | sed 's/.*:[ ]*//g' | tee -a $log
echo "... these multiply the online values:" >> $log
uvlist vis=$phcalfile options=var,full | grep jyperka >> $log

# INSPECT PHASES ON CALIBRATOR:
uvplt vis=$phcalfile axis=time,phase nxy=5,3 line=wide,1,$wide \
    device=calphases.ps/ps options=2p,source yrange=-180,180 \
    size=1.8,4
if ($device != "/null") gv calphases.ps &
if ($device == "/null") goto end_cal
uvamp vis=$phcalfile device=$device line=wide,1,$wide bin=45,1,klam
xspause

## OPTIONAL: MAP CALIBRATOR AND CHECK ITS SIZE:
echo ""
echo -n "Map the calibrator [n]? "
set resp = $<
if ($resp == "y") then
    echo "Inverting the $phasecals[1] data..." | tee -a $log
    rm -rf phasecals.map phasecals.beam
    invert vis=$phcalfile map=phasecals.map beam=phasecals.beam \
        imsize=256 cell=1 sup=0 line=wide,1,$wide options=systemp \
        select="source($phasecals[1])"
    imfit in=phasecals.map region='arcsec,box(-15,-15,15,15)' \
        object=gaussian > imfit1.tmp
    set bmaj=`grep Major imfit1.tmp | awk '{print $4}'`
    set bmin=`grep Minor imfit1.tmp | awk '{print $4}'`
    echo "Gaussian fit to map : $bmaj arcsec x $bmin arcsec" | tee -a $log
    imfit in=phasecals.beam region='arcsec,box(-15,-15,15,15)' \
        object=gaussian > imfit2.tmp
    set bmaj=`grep Major imfit2.tmp | awk '{print $4}'`
    set bmin=`grep Minor imfit2.tmp | awk '{print $4}'`
    echo "Gaussian fit to beam: $bmaj arcsec x $bmin arcsec" | tee -a $log
    rm -rf phasecals.clean
    clean map=phasecals.map beam=phasecals.beam out=phasecals.clean 
    rm -rf phasecals.cm
    restor map=phasecals.map beam=phasecals.beam model=phasecals.clean \
        out=phasecals.cm
    cgdisp in=phasecals.cm,phasecals.cm  type=p,c nxy=1 device=$device  \
        labtyp=arcsec region='arcsec,box(-60,-60,60,60)' range=0,0,lin,3 \
    slev=p,10 levs1=1,2,3,4,5,6,7,8,9 options=full,beambl,wedge,mirr
    xspause
endif

end_cal:
echo ""
if ($fluxcal != "") then
    if ($device == "/null") goto doflux
    echo -n "Continue with flux calibration [y]? "
    set resp = $<
    if ($resp != "n") goto doflux
else
    if ($device == "/null") goto doapply
    echo -n "Apply the gains to the source data [y]? "
    set resp = $<
    if ($resp != "n") goto doapply
endif
goto end

#--------------------------------------------------------------------------
# 6. Absolute flux calibration
#--------------------------------------------------------------------------

doflux:

if ($fluxcal == "") then
    echo "No flux calibrator specified."
    goto end_flux
endif
if ($passcal != "") then
	set phcalfile=phasecals.pb
else
	set phcalfile=phasecals
endif

# COPY AMPLITUDE GAINS FROM PHASECAL TO FLUXCAL:
gpcopy vis=$phcalfile out=$fluxcal options=nopass
puthd in=$fluxcal/interval value=1.
if ($device != "/null") then
    uvplt vis=$fluxcal line=wide,1,$wide device=$device \
        axis=uvd,amp options=nobase
    xspause
endif
uvflux vis=$fluxcal line=wide,1,$wide

# --- Gain fiddling: select a time range where calibrator is 
# --- close to planet's elevation and average gains in time
if ($gainsel != "") then
    echo "Selecting only gains in time range $gainsel" | tee -a $log
    gpedit vis=$fluxcal select="-time($gainsel)" options=flag
endif
if ($fluxavint != "") then
    echo "Averaging gains over $fluxavint min" | tee -a $log
    gpaver vis=$fluxcal interval=$fluxavint options=scalar
endif

# BOOTSTRAP THE FLUXES:
echo "" | tee -a $log
echo "------ flux calibration run on `date`" >> $log
set flxsrc=`prthd in=$fluxcal | grep Object | awk '{print $2}'`
set obsdate=`awk '/Chronology/ {print $5}' listobs`
echo "The flux calibrator is $flxsrc" | tee -a $log
if ($flxsrc =~ {MERCURY,VENUS,MARS,JUPITER,SATURN,URANUS,NEPTUNE}) then
    mfboot vis=$fluxcal,$phcalfile select="source($flxsrc)" device=boot.ps/cps \
        line=wide,1,$wide clip=0.2 mode=scalar | tee tmp.mfboot
    if ($device != "/null") gv boot.ps &
else 
    if ($fluxflux == "") then
        calflux source=$flxsrc freq=115 date=$obsdate deldate=60 delfreq=60
        echo ""
        echo -n "Please enter a value for the flux of $flxsrc in Jy: "
        set fluxflux = $<
    endif
    mfboot vis=$fluxcal,$phcalfile select="source($flxsrc)" \
        line=wide,1,$wide flux=$fluxflux mode=triple | tee tmp.mfboot
endif
grep Scaling tmp.mfboot >> $log
uvflux vis=$fluxcal line=wide,1,$wide

# PLOT THE SELFCAL GAINS ON FLUXCAL ALONGSIDE THE ADOPTED GAINS:
rm -rf $fluxcal.sgains
selfcal vis=$fluxcal options=amp,apriori,noscale interval=$pcalint \
    line=wide,1,$wide out=$fluxcal.sgains
gpcopy vis=$phcalfile out=$fluxcal.sgains mode=merge
gpplt vis=$fluxcal.sgains yaxis=amp device=$fluxcal.sgains.ps/ps \
    nxy=3,3
if ($device != "/null") gv $fluxcal.sgains.ps &

if ($device == "/null") goto doapply

end_flux:
echo ""
echo -n "Apply the gains to the source data [y]? "
set resp = $<
if ($resp != "n") then
    goto doapply
else
    goto end
endif

#--------------------------------------------------------------------------
# 7. Transfer gains to source
#--------------------------------------------------------------------------

doapply:
if ($passcal != "") then
	set phcalfile=phasecals.pb
else
	set phcalfile=phasecals
endif

# APPLY GAINS TO SOURCE:
echo "" | tee -a $log
echo "------ created $source.cal on `date`" >> $log

rm -rf $source.cal
uvcat vis=$source out=$source.cal
gpcopy vis=$phcalfile out=$source.cal options=nopass
puthd in=$source.cal/interval value=0.1

if ($device == "/null") goto domaps

echo ""
echo -n "Continue with INVERT [y]? "
set resp = $<
if ($resp != "n") then
    goto domaps
else
    goto end
endif

#--------------------------------------------------------------------------
# 8. Produce dirty maps.
#--------------------------------------------------------------------------

domaps:

# LOG ENTRY
set usefile=$source.cal
echo " " | tee -a $log
echo "Inverting $usefile..."
echo "------ inverted $usefile on `date`" >> $log

# SET UP DATACUBE
rm -rf $source.map $source.beam
if ($vfirst == "") then
	set vcen=`uvlist vis=$source options=var | grep vsource | sed 's/.*vsource ://'`
	echo "The source velocity appears to be $vcen" | tee -a $log
	set vtmp = `calc -i "$vcen/$delv-($nmaps-1)/2"`
	set vfirst = `expr $vtmp \* $delv`
endif
echo "Making $nmaps maps beginning at $vfirst and spaced by $delv km/s" 

# MAP SOURCE WITH NATURAL WEIGHTING
invert vis=$usefile map=$source.map beam=$source.beam cell=$cell \
    imsize=$imsize line=velocity,$nmaps,$vfirst,$delv,$delv \
    options=systemp,double,mosaic slop=1 sup=0 $exinvert | tee tmp.invert

echo "Produced $nmaps maps beginning at $vfirst and spaced by $delv km/s" \
    >> $log
grep Theoretical tmp.invert >> $log
grep Number tmp.invert >> $log
set nptng=`grep Number tmp.invert | awk '{print $4}'`

# OUTPUT STATS:
set nmin1 = `expr $nmaps - 1`
echo "Dirty map, Channels 1-2, $nmin1-$nmaps, Mean:" | tee -a $log
set exec="histo in=$source.map"
set box="box(-60,-60,60,60)"
set crmsi=`$exec region="a,$box(1,2)" |grep Rms |awk '{print $4}'`
set crmsf=`$exec region="a,$box($nmin1,$nmaps)" |grep Rms |awk '{print $4}'`
set crms = `calc -f f7.5 "($crmsi+$crmsf)/2"`
echo "RMS in central 2 x 2 arcm: $crmsi $crmsf  Mean: $crms" | tee -a $log
set frmsi=`$exec region="image(1,2)" | grep Rms | awk '{print $4}'`
set frmsf=`$exec region="image($nmin1,$nmaps)" | grep Rms | awk '{print $4}'`
set frms = `calc -f f7.5 "($frmsi+$frmsf)/2"`
echo "RMS in entire field      : $frmsi $frmsf  Mean: $frms" | tee -a $log
echo " "

#--------------------------------------------------------------------------
# 9. Plot dirty maps.
#--------------------------------------------------------------------------

showmaps:

# Get the (flattened) noise level.
rm -rf $source.sen
mossen in=$source.map sen=$source.sen
rm -rf $source.norm
set minval=`histo in=$source.sen region='image(1)'|grep Min|awk '{print $3}'`
echo "Normalizing $source.sen by $minval"
maths exp="$source.map*$minval/$source.sen" out=$source.norm
set nmin1 = `expr $nmaps - 1`
set exec="histo in=$source.norm"
set box="box(-60,-60,60,60)"
set crmsi=`$exec region="a,$box(1,2)" |grep Rms |awk '{print $4}'`
set crmsf=`$exec region="a,$box($nmin1,$nmaps)"|grep Rms|awk '{print $4}'`
set crms = `calc -f f7.5 "($crmsi+$crmsf)/2"`

if ($device != "/null") then
    echo ""
    echo -n "Enter contour level for plot [default=sigma=$crms]: "
    set clev = $<
    if ($clev == "") set clev=$crms
    echo -n "Enter plot device type [default=/ps]: "
    set pdev = $<
    if ($pdev == "") set pdev=/ps
else 
    if !($?clev) set clev=$crms
    set pdev=/ps
endif

cgdisp in=$source.norm device=$pdev region=$xyreg \
        options=full,3value labtyp=arcsec nxy=4,3 type=contour \
        slev=a,$clev levs1=2,3,4,5,6,8,10,12,14 csize=0.6,0.8
if ($pdev == "/ps") then
    mv pgplot.ps $source.dmaps.ps
    if ($device != "/null") gv $source.dmaps.ps &
endif

if ($device != "/null") then
    if ($start != "8") then
    echo ""
    echo "ENTER COMMENTS FOR LOG (1 line only):"
    set resp = "$<"
    echo "COMMENT: $resp" >> $log
    endif
    echo ""
    echo -n "Continue with deconvolution [n]? "
    set resp = $<
    if ($resp == "y") then
        goto doclean
    else
        goto end
    endif
else if ($do_deconv != y) then
    ls -lt *.ps
    goto end
endif


#--------------------------------------------------------------------------
# 10. Deconvolve map, if desired.
#--------------------------------------------------------------------------

doclean:

if !($?nptng) then
    set nptng=`imlist in=$source.map options=mos|grep Number|awk '{print $5}'`
    echo "Map appears to consist of $nptng pointings"
endif

if !($?crms) then
    set nmin1 = `expr $nmaps - 1`
    set exec="histo in=$source.norm"
    set box="box(-60,-60,60,60)"
    set crmsi=`$exec region="a,$box(1,2)" |grep Rms |awk '{print $4}'`
    set crmsf=`$exec region="a,$box($nmin1,$nmaps)"|grep Rms|awk '{print $4}'`
    set crms = `calc -f f7.5 "($crmsi+$crmsf)/2"`
endif

# PROMPT FOR WHICH PLANES TO DECONVOLVE:
if ($device != "/null") then
    echo -n 'Enter planes to deconvolve as "(z1,z2)" [default=all]: '
    set planes="$<"
    if ($xyreg == "") set planes="images$planes"
else 
    set planes=
endif

# MOSSDI FOR MOSAICS:
if ($nptng > 1) then
    if ($device != "/null") then
        echo -n "Enter rmsfac for MOSSDI [default=$rmsfacd]: "
        set rmsfac = $<
        if ($rmsfac == "") set rmsfac=$rmsfacd
    else 
    set rmsfac=$rmsfacd
    endif
    echo " " | tee -a $log
    echo "------ deconvolved $source.map using mossdi2 on `date`" >> $log
    echo "Region: $xyreg$planes   Rmsfac: $rmsfac" >> $log
    rm -rf $source.sdi
    mossdi2 map=$source.map beam=$source.beam out=$source.sdi cutoff=$rmsfac \
        region="$xyreg$planes" niters=10000
    rm -rf $source.psf
    mospsf beam=$source.beam out=$source.psf
    imfit in=$source.psf object=beam region="a,box(-10,-10,10,10)" \
        | tee tmp.imfit
    if !($?fitmaj) then
        set fitmaj=`grep 'Major axis' tmp.imfit | sed 's/.*://' | awk '{print $1}'`
        set fitmin=`grep 'Minor axis' tmp.imfit | sed 's/.*://' | awk '{print $1}'`
        set fitpa=`grep 'Position angle' tmp.imfit | sed 's/.*://' | awk '{print $1}'`
    endif
    rm -rf $source.cm
    restor map=$source.map beam=$source.beam model=$source.sdi out=$source.cm \
        fwhm=$fitmaj,$fitmin pa=$fitpa
    rm -rf $source.res
    restor map=$source.map beam=$source.beam model=$source.sdi out=$source.res \
        fwhm=$fitmaj,$fitmin pa=$fitpa mode=residual
    if (-e $source.sen) then
        set minval=`histo in=$source.sen region='image(1)'|grep Min|awk '{print $3}'`
        rm -rf $source.cmnorm
        maths exp="$source.cm*$minval/$source.sen" out=$source.cmnorm
        rm -rf $source.resnorm
        maths exp="$source.res*$minval/$source.sen" out=$source.resnorm
    endif
    copyhd in=$source.cm out=$source.res items=bmaj,bmin,bpa
    set rflux=`histo in=$source.res region="a,box(-60,-60,60,60)" | grep Flux | awk '{print $6}'`
    set rintflux=`calc -f f8.2 "$rflux*$delv"`
    set cflux=`histo in=$source.sdi | grep Flux | awk '{print $6}'`
    set cintflux=`calc -f f8.2 "$cflux*$delv"`
    echo "Used restoring beam of $fitmaj x $fitmin arcsec, pa $fitpa" | tee -a $log
    echo "Flux of residuals in region: $rintflux Jy km/s" | tee -a $log
    echo "Flux of deconv. model in region: $cintflux Jy km/s" | tee -a $log

# OR CLEAN (SINGLE-POINTING):
else
    if ($device != "/null") then
        echo "Enter clean cutoff as multiple of sigma [default=$rmsfacd]:"
        set rmsfac=$<
        if ($rmsfac == "") set rmsfac=$rmsfacd
    else 
    set rmsfac=$rmsfacd
    endif
    set cutoff=`calc -f f7.5 "$rmsfac*$crms"`
    echo " " | tee -a $log
    echo "------ deconvolved $source.map using clean on `date`" >> $log
    echo "Region: $xyreg$planes   Cutoff: $cutoff" >> $log
    rm -rf $source.clean
    clean map=$source.map beam=$source.beam out=$source.clean \
        region="$xyreg$planes" niters=1000 cutoff=$cutoff
    rm -rf $source.cm
    restor map=$source.map beam=$source.beam model=$source.clean out=$source.cm
    rm -rf $source.res
    restor map=$source.map beam=$source.beam model=$source.clean \
        out=$source.res mode=residual
    copyhd in=$source.cm out=$source.res items=bmaj,bmin,bpa
    set rflux=`histo in=$source.res region="$xyreg$planes" | grep Flux | awk '{print $6}'`
    set rintflux=`calc -f f8.2 "$rflux*$delv"`
    set cflux=`histo in=$source.clean | grep Flux | awk '{print $6}'`
    set cintflux=`calc -f f8.2 "$cflux*$delv"`
    echo "Flux of residuals in region: $rintflux Jy km/s" | tee -a $log
    echo "Flux of deconv. model in region: $cintflux Jy km/s" | tee -a $log
endif

# DISPLAY RESULTS:
if ($device != "/null") then
    echo "Plotting residuals..."
    if (-e $source.resnorm) then
        cgdisp in=$source.resnorm device=$device region=$xyreg type=p csize=0,0.8 \
            nxy=4,3 options=full,3val labtyp=arcsec range=0,0,lin,3
    else
        cgdisp in=$source.res device=$device region=$xyreg type=p csize=0,0.8 \
            nxy=4,3 options=full,3val labtyp=arcsec range=0,0,lin,3
    endif
    xspause
    echo "Plotting deconvolved map..."
    echo ""
    echo -n "Enter contour level for plot [default=sigma=$crms]: "
    set clev = $<
    if ($clev == "") set clev=$crms
    echo -n "Enter plot device type [default=/ps]: "
    set pdev = $<
    if ($pdev == "") set pdev=/ps
else 
    if !($?clev) set clev=$crms
    set pdev=/ps
endif

if (-e $source.cmnorm) then
    cgdisp in=$source.cmnorm device=$pdev region=$xyreg type=c csize=0.6,0.8 nxy=4,3 \
        options=full,3val slev=a,$clev levs1=2,3,4,5,6,8,10,12,14 \
        labtyp=arcsec
else
    cgdisp in=$source.cm device=$pdev region=$xyreg type=c csize=0.6,0.8 nxy=4,3 \
        options=full,3val slev=a,$clev levs1=2,3,4,5,6,8,10,12,14 \
        labtyp=arcsec
endif
if ($pdev == "/ps") then
    mv pgplot.ps $source.cmaps.ps
    echo  BAD BAD gv $source.cmaps.ps
    gv $source.cmaps.ps &
endif

echo ""
if ($testcal != "") then
    if ($device == "/null") goto dotest
    echo -n "Examine the test calibrator [y]? "
    set resp = $<
    if ($resp != "n") goto dotest
else
    goto end
endif
goto end

# Use moment.csh to make moment maps.

#--------------------------------------------------------------------------
# 11. Examine the test calibrator
#--------------------------------------------------------------------------

dotest:
if ($testcal == "") then
    echo 'You must specify a test calibrator!'
    goto end
endif

if ($passcal != "") then
	set phcalfile=phasecals.pb
else
	set phcalfile=phasecals
endif

# APPLY GAIN SOLUTIONS TO TESTCAL:
echo ""
echo "Copying the gains from phasecals to $testcal"
gpcopy vis=$phcalfile out=$testcal options=nopass
puthd in=$testcal/interval value=0.1
uvamp vis=$testcal device=$device line=wide,1,$wide
if ($device == "/xs") then
    set tmpr=$<
endif
uvspec vis=$testcal device=$testcal.ph.ps/ps axis=chan,phase line=chan \
    yrange=-180,180 interval=1000 nxy=5,3
if ($device != "/null") gv $testcal.ph.ps &

# IMAGE TEST CALIBRATOR:
rm -rf $testcal.map $testcal.beam
invert vis=$testcal map=$testcal.map cell=1 imsize=256 \
    beam=$testcal.beam robust=0.5 line=wide,1,$wide options=systemp
rm -rf $testcal.clean
clean map=$testcal.map beam=$testcal.beam out=$testcal.clean
rm -rf $testcal.cm
restor map=$testcal.map beam=$testcal.beam model=$testcal.clean \
    out=$testcal.cm
cgdisp in=$testcal.cm type=pixel nxy=1 device=$device labtyp=arcsec \
    options=full,beambl,wedge region='a,box(-30,-30,30,30)' \
    range=0,0,lin,3 

# FIT FOR POSITION OF POINT SOURCE:
echo "" | tee -a $log
echo "------ imaged test calibrator $testcal on `date`" >> $log
imfit in=$testcal.cm 'region=a,box(-15,-15,15,15)' object=gauss > tmp.imfit
set bmaj=`grep 'Beam Major' tmp.imfit | sed 's/.*://' | awk '{print $1}'`
set bmin=`grep 'Beam Major' tmp.imfit | sed 's/.*://' | awk '{print $2}'`
set fitmaj=`grep 'Major axis' tmp.imfit | sed 's/.*://' | awk '{print $1}'`
set fitmin=`grep 'Minor axis' tmp.imfit | sed 's/.*://' | awk '{print $1}'`
set offx=`grep 'Offset Pos' tmp.imfit | sed 's/.*://' | awk '{print $1}'`
set offy=`grep 'Offset Pos' tmp.imfit | sed 's/.*://' | awk '{print $2}'`
grep Total tmp.imfit | sed 's/^[ ]*//' | tee -a $log
echo "Beam   major, minor axes (arcsec): $bmaj, $bmin" | tee -a $log
echo "Fitted major, minor axes (arcsec): $fitmaj, $fitmin" | tee -a $log
echo "Offset from phase center (arcsec): $offx, $offy" | tee -a $log
goto end

#--------------------------------------------------------------------------
# 12. When satisfied, clean up files.
#--------------------------------------------------------------------------

dorm:
set echo

# initial fixes:
rm -rf uvdata.mir uvputhd.mir uvdata.wins
rm -rf uvputhd.*.mir*

# gain calibration / mapping calibrator:
rm -rf phasecals
rm -rf phasecals.map phasecals.beam phasecals.clean phasecals.cm

# mapping/deconvolution:
rm -rf $source.res $source.norm $source.sen $source.psf

# test calibrator:
rm -rf $testcal.map $testcal.beam $testcal.clean

# compress files:
gzip -f *.ps
unset echo

end:
echo "Output to $log"
rm -f tmp.* *.tmp

