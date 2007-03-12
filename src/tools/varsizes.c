/*============================================================================
*  Simple program to return variable sizes used on your platform.
*
*  To build: cc -o varsizes varsizes.c
*
*  On some 32 bit architecture machine in order to get off_t to be 8 byte, add
#      -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE
*  Author: Chris.Phillips@csiro.au
*  Date: 2005-03-31
*  $Id$
*===========================================================================*/

#include<stdio.h>
#include <sys/types.h>
#include <unistd.h>

int main (void)
{
  int i;

  printf("System variable sizes (in bytes)\n\n");
  printf(" Sizeof char = %d\n", sizeof(char));  
  printf(" Sizeof short = %d\n", sizeof(short));  
  printf(" Sizeof int = %d\n", sizeof(int));  
  printf(" Sizeof long = %d\n", sizeof(long));
  printf(" Sizeof long long = %d\n", sizeof(long long));
  printf(" Sizeof *void = %d\n", sizeof((void*) &i));
  printf("\n");
  printf(" Sizeof double = %d\n", sizeof(double));
  printf(" Sizeof long double = %d\n", sizeof(long double));
  printf("\n");
  printf(" Sizeof size_t = %d\n", sizeof(size_t));
  printf(" Sizeof off_t = %d\n",  sizeof(off_t));


  return 0;
}
