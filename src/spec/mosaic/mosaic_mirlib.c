/*----------------------------------------------------------------------------
-- mosaic_mirlib.c --
/*----------------------------------------------------------------------------*/
#include "mosaic_stc.h"
/*----------------------------------------------------------------------------*/

/******************************************************************************/
/* <<< MIRIAD LIBRARY >>>                             1724 +  654 = 2378 USERIO
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*
   MIRIAD FORTRAN LIBRARY ROUTINES

   First some routines that are very basic and could have been standard
   provided:
   - MESSAGE, BUG, Abort
   - dprintf, wwarning, assert

   The following routines are included in this file, but are actually
   rewritten-in-C replacements for routines from the miriad library.
   - fndaxnum
   - NextPow2
   - radra, raddec, degra, degdec
   - llsqu, nllsqu, sgefa_lp, sgesl_lp, isamax, sscal_lp, saxpy_lp, sdot_lp

   The following routines are variants optimized or adapted for mosaic, but
   also exist in a different form within the miriad library
   - sinc, airy, polynomial
   - RegionDecode
*/
/******************************************************************************/

/*

/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*    <<< Error functions >>>                          140 +   39 =  179 USERIO
/******************************************************************************/
/*
   First a few simple printing functions.
   - SETDEBUG makes sure that the user does not usually see all the debugging
     messages
   - MESSAGE writes a message using DTM, unless debugging is on.
   - BUG writes a message using DTM, then aborts.
   - Abort sends signal "ABORT" to other machine, then aborts.
   - AbortIt actually aborts.
*/
/******************************************************************************/

private logical debugging = FALSE;
void SETDEBUG(debug) logical debug; { debugging = debug; }

void MESSAGE(message) char *message; {
   void DTMprint();
   if( debugging ) Fprintf( stderr,message);
   else            DTMprint(stdout,message);
}

void BUG(message) char *message;
{  void DTMprint(), Abort();
   DTMprint(stderr,message);
   Abort();
}

void Abort(){ void DTMsendSignal(),AbortIt();DTMsendSignal("ABORT");AbortIt(); }

void AbortIt()
{  logical DTMmaster();
   if( DTMmaster() )
   Fprintf( stderr, "### Program exiting with return code = 1 ###\n" );
   exit(1);
}

/******************************************************************************/
/*
   dprintf  - print a message on stdout, with variable argument list
              (equiv. of printf, but adapted for DTM remote printing)
   wwarning - warning messages, with variable argument list
   assert   - error messages, with variable argument list

   The structure of the code below is a little complex because on the CM passing
   the va_list to a function causes a crash. Thus some code is repeated instead
   of being made into a function.
   Some shared code that does not use the va_list is put into three functions:
   Mess_Init   - to start the string with the type of message.
   Mess_Decode - to get one format
   Mess_Give   - to decide where to write to.
*/
/******************************************************************************/

#define MAXMESSLEN 256
private char    OutMessage[MAXMESSLEN], *out;
private char    format[10], *fmt;
private int     K;
private logical getform;
private logical readarg;
private char    severity;

private void Mess_Init(sev)
char sev;
{
   K       = 0;
   getform = FALSE;
   out     = &OutMessage[0];
   switch( sev ) {
   case ' ':           StrCpy( out, "" );                     break;
   case 'i': case 'I': StrCpy( out, "### Informational:  " ); break;
   case 'w': case 'W': StrCpy( out, "### Warning:  "       ); break;
   case 'e': case 'E': StrCpy( out, "### Error:  "         ); break;
   case 'f': case 'F': StrCpy( out, "### Fatal Error:  "   ); break;
   }
   out += strlen(out);
}
private logical Mess_Decode( Message, read_arg )
char     Message;
logical *read_arg;
{
   void DTMprint();
   *read_arg=FALSE;
   if( !getform ) {
      if(Message=='%'){ getform=TRUE; fmt = &format[0]; *fmt++ = '%'; }
      else            { *out++ = Message; K++; }
   } else {
      *fmt++ = Message;
      if( isalpha(Message) ) {
         getform=FALSE; *fmt='\0'; if(K>=MAXMESSLEN-10) K=MAXMESSLEN;
         *read_arg=TRUE;
      } else if( Message == '%' ) {
         getform=FALSE; StrCpy( out, "%%%%" ); out+=2; K+=2;
      }
   }
   if(K==MAXMESSLEN) DTMprint(stderr,"### Error: Message too long\n");
   return( K!=MAXMESSLEN );
}
private void Mess_Give(sev)
char sev;
{
   void BUG(), MESSAGE();
   if( sev != ' ' ) *out++ = '\n'; *out = '\0';
   if( sev == 'f' ) BUG(     OutMessage );
   else             MESSAGE( OutMessage );
}

void va_FUNC( dprintf, char, *Message )           /* dprintf( Message, args ) */
{
   va_list args;
   va_START( args, char*, Message );
   severity = ' ';

/* START IDENTICAL PART */
   Mess_Init(severity);
   while( *Message && Mess_Decode(*Message,&readarg) ) {
      if(readarg){
         switch( *Message ) {
         case 'u': Sprintf( out, format, va_arg(args,unsigned int) ); break;
         case 'd': Sprintf( out, format, va_arg(args,int         ) ); break;
         case 'f': Sprintf( out, format, va_arg(args,double      ) ); break;
         case 'g': Sprintf( out, format, va_arg(args,double      ) ); break;
         case 'c': Sprintf( out, format, va_arg(args,char        ) ); break;
         case 's': Sprintf( out, format, va_arg(args,char *      ) ); break;}
         while( *out && K<MAXMESSLEN ) { out++; K++; }
      } Message++;
   }
   Mess_Give(severity); va_end(args);
/* END IDENTICAL PART */
}

void va_FUNC( wwarning,logical,condition )/* wwarning(condition,Message,args) */
{
   char    *Message;
   va_list  args;
   va_START( args, logical, condition );
   if( !condition ) { va_end(args); return; }
   Message = va_arg( args, char* );
   severity = 'w';

/* START IDENTICAL PART */
   Mess_Init(severity);
   while( *Message && Mess_Decode(*Message,&readarg) ) {
      if(readarg){
         switch( *Message ) {
         case 'u': Sprintf( out, format, va_arg(args,unsigned int) ); break;
         case 'd': Sprintf( out, format, va_arg(args,int         ) ); break;
         case 'f': Sprintf( out, format, va_arg(args,double      ) ); break;
         case 'g': Sprintf( out, format, va_arg(args,double      ) ); break;
         case 'c': Sprintf( out, format, va_arg(args,char        ) ); break;
         case 's': Sprintf( out, format, va_arg(args,char *      ) ); break;}
         while( *out && K<MAXMESSLEN ) { out++; K++; }
      } Message++;
   }
   Mess_Give(severity); va_end(args);
/* END IDENTICAL PART */
}

