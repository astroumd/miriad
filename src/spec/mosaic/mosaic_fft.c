/*----------------------------------------------------------------------------
-- mosaic_fft.c --
/*----------------------------------------------------------------------------*/
#include "mosaic_def.h"
/*----------------------------------------------------------------------------*/

/******************************************************************************/
/*    <<< Fourier transforming >>>                     386 +  228 =  614 CONVOL
/******************************************************************************/

/* Choice of routines to compile, to be set on command line:
#define CMSSLFFT
#define MIRIADFFT
#define INTERNALFFT
*/

#ifdef MIRIADFFT
typedef struct { float real, imag; } Fcmplx;
#else
typedef struct { Real  real, imag; } Fcmplx;
#endif

/******************************************************************************/
/*
   Only if TIME_FFT is defined are internal timings done.
*/
/******************************************************************************/

#ifdef TIME_FFT
void Timer_ContN();
void Timer_StopN();
#define T_FFTRC  41
#define T_FFTCR  42
#define T_FFTCC  43
#define T_FFT842 44
#else
#define Timer_ContN(a)
#define Timer_StopN(a)
#endif

/*
*/
#ifdef INTERNALFFT
/******************************************************************************/
/*
   Fourier transform routines, translated from fft.for

   For doing the FFT with internal routines (identical to miriad library
   ones, but avoiding fortran altogether), include the translated code.
*/
/******************************************************************************/
/************************************************************************
c  These are a collection of routines originally based on Bergland and Dolan's
c  fft842 routine (called fft842x here). The fft842x (and the routines it calls)
c  is the real work horse. It performs a complex-to-complex FFT using a sign
c  of +1 in the exponent. The heart of fft842x is the r8txy and r8tyx routines,
c  which perform the radix-8 iterations.
c
c References:
c  Bergland G.D., Dolan M.T. (1979) "Fast Fourier transform algorithms",
c    in Programs for Digital Signal Processing, IEEE Press.
c  Press, Flannery,Teukolsky,Vetterling (1986), Numerical Recipes. Chapter 12.
c
c  History:
c    rjs Dark_ages  Adapted from the original Bergland and Dolan routines.
c    rjs   8sep89   Improved documentation.
c    rjs  25jan89   More documentation improvements.
c    rjs  20dec90   Check if N too large, in FFT842X.
c    rjs  19apr91   Redid FFTRC and FFTCR completely.
c    rjs  29apr91   Rewrote r8tyx to use "real" (rather than "complex")
c                   variables.
c    bpw   9jun93   'Stolen' to convert to C, to avoid stifling
c                   C calls FORTRAN problems.
c************************************************************************
c* Fftrc -- Real to complex 1D FFT
c: fourier-transform,FFT
c& rjs
c+
c
c  This performs a 1D Fourier transform of a real sequence. There is no
c  1/N scaling, and the "phase center" of the transform is the first
c  element of the input array.
c
c  Input:
c    in        The input real array.
c    sgn       The sign of the exponent in the transform, This can be
c              either 1 or -1.
c    n         The number of elements to transform. This must be a power
c              of 2.
c  Output:
c    out       The output array. Because of the conjugate symmetry of the
c              FFT of a real sequence, only half of the full complex sequence
c              is returned. Normally this array will be dimensioned of size
c              N/2+1 complex elements. Element 1 corresponds to the "DC" term,
c              element N/2+1 corresponding to the "folding frequency" term.
c              This array could alternately be dimensioned as N+2 real
c              elements.
c--
c------------------------------------------------------------------------ */

