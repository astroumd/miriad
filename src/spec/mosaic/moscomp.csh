#!/bin/csh -f

# lint on monet, sirius, mira, convex
# comp on monet, sirius, mira, convex
# mostest on monet, sirius, mira, convex




if ( "$1" == "help" ) then
echo 'Usage:'
echo '   cpp file  run c preprocessor on a file'
echo '   lint      run lint on the program'
echo '   intfft    compile and link in internal fft routines'
echo '             (default on mips)'
echo '   cmfft     compile and link in cm5 fft routines'
echo '             (NOT default on cm5)'
echo '   pca       on mips: precompile some files with PCA'
echo '   pcakeep   on mips: keep the intermediate PCA (.M, .L) files'
echo '             (supercedes pca)'
echo '   hippi     link in version of DTM library with HiPPI code (def on mips)'
echo '   nohippi   link in version of DTM library without HiPPI code (def else)'
echo '   debug     compile with -g to generate debugging info'
echo '   prof      compile with -p to generate profiling info'
exit
endif

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
# Get ARCH and HOST
#
# Note: not tested on cm5, might fail
# Note: not tested on hpux, but should work
#

set x = `arch |& grep not`
if ( "$x" != "" ) then
   set ARCH = `uname -m`
   set HOST = `uname -n`
else
   set ARCH = `arch `
   set HOST = `hostname | awk -F. '{print $1}'`
endif

if ( $HOST == cm5a || $HOST == cm5b || $HOST == cm5c || $HOST == cm5d ) then
set ARCH = cm5; set HOST = cm5
endif

if ( $HOST == mira ) set ARCH = sun4sol

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# FIGURE OUT FLAGS
#
# DODISKIO = "-DDODISKIO"  -> IO routines available on machine
#                             (used in _io.c)
#
# fft = "-DMIRIADFFT"      -> compile to link with miriad fft (usual default)
# fft = "-DINTERNALFFT"    -> compile internal fft routines (default on mips)
# fft = "-DCMSSLFFT"       -> compile cmssl fft routines (not default on cm5)
#                             (used in _main.c, _fft.c and _conv.c)
#
# pca     = -pca ...       -> run PCA during compilation (on mips)
# pcakeep = -pca ...       -> run PCA during compilation, keep listing (on mips)
#
# hippi = y                -> link hippi version of DTM (default on mips)
#         n                -> link standard version of DTM (default not on mips)
# DTMLIB = ...                points to directory with DTM library
# DTMINC = ...                points to directory with dtm.h
#                             (used in _dtm.c)
#
# debug = "" or "-g"       used during compilations and linking
# prof  = "" or "-p"       used during linking
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

set DOCC   = y
set DOCPP  = n
set DOLINT = n


                     set D_FFT = "-DMIRIADFFT"
 if( $ARCH == IP19 ) set D_FFT = "-DINTERNALFFT"
#if( $ARCH == IP19 ) set D_FFT = "-DPOWERFFT2D"
#if( $ARCH == cm5  ) set D_FFT = "-DCMSSLFFT"


                                set D_MAIN = "-D__main__=main"
if ( "$D_FFT" == "-DCMSSLFFT" ) set D_MAIN = "-D__main__=MAIN_"


set pca_opts = "-WK,-ro=3,-lo=ls"
set D_PCA =
set D_PCAkeep =
if ( $ARCH == IP19 ) set D_PCA = "-pca $pca_opts"


if ( $HOST != loki ) set D_DODISKIO = "-DDODISKIO"
if ( $HOST == loki ) set D_DODISKIO =
if ( $ARCH != IP19 ) set hippi = n
if ( $ARCH == IP19 ) set hippi = y


set debug =
set prof =


foreach arg ( $* )
   if ( "$arg" == "cpp"      ) set DOCPP  = y
   if ( "$arg" == "cpp"      ) set DOCC   = n
   if ( "$arg" == "lint"     ) set DOLINT = y
   if ( "$arg" == "lint"     ) set DOCC   = n

   if ( "$arg" == "intfft"   ) set D_FFT = "-DINTERNALFFT"
   if ( "$arg" == "cmfft"    ) set D_FFT = "-DCMSSLFFT"

   if ( "$arg" == "pca"      ) set D_PCA = "-pca $pca_opts"
   if ( "$arg" == "pcakeep"  ) set D_PCA = "-pca keep $pca_opts"

   if ( "$arg" == "nohippi"  ) set hippi = n
   if ( "$arg" == "hippi"    ) set hippi = y

   if ( "$arg" == "debug"    ) set debug = "-g"
   if ( "$arg" == "debug"    ) setenv MIRDEBUG
   if ( "$arg" == "prof"     ) set prof = "-p"
end


#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# FIGURE OUT WHERE DTM IS
#
# defines DTMINC  for compilation
# defines D_DTMIO for compilation 
# defines DTMLIB  for linking

if ( $HOST == monet || $HOST == loki ) then
   if ( $hippi == y ) then
      set DTM = ~jefft/dtm
      set DTMLIB = $DTM/lib
      set DTMINC = $DTM/include
   else
      if ( $HOST == monet ) set DTM = $MIR
      if ( $HOST == monet ) set OS  = /mips
      if ( $HOST == loki  ) set DTM = /afs/ncsa/packages/dtm/dtm2.4.0
      if ( $HOST == loki  ) set OS  = /sgi_52
      set DTMLIB = $DTM/lib$OS
      set DTMINC = $DTM/include
      if ( $HOST == monet ) set DTMINC = $MIR/borrow/dtm/libsrc
   endif
else
   set DTMLIB = $MIRLIB
   set DTMINC = $MIR/borrow/dtm/libsrc
