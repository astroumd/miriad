:
: change the fortran files to short names only
t=/tmp/short.$$
for f in *.f
do
  sed -e '/CEND7MAX/q' $f > $t
  mv -f $t $f
done