void fftrc(in,out,sgn,len)
Real *in, *out; /* in[len], out[len+2] */
int  *sgn, *len;
{
   private void fft_ini(), fft842x();
   int  n, no2;
   int  i, j;
   Real w0r,w0i, wr,wi, t1r,t1i, t2r,t2i, tr,ti;

   n = *len; no2 = n/2;

   Timer_ContN(T_FFTRC);

   if( in != out ) { for( i=0; i<n; i++ ) out[i] = in[i]; }

/* get FFT parameters */
   fft_ini(no2,&w0r,&w0i);

/* Initially assume sgn is positive (this is all that fft842x can handle) */
   fft842x( out, no2 );

   wr=w0r; wi=w0i;
   for( j=n-2, i=2; i<no2; i+=2 ) {
      t1r = 0.5*( out[i]   + out[j]   );  t2i = -0.5*( out[i]   - out[j]   );
      t1i = 0.5*( out[i+1] - out[j+1] );  t2r =  0.5*( out[i+1] + out[j+1] );
      tr  = wr*t2r - wi*t2i;              ti  = wi*t2r + wr*t2i;
      out[i] = t1r + tr;   out[i+1] =  t1i + ti;
      out[j] = t1r - tr;   out[j+1] = -t1i + ti;
      tr=wr;  wr = tr*w0r - wi*w0i;  wi = wi*w0r + tr*w0i;
      j -= 2;
   }

/* If sgn was negative, conjugate the output */
   if( *sgn < 0 ) { for( i=3; i<n; i+=2 ) out[i] = -out[i]; }

/* Fix the end elements */
   tr     = out[0];
   out[0] = tr + out[1];   out[n]   = tr - out[1];
   out[1] = 0.;            out[n+1] = 0.;

   Timer_StopN(T_FFTRC);
}

/************************************************************************
c* Fftcr -- Complex to Real 1D FFT routine.
c: fourier-transform,FFT
c& rjs
c+
c
c  This performs a 1D Fourier transform of a complex sequence (with
c  conjugate symmetry), to produce a real output. There is no
c  1/N scaling, and the "phase center" of the transform is the first
c  element of the input array.
c
c  Input:
c    in        The input complex array. This will normally be dimensioned
c              as N/2+1 complex elements. Because the sequence is assumed
c              to have conjugate symmetry, only half the input array is
c              needed. The first element corresponds to the "DC" term.
c              This array could also be declared to be a real array of
c              size N+2 elements.
c    sgn       The sign of the exponent in the transform, This can be
c              either 1 or -1.
c    n         The number of elements to transform. This must be a power
c              of 2.
c  Output:
c    out       The output real array.
c--
c------------------------------------------------------------------------ */

void fftcr(in,out,sgn,len)
Real *in, *out; /* in[len+2], out[len] */
int  *sgn, *len;
{
   private void fft_ini(), fft842x();
   int  n, no2;
   int  i, j;
   Real w0r,w0i, wr,wi, t1r,t1i, t2r,t2i, tr,ti;

   n = *len; no2 = n/2;
   Timer_ContN(T_FFTCR);

/* get FFT parameters */
   fft_ini(no2,&w0r,&w0i);

/* Copy the vector across. If sgn is negative, conjugate the data on the way
   (as fft842x can only handle positive sgn) */
   if( *sgn > 0 ) { for( i=0; i<n; i++  ) { out[i]=in[i];                     }}
   else           { for( i=0; i<n; i+=2 ) { out[i]=in[i]; out[i+1]= -in[i+1]; }}
   out[1] = in[n];

   wr=w0r; wi=w0i;
   for( j=n-2, i=2; i<no2; i+=2 ) {
      t1r =  ( out[i]   + out[j]   );  t2i = -( out[i]   - out[j]   );
      t1i =  ( out[i+1] - out[j+1] );  t2r =  ( out[i+1] + out[j+1] );
      tr  = wr*t2r - wi*t2i;           ti  = wi*t2r + wr*t2i;
      out[i] = t1r + tr;   out[i+1] =  t1i + ti;
      out[j] = t1r - tr;   out[j+1] = -t1i + ti;
      tr=wr;  wr = tr*w0r - wi*w0i;  wi = wi*w0r + tr*w0i;
      j -= 2;
   }

/* Fiddle the end elements, and do the FFT */
   tr       = out[0];
   out[0]   = (tr + out[1]);     out[1]     = -(tr - out[1]);
   out[no2] = 2. * out[no2];     out[no2+1] = 2. * out[no2+1];

   fft842x( out, no2 );

/* Reconjugate the data (always!) */
   for( i=1; i<n; i+=2 ) out[i] = -out[i];

   Timer_StopN(T_FFTCR);
}

