#!/bin/csh -f
#
#   excersize integer size vs. malloc
#   the mem.for / mm.f2c problem on IA32 vs. IA64 bit
#
#   Originally written by Bob Sault - nov 2005
#   Adapted for miriad4 by Peter Teuben - 28-nov-05

set mode = "std"

foreach a ($*)
  set $a
end

#------------------------------------------------------------------------
# Generate the source for the test program

cat <<EOF >exa1.f
c    do not edit, created by $0
	program exa
	integer n
	real x(1)
	common/dynmem/x
c	write(*,*)'Enter number of bytes'
	read(*,*)n
	call myalloc(x,n)
	end
EOF



cat <<EOF >exa2.c
/*    do not edit, created by $0 */
#include <stddef.h>
#include <stdlib.h>
#include <stdio.h>

#ifdef dolong
  typedef long int fortran_integer;
#else
  typedef int fortran_integer;
#endif

void myalloc_(float *x,fortran_integer *n){
  float *s;
  size_t myn;
  ptrdiff_t d;
  fortran_integer i;

  myn = *n;
  s = (float *)malloc(myn);
  if(s == NULL){
    perror("malloc");
  }else{
    d = s - x;
    i = (fortran_integer)d;
    if(d != i){
      printf("myalloc: Funny rounding problem\n");
      exit(1);
    }else{
      printf("Success\n");
      exit(0);
    }
  }
}
EOF

#------------------------------------------------------------------------
# Compile the test program

if ( "$mode" == "std") then
  cc -c exa2.c
  f77 -o exa exa1.f exa2.o
endif
if ( "$mode" == "ifort") then
  icc -c exa2.c
  ifort -o exa exa1.f exa2.o
endif
if ( "$mode" == "ifortd") then
  icc -c exa2.c
  ifort -o exa -Qdyncom"dynmem" exa1.f exa2.o
endif
if ( "$mode" == "ifortx") then
  icc -Ddolong -c exa2.c
  ifort -i8 -o exa exa1.f exa2.o
endif
if ( "$mode" == "gfortran") then
  gcc -c exa2.c
  gfortran -o exa exa1.f exa2.o
endif
if ( "$mode" == "gfortranx") then
  gcc -Ddolong -c exa2.c
  gfortran -fdefault-integer-8 -o exa exa1.f exa2.o
endif

#------------------------------------------------------------------------
# Run the test

echo "============> First a size:"
size exa
echo "============> and a loadmap:" 
ldd exa
echo "============> now the run:"

./exa <<EOF
10000000
EOF
echo $status
