/*----------------------------------------------------------------------------
-- mosaic_conv.c --
/*----------------------------------------------------------------------------*/
#include "mosaic_def.h"

/******************************************************************************/
/*
   On command line decide which FFT routines to use by using -D.....
      MIRIADFFT   -> use miriad library (default)
      INTERNALFFT -> the internal FFT code, miriad library C-rewrite
      CMSSLFFT    -> use the CM Scientific Software Library
      POWERFFT1D  -> use the 1D SGI power Challenge routines
      POWERFFT2D  -> use the 2D SGI power Challenge routines
*/
/******************************************************************************/

/* Only the following symbols are actually used from mosaic_def.h
#define logical int
#define TRUE 1
#define FALSE 0
#define Real float
typedef struct { Real  real, imag; } cmplx;
#define Real_current  Real
#define cmplx_current cmplx
typedef struct { int start, end, size, xlen, ylen, nsel; } shape;
#define Malloc(v,t,n) (v) = (t *)malloc( (unsigned)(n)*sizeof(t) )
*/

#ifdef MIRIADFFT
#define Float float
#else
#define Float Real
#endif
typedef struct { Float real, imag; } Fcmplx;

#define SINGLEFFT
#ifdef SINGLEFFT
#define rfft1dui sfft1dui
#define rfft1du  sfft1du
#define rfft2dui sfft2dui
#else
#define rfft1dui dfft1dui
#define rfft1du  dfft1du
#define rfft2dui dfft2dui
#define rfft2du  dfft2du
#define cfft1di  zfft1di
#define cfft1d   zfft1d
#define cprod2d  zprod2d
#endif

/******************************************************************************/
/*
   Utility routines useful to get some performance info out.
*/
/******************************************************************************/

private shape aShape;
void OperCount(), FFTOpCnt();
#define CCONV 2
#define OpCnt(LEN,npl,nps,nm,na,nd) \
        aShape.size=LEN; OperCount(CCONV,&aShape,0,npl,nps,nm,na,nd)

void Timer_Cont(), Timer_Stop();

/******************************************************************************/
/* <<< CONVOLUTION  >>>                                863 +  524 = 1387 CONVOL
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*
   CONVOLUTION
   DTM NOTE: FOURIER TRANSFORM ROUTINES MAY RUN REMOTELY

   Routines InitializeFFT, BeamFT and Convolution
*/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*    <<< Compiler switches >>>                          9 +   22 =   31 CONVOL
/******************************************************************************/

#if defined(mips)
#define COMPILE_PARALLEL
#endif

private int FWD=-1, BWD=1;

/*

/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*    <<< Convolution >>                               468 +  256 =  724 CONVOL
/******************************************************************************/
/*
   DTM NOTE: CONVOLUTION ROUTINES MAY RUN REMOTELY
*/
/******************************************************************************/
/*
   The convolution is done in two steps.
   There are several versions:
     one for use with miriad library (or with internal fft routines)
     one for use with CMSSL
     one for use with SGI power challenge

   In all case four functions must be defined:

   int InitializeFFT( ftid, xlen, ylen, workspace )
   int   ftid;
   int   xlen, ylen;
   Real *scfc[2];

   int BeamFT( BeamArr, BeamShape, CovArr, ShapeOfCov, xref, yref, xlen, ylen )
   Real_current  *Beam_Arr;
   cmplx_current *Cov_Arr;
   shape         *ShapeOfBea, *ShapeOfCov;
   double         xref, yref;
   int            xlen, ylen;

   void Convolution( ftid, Cnv_Arr,Map_Arr,ShapeOfMap, Cov_Arr,ShapeOfCov,
                     xlen,ylen,ulen,vlen )
   int            ftid;
   Real_current  *Cnv_Arr, *Map_Arr;
   cmplx_current *Cov_Arr;
   shape         *ShapeOfMap, *ShapeOfCov;
   int            xlen,ylen,ulen,vlen;

   - InitializeFFT initializes work array for the fft, and returns an ftid.

   - BeamFT needs to be called first to transform the beam. The result is the
     uv-coverage, which is saved such that the first axis is the y-axis; the
     second axis is only half the length of the original since the beam is
     symmetrical.
     It returns an id, which allows later calls to identify the array with
     sine and cosine factors.

   - Convolution is called to convolve with this beam array.
*/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/

