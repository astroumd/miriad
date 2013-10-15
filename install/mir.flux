#! /bin/csh -f
#
#  mir.flux      run standard flux cal test suite for CARMA
#
#
set tmp=flux$$
mkdir $tmp
cd $tmp

set ftp=ftp://ftp.astro.umd.edu/pub/carma/data/
set flux=flux_test.miriad.tar.gz

set keep=1
set marstb=1

foreach a ($*)
  set $a
end

set targz=$MIR/data/$flux


if (-e $targz) then
  echo Using local copy $targz 
  tar zxf $targz
else
  echo Grabbing remote copy $ftp/$flux
  wget $ftp/$flux
  if ($status) then
    echo No wget ... Trying curl $ftp/$flux
    curl $ftp/$flux | tar zxf -
  else
    tar zxf $flux
  endif
  if ($keep) cp $flux $MIR/data
endif

set vis=$flux:r:r

if (! -d $vis) then
  echo Missing flux dataset $vis
  exit 1
endif

echo Running fluxtest:

echo $MIR/src/scripts/fluxtest vis=$vis '$*' > runme
chmod +x runme
./runme marstb=$marstb >& fluxtest.log

echo Logfile in $tmp/fluxtest.log

grep "should be" fluxtest.log  |  awk '{if ($2-$10 != 0) print "BAD BOOTFLUX ",NR,$0}'