void va_FUNC( assert, logical, condition )  /* assert(condition,Message,args) */
{
   char   *Message;
   va_list args;
   va_START( args, logical, condition );
   if( condition ) { va_end(args); return; }
   Message = va_arg( args, char* );
   severity = 'f';

/* START IDENTICAL PART */
   Mess_Init(severity);
   while( *Message && Mess_Decode(*Message,&readarg) ) {
      if(readarg){
         switch( *Message ) {
         case 'u': Sprintf( out, format, va_arg(args,unsigned int) ); break;
         case 'd': Sprintf( out, format, va_arg(args,int         ) ); break;
         case 'f': Sprintf( out, format, va_arg(args,double      ) ); break;
         case 'g': Sprintf( out, format, va_arg(args,double      ) ); break;
         case 'c': Sprintf( out, format, va_arg(args,char        ) ); break;
         case 's': Sprintf( out, format, va_arg(args,char *      ) ); break;}
         while( *out && K<MAXMESSLEN ) { out++; K++; }
      } Message++;
   }
   Mess_Give(severity); va_end(args);
/* END IDENTICAL PART */
}

/*

/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*    <<< Utility routines >>>                         130 +   52 =  182 USERIO
/******************************************************************************/
/*
   Find position of character in string.
*/
/******************************************************************************/

int index_c(c,s) char c,*s;
{ register int n=0; while( *s&&*s!=c ) { s++; n++; } if(!*s) n= -1; return(n); }

/******************************************************************************/
/*
   Convert string to number.
*/
/******************************************************************************/

double AtoF(s) char *s;
{ double coo; char *pend;
  coo = strtod(s,&pend); /* on sirius strtod seems to fail!!! */
  coo = atof(s);         /* so redo it, after getting pend, which works */
  assert( *pend == NULL, "Error decoding string %s", s );
  return( (double)coo );
}

/******************************************************************************/
/*
   Find next higher power of 2.
*/
/******************************************************************************/

int NextPow2( len ) int len;
{  register int l=2; while( l < len ) l *= 2; return l; }

/******************************************************************************/
/*
   Find axis numbers for unit tinp
*/
/******************************************************************************/

void fndaxnum( tinp, type, axisname, axisnr )
int  *tinp;
char *type;
char *axisname;
AXIS *axisnr;
{
   void rdhda_c(),rdhdi_c();
   int  n, naxis;
   char key[6], ctype[AITEMLEN];
   char axnames[MAXNAX+1];
   StrCpy( axnames, "xyzabcd" );

   rdhdi_c( *tinp, "naxis", &naxis, 0 );
   *axisnr = NOAX;
   for( n=1; n<=naxis; n++ ) {
     Sprintf( key, "ctype%d", n ); rdhda_c( *tinp, key, ctype, "\0",AITEMLEN );
     if(        StrEq(type,"lon") ) {
       if(StrEqN(ctype,"ra",2)   || StrEqN(ctype,"RA",2)  )*axisnr=IntToAxis(n);
     } else if( StrEq(type,"lat") ) {
       if(StrEqN(ctype,"dec",3)  || StrEqN(ctype,"DEC",3) )*axisnr=IntToAxis(n);
     } else if( StrEq(type,"freq") ) {
       if(StrEqN(ctype,"freq",4) || StrEqN(ctype,"FREQ",4))*axisnr=IntToAxis(n);
       if(StrEqN(ctype,"velo",4) || StrEqN(ctype,"VELO",4))*axisnr=IntToAxis(n);
       if(StrEqN(ctype,"felo",4) || StrEqN(ctype,"FELO",4))*axisnr=IntToAxis(n);
     }
   }
   assert( *axisnr!=NOAX, "no axis of type %s found", type );
   *axisname = axnames[*axisnr-AXIS1];
   return;
}

/******************************************************************************/
/*
   Convert radians or degrees to ra/dec strings and vice versa.

   An ra string is 'Shh:mm:ss.ss' with 0's added if h, m or s < 10 (S=sign)
   A dec string is 'Sdd:mm:ss.s'  with 0's added if d, m or s < 10 (S=sign)
   (ra signs can occur for gridspacings)

   radra/raddec:  input ra/dec in radians, output shh:mm:ss.ss
   degra/degdec:  input ra/dec in degrees, output sdd:mm:ss.s
   rarad/decrad:  input ra/dec string, output in radians
   radeg/decdeg:  input ra/dec string, output in degrees
*/
/******************************************************************************/

void radra( ra, s) double ra;  char *s; { void degra();  degra( rtod(ra), s ); }
void raddec(dec,s) double dec; char *s; { void degdec(); degdec(rtod(dec),s ); }
double rarad( s) char *s; { double radeg();  return( dtor( radeg( s) ) ); }
double decrad(s) char *s; { double decdeg(); return( dtor( decdeg(s) ) ); }

/* Returns -hh:mm:ss.ss in rastring; 12 chars long */
void degra(ra,rastring)
double ra;
char  *rastring;
{
   private void mkradecstring();
   double round = stod(0.005)/DEGpHOUR; /* roundoff in degrees/15 */
   int    sign;
   int    hour, minu; double secs, rest;

   sign = signum(ra);
   ra   = fabs(ra) + round; ra = ra>360. ? mod(ra,360.) : ra;
   ra  /= DEGpHOUR;
   hour = (int)ra;   rest = MINpHOUR*( ra   - (double)hour );
   minu = (int)rest; rest =    mtos(   rest - (double)minu );
   secs =      rest;
   mkradecstring( 'h', sign, hour, minu, secs, rastring );
}

/* return -dd:mm:ss.s in decstring; 11 chars long */
void degdec(dec,decstring)
double dec;
char  *decstring;
{
   private void mkradecstring();
   double round = stod(0.005); /* roundoff in degrees */
   int    sign;
   int    degr, minu; double secs, rest;

   sign = signum(dec);
   dec  = fabs(dec) + round; dec = dec>90. ? mod(dec,90.) : dec;
   degr = (int)dec ; rest = dtom( dec  - (double)degr );
   minu = (int)rest; rest = mtos( rest - (double)minu );
   secs =      rest;
   mkradecstring( 'd', sign, degr, minu, secs, decstring );
}

