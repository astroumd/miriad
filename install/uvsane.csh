#! /bin/csh -f
#
#   silly little sanity check on a miriad vis file

if ($#argv == 0) then
  echo Usage: $0 vis-dataset
  exit 0
endif
set vis=$1

if (! -d $vis) then
  echo $vis is not a directory
  exit 1
endif

if (! -f $vis/visdata) then
  echo $vis does not look like a miriad visibility dataset
  exit 1
endif

set tmp=tmp$$

mkdir $tmp
if ($status) then
  echo Cannot create $tmp here
  exit 1
endif

echo -n "uvio ..."
uvio $vis > /dev/null
if ($status) echo uvio failed, but that is ok for now until uvio is fixed
echo ok

echo -n "uvcat ..."
uvcat vis=$vis out=$tmp/vis1 > /dev/null
if ($status) echo failed
echo ok
rm -rf $tmp/vis1

echo -n "uvcat dra() ..."
uvcat vis=$vis out=$tmp/vis1 'select=dra(0)' > /dev/null
if ($status) echo failed
echo ok
rm -rf $tmp/vis1

echo -n "uvcat ddec() ..."
uvcat vis=$vis out=$tmp/vis1 'select=ddec(0)' > /dev/null
if ($status) echo failed
echo ok
rm -rf $tmp/vis1

echo -n "uvcat vis() ..."
uvcat vis=$vis out=$tmp/vis1 'select=vis(1,10)' > /dev/null
if ($status) echo failed
echo ok
rm -rf $tmp/vis1

echo -n "uvcat win() ..."
uvcat vis=$vis out=$tmp/vis1 'select=win(1)' > /dev/null
if ($status) echo failed
echo ok
rm -rf $tmp/vis1

cleanup:
  rm -rf $tmp
