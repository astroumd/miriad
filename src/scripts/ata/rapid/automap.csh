#! /usr/bin/tcsh -f
#
# $Id$
#
# A simple mapping routine that has a bunch of cool features to it...

# Begin variable preset, determine what variables to populate

set vis
set skip = "inter"
set lflux
set uflux
set autocmd
set sflag
set uselect

if ($#argv == 0) then
echo "AUTOMAP: No input files detected!"
exit 0
endif

varassign:


if ("$argv[1]" =~ vis*) then
    set vis = `echo $argv[1] | tr '=' ' ' | awk '{print $2}'`
    shift argv; if ("$argv" == "") set argv = "finish"
else if ("$argv[1]" =~ mode*) then
    if ("$argv[1]" =~ *auto*) set skip = auto
    if ("$argv[1]" =~ *inter*) set skip = inter
    if ("$argv[1]" =~ *skip*) set skip = skip
    shift argv; if ("$argv" == "") set argv = "finish"
else if ("$argv[1]" =~ amplim*) then
    set lflux = `echo "$argv[1]" | tr '=,' ' ' | awk '{print $2}'`
    set uflux = `echo "$argv[1]" | tr '=,' ' ' | awk '{print $3}'`
    set sflag = `echo "$argv[1]" | tr '=,' ' ' | awk '{print $4}'`

    if ($sflag == "") set sflag = 10000
    if ($lflux == "") set lflux = 0
    if ($uflux == "") set uflux = 5000
    shift argv; if ("$argv" == "") set argv = "finish"
else if ("$argv[1]" =~ autocmd*) then
    set autocmd = `echo "$argv[1]" | tr '=' ' '`
    shift argv; if ("$argv" == "") set argv = "finish"
else if ("$argv" =~ select*) then
    set uselect = `echo "$argv[1]" | tr '=' ' ' | awk '{print $2}'`
    shift argv; if ("$argv" == "") set argv = "finish"
else
    echo "$argv[1] not recognized!"
    exit 0
endif

if ($vis != "") then
echo "Beginning..."
else if (! -e $vis) then
echo "Vis file needed!"
exit 0
endif
##################################################################

set badcal # Debugging var to tell what happened if auto-selfcal fails
set psci = 0 # Phase auto-selfcal iterations
set asci = 0 # Amp auto-selfcal iterations
set flct = 0 # Count of how many spectra were flagged during autoflagging
set freq = `uvlist vis=$vis options=var | grep freq | awk '{print 1000*$3}'` # Set the freq in MHz
set levs1 = "levs1=15,30,45" #Levels for contour plot
if ($autocmd == "noscale") set levs1 = "levs1=15,30,45,60,75"
if ($autocmd == "noamps") set levs1 = "levs1=15,30,45,60,75"  
set fidx = 0 # Index marker
set sidx = 0 # Index marker
set iopt = 'options=mfs,double' # Options for invert step
set arc = `echo 4500 | awk '{print $1*1430/freq}' freq=$freq`# fov of displayed plot in arcsec
onintr enderr # Error trapping
set object = $vis # Name switch, to be removed later...
rm -f amplog mixolay; touch amplog # HD dump for recording bad spectra
echo "Imaging report for $vis" > $vis.imgrpt #Reporting tools
set refant = 0
set noflct = `uvplt vis=$vis device=/null options=2pass,nobase | grep Plot | awk '{print $2}'`
set int=10		# selfcal interval (min)
set scopt=pha		# option = pha or amp (phase+amp)
set sup=0		# natural = 0 (high sensitivity - bigger beam)
set imsize=512		# number of cells in image
set cell = `echo 30 | awk '{print $1*1430/freq}' freq=$freq` # cell size in arcsec orig 30
set map=cm		# plot the cleaned map (source.cm)
set scint=$int		# selfcal interval 
set clip=0.05		# clip out negative amplitudes 
set olay = olay # Define the overlay
set oldrange = 0 # Measure of dynamic range for auto-selfcal
set cleanlim = 2500

if (! -e olay) then
    echo "star arcmin arcmin star no 0 0 20 20 0 0" > olay
    endif

set sel="-shadow(7.5),$uselect" # Specify what should be imaged

uvaver vis=$object out=tempmap options=nocal,nopol,nopass select="$sel"
gpcopy vis=$object out=tempmap

# grid and transform visibilities into brightness map
invert:

if ($scopt == tamp) set scopt = amp 
	
foreach type (map beam clean cm rs)
   if (-e $object.$type)  rm -r $object.$type
end
invert vis=$vis map=$object.map beam=$object.beam cell=$cell \
	imsize=$imsize sup=$sup select=$sel $iopt
if ($skip == "inter") then
    echo "Number of clean iterations? (default $cleanlim iterations)"
    set uinput = $<
    if (`echo $uinput | awk '{if ($1*1 > 0) print "go"}'` == "go") set cleanlim = $uinput # Make sure that the input in a number greater than zero
else
set cleanlim = 2500
endif

clean map=$object.map beam=$object.beam out=$object.clean niters=$cleanlim
restor map=$object.map beam=$object.beam model=$object.clean out=$object.cm
restor map=$object.map beam=$object.beam model=$object.clean out=$object.rs \
    mode=residual

rm -f sfind.log
sfind in=$object.cm options=oldsfind,auto rmsbox=100 xrms=4 labtyp=arcsec

grep -v "#" sfind.log | tr ":" " " | awk '{if ($11 < 3000) print "star hms dms","sfind"NR,"no",$1,$2,$3,$4,$5,$6,$11,$11; else print "star hms dms","sfind"NR,"no",$1,$2,$3,$4,$5,$6,3000,3000}' > sfindolay # Build an overlay of detected sources

# Find some stats about the map...
set peak = `less sfind.log | grep : | sort -rnk7 | head -n 1 | awk '{print $7}'`
set rmsrange = `imstat in=$object.rs region=relcenter,arcsec,box"($arc,$arc,-$arc,-$arc)" | grep E- | awk '{print $5}'`
set rmsnoise = `echo $rmsrange | awk '{print $1}'`
set range = `echo $peak $rmsnoise | awk '{print .001*$1/$2}'`

if ($skip == "auto") goto auto # Skip display during the auto cycle

plot:			# display map

cat olay sfindolay > mixolay

echo "Writing PS document"
cgdisp slev=p,1 in=$object.$map,$object.$map \
   region=relcenter,arcsec,box"($arc,-$arc,-$arc,$arc)" device=$vis.ps/cps \
   labtyp=arcmin options=beambl,wedge,3value,mirr,full csize=0.6,1 olay=mixolay \
   type=contour,pix slev=p,1 $levs1 \
   range=0,0,lin,2 #device=$object.ps/cps

echo "Displaying Results"
cgdisp slev=p,1 in=$object.$map,$object.$map \
   device=$contplt region=relcenter,arcsec,box"($arc,-$arc,-$arc,$arc)" \
   labtyp=arcmin options=beambl,wedge,3value,mirr,full csize=0.6,1 olay=mixolay \
   type=contour,pix slev=p,1 $levs1 range=0,0,lin,2 #device=$object.ps/cps 

set orc = `echo 1000 $freq | awk '{print int($1*1430/$2}'`
imfit in=$object.$map region=relcenter,arcsec,box"($orc,$orc,-$orc,-$orc)" object=point

echo "RMS noise is $rmsnoise[1] - dynamic range is $range"
if ($skip == "skip") set oldrange = $range
if ($skip == "skip") goto finish
if ($skip == "auto") goto finish

imcomp:

echo "Imaging complete. Would you like to (s)elfcal, (f)lag or e(x)it?"
set yn = $<
if ($yn == "s") goto selfcal
if ($yn == "f") goto postflag
if ($yn == "x") goto finish
echo "$yn is not a recognized selection"
goto imcomp 

selfcal:		# selfcal - in the true selfcal the imaged data

set clip = `echo 10 $rmsnoise[1] | awk '{print $1*$2}'`
  echo "Selfcal interval [default=$scint]: "; set ans=$<
  if ($ans != "") set scint = $ans
  echo "amp or pha? [default=$scopt]: "; set cl=$<
  if ($cl != "") set scopt = $cl
  echo "Clip level? [default=$clip]: "; set ans=$<
  if ($ans != "") set clip = $clip

  selfcal vis=$vis model=$object.clean interval=$scint select=$sel \
	minants=4 options=noscale,mfs,$scopt clip=$clip refant=$refant
  goto invert


postflag:
set blopt = "options=nobase" 
echo "Review baselines one-by-one? (y)es |n|o"
set $yn = $< ; if ($yn == "y") set blopt
echo "Plotting all baseline by uv distance and amp."
blflag vis=$vis device=/xs $blopt select='-auto' axis=uvd,amp
echo "Plotting all baseline by time and amp."
blflag vis=$vis device=/xs $blopt select='-auto' axis=time,amp
echo "Review phases? (y)es |n|o"
set $yn = $<
if ($yn == "y") then
echo "Plotting all baselines by uv distance and phase."
blflag vis=$vis device=/xs options=nobase select='-auto' axis=uvd,pha
echo "Plotting all baselines by time and phase."
blflag vis=$vis device=/xs options=nobase select='-auto' axis=time,pha
endif

goto invert

auto:
if ($autocmd == "noflag") goto autocal

autoflag:
if ($sidx == 2) then
if (`echo $oldrange $range | awk '{if (($2/$1) <= 1.025) print "stop"}'` == stop) goto autocal
endif

echo "Beginning automated amp flagging"
# Check to see if there are any spectra with amplitudes outside of nominal range
if ($sflag != "") then
set asel = "amp($sflag)"
uvflag vis=$vis select=$asel options=none flagval=f
endif

set fidx = 0
uvaver vis=$vis out=$vis.temp options=relax
uvlist vis=$vis.temp options=stat recnum=0 | grep -v CHAN | grep ":" | grep -v "e" | awk '{if ($7>uflux) print $1}' uflux=$uflux | awk '{print "R",NR,$1}' > hamps
uvlist vis=$vis.temp options=stat recnum=0 | grep -v CHAN | grep ":" | grep -v "e" | awk '{if ($7<lflux) print $1}' lflux=$lflux | awk '{print "R",NR,$1}' > lamps
cat hamps lamps > amps
# Check hi and low amps seperately, MIRIAD can only handle so many records flags at once
rm -r $vis.temp
if (`cat amps| wc -w` == 0) echo "No flagging neccessary"
if (`cat amps| wc -w` == 0) goto autocal
cat amps >> amplog
set llim=0
set ulim=51
set lim = `cat amps | wc -l`
echo "$lim amp records to flag."
set flct = `echo $flct $lim | awk '{print $1+$2}'`
    while ($fidx == 0)
    set flags = `awk '{if ($2>llim) print $0}' llim=$llim amps | awk '{if ($2<ulim) printf "%s","vis("$3"),"}' ulim=$ulim`
    uvflag vis=$vis flagval=f options=none select=$flags
    if (`grep "R $ulim " amps | wc -l ` == 0) set fidx = 2
    set llim = `calc -i 50+$llim`
    set ulim = `calc -i 50+$ulim`
    end

autocal:
if ($autocmd == "nocal") set skip='skip'
if ($autocmd == "nocal") goto invert
echo $range $oldrange $sidx
if ($scopt == "pha") @ psci++
if ($scopt == "amp") @ asci++
set clip = `echo 5 $rmsnoise[1] | awk '{print $1*$2}'`
# If the dynamic range is moving on up, let it ride...
if (`echo $range $oldrange | awk '{if ($1 > 1.025*$2) print "go"}'` == go) then
gpcopy vis=$object out=tempmap
set sidx = 0
  selfcal vis=$vis model=$object.clean interval=$scint select=$sel \
	minants=4 options=noscale,mfs,$scopt clip=$clip refant=$refant
set oldrange = $range
goto invert
endif
# Check to see if the dynamic range is not increasing
if (`echo $oldrange $range | awk '{if ((($2/$1)-.975)^2 <= .0025) print "stop"}'` == stop) then
    if ($autocmd == noamps) goto plot
    if ($scopt == amp) set scopt = tamp 
    if (`echo $scopt$fidx` == "tamp2") goto invert
set oldrange = $range
    if (`echo $scopt$fidx` == "tamp0") echo "Maximum range reached."
    if (`echo $scopt$fidx` == "tamp0") set skip = "skip"
    if (`echo $scopt$fidx` == "tamp0") goto invert
    set scopt = amp
    echo
gpcopy vis=$object out=tempmap
    set sidx = 0
  selfcal vis=$vis model=$object.clean interval=$scint select=$sel \
	minants=4 options=noscale,$scopt clip=$clip refant=$refant \
goto invert
endif
@ sidx++
if ($sidx < 2) then 
  selfcal vis=$vis model=$object.clean interval=$scint select=$sel \
	minants=4 options=noscale,$scopt clip=$clip refant=$refant
goto invert
endif
# If the dynamic range does not improve over three cycles, soft failsafe mode will copy the last known good gains and will make a final map
echo "Auto-selfcal has failed. Run automap in manual mode or rerun under different parameters."
if ($scopt == "pha") set badcal = pha
if ($scopt == "amp") set badcal = amp

gpcopy vis=tempmap out=$object

set skip = "skip"
goto invert

enderr: # Hard failsafe mode will copy the last known good gains back and not invert data
echo "Failsafe initiated"
gpcopy vis=tempmap out=$object
rm -rf tempmap
finish:

# Below this is all reporting code, nothing terribly interesting...
echo "The following parameters were used for this auto-mapping iteration:" >> $vis.imgrpt

if ($autocmd == "noflag") echo "Automap was instructed not to flag on amplitudes" >> $vis.imgrpt
if ($autocmd != "noflag")echo "Amplitudes below $lflux and above $uflux were flagged" >> $vis.imgrpt
echo "---------------------------------------" >> $vis.imgrpt
echo "$flct out of $noflct spectra were flagged with amplitudes outside the selected range" >> $vis.imgrpt
echo "$psci phase self-cal iterations and $asci amp self-cal interations were attempted" >> $vis.imgrpt
if ($badcal == pha) then
echo "No self-cal solution was reached." >> $vis.imgrpt
else if ($badcal == amp) then
echo "A phase self-cal solution was reached." >> $vis.imgrpt
echo "No amplitude self-cal solution was reached." >> $vis.imgrpt
else if ($asci != 0) then
echo "Phase and amplitude self-cal solutions were successfully reached."  >> $vis.imgrpt
endif
echo "Dynamic range for this field is $oldrange, with an RMS residual noise of $rmsnoise[1] Jy." >> $vis.imgrpt
echo "Below is the ImFit report assuming a point source model near the center of the field" >> $vis.imgrpt
echo " " >> $vis.imgrpt
imfit in=$object.cm region=relcenter,arcsec,box"($orc,$orc,-$orc,-$orc)" object=point >> $vis.imgrpt
echo " " >> $vis.imgrpt
echo "Below is the ImStat report for the area within the primary beam." >> $vis.imgrpt
echo " " >> $vis.imgrpt
imstat in=$object.cm region=relcen,arcsec,box"(-4500,-4500,4500,4500)" >> $vis.imgrpt
echo "---------------------------------------------------------">> $vis.imgrpt
echo "Imaging report now available under $vis.imgrpt"
#rm -r *.beam *.clean *.map
rm -rf tempmap
exit 0