private void mkradecstring( mode, sign, hrdg, minu, secs, string )
char   mode;
int    sign, hrdg, minu;
double secs;
char  *string;
{
             if( fabs(secs-SECpMIN) < 1.E-3 ) { minu++; secs=0.; }
   switch( mode ) {
   case 'h': if(     minu   ==   MINpHOUR   ) { hrdg++; minu=0; }
             if(     hrdg   ==   HOURpDAY   ) {         hrdg=0; } break;
   case 'd': if(     minu   ==   MINpDEG    ) { hrdg++; minu=0; } break; }
             Sprintf( string, " %2d:%2d:", hrdg, minu );
   switch( mode ) {
   case 'h': Sprintf( string+7, "%5.2f", secs ); break;
   case 'd': Sprintf( string+7, "%4.1f", secs ); break; }
   if( sign == -1 ) *(string  ) = '-';
   if( hrdg < 10  ) *(string+1) = '0';
   if( minu < 10  ) *(string+4) = '0';
   if( secs < 10. ) *(string+7) = '0';
}

double radeg( string )
char *string;
{
   double decdeg();
   return( DEGpHOUR * decdeg(string) );
}

double decdeg( string )
char *string;
{
   double AtoF();
   enum { degr, mins, secs } stage;
   double sign=1., dec=0.;
   char   number[8]; int n=0; char *s;
   s=string; stage=degr;
   while( *s ) {
      switch( *s ) {
      case '-': sign = -1.; break;
      case ':': number[n]   = '\0'; n=0;
                switch( stage ) {
                case degr: dec  = AtoF(number);       stage=mins; break;
                case mins: dec += mtod(AtoF(number)); stage=secs; break;
                } break;
      default:  number[n++] = *s; break;
      }
      s++;
   }
   dec += stod(AtoF(number));
   return( sign * dec );
}

/*

/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*    <<< Parallel math functions >>>                   45 +   11 =   56 SETUP
/******************************************************************************/
/*
   Some functions that must be defined as 'extern' in mosaic_pb.c
*/
/******************************************************************************/

double_current sinc(r)
Real_current *r;
{
   return( (double)(*r == ZERO ? 1. : sin(*r) / *r) );
}

double_current airy(r)
Real_current *r;
{   double_current bj1();
    with_current *r = *r==ZERO ? ONE : 2. * bj1(r) / *r;
    return( (double_current)(*r * *r) );
}
double_current bj1(r)
Real_current *r;
{
   Real_current t, p, a;
   with_current {
      where( *r < 3. ) {
        t  = *r * *r / 9.0;
        p = ( 0.5 + t*( -0.56249985 + t*(  0.21093573 + t*( -0.03954289 +
                    t*(  0.00443319 + t*( -0.00031761 + t*(  0.00001109
                      ))))))
            ) * *r;
      } else {
        t  = 3. / *r;
        p =             0.79788456 + t*(  0.00000156 + t*(  0.01659667 +
                   t*(  0.00017105 + t*( -0.00249511 + t*(  0.00113653 +
                   t*(  0.00020033   ))))));
        a =  *r        -2.35619449 + t*(  0.12499612 + t*(  0.00005650 +
                   t*( -0.00637879 + t*(  0.00074348 + t*(  0.00079824 +
                   t*( -0.00029166   ))))));
        p *= cos(a) / sqrt(*r);
      }
      return( (double_current)p );
   }
}

double_current polynomial( order, coeff, x )
int           order;
double        coeff[];
Real_current *x;
{  Real_current y=ZERO; int i;
   with_current {
      for( i=order; i>=1; i-- ) {
         y  = ( y + coeff[i] ) * *x; }
         y += coeff[0];
   }
   return( (Real_current)y );
}

/*

/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*    <<< 2-d gaussian fitting >>>                     273 +  196 =  469 USERIO
/******************************************************************************/
/*
   Fit a 2-dimensional gaussian to a patch of data.

   Start with a linear fit to get initial estimate. This finds values of b which
   minimizes: SUM ( log(Data(x,y)) - b[0]*x*x - b[1]*y*y - b[2]*x*y )**2,
   where the sum is taken over the "main lobe" of the beam only (the "main lobe"
   is the central part of the beam which is greater than a threshold). Because
   this is a linear least squares problem, it should always produce a solution,
   i.e. no worries about convergence of an iterative fitting process. To make
   sure that only the main lobe is fitted, the pixel range that spans across the
   main lobe at each y is found. If the matrix proves singular, return the
   estimate as two grid units.

   Then a full non-linear fit is done.
   The function that is fit is:
   exp( b0 (x-xref)^2 + b1 (y-xref)^2 + b2 (x-xref)(y-yref)^2 ).

   The return value indicates the error condition, to be checked by the caller.
*/
/******************************************************************************/

/* some global variables, used by nllsqu function/derivative */
#define FITWIDTH 11
#define FITSIZE  FITWIDTH * FITWIDTH

private double sxxc[FITSIZE], syyc[FITSIZE], sxyc[FITSIZE];
private double DataPatch[FITSIZE];

int Fit_2D_Gaussian( Data,nx,ny, x_ref,y_ref, b )
float  Data[];
int    nx, ny;
double x_ref, y_ref;
double b[3];
{
#define THRESHOLD 0.1
   private  int    llsqu(), nllsqu(), ok;
   private  void   GaussFunction(), GaussDerivative();
   register int    x,     y,        k;
   register int    xref=nint(x_ref), yref=nint(y_ref);
   register int    xlo=0, xhi=nx-1;
   register int    x_lo,  x_hi;
   register double X, Y, Z, F;

   double A[3][3];
   double ScrM[3][3]; int ScrA[3];
   double f[FITSIZE], fp[FITSIZE], dfdb[3][FITSIZE], db[3];

   for(x=0;x<3;x++){b[x]=ZERO;for(y=0;y<3;y++){A[x][y]=ZERO;}}

   /* find pixel range across main lobe at x=xref */
   xhi=xref, k=yref*nx+xref;
   do { if( Data[k]<THRESHOLD ) break; xhi++; k++; } while( xhi < nx );
   xlo = xref - ( xhi - xref );

   for( y=yref; y<ny; y++ ) {
      if( xlo>xhi ) break;
      x_lo=nx+1; x_hi=0;
      for( x=max(xlo-1,0); x<=min(xhi+1,nx); x++ ) { k=y*nx+x;
         if( Data[k] > THRESHOLD ) {
            assmin( x_lo, x ); assmax( x_hi, x );
            X = square(x-xref); Y = square(y-yref); Z = (x-xref)*(y-yref);
            F = log(Data[k]);
            A[0][0] += X*X;  A[0][1] += X*Y;  A[0][2] += X*Z;
            A[1][0] += Y*X;  A[1][1] += Y*Y;  A[1][2] += Y*Z;
            A[2][0] += Z*X;  A[2][1] += Z*Y;  A[2][2] += Z*Z;
            b[0]    += F*X;  b[1]    += F*Y;  b[2]    += F*Z;
         }
      }
      xlo=x_lo; xhi=x_hi;
   }

   if( llsqu( b,A,3,3,b, ScrM,ScrA, 0 ) != 0 ) { b[0]=b[1]= -M_LN2; b[2]=ZERO; }
   for( k=0, y=0; y<ny; y++ ) { for( x=0; x<nx; x++, k++ ) {
      DataPatch[k] = (double)Data[k];
      sxxc[k]      = (x-xref)*(x-xref);
      syyc[k]      = (y-yref)*(y-yref);
      sxyc[k]      = (x-xref)*(y-yref);
   }}
   ok = nllsqu( 3, nx*ny, b, db, 20, ZERO, 0.005/3.,
                GaussFunction, GaussDerivative, TRUE, f,fp,db,dfdb,ScrM );
   return( ok );
}