/*

/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*
   InitializeFFT finds the ftid, and initializes the appropriate work arrays.

   If on entry ftid=0, then new arrays are calculated.
        For INTERNALFFT, fftini is called, which sets global arrays.
        For POWERFFT,    scfc arrays are allocated, then initialized.
   If on entry ftid!=0, then
        For INTERNALFFT, nothing happens.
        For POWERFFT,    scfc array #ftid is returned.
*/
/******************************************************************************/

#if defined(POWERFFT1D) || defined(POWERFFT2D)
typedef struct ftarrays { Real *scfc[2]; struct ftarrays *nextFTARR; } FTARR;
private FTARR *ftarr0 = 0;
#endif

private int InitializeFFT( ftid, xlen, ylen, scfc )
int   ftid;
int   xlen, ylen;
Real *scfc[2];
{
   assert( xlen == NextPow2(xlen), "x-length (%d) not a power of 2", xlen );
   assert( ylen == NextPow2(ylen), "y-length (%d) not a power of 2", ylen );
#ifdef INTERNALFFT
{  void fftini();
   if( ftid == 0 ) {
      fftini(xlen);
      fftini(ylen);
      ftid++;
     *scfc=0; /* keep lint quiet */
   }
   return( ftid );
}
#endif

#ifdef MIRIADFFT
{
   xlen=xlen;ylen=ylen;scfc[0]=scfc[0]; /* keep lint quiet */
   if( ftid == 0 ) ftid++;
   return( ftid );
}
#endif

#if defined(POWERFFT1D) || defined(POWERFFT2D)
{  Real  *rfft1dui(), *rfft2dui();
   cmplx *cfft1di();
   FTARR *ftarr = ftarr0;
   int    id=1;

   if( ftid == 0 ) {
      if( ftarr != 0 ) {
         while( ftarr->nextFTARR != 0 ) { ftarr=ftarr->nextFTARR; id++; }
      }
      Malloc( ftarr, FTARR, 1 ); ftarr->nextFTARR = 0;
      if( id == 1 ) ftarr0 = ftarr;

#ifdef POWERFFT1D
      Malloc( ftarr->scfc[0], Real, xlen+15 );
      scfc[0]=ftarr->scfc[0]; (void)rfft1dui( xlen, ftarr->scfc[0] );
      Malloc( ftarr->scfc[1], cmplx, ylen+15 );
      scfc[1]=ftarr->scfc[1]; (void)cfft1di(  ylen, ftarr->scfc[1] );
#else
      Malloc( ftarr->scfc[0], Real, xlen+15+2*ylen+15 );
      scfc[0]=ftarr->scfc[0]; (void)rfft2dui( xlen, ylen, ftarr->scfc[0] );
      ftarr->scfc[1] = 0;
#endif
      return( id );
   } else {
      while( id<ftid ) { ftarr = ftarr->nextFTARR; id++; }
      scfc[0] = ftarr->scfc[0];
      scfc[1] = ftarr->scfc[1];
   }
}
#endif
}

void fft_deall(ftid) int *ftid; { *ftid=0; }

/*
*/
#if defined(MIRIADFFT) || defined(INTERNALFFT) || defined(POWERFFT1D)
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*
   Do the convolution by means of many 1-d ffts.

   - The scratch arrays are used to store intermediate results of the fourier
     transforming.

   - The routines BeamFT and Convolution get pointers to parallel variables as
     input. When compiling with C*, these are first copied to scratch arrays,
     to avoid lots of communication. The maps then are transferred to and from
     smaller line-sized arrays with which the FFT routines are called.

   Divide up the available scratch space into several arrays.
   (xlen/2+1)*ylen is the allocation for complex scratch planes.
      xlen*ylen    is the allocation for Real    scratch planes.
*/
/******************************************************************************/

private void SetFTScratch( xlen, ylen,  uvPln0,uvLin0,LO,  Map0,Conv0,Cover0 )
int      xlen, ylen;
Fcmplx **uvPln0, **uvLin0; int *LO;
Real   **Map0, **Conv0;
cmplx  **Cover0;
{
   Real *GetScrAddress();
   Real *FFTScratch = GetScrAddress();
   int   size = (xlen/2+1)*ylen;
   int   offset;

   TRACE("SetFTScratch");
   *uvPln0 = (Fcmplx *)(FFTScratch       ); offset = 2*size;
   *uvLin0 = (Fcmplx *)(FFTScratch+offset);
#ifdef mips
   offset += 2*size;     *LO=1;
#else
   offset += 2*(xlen+2); *LO=0;
#endif
   *Map0   = (Real  *)(FFTScratch+offset); offset +=   size;
   *Cover0 = (cmplx *)(FFTScratch+offset); offset += 2*size;
   *Conv0  = (Real  *)(FFTScratch+offset); offset +=   size;
}

