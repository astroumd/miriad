#!/bin/csh -f
#
echo "# robust.csh: script to check beam profile and dirty map rms "
echo "# versus various values of robustness as well as natural and"
echo "# uniform weighting."
echo "#   -- MWP Thu Aug  1 13:53:19 PDT 1996"
echo " "
echo "#  automatically generate slice.param if it is not there"
echo "#  mwp Thu Jun  5 12:10:23 PDT 1997"
echo "  "
echo "# Fixed some minor bugs"
echo "#  mwp Tue Jun 17 11:34:23 PDT 1997 "
echo " "
echo " USAGE:"
echo " cp $MIRBIN/robust.csh . "
echo " Edit the map parameters then run script in your own directory"
goto end
#



set device=/xs

# map parameters
set ovis=m16.co.ga,../09may97/m16.co.ga,../10may97/m16.co.ga
set line=velo,1,15.0,.266,.266 # take an empty channel
set imsize=128,128
set cell=2,2
set sel='window(8)'
set robust=-2
set incr=0.5
set region='image(1)'

# make a beam slice file for cgslice
if ( ! -e slice.param ) then
 echo abspix abspix 128 128 128 255 1 1 > slice.param
 echo abspix abspix 128 128 255 128 1 1 >> slice.param
endif
 
echo > robust.wip
set n=1

# first do natural and uniform
invert vis=$ovis map=mp.nat \
        beam=bm.nat imsize=$imsize select=$sel \
        cell=$cell sup=0 line=$line options=systemp,mosaic,double 

echo Natural |tee -a robust.stats
echo File bm.nat |tee -a robust.stats
set label=`histo region=$region in=mp.nat |grep Rms`
echo Dirty map parameters: $label |tee -a robust.stats
echo =================================== >> robust.stats

cgslice in=bm.nat device=$device nxy=1,1 labtyp=arcsec options=noimage \
        csize=0.5 posin=slice.param valout=beamslice.nat region=$region

echo panel 2 6 $n>> robust.wip
echo font 1 >> robust.wip
echo data beamslice.nat >> robust.wip
echo lines 3 510 >> robust.wip
echo xcol 4 >> robust.wip
echo ycol 5 >> robust.wip
echo limits 0 160 -0.5 1 >> robust.wip
echo lstyle 1 >> robust.wip
echo box >> robust.wip
echo connect >> robust.wip
echo lines 511 1018 >> robust.wip
echo xcol 4 >> robust.wip
echo ycol 5 >> robust.wip
echo lstyle 3 >> robust.wip
echo connect >> robust.wip
echo move 55 0.75 >> robust.wip
echo label Natural >> robust.wip
echo move 55 0.55 >> robust.wip
set rms=`echo $label | awk '{printf "%4.3f", $4}'`
echo label Dirty Map Rms: $rms >> robust.wip

/bin/rm -rf mp.nat 
invert vis=$ovis map=mp.uni\
        beam=bm.uni imsize=$imsize select=$sel\
        cell=$cell line=$line options=systemp,mosaic,double 

echo Uniform |tee -a robust.stats
echo File bm.uni|tee -a robust.stats
set label=`histo region=$region in=mp.uni |grep Rms`
echo Dirty map parameters: $label |tee -a robust.stats
echo =================================== >> robust.stats
/bin/rm -rf mp.uni

cgslice in=bm.uni device=$device nxy=1,1 labtyp=arcsec options=noimage \
        csize=0.5 posin=slice.param valout=beamslice.uni region=$region


@ n++
echo panel 2 6 $n>> robust.wip
echo font 1 >> robust.wip
echo data beamslice.uni >> robust.wip
echo lines 3 510 >> robust.wip
echo xcol 4 >> robust.wip
echo ycol 5 >> robust.wip
echo limits 0 160 -0.5 1 >> robust.wip
echo lstyle 1 >> robust.wip
echo box >> robust.wip
echo connect >> robust.wip
echo lines 511 1018 >> robust.wip
echo xcol 4 >> robust.wip
echo ycol 5 >> robust.wip
echo lstyle 3 >> robust.wip
echo connect >> robust.wip
echo move 55 0.75 >> robust.wip
echo label Uniform >> robust.wip
echo move 55 0.55 >> robust.wip
set rms=`echo $label | awk '{printf "%4.3f", $4}'`
echo label Dirty Map Rms: $rms >> robust.wip
@ n++

while ( `expr $robust "<" 2.1` )
invert vis=$ovis map=mp.r_$robust \
        beam=bm.r_$robust imsize=$imsize select=$sel\
        cell=$cell robust=$robust line=$line options=systemp,mosaic,double \
 
echo Robustness parameter is $robust |tee -a robust.stats
echo File bm.r_$robust |tee -a robust.stats
set label=`histo region=$region in=mp.r_$robust |grep Rms`
echo Dirty map parameters: $label |tee -a robust.stats
echo =================================== >> robust.stats
/bin/rm -rf mp.r_$robust
 
cgslice in=bm.r_$robust device=$device nxy=1,1 labtyp=arcsec options=noimage \
        csize=0.5 posin=slice.param valout=beamslice.r_$robust region=$region

echo panel 2 6 $n >> robust.wip
echo font 1 >> robust.wip
echo data beamslice.r_$robust >> robust.wip
echo lines 3 510 >> robust.wip
echo xcol 4 >> robust.wip
echo ycol 5 >> robust.wip
echo limits 0 160 -0.5 1 >> robust.wip
echo lstyle 1 >> robust.wip
echo box >> robust.wip
echo connect >> robust.wip
echo lines 511 1018 >> robust.wip
echo xcol 4 >> robust.wip
echo ycol 5 >> robust.wip
echo lstyle 3 >> robust.wip
echo connect >> robust.wip
echo move 55 0.75 >> robust.wip
echo label Robustness: $robust >> robust.wip
echo move 55 0.55 >> robust.wip
set rms=`echo $label | awk '{printf "%4.3f", $4}'`
echo label Dirty Map Rms: $rms >> robust.wip

set robust=`echo $robust + $incr|bc -l `
@ n++
end

echo panel 2 6 12 >> robust.wip
echo limits 0 1 0 1 >> robust.wip
echo expand 1.1 >> robust.wip
echo move 0.1 0.75 >> robust.wip
echo label Beam Profile vs. Robustness >> robust.wip
echo move 0.1 0.5  >> robust.wip
echo lstyle 1 >> robust.wip
echo draw 0.35 0.5  >> robust.wip
echo label N-S cut >> robust.wip
echo move 0.1 0.25 >> robust.wip
echo lstyle  2 >> robust.wip
echo draw 0.35 0.25 >> robust.wip
echo label E-W cut >> robust.wip
echo end >> robust.wip

WipitGood:
wip -d /xs robust.wip

TheEnd:
exit 0