/******************************************************************************/
/*
   The gaussian and its derivative.
*/
/******************************************************************************/

private void GaussFunction(b,f,n,m)
double b[],f[];
int    n, m;
{
   int i;
   i=n; /* Stop lint complaint */
   for( i=0; i<m; i++ ) {
      f[i] = DataPatch[i] - EXP( sxxc[i]*b[0] + syyc[i]*b[1] + sxyc[i]*b[2] );
   }
}
private void GaussDerivative(b,dfdb,n,m)
double b[], dfdb[];
int    n, m;
{
   int    i;
   double F;
   i=n; /* Stop lint complaint */
   for( i=0; i<m; i++ ) {
      F = EXP( sxxc[i]*b[0] + syyc[i]*b[1] + sxyc[i]*b[2] );
      dfdb[0*m+i] = - sxxc[i] * F;
      dfdb[1*m+i] = - syyc[i] * F;
      dfdb[2*m+i] = - sxyc[i] * F;
   }
}

/******************************************************************************/
/*
   Convert the xx, xy and yy coefficients to major/minor axis and pa.
*/
/******************************************************************************/

void Convert_GauPar( b, cdelt1, cdelt2, direction )
double  b[3];
double  cdelt1, cdelt2;
logical direction;
{
   double c[3];
   double t1, t2;
   double sinpa, cospa;
   if( direction==TRUE ) {
      c[0] = -b[0] / FOURLN2 / ( cdelt1 * cdelt1 );
      c[1] = -b[1] / FOURLN2 / ( cdelt2 * cdelt2 );
      c[2] =  b[2] / FOURLN2 / ( cdelt1 * cdelt2 );
      t1   = c[0] + c[1];
      t2   = -dist( c[0]-c[1], c[2] );
      b[0] = sqrt(  2. / (t1+t2) );
      b[1] = sqrt(  2. / (t1-t2) );
      b[2] = c[2] != ZERO ? atan2( c[2], c[0]-c[1] )/2. : ZERO;
   } else {
      sinpa = sin( b[2] );
      cospa = cos( b[2] );
      c[0] = -FOURLN2 * square(sinpa/b[0]) + square(cospa/b[1]);
      c[1] = -FOURLN2 * square(cospa/b[0]) + square(sinpa/b[1]);
      c[2] = 2.*FOURLN2 * sinpa*cospa * ( square(ONE/b[0])-square(ONE/b[1]) );
      b[0] = c[0] * ( cdelt1 * cdelt1 );
      b[1] = c[1] * ( cdelt2 * cdelt2 );
      b[2] = c[2] * ( cdelt1 * cdelt2 );
   }
}

/******************************************************************************/
/*
   llsqu and nllsqu below have been copied (almost) verbatim from the fortran
   miriad library routines. Included and rewritten in C to keep the mosaic
   program as self-contained as possible. The linpack routines sgefa and sgesl
   have been converted to C also.


   llsqu solves a linear least squares problem in "n" unknowns, and "m"
   equations. As usual, m must be greater or equal to n.
   The problem is solved by finding:
              t               t
        y' = A y    and B  = A A
   then solving this system of linear equations.

   Inputs:  n = Number of unknowns; m = number of equations
            f = function values for the m equations
            A = the matrix giving the weights for each equation
            failcode gives job to do: 0: solve A*X=B; != 0: solve TRANS(A)*X=B
   Scratch: B and pivot
   Output:  c = the solution coefficients.
            failcode gives success status: 0=OK, 1=singular matrix encountered
*/
/******************************************************************************/

private int llsqu( f, A, n,m, c, B,pivot, job )
double f[], A[]; /* f[m], A[n][m]; A declared 1-d => OK for C and Fortran */
int    n, m;
double c[];      /* c[n]          */
double B[];      /* B[n][n]       */
int    pivot[];  /* pivot[n]      */
int    job;
{
   private void sgefa_lp(), sgesl_lp();
   int  i, j, k;
   int  ifail;

   if( m < n ) {
      return -1;

/* If m and n are equal, then it is a simple solution of linear equations */
   } else if( m == n ) {
      for( i=0; i<n;   i++ ) c[i] = f[i];
      for( i=0; i<n*m; i++ ) B[i] = A[i];

/* If m and n are not equal, then we have to generate the B matrix. */
   } else {
      for( i=0; i<n; i++ ) {
         for( c[i]=ZERO, k=0; k<m; k++ ) c[i] += A[i*m+k] * f[k];
         for( j=0; j<n; j++ ) {
            for( B[i*n+j]=ZERO,k=0;k<m;k++ ) B[i*n+j] += A[i*m+k] * A[j*m+k];
                                             B[j*n+i]  = B[i*n+j];
         }
      }
   }
                sgefa_lp(B,n,n,pivot,&ifail);
   if(ifail==0) sgesl_lp(B,n,n,pivot,c,job);
   return ifail;
}

/******************************************************************************/
/*
   nllsqu() minimizes the sum of squares, and solves a set of nonlinear
   equations. This is derived from H. Spath, "The damped Taylors series method
   for minimizing a sum of squares and solving systems of nonlinear equations."
   Comm. ACM v10, n11, p726-728.
   There have been some modifications to the algorithm as presented in CACM. In
   particular the call sequence is different, and the algorithm has been mildly
   improved in a few places.

   Inputs:
      n         Number of unknowns.
      m         Number of nonlinear equations.
      itmax     Max no of iterations.
      eps1      Iteration stops if (sum f**2) < eps1
      eps2      Iteration stops if eps2 * sum (abs(x)) < sum( abs(dx) )
      der       Logical. If true, then the derivative routine is called. If
                false, the derivative is estimated by many calls to FUNCTION.
      h         This is used ONLY if der=.false. It gives the step sizes
                to use in estimating partial derivatives.
   Input/Output:
      x         Input: Initial estimate of solution.
                Output: The best solution so far.
   Scratch:
      f, fp, dx, dfdx, ScrM
   Outputs:
      function value: 0 All OK.
                      1 Singular matrix encountered.
                      2 Max number of iterations exceeded.
                      3 Failure to find better solution.
   Externals:
      The external FUNCTION must be implemented. But DERIVATIVE is not used if
      "der" is set false.
        void FUNCTION(x,f,n,m) double x[n],f[m];
          x (input)     : prospective solution
          f (output)    : value of the m nonlinear equations, given x
        void DERIVATIVE(x,dfdx,n,m) double x[n],dfdx[n,m];
          x (input)     : prospective solution
          dfdx (output) : Derivatives of the nonlinear equation at this x
*/
/******************************************************************************/