/******************************************************************************/
/*
   Change the calls to get the right function.
   If MIRIADFFT BeamFT and Convolution must call fortran routines,
   else they call internal fft routines.
*/
/******************************************************************************/

#ifdef MIRIADFFT
#define fftrc fftrc_
#define fftcc fftcc_
#define fftcr fftcr_
#endif /* MIRIADFFT */

#if defined(MIRIADFFT) || defined(INTERNALFFT)
#  define FFTRCx(s,l,a)        fftrc( a, a, &s, &l )
#  define FFTCRx(s,l,a)        fftcr( a, a, &s, &l )
#  define GetCol(a,ul,yl,c,vl) Get_Column( a,ul,yl, c,vl )
#  define PutCol(a,ul,vl,c)    Put_Column( a,ul,vl, c    )
#  define FFTCCy(s,xl,yl,c)    fftcc( c, c, &s, &yl )
   void fftrc(), fftcc(), fftcr();
   private void Get_Column(), Put_Column();
#endif
#ifdef POWERFFT1D
#  define FFTRCx(s,l,a)        rfft1du( s, l, a, 1, scfc[0] )
#  define FFTCRx(s,l,a)        rfft1du( s, l, a, 1, scfc[0] )
#  define GetCol(a,ul,yl,c,vl) uvLin = uvPln
#  define PutCol(a,ul,vl)
#  define FFTCCy(s,xl,yl,c)    cfft1d( s, yl, c, xl, scfc[1] )
   int sfft1du(), cfft1d();
#endif

#ifdef mips
#pragma no side effects(fftrc)
#pragma no side effects(fftcr)
#pragma no side effects(fftcc)
#pragma no side effects(Get_Column)
#pragma no side effects(Put_Column)
#endif

/******************************************************************************/
/* Old: needs to be adapted for 'DEBUGLEVEL' routine */
/*
#ifdef TEST
void Check_uv();
#define UVCHECK(flag) \
        Check_uv(flag,(flag==1|flag==4?y:u),(flag==1|flag==4?xlen:vlen), \
                 uvPln,Line,uvLin,uvLin,uvPln)
#else
#define UVCHECK(flag)
#endif
*/
/******************************************************************************/

/*

/******************************************************************************/
/*
   Calculate the fourier transform of the beam, and store it. This prepares for
   convolutions.
   Arguments: CovArr  = start address of where tranformed beam will be stored
              BeamArr = start address of beam array
              xref, yref = phase center of beam
              xlen, ylen = size of beam

   The Line array is used to read the beam. The resulting uv coverage is stored
   in the Memory array. A phase term is applied, which is equivalent to shifting
   the image to that the reference pixel of the input is at absolute pixel
   (1,1); xref and yref give the crpix of the beam dataset.

   Pass 1: FT all rows
      - Read a line from the beam into Line
      - FT the line (xlen long) and store it in uvPln
        uvPln becomes a plane ulen_h wide and ylen high, which is why the beam
        beam cannot be read as one plane, since the last element of each line is
        special.
   Pass 2: FT all columns
      - Read column from uvPln, ylen long; save in uvLin
      - FT the column (vlen long) and store it in uvLin
      - Add phase shift to uvLin and take the real part
      - Save in Memory: the beam array becomes a plane vlen wide and ulen_h
        high, i.e. it is transposed. The transformed beam array is transposed
        for easier use later on, since then elements are accessed in memory
        sequence when transforming in y.
*/
/******************************************************************************/

