#! /usr/bin/tcsh -f
#Calibrates a cal
#
# $Id$
#


set pfx = $1
set sfx = $2
set cal = $3
set freq = $4
set olay = $5
set mapskip = $6
set maplflux = $7
set maphflux = $8
set plim = 45
set clim = 30
set int = .25
set flux = `grep -i $cal $MIRCAT/ata/cals.list | awk '{print $6}'`
rm -f $cal.calrpt
if (`echo $flux | wc -w` == 0) set flux = 1

set minflux = `echo $flux .666 | awk '{print $1*$2}'`
set maxflux = `echo $flux 1.333 | awk '{print $1*$2}'`
set lflux = `echo $flux .5 | awk '{print $1*$2}'`
set hflux = `echo $flux 1.5 | awk '{print $1*$2}'`
set uflux = `echo $flux 2 | awk '{print $1*$2}'`
echo $flux $uflux $hflux $lflux $maxflux $minflux

set ofilelist = `du $pfx*$sfx | awk '{print $2}'`

# It's okay if this throws an error on an offsite install of MIRIAD
cp ~/bin/olays/$olay$cal.olay olay

#if (-e rfi.totallog) goto norfi

#rfi.obscheck $freq

#norfi:
echo "Cal is $cal - flux is $flux"
set rcount = 0
set iccount
set ibcount
set fbcount
set fccount

foreach file (`echo $ofilelist`)
uvaver vis=$file select='window(1),pol(xx,yy),-auto' line=chan,824,100 interval=$int out=$file.temp options=nocal,nopass,nopol
set count = `uvlist vis=$file.temp recnum=0 select='window(1),-auto' | grep -v CHAN | grep ":" | grep -v "e" | wc -l| awk '{print $1}'`
set rcount = `calc $rcount+$count`
set iccount = ($iccount $count)

set bcount = `uvplt vis=$file.temp options=2pass select=-auto device=/null | grep Baseline | wc -l`
set ibcount = ($ibcount $bcount)
uvplt vis=$file.temp select=-auto select='pol(xx)' device=/null options=2pass | grep Baseline | tr "-" " " | awk '{print " "$2"X-"$3"X",$5}' > $file.ibaselist
uvplt vis=$file.temp select=-auto select='pol(yy)' device=/null options=2pass | grep Baseline | tr "-" " " | awk '{print " "$2"Y-"$3"Y",$5}' >> $file.ibaselist

cat $file.ibaselist | tr "-" " "| awk '{print $1}' > temp
cat $file.ibaselist | tr "-" " "| awk '{print $2}' >> temp
sort -u temp | sort -n > $file.antlist
end

set filelist = `du $pfx*$sfx.temp | awk '{print $2}'`

foreach file (`echo $filelist`)
@ fidx++
jumper:
echo $file
if (-e refants) then
echo "Refants found!"
set antlist = (`cat refants`)
set refant = $antlist[$fidx]
echo "$refant selected."
else
set refant = `mselfcal vis=$file options=amp,noscale flux=$flux interval=30 refant=0 | grep Antenna | grep 0.00 | awk -F a '{print $2}'| awk '{print $1}'`
endif

if (`echo $refant| wc -w` != 0) mfcal vis=$file refant=$refant options=interpolate minants=4 flux=$flux,1.420,0 interval=30

uvaver vis=$file out=cal.temp options=relax

uvlist vis=cal.temp options=stat recnum=0 | grep -v CHAN | grep ":" | grep -v "e" | awk '{if ($7>uflux) print $1}' uflux=$uflux| awk '{print "R",NR,$1}' > amps

if (`cat amps| wc -w` == 0) then

uvlist vis=cal.temp options=stat recnum=0 | grep -v CHAN | grep ":" | grep -v "e" | awk '{if ($7>hflux) print $1}' hflux=$hflux| awk '{print $1}' > lamps
uvlist vis=cal.temp options=stat recnum=0 | grep -v CHAN | grep ":" | grep -v "e" | awk '{if ($7<lflux) print $1}' lflux=$lflux| awk '{print $1}' > hamps
cat lamps hamps | awk '{print "R",NR,$1}' > amps
endif


    set idx=0
    set llim=0
    set ulim=101
    set lim = `cat amps | wc -l`
    echo "$lim amp records to flag."
    if (`cat amps| wc -w` == 0) set idx = 1
    echo "Round 0 of flagging"
    while ($idx == 0)
    set flags = `awk '{if ($2>llim) print $0}' llim=$llim amps | awk '{if ($2<ulim) printf "%s","vis("$3"),"}' ulim=$ulim`
    uvflag vis=$file flagval=f options=none select=$flags

    if (`grep "R $ulim " amps | wc -l ` == 0) set idx = 2
    set llim = `calc -i 100+$llim`
    set ulim = `calc -i 100+$ulim`
    end
rm -r cal.temp
if ($idx == 2) then
uvaver vis=$file options=nocal,nopass,nopol out=cal.temp > dump
gpcopy vis=$file out=cal.temp > dump
rm -r $file
mv cal.temp $file
endif
if ($idx == 2) goto jumper
eprms.csh $file $plim $clim report


set check = `wc -w sel.$file | awk '{print $1}'`
echo $check
if ($check != 0) uvflag vis=$file select=`cat sel.$file` flagval=f options=none
if ($check != 0) goto jumper

end
nophase:
rm sel*

foreach file (`echo $ofilelist`)
puthd in=$file.temp/interval value=.021
gpcopy vis=$file.temp out=$file

set count = `uvlist vis=$file.temp recnum=0 select='window(1),-auto' | grep -v CHAN | grep ":" | grep -v "e" | wc -l| awk '{print $1}'`
set fccount = ($fccount $count)
set bcount = `uvplt vis=$file.temp select=-auto device=/null options=2pass | grep Baseline | wc -l`
set fbcount = ($fbcount $bcount)