/************************************************************************
c* Fftcc -- Complex to complex 1D FFT routine.
c: fourier-transform,FFT
c& rjs
c+
c
c  This performs a 1D Fourier transform of a complex sequence. There is no
c  1/N scaling, and the "phase center" of the transform is the first
c  element of the input array.
c
c  Input:
c    in        The input complex array.
c    sgn       The sign of the exponent in the transform, This can be
c              either 1 or -1.
c    n         The number of elements to transform. This must be a power
c              of 2.
c  Output:
c    out       The output complex array.
c--
c------------------------------------------------------------------------ */

void fftcc(in,out,sgn,len)
Real *in, *out; /* in[2*len], out[2*len] */
int  *sgn, *len;
{
   private void fft_ini(), fft842x();
   int  n2;
   int  i;
   Real w0r, w0i;

   n2 = 2 * *len;

   Timer_ContN(T_FFTCC);

/* Take the conjugate on a forward transform. Otherwise copy input to output */
   if( in != out ) {
      if( *sgn < 0 ) { for(i=0;i<n2;i+=2 ) { out[i]=in[i]; out[i+1]=-in[i+1]; }}
      else           { for(i=0;i<n2;i++  ) { out[i]=in[i];                    }}
   } else {
      if( *sgn < 0 ) { for(i=1;i<n2;i+=2 ) { out[i]=-in[i]; } }
   }

/* Get FFT parameters */
   fft_ini(n2/2,&w0r,&w0i);

/* Do the fft */
   fft842x( out, n2/2 );

/* Conjugate (forward) the result */
   if( *sgn < 0 ) { for(i=1;i<n2;i+=2) out[i]=-out[i]; }

   Timer_StopN(T_FFTCC);
}

/************************************************************************
c  Generate twiddle factors and a bit-reverse lookup table.
c  This technique for generating bit-reverse permutation is (poorly) described
c  in Bracewell's Hartley transform book, and is apparently due to David
c  Evans. Though it is cryptic and long, it is significantly more efficient
c  than any other bit-reverse permutation I know of. It works by using a
c  bit-reverse lookup table for ndash = 2**(log2(n)/2).
c
c  Input:
c    n         Value of n to generate tables for.
c
c  Output:
c    log2_n    log2(n)
c    perm1
c    perm2     Permutation arrays. To perform bit reverse ordering,
c              swap data(perm1[i]) with data(perm2[i]) for i=1,ni.
c    nperm     Size of permutation array.
c    twiddle   Twiddle factors.
c              twiddle[i] = exp( j*2*pi/n * (i-1) )
c
c------------------------------------------------------------------------ */

#define MAXLOG 20

private int First=1;
private struct {
         int    log2n, n;
         int    nperm, *perm1, *perm2;
         cmplx *twiddle;
         Real   w0r, w0i;
      } FTPAR[MAXLOG];

/* set w0r, w0i */
private void fft_ini(N,w0r,w0i)
int   N;
Real *w0r, *w0i;
{
   int log2n;
   for(log2n=0;log2n<MAXLOG;log2n++) { if(FTPAR[log2n].n==N) {
      *w0r = FTPAR[log2n].w0r;
      *w0i = FTPAR[log2n].w0i;
      break;
   }}
}

