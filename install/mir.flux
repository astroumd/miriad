#! /bin/csh -f
#
#  mir.flux      run standard flux cal test suite for CARMA
#
#
set tmp=flux$$
mkdir $tmp
cd $tmp

set ftp=ftp://ftp.astro.umd.edu/pub/carma/data/
set flux=flux.mirtest.tar.gz

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

