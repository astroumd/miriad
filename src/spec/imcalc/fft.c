/************************************************************************/
/*									*/
/*	This contains the routines to perform FFT operations.		*/
/*                                                                      */
/************************************************************************/

#include <math.h>
#include <stdio.h>
#include "header.h"

static int maxdim=0;
static FLOAT *buf=NULL;

private void fftr(),fftc(),fiddler(),fiddlec(),fftalloc();

/**********************************************************************/
void imfft_r(a,n1,n2,sign)
FLOAT *a;
int n1,n2,sign;
/*
  This forms the FFT of a real image. On input the phase centre is assumed
  to be at N/2+1. The output is a full sized complex array, again with the
  phase centre at N/2+1.

  Input:
    a		The real array to be FFTed.
    n1,n2	The dimensions of the image.
    sign	Sign of the transform.
  Output:
    out		The full sized output complex array.
----------------------------------------------------------------------*/
{
  FLOAT *d,*t,*d1,*d2,*b;
  int i,j;

/* Make sure we have enough scratch memory. */

  fftalloc(2*max(n1,n2));


/* First to the fiddle so that the origin in both the input and output
   is at (n1/2,n2/2). */

  fiddler(a,n1,n2);

/* Do the FFTs of the rows. */

  d = a;
  for(j=0; j < n2; j++){
    fftr(d,n1,sign);
    d += n1;
  }

/* Do the FFTs of the columns. Extract the columns into a buffer, FFT the
   buffer, then reinsert the result back. */

  d = a;
  for(i=0; i < n1/2; i++){
    t = d;
    b = buf;
    for(j=0; j < n2; j++){
      *b++ = *t;
      *b++ = *(t+1);
      t += n1;
    }
    fftc(buf,n2,sign);
    t = d;
    b = buf;
    for(j=0; j < n2; j++){
      *t = *b++;
      *(t+1) = *b++;
      t += n1;
    }
    d += 2;
  }

/* We now have the FFT of the image in the array, but in a somewhat
   confused state. Get it into the right state. */

  d1 = a + n1*n2 - n1;
  d2 = a + 2*n1*n2 - 2*n1;
  for(j=0; j < n2; j++){
    for(i=0; i < n1/2; i++){
    }
  }
}
/**********************************************************************/
void imfft_c(a,n1,n2,sign)
FLOAT *a;
int n1,n2,sign;
/*
----------------------------------------------------------------------*/
{
  FLOAT *d,*t,*b;
  int i,j;

/* Make sure we have enough scratch memory. */

  fftalloc(2*max(n1,n2));

/* First to the fiddle so that the origin in both the input and output
   is at (n1/2,n2/2). */

  fiddlec(a,n1,n2);

/* Do the FFTs of the rows. */

  d = a;
  for(j=0; j < n2; j++){
    fftc(d,n1,sign);
    d += n1+n1;
  }

/* Do the FFTs of the columns. Extract the columns into a buffer, FFT the
   buffer, then reinsert the result back. */

  d = a;
  for(i=0; i < n1; i++){
    t = d;
    b = buf;
    for(j=0; j < n2; j++){
      *b++ = *t;
      *b++ = *(t+1);
      t += n1+n1;
    }
    fftc(buf,n2,sign);
    t = d;
    b = buf;
    for(j=0; j < n2; j++){
      *t = *b++;
      *(t+1) = *b++;
      t += n1+n1;
    }
    d += 2;
  }
}
/**********************************************************************/
private void fftalloc(i)
int i;
/*
  This makes sure we have enough scratch space.
----------------------------------------------------------------------*/
{
  char *malloc(),*realloc();

  if(i > maxdim){
    if(buf == NULL) buf = (FLOAT *)malloc(sizeof(FLOAT)*i);
    else	    buf = (FLOAT *)realloc((char *)buf,sizeof(FLOAT)*i);
    maxdim = i;
    if(buf == NULL){
      fprintf(stderr,"### Ran out of memory, aborting ...\n");
      exit(1);
    }
  }
}
/**********************************************************************/
private void fiddler(a,n1,n2)
FLOAT a[];
int n1,n2;
/*
  This performs a n/2 cyclic shift of a real image, in both the x and
  y direction, and multiplies the images by (-1)**(i+j). These operations
  are needed to make the origin of transform be "natural" to the user.

  Inputs:
    n1,n2	Dimensions of the input real image.
  Input/Output:
    a		The image to be fiddled.
----------------------------------------------------------------------*/
{
  int i,j;
  FLOAT *a1,*a2,*a3,*a4,*tf,t;

  a1 = a;
  a2 = a + n1/2;
  a3 = a + n1*n2/2;
  a4 = a + n1*n2/2 + n1/2;

  for(j=0; j < n2/4; j++){
    for(i=0; i < n1/4; i++){
      t = *a1; *a1++ = *a4; *a4++ = t;
      t = *a2; *a2++ = *a3; *a3++ = t;
      t = *a1; *a1++ = - *a4; *a4++ = -t;
      t = *a2; *a2++ = - *a3; *a3++ = -t;
    }
    a1 += n1/2; a2 += n1/2; a3 += n1/2; a4 += n1/2;
    for(i=0; i < n1/4; i++){
      t = *a1; *a1++ = - *a4; *a4++ = - t;
      t = *a2; *a2++ = - *a3; *a3++ = - t;
      t = *a1; *a1++ =   *a4; *a4++ =   t;
      t = *a2; *a2++ =   *a3; *a3++ =   t;
    }
    a1 += n1/2; a2 += n1/2; a3 += n1/2; a4 += n1/2;
  }
}
/**********************************************************************/
private void fiddlec(a,n1,n2)
FLOAT a[];
int n1,n2;
/*
  This performs a n/2 cyclic shift of a complex image, in both the x and
  y direction, and multiplies the images by (-1)**(i+j). These operations
  are needed to make the origin of transform be "natural" to the user.

  Inputs:
    n1,n2	Dimensions of the input complex image.
  Input/Output:
    a		The image to be fiddled.
----------------------------------------------------------------------*/
{
  int i,j;
  FLOAT *a1,*a2,*a3,*a4,*tf,t;

  a1 = a;
  a2 = a + n1;
  a3 = a + n1*n2;
  a4 = a + n1*n2 + n1;

  for(j=0; j < n2/4; j++){
    for(i=0; i < n1/4; i++){
      t = *a1; *a1++ = *a4; *a4++ = t;
      t = *a1; *a1++ = *a4; *a4++ = t;
      t = *a2; *a2++ = *a3; *a3++ = t;
      t = *a2; *a2++ = *a3; *a3++ = t;
      t = *a1; *a1++ = - *a4; *a4++ = -t;
      t = *a1; *a1++ = - *a4; *a4++ = -t;
      t = *a2; *a2++ = - *a3; *a3++ = -t;
      t = *a2; *a2++ = - *a3; *a3++ = -t;
    }
    a1 += n1; a2 += n1; a3 += n1; a4 += n1;
    for(i=0; i < n1/4; i++){
      t = *a1; *a1++ = - *a4; *a4++ = - t;
      t = *a1; *a1++ = - *a4; *a4++ = - t;
      t = *a2; *a2++ = - *a3; *a3++ = - t;
      t = *a2; *a2++ = - *a3; *a3++ = - t;
      t = *a1; *a1++ =   *a4; *a4++ =   t;
      t = *a1; *a1++ =   *a4; *a4++ =   t;
      t = *a2; *a2++ =   *a3; *a3++ =   t;
      t = *a2; *a2++ =   *a3; *a3++ =   t;
    }
    a1 += n1; a2 += n1; a3 += n1; a4 += n1;
  }
}
/**********************************************************************/
private void fftr(a,n,sign)
FLOAT a[];
int n,sign;
/*
  This does an FFT of a single real valued sequence, returning the
  result in a "packed" form, i.e. a[0] is the DC value, a[1] is the
  folding frequency value, and (a[2*k],a[2*k+1]) form a complex pair.

  Input:
    n		The size of the real array to transform.
    sign	The sign of the transform.
  Input/Output:
    a		On input, it contains the sequence to be transformed.
		On output, it contains the transform, in a packed form.
----------------------------------------------------------------------*/
{
  FLOAT wr0,wi0,wr,wi,tr1,ti1,tr2,ti2,temp,tr,ti,theta;
  int i,j;

/* Do a N/2 transform of the real sequence, treating every second value
   as a imaginary part. */

  fftc(a,n/2,sign);

/* Fiddle this fiddled form into something more useful. */

  temp = a[0];
  a[0] += a[1];
  a[1] = temp - a[1];

  theta = 2*PI*sign/n;
  wr0 = sin(theta/2);
  wr0 *= -2*wr0;
  wi0 = sin(theta);
  wr = 1 + wr0;
  wi = wi0;
  j = n/2 - 1;
  for(i=1; i < n/2; i++){
    tr1 = 0.5*(a[i+i] + a[j+j]);
    ti1 = 0.5*(a[i+i+1] - a[j+j+1]);
    tr2 = 0.5*(a[i+i+1] + a[j+j+1]);
    ti2 = -0.5*(a[i+i] - a[j+j]);
    tr = wr*tr2 - wi*ti2;
    ti = wi*tr2 + wr*ti2;
    a[i+i] = tr1 + tr;
    a[i+i+1] = ti1 + ti;
    a[j+j] =  tr1 - tr;
    a[j+j+1] = -ti1 + ti;
    j = j - 1;
    temp = wr;
    wr = wr*wr0 + wi*wi0 + wr;
    wi = wi*wr0 + wr*wi0 + wi;
  }
}
/**********************************************************************/
private void fftc(a,n,sign)
FLOAT a[];
int n,sign;
/*
  This does an FFT of a single complex sequence.

  Input:
    a		An array of size 2*n FLOAT elements, containing the
		complex sequence to be FFTed.
    n		The number of elements in a.
    sign	Either 1 or -1, being the sign of the transform.
----------------------------------------------------------------------*/
{
  int k,kr,m,i,j,step;
  FLOAT t1,t2,theta,wr,wi,wr0,wi0,temp;

/* Do the bit-reverse re-ordering. */

  kr = 0;
  for(k=0; k < n-1; k++){
    if(k < kr){
      t1 = a[k+k];
      t2 = a[k+k+1];
      a[k+k] = a[kr+kr];
      a[k+k+1] = a[kr+kr+1];
      a[kr+kr] = t1;
      a[kr+kr+1] = t2;
    }

/* Do the bit-reverse incrementing. */

    m = n/2;
    while(m <= kr){
      kr -= m;
      m /= 2;
    }
    kr += m;
  }

/* Now go through the real work. */

  step = 1;
  while(step < n){
    theta = PI*sign / step;
    wr = 1; wi = 0;
    wr0 = sin(theta/2);
    wr0 = -2*wr0*wr0;
    wi0 = sin(theta);
    for( i=0; i < step; i++){
      for( j=i; j < n; j += 2*step ){
	k = j + step;
	t1 = wr*a[k+k] - wi*a[k+k+1];
	t2 = wi*a[k+k] + wr*a[k+k+1];
	a[k+k] = a[j+j] - t1;
	a[k+k+1] = a[j+j+1] - t2;
	a[j+j] = a[j+j] + t1;
	a[j+j+1] = a[j+j+1] + t2;
      }
      temp = wr;
      wr = wr*wr0 - wi*wi0 + wr;
      wi = wi*wr0 + temp*wi0 + wi;
    }
    step += step;
  }
}
