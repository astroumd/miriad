#! /usr/bin/tcsh -f
#
# $Id$
#

set pfx = $1
set sfx = $2
set cal = $3
set vis = $4
set freq = $5
set olay = $6
set mapskip = $7
set maplflux = $8
set maphflux = $9
set autocmd = $10
set sflag = $11
if ($pfx == "none") set pfx
if ($sfx == "none") set sfx
set flux = `grep -i $vis ${MIRCAT}/ata/cals.list | awk '{print $6}'`
if (`echo $flux | wc -w` != 0) then
set lflux = `echo $flux .1 | awk '{print $1*$2}'`
set hflux = `echo $flux 1.9 | awk '{print $1*$2}'`
set uflux = `echo $flux 2 | awk '{print $1*$2}'`
else
set flux = "unknown"
set uflux = 25000
set hflux = 10000
set lflux = 0
endif
rm -f crosscalbasei
touch crosscalbasei
rm -f crosscalbasef
touch crosscalbasef

echo $flux $uflux $hflux $lflux
onintr finish
if (-e tot-$cal$sfx) goto beenthere
calcal.csh $pfx $cal$sfx $cal $freq gamma skip
beenthere:

cat $cal.calrpt | grep " --- " | grep "spectra preserved (0%)" | awk '{print $1}' | grep X | tr 'X-' ' ' | awk '{print "ant("$1")("$2"),pol(xx)"}' > badbase

cat $cal.calrpt | grep " --- " | grep "spectra preserved (0%)" | awk '{print $1}' | grep Y | tr 'Y-' ' ' | awk '{print "ant("$1")("$2"),pol(yy)"}' >> badbase

echo "Flagging bad baselines!"
foreach baseline (`cat badbase`)
echo "Flagging $baseline"
uvflag vis=$pfx'*'$vis$sfx flagval=f options=none select=$baseline
end

rm badbase

#if (-e tot-$vis$sfx) goto donethat
#calcal.csh $pfx $vis$sfx $vis $freq gamma skip
#donethat:

cp ~/bin/olays/olay .

if (`echo $olay` != "none" ) then
if (-e ~/bin/olays/$olay$vis.olay) cp ~/bin/olays/$olay$vis.olay olay
endif 

set calfilelist = `du $pfx*$cal*$sfx | awk '{print $2}'`
set visfilelist = `du $pfx*$vis*$sfx | awk '{print $2}'`

mkdir -p visgains
rm -rf temp 
foreach file (`echo $visfilelist`)

cp $file/bandpass visgains/$file.bandpass
cp $file/gains visgains/$file.gains

uvaver vis=$file out=$file.temp select='window(1),-auto' options=nocal,nopol,nopass interval=.5

uvplt vis=$file.temp device=/null select='pol(xx),window(1),-auto' options=nocal,nopass,nopol | grep Baseline | tr "-" " " | awk '{print " "$2"X-"$3"X",$5}' >> crosscalbasei

uvplt vis=$file.temp device=/null select='pol(yy),window(1),-auto' options=nocal,nopass,nopol | grep Baseline | tr "-" " " | awk '{print " "$2"Y-"$3"Y",$5}' >> crosscalbasei

cat crosscalbasei | tr "-" " "| awk '{print $1}' >> temp
cat crosscalbasei | tr "-" " "| awk '{print $2}' >> temp

end 


sort -u temp | sort -n > crosscalants
grep -v uvplt crosscalbasei > temp
mv temp crosscalbasei


set idx=0
foreach file (`echo $calfilelist`)
@ idx++
echo $file $visfilelist[$idx]
puthd in=$file/interval value=1
gpcopy vis=$file out=$visfilelist[$idx].temp
puthd in=$file/interval value=.021
end

foreach file (`echo $visfilelist`)
cp visgains/$file.bandpass $file/bandpass
cp visgains/$file.gains $file/gains
end 

set templist = `du $pfx*$vis$sfx.temp | awk '{print $2}'`
set list = `echo $templist | tr " " ","`
echo $list

set catfile = cross-$vis-$cal$sfx
rm -rf $catfile
uvaver vis=$list select='window(1),-auto' out=$catfile

rm -r *.temp

set sel = "amp($uflux)"
uvflag vis=$catfile flagval=f select=$sel options=none