private int nllsqu( n,m, x, h, itmax, eps1,eps2,
            FUNCTION, DERIVATIVE, der,  f,fp,dx,dfdx,ScrM )
int     n,m, itmax;
double  x[],h[], eps1,eps2;        /* x[n],h[n] */
void    (*FUNCTION)(), (*DERIVATIVE)();
logical der;
double  f[], fp[], dx[], dfdx[],    ScrM[];
     /* f[m],fp[m],dx[n],dfdx[n][m],ScrM[n][n] */
{
   private int llsqu();
   int         i, k, niter=0, l;
   double      hf, hl, hs=ZERO, hz, hh;
   logical     first=TRUE;

/* ITERATION: */
   do {
      if( niter++ > itmax ) return 2;
/* DAMP: */
      l=0; hl=ONE;
      do {
         if( l++ > 16 ) return 3;
         (*FUNCTION)(x,f,n,m);
         for( hf=0,i=0; i<m; i++ ) hf += square(f[i]);
         if( first || hf<=hs ) break;
         hl *= 0.5; for( k=0; k<n; k++ ) x[k] += hl * dx[k];
      } while( hf>hs );

      first = FALSE; if( (hs=hf)<eps1 ) return 0;

/* Determine the Jacobian matrix */
      if(der) {
         (*DERIVATIVE)(x,dfdx,n,m);
      } else {
         for( i=0; i<n; i++ ) {
            hh = x[i];     x[i] = hh + h[i];
            (*FUNCTION)(x,fp,n,m);
            hz = ONE/h[i]; x[i] = hh;
            for( k=0; k<m; k++ ) dfdx[i*m+k] = hz*(fp[k]-f[k]);
         }
      }

/* Perform the linear least squares solution */
      i=llsqu( f, dfdx, n,m, dx, ScrM,(int *)&fp[0], 1 ); if(i!=0) return i;

/* Add the estimated step change to x and check for convergence */
      for( hz=hf=0,i=0; i<n; i++ ) {
         x[i] -= dx[i]; hz += fabs(x[i]); hf += fabs(dx[i]);
      }
   } while( hf >= eps2 * hz );
   return 0;
}

/******************************************************************************/
/*
   sgefa_lp factors a real matrix by gaussian elimination.

   Inputs:
     A     The matrix to be factored
     nrow  The order of the matrix A
     ncol  The leading dimension of the array A
   Outputs:
     A     An upper triangular matrix and the multipliers which were used to
           obtain it. The factorization can be written A = L*U where L is a
           product of permutation and unit lower triangular matrices and U is
           upper triangular
     pivot An integer vector of pivot indices
     info  = 0  normal value.
           = k  if U(k,k)==0. this is not an error condition for this
           subroutine, but it does indicate that sgesl_lp will divide by zero if
           called.

   Converted from LINPACK fortran, version dated 08/14/78
   Cleve Moler, University of New Mexico, Argonne National Lab.
*/
/******************************************************************************/

private void sgefa_lp( A,nrow,ncol, pivot, info )
double A[];
int    nrow, ncol, pivot[], *info;
{
   private int  isamax();
   private void sscal_lp(), saxpy_lp();
   double       t;
   int          j, k, l;

   *info = 0;
   if( nrow > 1 ) { for( k=0; k<nrow-1; k++ ) {

/* find l = pivot index */;
      pivot[k] = l = isamax( nrow-k, &A[ncol*k+k] ) + k;

/* zero pivot implies this column already triangularized */;
      if( A[ncol*k+l] != ZERO ) {

/* interchange if necessary */;
         if( l!=k ) { t=A[ncol*k+l]; A[ncol*k+l]=A[ncol*k+k]; A[ncol*k+k]=t; }

/* compute multipliers */;
         t= -ONE/A[ncol*k+k]; sscal_lp( nrow-k-1, t, &A[ncol*k+k+1] );

/* row elimination with column indexing */;
         for( j=k+1; j<nrow; j++ ) {
            t = A[ncol*j+l];
            if( l != k ) { A[ncol*j+l] = A[ncol*j+k]; A[ncol*j+k] = t; }
            saxpy_lp( nrow-k-1, t, &A[ncol*k+k+1], &A[ncol*j+k+1] );
         }
      } else {
         *info = k+1;
      }
   }}
   pivot[nrow-1] = nrow-1;
   if( A[ncol*nrow+nrow] == ZERO ) *info = nrow;
}

/******************************************************************************/
/*
   sgesl_lp -- Solve a real system of linear equations.

   solves the real system A*X=B or TRANS(A)*X=B, using the factors computed by
   sgefa_lp

   Inputs:
      A     The output from sgefa_lp
      nrow  The order of the matrix A
      ncol  The leading dimension of the array A
      pivot The pivot vector from sgefa_lp
      B     The right hand side vector
      job   = 0       to solve  A*X = B ,
            = nonzero to solve  TRANS(A)*X = B where TRANS(A) is the transpose
   Outputs:
      B     The solution vector X

   Error condition:
      A division by zero will occur if the input factor contains a zero on the
      diagonal. Technically this indicates singularity but it is often caused
      by improper arguments or improper setting of lda. It will not occur if
      the subroutines are called correctly and if sgefa_lp has set info=0.

   Converted from LINPACK fortran, version dated 08/14/78 by
   Cleve Moler, University of New Mexico, Argonne National Lab.
*/
/******************************************************************************/

