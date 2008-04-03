#! /usr/bin/tcsh -f
# simple mapping script 			september 06 - jrf
# example
#
# $Id$
#

if ($#argv < 1) then
    echo 'Enter vis'
    set vcp = ($<)
    set vis = $vcp[1]
else
    set vis = $1
    set skip = $2
    set lflux = $3
    set uflux = $4
    set autocmd = $5
endif
set sfx = "_1430"
set contplt = /xs
set badcal
set psci = 0
set asci = 0
set flct = 0

set levs1 = "levs1=2,8,32"
if ($autocmd == "noscale") set levs1 = "levs1=15,30,45,60,75"
if ($autocmd == "noamps") set levs1 = "levs1=15,30,45,60,75"  

set fidx = 0
set sidx = 0
set iopt = 'options=mfs'
set arc = 4000		# fov of displayed plot in arcsec
if (`echo $uflux | wc -w` == 0) set uflux = 500 
if (`echo $lflux | wc -w` == 0) set lflux = 0 
onintr enderr
set object = $vis
rm -f amplog; touch amplog
echo "Imaging report for $vis" > $vis.imgrpt

set refant = 0

set noflct = `uvplt vis=$vis device=/null options=2pass,nobase | grep Plot | awk '{print $2}'`

# give one argument to start =  ave, flag, cal, invert, plot, selfcal
#
#
set int=10		# selfcal inel is a point source at the observing centerReadterval (min)
set scopt=pha		# option = pha or amp (phase+amp)
set sup=0		# natural = 0 (high sensitivity - bigger beam)
set cline=chan,2,100,400,24	# cont line - channel range for phase calibration
set line=$cline	# extract line - channels to keep from source dataset
set mline=chan,1,1,2	# map line - 60-90 covers HI line in m31

set imsize=512		# number of cells in image
set cell=30		# cell size in arcsec orig 30
set map=cm		# plot the cleaned map (source.cm)
set scint=$int		# selfcal interval 
set clip=0.05		# clip out negative amplitudes 
set olay = olay
set oldrange = 0
#set olay = ~/bin/olay	# cross to overlay for center of field
#set olay = ~/bin/nvss_blank18.olay

alias hit 'echo Hit return to continue; set yn = $<'

    set sel="-shadow(7.5)"
uvaver vis=$object out=tempmap options=nocal,nopol,nopass
gpcopy vis=$object out=tempmap
# grid and transform visibilities into brightness map
invert:

if ($scopt == tamp) set scopt = amp 
	
foreach type (map beam clean cm rs)
   if (-e $object.$type)  rm -r $object.$type
end
invert vis=$vis map=$object.map beam=$object.beam cell=$cell \
	imsize=$imsize sup=$sup select=$sel $iopt
clean map=$object.map beam=$object.beam out=$object.clean 
restor map=$object.map beam=$object.beam model=$object.clean out=$object.cm \
    #fwhm=100
restor map=$object.map beam=$object.beam model=$object.clean out=$object.rs \
    mode=residual #fwhm=100

rm -f sfind.log
sfind in=$object.cm options=oldsfind,auto rmsbox=100 xrms=4 labtyp=arcsec
set peak = `less sfind.log | grep : | sort -rnk7 | head -n 1 | awk '{print $7}'`
set rmsrange = `imstat in=$object.rs region=relcenter,arcsec,box"($arc,$arc,-$arc,-$arc)" | grep E- | awk '{print $5}'`
set rmsnoise = `echo $rmsrange | awk '{print $1}'`
set range = `echo $peak $rmsnoise | awk '{print .001*$1/$2}'`
#set range = `imfit in=$object.$map region=relcenter,arcsec,box"($arc,$arc,-$arc,-$arc)" object=point | grep Peak | awk '{print $3/rmsnoise}' rmsnoise=$rmsnoise`

#if ($autocmd == "noscale") set range = `imfit in=$object.$map region=relcenter,arcsec,box"(1800,300,2400,-900)" object=point | grep Peak | awk '{print $3/rmsnoise}' rmsnoise=$rmsnoise`

#echo "Displaying Results"
#cgdisp slev=p,1 in=$object.$map,$object.$map \
#   device=$contplt region=relcenter,arcsec,box"(4500,-4500,-4500,4500)" \
#   labtyp=arcmin options=beambl,wedge,3value,mirr,full csize=0.6,1 olay=$olay \
#   type=contour,pix slev=p,1 $levs1\
#    range=0,0,lin,2 #device=$object.ps/cps 


if ($skip == "auto") goto auto

plot:			# display map
echo "Writing PS document"
cgdisp slev=p,1 in=$object.$map,$object.$map \
   region=relcenter,arcsec,box"(4500,-4500,-4500,4500)" device=$vis.ps/cps \
   labtyp=arcmin options=beambl,wedge,3value,mirr,full csize=0.6,1 olay=$olay \
   type=contour,pix slev=p,1 $levs1 \
   range=0,0,lin,2 #device=$object.ps/cps

echo "Displaying Results"
cgdisp slev=p,1 in=$object.$map,$object.$map \
   device=$contplt region=relcenter,arcsec,box"(4500,-4500,-4500,4500)" \
   labtyp=arcmin options=beambl,wedge,3value,mirr,full csize=0.6,1 olay=$olay \
   type=contour,pix slev=p,1 $levs1\
    range=0,0,lin,2 #device=$object.ps/cps 

set orc = 1000
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

selfcal:		# selfcal (in the true semacs ~/bin/calcal.csh &ense) the imaged data
#if ($yn == y) then
set clip = `echo 10 $rmsnoise[1] | awk '{print $1*$2}'`
  echo "Selfcal interval [default=$scint]: "; set ans=$<
  if ($ans != "") set scint = $ans
  echo "amp or pha? [default=$scopt]: "; set cl=$<
  if ($cl != "") set scopt = $cl
  echo "Clip level? [default=$clip]: "; set ans=$<
  if ($ans != "") set clip = $clip

  selfcal vis=$vis model=$object.clean interval=$scint select=$sel \
	minants=4 options=noscale,$scopt clip=$clip refant=$refant \
	line=chan,1,1,824
#refant=$refant \
  #gpplt vis=$vis device=/xw yaxis=pha nxy=2,4; echo "show amp? [n]"
  #if ($< == y)  gpplt vis=$vis device=/xw nxy=2,4
  goto invert
#endif

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

echo "Beginning automated amp flagging"
set fidx = 0
uvaver vis=$vis out=$vis.temp options=relax
uvlist vis=$vis.temp options=stat recnum=0 | grep -v CHAN | grep ":" | grep -v "e" | awk '{if ($7>uflux) print $1}' uflux=$uflux | awk '{print "R",NR,$1}' > hamps
uvlist vis=$vis.temp options=stat recnum=0 | grep -v CHAN | grep ":" | grep -v "e" | awk '{if ($7<lflux) print $1}' lflux=$lflux | awk '{print "R",NR,$1}' > lamps
cat hamps lamps > amps

rm -r $vis.temp
if (`cat amps| wc -w` == 0) echo "No flagging neccessary"
if (`cat amps| wc -w` == 0) goto autocal
cat amps >> amplog
set llim=0
set ulim=101
set lim = `cat amps | wc -l`
echo "$lim amp records to flag."
set flct = `echo $flct $lim | awk '{print $1+$2}'`
    while ($fidx == 0)
    set flags = `awk '{if ($2>llim) print $0}' llim=$llim amps | awk '{if ($2<ulim) printf "%s","vis("$3"),"}' ulim=$ulim`
    uvflag vis=$vis flagval=f options=none select=$flags
    if (`grep "R $ulim " amps | wc -l ` == 0) set fidx = 2
    set llim = `calc -i 100+$llim`
    set ulim = `calc -i 100+$ulim`
    end

autocal:
if ($autocmd == "nocal") set skip='skip'
if ($autocmd == "nocal") goto invert
echo $range $oldrange $sidx
if ($scopt == "pha") @ psci++
if ($scopt == "amp") @ asci++
set clip = `echo 10 $rmsnoise[1] | awk '{print $1*$2}'`

if (`echo $range $oldrange | awk '{if ($1 > 1.025*$2) print "go"}'` == go) then
gpcopy vis=$object out=tempmap
set sidx = 0
  selfcal vis=$vis model=$object.clean interval=$scint select=$sel \
	minants=4 options=noscale,$scopt clip=$clip refant=$refant \
	line=chan,1,1,824
set oldrange = $range
goto invert
endif

if (`echo $oldrange $range | awk '{if ((($2/$1)-.975)^2 <= .0025) print "stop"}'` == stop) then
    if ($autocmd == noamps) goto plot
    if ($scopt == amp) set scopt = tamp 
    if (`echo $scopt$fidx` == "tamp2") goto invert
set oldrange = $range
    if (`echo $scopt$fidx` == "tamp0") echo "Maximum range reached."
    if (`echo $scopt$fidx` == "tamp0") goto plot
    set scopt = amp
    echo
gpcopy vis=$object out=tempmap
    set sidx = 0
  selfcal vis=$vis model=$object.clean interval=$scint select=$sel \
	minants=4 options=noscale,$scopt clip=$clip refant=$refant \
	line=chan,1,1,824
goto invert
endif
@ sidx++
if ($sidx < 3) then 
  selfcal vis=$vis model=$object.clean interval=$scint select=$sel \
	minants=4 options=noscale,$scopt clip=$clip refant=$refant \
	line=chan,1,1,824
goto invert
endif

echo "Auto-selfcal has failed. Run automap in manual mode or rerun under different parameters."
if ($scopt == "pha") set badcal = pha
if ($scopt == "amp") set badcal = amp

gpcopy vis=tempmap out=$object

set skip = "skip"
goto invert

enderr:
echo "Failsafe initiated"
gpcopy vis=tempmap out=$object
rm -rf tempmap
finish:

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
