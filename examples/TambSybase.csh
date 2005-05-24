#! /bin/csh -f
#
# Script to extract Ambient Temperature data from SMA sybase
# author: jhz
# Usage:
# TambSybase.csh yyyy mm dd antID
# output file name = tambient.dat
# first row of the header is yyyy mm dd antID
# 1st column = UT time in min
# 2nd column = Tamb in Celsius
if ($#argv < 4) then
echo "Usage: Incorrect number of input arguments for observing date"
echo "       TambSybase.csh yyyy mm dd antID"
exit 0
endif
set y = $1 
set m = $2 
set d = $3 
set ant = $4
dBValue -T "$y-$m-$d 00:00:00 $y-$m-$d 23:59:59 1 acc$ant RM_WEATHER_TEMP_F" \
	> tambient.dat
cp tambient.dat tmp.dat
wc -l tambient.dat > tmp2.dat
echo '   '$y $m $d $ant >> tmp2.dat
cp tmp2.dat tambient.dat
cat tmp.dat >> tambient.dat
exit 0 