endif

set D_DTMIO =
if ( -f $DTMLIB/libdtm.a ) set D_DTMIO = "-DDTMIO"


#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# GET THE COMPILER AND LOADER AND THEIR OPTIONS
#

# set machine flag
switch ( $ARCH )
case sun3:
case sun4:
              set machine = "-Dsun"; breaksw
case sun4sol:
              set machine = "-Dsun"; breaksw
case IP19:
              set machine = "-Dmips -DSYSV"; breaksw
case cm5:
              set machine = "-Dcm5"; breaksw
default:
              set machine = ""; breaksw
endsw

# set CC, LD and libs to compile properly
set dtmlib = '-L$DTMLIB -ldtm'

switch ( $ARCH )
case sun3:
case sun4:
case sun4sol:
case c38:
case hpux:
              source $MIR/src/sys/bin/compile.$MIRHOST
              set CC   = "$Ccompile $machine $Coptions"
              set LD   = "$Fcompile $debug $prof"
              set libs = "$dtmlib $Clinkdir $Clinklib"
              breaksw
case IP19:
              set CC   = "cc $machine -cckr -O $debug"
              set LD   = "f77 -pca -mp $debug $prof"
              if ( $D_DODISKIO != "" ) set mirlib = '-L$MIRLIB -lmir'
              if ( $D_DODISKIO == "" ) set mirlib =
              set libs = "$dtmlib $mirlib -lmalloc"
              if ( $D_FFT == -DPOWERFFT2D) set libs="$libs -lcomplib.sgimath_mp"
              breaksw
case cm5:
              set CC   = "cs $machine -cm5 -vu $debug"
              set LD   = "f77 -cg92 -cm5 -vu $debug $prof"
              set libs = "$dtmlib"
              breaksw
default:
              set CC   = "cc $debug"
              set LD   = "f77 $debug $prof"
              set libs = "$dtmlib"
              breaksw
endsw

# set LINT command
set LINT = "lint $machine"
switch ( $ARCH )
case sun3:
case sun4:
              set LINT = "$LINT -bchqu"; breaksw
case sun4sol:
              set LD   = "$CC $prof"
              set LINT = "$LINT -cux"; breaksw
case c38:
              set LINT = "$LINT -bhu"; breaksw
case IP19:
              set LINT = "$LINT -ux"
              breaksw
default:
              breaksw
endsw

if ( $DOCPP  == n ) set CC = "$CC -c"
if ( $DOCPP  == y ) set CC = "$CC -P"
if ( $DOLINT == y ) rm -f mosaic*.o >& /dev/null

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# COMPILE ALL INPUT FILES
#

set MOSAIC = ( mosaic*.c )
if ( $ARCH == cm5 ) then
   set MOSAIC = ( mosaic*.cs )
   if ( "$D_FFT" == "-DCMSSLFFT" ) set MOSAIC = ( mosaic*.fcm mosaic*.cs )
endif
if ( $DOCPP == y ) set MOSAIC = "$2"

foreach file ( $MOSAIC )
   set name = $file:r
   if ( -f ${name}.o ) then
      set oldobj = `find . -name ${name}.c -newer ${name}.o -print`
   else
      set oldobj = n
   endif
   if ( $DOCPP == y || "$oldobj" != "" ) then

      set parallel = ""
      if ( `echo $name | awk '{print substr($0,1,7)}'` == "mosaicP" ) \
      set parallel = "$D_PCA"

      if ( $DOLINT == y ) set COMP = "$LINT"
      if ( $DOLINT == n ) set COMP = "$CC $parallel"

      if ( $name == mosaic_main  ) set COMP = "$COMP $D_MAIN"
      if ( $name == mosaic_dtm   ) set COMP = "$COMP $D_DTMIO "-I'$DTMINC'
      if ( $name == mosaic_io    ) set COMP = "$COMP $D_DODISKIO"
      if ( $name == mosaic_fft   ) set COMP = "$COMP $D_FFT"
      if ( $name == mosaicP_conv ) set COMP = "$COMP $D_FFT"

      if ( $DOLINT == y ) then
         echo "--------------------------------------------"
         echo $COMP ${name}.c
         eval $COMP ${name}.c | grep  -v 'pointer casts may be troublesome' | \
                                grep  -v 'possible pointer alignment problem'
      else
         echo $COMP -o ${name}.o ${name}.c
         eval $COMP -o ${name}.o ${name}.c
      endif
   endif
end

if ( $DOCPP == y ) exit

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# SECOND RUN OF LINT TO FIND INCONSISTENCIES BETWEEN FILES
#

if ( $DOLINT == y ) then

set lintcmd = "$LINT $D_MAIN $D_DTMIO -I$DTMINC $D_DODISKIO $D_FFT $MOSAIC"

switch ( $ARCH )
case sun3:
case sun4:
case IP19:
   $lintcmd | egrep -v 'dprintf|assert|wwarning|DTMexchange' \
            | grep  -v 'pointer casts may be troublesome' \
            | grep  -v 'possible pointer alignment problem'
   breaksw
case c38:
   $lintcmd |& egrep -v 'dprintf|assert|wwarning|DTMexchange' \
            |  grep  -v 'hides declaration at line' \
            |  grep  -v 'but never used' \
            |  grep  -v 'but not defined' \
            |  grep  -v 'may be used before being assigned'
   breaksw
default:
   $lintcmd
   breaksw
endsw

exit
endif

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# LINK

echo "used DTM library from $DTMLIB"

echo $LD -o mosaic mosaic*.o $libs -lm
eval $LD -o mosaic mosaic*.o $libs -lm
