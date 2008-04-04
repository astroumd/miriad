#! /usr/bin/tcsh -f
# simple RFI script 			1/4/08 - gkk
#
# $Id$
#

if ($#argv < 4) then
echo "Prefix for files? (e.g. scan-)"
set pfx = $<
echo "Suffix for files? (e.g. -casa_1430)"
set sfx = $<
echo "Frequency of observations (in MHz)?)"
set freq = $<
echo "Frequency side?"
set side = $<
else
set pfx = $1
set sfx = $2
set freq = $3
set side = $4
endif
if ($5 == "skip") set rcount = "N/A"
if ($5 == "skip") goto skip
rm -f rfi.temp 
touch rfi.temp
echo "Beginning RFI search -- polling all records for $pfx*$sfx files."
set filelist = `du -sk $pfx*$sfx | awk '{print $2}'`
foreach file ( `echo $filelist`)
if ($side == 1) set line = "chan,412,101"
if ($side == 2) set line = "chan,412"
uvlist vis=$file recnum=0 options=stat select='window(1),-ant(1,4,12,19,23,31,33,37),-auto' line=$line | grep CHAN | awk '{print "C"$2,"C"$3,"C"$4,"C"$5,"C"$6,"C"$7,"C"$8,"C"$9,"C"$10,"C"$11,"C"$12,"C"$13}' >> rfi.temp
if ($5 == loud) echo "$file scanned and logged."
end
set rcount = `wc -l rfi.temp | awk '{print $1}'`
if ($rcount == 0) echo "No records found!"
if ($rcount == 0) goto finish

echo "Polling complete! $rcount records searched. Building count files."
cat rfi.temp | awk '{print $1" "}' > rfi.temp2
cat rfi.temp | awk '{print $2" "}' >> rfi.temp2
cat rfi.temp | awk '{print $3" "}' >> rfi.temp2
cat rfi.temp | awk '{print $4" "}' >> rfi.temp2
cat rfi.temp | awk '{print $5" "}' >> rfi.temp2
cat rfi.temp | awk '{print $6" "}' >> rfi.temp2
cat rfi.temp | awk '{print $7" "}' >> rfi.temp2
cat rfi.temp | awk '{print $8" "}' >> rfi.temp2
cat rfi.temp | awk '{print $9" "}' >> rfi.temp2
cat rfi.temp | awk '{print $10" "}' >> rfi.temp2
cat rfi.temp | awk '{print $11" "}' >> rfi.temp2
cat rfi.temp | awk '{print $12" "}' >> rfi.temp2

set chan = 1
if ($side == 1) set startchan = 100
if ($side == 2) set startchan = 512 
rm -f rfi.count
touch rfi.count
echo "File creation complete. Beginning RFI count."
while ($chan < 413)
set idx = `calc -i $startchan+$chan`
set count =  `grep -c "C$chan " rfi.temp2 | awk '{print $1}'`
echo "$idx $count" | awk '{print $1,1+$2}' >> rfi.count
if ($5 == loud) echo "$idx $count"
@ chan++
end
echo "RFI count complete."
rm rfi.temp
rm rfi.temp2

if ($5 == "partial") goto finish

skip:

echo "Running statistics."
cat rfi.count | sort -nk2 > rfi.count2 # lower 48
set clist = `cat rfi.count2 | awk '{print $1}'`
set plist = `cat rfi.count2 | awk '{print $2}'`
set nct=372

set istat = (`awk '{n++; if (n==1) {sx=$2; sxx=$2*$2} else {sx=sx+$2; sxx=sxx+($2*$2)} if (n==nct) {m=sx/n; r=sqrt((sxx-n*m*m)/n); print n, m, r}}' nct=$nct rfi.count2`)
echo $istat | awk '{printf "N, ave (rms) = %-2s %7.3f (%5.3f)\n", $1,$2,$3}'
set lim = `calc {$istat[2]}+4'*'{$istat[3]}`
set nct=412
set idx = 0
echo "RFI Listing for $pfx*$sfx files" > rfi.log
echo "Total number of records: $rcount" >> rfi.log
echo "Chan Count Sigma Freq" >> rfi.log

while ($idx == 0)
set cfreq = `calc '('$clist[$nct]-513')''*'0.1024+$freq`
set csig = `calc -i '('$plist[$nct]-$istat[2]')'/$istat[3]`
if ($csig > 3) then
if ($5 == loud) echo "$clist[$nct] $plist[$nct] $csig $cfreq"
if ($5 == skip) echo "$clist[$nct] $plist[$nct] $csig $cfreq"
echo "$clist[$nct] $plist[$nct] $csig $cfreq" >> rfi.log
  @ nct--
else
set idx = 1
endif
end
grep -v o rfi.log | sort -n > rfi.count2
if ($5 != "silent") wip ${MIRBIN}/rfi.wip
set cct = `calc -i 413-$nct`
echo "$cct channels with suspected RFI."
echo "Results logged in rfi.log. RFI count values in rfi.count."
rm -f rfi.count2
finish:
exit 0
