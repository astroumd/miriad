#!/bin/sh
# Note : this installer assumes you have miriad installed on your system
# This takes 2 arguments: the location of your miriad installation
#                         the operating system
# e.g. build_python.sh /home/x/miriad linux
#
# See the README file for a full description
#
# Some parts of this script have been borrowed from the swig installation
#  script
# History
# 02jul10 dnf initial version
###########################################################################

hosttype=$2
MIRTMP="$1/tmp/miriadwrap.$$.$hosttype"
MIRBIN="$1/bin/$hosttype"
MIRSUBS="$1/src/subs"
MIRINC="$1/src/inc"
MIRLIB="$1/lib/$hosttype"

as_nl='
'
IFS=" ""	$as_nl"

as_me="config"
as_cr_letters='abcdefghijklmnopqrstuvwxyz'
as_cr_LETTERS='ABCDEFGHIJKLMNOPQRSTUVWXYZ'
as_cr_Letters=$as_cr_letters$as_cr_LETTERS
as_cr_digits='0123456789'
as_cr_alnum=$as_cr_Letters$as_cr_digits

if test "${PATH_SEPARATOR+set}" != set; then
    echo "#! /bin/sh" >conf$$.sh
    echo  "exit 0"   >>conf$$.sh
    chmod +x conf$$.sh
    if (PATH="/nonexistent;."; conf$$.sh) >/dev/null 2>&1; then
	PATH_SEPARATOR=';'
    else
	PATH_SEPARATOR=:
    fi
    rm -f conf$$.sh
