#! /bin/bash
#
#  new V6.0+ install
#

echo "install_miriad.sh:  Version 1.0 -- 2-apr-2025"

miriad=miriad
branch=master
opt=1           # TBD
python=0        # TBD
pgplot=0        # 0: borrow from system    1: build from our source
url=https://github.com/astroumd/miriad

help() {
    echo This is a simple install script for MIRIAD
    echo Optional parameters are key=val, defaults are:
    echo
    echo opt=$opt
    echo miriad=$miriad
    echo branch=$branch
    echo python=$python
    echo url=$url
}


for arg in $*; do\
  if test $arg == --help || test $arg == -h; then
    help
    exit 0
  fi
  export $arg
done

echo "Using: "
echo "  miriad=$miriad"
echo "  branch=$branch"
echo "  opt=$opt"
echo "  pgplot=$pgplot"
echo "  python=$python"
echo "  url=$url"
echo ""

# safety
if [ -d $miriad ]; then
    echo Sleep 5 seconds before removing miriad=$miriad ....
    sleep 5
else
    echo Installing MIRIAD in a new directory $miriad
fi    

date0=$(date)

if [ $miriad == "." ]; then
    if [ -d .git ]; then
	git pull
    else
	echo Not a miriad with git?
	exit 0
    fi
else
    rm -rf $miriad
    git clone $url $miriad
    cd $miriad
    git checkout $branch
fi

#      default use the GNU compiler
#      @todo some tools don't listen to this yet 
export F77=${F77:-gfortran}
export  FC=${FC:-gfortran}
export  CC=${CC:-gcc}
export CXX=${CXX:-g++}

# if (-e  $rootdir/src/tools/ercmd.c) rm $rootdir/src/tools/ercmd.c
time install/install.miriad gfortran=1  generic=1 gif=1 pgplot=$pgplot telescope=carma


#    patch the VERSION
version=$(cat VERSION)
echo "$version - [automated build `date`]" > VERSION



date1=$(date)

echo "Started: $date0"
echo "Ended:   $date1"

echo All done.
echo ""
echo "(ba)sh users:  source $miriad/miriad_start.sh  to activate MIRIAD in your shell"
echo "(t)csh users:  source $miriad/miriad_start.csh to activate MIRIAD in your shell"

