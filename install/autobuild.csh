#! /bin/csh -f
#
#  simple script that can be called from a crontab, some of the variables
#  here are very Maryland specific
#  Requirements:
#    - a baseline <name>.tar.gz file, created from CVS
#    - a timestamp file, created via  "date > LastBuild"
#    - this script, autobuild.csh
#    - an optional branch name
#
# $Id$

#   choose miriad or miriad5
set name=miriad
set sleep=0
set force=0
set dir=/chara/teuben/redo_miriad/autobuild

foreach arg ($*)
  set $arg
end

if (! -e $dir) then
  echo Directory dir=$dir does not exist
  exit 1
endif


start:

cd $dir

set targz=$name.tar.gz

if (! -e $targz) then
  echo $0 : $targz not found
  exit 1
endif

rm -rf $name
tar zxf $targz
(echo updating with cvs;cd $name; cvs -q up -dP) >& LastBuild.cvsup.log
find $name -type f -newer LastBuild | grep -v CVS/Entries > LastBuild.newfiles
date > LastBuild.new

if (-z LastBuild.newfiles) then
  if ($force == 1) then
    echo No new source code in $name since `cat LastBuild`
    echo But building anyways....
  else
    goto last_check
  endif
endif

echo Files updated since `cat LastBuild`
cat LastBuild.newfiles


echo Now rebuilding
tar zcf $targz.new $name
# cp $name/install/test_a_new_miriad_cvs .
if (0) then
    # default gcc 3.4.1 doesn't compile falcON, so use 3.4.3 for now
    source /n/astromake2/astromake_start
    astroload gcc
endif
./test_a_new_miriad_cvs rootdir=$name reuse=1 >& LastBuild.log

if (! -d logs) mkdir logs
foreach file (LastBuild.log LastBuild.newfiles autobuild.csh $name/tmp/*.log)
     set dest=$file:t
     cp $file logs/$dest.txt
end

 
if (1) then
  #  this will move over the build
  mv $targz.new $targz
  mv LastBuild.new LastBuild  
endif


last_check:


cmp -s autobuild.csh miriad/install/autobuild.csh
if ($status) then
  echo Warning: local autobuild.csh differs from $name/install/autobuild.csh
  echo dir=$dir
endif


if ($sleep) then
  sleep $sleep
  goto start
endif