/* calculate parameters, if not yet done for this N */
void fftini(N)
int N;
{
   int  log2n;
   int  j, n;
   int  i, irev, k, nperm;
   Real theta;
   Real w0r,w0i, wr,wi, t;

/* First pass: initialize; else: check if done before */
   if(First){ for(log2n=0;log2n<MAXLOG;log2n++) FTPAR[log2n].n=0; First=0; }
   else     { for(log2n=0;log2n<MAXLOG;log2n++) {
                     if((FTPAR[log2n].n==N) & (FTPAR[log2n-1].n==N/2)) return;}}

/* Calculate factors for N and for N/2 */
   for( j=0; j<2; j++ ) { n = j==0 ? N : N/2;

/* Determine log2(n) */
   k=1; log2n=0; while(k<n) { k+=k; log2n++; }

/* Indicate we did this one */
   FTPAR[log2n].n     = n;
   FTPAR[log2n].log2n = log2n;

/* Allocate array space */
   Malloc( FTPAR[log2n].perm1,   int,   n/2 );
   Malloc( FTPAR[log2n].perm2,   int,   n/2 );
   Malloc( FTPAR[log2n].twiddle, cmplx, n   );

/* Generate a bit-reverse permutation array */
   nperm = irev = 0;
   for( i=0; i<=n-2; i++ ) {
      if( i < irev ) { nperm+=1; FTPAR[log2n].perm1[nperm-1] = i;
                                 FTPAR[log2n].perm2[nperm-1] = irev; }
      k = n/2;
      while( irev >= k ) { irev -= k; k = k/2; } irev += k;
   }
   FTPAR[log2n].nperm = nperm;

/* Generate the twiddle factors */
   theta = 2.*M_PI / n;    t = sin(0.5*theta);
   wr = w0r = -2.*t*t + 1.;
   wi = w0i = sin(theta);

   FTPAR[log2n].twiddle[0].real = 1.;
   FTPAR[log2n].twiddle[0].imag = 0.;
   for( i=1; i<n; i++ ) {
      FTPAR[log2n].twiddle[i].real = wr;
      FTPAR[log2n].twiddle[i].imag = wi;
      t=wr;  wr = t*w0r - wi*w0i;  wi = wi*w0r + t*w0i;
   }

/* Calculate first phase factor for n/2 */
   theta = M_PI / n;  t = sin(0.5*theta);
   FTPAR[log2n].w0r = -2.*t*t + 1.;
   FTPAR[log2n].w0i = sin(theta);

   }
}

/************************************************************************
c
c Fast fourier transform for n=2**m, for complex input sequence.
c
c This routine replaces the vector data by its finite
c discrete, complex fourier transform. It performs as many base
c 8 iterations as possible and then finishes with a base 4 iteration
c or a base 2 iteration if needed.
c
c Tables are used to store twiddle factors and bit-reverse permutation.
c
c------------------------------------------------------------------------ */

private void fft842x( data, n )
Real *data; /* data[2*n] */
int   n;
{
   private void r8tyx(), r4txx(), r2txx();
   int          log2n;
   int          length, nxtlt, i, ilim;
   Real         t1r, t1i;
   int          nperm, *perm1, *perm2;
   cmplx       *twiddle;

   Timer_ContN(T_FFT842);

   for(log2n=0;log2n<MAXLOG;log2n++) { if(FTPAR[log2n].n==n) break; }
   perm1   = FTPAR[log2n].perm1;
   perm2   = FTPAR[log2n].perm2;
   nperm   = FTPAR[log2n].nperm;
   twiddle = FTPAR[log2n].twiddle;

/* Radix 8 passes,if any */
   nxtlt  = n/8;
   length = n;
   i=1; ilim=log2n/3;
   while( i <= ilim ) {
      r8tyx( nxtlt, n, length, twiddle,
             &data[0],       &data[ 2*nxtlt], &data[ 4*nxtlt], &data[ 6*nxtlt],
             &data[8*nxtlt], &data[10*nxtlt], &data[12*nxtlt], &data[14*nxtlt]);
      length = nxtlt;
      nxtlt /= 8;
      i++;
   }

/* Do the remaining radix-4 or radix-2 stage, if required */
   if(      log2n%3==2 ) r4txx( n, &data[0],&data[2],&data[4],&data[6] );
   else if( log2n%3==1 ) r2txx( n, &data[0],&data[2] );

/* Perform bit reversal */
   for( i=0; i<nperm; i++ ) {
      t1r                  = data[ 2*perm1[i]   ];
      t1i                  = data[ 2*perm1[i]+1 ];
      data[ 2*perm1[i]   ] = data[ 2*perm2[i]   ];
      data[ 2*perm1[i]+1 ] = data[ 2*perm2[i]+1 ];
      data[ 2*perm2[i]   ] = t1r;
      data[ 2*perm2[i]+1 ] = t1i;
   }

   Timer_StopN(T_FFT842);
}

/************************************************************************
c
c Radix 2 iteration subroutine.
c
c----------------------------------------------------------------------- */

private void r2txx( nthpo, c0, c1 )
int  nthpo;
Real *c0, *c1;
{
   int  k;
   Real a1r, a1i;
   for( k=0; k<2*nthpo; k+=4 ) {
      a1r   = c0[k];            a1i     = c0[k+1];
      c0[k] = a1r + c1[k];      c0[k+1] = a1i + c1[k+1];
      c1[k] = a1r - c1[k];      c1[k+1] = a1i - c1[k+1];
   }
}

