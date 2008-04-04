#! /usr/bin/tcsh -f
#
# $Id$
#

if ($#argv < 4) then
    echo "File prefix?"
    set pfx = "$<"
    echo "File suffix?"
    set sfx = "$<"
    echo "Frequency of obscheck? (in MHz)"
    set freq = $<
    echo "Mode?"
    set mode = $<
    set scanopt
    set jump
    set stime
    set etime
 else
    set pfx = "$1"
    set sfx = "$2"
    set freq = $3
    set mode = $4
    set scanopt = $5
    set jump = $6
    set stime = $7
    set etime = $8
endif

set schan = 0

if ($jump == crawl) goto spider

if ($jump == display) goto display

if ($jump != "noscan") goto start
if (-e lastrfi) then
    echo "Resume last flagging? ( |y|es or [n]o )"
    if ( $< != "n") set schan = `cat lastrfi | awk '{print $1}'`
    echo "Starting channel set to $schan"
endif

start:

set timerange

if ($stime != "") set timerange = "time($stime,$etime)"  

if ($mode == "normal") then

set filelist = "$pfx*$sfx"
set list = `echo $filelist | tr ' ' ','`
if ($jump == "noscan") goto flag

rm -f full.rficount full.rfilog

rm -rf tempx-*-cal tempy-*-cal

echo "Building files..."
foreach file (`echo $filelist`)
mv $file/flags $file/flags2
uvcal vis=$file options=fxcal,nocal,nopass,nopol out=tempx-$file-cal select="pol(xx),$timerange" > /dev/null
    if (-e tempx-$file-cal/visdata) then
    else
    rm -rf tempx-$file-cal
    endif

uvcal vis=$file options=fxcal,nocal,nopass,nopol out=tempy-$file-cal select="pol(yy),$timerange" > /dev/null
    if (-e tempy-$file-cal/visdata) then
    else
    rm -rf tempy-$file-cal
    endif
mv $file/flags2 $file/flags
#rm -rf tempa tempb
end

if (`du -sh temp*cal | wc -l` == 0) then
echo "No files found!"
goto finish
endif

uvflag vis='temp*cal' flagval=u options=none select="window(1),$timerange" > /dev/null
uvflag vis='temp*cal' flagval=f options=none select="window(1),ant(1,2,3,4,9,12,19,23,24,31,33,35,37),pol(xx),$timerange" > /dev/null
echo "Building complete!"

if (-e scan-.log) mv scan-.log scan.log

rfi.csh temp cal $freq $scanopt

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

set filelist1 = "$pfx*$sfx"_1
set filelist2 = "$pfx*$sfx"_2

set list1 = `echo $filelist1 | tr ' ' ','`
set list2 = `echo $filelist2 | tr ' ' ','`

if ($jump == "noscan") goto flag

rm -f full.rficount full.rfilog
 
rm -rf tempx-*-cal1 tempy-*-cal1 tempx-*-cal2 tempy-*-cal2

echo "Building files..."

set idx = 0
foreach file (`echo $filelist1`)
@ idx++
mv $file/flags $file/flags2
uvcal vis=$file options=fxcal select="pol(xx),$timerange" out=tempx-$idx-cal1 > /dev/null

    if (-e tempx-$idx-cal1/visdata) then
    echo "File good!"
    else
    echo "File no good!"
    rm -rf tempx-$idx-cal1
    endif

uvcal vis=$file options=fxcal select="pol(yy),$timerange" out=tempy-$idx-cal1 > /dev/null

    if (-e tempy-$idx-cal1/visdata) then
    echo "File good!"
    else
    echo "File no good!"
    rm -rf tempy-$idx-cal1
    endif

mv $file/flags2 $file/flags
end
set idx = 0
foreach file (`echo $filelist2`)
@ idx++
mv $file/flags $file/flags2
uvcal vis=$file options=fxcal select="pol(xx),$timerange" out=tempx-$idx-cal2 > /dev/null

    if (-e tempx-$idx-cal2/visdata) then
    echo "File good!"
    else
    echo "File no good!"
    rm -rf tempx-$idx-cal2
    endif

uvcal vis=$file options=fxcal select="pol(yy),$timerange" out=tempy-$idx-cal2 > /dev/null

    if (-e tempy-$idx-cal2/visdata) then
    echo "File good!"
    else
    echo "File no good!"
    rm -rf tempy-$idx-cal2
    endif

mv $file/flags2 $file/flags
end

uvflag vis='temp*cal*' flagval=u options=none > /dev/null
uvflag vis='temp*cal1' flagval=f options=none select='window(1),ant(1,4,12,19,23,31,33,37),pol(xx)' > /dev/null
uvflag vis='temp*cal2' flagval=f options=none select='window(1),ant(1,3,4,9,12,19,23,24,31,33,35,37),pol(xx)' > /dev/null
echo "Building complete!"
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

rm -rf tempx-*-cal* tempy-*-cal*

if ($jump == "noflag") goto finish
goto flag

#Flagging stage

flag:

if ($mode == "split") goto splitflag

foreach chan (`grep -v o full.rfilog | sort -nk1 | awk '{if ($1 > schan) print $1}' schan=$schan`)
echo "Flagging channel $chan"
uvflag vis=$list flagval=f options=none line=chan,1,$chan select="window(1),$timerange"
echo $chan > lastrfi
end
rm lastrfi
echo "Flagging first 100 channels"
uvflag vis=$list flagval=f options=none line=chan,100
echo "Flagging last 100 channels"
uvflag vis=$list flagval=f options=none line=chan,100,925
echo "Flagging known bad spectra"
uvflag vis=$list flagval=f options=none select="window(1),ant(1,19,23,37),pol(xx),$timerange" line=chan,256,513
uvflag vis=$list flagval=f options=none select="window(1),ant(4,12,31,33),pol(xx),$timerange" line=chan,64,769
uvflag vis=$list flagval=f options=none select="window(1),ant(3,9,24,35),pol(xx),$timerange" line=chan,256,769
uvflag vis=$list flagval=f options=none select="window(1),ant(2,17,36,40),pol(xx),$timerange" line=chan,64,193

echo "RFI flagging complete!"
goto finish
#splitsville
splitflag:

foreach chan (`grep -v o full.rfilog | sort -nk1 | awk '{if ($1 > schan) print $1}' schan=$schan | awk '{if ($1 < 513) print $1}'`)
echo "Flagging channel $chan"
uvflag vis=$list1 flagval=f options=none line=chan,1,$chan select="window(1),$timerange"
echo $chan > lastrfi
end

foreach chan (`grep -v o full.rfilog | sort -nk1 | awk '{if ($1 > schan) print $1}' schan=$schan | awk '{if ($1 > 512) print $1-512}'`)
echo "Flagging channel $chan (+512)"
uvflag vis=$list2 flagval=f options=none line=chan,1,$chan select="window(1),$timerange"
echo $chan | awk '{print $1+512}' > lastrfi
end
rm lastrfi
echo "Flagging center channel"
uvflag vis=$list2 flagval=f options=none line=chan,1 select="window(1),$timerange"
echo "Flagging first 100 channels"
uvflag vis=$list1 flagval=f options=none line=chan,100 select="window(1),$timerange"
echo "Flagging last 100 channels"
uvflag vis=$list2 flagval=f options=none line=chan,100,413 select="window(1),$timerange"
echo "Flagging known spectral corruption"
uvflag vis=$list2 flagval=f options=none select="window(1),ant(1,19,23,37),pol(xx),$timerange" line=chan,256,1
uvflag vis=$list2 flagval=f options=none select="window(1),ant(4,12,31,33),pol(xx),$timerange" line=chan,64,257
uvflag vis=$list2 flagval=f options=none select="window(1),ant(3,9,24,35),pol(xx),$timerange" line=chan,256,257
echo "RFI scanning and flagging complete!"

finish:

exit 0

display:
if (! -e full.rficount) then
echo "No scan detected! Must scan dataset first."
goto finish
endif

if (! -e full.rfilog) then
echo "No RFI detected in last scan!"
goto finish
endif

echo "Displaying RFI results of last scan..."
grep -v "o" full.rfilog > full.rfilogtemp
wip ${MIR}/src/scripts/ata/rapid/rfisweep.wip
rm -f full.rfilogtemp
goto finish

spider:

goto finish
