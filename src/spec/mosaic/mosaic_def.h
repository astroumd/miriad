/*----------------------------------------------------------------------------
-- mosaic_def.h --
/*----------------------------------------------------------------------------*/

/******************************************************************************/
/* <<< DEFINITIONS >>>                                 211 +  185 =  396 SETUP
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*
  DEFINITIONS FOR GENERAL USE
*/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*    <<< Compiler Switches >>                           5 +   35 =   40 SETUP
/******************************************************************************/
/*
   Symbol defined at compile time to indicate the current machine:
      sun              Sun workstation
      cm5              TMC connection machine 5
      convex           Convex c3
      mips             Silicon Graphics IRIX

   Other symbols defined at compile time
      __main__         name of main entry point (used in _main.c)
      DTMIO            if defined: compile with DTM routines (used in _dtm.c)
      SYSV             Compiled under system V (used in _timer.c)
      DODISKIO         if defined: can access miriad IO (used in _io.c)
      .....FFT         need to define one of the FFT symbols in _fft.c/P_conv.c)
                       (MIRIADFFT, INTERNALFFT, CMSSLFFT, POWERFFT2D)

   Internally defined symbols
      DEFVARS          set in one of the files to get global variables (_main.c)
      __CSTAR__        TRUE if compiled with the cs compiler; cm5 only
      XYIO or XYZIO    indicates which IO routines to use (_io.c)
      LINEIO or PLANEIO indicates how to do IO (_io.c)
      COMPILE_PARALLEL parallel FT on mips if set (P_conv.c)
      TIME_FFT         if set, time the internals of the FFT
      DTM_2CONN        if set, DTM knows about HiPPI (_dtm.c)

   To avoid double definitions, but to also ensure that definitions are right
   whether DEFVARS is on or off, define "Global". At the end of the mosaic.h
   file "Global" is always made equal to "extern".
*/
/******************************************************************************/

#if defined(DEFVARS)
#define Global
#else
#define Global extern
#endif

#if defined(sun) || defined(mips) || defined(linux)
#define private static
#else
#define private
#endif

/*

/******************************************************************************/
/*    <<< Include files >>>                             26 +   21 =   47 SETUP
/******************************************************************************/

/* standard IO */
#include <stdio.h>
int pclose(), _filbuf();

/* character types */
#include <ctype.h>

/* math */
#include <math.h>

/* standard string functions */
#include <string.h>
#if defined(sun) || defined(cm5)
#include <memory.h>
#endif

/* memory allocation
#if defined(convex) || defined(cm5) || defined(mips)
#include <stdlib.h>
#else
#include <malloc.h>
#endif*/
#include <stdlib.h>

/* variable arguments */
#if ( defined(sun) && !defined(cm5) ) || defined(convex) || defined(mips)
#   include <varargs.h>
#   define va_FUNC(function,type1,arg1) function(va_alist) va_dcl
#   define va_START(args,type1,arg1)    type1 arg1; va_start(args); \
                                        arg1=va_arg(args,type1)
#else
#   include <stdarg.h>
#   define va_FUNC(function,type1,arg1) function(type1 arg1,...)
#   define va_START(args,type1,arg1)    va_start(args,arg1)
#endif

#define N_NODES   128  /* number of CM5 nodes                                 */

/* from $MIRINC/maxdimc.h */
#define MAXNAX      7  /* maximum number of axes a dataset can have           */
#define MAXCHAN  2048  /* maximum number of planes;   Region struct array size*/

/*

/******************************************************************************/
/*    <<< New datatypes >>>                             38 +   47 =   85 SETUP
/******************************************************************************/
/*
   Decide whether to use double precision or single precision arrays and/or
   variables. On normal machines single precision is sufficient, and it saves
   memory. On the CM-5 double precision is more efficient.
   So, define the variable type Real, which will be "double", but "float" if
   that is not needed or wanted. Actually, the image arrays are defined as:
   "Real_current", which translates into "double:current" on the CM-5 and into
   "double" or "float" otherwise

   For some internal variables it matters whether or not they are double or
   float, since they are set by external subroutines. For others it does not
   matter at all since they are used just a few times. Usually "double" is used
   by the external routines. Therefore, to avoid extra conversion complications,
   most internal variables are of type "double". Only in those cases that a
   variable is used inside a loop, is it defined as "Real", which may mean
   "double" or "float", depending on which one is better.
*/
/******************************************************************************/

#if defined(__CSTAR__)
#   define Real double
#   define REAL_IS_DOUBLE
#else
#   define Real float
#endif

/******************************************************************************/
/*
   logical
   (fortran TRUE and FALSE are returned by the io routines for the mask)
*/
/******************************************************************************/

#define logical int
#define FALSE 0
#define TRUE  1