/************************************************************************
c
c Radix 4 iteration subroutine.
c
c----------------------------------------------------------------------- */

private void r4txx( nthpo, c0, c1, c2, c3 )
int   nthpo;
Real *c0, *c1, *c2, *c3;
{
   int  k;
   Real ar1,ai1, ar2,ai2, ar3,ai3, ar4,ai4;
   for( k=0; k<2*nthpo; k+=8 ) {
      ar1   = c0[k] + c2[k];      ai1     = c0[k+1] + c2[k+1];
      ar2   = c0[k] - c2[k];      ai2     = c0[k+1] - c2[k+1];
      ar3   = c1[k] + c3[k];      ai3     = c1[k+1] + c3[k+1];
      ar4   =-c1[k+1] + c3[k+1];  ai4     = c1[k] - c3[k];
      c0[k] = ar1 + ar3;          c0[k+1] = ai1 + ai3;
      c1[k] = ar1 - ar3;          c1[k+1] = ai1 - ai3;
      c2[k] = ar2 + ar4;          c2[k+1] = ai2 + ai4;
      c3[k] = ar2 - ar4;          c3[k+1] = ai2 - ai4;
   }
}

/************************************************************************
c
c  Radix 8 iterations. This uses "Real" rather than "cmplx" as many
c  compilers are inefficient at dealing with "cmplx".
c
c------------------------------------------------------------------------ */

