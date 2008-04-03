#! /usr/bin/tcsh -f
#
# $Id$
#

if ($#argv < 4) then
    echo "File prefix?"
    set pfx = $<
    echo "File suffix?"
    set sfx = $<
    echo "Frequency of obscheck? (in MHz)"
    set freq = $<
    echo "Mode?"
    set mode = $<
    else
    set pfx = $1
    set sfx = $2
    set freq = $3
    set mode = $4
    set scanopt = $5
    set jump = $6
endif

if ($mode == "normal") then

set filelist = $pfx'*'$sfx
set list = `echo $filelist | tr ' ' ','`
if ($jump == "noscan") goto flag
uvflag vis=$list flagval=u options=none

rm -rf tempx-*-cal tempy-*-cal
foreach file (`echo $filelist`)
#uvcat vis=$list select='pol(xx)' options=nocal,nopass,nopol out=tempa
#uvcat vis=$list select='pol(yy)' options=nocal,nopass,nopol out=tempb
uvcal vis=$file options=fxcal,nocal,nopass,nopol out=tempx-$file-cal select='pol(xx)'
uvcal vis=$file options=fxcal,nocal,nopass,nopol out=tempy-$file-cal select='pol(yy)'
#rm -rf tempa tempb
end

if (-e scan-.log) mv scan-.log scan.log

rfi.csh temp cal $freq loud

mv rfi.count full.rficount
mv rfi.log full.rfilog

rm -f rfi.total
touch rfi.total
if ($jump == "noflag") goto finish
goto flag
endif
if ($mode != "split") echo "Mode not recognized!"
if ($mode != "split") goto finish

#And if it should be in fx32/split mode

set filelist1 = $pfx'*'$sfx"_1"
set filelist2 = $pfx'*'$sfx"_2"

set list1 = `echo $filelist1 | tr ' ' ','`
set list2 = `echo $filelist2 | tr ' ' ','`

if ($jump == "noscan") goto flag

uvflag vis=$list1 flagval=u options=none
uvflag vis=$list2 flagval=u options=none

rm -rf tempx-*-cal1 tempy-*-cal1 tempx-*-cal2 tempy-*-cal2

set idx = 0
foreach file (`echo $list1`)
@ idx++
uvcal vis=$file options=fxcal select='pol(xx)' out=tempx-$idx-cal1
uvcal vis=$file options=fxcal select='pol(yy)' out=tempy-$idx-cal1

end
set idx = 0
foreach file (`echo $list2`)
@ idx++

uvcal vis=$file options=fxcal select='pol(xx)' out=tempx-$idx-cal2
uvcal vis=$file options=fxcal select='pol(yy)' out=tempy-$idx-cal2

end

rm -rf tempa1 tempa2 tempb1 tempb2

if (-e scan-.log) mv scan-.log scan.log

rfi32.csh temp -cal1 $freq 1 $scanopt
mv rfi.count rfi-spec1.count
mv rfi.log rfi-spec1.log
rfi32.csh temp -cal2 $freq 2 $scanopt
mv rfi.count rfi-spec2.count
mv rfi.log rfi-spec2.log
cat rfi-spec1.log rfi-spec2.log >> full.rfilog
cat rfi-spec1.count rfi-spec2.count >> full.rficount

rm -f rfi-spec*.*

rm -f rfi.total
touch rfi.total
if ($jump == "noflag") goto finish
goto flag

#Flagging stage

flag:

if ($mode == "split") goto splitflag

foreach chan (`grep -v o full.rfilog | sort -nk1 | awk '{print $1}'`)
echo "Flagging channel $chan"
uvflag vis=$list flagval=f options=none line=chan,1,$chan
end

echo "Flagging first 100 channels"
uvflag vis=$list flagval=f options=none line=chan,100
echo "Flagging last 100 channels"
uvflag vis=$list flagval=f options=none line=chan,100,925
echo "RFI flagging complete!"
goto finish
#splitsville
splitflag:

foreach chan (`grep -v o full.rfilog | sort -nk1 | awk '{if ($1 < 513) print $1}'`)
echo "Flagging channel $chan"
uvflag vis=$list1 flagval=f options=none line=chan,1,$chan
end

foreach chan (`grep -v o full.rfilog | sort -nk1 | awk '{if ($1 > 512) print $1-512}'`)
echo "Flagging channel $chan (+512)"
uvflag vis=$list2 flagval=f options=none line=chan,1,$chan
end

echo "Flagging center channel"
uvflag vis=$list2 flagval=f options=none line=chan,1
echo "Flagging first 100 channels"
uvflag vis=$list1 flagval=f options=none line=chan,100
echo "Flagging last 100 channels"
uvflag vis=$list2 flagval=f options=none line=chan,100,413
echo "RFI scanning and flagging complete!"


finish:

rm -rf tempx-*-cal tempy-*-cal

exit 0
