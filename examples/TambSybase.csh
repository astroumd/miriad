#! /bin/csh -f
#
# Script to extract Ambient Temperature data from SMA sybase
# author: jhz 2005-5-25
#         jhz 2005-5-25 change Arguments 4 to RM_VARIABLE 
# Usage:
# TambSybase.csh yyyy mm dd antID
# output file name = tambient.dat
# first row of the header is yyyy mm dd Nant
# then concatenate indiviaul antenna-based file with
# 1st row for total number data and filename
# 2nd row antenna id 
# 1st column = UT time in min
# 2nd column = Tamb in Celsius
if ($#argv < 4) then
echo "Usage: Incorrect number of input arguments for observing date and interval(min)"
echo "       TambSybase.csh yyyy mm dd RM_VAR"
exit 0
endif
set y = $1 
set m = $2 
set d = $3
# RM Variables RM_WEATHER_TEMP_F RM_AMBIENTLOAD_TEMPERATURE_F
set RM_VAR = $4 
set int = 1 
set ant = 1 
echo '   '$ant > tambient$ant.dat
while($ant < 9)
dBValue -T "$y-$m-$d 00:00:00 $y-$m-$d 23:59:59 $int acc$ant $RM_VAR" \
	> tmp$ant.dat
cp tmp$ant.dat tambient.dat
wc -l tmp$ant.dat >> tambient$ant.dat 
cat tambient.dat >> tambient$ant.dat
rm tambient.dat 
    @ ant++
echo '   '$ant > tambient$ant.dat
end
    @ ant--
echo '   '$y $m $d $ant $RM_VAR > tambient.dat
set i=1
while($i < 9)
cat tambient$i.dat >> tambient.dat
rm tambient$i.dat tmp$i.dat
   @ i++
end
exit 0 