private void sgesl_lp( A,nrow,ncol, pivot, B, job )
double A[], B[];
int    nrow, ncol, pivot[], job;
{
   private void   saxpy_lp();
   private double sdot_lp(), t;
           int    k, kb, l;

/* job = 0, solve A*X = B; first solve L*Y = B */
   if( job == 0 ) {

      if( nrow > 1 ) {
         for( k=0; k<nrow-1; k++ ) {
            l = pivot[k]; t = B[l]; if( l != k ) { B[l] = B[k]; B[k] = t; }
            saxpy_lp( nrow-k-1, t, &A[ncol*k+k+1], &B[k+1] );
         }
      }
/* now solve U*X = Y */
      for( kb=0; kb<nrow; kb++ ) {
         k = nrow-1 - kb; B[k] /= A[ncol*k+k]; t = -B[k];
         saxpy_lp( k, t, &A[ncol*k+0], &B[0] );
      }

/* job = nonzero, solve TRANS(A)*X = B; first solve TRANS(U)*Y = B */
   } else {

      for( k=0; k<nrow; k++ ) {
         t = sdot_lp( k, &A[ncol*k+0], &B[0] );
         B[k] = ( B[k] - t ) / A[ncol*k+k];
      }
/* now solve TRANS(L)*X = Y */
      if( nrow > 1 ) {
         for( kb=0; kb<nrow-1; kb++ ) {
            k = nrow-2 - kb;
            B[k] += sdot_lp( nrow-k-1, &A[ncol*k+k+1], &B[k+1] );
            l = pivot[k]; if( l != k ) { t = B[l]; B[l] = B[k]; B[k] = t; }
         }
      }

   }
}

/******************************************************************************/
/* isamax -- Find index of absolute maximum value in a vector */
/******************************************************************************/
private int isamax(n,x) int n; double x[];
{ double xmax; int i,j; if(n<1) return 0; if(n==1) return 1;
j=0; xmax=fabs(x[0]);
for( i=1; i<n; i++ ) { if( fabs(x[i]) > xmax ) { j=i; xmax = fabs(x[i]); } }
return j;
}
/******************************************************************************/
/* sscal_lp -- Scale a vector */
/******************************************************************************/
private void sscal_lp(n,scale,x) int n; double scale,x[];
{ int i; if(n<0)return; for( i=0; i<n; i++ ) x[i] *= scale; }
/******************************************************************************/
/* saxpy_lp -- Constant times a vector, plus a vector */
/******************************************************************************/
private void saxpy_lp(n,scale,x,y) int n; double scale,x[],y[];
{ int i; if(n<0)return; for( i=0; i<n; i++ ) y[i] += scale * x[i]; }
/******************************************************************************/
/* sdot_lp -- Dot product */
/******************************************************************************/
private double sdot_lp(n,x,y) int n; double x[], y[];
{ double t=ZERO; int i; if(n>0){ for(i=0;i<n;i++) t += x[i] * y[i]; } return t;}

/*

/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*    <<< Decode region keyword >>>                    337 +  123 =  460 USERIO
/******************************************************************************/
/*
   Decode the region keyword.
   This produces a list of planes and a list of vertices, and possibly a mask,
   which are later used by routine Inside to determine whether a pixel is in the
   selected region.

   The results are stored in the struct pointed to by 'Region'. The elements are
   - nPlanes     the number of planes selected.
   - Planes      a pointer to a list of planes.
   - nVertList   the number of corners and vertices.
   - VertList[i] pointer to a list of corners or vertices (max 10 lists); the
                 first element gives the number of elements in the list; the
                 second element gives the number of vertices in the list; the
                 rest is the list of which the third through sixth element give
                 the corners xmin,ymin,xmax,ymax of a rectangular region that
                 surrounds the box or polygon. If the first element is negative,
                 this indicates that the list represents a polygon, in which
                 case the vertices follow.
   - Mask        pointer to a dataset that describes the mask.
   - mask        pointer to a dynamically allocated array that contains the mask

   Planes, VertList[i] and Mask are dynamically allocated.

   Below, first define a set of constants, to make the code more readable. Then
   define the possible subcommands of the region keyword.

   The program decodes the keyword step by step. First it finds a single block
   (between ',') with keya, then extracts the subcommand word (with minimum
   match), and for some subcommands, decodes the arguments between '(' and ')'.
   The decoding is done is function Boxes, which expects an input string between
   parentheses, and a flag that tells it how to interpret it. A mask is
   interpreted in function MaskFile.
*/
/******************************************************************************/

#define REG_WORDS enum Reg_Words
REG_WORDS {
      ABSPIXEL,    RELPIXEL,   RELCENTER,   ARCSEC,    KMS,
      IMAGES,      QUART,      BOXES,       POLYGON,   MASK,
                   ALLPLANES,  WHOLEMAP,    INNERQRT              };
private char *userwords[] = {
     "abspixel ", "relpixel", "relcenter", "arcsec",  "kms",
     "images",    "quart",    "boxes",     "polygon", "mask", ""  };

void RegionDecode( key, Coords, Region )
char   *key;
COORDS *Coords;
REGION *Region;
{
   logical      keyprsnt_c();
   void         keya_c();
   int          index_c();
   private void SynErr();
   private void Boxes();
           void MaskFile();

   char         userspec[256], *reg;
   int          uind=0;
   register int i, k, l, m, n;
   REG_WORDS    word=-1;
   REG_WORDS    xyunits = ABSPIXEL;
   REG_WORDS    zunits  = ABSPIXEL;
   TRACE("RegionDecode");

   Region->nPlanes = Region->nVertLists = 0; Region->MaskPresent = FALSE;

   do {

   keya_c( key, userspec, "\0" ); reg = &userspec[0];
   while( *reg ) Region->UserString[uind++] = *reg++;
                 Region->UserString[uind++] = ',';
   reg = &userspec[0]; if( *reg == '\0' ) break;

   /* n=offset of last char; k=offset of '('; l=length to compare */
   n=strlen(reg)-1; k=index_c('(',reg); SynErr(k==0,1,key); l=(k==-1?n+1:k);
   for(m=0,i=0;*userwords[i];i++){ if(StrEqN(reg,userwords[i],l)){ word=i;m++;}}
   assert( m==1, "syntax error in command %s=%s", key, reg );

   switch( word ) {
   case ABSPIXEL:  xyunits=ABSPIXEL;  break;
   case RELPIXEL:  xyunits=RELPIXEL;  break;
   case RELCENTER: xyunits=RELCENTER; break;
   case ARCSEC:    xyunits=ARCSEC;    break;
   case KMS:       zunits =KMS;       break;
   /* find ')', decode planes between '(' and ')' */
   case IMAGES:
   case QUART:     SynErr(k==-1,2,key); reg+=k;
                   k=index_c(')',reg); SynErr(k<=1,3,key);
                                    Boxes(word,    reg,zunits,  Coords,Region);
                   if(word==IMAGES) Boxes(WHOLEMAP,reg,ABSPIXEL,Coords,Region);
                   if(word==QUART ) Boxes(INNERQRT,reg,ABSPIXEL,Coords,Region);
                   break;
   /* find ')', decode vertices between '(' and ')'
      then find another '(' ')' combination and decode planes */
   case BOXES:
   case POLYGON:   SynErr(k==-1,4,key); reg+=k;
                   k=index_c(')',reg); SynErr(k<=1,5,key);
                   if(*(reg+k+1)=='(') {
                      *(reg+k+1)='\0';
                      Boxes( word, reg, xyunits, Coords, Region );
                      reg+=k+1; *reg='(';
                      k=index_c(')',reg); SynErr(k<=0,6,key);
                      Boxes( IMAGES, reg, zunits, Coords, Region );
                   } else {
                      SynErr(*(reg+k+1)!='\0',7,key);
                      Boxes(  word,    reg, xyunits,  Coords, Region );
                      Boxes(ALLPLANES, reg, ABSPIXEL, Coords, Region);
                   }
                   break;
   /* find ')', filename between '(' and ')' */
   case MASK:      SynErr(k==-1,8,key); reg+=k;
                   k=index_c(')',reg); SynErr(k<=1,9,key);
                   MaskFile( reg, Coords, Region );
                   Region->MaskPresent = TRUE;
                   break;
   default:        assert(TRUE,"illegal command in keyword %s",key);
   }
   } while( keyprsnt_c(key) );
   if( Region->nPlanes == 0 ) Boxes(ALLPLANES,reg,ABSPIXEL,Coords,Region);
   Region->UserString[--uind] = '\0';
}