#if defined(convex)
#   define FORT_TRUE -1
#else
#   define FORT_TRUE  1
#endif
#define FORT_FALSE 0

/******************************************************************************/
/*
   complex numbers
*/
/*****************************************************************************/

typedef struct { Real real, imag; } cmplx;
#define cpxEq(c1,c2)   ((c1)).real=((c2)).real; ((c1)).imag=  ((c2)).imag
#define cpxCJ(c1,c2)   ((c1)).real=((c2)).real; ((c1)).imag= -((c2)).imag
#define cpxEqRI(c,r,i) ((c)).real=(r); ((c)).imag=(i)
#define cpxEqAP(c,a,p) ((c)).real=(a)*cos((p)); ((c)).imag=(a)*sin((p))
#define cpxAbs(c)      sqrt( square( ((c)).real ) + square( ((c)).imag ) )
#define cpxPhase(c)    atan2( ((c)).imag, ((c)).real )
#define cpxAdd(c,a,b)  ((c)).real = ((a)).real + ((b)).real;  \
                       ((c)).imag = ((a)).imag + ((b)).imag
#define cpxSub(c,a,b)  ((c)).real = ((a)).real - ((b)).real;  \
                       ((c)).imag = ((a)).imag - ((b)).imag
#define cpxMul(c,a,b)  ((c)).real = ((a)).real * ((b)).real - \
                                    ((a)).imag * ((b)).imag;  \
                       ((c)).imag = ((a)).real * ((b)).imag + \
                                    ((a)).imag * ((b)).real

/******************************************************************************/
/*
   axis
*/
/******************************************************************************/

#define AXIS enum axnums
AXIS    { AXIS1, AXIS2, AXIS3, AXIS4, AXIS5, AXIS6, AXIS7, RA_SEC, NOAX };
#define RA_AXIS AXIS1
#define DC_AXIS AXIS2
#define FQ_AXIS AXIS3

#define AxisToInt(a) (a)+1
#define IntToAxis(a) (a)-1

/******************************************************************************/
/*
   IOmodes
*/
/******************************************************************************/

#define IOmodes enum IOMODES
IOmodes { READ, WRITE, COPY };

/*

/******************************************************************************/
/*    <<< Basic definitions >>>                         70 +   20 =   90 SETUP
/******************************************************************************/
/*
   Several basic definitions to make life easier.
   - math definitions and simple functions
   - easier string functions
*/
/******************************************************************************/

Global Real TMPVAL;

#define ZERO     0.0
#define ONE      1.0
#define FOURLN2  2.77258872223978123768
#define M_TWOPI  6.28318530717958667692
#define MIN_REAL 1.E-38
#define MAX_REAL 1.E+38

#define Procent(a) 100.0*(a)
#define signum(a)  ( (a) >= ZERO ? ONE : -ONE )
#ifdef __CSTAR__
#   define max(a,b)    ( (a) >?  (b) )
#   define min(a,b)    ( (a) <?  (b) )
#   define assmax(a,b) ( (a) >?= (b) )
#   define assmin(a,b) ( (a) <?= (b) )
#else
#   define max(a,b)          ( (a) >= (b) ? (a) : (b) )
#   define min(a,b)          ( (a) <= (b) ? (a) : (b) )
#   define assmax(a,b) (a) = ( (a) >= (b) ? (a) : (b) )
#   define assmin(a,b) (a) = ( (a) <= (b) ? (a) : (b) )
#endif
#if defined(convex) || defined(mips)
#define nint(a)   ( (TMPVAL=(a))>=ZERO ? (int)(TMPVAL+.5) : -(int)(-TMPVAL+.5) )
#endif
#define mod(a,b)  ( (a) - ((a)/(b))*(b) )
#define square(a) ( (a) * (a) )
#define dist(a,b) ( sqrt( (a)*(a) + (b)*(b) ) )
#define between(a,b,c) ( (a) <= (b) ) & ( (b) <= (c) )
#define EXP(x)        ( (TMPVAL=(x)) > -20.0 ? exp(TMPVAL) : ZERO )
#define pEXP(p,x) p = (      (p=(x)) > -20.0 ? exp(p)      : ZERO )

#define Fprintf       fprintf
#define Sprintf       sprintf
#define StrCpy(a,b)   (void)strcpy((a),(b))
#define StrCat(a,b)   (void)strcat((a),(b))
Global int LA, LB;
#define StrEqX(a,b) (!memcmp((a),(b),((LA=strlen((a)))>=(LB=strlen((b)))?LA:LB)))
#define StrEq(a,b)    (!memcmp((a),(b),strlen((b))))
#define StrEqN(a,b,n) (!memcmp((a),(b),(n)))
#define fEq(a,b)      (fabs((Real)((a)/(b)-ONE))<1.E-5)

#define FILENAMELEN 256
#define INSTRLEN     20
#define OUTSTRLEN   128