fi
for as_dir in $PATH
do
    IFS=$as_save_IFS
    test -z "$as_dir" && as_dir=.
  # Account for people who put trailing slashes in PATH elements.
    case $as_dir/ in
	./ | .// | /cC/* | \
	    /etc/* | /usr/sbin/* | /usr/etc/* | /sbin/* | /usr/afsws/bin/* | \
	    ?:\\/os2\\/install\\/* | ?:\\/OS2\\/INSTALL\\/* | \
	    /usr/ucb/* ) ;;
	*)
    # OSF1 and SCO ODT 3.0 have their own names for install.
    # Don't use installbsd from OSF since it installs stuff as root
    # by default.
	    for ac_prog in ginstall scoinst install; do
		for ac_exec_ext in '' $ac_executable_extensions; do
		    if { test -f "$as_dir/$ac_prog$ac_exec_ext" && $as_test_x "$as_dir/$ac_prog$ac_exec_ext"; }; then
			if test $ac_prog = install &&
			    grep dspmsg "$as_dir/$ac_prog$ac_exec_ext" >/dev/null 2>&1; then
	    # AIX install.  It has an incompatible calling convention.
			    :
			elif test $ac_prog = install &&
			    grep pwplus "$as_dir/$ac_prog$ac_exec_ext" >/dev/null 2>&1; then
	    # program-specific install script used by HP pwplus--don't use.
			    :
			else
			    ac_cv_path_install="$as_dir/$ac_prog$ac_exec_ext -c"
			    break 3
			fi
		    fi
		done
	    done
	    ;;
    esac
done
IFS=$as_save_IFS

# test if we are running 32 or 64 bit
SFBIT=1
echo "$as_me:$LINENO: testing for 64 bit kernel"
if uname -a | grep -q x86_64; then
    echo "$as_me:$LINENO: result: yes"
    SFBIT=0
else
    if uname -a | grep -q ppc64; then
	echo "$as_me:$LINENO: result: yes"
	SFBIT=0
    else
	echo "$as_me:$LINENO: result: no"
    fi
fi

for ac_prog in python python2.8 python2.7 python2.6 python2.5 python2.4 python2.3 python2.2 python2.1 python2.0 python1.6 python1.5 python1.4 python
do
  # Extract the first word of "$ac_prog", so it can be a program name with args.
    set dummy $ac_prog; ac_word=$2
    echo "$as_me:$LINENO: checking for $ac_word"
    as_save_IFS=$IFS; IFS=$PATH_SEPARATOR
    for as_dir in $PATH
    do
	IFS=$as_save_IFS
	test -z "$as_dir" && as_dir=.
	for ac_exec_ext in '' $ac_executable_extensions; do
	    if test -f "$as_dir/$ac_word$ac_exec_ext"; then
		ac_cv_prog_PYTHON="$ac_prog"
		echo "$as_me:$LINENO: found $as_dir/$ac_word$ac_exec_ext"
		break 2
	    fi
	done
    done
    IFS=$as_save_IFS
    
    PYTHON=$ac_cv_prog_PYTHON
    if test -n "$PYTHON"; then
	echo "$as_me:$LINENO: result: $PYTHON"
    else
	echo "$as_me:$LINENO: result: no"
	echo "Please install Python"
	exit
    fi
    
    test -n "$PYTHON" && break
done

for ac_prog in swig swig1.0 swig1.1 swig1.2 swig1.3 swig-1.0 swig-1.1 swig-1.2 swig-1.3 swig-1.4 swig
do
  # Extract the first word of "$ac_prog", so it can be a program name with args.
    set dummy $ac_prog; ac_word=$2
    echo "$as_me:$LINENO: checking for $ac_word"
    as_save_IFS=$IFS; IFS=$PATH_SEPARATOR
    for as_dir in $PATH
    do
	IFS=$as_save_IFS
	test -z "$as_dir" && as_dir=.
	for ac_exec_ext in '' $ac_executable_extensions; do
	    if test -f "$as_dir/$ac_word$ac_exec_ext"; then
		ac_cv_prog_SWIG="$ac_prog"
		echo "$as_me:$LINENO: found $as_dir/$ac_word$ac_exec_ext"
		break 2
	    fi
	done
    done
    IFS=$as_save_IFS

    SWIG=$ac_cv_prog_SWIG
    if test -n "$SWIG"; then
	echo "$as_me:$LINENO: result: $SWIG"
    else
	echo "$as_me:$LINENO: result: no"
	echo "SWIG needs to be installed or is not in your path, it is a free download from the web"
	echo "     www.swig.org"
	echo "This software is known to work with swig 1.3.35"
	exit
    fi
    
    test -n "$SWIG" && break
done

echo "$as_me:$LINENO: checking for Python prefix"
PYPREFIX=`($PYTHON -c "import sys; print sys.prefix") 2>/dev/null`
echo "$as_me:$LINENO: result: $PYPREFIX"
echo "$as_me:$LINENO: checking for Python exec-prefix"
PYEPREFIX=`($PYTHON -c "import sys; print sys.exec_prefix") 2>/dev/null`
echo "$as_me:$LINENO: result: $PYEPREFIX"


echo "$as_me:$LINENO: checking for Python version"

filehack="file__"
PYVERSION=`($PYTHON -c "import string,operator,os.path; print operator.getitem(os.path.split(operator.getitem(os.path.split(string.__$filehack),0)),1)")`
echo "$as_me:$LINENO: result: $PYVERSION"

    # Find the directory for libraries this is necessary to deal with
    # platforms that can have apps built for multiple archs: e.g. x86_64
echo "$as_me:$LINENO: checking for Python lib dir"
PYLIBDIR=`($PYTHON -c "import sys; print sys.lib") 2>/dev/null`
STATIC=0
if test -z "$PYLIBDIR"; then
      # older versions don't have sys.lib  so the best we can do is assume lib
    #PYLIBDIR="lib"
    if test -r /lib64/lib$PYVERSION.so; then
	    PYLIBDIR="/lib64"
    elif test -r /lib64/lib$PYVERSION.a; then
	    PYLIBDIR="/lib64"
	    STATIC=1
    elif test -r /usr/lib64/lib$PYVERSION.so; then
	    PYLIBDIR="/usr/lib64"
    elif test -r /usr/lib64/lib$PYVERSION.a; then
	    PYLIBDIR="/usr/lib64"
	    STATIC=1
    elif test -r /usr/local/lib64/lib$PYVERSION.so; then
	    PYLIBDIR="/usr/local/lib64"
    elif test -r /usr/local/lib64/lib$PYVERSION.a; then
	    PYLIBDIR="/usr/local/lib64"
	    STATIC=1
    elif test -r /lib/lib$PYVERSION.so; then
	    PYLIBDIR="/lib"
    elif test -r /lib/lib$PYVERSION.a; then
	    PYLIBDIR="/lib"
	    STATIC=1
    elif test -r /usr/lib/lib$PYVERSION.so; then
	    PYLIBDIR="/usr/lib"
    elif test -r /usr/lib/lib$PYVERSION.a; then
	    PYLIBDIR="/usr/lib"
	    STATIC=1
    elif test -r /usr/local/lib/lib$PYVERSION.so; then
	    PYLIBDIR="/usr/local/lib"
    elif test -r /usr/local/lib/lib$PYVERSION.a; then
	    PYLIBDIR="/usr/local/lib"
	    STATIC=1
    else
	    PYLIBDIR="lib"
    fi
fi
echo "$as_me:$LINENO: result: $PYLIBDIR"
echo "$as_me:$LINENO: checking if static linking is needed"
if [ $STATIC == 0 ]; then
    echo "$as_me:$LINENO: result: no"
else
    echo "$as_me:$LINENO: result: yes"
fi

    # Set the include directory

echo "$as_me:$LINENO: checking for Python header files"
if test -r $PYPREFIX/include/$PYVERSION/Python.h; then
    PYINCLUDE="-I$PYPREFIX/include/$PYVERSION"
fi
if test -z "$PYINCLUDE"; then
    if test -r $PYPREFIX/include/Py/Python.h; then
        PYINCLUDE="-I$PYPREFIX/include/Py -I$PYEPREFIX/$PYLIBDIR/python/lib"
    fi
fi
echo "$as_me:$LINENO: result: $PYINCLUDE"

# test what version of f2c we are using
echo "$as_me:$LINENO: testing for f2c"
F2CARG=""
F2CPRE=""
F2CLIB=""
if f2c test.F; then
    echo "$as_me:$LINENO: result: found"
    echo "$as_me:$LINENO: checking for need for -K flag in f2c"
    if f2c -K test.F; then
	    F2CARG="-K"
	    echo "$as_me:$LINENO: result: needed"
    else
	    echo "$as_me:$LINENO: result: not needed"
    fi
else
    echo "$as_me:$LINENO: result: not found"
    echo "   installing the included versions"
    tar zxvf f2c.tar.gz
    tar zxvf libf2c.tar.gz
    cd f2c
    make -f makefile.u
    mv f2c $MIRBIN/.
    cp f2c.h $MIRINC/.
    cd ../libf2c
    if test $hosttype = "darwin"; then
	    make -f makefile.osx
    else
	    make -f makefile.u
    fi
    mv libf2c.so $MIRLIB/.
    mv libf2c.a $MIRLIB/.
    cd ..
    echo "$as_me:$LINENO: checking for need for -K flag in f2c"
    if f2c -K test.F; then
	    F2CARG="-K"
	    echo "$as_me:$LINENO: result: needed"
    else
	    echo "$as_me:$LINENO: result: not needed"
    fi
fi


# test which fortran library we need
FORLIB=""
echo "$as_me:$LINENO: testing for which fortran library is needed"
if ldd $MIRBIN/listobs | grep -q gfortran; then
    echo "$as_me:$LINENO: result: gfortran"
    FORLIB="gfortran"
elif ldd $MIRBIN/listobs | grep -q g2c; then
    echo "$as_me:$LINENO: result: g2c"
    FORLIB="g2c"
else
    echo "$as_me:$LINENO: result: ERROR"
fi

echo "Precompiling fortran code"
for file in align calio deghms hann medfit pb refract tangle varmint amphase callinp ephem hdtab median pcvt rest velocity angles calphase expun headcopy lagwt mem pghline rtfmt title versan antennas calpoly fftsubs hisinput linetype model pkfit select calsetio fitsio hsort log modp plane sfetra wpfit calstoke fndaxnum imminmax lsearch mostab planet shadowed zed calsubs fullname inc lsf nearest plotone si tvsubs zeebin assert gamma intpio lspoly nextpow2 plproc sma_fsubs atjones gaupar iscoords lsqfit nllsqu pols sort utilities axistype cnvl getbeam lsqu1 noise polyfit sortidx uvdat basant co getfreq lsqu nswc poly spaxsw uvfitsubs bessel convl getpb mapper numbpg powell spline uvgetbl boxes cosubs getxy match obspar prime strf uvgn bsrch ctrl grid j1xbyx math ofm promptf string uvsubs btype defsmodl gsubs julday mc mp options tabflux var txtio keyf keyline tv
do
    $MIRBIN/ratty -s f2c -b -D $hosttype -I $MIRSUBS -I $MIRINC $MIRSUBS/$file.for $file.f >& temp
    cat temp >> $MIRTMP
    f2c $F2CARG -I$MIRSUBS -I$MIRINC $file.f >& temp
    cat temp >> $MIRTMP
done

#$MIRBIN/ratty -s f2c -b -D $hosttype -I $MIRSUBS -I $MIRINC moduvdat.for moduvdat.f >& temp
#cat temp >> $MIRTMP
#f2c $F2CARG -I$MIRSUBS -I$MIRINC moduvdat.f >& temp
#cat temp >> $MIRTMP



rm temp

echo "Building c wrappers"
for i in iface wrap xyziowrap bugwrap keywrap packwrap tcpio oscalls mm hio3
do
    $MIRBIN/intf2c -s f2c $MIRSUBS/$i.f2c $i.c
done

cp $MIRSUBS/*.c .
cp $MIRSUBS/pybug.cc ./pybug.c
rm dirs.c
rm -f bug.c

echo "Build swig interface module"
$SWIG -python miriadwrap.i

echo "Compiling..."

if [ $SFBIT == 0 ]; then
    gcc -m64 -c -O -fPIC -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -I$MIRINC -I$MIRSUBS -I$MIRINC -I$MIRSUBS $PYINCLUDE *.c >& temp
else
    gcc -c -O -fPIC -fno-second-underscore  -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -I$MIRINC -I$MIRSUBS -I$MIRINC -I$MIRSUBS $PYINCLUDE *.c >& temp
fi
cat temp >> $MIRTMP

echo "Linking..."
if test $hosttype = "darwin"; then
    gcc  -bundle -flat_namespace -undefined suppress -o _miriad_io.so *.o
else
    if [ $SFBIT == 0 ]; then
    #ld -mi386linux -L/usr/lib -L/home/friedel/miriad/lib/32bit -shared *.o -o _miriad_io.so -L$MIRLIB -lf2c -llinpack -lpgplot -lgfortran -lX11 >& temp
	    ld -melf_x86_64 -shared *.o -o _miriad_io.so -L$MIRLIB -lf2c -lwcs -llinpack -lpgplot -l$FORLIB -lX11 >& temp
    else
	    ld -shared *.o -o _miriad_io.so -L$MIRLIB -lf2c -llinpack -lwcs -lpgplot -l$FORLIB -lX11 >& temp
    fi
    cat temp >> $MIRTMP
fi

rm -f *.o #*.c *.o #*.f

# BUILD MXTOOLS
echo "Building mxTools"
cd mx
if [ $SFBIT == 0 ]; then
    gcc -m64 -pthread -fno-strict-aliasing -DNDEBUG -O2 -fmessage-length=0 -D_FORTIFY_SOURCE=2 -g -fPIC -DHAVE_STRPTIME=1 -I/. $PYINCLUDE -c mxTools.c -o mxTools.o >& temp
else
    gcc -pthread -fno-strict-aliasing -DNDEBUG -O2 -fmessage-length=0 -D_FORTIFY_SOURCE=2 -fstack-protector -g -fPIC -DHAVE_STRPTIME=1 -I/. $PYINCLUDE -c mxTools.c -o mxTools.o >& temp
fi
cat temp >> $MIRTMP

if [ $SFBIT == 0 ]; then
    if [ $STATIC == 0 ]; then
	ld -melf_x86_64 -shared mxTools.o -l$PYVERSION -o mxTools.so >& temp
    else
	ld -melf_x86_64 -static mxTools.o -l$PYVERSION -o mxTools.so >& temp
    fi
else
    if [ $STATIC == 0 ]; then
	gcc -shared mxTools.o -l$PYVERSION -o mxTools.so >& temp
    else
	gcc -static mxTools.o -l$PYVERSION -o mxTools.so >& temp
    fi
fi
cat temp >> $MIRTMP

echo "Installing in $MIRLIB/python"
if test -e "$MIRLIB/python"; then
    echo "" > /dev/null
else
    mkdir $MIRLIB/python
fi
mv mxTools.so $MIRLIB/python/.
rm -f *.o temp
cd ..
mv miriad_io.py $MIRLIB/python/.
mv _miriad_io.so $MIRLIB/python/.
cp miriadwrap.py $MIRLIB/python/.
cp README $MIRLIB/python/.
rm -f temp

echo "Installation complete. In python import the miriadwrap module and be sure $MIRLIB/python is in your python path"