int BeamFT( Beam_Arr, ShapeOfBea, Cov_Arr, ShapeOfCov, xref,yref, xlen,ylen )
Real_current  *Beam_Arr;
cmplx_current *Cov_Arr;
shape         *ShapeOfBea, *ShapeOfCov;
double         xref, yref;
int            xlen, ylen;
{
   private void     SetFTScratch();
   private int      InitializeFFT();
   void             PhaseShift();
   int              ftid;
   Real            *scfc[2];
   register int     x, y, u;
            int     ulen = xlen;
            int     vlen = ylen;
   register int     ulen_h = ulen/2+1;

            Real   *Conv0;
   register Real   *Beam;  Real  *Beam0;
   register cmplx  *Cover; cmplx *Cover0;
   register Fcmplx *uvPln, *uvLin; Fcmplx *uvPln0, *uvLin0; int LO;
   register Float  *Line;

   SetFTScratch( xlen, ylen, &uvPln0,&uvLin0,&LO, &Beam0,&Conv0,&Cover0 );
#ifdef __CSTAR__
   with( *ShapeOfBea ) read_from_pvar( Beam0, *Beam_Arr );
   /* Cover0 = allocated scratch space */
#else
   ShapeOfBea = ShapeOfBea; /* keep lint quiet */
   ShapeOfCov = ShapeOfCov; /* keep lint quiet */
   Beam0  = (Real  *)Beam_Arr;
   Cover0 = (cmplx *)Cov_Arr;
#endif

   ftid = InitializeFFT( 0, xlen, ylen, scfc );

   TRACE("BeamFT-Pass1");
#ifdef COMPILE_PARALLEL
#pragma parallel byvalue(ulen_h,xlen,ylen,FWD)
#pragma          local(x,y,uvPln,Line,Beam) shared(uvPln0,Beam0)
{
#pragma pfor iterate(y=0;ylen;1)
#else
{
#endif
   for( y=0; y<ylen; y++ ) {
      Beam  = (Real   *)(Beam0  + y*xlen  );
      uvPln = (Fcmplx *)(uvPln0 + y*ulen_h);
      Line  = (Float  *)(uvPln);
      for( x=0; x<xlen; x++ ) *(Line+x) = *(Beam+x);
      FFTRCx( FWD, xlen, uvPln );
   }
}
   OpCnt(ylen*xlen, 1,1, 0, 0,0);
   FFTOpCnt("fftrc",FWD,ylen,xlen);


   TRACE("BeamFT-Pass2");
#ifdef COMPILE_PARALLEL
#pragma parallel byvalue(FWD,ulen_h,vlen,LO)
#pragma          local(u,uvPln,uvLin) shared(uvPln0,uvLin0)
{
#pragma pfor iterate(u=0;ulen_h;1)
#else
{
#endif
   for( u=0; u<ulen_h; u++ ) {
      uvPln = (Fcmplx *)(uvPln0 + u);
      uvLin = (Fcmplx *)(uvLin0 + u*vlen*LO);
      GetCol( uvPln, ulen_h, vlen, uvLin, vlen );
      FFTCCy( FWD,   ulen_h, vlen, uvLin );
      PutCol( uvPln, ulen_h, vlen, uvLin );
   }
}
   OpCnt(ulen_h*vlen, 4,4, 0, 0,0); /* GetCol+PutCol */
   FFTOpCnt("fftcc",FWD,ulen_h,vlen);

   Cover = ( cmplx *)Cover0;
   uvPln = (Fcmplx *)uvPln0;
   PhaseShift( Cover, uvPln, ulen, vlen, xref, yref, TRUE );
   FFTOpCnt("PhaseShift",0,ulen,vlen);


#ifdef __CSTAR__
   with( *ShapeOfCov ) *Cov_Arr = write_to_pvar( (Real *)Cover0 );
#endif

   return( ftid );
}

/*

/******************************************************************************/
/*
   Do the convolution.
   Arguments: CnvArr = start address of output map
              MapArr = start address of map to convolve
              CovArr = start address of transposed, transformed beam
              xlen, ylen = size of map
              ulen, vlen = size of beam

   Pass 1: Perform the row FT
      - Zero pad the end of the array used for FFT's
      - Extract the appropriate data from MapArr and store it in Line
      - FT the resulting row and store in uvPln; if all pixels are 0 do no FT,
        just set result to zero
        uvPln becomes a plane ulen_h wide, ylen high
   Pass 2: Perform the column FFT row by row and multiply by the beam
      - Read column from scratch into uvLin (length vlen, padded with zeroes
        past ylen)
        Scratch is a plane ulen_h wide and ylen high
      - FT the column and store in uvLin
      - Multiply by the beam, stored as array CovArr, vlen wide and ulen_h high
      - Inverse transform column, and put it back into uvPln
   Pass 3: Perform the final pass of the FT
      - Inverse transform rows of scratch array uvPln (which is ulen_h wide and
        ylen high) into Line
      - Save the result in CnvArr

   First do some definitions to be able to save the uv plane. The functions that
   they call are near the definition of "SaveSet", since these use some internal
   variables.
*/
/******************************************************************************/

void Convolution( ftid, Cnv_Arr,Map_Arr,ShapeOfMap, Cov_Arr,ShapeOfCov,
                  xlen,ylen,ulen,vlen )
int            ftid;
Real_current  *Cnv_Arr, *Map_Arr;
cmplx_current *Cov_Arr;
shape         *ShapeOfMap, *ShapeOfCov;
int            xlen,ylen,ulen,vlen;
{
   private void      SetFTScratch();
   private int       InitializeFFT();

   Real             *scfc[2];

   register int      x, y, u, v;
   register int      ulen_h = ulen/2+1;

            logical  Sel[1024];
   register Real    *Map;   Real  *Map0;
   register Real    *Conv;  Real  *Conv0;
   register cmplx   *Cover; cmplx *Cover0;
   register Fcmplx  *uvPln, *uvLin; Fcmplx *uvPln0, *uvLin0; int LO;
   register Float   *Line;

   Timer_Cont("CONV");

   SetFTScratch( ulen, vlen, &uvPln0,&uvLin0,&LO, &Map0,&Conv0,&Cover0 );
#ifdef __CSTAR__
   with( *ShapeOfMap ) read_from_pvar( (Real *)Map0,   *Map_Arr );
   with( *ShapeOfCov ) read_from_pvar( (Real *)Cover0, *Cov_Arr );
   /* Conv0 = allocated scratch space */
#else
   ShapeOfMap = ShapeOfMap; /* keep lint quiet */
   ShapeOfCov = ShapeOfCov; /* keep lint quiet */
   Map0   = (Real  *)Map_Arr;
   Cover0 = (cmplx *)Cov_Arr;
   Conv0  = (Real  *)Cnv_Arr;
#endif


   (void)InitializeFFT( ftid, ulen, vlen, scfc );


   TRACE("Convolution-Pass1");
#ifdef COMPILE_PARALLEL
#pragma parallel byvalue(FWD,xlen,ylen,ulen,ulen_h)
#pragma          local(x,y,u,Map,uvPln,Line) shared(Map0,Sel,uvPln0)
{
#pragma pfor iterate(y=0;ylen;1)
#else
{
#endif
   for( y=0; y<ylen; y++ ) {
      Map   = (Real   *)(Map0   + y*xlen  );
      uvPln = (Fcmplx *)(uvPln0 + y*ulen_h);
      Line  = (Float  *)(uvPln);
      Sel[y]=FALSE;
      for(x=0;x<xlen;x++) { Sel[y] |= (*(Map+x)!=0.); *(Line+x) = *(Map+x); }
      if(ulen>xlen) { for(;x<ulen;x++) *(Line+x)=0.; }
      if(Sel[y]) { FFTRCx( FWD, ulen, uvPln ); }
      else       { for( u=0; u<ulen_h; u++ ) {
                        (*(uvPln+u)).real= (*(uvPln+u)).imag = 0.; } }
   }
}
   OpCnt(ylen*xlen,     2,3, 0, 2,0);
   OpCnt(ylen/2*ulen_h, 2,0, 0, 0,0);
   FFTOpCnt("fftrc",FWD,ylen,ulen);


   TRACE("Convolution-Pass2");
#ifdef COMPILE_PARALLEL
#pragma parallel byvalue(FWD,BWD,ylen,ulen_h,vlen,LO)
#pragma          local(y,u,v,Cover,uvPln,uvLin)shared(Cover0,uvPln0,uvLin0)
{
#pragma pfor iterate(u=0;ulen_h;1)
#else
{
#endif
   for( u=0; u<ulen_h; u++ ) {
      uvPln = (Fcmplx *)(uvPln0 + u     );
      Cover = ( cmplx *)(Cover0 + u*vlen);
      uvLin = (Fcmplx *)(uvLin0 + u*vlen*LO);
      GetCol( uvPln,ulen_h,ylen, uvLin,vlen );
      FFTCCy( FWD,  ulen_h,vlen, uvLin );

      for( v=0; v<vlen; v++ ) {
         (*(uvLin+v)).real *= (*(Cover+v)).real;
         (*(uvLin+v)).imag *= (*(Cover+v)).real;
      }
      FFTCCy( BWD,  ulen_h,vlen, uvLin );
      PutCol( uvPln,ulen_h,ylen, uvLin );
   }
}
   OpCnt(ulen_h*ylen, 4,4, 0, 4,0); /* GetCol+PutCol */
   OpCnt(ulen_h*vlen, 2,4, 0, 2,0);
   FFTOpCnt("fftcc",FWD,ulen_h,vlen);
   FFTOpCnt("fftcc",BWD,ulen_h,vlen);


   TRACE("Convolution-Pass3");
#ifdef COMPILE_PARALLEL
#pragma parallel byvalue(BWD,xlen,ylen,ulen,ulen_h)
#pragma          local(x,y,uvPln,Line,Conv) shared(uvPln0,Conv0)
{
#pragma pfor iterate(y=0;ylen;1)
#else
{
#endif
   for( y=0; y<ylen; y++ ) {
      uvPln = (Fcmplx *)(uvPln0 + y*ulen_h);
      Line  = (Float  *)(uvPln);
      Conv  = (Real   *)(Conv0  + y*xlen );
      FFTCRx( BWD, ulen, uvPln );
      for( x=0; x<xlen; x++ ) *(Conv+x) = *(Line+x);
   }
}
   OpCnt(ylen*xlen, 1,1, 0, 0,0);
   FFTOpCnt("fftcr",BWD,ylen,ulen);


#ifdef __CSTAR__
   with( *ShapeOfMap ) *Cnv_Arr = write_to_pvar( (Real *)Conv0 );
#endif

   Timer_Stop("CONV");
}

/******************************************************************************/

private void Get_Column( plane, xlen, ylen, column, clen )
Fcmplx *plane;
int     xlen,ylen;
Fcmplx *column;
int     clen;
{
   register int y=0;
   while(y<ylen) { (*(column+y)).real = (*(plane+y*xlen)).real;
                   (*(column+y)).imag = (*(plane+y*xlen)).imag;  y++; }
   while(y<clen) { (*(column+y)).real = (*(column+y)).imag = 0.; y++; }
}
private void Put_Column( plane, xlen, ylen, column )
Fcmplx *plane;
int     xlen,ylen;
Fcmplx *column;
{
   register int y=0;
   while(y<ylen) { (*(plane+y*xlen)).real = (*(column+y)).real;
                   (*(plane+y*xlen)).imag = (*(column+y)).imag; y++; }
}

#endif /* MIRIADFFT || INTERNALFFT */

/*
*/
#ifdef CMSSLFFT
/******************************************************************************/
/*
   Prepare for the convolution.
   CovArr is a two-dimensional complex conjugate array, for which separate
   memory was allocated earlier on.
   First prepare for the real to complex FFT. Then copy all elements of the
   input 1-d real array BeamArr to the appropriate position in CovArr.
   Next do the FFT. Finally multiply the result by a phase factor to make pixel
   1,1 the phase center.
*/
/******************************************************************************/

private void SetFTScratch( xlen, ylen );
int   xlen, ylen;
{;}

int BeamFT( BeamArr, BeamShape, CovArr, ShapeOfCov, xref, yref, xlen, ylen )
cmplx:void  *CovArr;
shape       *ShapeOfCov;
double:void *BeamArr;
shape       *BeamShape;
double       xref, yref;
int          xlen, ylen;
{
   void   fft2D_s_c(),fft2D_do_c();
   void   ConvertShape();
   int    ftid, ier;
   double ThetaX = M_TWOPI * (xref-ONE) / (double)xlen;
   double ThetaY = M_TWOPI * (yref-ONE) / (double)ylen;
   shape  covshape = *ShapeOfCov;
   cmplx:covshape Rotu, Rotv, PhaseFactor;

   TheShape = *ShapeOfCov;  /* CovArr declared to be of shape 'TheShape' */
   fft2D_s_c( CovArr, &xlen, &ylen, fft_cc_xform, &ftid, &ier );

   ConvertShape( "RTOC", BeamArr, CovArr, xlen,ylen,xlen,ylen );

   fft2D_do_c(
      CovArr, &xlen, &ylen,
      fft_cc_xform, fft_forward, fft_bits_normal, fft_bits_normal, fft_noscale,
      &ftid, &ier );

   with( *ShapeOfCov ) {
      cpxEqAP( Rotu, ONE, pcoord(0)*ThetaX );
      cpxEqAP( Rotv, ONE, pcoord(1)*ThetaY );
      cpxMul(  PhaseFactor, Rotu, Rotv );
      cpxMul( *CovArr, PhaseFactor, *CovArr );
   }

   return( ftid );
}

/******************************************************************************/
/*
   Convolve a map with the prepared uv-coverage.
   First convert the 1-d real input array MapArr to a 2-d complex conjugate
   array, TmpArr. This is really an complex array in which all imaginary parts
   are zero, but it is stored as a complex array with half the length in x.
   Then do the FFT on it. Multiply by the uv-coverage. Do the
   backward FFT. Finally copy it back to a 1-d real array, CnvArr.
*/
/******************************************************************************/

void Convolution( ftid, CnvArr,MapArr,ShapeOfMap, CovArr,ShapeOfCov,
                  xlen,ylen,ulen,vlen )
int          ftid;
double:void *CnvArr, *MapArr;
cmplx:void                    *CovArr;
shape       *ShapeOfMap,      *ShapeOfCov;
int          xlen,ylen,ulen,vlen;
{
   void            fft2D_do_c();
   private void    ConvertShape();
   int             ier;
   shape           covshape = *ShapeOfCov;
   cmplx:covshape  TempArr;
   cmplx:covshape *TmpArr = &TempArr;

   Timer_Cont("CONV");

   TheShape = *ShapeOfCov; /* CovArr declared to be of shape 'TheShape' */

   ConvertShape( "RTOC", MapArr, TmpArr, xlen,ylen,ulen,vlen );

   fft2D_do_c(
      TmpArr, &ulen, &vlen,
      fft_cc_xform, fft_forward, fft_bits_normal, fft_bits_normal, fft_noscale,
      &ftid, &ier );

   with( *ShapeOfCov ) {
      TmpArr->real *= CovArr->real;
      TmpArr->imag *= CovArr->real;
   }

   fft2D_do_c(
      TmpArr, &ulen, &vlen,
      fft_cc_xform, fft_inverse, fft_bits_normal, fft_bits_normal, fft_scale_n,
      &ftid, &ier );

   ConvertShape( "CTOR", CnvArr, TmpArr, xlen,ylen,ulen,vlen );

   Timer_Stop("CONV");
}

/******************************************************************************/
/*
   Convert between a one-dimensional real array and a two-dimensional complex
   conjugate array.
*/
/******************************************************************************/

private void ConvertShape( dir, RealArr, cmplxArr, xlen, ylen, ulen, vlen )
char           *dir;
double:current *RealArr;
cmplx:ShapeOfCov *cmplxArr;
int             xlen, ylen, ulen, vlen;
{
   if(        StrEq( dir, "RTOC" ) ) {
      with( ShapeOfCov ) { cmplxArr->real = cmplxArr->imag = 0.; }
      with( current ) {
        [pcoord(0)%xlen][pcoord(0)/xlen]cmplxArr->real = [pcoord(0)](*RealArr);
      }
   } else if( StrEq( dir, "CTOR" ) ) {
      with( current ) {
        [pcoord(0)](*RealArr) = [pcoord(0)%xlen][pcoord(0)/xlen]cmplxArr->real;
      }
   }
}

#endif /* CMSSLFFT */

/*
*/
#ifdef POWERFFT2D
/******************************************************************************/
/*
   Do the convolution using the fft routines on the SGI power Challenge.
*/
/******************************************************************************/

private void SetFTScratch( xlen, ylen, uvPln0 )
int     xlen, ylen;
cmplx **uvPln0;
{
   Real *GetScrAddress();
   Real *FFTScratch = GetScrAddress();
   *uvPln0 = (cmplx *)(FFTScratch );
}

/******************************************************************************/
/*
   Calculate the fourier transform of the beam, and store it. This prepares for
   convolutions.
   Arguments: CovArr  = start address of where tranformed beam will be stored
              BeamArr = start address of beam array
              xref, yref = phase center of beam
              xlen, ylen = size of beam

   - First allocate the workspace arrays for the forward and backward transforms
     Initialize the workspace.
   - Copy the beam to a new array that is 1 longer in X, which is what the fft
     routines need.
   - Do the FFT.
   - Calculate and apply the phase factor, which reflects that the zero
     frequency is actually in the center of the map. In this step the scaling is
     done also.
*/
/******************************************************************************/

int BeamFT( Beam_Arr, ShapeOfBea, Cov_Arr, ShapeOfCov, xref,yref, xlen,ylen )
Real   *Beam_Arr;
cmplx  *Cov_Arr;
shape  *ShapeOfBea, *ShapeOfCov;
double  xref, yref;
int     xlen, ylen;
{
   Real           *rfft2dui();
   int             rfft2du();
   private int     InitializeFFT();
   void            PhaseShift();

   int             ftid;
   Real           *scfc[2];

   register int    x, y;
   register int    ulen   = xlen, ulen2=xlen+2;
   register int    vlen   = ylen;
   register int    ulen_h = ulen2/2;
   register int    xy, xysize=ulen2*ylen;

   register Real  *Beam, *BeamE;
   register cmplx *Cover;

   ftid = InitializeFFT( 0, xlen, ylen, scfc );

   TRACE("BeamFT-Pass1");
   Beam  =          Beam_Arr;
   BeamE = (Real  *)Cov_Arr;
   Cover = (cmplx *)Cov_Arr;
   for( xy=0; xy<xysize; xy++ ) {
      x=xy%ulen2; y=xy/ulen2;
      *(BeamE+xy) = x<xlen ? *(Beam+y*xlen+x) : 0.;
   }

   TRACE("BeamFT-Pass2");
   (void)rfft2du( FWD, xlen, ylen, Cover, 2*ulen_h, scfc[0] );

   TRACE("BeamFT-Pass3");
   PhaseShift( Cover, Cover, ulen,vlen, xref,yref, FALSE );

   return( ftid );
}

/******************************************************************************/
/*
   Do a 2D real with real convolution of Map_Arr to Cnv_Arr with Cov_Arr.

   Do the convolution.
   Arguments: CnvArr = start address of output map
              MapArr = start address of map to convolve
              CovArr = start address of transposed, transformed beam
              xlen, ylen = size of map
              ulen, vlen = size of beam

   - First find the workspace array from the ftid.
   - Then copy Map_Arr into the scratch space. This is needed because the fft
     routine wants an input array with first dimension of at least 2*((xlen+2)/2
     so that the size of the Cnv_Arr is just too small. Further, if the map is
     smaller than the beam, extend it with zeroes.
   - Fourier transform the map.
   - Next calculate the product of this fourier transform with the uv-coverage,
     Cov_Arr.
   - Then do the backward transform of the product.
   - Copy the result to Cnv_Arr.
*/
/******************************************************************************/

void Convolution( ftid, Cnv_Arr,Map_Arr,ShapeOfMap, Cov_Arr,ShapeOfCov,
                  xlen,ylen,ulen,vlen )
int    ftid;
Real  *Cnv_Arr, *Map_Arr;
cmplx *Cov_Arr;
shape *ShapeOfMap, *ShapeOfCov;
int    xlen,ylen,ulen,vlen;
{
   int             rfft2du();
   void            cprod2d();
   private void    SetFTScratch();
   private int     InitializeFFT();

   Real           *scfc[2];

   register int    x, y, u, v;
   register int    ulen_h = ulen/2+1;
   register int    xlen_e = 2*ulen_h;
   register int    xy, xysize=xlen*ylen;
   register int    uv, uvsize=ulen_h*vlen;

   register Real  *Map, *MapE, *Conv;
   register cmplx *Cover, *uvPln; cmplx *uvPln0;

   Timer_Cont("CONV");

   SetFTScratch( ulen, vlen, &uvPln0 );
   (void)InitializeFFT( ftid, ulen, vlen, scfc );

   Map   =          Map_Arr;
   MapE  = (Real  *)uvPln0;
   uvPln = (cmplx *)uvPln0;
   Cover = (cmplx *)Cov_Arr;
   Conv  =          Cnv_Arr;

   TRACE("Convolution-Pass1");
   for( xy=0; xy<2*uvsize; xy++ ) *(MapE+xy) = 0.;
   for( xy=0; xy<xysize;   xy++ ) {
      *( MapE + (xy/xlen)*xlen_e + (xy%xlen) ) = *( Map + xy );
   }
   (void)rfft2du( FWD, ulen, vlen, MapE,  2*ulen_h, scfc[0] );


   TRACE("Convolution-Pass2");
   (void)cprod2d(    ulen_h, vlen, uvPln,   ulen_h, Cover, ulen_h );


   TRACE("Convolution-Pass3");
   (void)rfft2du( BWD, ulen, vlen, MapE,  2*ulen_h, scfc[0] );
   for( xy=0; xy<xysize; xy++ ) {
      *( Conv + xy ) = *( MapE + (xy/xlen)*xlen_e + (xy%xlen) );
   }

   Timer_Stop("CONV");
}

#endif /* POWERFFT2D */