uvlist vis=$catfile options=stat recnum=0 | grep -v CHAN | grep ":" | grep -v "e" | awk '{if ($7>hflux) print $1}' hflux=$hflux| awk '{print $1}' > lamps
uvlist vis=$catfile options=stat recnum=0 | grep -v CHAN | grep ":" | grep -v "e" | awk '{if ($7<lflux) print $1}' lflux=$lflux| awk '{print $1}' > hamps
cat lamps hamps | awk '{print "R",NR,$1}' > amps

  set idx=0
  set llim=0
  set ulim=101
  set lim = `cat amps | wc -l`
  echo "$lim amp records to flag."
  if (`cat amps| wc -w` == 0) set idx = 1
  echo "Round 396 of flagging (Closure!)"
    while ($idx == 0)
    set flags = `awk '{if ($2>llim) print $0}' llim=$llim amps | awk '{if ($2<ulim) printf "%s","vis("$3"),"}' ulim=$ulim`
    uvflag vis=$catfile flagval=f options=none select=$flags
    echo $llim $lim
      if (`grep "R $ulim " amps | wc -l` == 0) set idx = 2
    set llim = `calc -i 100+$llim`
    set ulim = `calc -i 100+$ulim`
    end

automap.csh $catfile $mapskip $maplflux $maphflux $autocmd $sflag
echo "(Note - flux for $vis is $flux)" >> $catfile.imgrpt


report:

rm -f rpt.temp
uvplt vis=$catfile device=/null select='pol(xx),-auto' | grep Baseline | tr "-" " " | awk '{print " "$2"X-"$3"X",$5}' >> crosscalbasef
uvplt vis=$catfile device=/null select='pol(yy),-auto' | grep Baseline | tr "-" " " | awk '{print " "$2"Y-"$3"Y",$5}' >> crosscalbasef
set tipts
set tfpts
foreach base (`cat crosscalbasei | awk '{print $1}'`)
set ipts = `grep " $base" crosscalbasei | awk '{print $2}'`
set tipts = `echo $ipts $tipts | awk '{print $1+$2}'`
set fpts = " "`grep " $base" crosscalbasef | awk '{print $2}'`
set tfpts = `echo $fpts $tfpts | awk '{print $1+$2}'`

if (`echo $fpts | wc -w` == 0) set fpts = 0

set pct = `echo $fpts $ipts | awk '{print 100*$1/$2}' | tr "." " " | awk '{print $1}'`
echo " $base --- $fpts out of $ipts spectra preserved ($pct%)" >> rpt.temp

end

set tptspct = `echo $tfpts $tipts | awk '{print 100*$1/$2}' | tr "." " " | awk '{print $1}'`
set badlist = `grep "(0%)" rpt.temp | awk '{print $1}'`

echo "Cross-cal report summary for $cal and $vis"  > $catfile.baserpt
echo "-----------------------------------------" >> $catfile.baserpt
set iblines = `wc -l crosscalbasei | awk '{print $1}'` 
set fblines = `wc -l crosscalbasef | awk '{print $1}'`
set bpct = `echo $fblines $iblines | awk '{print 100*$1/$2}' | tr "." " "| awk '{print $1}'`
echo "$tfpts out of $tipts ($tptspct%) spectra were preserved during the observation." >> $catfile.baserpt
echo "$fblines out of $iblines ($bpct%) baselines were preserved during the observation." >> $catfile.baserpt
echo " " >> $catfile.baserpt

if ($bpct != 100) then
echo "Baselines that were not preserved (0% spectra):" >> $catfile.baserpt
echo $badlist | tr " " "," >> $catfile.baserpt
echo " " >> $catfile.baserpt
echo "(Note - baselines in $vis will not be preserved if they were not preserved in $cal. Check the calcal report for $cal for baselines that failed to converge on the calibrator)"  >> $catfile.baserpt
echo " " >> $catfile.baserpt
echo "Antenna Counts" >> $catfile.baserpt
echo "--------------------------------------------------------------"  >> $catfile.baserpt
    foreach antpol (`cat crosscalants`)
    set antcount = `grep "(0%)" rpt.temp | tr "-" " "| grep " $antpol " | wc -l | awk '{print $1}'`
    if ($antcount != 0) echo "$antpol --- $antcount affected baseline(s)" >> $catfile.baserpt
end
echo " " >> $catfile.baserpt
echo "END SUMMARY" >> $catfile.baserpt
echo "--------------------------------------------------------------"  >> $catfile.baserpt
endif
echo " " >> $catfile.baserpt
echo " " >> $catfile.baserpt

echo "Full baseline statistics for $catfile" >> $catfile.baserpt
echo "--------------------------------------------------------------"  >> $catfile.baserpt
cat rpt.temp >> $catfile.baserpt

echo "Baselines report now available under $catfile.baserpt"
finish:
rm -rf visgains
#rm -rf $catfile
rm -rf rpt.temp crosscal* temp

exit 0
