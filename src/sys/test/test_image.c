/*
cc -g -O2 -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -I$MIRSUBS -Wall -o test_image test_image.c -L$MIRLIB -lmir -lm
*/
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>

#include "miriad.h"

int main(int ac, char *av[])
{
    int t;
    char *fname = "bigmirimage";
    char *status = "new";
    int naxis = 3;
    int naxes[3];
    int nx=1000;
    int ny=1000;
    int nz=542;
    int i,j,k;
    float data[2048];

    if (ac > 1) 
        nz = atoi(av[1]);


    naxes[0] = nx;
    naxes[1] = ny;
    naxes[2] = nz;
    
    xyopen_c(&t,fname,status,naxis,naxes);
    printf("file handle=%d,   nz=%d\n",t,nz);
    for (k=1; k<=nz; k++) {
      xysetpl_c(t,1,&k);
      for (j=0; j<ny; j++) {
        xywrite_c(t,j+1,data);
      }
    }
    
    xyclose_c(t);
    
}