private void r8tyx( nxtlt, nthpo, length, twiddle, c0,c1,c2,c3,c4,c5,c6,c7 )
int    nxtlt, nthpo, length;
cmplx *twiddle;
Real  *c0, *c1, *c2, *c3, *c4, *c5, *c6, *c7;
{
   int  j, k, jmax=2*nxtlt, kmax=2*nthpo, kstep=2*length;
   int  i1, i2, i3, i4, i5, i6, i7;
   int  inc1, inc2, inc3, inc4, inc5, inc6, inc7;
   Real *cs = (Real *)twiddle;
   Real a0r,a0i,a1r,a1i,a2r,a2i,a3r,a3i,tr,ti;
   Real b0r,b0i,b1r,b1i,b2r,b2i,b3r,b3i;
   Real b4r,b4i,b5r,b5i,b6r,b6i,b7r,b7i;

   jmax=2*nxtlt; kmax=2*nthpo; kstep=2*length;

   i1 = i2 = i3 = i4 = i5 = i6 = i7 = 0;
   inc1 = 2*nthpo/length;
   inc2 = inc1 + inc1;  inc3 = inc2 + inc1;  inc4 = inc3 + inc1;
   inc5 = inc4 + inc1;  inc6 = inc5 + inc1;  inc7 = inc6 + inc1;


   for( j=0; j<jmax; j+=2 ) {
      for( k=j; k<kmax; k+=kstep ) {
         a0r = c0[k]   + c4[k];    a2r = c0[k]   - c4[k];
         a0i = c0[k+1] + c4[k+1];  a2i = c0[k+1] - c4[k+1];
         a1r = c2[k]   + c6[k];    a3i = c2[k]   - c6[k];
         a1i = c2[k+1] + c6[k+1];  a3r = c6[k+1] - c2[k+1];
         b0r = a0r + a1r;          b0i = a0i + a1i;
         b2r = a0r - a1r;          b2i = a0i - a1i;
         b4r = a2r + a3r;          b4i = a2i + a3i;
         b6r = a2r - a3r;          b6i = a2i - a3i;

         a0r = c1[k]   + c5[k];    a2r = c1[k]   - c5[k];
         a0i = c1[k+1] + c5[k+1];  a2i = c1[k+1] - c5[k+1];
         a1r = c3[k]   + c7[k];    a3i = c3[k]   - c7[k];
         a3r = c7[k+1] - c3[k+1];  a1i = c3[k+1] + c7[k+1];
         b1r = a0r + a1r;          b1i = a0i + a1i;
         b3r = a1i - a0i;          b3i = a0r - a1r;
         tr  = a2r + a3r;          ti  = a2i + a3i;
         b5r =  M_SQRT1_2*(tr-ti); b5i = M_SQRT1_2*(tr+ti);
         tr  = a2r - a3r;          ti  = a2i - a3i;
         b7r = -M_SQRT1_2*(tr+ti); b7i = M_SQRT1_2*(tr-ti);

         if( j>0 ) {
           c0[k]   =           b0r+b1r;
           c0[k+1] =           b0i+b1i;
           c1[k]   = cs[i4]  *(b0r-b1r) - cs[i4+1]*(b0i-b1i);
           c1[k+1] = cs[i4+1]*(b0r-b1r) + cs[i4]  *(b0i-b1i);
           c2[k]   = cs[i2]  *(b2r+b3r) - cs[i2+1]*(b2i+b3i);
           c2[k+1] = cs[i2+1]*(b2r+b3r) + cs[i2]  *(b2i+b3i);
           c3[k]   = cs[i6]  *(b2r-b3r) - cs[i6+1]*(b2i-b3i);
           c3[k+1] = cs[i6+1]*(b2r-b3r) + cs[i6]  *(b2i-b3i);
           c4[k]   = cs[i1]  *(b4r+b5r) - cs[i1+1]*(b4i+b5i);
           c4[k+1] = cs[i1+1]*(b4r+b5r) + cs[i1]  *(b4i+b5i);
           c5[k]   = cs[i5]  *(b4r-b5r) - cs[i5+1]*(b4i-b5i);
           c5[k+1] = cs[i5+1]*(b4r-b5r) + cs[i5]  *(b4i-b5i);
           c6[k]   = cs[i3]  *(b6r+b7r) - cs[i3+1]*(b6i+b7i);
           c6[k+1] = cs[i3+1]*(b6r+b7r) + cs[i3]  *(b6i+b7i);
           c7[k]   = cs[i7]  *(b6r-b7r) - cs[i7+1]*(b6i-b7i);
           c7[k+1] = cs[i7+1]*(b6r-b7r) + cs[i7]  *(b6i-b7i);
         } else {
           c0[k] = b0r + b1r;   c0[k+1] = b0i + b1i;
           c1[k] = b0r - b1r;   c1[k+1] = b0i - b1i;
           c2[k] = b2r + b3r;   c2[k+1] = b2i + b3i;
           c3[k] = b2r - b3r;   c3[k+1] = b2i - b3i;
           c4[k] = b4r + b5r;   c4[k+1] = b4i + b5i;
           c5[k] = b4r - b5r;   c5[k+1] = b4i - b5i;
           c6[k] = b6r + b7r;   c6[k+1] = b6i + b7i;
           c7[k] = b6r - b7r;   c7[k+1] = b6i - b7i;
         }

      }
      i1+=inc1; i2+=inc2; i3+=inc3; i4+=inc4; i5+=inc5; i6+=inc6; i7+=inc7;
   }
}

#endif /* INTERNALFFT */


/*
*/
#ifdef CMSSLFFT
/******************************************************************************/
/*
  For using CMSSL: predefine some symbols that are arguments to the fft
  functions (always put in and get back bit-reversed arrays, scale once with
  1/N). Include the C to Fortran interface.
  The routines will go into the miriad library, the symbol definitions into
  a miriad include file.
*/
/******************************************************************************/

#include <csfort.h>

void fft2D_d_c(SetupID) int *SetupID;
{
   void fft2D_d_();
   CMC_CALL_FORTRAN( fft2D_d_(SetupID) );
   return;
}

void fft2D_do_c( A,nx,ny, type,
                 ops, in_bit_orders, out_bit_orders, scales,
                 SetupID, ier )
int  *nx, *ny;
CMC_double_complex:current *A;
char *type;
int  *ops, *in_bit_orders, *out_bit_orders, *scales;
int  *SetupID, *ier;
{
   void fft2D_do_();
   CMC_descriptor_t ApDesc = CMC_wrap_pvar(A);
   CMC_CALL_FORTRAN(  fft2D_do_(ApDesc,ny,nx,type,
                                ops,in_bit_orders,out_bit_orders,scales,
                                SetupID,ier)    );
   CMC_free_desc(ApDesc);
   return;
}