private void SynErr(cond,n,key)
logical cond;
int     n;
char   *key;
{
   switch( n ) {
   case 1:  assert( !cond, "Missing '(' in keyword %s",             key );break;
   case 2:  assert( !cond, "Missing '(' in image subcommand of %s", key );break;
   case 3:  assert( !cond, "Missing ')' in image subcommand of %s", key );break;
   case 4:  assert( !cond, "Missing '(' in box or poly subcommand of %s", key );
            break;
   case 5:  assert( !cond, "Missing ')' in box or poly subcommand of %s", key );
            break;
   case 6:  assert( !cond, "Error in plane specification of %s",    key );break;
   case 7:  assert( !cond, "Syntax error after boxes, keyword %s",  key );break;
   case 8:  assert( !cond, "Missing '(' in mask subcommand of %s",  key );break;
   case 9:  assert( !cond, "Missing ')' in mask subcommand of %s",  key );break;
   }
}

/******************************************************************************/
/*
   Boxes convert the string 'reg' to a list of numbers in the Region struct, as
   described above in the comments on RegionDecode. For WORD=IMAGES, QUART,
   BOXES and POLYGON, the input string 'reg' must be surrounded by parentheses
   and is actually decoded by 'GetList'; for the other modes, 'reg' is ignored
   and some special box is defined.

   For WORD ALLPLANES a list from 1 to n is generated, with n the length of the
       FREQ-axis.
   For WORD IMAGES or QUART there can be at most two numbers, giving the start
       and end of a list of planes.
   For WORD WHOLEMAP or INNERQRT a single box describing the whole map or the
       inner quarter is generated.
   For WORD BOXES there must be a multiple of four numbers, giving corners.
   For WORD POLYGON there must be a multiple of two numbers, giving vertices.
       Polygon vertices are indicated by negative numbers.

   Depending on the units, a coordinate transformation may be done too (inside
   GetList). The resulting list gives coordinates in absolute pixels, i.e. the
   lower edge is pixel # 1.

   The List array is first set up, FillRegion transfers it to the Region struct.
*/
/******************************************************************************/

private void Boxes( WORD, reg, units, Coords, Region )
REG_WORDS  WORD;
char      *reg;
REG_WORDS  units;
COORDS    *Coords;
REGION    *Region;
{
   private void GetList();
   private void FillRegion();
   private void CheckRange();

            int List[MAXCHAN+1];
   register int i, j, n;
   TRACE("-- Boxes");

   switch( WORD ) {
   case ALLPLANES:
      List[0] = Coords->ZLEN;
      assert( List[0] <= MAXCHAN, "Too many planes" );
      for( i=1; i<=List[0]; i++ ) List[i] = i;
      FillRegion( IMAGES, List, Region ); break;
   case IMAGES:
   case QUART:
      GetList( reg, units, Coords, List ); List[2]=List[(List[0]==1?1:2)];
      assert( List[0] <= 2, "Too many numbers in image or quart command" );
      assert( List[2]-List[1]+1 <= MAXCHAN, "Too many planes" );
      CheckRange( List[0], &List[1], Coords, FQ_AXIS );
      List[0] = List[2] - List[1] + 1;
      n = List[2]; for( i=0; i<n; i++ ) List[i+1] = List[1]+i;
      FillRegion( IMAGES, List, Region ); break;
   case WHOLEMAP:
      List[0] = 4;
      List[1] = 2;
      List[2] = 1; List[4] = Coords->XLEN;
      List[3] = 1; List[5] = Coords->YLEN;
      FillRegion( BOXES, List, Region ); break;
   case INNERQRT:
      List[0] = 4;
      List[1] = 2;
      List[2] = Coords->XLEN/4 + 1;   List[4] = List[2] + Coords->XLEN/2;
      List[3] = Coords->YLEN/4 + 1;   List[5] = List[3] + Coords->YLEN/2;
      FillRegion( BOXES, List, Region ); break;
   case BOXES:
      GetList( reg, units, Coords, List );
      assert( List[0]%4==0, "Bad number of corners" );
      CheckRange( List[0], &List[1], Coords, RA_AXIS );
      CheckRange( List[0], &List[1], Coords, DC_AXIS );
      n = List[0]/4; List[1000] = 4; List[1001] = 2;
      /* Add a new VertList for every box */
      for( i=0; i<n; i++ ) {
         for( j=0; j<4; j++ ) List[j+1002] = List[1+4*i+j];
         assert( List[1002]<=List[1004], "xmin greater than xmax" );
         assert( List[1003]<=List[1005], "ymin greater than ymax" );
         FillRegion( BOXES, &List[1000], Region );
      }
      break;
   case POLYGON:
      GetList( reg, units, Coords, List );
      assert( List[0]%2==0, "Bad number of vertices" );
      CheckRange( List[0], &List[1], Coords, RA_AXIS );
      CheckRange( List[0], &List[1], Coords, DC_AXIS );
      /* Add a final vertex equal to first to wrap it up */
      n=List[0]; List[n+1]=List[1]; List[n+2]=List[2]; n+=2;
      /* shift the list by 5 elements */
      for( i=n; i>0; i-- ) List[i+5] = List[i];
      /* Add the min and max x and y to the list, in element 2 to 5 */
      List[2]=List[4]=List[6]; List[3]=List[5]=List[7];
      for( i=6; i<n+6; i+=2 ) {
         assmin(List[2],List[i]  ); assmax(List[4],List[i]  );
         assmin(List[3],List[i+1]); assmax(List[5],List[i+1]);
      }
      /* Store number of vertices in List[1]. */
      List[1] = n/2;
      /* Store number of elements in List[0] (negative to indicate polygon) */
      List[0] = -(n+4);
      FillRegion( BOXES, List, Region ); break;
   }
}

