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
    uvcat vis=$cal select=win'('$lower')',win'('$upper')' out=$cal.$lower options=nowide
    uvcat vis=$src select=win'('$lower')',win'('$upper')' out=$src.$lower options=nowide

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
set stop = `calc -i "($size/2)"`
while($lower < $half)
    uvlist vis=$cal.$lower options=spec log=log
    set nchan=`gawk '{if ($1 == "number") print $5}' log`
    gmakes vis=$cal.$lower line=channel,2,1,$nchan,$nchan refant=$ant interval=$int fluxes=$pcal,$flux options=apriori,amp,noscale out=gmake.$lower

    gfiddle vis=gmake.$lower device=/xw out=gfiddle.$lower
    gapply vis=$cal.$lower gvis=gfiddle.$lower out=$cal.caled.$lower
    gapply vis=$src.$lower gvis=gfiddle.$lower out=$src.caled.$lower
    uvcat vis=$src.caled.$lower select=win'('1')' out=$src.w$lower
    uvcat vis=$src.caled.$lower select=win'('2')' out=$src.w$upper
    uvcat vis=$cal.caled.$lower select=win'('1')' out=$cal.w$lower
    uvcat vis=$cal.caled.$lower select=win'('2')' out=$cal.w$upper
    set lower = `calc -i "($lower+1)"`
    set upper = `calc -i "($upper+1)"`
end

cleanup:
set lower = 1
rm -rf *.caled.* log
while($lower < $half)
    rm -rf $cal.$lower $src.$lower
    set lower = `calc -i "($lower+1)"`
end

exit