uvplt vis=$file.temp select='pol(xx),-auto' device=/null options=2pass | grep Baseline | tr "-" " " | awk '{print " "$2"X-"$3"X",$5}' > $file.fbaselist
uvplt vis=$file.temp select='pol(yy),-auto' device=/null options=2pass | grep Baseline | tr "-" " " | awk '{print " "$2"Y-"$3"Y",$5}' >> $file.fbaselist
rm -f $file.badbase | touch $file.badbase
    foreach base (`cat $file.ibaselist | awk '{print $1}'`)
    set ipts = `grep " $base" $file.ibaselist | awk '{print $2}'`
    set fpts = " "`grep " $base" $file.fbaselist | awk '{print $2}'`
    if (`echo $fpts | wc -w | awk '{print $1}'` != 0) then
    set pct = `echo $fpts $ipts | awk '{print 100*$1/$2}' | tr "." " " | awk '{print $1}'`
	echo " $base --- $fpts out of $ipts spectra preserved ($pct%)" >> $file.rpttemp
    else
    set fpts = 0
    echo $base >> $file.badbase 
    echo " $base --- $fpts out of $ipts spectra preserved (0%)" >> $file.rpttemp
    endif
    end
end

rm -rf tot$sfx
uvaver vis='*.temp' out=tot$sfx #options=nocal,nopass,nopol

echo "The last flag!"

set sel = "amp($uflux)"
uvflag vis=tot$sfx flagval=f select=$sel options=none

uvlist vis=tot$sfx options=stat recnum=0 | grep -v CHAN | grep ":" | grep -v "e" | awk '{if ($7>maxflux) print $1}' maxflux=$maxflux| awk '{print $1}' > lamps
uvlist vis=tot$sfx options=stat recnum=0 | grep -v CHAN | grep ":" | grep -v "e" | awk '{if ($7<minflux) print $1}' minflux=$minflux| awk '{print $1}' > hamps
cat lamps hamps | awk '{print "R",NR,$1}' > amps

    set idx=0
    set llim=0
    set ulim=101
    set lim = `cat amps | wc -l`
    echo "$lim amp records to flag."
    if (`cat amps| wc -w` == 0) set idx = 1
    echo "Round 2 of flagging (Fight!)"
    while ($idx == 0)
    set flags = `awk '{if ($2>llim) print $0}' llim=$llim amps | awk '{if ($2<ulim) printf "%s","vis("$3"),"}' ulim=$ulim`
    uvflag vis=tot$sfx flagval=f options=none select=$flags
    echo $llim $lim
    if (`grep "R $ulim " amps | wc -l` == 0) set idx = 2
    set llim = `calc -i 100+$llim`
    set ulim = `calc -i 100+$ulim`
    end

    automap.csh tot$sfx $mapskip $maplflux $maphflux
echo "Cal is $cal - flux is $flux" >> tot$sfx.imgrpt
rm -rf *.temp
rm -f amps
rm -f dump

report:

set scount = `uvlist vis=tot$sfx options=stat recnum=0 select=-auto | grep -v CHAN | grep ":" | grep -v "e" | wc -l| awk '{print $1}'`

echo "Calcal summary for $cal data" >> $cal.calrpt
echo "------------------------------------------------" >> $cal.calrpt
echo "$scount out of $rcount records left in image. (`calc -i 100'*'$scount/$rcount`%)" >> $cal.calrpt
echo " " >> $cal.calrpt
set idx = 0
foreach file (`echo $ofilelist`)
@ idx++
set bpct = `echo $fbcount[$idx] $ibcount[$idx] | awk '{print 100*$1/$2}' | tr "." " " | awk '{print $1}'` >> $cal.calrpt
set cpct = `echo $fccount[$idx] $iccount[$idx] | awk '{print 100*$1/$2}'| tr "." " " | awk '{print $1}'` >> $cal.calrpt
echo "Correlator file - $file" >> $cal.calrpt
echo "--------------------------------------------------------------------" >> $cal.calrpt
echo " $fbcount[$idx] out of $ibcount[$idx] baselines preserved ($bpct%)" >> $cal.calrpt
echo " $fccount[$idx] out of $iccount[$idx] spectra preserved ($cpct%)" >> $cal.calrpt
echo "--------------------------------------------------------------------" >> $cal.calrpt
echo " " >> $cal.calrpt
echo "The following baselines in this file were not preserved (0% spectra):" >> $cal.calrpt
set badlist = `cat $file.badbase`
echo $badlist | tr " " "," >> $cal.calrpt
echo " "  >> $cal.calrpt
echo "Antenna Counts" >> $cal.calrpt
echo "-------------------------"  >> $cal.calrpt
    foreach antpol (`cat $file.antlist`)
    set antcount = `cat $file.badbase | tr "-" " "| awk '{print " "$1" "$2}' | grep " $antpol " | wc -l | awk '{print $1}'`
    if ($antcount != 0) echo "$antpol --- $antcount affected baseline(s)" >> $cal.calrpt
    end
echo " "  >> $cal.calrpt
end
echo " " >> $cal.calrpt
echo "END SUMMARY" >> $cal.calrpt
echo "Full listing" >> $cal.calrpt
foreach file (`echo $ofilelist`)
echo "Listing for $file" >> $cal.calrpt
echo "--------------------------------------------------------------" >> $cal.calrpt
cat $file.rpttemp >> $cal.calrpt
end
finish:
rm *.antlist *.ibaselist *.fbaselist *.badbase *.rpttemp
exit 0 
