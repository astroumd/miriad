#include "header.h"

/**********************************************************************/
void convl(a,n1a,n2a,b,n1b,n2b,c)
FLOAT *a,*b,*c;
int n1a,n2a,n1b,n2b;
/*
  This convolves two images to produce a third.

  Inputs:
    a		First input image.
    n1a,n2a	Size of a.
    b		Second input image.
    n1b,n2b	Size of b. For greater efficiency, b should be the smaller
		of the two input images.
  Outputs:
    c		The output image, of size (n1a+n1b-1,n2a+n2b-1).
----------------------------------------------------------------------*/
{
  int i,ib,jb,ia,ja;
  FLOAT *f,*af,bval;

/* Zero out the resultant array. */

  f = c;
  for(i=0; i < (n1a+n1b-1)*(n2a+n2b-1); i++) *f++ = 0;

/* Loop over the pixels in b */

  b += n1b*n2b;
  for(jb = 0; jb < n2b; jb++ )for(ib = 0; ib < n1b; ib++){
    bval = *(--b);
    f = c + jb*(n1a+n1b-1) + ib;
    af = a;
    for(ja = 0; ja < n2a; ja++){
      for(ia = 0; ia < n1a; ia++) *f++ += bval * *af++;
      f += n1b-1;
    }
  }
}