void fft2D_s_c( A,nx,ny, type, SetupID, ier )
int  *nx, *ny;
CMC_double_complex:current *A;
char *type;
int  *SetupID, *ier;
{
   void fft2D_s_();
   CMC_descriptor_t ApDesc = CMC_wrap_pvar(A);
   CMC_CALL_FORTRAN(  fft2D_s_(ApDesc,ny,nx,type,SetupID,ier)  );
   CMC_free_desc(ApDesc);
   return;
}

/******************************************************************************/
/*
   Ugliness below is to get the cmf definitions to call cmssl's fft
*/
/******************************************************************************/

#define CMSSL_nop          0
#define CMSSL_f_xform      1
#define CMSSL_i_xform      2
#define CMSSL_cx_cx_xform  "CTOC"
#define CMSSL_re_cx_xform  "RTOC"
#define CMSSL_cx_re_xform  "CTOR"
#define CMSSL_default      0
#define CMSSL_default_124  0
#define CMSSL_send         1
#define CMSSL_news         2
#define CMSSL_normal       0
#define CMSSL_bit_reversed 1
#define CMSSL_noscale      0
#define CMSSL_scale_sqrt   1
#define CMSSL_scale_n      2

char *fft_cc_xform         =   CMSSL_cx_cx_xform;
char *fft_cr_xform         =   CMSSL_cx_re_xform;
char *fft_rc_xform         =   CMSSL_re_cx_xform;
int   fft_nop          [2] = { CMSSL_nop,          CMSSL_nop          };
int   fft_forward      [2] = { CMSSL_f_xform,      CMSSL_f_xform      };
int   fft_inverse      [2] = { CMSSL_i_xform,      CMSSL_i_xform      };
int   fft_bits_normal  [2] = { CMSSL_normal,       CMSSL_normal       };
int   fft_bits_reversed[2] = { CMSSL_bit_reversed, CMSSL_bit_reversed };
int   fft_noscale      [2] = { CMSSL_noscale,      CMSSL_noscale      };
int   fft_scale_sqrt   [2] = { CMSSL_scale_sqrt,   CMSSL_scale_sqrt   };
int   fft_scale_n      [2] = { CMSSL_scale_n,      CMSSL_scale_n      };

#endif /* CMSSLFFT */


/*

/******************************************************************************/
/*
   Perform the phase shift of the coverage array, so that phase zero is now
   at element one. Different FT routines need the coverage plane to be either
   transposed on not, so indicate this by a flag.
*/
/******************************************************************************/

private int    RotAll=0;
private cmplx *ROTU, *ROTV;

void PhaseShift( Cover, uvPln, ulen, vlen, xref, yref, transpose )
cmplx  *Cover;
Fcmplx *uvPln;
int     ulen, vlen;
double  xref, yref;
int     transpose;
{
   register int    xy, u, v, uv;
   register int    ulen_h = ulen/2+1;
   register int    uvsize=ulen_h*vlen;

   register cmplx *Rotu, *Rotv;
   register Real   Rur, Rui, Rvr, Rvi, Cr, Ci;
   register Real   one_over_N = 1./(ulen*vlen);
   register Real   thetau = 2.*M_PI * (xref-1.) / (Real)ulen;
   register Real   thetav = 2.*M_PI * (yref-1.) / (Real)vlen;
   TRACE("PhaseShift");

   if( (ulen_h > RotAll) | (vlen > RotAll) ) {
      Malloc( ROTU, cmplx, ulen_h );
      Malloc( ROTV, cmplx, vlen   );
      RotAll = ulen_h>vlen ? ulen_h : vlen;
   }
   Rotu=ROTU; Rotv=ROTV;

   for( u=0; u<ulen_h; u++ ) {
      (*(Rotu+u)).real = cos(u*thetau);
      (*(Rotu+u)).imag = sin(u*thetau);
   }
   for( v=0; v<vlen;   v++ ) {
      (*(Rotv+v)).real = one_over_N * cos(v*thetav);
      (*(Rotv+v)).imag = one_over_N * sin(v*thetav);
   }

   for( uv=0; uv<uvsize; uv++ ) {
                 u=uv%ulen_h; Rur = (*(Rotu+u)).real;  Rui = (*(Rotu+u)).imag;
      if(u==0) { v=uv/ulen_h; Rvr = (*(Rotv+v)).real;  Rvi = (*(Rotv+v)).imag; }
                              Cr = (*(uvPln+uv)).real; Ci = (*(uvPln+uv)).imag;
      xy = transpose ? u*vlen+v : uv;
      (*(Cover+xy)).real = (Cr*Rur-Ci*Rui)*Rvr - (Cr*Rui+Ci*Rur)*Rvi;
      (*(Cover+xy)).imag = (Cr*Rur-Ci*Rui)*Rvi + (Cr*Rui+Ci*Rur)*Rvr;
   }
}