/******************************************************************************/
/*
   all conversions between radians, degrees, arcminutes and arcseconds
*/
/******************************************************************************/

#define SECpMIN      60
#define SECpDEG    3600
#define MINpDEG      60
#define HOURpDAY     24
#define DEGpHOUR     15
#define MINpHOUR     60
#define SECpHOUR   3600
#define M_RADIAN      57.2957795130823228646
#define M_1_RADIAN     0.0174532925199432954
#define rtod(a) (a)*M_RADIAN
#define rtom(a) (a)*M_RADIAN*MINpDEG
#define rtos(a) (a)*M_RADIAN*SECpDEG
#define dtor(a) (a)*M_1_RADIAN
#define dtom(a) (a)*MINpDEG
#define dtos(a) (a)*SECpDEG
#define mtor(a) (a)*M_1_RADIAN/MINpDEG
#define mtod(a) (a)/MINpDEG
#define mtos(a) (a)*SECpMIN
#define stor(a) (a)*M_1_RADIAN/SECpDEG
#define stod(a) (a)/SECpDEG
#define stom(a) (a)/SECpMIN

/*

/******************************************************************************/
/*    <<< C and C* >>>                                  57 +   20 =   77 SETUP
/******************************************************************************/
/*
   Below are some (re)definitions that allow the rest of the program to look
   like C*, even if it is really C.

   For standard C, define a struct type 'shape', which contains the total and
   the x-length of the array.

   The 'with' statement uses this struct to find the loop length and folding.
   Define the with, where and everywhere statements.

   The MemPixNum counter is used to find an element in a serial array by adding
   this number to a start address, and to loop over an image.

   Dereferencing a parallel arrays differs for C* and C, so p_arr(p) is defined
   Elem extracts a single value from a parallel array.
   Examples:
   CM5     *p_arr(p_x)   becomes    *p_x
   mips    *p_arr(p_x)   becomes    *(p_x+MemPixNum)
   other   *p_arr(p_x)   becomes    *(p_x+MemPixNum)

   New 'datatypes' are #defined to indicate parallel arrays in C*.
*/
/******************************************************************************/

#define TimerStartParallel Timer_Cont("PARALLEL");
#define TimerStopParallel  Timer_Stop("PARALLEL");
void Timer_Cont(), Timer_Stop();


#ifndef __CSTAR__
typedef struct { int start, end, size, xlen, ylen, nsel; } shape;
shape *current;
#endif

Global int MemPixNum;

#ifdef __CSTAR__

#define int_void        int:void
#define logical_void    logical:void
#define Real_void       Real:void
#define double_void     double:void
#define cmplx_void      cmplx:void
#define int_current     int:current
#define Real_current    Real:current
#define double_current  double:current
#define cmplx_current   cmplx:current
#define logical_current logical:current

#define p_arr(p)     p
#define P_arr(p)     p
#define Elem(n,p0) [n]*p0

#define ArrayCoord      pcoord(0)
#define with_current    with(current)

#include <cscomm.h>

#else /* !__CSTAR */

#define int_void        int
#define logical_void    logical
#define Real_void       Real
#define double_void     double
#define cmplx_void      cmplx
#define int_current     int
#define Real_current    Real
#define double_current  double
#define cmplx_current   cmplx
#define logical_current logical

#define p_arr(p)    (p  +MemPixNum)
#define P_arr(p)     p
#define Elem(n,p0) *(p0 +   n     )

#define ArrayCoord      MemPixNum
#define with_current
#define where if
#define everywhere

Global int START, END, XFOLD;
#define with(s) TimerStartParallel \
                START=(&s)->start; END=(&s)->end; XFOLD=(&s)->xlen; \
                for(MemPixNum=START;MemPixNum<END;MemPixNum++)

#endif /* __CSTAR__ */

#define pcoord_x ( ArrayCoord % XFOLD )
#define pcoord_y ( ArrayCoord / XFOLD )
#define Pcoord_X ( ArrayCoord % XFOLD + 1 )
#define Pcoord_Y ( ArrayCoord / XFOLD + 1 )

/*

/******************************************************************************/
/*    <<< Function Definitions >>>                      15 +   24 =   39 SETUP
/******************************************************************************/
/*
   Allocations
*/
/******************************************************************************/

#define Malloc(v,t,NB) \
        assert( ( (v) = (t *)malloc( (unsigned)(NB)*sizeof(t) ) ) != NULL, \
                "failed allocation of %d bytes", (NB)*sizeof(t) )

#define Calloc(v,n) \
        assert( (v = (char *)malloc( (unsigned)(n) ) ) != NULL, \
                "failed allocation of %d bytes", n )

/******************************************************************************/
/*
   Output.
*/
/******************************************************************************/

void dprintf(), wwarning(), assert();
void TRACE(), DBGVAL();
