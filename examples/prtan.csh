#!/bin/csh -f
#
# prtan.csh: uses listobs to obtain antenna positions which are then
#            written to a data file plotted by a wip script.
#
# Inputs: 1. Source data filename, used only to get positions of 
#            antennas used in the observations
#         2. Array configuration (optional - C is default)
#
# v1.0 agg 11/25/03 Basic functionality
#      pjt  2/14/07 Made it work for CARMA, and fixed to use new ENU from listobs
#
#

# Check inputs...
if ($#argv == 0) then
    echo "Usage: prtan.csh source [array_config (C)]"
    echo "Note - source is just used to extract antenna positions"
    exit 1
else if ($#argv == 1) then
    set ary=C
    echo "No array specified: assuming C array"
else if ($#argv == 2) then
    set ary=$2
    if ($ary == "a") then
	set ary=A
    else if ($ary == "a+") then
	set ary=A+
    else if ($ary == "b") then
	set ary=B
    else if ($ary == "c") then
	set ary=C
    else if ($ary == "d") then
	set ary=D
    endif
endif

# Get antenna positions from listobs
listobs vis=$1 > /tmp/listobs.tmp

cat /tmp/listobs.tmp | grep Antenna | grep -vi "in" | \
        awk '{print $2 " " $7 " " $6}' | \
        sed s/":"/" "/g  > /tmp/anten.tmp

set date=`grep Chron /tmp/listobs.tmp | awk '{print $5}'`
set freq=`grep "Rest Freq" /tmp/listobs.tmp | awk '{print $6}'`

# Generate wip macro
if ($ary == "A") then
    echo "winadj -3000 3000 -3000 3000" > /tmp/prtan.wip
else if ($ary == "A+") then
    echo "winadj -3000 3000 -3000 3000" > /tmp/prtan.wip
else if ($ary == "B") then
    echo "winadj -600 600 -600 600" > /tmp/prtan.wip
else if ($ary == "C") then
    echo "winadj -240 240 -240 240" > /tmp/prtan.wip
else if ($ary == "D") then
    echo "winadj -100 100 -100 100" > /tmp/prtan.wip
endif
#echo "box bcnts bcnts" >> /tmp/prtan.wip
echo "xlabel E-W distance (ns) " >> /tmp/prtan.wip
echo "ylabel N-S distance (ns) " >> /tmp/prtan.wip
echo "data /tmp/anten.tmp" >> /tmp/prtan.wip
echo "ycol 2" >> /tmp/prtan.wip
echo "xcol 3" >> /tmp/prtan.wip
echo "symbol 7" >> /tmp/prtan.wip
echo "points" >> /tmp/prtan.wip

# Draw compass
#echo "move " >> /tmp/prtan.wip

# Draw the `T'
echo "lstyle 4" >> /tmp/prtan.wip
echo "move -500 0" >> /tmp/prtan.wip
echo "draw 500 0" >> /tmp/prtan.wip
echo "move 0 0" >> /tmp/prtan.wip
echo "draw 0 -580" >> /tmp/prtan.wip
echo "lstyle 1" >> /tmp/prtan.wip

@ i=0
foreach j (`cat /tmp/anten.tmp | awk '{print $1}'`)
    @ i++
    echo "move x["$i"] y["$i"]" >> /tmp/prtan.wip
    echo "label " $j >> /tmp/prtan.wip
end
if ($ary == "A") then
    echo "limits -3000 3000 -3000 3000" >> /tmp/prtan.wip
else if ($ary == "A+") then
    echo "limits -3000 3000 -3000 3000" >> /tmp/prtan.wip
else if ($ary == "B") then
    echo "limits -600 600 -600 600" >> /tmp/prtan.wip
else if ($ary == "C") then
    echo "limits -240 240 -240 240" >> /tmp/prtan.wip
else if ($ary == "D") then
    echo "limits -100 100 -100 100" >> /tmp/prtan.wip
endif
echo "box bcnts bcnts" >> /tmp/prtan.wip

echo "mtext t 3.0 0.5 0.5 CARMA antenna positions for "$ary" Array " >> /tmp/prtan.wip
echo "mtext t 1.25 0.25 0.5 Date of observation:" $date >> /tmp/prtan.wip
echo "mtext t 1.25 0.75 0.5 Frequency:" $freq "GHz" >> /tmp/prtan.wip

echo " " >> /tmp/prtan.wip
# Generate plot
wip -x /tmp/prtan.wip -d 1/xs

# Ask if hardcopy required
echo "Hardcopy? (y/n, default=n)"
set hcopy=$<
if ($hcopy == "y") then
    wip -x /tmp/prtan.wip -d /ps
endif

# Cleanup and exit
\rm /tmp/prtan.wip
\rm /tmp/anten.tmp
\rm /tmp/listobs.tmp

exit 0 