/*

/******************************************************************************
/*
   Find the number of operations, to be called outside the loop in which the
   fft routines are called, so that different processors don't interfere with
   eachother.
*/
/******************************************************************************/

private void fft842count( N, pt_lcnt, pt_scnt, mcnt, acnt )
int  N;
int *pt_scnt, *pt_lcnt, *mcnt, *acnt;
{
   int log2n;
   int nxtlt, length, i;
   int j,jmax, k,kmax,kstep;
   int lcnt=0, jcnt=0;

   k=1; log2n=0; while(k<N) { k+=k; log2n++; }

   nxtlt=N/8; length=N; i=1;
   while( i <= log2n/3 ) {
      jmax=2*nxtlt; kmax=2*N; kstep=2*length;
      for(j=0;j<jmax;j+=2) { jcnt++; lcnt += (kmax-j+1)/kstep; }
      length = nxtlt; nxtlt/=8; i++;
   }
   *pt_scnt=lcnt*16;
   *pt_lcnt=lcnt*60;
   *mcnt   =lcnt*103+jcnt*27;
   *acnt   =lcnt*111+jcnt*9;

   if(log2n%3==2) {
   lcnt=N/4; *pt_scnt+=lcnt*8; *pt_lcnt+=lcnt*16; *mcnt+=lcnt*24; *acnt+=lcnt*16;
   }
   if(log2n%3==1) {
   lcnt=N/2; *pt_scnt+=lcnt*4; *pt_lcnt+=lcnt* 6; *mcnt+=lcnt*6;  *acnt+=lcnt*4;
   }
}


void FFTOpCnt(func,sgn,ncall,N)
char *func;
int   sgn;
int   ncall, N;
{
   void         OperCount();
#define CCONV 2
   private void fft842count();
   shape        aS;
   int          pt_scnt, pt_lcnt, mcnt, acnt;

   aS.size=ncall;
   if(        !memcmp(func,"PhaseShift",10) ) {
      aS.size *= N; OperCount( CCONV, &aS,0, 2,6, 38, 20, 2);

   } else if( !memcmp(func,"fftrc",5) ) {
      fft842count( N/2, &pt_scnt,&pt_lcnt,&mcnt,&acnt );
      OperCount(   CCONV, &aS,0,
                   pt_scnt + N*1 + N/4* 4 + (sgn<0?N/2*1:0),
                   pt_lcnt + N*1 + N/4* 8 + (sgn<0?N/2*1:0),
                   mcnt    + N*0 + N/4*35 + (sgn<0?N/2*0:0),
                   acnt    + N*0 + N/4*25 + (sgn<0?N/2*0:0), 0 );

   } else if( !memcmp(func,"fftcr",5) ) {
      fft842count( N/2, &pt_scnt,&pt_lcnt,&mcnt,&acnt );
      OperCount(   CCONV, &aS,0,
                   pt_scnt + N*1 + N/4* 4 + N/2*1,
                   pt_lcnt + N*1 + N/4* 8 + N/2*1,
                   mcnt    + N*0 + N/4*35 + N/2*0,
                   acnt    + N*0 + N/4*21 + N/2*0, 0 );

   } else if( !memcmp(func,"fftcc",5) ) {
      fft842count( N,   &pt_scnt,&pt_lcnt,&mcnt,&acnt );
      OperCount(   CCONV, &aS,0,
                   pt_scnt + 2*N*1 + (sgn<0?N/2*1:0),
                   pt_lcnt + 2*N*1 + (sgn<0?N/2*1:0),
                   mcnt    + 2*N*0 + (sgn<0?N/2*0:0),
                   acnt    + 2*N*0 + (sgn<0?N/2*0:0), 0 );
   }
}
