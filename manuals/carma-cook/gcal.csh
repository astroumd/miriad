#! /bin/csh -f
onintr cleanup
set size = $1
set half = `calc -i "($size/2)+1"`

alias prompt 'echo -n "$mess > ";set ans=$<;if ("$ans" == "") set ans="$dflt"'

set dflt=""
set mess = "Source file : ";prompt
set src = $ans
set mess = "Gain-calibrator file : ";prompt
set cal = $ans

set lower = 1
set upper = $half
while($lower < $half)
    uvcat vis=$cal select=win'('$lower')',win'('$upper')' out=$cal.$lower
    uvcat vis=$src select=win'('$lower')',win'('$upper')' out=$src.$lower
    set lower = `calc -i "($lower+1)"`
    set upper = `calc -i "($upper+1)"`
end

set mess = "Reference antenna: ";prompt
set ant = $ans
set mess = "Averaging interval (this should be <= your time on calibrator, i.e <= 5 min): ";prompt
set int = $ans
set mess = "Phase calibrator name (as it is in the dataset): ";prompt
set pcal = $ans
set mess = "Phase calibrator flux: ";prompt
set flux = $ans

set lower = 1
set upper = $half
while($lower < $half)
    gmakes vis=$cal.$lower line=wide,2,1 refant=$ant interval=$int fluxes=$pcal,$flux \
           options=apriori,amp,noscale out=gmake.$lower
    gfiddle vis=gmake.$lower device=/xw out=gfiddle.$lower
    gapply vis=$cal.$lower gvis=gfiddle.$lower out=$cal.caled.$lower
    gapply vis=$src.$lower gvis=gfiddle.$lower out=$src.caled.$lower
    uvcat vis=$src.caled.$lower select=win'('1')' out=$src.w$lower
    uvcat vis=$src.caled.$lower select=win'('2')' out=$src.w$upper
    uvcat vis=$cal.caled.$lower select=win'('1')' out=$cal.w$lower
    uvcat vis=$cal.caled.$lower select=win'('2')' out=$cal.w$upper
    if($lower == "1")then
        set vis = "$cal.caled.1"
    else
        set vis = "$vis,$cal.caled.$lower"
    endif
    set lower = `calc -i "($lower+1)"`
    set upper = `calc -i "($upper+1)"`
end

echo ""
echo "Plotting uvdistance vs amplitude for LSB"
echo " "
uvplt vis=$vis device=/xw line=wide,1,1 axis=uvd,amp options=nobase
echo ""
echo "Plotting uvdistance vs phase for LSB"
echo " "
uvplt vis=$vis device=/xw line=wide,1,1 axis=uvd,phase options=nobase
echo ""
echo "Plotting uvdistance vs amplitude for USB"
echo " "
uvplt vis=$vis device=/xw line=wide,1,2 axis=uvd,amp options=nobase
echo ""
echo "Plotting uvdistance vs phase for USB"
echo " "
uvplt vis=$vis device=/xw line=wide,1,2 axis=uvd,phase options=nobase

cleanup:
set lower = 1
rm -rf gmake.* gfiddle.* *.caled.*
while($lower < $half)
    rm -rf $cal.$lower $src.$lower
    set lower = `calc -i "($lower+1)"`
end

exit
