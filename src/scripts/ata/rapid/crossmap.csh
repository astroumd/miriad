#! /usr/bin/tcsh -f
#
# $Id$
#

cp ~/bin/olays/olay olay
set cal = $1
set vis = $2
set marker = $3
set freq = $4
set line = $5
set mapskip = $6
set maplflux = $7
set maphflux = $8
set mapfflux = $9
set autocmd = $10
set sflag = $11

set flux = `grep -i $vis ${MIRCAT}/ata/cals.list | awk '{print $6}'`
set flux = "unknown"
set uflux = 1000
set hflux = 500
set lflux = 0

rm -rf *.temp

onintr finish

if (-e tot-$cal-$freq) goto beenthere
echo "Must run calcal.csh first!"
goto finish

beenthere:

cp ~/bin/olays/olay .

set calfilelist = `du *$cal*/visdata | grep $marker | tr "/" " " | awk '{print $2}'`
set visfilelist = `du *$vis*/visdata | grep $marker | tr "/" " " | awk '{print $2}'`

rm -rf temp 
foreach file (`echo $visfilelist`)


cat $cal.calrpt | grep " --- " | grep "spectra preserved (0%)" | awk '{print $1}' | grep X | tr 'X-' ' ' | awk '{print "ant("$1")("$2"),pol(xx)"}' > badbase

cat $cal.calrpt | grep " --- " | grep "spectra preserved (0%)" | awk '{print $1}' | grep Y | tr 'Y-' ' ' | awk '{print "ant("$1")("$2"),pol(yy)"}' >> badbase

echo "Flagging bad baselines!"
foreach baseline (`cat badbase`)
echo "Flagging $baseline"
uvflag vis=$file flagval=f options=none select=$baseline
end

rm badbase

cp $file/bandpass visgains/$file.bandpass
cp $file/gains visgains/$file.gains
#uvflag vis=$file flagval=u options=none line=chan,80,380
uvaver vis=$file out=$file.temp select='window(1),-auto' options=nocal,nopol,nopass interval=.5

end

set idx=0
foreach file (`echo $calfilelist`)
@ idx++
puthd in=$file/interval value=1
gpcopy vis=$file out=$visfilelist[$idx].temp
puthd in=$file/interval value=.021
end

foreach file (`echo $visfilelist`)
cp visgains/$file.bandpass $file/bandpass
cp visgains/$file.gains $file/gains
end 

set templist = `du *$vis*.temp/visdata | tr "/" " " | awk '{print $2}'`
set list = `echo $templist | tr " " ","`
echo $list

set catfile = comb-$vis
rm -rf $catfile
uvaver vis=$list select='window(1),-auto' out=$catfile

rm -rf *.temp

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
uvflag vis=$catfile flagval=f options=none line=$line
set fsel = "amp($mapfflux)"
uvflag vis=$catfile flagval=f options=none select=$fsel 
automap.csh $catfile $mapskip $maplflux $maphflux $autocmd $sflag
uvflag vis=$catfile flagval=u options=none line=$line
rm -rf $catfile-spec*
set fsel = "amp($mapfflux)"
uvaver vis=$catfile out=$catfile-spec options=relax,nocal,nopol,nopass
gpcopy vis=$catfile out=$catfile-spec

uvflag vis=$catfile flagval=f options=none line=$line

if (`cat amplog | wc -w` == 0) echo "No flagging neccessary"
if (`cat amplog | wc -w` == 0) goto noflag
set llim=0
set ulim=101
set lim = `cat amplog | wc -l`
echo "$lim records to flag."
set fidx = 0
    while ($fidx == 0)
    set flags = `awk '{if ($2>llim) print $0}' llim=$llim amplog | awk '{if ($2<ulim) printf "%s","vis("$3"),"}' ulim=$ulim`
    uvflag vis=$catfile-spec flagval=f options=none select=$flags
    echo $llim $lim
    if (`grep "R $ulim " amplog | wc -l ` == 0) set fidx = 2
    set llim = `calc -i 100+$llim`
    set ulim = `calc -i 100+$ulim`
    end

noflag:

uvflag vis=$catfile-spec flagval=f options=none select=$fsel 



invert vis=$catfile-spec line=$line options=double sup=0 cell=30 imsize=512 map=$catfile-spec.mp beam=$catfile-spec.bm select='-shadow(7.5)'
clean map=$catfile-spec.mp beam=$catfile-spec.bm out=$catfile-spec.cl
restor map=$catfile-spec.mp beam=$catfile-spec.bm model=$catfile-spec.cl out=$catfile-spec.cm
#cp ~/bin/olays/olay .
#moment in=$catfile-spec.cm mom=0 out=$catfile-spec.mom0
#cgdisp in=$catfile-spec.mom0 device=/xs nxy=3,3 range=0,0,lin,3 region=relcen,arcsec,box"(-5000,-5000,5000,5000)" labtyp=hms options=wedge,full,beambl

finish:
rm -rf visgains
#rm -rf $catfile
rm -rf $catfile.map $catfile.beam $catfile.rs rpt.temp crosscal* temp

exit 0