private void CheckRange( nList, List, Coords, axis )
int     nList;
int     List[];
COORDS *Coords;
AXIS    axis;
{
   register int n;
   for( n=0; n<abs(nList); n++ ) {
      assert( List[n] >= 1,                   "Coordinate below lower limit" );
      assert( List[n] <= Coords->axlen[axis], "Coordinate above upper limit" );
   }
}

/******************************************************************************/
/*
   Decode the string 'reg' into a list of numbers. Depending on the value of
   units a coordinate transformation may be done.
*/
/******************************************************************************/

private void GetList( reg, units, Coords, List )
char      *reg;
REG_WORDS  units;
COORDS    *Coords;
int        List[];
{
   double        AtoF();
   double        ConvertToPixel();
   char          c[INSTRLEN];
   register int  i, n=1;
   register AXIS xy=RA_AXIS;
   double        coo;

   reg++; List[0]=0;
   while( *reg ) {
      i=0; while( *reg!=',' && *reg!=')' ) {
         assert( isdigit(*reg) || *reg!='.' || *reg!='-',
                 "Expected number as input: %s", reg );
         c[i++] = *reg++;
      } c[i]='\0'; reg++;
      coo = AtoF(c);

      switch( units ) {
      case ABSPIXEL:  List[n] = coo;                                      break;
      case RELPIXEL:  List[n] = coo + Coords->crpix[xy];                  break;
      case RELCENTER: List[n] = coo + Coords->axlen[xy] / 2 + 1;          break;
      case ARCSEC:    List[n] = nint( stor(coo)/fabs(Coords->cdelt[xy]) ) +
                                      Coords->crpix[xy];                  break;
      case KMS:       List[n] = nint(ConvertToPixel(coo,Coords,FQ_AXIS)); break;
      }
      assert( n <= MAXCHAN-6, "Too many vertices" );
      n++;
      xy = xy == RA_AXIS ? DC_AXIS : RA_AXIS;
   }
   List[0] = n-1;
}

/******************************************************************************/
/*
   Copy the List of planes, corners or vertices to the Region struct.
   - For a list of planes, the Region->Planes pointer is allocated to point to
     and array of plane. The planes in the old list that do not occur in the new
     list are appended.
   - For boxes and polygons a new vertlist is created in the memory pointed to
     by Region->VertList[ Region->nVertLists ].
*/
/******************************************************************************/

private void FillRegion( WORD, List, Region )
REG_WORDS WORD;
int       List[];
REGION   *Region;
{
   register int     i, j, k;
   register int    *pnt;
   register logical occurs;

   switch( WORD ) {
   case IMAGES:
      k=List[0];
      for( i=0; i<Region->nPlanes; i++ ) {
         for( j=1, occurs=FALSE; j<=List[0]; j++ ) {
            if( *(Region->Planes+i)==List[j] ) { occurs=TRUE; break; }}
         if( !occurs ) { k++; List[k] = *(Region->Planes+i); }
         assert( k < MAXCHAN-1, "Too many planes" );
      }
      Region->nPlanes = k;
      Malloc( Region->Planes, int, Region->nPlanes );
      pnt = Region->Planes;
      for( i=1; i<=Region->nPlanes; i++ ) *pnt++ = List[i];
      break;
   case BOXES:
      assert( Region->nVertLists <= MAXPOLYS, "Too many regions" );
      Malloc( Region->VertList[Region->nVertLists], int, abs(List[0])+2 );
      pnt = Region->VertList[Region->nVertLists];
      for( i=0; i<abs(List[0])+2; i++ ) *pnt++ = List[i];
      Region->nVertLists++;
      break;
   }
}

/******************************************************************************/
/*
   DTM NOTE: INSIDE REGION CHECKING ROUTINE MAY RUN REMOTELY
*/
/******************************************************************************/
/*
   - Return TRUE or FALSE, depending on whether a pixel is within the region
     described by the Region pointer.
   - First initialize the array IsInside to TRUE if there is no list of boxes.
   - If there is a list of boxes and/or polygons, then check if the pixel is in
     the (surrounding) box. For polygons, next check if it is in the polygon.
     Loop over all boxes and polygons. If a pixel is inside any one box,
     IsInside is set to TRUE.
     El. 0 of the vertex list is the # of elements; el. 1 is the number of
     vertices; el 2-5 is the (surrounding) box; el 6-n are the polygon vertices.
   - Last check the presence of a mask. If there is one, add in the mask given
     in MskArr.
*/
/******************************************************************************/

logical_current Inside( Region, x, y, MskArr )
REGION       *Region;
int_current   x, y;
Real_current *MskArr;
{
   logical_current       IsInside;
   register int         *Vertex, Listnr, nVert, Vertnr;
   register int          xmin, xmax, ymin, ymax;
   register Real_current ax, ay, bx, by;
   register Real_current d;
            Real_current angsum;

   if( Region->nVertLists == 0 ) {
      with_current IsInside = TRUE;
   } else {
      with_current IsInside = FALSE;

      for( Listnr=0; Listnr<Region->nVertLists; Listnr++ ) {
         Vertex = Region->VertList[Listnr];
         xmin = *(Vertex+2); xmax = *(Vertex+4);
         ymin = *(Vertex+3); ymax = *(Vertex+5);

/* box */
         if( *Vertex > 0 ) {
            with_current  IsInside |= ( (xmin<=x) && (x<=xmax) &&
                                        (ymin<=y) && (y<=ymax) );

/* polygon */
         } else {
            nVert = *(Vertex+1); Vertex += 6;
            with_current { where( xmin<=x && x<=xmax && ymin<=y && y<=ymax ) {
               angsum = ZERO;
               for( Vertnr=1; Vertnr<nVert; Vertnr++, Vertex+=2 ) {
                  ax = (Real_current)(*(Vertex  ) - x);
                  ay = (Real_current)(*(Vertex+1) - y);
                  bx = (Real_current)(*(Vertex+2) - x);
                  by = (Real_current)(*(Vertex+3) - y);
                  where( dist(ax,ay)<ONE || dist(bx,by)<ONE ) IsInside |= TRUE;
                  else {
                     angsum +=
                        ( signum( ax*by - ay*bx ) ) *
                        ( ( d = ( ax*bx + ay*by ) / dist(ax,ay) / dist(bx,by) )
                            >=ONE ? ZERO : ( d<=-ONE ? M_PI : acos(d) ) );
                  }
               }
               IsInside |= ( (fabs((Real_current)angsum) > M_PI ));
            }}
         }
      }
   }

   if( Region->MaskPresent ) {
      with_current IsInside &= (int)(*MskArr) == ONE;
   }

   return( IsInside );
}
