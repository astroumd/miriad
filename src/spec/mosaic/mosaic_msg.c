/*----------------------------------------------------------------------------
-- mosaic_msg.c --
/*----------------------------------------------------------------------------*/
#include "mosaic.h"
/*----------------------------------------------------------------------------*/

/******************************************************************************/
/* <<< MESSAGES >>>                                   1142 +  297 = 1439 USERIO
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*
   MESSAGES
   Print a message to standard output, but first compare the value of
   MessageLevel to the level at which the output must be written.
*/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*    <<< Message Level definitions >>>                 64 +    5 =   69 USERIO
/******************************************************************************/

#define Lev_Timer      1
#define Lev_Plane      2
#define Lev_Converge   2
#define Lev_ConvPar    3
#define Lev_Init       4
#define Lev_DataSet    5
#define Lev_CTRL       5
#define Lev_Region     5
#define Lev_Sums       6
#define Lev_Count      7

#define Lev_Trace     11

#define Lev_KeyCheck  21
#define Lev_ValCheck  21
#define Lev_ParCheck  23
#define Lev_DTMCheck  26
#define Lev_Pause     27
#define Lev_CooCheck  29

#define Lev_DDBCheck  61

/******************************************************************************/
/*
   MesLevInp reads the meslev, alltimers and datmod keywords.
   MessageLevel indicates the verbosity of the output.
   It also checks the MOSDEBUG environment variable. The value of MOSDEBUG is
   assigned to MessageLevel if it is larger than Lev_Trace. It then overrides
   the value in the keyword meslev.

   DBG_MESSAGE print a debugging message, after inserting 5 characters in
   the beginning to indicate the machine it is send from. To not hit overflows,
   the message string is copied to the MES variable first.

   There are several modes:
   1) run program locally -> manually 'setenv MOSDEBUG x' on local machine
   2) run with 2 cpus, using 'remotedbg=t' keyword -> manually
              'setenv MOSDEBUG x' on both machines, and explicitly start the
              program on the remote machine as well as the local one
   3) run with 2 cpus, using 'rsh' -> manually 'setenv MOSDEBUG x' on local
              machine, and include it in .cshrc on remote machine
*/
/******************************************************************************/

#define MESSTRLEN 512
private char    MES[MESSTRLEN], *mes;
private int     MessageLevel;
private logical AllTimers;

int MesLevInp()
{
   void   keyi_c(), keyl_c();
   char  *dbglev;
   double AtoF();
   int    debuglevel;
   void   SETDEBUG(), MESSAGE();
   void   DatModInp();

   keyi_c( "meslev", &MessageLevel, 2 );

   dbglev     = getenv("MOSDEBUG");
   debuglevel = dbglev!=NULL ? (int)AtoF(dbglev) : 0;
   if( debuglevel >= Lev_Trace ) {
      MessageLevel = debuglevel;
      SETDEBUG(TRUE);
      Sprintf( MES, "MessageLevel=%d\n", MessageLevel ); MESSAGE(MES);
   } else {
      MessageLevel = min(MessageLevel,Lev_Trace-1);
   }

   keyl_c( "alltimers", &AllTimers, FALSE );

   DatModInp(MessageLevel,AllTimers);

   return( MessageLevel );
}

void MESSAGE();

private void DBG_MESSAGE( format, value )
char *format, *value;
{  char    DTM_IDCHAR();
   logical toolong; int off=0; char save='\0';

   if( value != NULL ) {
      off     = 5 + strlen(format)-2;
      toolong = (int)( off + strlen(value)+1 ) > MESSTRLEN;
      off     = MESSTRLEN - off;
      if( toolong ) { save = *(value+off); *(value+off) = '\0'; }
   } else toolong = FALSE;

   Sprintf(  MES,    "  %c> ", DTM_IDCHAR() );
   Sprintf( &MES[5], format, value );
   MESSAGE(MES);

   if( toolong ) { *(value+off) = save; }
}

void TRACE(func) char *func;
{ if( MessageLevel >= Lev_Trace    ) DBG_MESSAGE( "%s --\n", func  ); }

void DBGVAL(format,value) char *format, *value;
{ if( MessageLevel >= Lev_ValCheck ) DBG_MESSAGE( format,    value ); }

void DBGDTM(format,value) char *format, *value;
{ if( MessageLevel >= Lev_DTMCheck ) DBG_MESSAGE( format,    value ); }

void Pause(message)
char *message;
{
   logical DTMmaster();
   void    MESSAGE();
   if( DTMmaster() && MessageLevel == Lev_Pause ) {
      Sprintf(MES,"Hit <RTN> to %s >",message); MESSAGE(MES); (void)getchar();
   }
}

logical DBGDTMDCD() { return( MessageLevel >= Lev_DDBCheck ); }

/*

/******************************************************************************/
/*    <<< Timer messages >>>                           704 +  241 =  945 USERIO
/******************************************************************************/
/*
   Concentrate all timer messages here.
*/
/******************************************************************************/

logical TimerLevel(n) int n;
{ return( n==0 ? MessageLevel >= Lev_Timer : AllTimers ); }

/******************************************************************************
/*
   Grab bag of timer messages concentrated here to avoid lots of extra
   declarations and ugly-looking code, since different routines need different
   combinations of calls.
*/
/******************************************************************************/

void Timer_End(mode)
char *mode;
{
   logical      TimerLevel();
   void         Timer_Stop(), Timer_Change(), Timer_Print();
   private void TimerDTM();
   private void TimerParallel();
   private void TimerCPR();

   logical LocallyRun();
   int     prtmode;
   void    ExchangeVariables();
   double  AtoF();
   int     plane;
   char    string[40];

/* time for individual disk IO stages */
   if( StrEq(mode,"map") || StrEq(mode,"beam") || StrEq(mode,"output") ) {

                                                       prtmode = 0;
      if( MessageLevel >= Lev_Timer && !LocallyRun() ) prtmode = 1;
      if( AllTimers                                  ) prtmode = 2;
      if( prtmode == 0 ) return;

      Sprintf( MES, "Time for %s disk IO", mode );
      TimerCPR( prtmode==2, "DISK_IO", "TOTAL_DISK_IO", MES );

      if( !LocallyRun() ) {
      Sprintf( MES, "Time for %s data exchange", mode );
      TimerCPR( prtmode==2, "DATA_EXCHANGE", "TOTAL_DATA_EXCH", MES ); }

      Sprintf( MES, "  (time spent in with loops)" );
      TimerCPR( prtmode==2, "PARALLEL", "TOTAL_PARALLEL", MES );

/* finishing InitArrays */
   } else if( StrEq(mode,"REMOTE_INIT") ) {
      Timer_Stop(    "REMOTE_INIT" );
      Timer_Change(  "TOTCALC","+","REMOTE_INIT" );
      if( TimerLevel(1) ) {
         Timer_Print( "REMOTE_INIT", "Time for array initializations" );
         TimerParallel( FALSE );
         TimerParallel( TRUE  );
      }

/* finishing SetupArrays */
   } else if( StrEq(mode,"LOCAL_INIT") ) {
      Timer_Stop(  "LOCAL_INIT" );
      TimerDTM( FALSE );
      ExchangeVariables( "TIMERS",0,0,0,0,0 ); /* add REMOTE_INIT user+system */
      Timer_Print( "LOCAL_INIT", "Time for initializations" );

/* finishing remote execution */
   } else if( StrEq(mode,"DTM_REMOTE_EXEC") ) {
      Timer_Stop(   "DTM_REMOTE_EXEC" );
      if(TimerLevel(1))
      Timer_Print(  "DTM_REMOTE_EXEC","Time for remote execution" );
      Timer_Change( "DTM_READ", "-", "DTM_REMOTE_EXEC" );

/* finishing one plane */
   } else if( StrEq("PLANE",mode ) ) {
      plane = (int)AtoF( mode+5 );
      TimerDTM( FALSE );
      Timer_Stop(  "PLANE"); Sprintf( string,"Total time for plane %d", plane );
      Timer_Print( "PLANE", string );

/* finishing Local_Main */
    } else if( StrEq(mode,"TOTAL" ) ) {

#ifdef TIME_FFT
      if( AllTimers && StrEq(string,"FFT") ) {
         Timer_PrintN( 41, "FFTRC" );
         Timer_PrintN( 42, "FFTCR" );
         Timer_PrintN( 43, "FFTCC" );
         Timer_PrintN( 44, "FFT842" );
      }
#endif

      TimerCPR(AllTimers,"TOTAL_DISK_IO",  "\0","Total time for disk IO"      );
      if( !LocallyRun() )
      TimerCPR(TRUE,     "TOTAL_DATA_EXCH","\0","Total time for data exchange");

      TimerDTM( TRUE );

      Timer_Print( "TOTCALC", "Total time spent calculating" );
      Timer_Stop(  "TOTAL" );
      Timer_Print( "TOTAL",   "Total time for this run" );

/* finishing Remote_Main */
   } else if( StrEq(mode,"REMOTE_DTM") ) {
      TimerDTM( TRUE );

   }
}

/******************************************************************************/
/*
   Timing waiting for DTM.
*/
/******************************************************************************/

private void TimerDTM(total)
logical total;
{
   logical      LocallyRun(), DTMmaster();
   private void TimerCPR();

   if( !AllTimers || LocallyRun() ) return;

   if( DTMmaster() ) {
      TimerCPR(TRUE,"DTM_READ", "TOTAL_DTM","Time spent in DTMreadMsg" );
      TimerCPR(TRUE,"DTM_WRITE","TOTAL_DTM","Time spent in DTMwriteMsg");
   } else {
      TimerCPR(TRUE,"DTM_READ", "TOTAL_DTM","Remote time spent in DTMreadMsg");
      TimerCPR(TRUE,"DTM_WRITE","TOTAL_DTM","Remote time spent in DTMwriteMsg");
   }
   if( total )
   TimerCPR( TRUE, "TOTAL_DTM", "\0", "Total time waiting for DTM" );
}

/******************************************************************************/
/*
   Timing with loops
*/
/******************************************************************************/

private void TimerParallel(total)
logical total;
{
   private void TimerCPR();
   if( !AllTimers ) return;

   if( !total )
   TimerCPR(TRUE,"PARALLEL","TOTAL_PARALLEL","  (time spent in with loops)");
   else
   TimerCPR(TRUE,"TOTAL_PARALLEL", "\0",     "  (total time in with loops)");
}

/******************************************************************************/
/*
   Utility to add written time to total time, or write total time.
*/
/******************************************************************************/

private void TimerCPR( printflag, timer, tottimer, mess )
logical printflag;
char   *timer, *tottimer, *mess;
{
   void Timer_Print(), Timer_Reset(), Timer_Change();
   if(*tottimer!='\0') Timer_Change( tottimer, "+", timer );
   if( printflag )     Timer_Print( timer, mess );
   Timer_Reset( timer );
}

/******************************************************************************/
/*
   Start/Stop and Print timers needed for calculations.
*/
/******************************************************************************/

void CalcTimers(mode)
int mode;
{
   void         Timer_Start(), Timer_Stop(), Timer_Reset(), Timer_Change();
   void         Timer_Print();
   private void TimerParallel();
   logical      TimerLevel();
   switch( mode ) {
   case 0: Timer_Start( "CALC"  );
           Timer_Start( "STAGE" );
           break;

   case 1: if( TimerLevel(1) ) {
           Timer_Stop(  "STAGE" );
           Timer_Print( "STAGE", "-- time for reference initializing" );
           TimerParallel( FALSE );

           Timer_Reset( "CONV"  );
           Timer_Start( "STAGE" ); }
           break;

   case 2: if( TimerLevel(1) ) {
           Timer_Stop(  "STAGE" );
           Timer_Print( "STAGE", "-- time to regrid single-dish maps" );
           TimerParallel( FALSE );

           Timer_Start( "STAGE" );
           }
           break;

   case 3: if( TimerLevel(1) ) {
           Timer_Stop(  "STAGE" );
           Timer_Print( "STAGE", "-- time for deconvolution" );

           Timer_Reset( "OCALC" );
           Timer_Change("OCALC", "+", "STAGE" );
           Timer_Change("OCALC", "-", "CONV" );

           Timer_Print( "CONV",  "  (time for convolutions)" );
           Timer_Print( "OCALC", "  (time for other calculations)" );
           TimerParallel( FALSE );

           Timer_Start( "STAGE" ); }
           break;

   case 4: if( TimerLevel(1) ) {
           Timer_Stop(  "STAGE" );
           Timer_Print( "STAGE", "-- time for restorations" );
           TimerParallel( FALSE );

           Timer_Start( "STAGE" ); }
           break;

   case 5: Timer_Stop(  "CALC"  );
           Timer_Print( "CALC",  "Calculation time for this plane" );
           TimerParallel( TRUE );

           Timer_Change("TOTCALC",  "+","CALC");

           break;
   }
}

/*

/******************************************************************************/
/*    <<< User messages >>>                            704 +  241 =  945 USERIO
/******************************************************************************/
/*
   Define some counters to be able to count the number of operations.
   Counts[0][i] counts initializations
   Counts[1][i] counts combination of output maps
   Counts[2][i] counts the convolution
   Counts[3][i] counts the mosaic algorithm
   i=0 counts the number of pointer dereferencings
       (1 instruction / operation)
   i=1 counts the number of memory operations
       (2 instructions / load; 1 instruction / store)
   i=2 counts the number of arithmetic and logical operations.
       (4 instructions / add,mult,madd; 14 instructions / div,sqrt)

   for loop:             1 load + 1 store + 1 comp + 1/4 arith per iteration
   comparison with mask: 1 pointer deref + 1 load + 1 comp per iteration
*/
/******************************************************************************/

#define NCNT 3
#define NCOUNTERS 5
private double Counts[NCOUNTERS][NCNT] = { 0,0,0, 0,0,0, 0,0,0, 0,0,0, 0,0,0 };

private char cntstring[NCOUNTERS][9] =
     { "Init", "FinishUp", "Convolve", "Mosaic", "Total" };
private char *fillerspace = "               ";

void OperCount(nr,aShape,sel,npstore,npload,nmem,narith,ndiv)
int            nr,       sel,npstore,npload,nmem,narith,ndiv;
shape            *aShape;
{
   int lc = sel ? aShape->nsel : aShape->size;
   int fc =                      aShape->size;
   Counts[nr][0] += lc*( npstore + npload )            + fc*(    (sel?1:0));
   Counts[nr][1] += lc*( npstore + 2*npload + 2*nmem ) + fc*(3  +(sel?2:0));
   Counts[nr][2] += lc*( narith + 3.5*ndiv )           + fc*(5/4+(sel?1:0));
}

void ExchCounts()
{
   void    DTMexchange();
   logical DTMs2m();
   DTMexchange( DTMs2m(), "COUNTS", "ddddddddddddddd",
   &Counts[0][0], &Counts[0][1], &Counts[0][2],
   &Counts[1][0], &Counts[1][1], &Counts[1][2],
   &Counts[2][0], &Counts[2][1], &Counts[2][2],
   &Counts[3][0], &Counts[3][1], &Counts[3][2],
   &Counts[4][0], &Counts[4][1], &Counts[4][2] );
}

void Messages_Count()
{if( MessageLevel >= Lev_ConvPar || AllTimers ) {
   private void dashfill();
   void         Timer_Return();
   int          i, nr;
   int          ntot = NCOUNTERS-1;
   double       totopI, totopA, timeU, times[3];

   for( i=0;i<NCNT;i++ ) {
      for( nr=0;nr<ntot;nr++ ) Counts[ntot][i] += Counts[nr][i];
   }

   if( MessageLevel >= Lev_Count ) {
      dashfill( "", 0 );
      for( nr=0; nr<NCOUNTERS; nr++ ) {
         dprintf( "%s count:%s%10d pointer ops; %10d mem ops; %10d arith ops\n",
                   cntstring[nr], &fillerspace[strlen(cntstring[nr])+7],
                   (long int)Counts[nr][0],
                   (long int)Counts[nr][1],
                   (long int)Counts[nr][2]  );
      }
      totopI = Counts[ntot][0]+Counts[ntot][1]+Counts[ntot][2];
      dprintf( "%s%s%10d\n", "Total ops:", &fillerspace[strlen("Total ops:")],
                   (long int)totopI );
   }
   dashfill( "", 0 );

   totopI = ( Counts[ntot][0]+Counts[ntot][1]+4*Counts[ntot][2] ) / 1.e6;
   totopA =   Counts[ntot][2] / 1.e6;
   Timer_Return("TOTCALC",times); timeU=times[1];

   dprintf( "MIPS   (total ops/total user time): %5.1f\n", totopI/timeU );
   dprintf( "MFlops (arith ops/total user time): %5.1f\n", totopA/timeU );
   dashfill( "", 0 );

}}

/*

/******************************************************************************/
/*
   Tell user the plane.
*/
/******************************************************************************/

void Messages_Plane( plane )
int   plane;
{if( MessageLevel >= Lev_Plane ) {
   private void dashfill();
   dashfill( "", 0 );
   dprintf( "Working on plane %d\n", plane );
}}

/*

/******************************************************************************/
/*
   Tell user the read/write plane.
*/
/******************************************************************************/

void Messages_RW( mess, plane, name )
char *mess;
int   plane;
char *name;
{if( MessageLevel >= Lev_Init ) {
   if( name != NULL ) dprintf( "%s plane %d of dataset %s\n", mess,plane,name );
   else               dprintf( "%s plane %d\n",               mess,plane      );
}}

/******************************************************************************/
/*
   Print a message with the value of a parameter.
*/
/******************************************************************************/

void Messages_Par( mess, value )
char *mess;
Real  value;
{if( MessageLevel >= Lev_ParCheck )
{
   int i;
   for(i=0;i<100;i++) MES[i]=' ';
   StrCpy( MES, mess ); StrCat( MES, ":" );
   MES[strlen(MES)]=' '; MES[35]='\0';
   StrCat(  MES, "%f\n" );
   dprintf( MES, value );
}}

/******************************************************************************/
/*
   Print a message during initializations of arrays.
*/
/******************************************************************************/

void Messages_Init( string, name )
char *string;
char *name;
{if( MessageLevel >= Lev_Init ) {
   dprintf( "Initializing %s for dataset %s\n", string, name );
}}

/******************************************************************************/
/*
   Print information about datasets (e.g.):

   The mosaiced dataset <<model>> will have the following parameters:
   object: xxx naxes: 4;  nPoints: 21488
   axis                  1            2            3            4
   ctype          RA---SIN     DEC--SIN         FREQ       STOKES
   crval       19:57:43.97   40:35:47.3     101.4303       1.0000
   crshf       00:00:15:00  -00:00:05.8
   cdelt      -00:00:05.0    00:00:05.0       0.6200       1.0000
   delra      -00:00:00.33                                       
   axlen               128          128            1            1
   crpix           80.0000      69.0000       1.0000       1.0000
*/
/******************************************************************************/

private void Messages_DataSet( Set )
DATASET *Set;
{if( MessageLevel >= Lev_DataSet ) {
   private void dashfill();
   private void axprint();

   if(        StrEqX( Set->type, "input"     ) ||
              StrEqX( Set->type, "sdinput"   ) ||
              StrEqX( Set->type, "reference" ) ||
              StrEqX( Set->type, "initial"   ) ||
              StrEqX( Set->type, "estimate"  )    ) {
      dashfill( "", 0 );
      dprintf( "The %s dataset <<%s>> has the following parameters:\n",
                Set->type, Set->name);

   } else if( StrEqX( Set->type, "synthesized beam" ) ) {
      dashfill( "---------- Synthesized beam parameters", 1 );
      dprintf( "   From dataset <<%s>>\n", Set->name );
      return;

   } else if( StrEqX( Set->type, "model"     ) ||
              StrEqX( Set->type, "linmos"    )    ) {
      dashfill( "", 0 );
      dprintf( "The %s dataset <<%s>> will have the following parameters:\n",
                Set->type, Set->name );
   }

   if( strlen(Set->Object) != 0 ) dprintf( "   object %s", Set->Object );
   dprintf( "   naxes: %d;  nPoints: %d",
            AxisToInt(Set->Coords.naxis), Set->Coords.nPoints );
   if( StrEqX( Set->type, "input" ) ) dprintf( ";  rms %6.3f", Set->rms );
   dprintf( "\n" );

   axprint( "axis",  &Set->Coords );
   axprint( "ctype", &Set->Coords );
   axprint( "crval", &Set->Coords );
   axprint( "crshf", &Set->Coords );
   axprint( "cdelt", &Set->Coords );
   axprint( "delra", &Set->Coords );
   axprint( "axlen", &Set->Coords );
/* axprint( "blc",   &Set->Coords );
   axprint( "trc",   &Set->Coords ); */
   axprint( "crpix", &Set->Coords );
}}

private void axprint( id, Coords )
register char *id;
COORDS        *Coords;
{
   void radra(), raddec();
   AXIS n, j;
   mes=&MES[0];

   Sprintf( mes, "   %-10s", id ); mes += 13;
   for( n=AXIS1; n<=Coords->naxis; n++ ) {
      for( j=AXIS1; j<=Coords->naxis; j++ ) if(n==Coords->axisnr[j]) break;
      if( StrEq(id,"axis")  ) Sprintf( mes, "       %1d     ",
                                                  AxisToInt(Coords->axisnr[n]));
      if( StrEq(id,"ctype") )      Sprintf( mes, "%13s", Coords->ctype[j]  );
      if( StrEq(id,"crval") ) { *mes = *(mes+1)=' '; switch( j ) {
                     case RA_AXIS: radra(  Coords->crval[j], (mes+1) ); break;
                     case DC_AXIS: raddec( Coords->crval[j], (mes+2) ); break;
                     default:      Sprintf( mes, "%13.4f", Coords->crval[j]); }}
      if( StrEq(id,"crshf") ) { *mes = *(mes+1)=' '; switch( j ) {
                     case RA_AXIS: radra(  Coords->crshf[j], (mes+1) ); break;
                     case DC_AXIS: raddec( Coords->crshf[j], (mes+2) ); break;
                     default:      Sprintf( mes, "             " );           }}
      if( StrEq(id,"cdelt") ) { *mes = *(mes+1)=' '; switch( j ) {
                     case RA_AXIS: raddec( Coords->cdelt[j], (mes+2) ); break;
                     case DC_AXIS: raddec( Coords->cdelt[j], (mes+2) ); break;
                     default:      Sprintf( mes, "%13.4f", Coords->cdelt[j]); }}
      if( StrEq(id,"delra") ) { *mes = *(mes+1)=' '; switch( j ) {
                     case RA_AXIS: radra(  Coords->cdelt[j], (mes+1) ); break;
                     case DC_AXIS: Sprintf( mes, "             " );     break;
                     default:      Sprintf( mes, "             " );          }}
      if( StrEq(id,"axlen") )      Sprintf( mes, "%13d",   Coords->axlen[j]  );
      if( StrEq(id,"blc")   )      Sprintf( mes, "%13d",   Coords->blc[j]    );
      if( StrEq(id,"trc")   )      Sprintf( mes, "%13d",   Coords->trc[j]    );
      if( StrEq(id,"crpix") )      Sprintf( mes, "%13.3f", Coords->crpix[j]  );
      mes += 13;
   }
   *mes = '\n'; *(mes+1) = '\0';
   dprintf( MES );
}

/******************************************************************************/
/*
   Print information about the primary beam.
*/
/******************************************************************************/

private void Messages_PB( PB )
PBPAR *PB;
{if( MessageLevel >= Lev_Init ) {
   private void dashfill();
   void         PBdescription();
   char         string[OUTSTRLEN];
   if( MessageLevel >= Lev_DataSet )
   dashfill( "---------- Primary Beam parameters", 1 );
   else
   dashfill( "---------- Beam parameters", 1 );
                                 dprintf( "   Telescope: %s", PB->Telescope );
   if( PB->fwhm != ZERO ) {
   if( PB->freq  > PB->LimFreq ) dprintf( "; pbfwhm %8.2f''",dtos(PB->fwhm) );
   if( PB->freq <= PB->LimFreq ) dprintf( "; pbfwhm %8.2f'", dtom(PB->fwhm) ); }
   if( PB->freq != ZERO        ) dprintf( " at %9.5f GHz",   PB->freq       );
   dprintf( "\n" );
   PBdescription( PB, string );
}}

/******************************************************************************/
/*
   Print information about the synthesized beam.
*/
/******************************************************************************/

void Messages_BM( mess, BM )
char  *mess;
BMPAR *BM;
{if( MessageLevel >= Lev_ConvPar ) {
   dprintf( "%sFWHM:  %5.2f x %5.2f arcsec; PA %4.1f degrees\n",
             mess, rtos(BM->bmaj), rtos(BM->bmin), rtod(BM->bpa) );
}}

/******************************************************************************/
/*
   Print information giving the relative positions of input maps (e.g.):

   List of where each input map fits in mosaiced map
   Dataset        blc(x)  trc(x)  blc(y)  trc(y)  crpix(x) crpix(y)
   map1             16     143       5     132     80.000   69.000
   map2             31     158       9     136     95.326   73.400
   map3              1     128       1     128     65.037   64.500
*/
/******************************************************************************/

void Messages_Where( Lun, MosMap, Maps )
int     Lun;
MOSMAP *MosMap;
ONEMAP *Maps;
{if( MessageLevel >= Lev_DataSet || Lun != 0 ) {
   private void dashfill();
   private void TerHisOut();
   double       ConvertPixel();

   ONEMAP *MapI;
   COORDS *SetCoo;
   COORDS *MosCoo = &MosMap->MosaicMap.Coords;
   double  xorg,  yorg;
   double  xmap,  ymap;
   int     n=1;
   int    *Grid, xwidth, ywidth, x, y, mxlen, mylen, miny, maxy;
   double  scale;
   if( Maps->PB.fwhm != ZERO ) scale = 8. / Maps->PB.fwhm;
   else                        scale = 8. / (120.*rtod(MosCoo->cdelt[DC_AXIS]));


   if( Lun == 0 ) {
      mxlen  = MosCoo->XLEN;
      mylen  = MosCoo->YLEN;
      xwidth = nint( fabs(rtod(MosCoo->cdelt[RA_AXIS]*MosCoo->XLEN)) * scale );
      ywidth = nint(     (rtod(MosCoo->cdelt[DC_AXIS]*MosCoo->YLEN)) * scale );
      Malloc( Grid, int, xwidth*ywidth );
      for( x=0; x<xwidth*ywidth; x++ ) *(Grid+x)=0;
      miny=ywidth; maxy=0;
   }

   if( Lun == 0 ) dashfill( "", 0 );
   TerHisOut( Lun, "List of where each input map fits in mosaiced map\n" );
   TerHisOut( Lun,
   "Dataset                   blc(x) trc(x) blc(y) trc(y) pointing center @\n"
   );

   for( ALLMAPSI ) { if( MapI->IsIFmap ) {
      SetCoo = &MapI->Observation.Coords;
      xorg   = ConvertPixel(ZERO,SetCoo,MosCoo,RA_AXIS);
      yorg   = ConvertPixel(ZERO,SetCoo,MosCoo,DC_AXIS);
      xmap   = xorg + SetCoo->crpix[RA_AXIS];
      ymap   = yorg + SetCoo->crpix[DC_AXIS];
      Sprintf( MES, "%-26s %4d   %4d   %4d   %4d   %5.1f   %5.1f\n",
                     MapI->Observation.name,
                           nint(xorg)+1, nint(xorg+SetCoo->XLEN),
                                       nint(yorg)+1, nint(yorg+SetCoo->YLEN),
                                                   xmap, ymap );
      TerHisOut(Lun,MES);
      if( Lun == 0 ) {
         x = nint( xwidth * xmap/mxlen );
         y = nint( ywidth * ymap/mylen ); miny=min(miny,y); maxy=max(maxy,y);
         *(Grid + xwidth*y + x) = n++;
      }
   }}
   if( Lun == 0 ) {
      dashfill( "", 0 );
      dprintf( "Schematic distribution of pointing centers\n" );
      for( y=maxy; y>=miny; y-- ) { for( x=0; x<xwidth; x++ ) {
         if( *(Grid+xwidth*y+x) == 0 ) dprintf("  ");
         else                          dprintf("%2d", *(Grid + xwidth*y + x) );
      } dprintf("\n"); }
   }

}}

/******************************************************************************/
/*
Memory usage ------------------------------------------------------------------
  Interferometer maps (Obs, PrimBeam, Res, PrevRes, Assoc, SynthBeam)
    Each map:                                                       1.57 Mbyte
      5  256x 256 images of  65536 pixels, 0.26 Mbyte
      1  256x 256 image  of  65536 pixels, 0.26 Mbyte
    Total of 3 interferometer maps:                                 4.72 Mbyte
  Single-dish maps (Obs, PrimBeam, Res, PrevRes, Map);
    Each map:                                                       x.xx Mbyte
      1    nx   n image  of  65536 pixels, 0.26 Mbyte
      1    mx   m image  of  65536 pixels, 0.26 Mbyte
      3  146x 185 images of  27010 pixels, 0.11 Mbyte
    Total of x single-dish input maps                               x.xx Mbyte
  Mosaiced map (Est, Ref, Grad X, H, J, Grad^2 X, Metric, Sel)
      8  146x 185 images of  27010 pixels, 0.11 Mbyte
    Total:                                                          0.86 Mbyte
  Scratch space for IO and convolutions:                            0.68 Mbyte
  Total use:                                                        6.27 Mbyte
*/
/******************************************************************************/

private char *spaces = {
"                                                                  " };

#define Mbyte(a) ((Real)((a)/1.E6))

#define nOData MapI->Observation.Coords.nPoints
#define nDData MapI->DirtyMap.Coords.nPoints
#define nPData MapI->PrimaryBeam.Coords.nPoints
#define nBData MapI->SynthBeam.Coords.nPoints
#define nMData MosMap->MosaicMap.Coords.nPoints
#define nGData MosMap->Gaussian.Coords.nPoints

#ifdef __CSTAR__
#define NBEAARRAYS (2)
#define NGAUARRAYS (2)
#else
#define NBEAARRAYS (1)
#define NGAUARRAYS (1)
#endif

private void Messages_Memory( MosMap, Maps, Flags )
MOSMAP  *MosMap;
ONEMAP  *Maps;
logical  Flags[];
{if( MessageLevel >= Lev_Init ) {
   private void dashfill();
   private void Messages_Size();
   int          CalcScratch();
   ONEMAP      *MapI;
   DATASET     *oSet, *dSet, *bSet, *pSet;
   logical      sameIF=TRUE,   sameSD=TRUE;
   logical      FirstIF=TRUE,  FirstSD=TRUE;
   int          size=0;
   int          nInt=0, nSD=0;
   int          MpBt, nBytes, nBytesTot=0;

   dashfill( "Memory usage", 0 );

   for( ALLMAPSI ) {
      if( MapI->IsIFmap ) {
        nInt++; if( FirstIF ) { size = nOData; FirstIF=FALSE;      }
                else          { if( nOData != size ) sameIF=FALSE; }
      } else {
        nSD++;  if( FirstSD ) { size = nOData; FirstSD=FALSE;      }
                else          { if( nOData != size ) sameSD=FALSE; }
      }
   }


   FirstIF=TRUE; nBytes=0;
   dprintf(
   "   Interferometer maps (Obs, PrimBeam, Res, PrevRes, Assoc, SynthBeam)\n" );
   for( ALLMAPSI ) { if( MapI->IsIFmap ) {
      dSet = &MapI->DirtyMap;
      bSet = &MapI->SynthBeam;
      MpBt = ( 5*nOData+(Flags[READBEAMS]?NBEAARRAYS:0)*nBData ) * sizeof(Real);

      if(  sameIF && FirstIF )   dprintf( "     Each map:%s%7.2f Mbyte\n",
                                   &spaces[15], Mbyte(MpBt) );
      if( !sameIF            )   dprintf( "     %s:%s%7.2f Mbyte\n", dSet->name,
                                   &spaces[strlen(dSet->name+3)], Mbyte(MpBt) );
      if( !sameIF || FirstIF ) { Messages_Size( 5,          dSet );
                                 Messages_Size( NBEAARRAYS, bSet ); }

      nBytes += MpBt;
      FirstIF=FALSE;
   }}
   if( nInt < 10 ) dprintf( "     Total of %1d Input maps ", nInt );
   else            dprintf( "     Total of %2d Input maps",  nInt );
   dprintf( "%s%7.2f Mbyte\n", &spaces[28], Mbyte(nBytes) );
   nBytesTot += nBytes;


   if( nSD > 0 ) {
   FirstSD=TRUE; nBytes=0;
   dprintf("   Single-dish maps (Obs, RegrObs, PrimBeam, Res, PrevRes, Map)\n");
   for( ALLMAPSI ) { if( MapI->IsSDmap ) {
      oSet = &MapI->Observation;
      dSet = &MapI->DirtyMap;
      pSet = &MapI->PrimaryBeam;
      MpBt = ( 1*nOData + 3*nDData + 1*nPData ) * sizeof(Real);
      if(  sameSD && FirstSD )   dprintf( "     Each map:%s%7.2f Mbyte\n",
                                   &spaces[15], Mbyte(MpBt) );
      if( !sameSD            )   dprintf( "     %s:%s%7.2f Mbyte\n", oSet->name,
                                   &spaces[strlen(oSet->name+3)], Mbyte(MpBt) );
      if( !sameSD || FirstSD ) { Messages_Size( 1, oSet );
                                 Messages_Size( 3, dSet );
                                 Messages_Size( 1, pSet ); }
      nBytes += MpBt;
      FirstSD=FALSE;
   }}
   if( nSD < 10 ) dprintf( "     Total of %1d Input maps ", nSD );
   else           dprintf( "     Total of %2d Input maps",  nSD );
   dprintf( "%s%7.2f Mbyte\n", &spaces[28], Mbyte(nBytes) );
   nBytesTot += nBytes;
   }


   dprintf( "   Mosaiced map" );
   dprintf(  " (Est, Ref, Grad X, H, J, Grad^2 X, Metric, Sel)\n" );
   MpBt = 8 * nMData * sizeof(Real);
   Messages_Size( 8, &MosMap->MosaicMap );
   dprintf( "     Total:%s%7.2f Mbyte\n", &spaces[12], Mbyte(MpBt) );
   nBytesTot += MpBt;


   if( Flags[CALCGAU] ) {
#ifdef __CSTAR__
      nBytes = sizeof(Real) *   nGData * NGAUARRAYS;
#else
      nBytes = sizeof(Real) * ( nGData - nMData );
#endif
   } else {
      nBytes = 0;
   }
   nBytes += CalcScratch( MosMap, Maps, Flags ) * sizeof(Real);
   dprintf( "   Scratch space for IO and convolutions:%s%7.2f Mbyte\n",
             &spaces[42], Mbyte(nBytes) );
   nBytesTot += nBytes;


   dprintf( "   Total use:%s%7.2f Mbyte\n", &spaces[14], Mbyte(nBytesTot) );
}}

private void Messages_Size( nImage, Set )
int      nImage;
DATASET *Set;
{
   int xlen = Set->Coords.XLEN;
   int ylen = Set->Coords.YLEN;
   dprintf( "        %1d %4dx%4d image%s of %7d pixels, %7.2f Mbyte\n",
                     nImage, xlen, ylen,
                     nImage==1 ? " " : "s",
                     xlen*ylen, Mbyte(xlen*ylen*sizeof(Real))
          );
}

/******************************************************************************/
/*
   Print an overview of the selected region (e.g):

   >> Map 1
      Planes (1): 1
      List  1 (Box corners): 54 57 67 72
      There is a mask, from file mmap1
*/
/******************************************************************************/

private void Messages_Region( Region )
REGION *Region;
{if( MessageLevel >= Lev_Region ) {
   private void  dashfill();
   register int  i, j;
   register int *vl, nEl, nVrt;

   dashfill( "---------- Selected region", 1 );

   dprintf( "      Planes (%d): ", Region->nPlanes );
   for( i=0; i<Region->nPlanes; i++ ) dprintf( "%d ", *(Region->Planes+i) );
   dprintf("\n");

   for( i=0; i<Region->nVertLists; i++ ) {
      vl  = Region->VertList[i];
      nEl = *vl; nVrt = *(vl+1);
      if(nEl>0) { dprintf("      List %2d (Box corners): ", i+1     ); vl+=2; }
      else      { dprintf("      List %2d (%2d Vertices): ",i+1,nVrt); vl+=6; }
      for( j=0; j<2*abs(nVrt); j++ ) dprintf( "%d ", *(vl+j) ); dprintf("\n");
   }

   if( Region->MaskPresent ) {
   dprintf( "      Mask from file <<%s>>\n", Region->Mask->name ); }
}}

/******************************************************************************/
/*
   Print information concerning the control parameters (e.g):

   Control Parameters
      TargetRms  0.100  0.100  0.100
      TargetFlux 15.000000   Do not constrain flux
      Maximum number of iterations: 20
      Tolerance in norm criterion:  1.0%
      Tolerance in chi^2 and flux:  5.0%
      Gull's entropy measure --- Sum b (log(b/r)-1)
      Do not read initial estimate   Do not read reference image
*/
/******************************************************************************/

private void Messages_CTRL( Flags, CTRL, Maps )
logical  Flags[];
CONTROL *CTRL;
ONEMAP  *Maps;
{  private void dashfill();
   ONEMAP      *MapI;
   int          n;
 if( MessageLevel >= Lev_CTRL ) {
   dashfill( "", 0 );
   dprintf( "Control Parameters\n" );

   dprintf( "   TargetRms " );
   for( ALLMAPSI ) dprintf( "%6.3f ", MapI->DirtyMap.rms ); dprintf("\n");

   if( CTRL->TargetFlux != ZERO ) {
      dprintf( "   TargetFluxes (channel:flux) " );
      for(n=0;n<CTRL->nchan;n++)
      dprintf( "(%d:%6f) ", n+1, fabs(*(CTRL->TargetFluxes+n)) );
      dprintf("\n");
   }
   if( CTRL->TargetFlux > ZERO ) dprintf( "   Constrain flux       \n" );
   else                          dprintf( "   Do not constrain flux\n" );

   dprintf( "   Maximum number of iterations: %4d\n",    CTRL->MaxIters );

   Sprintf( MES, "   Tolerance in norm criterion:  %4.1f%c%c\n",
                     Procent(CTRL->Epsilon),   '%','%' ); dprintf(MES);
   Sprintf( MES, "   Tolerance in chi^2 and flux:  %4.1f%c%c\n",
                     Procent(CTRL->Tolerance), '%','%' ); dprintf(MES);

   switch( CTRL->EntropyMeasure ) {
   case GULL:
   dprintf( "   Gull's entropy measure - Sum b( log(b/r)-1 )\n"       ); break;
   case CORN:
   dprintf( "   Cornwell's entropy measure - Sum -log( cosh(b/r) )\n" ); break;}

   if(  Flags[READINI] ) dprintf( "   Read initial estimate       \n" );
   else                  dprintf( "   Do not read initial estimate\n" );
   if(  Flags[READREF] ) dprintf( "   Read reference image        \n" );
   else                  dprintf( "   Do not read reference image \n" );
}
   if( MessageLevel >= Lev_Init ) dashfill( "", 0 );
}

/******************************************************************************/
/*
   Print message when starting a new iteration:

   ITERATION #
      alpha = .......; beta = .......; ClipLevel = .......
      Q[.]=.....
*/
/******************************************************************************/

private double PreviousMagicQ=0.;

void Messages_Iter( CTRL, Stats, Maps )
CONTROL *CTRL;
STATS   *Stats;
ONEMAP  *Maps;
{if( MessageLevel >= Lev_Converge ) {
   private void dashfill();
   ONEMAP      *MapI;
   int          i=1;
   logical      ConstrainFlux = CTRL->TargetFlux > ZERO;

if( MessageLevel == Lev_CTRL && Stats->Iteration == 1 ) {
   dashfill( "", 0 );
   dprintf( "rms  = rms of combined residual\n" );
   dprintf( "F    = flux in model\n" );
   dprintf( "Norm = 'norm GradJ'/'norm unit vector'; steepness of gradient\n");
   dprintf( "dX^2 = percent difference between chi^2 and wanted value\n" );
   if( ConstrainFlux ) {
   dprintf( "dF   = percent difference between Flux and wanted value\n" );
   dprintf( "a,b  = Lagrange multipliers\n" ); }
   else
   dprintf( "alpha = Lagrange multiplier\n" );
}

if( MessageLevel >= Lev_ConvPar ) {
  dashfill( "", 0 );
  dprintf( "ITERATION # %d\n", Stats->Iteration );

  mes = &MES[0];
   Sprintf(mes, "   alpha = %7.3g;",Stats->LM[LMint]); mes=&MES[0]+strlen(MES);
  if( ConstrainFlux ) {
   Sprintf(mes, "   beta = %7.3g;", Stats->LM[LMflx]); mes=&MES[0]+strlen(MES);}
  if( CTRL->EntropyMeasure == GULL ) {
   Sprintf(mes, "   Clip @ %7.3g",  Stats->Clip     ); mes=&MES[0]+strlen(MES);}
  Sprintf(mes, "\n");
  dprintf(MES);

  if( Stats->MagicQ != PreviousMagicQ || Stats->Iteration == 1 ) {
    mes = &MES[0];
    for( ALLMAPSI, i++ ) {
       if(i<10)Sprintf(mes,"   Q[%1d]= %5.2f",i,MapI->BM.Q*sqrt(Stats->MagicQ));
       else    Sprintf(mes, "   Q[%2d]=%5.2f",i,MapI->BM.Q*sqrt(Stats->MagicQ));
       mes = &MES[0]+strlen(MES);
       if( (i-1)%4 == 3 || MapI->NextMap==NULL ) {
          Sprintf( mes, "\n" ); dprintf(MES); mes = &MES[0];
       }
    }
    PreviousMagicQ = Stats->MagicQ;
  }
}}
}

/******************************************************************************/
/*
   Print message with short convergence information:

   if MessageLevel == Lev_Converge

IT .. rms=_.___ F=___.__ Norm=_.___ dX^2=____._% dF=____._% ab=_.__e__,_.__e__
IT .. rms=_.___ F=___.__ Norm=_.___ dX^2=____._% alpha=_._____ clip=_.__e__

*/
/******************************************************************************/

private void Messages_Converge_Short( CTRL, Stats )
CONTROL *CTRL;
STATS   *Stats;
{
   void    SumChiSq();
   double  ratio;
   double  ChiSq, TargetChiSq, Cdiff;
   double  mFlux, TargetFlux,  Fdiff;
   logical ConstrainFlux;

   SumChiSq( CTRL,Stats, &ratio, &ChiSq, &TargetChiSq, &Cdiff,
                                 &mFlux, &TargetFlux,  &Fdiff, &ConstrainFlux );

   mes = &MES[0];
   Sprintf(mes,"IT %2d rms=%5.3f F=%6.2f Norm=%5.3f dX^2=%6.2f%c%c",
           Stats->Iteration,Stats->rms,mFlux,ratio,Cdiff,'%','%');

   mes = &MES[0]+strlen(MES);
   if( ConstrainFlux )
   Sprintf(mes, " dF=%6.2f%c%c a,b=%6.1e,%6.1e\n",
           Fdiff, '%','%', Stats->LM[LMint], Stats->LM[LMflx] );
   else
   Sprintf(mes, " alpha=%7.1e clip=%7.2e\n", Stats->LM[LMint], Stats->Clip );
   dprintf(MES);
}

void Messages_Converge_Long( Lun, CTRL, Stats, plane )
int      Lun;
CONTROL *CTRL;
STATS   *Stats;
int      plane;
{if( Stats->Iteration > 0 ) {
   private void dashfill();
   private void TerHisOut();
   void         SumChiSq();
   double       ratio;
   double       ChiSq, TargetChiSq, Cdiff;
   double       mFlux, TargetFlux,  Fdiff;
   logical      ConstrainFlux;

   if( Lun!=0 ) CTRL->TargetFlux = *(CTRL->TargetFluxes+plane-1);
   SumChiSq( CTRL,Stats, &ratio, &ChiSq, &TargetChiSq, &Cdiff,
                                 &mFlux, &TargetFlux,  &Fdiff, &ConstrainFlux );

   if(Lun==0) { dashfill( "Info", 1 ); Sprintf(MES,"      "); mes = &MES[6]; }
   else {       Sprintf( MES, "Convergence Info for plane %d\n", plane );
                TerHisOut( Lun, MES );                        mes = &MES[0]; }

   Sprintf(mes,"          H  =%10.3g;    J  =%10.3g;  rms of residual =%9.3f\n",
           Stats->H, Stats->J, Stats->rms );
   TerHisOut(Lun,MES);


   if( Lun == 0 ) {
      dashfill( "Control Parameters", 1 );
      dprintf("      delta alpha = %7.3g -> alpha = %7.3g\n",
                     Stats->dLM[LMint], Stats->LM[LMint]+Stats->dLM[LMint]    );
      if( ConstrainFlux )
      dprintf("      delta beta  = %7.3g -> beta  = %7.3g\n",
                     Stats->dLM[LMflx], Stats->LM[LMflx]+Stats->dLM[LMflx] );
   }


   if(Lun==0)   dashfill( "Convergence Criteria", 1 ); Sprintf(MES,"      ");
   if(Lun!=0) { Sprintf(mes,"# of iterations: %d\n", Stats->Iteration );
                TerHisOut(Lun,MES); }


   Sprintf(mes,"NORM:  ||GJ||=%10.3g   ||1||=%10.3g   ratio=%10.3f\n",
           Stats->NormGJ*Stats->Norm1, Stats->Norm1,   ratio );
   TerHisOut(Lun,MES);


   Sprintf(mes,"CHISQ: chi^2 =%10.3g     N  =   %7d   diff= %10.1f%c%c\n",
                       ChiSq, (int)TargetChiSq, Cdiff, '%','%' );
   TerHisOut(Lun,MES);


   if( ConstrainFlux )
   Sprintf(mes,"FLUX:  Flux  =%10.3g  Target=%10.3g   diff= %10.1f%c%c\n",
                       mFlux, TargetFlux, Fdiff, '%','%' );
   else
   Sprintf(mes,"FLUX:  Flux  =%10.3g\n", mFlux );
   TerHisOut(Lun,MES);
}}

/******************************************************************************/
/*
   Print message with sums:

      Sums
          GradJJ     GradXX     GradJX     GradFF     GradJF     GradXF
          .......... .......... .......... .......... .......... ..........
*/
/******************************************************************************/

private void Messages_Sums( CTRL, Stats )
CONTROL *CTRL;
STATS   *Stats;
{if( MessageLevel >= Lev_Sums )
{
   private void dashfill();
   dashfill( "Sums", 1 );
   if( CTRL->TargetFlux > ZERO ) {
     dprintf(
     "       GradJJ     GradXX     GradJX       GradFF     GradJF     GradXF\n"
     );
     dprintf( "   %10.3g %10.3g %10.3g   %10.3g %10.3g %10.3g\n",
     Stats->JJ, Stats->XX[LMint*CTRL->NLM+LMint], Stats->JX[LMint],
                Stats->XX[LMflx*CTRL->NLM+LMflx], Stats->JX[LMflx],
                Stats->XX[LMint*CTRL->NLM+LMint]);
   } else {
     dprintf(
     "       GradJJ     GradXX     GradJX\n" );
     dprintf( "   %10.3g %10.3g %10.3g\n",
     Stats->JJ, Stats->XX[LMint*CTRL->NLM+LMint],  Stats->JX[LMint] );
   }
}}

/******************************************************************************/
/*
   Print message with information, combine several calls.
*/
/******************************************************************************/

void Messages_Step( CTRL, Stats )
CONTROL *CTRL;
STATS   *Stats;
{if( MessageLevel >= Lev_Converge )
{
   private void Messages_Sums();
   private void Messages_Converge_Short();
           void Messages_Converge_Long();
   Messages_Sums( CTRL, Stats );
   if( MessageLevel == Lev_Converge ) Messages_Converge_Short(   CTRL,Stats  );
   if( MessageLevel >= Lev_ConvPar  ) Messages_Converge_Long(  0,CTRL,Stats,0);
}}

/******************************************************************************/
/*
   Print message when step-scaling is done.
*/
/******************************************************************************/

void Messages_Scaling( Scale, Frac, Interpolate )
double  Scale, Frac;
logical Interpolate;
{if( MessageLevel >= Lev_ConvPar )
{
   if( Interpolate ) {
      dprintf( "   Interpolation scales step back by factor %10.3g\n",   Frac );
   } else {
      if( Scale < ONE )
      dprintf( "   Calculated step was scaled back by factor: %10.3g\n", Scale);
   }
}}

/******************************************************************************/
/*
   Print a message with the individual final rms values.
*/
/******************************************************************************/

void Messages_rms( Maps )
ONEMAP *Maps;
{if( MessageLevel >= Lev_ConvPar )
{
   private void dashfill();
   ONEMAP      *MapI;

   dashfill( "", 0 );
   dprintf( "Mean and rms of residuals\n");
   dprintf( "%-26s %9s %9s  %10s\n",
            "Dataset", "   Mean", "    rms", "Wanted rms" );

   for( ALLMAPSI ) {
      Sprintf( MES, "%-26s %9.3f %9.3f %9.3f\n",
               MapI->DirtyMap.name, MapI->DirtyMap.mean,
               MapI->DirtyMap.rms,  sqrt(MapI->DirtyMap.variance) );
      dprintf( MES );
   }

   dashfill( "", 0 );
}}

/******************************************************************************/
/*
   Overview of calculation of Chi^2.
*/
/******************************************************************************/

void Messages_ChiSq( Map, sum, sumsq, MagicQ )
ONEMAP  *Map;
double   sum, sumsq, MagicQ;
{if( MessageLevel >= Lev_ParCheck )
{
   double variance, weight, Q, TwoWQv;
   variance = Map->DirtyMap.variance;
   weight   = Map->DirtyMap.weight;
   Q        = Map->BM.Q * sqrt(MagicQ);
   TwoWQv   = -2. * weight * Q / variance;

   dprintf( "w=%6.3f; 2WQ/v=%8.2f; sum=%8.2f; sumsq=%9.2f; Contr=%9.1f\n",
             weight, -TwoWQv, sum, sumsq, weight*sumsq/variance );
}}

/******************************************************************************/
/*
   Show the change in Lagrange multipliers.
*/
/******************************************************************************/

void Messages_LM( n, dlm, dlm2, Change, mindlm, maxdlm )
int    n, Change;
double dlm, dlm2, mindlm, maxdlm;
{if( MessageLevel >= Lev_ParCheck )
{
   int i;
   for(i=0;i<100;i++) MES[i]=' ';
   if( n>=LMint ) StrCpy( MES, "alpha: " );
   if( n==LMflx ) StrCpy( MES, "beta:  " );
   mes = &MES[0]+strlen(MES);
   switch( Change ) {
   case 0: Sprintf( mes, "ch(0): delta=%10.3e\n", dlm2 );
           break;
   case 1: Sprintf( mes, "ch(1): %10.3e<%10.3e<%10.3e -> %10.3e\n",
                                 mindlm, dlm, maxdlm, dlm2 );
           break;
   case 2: Sprintf( mes, "ch(2): delta=%10.3e -> %10.3e\n", dlm, dlm2 );
           break;
   }
   dprintf( MES );
}}

/******************************************************************************/
/*
   In a nice way write out how alignment calculations are done.
*/
/******************************************************************************/

void Messages_Coords( option,SetCoo,RefCoo,axis, left,right,leftedge,rightedge)
int     option;
COORDS *SetCoo, *RefCoo;
AXIS    axis;
int     left[2], right[2];
double  leftedge[2], rightedge[2];
{if( MessageLevel >= Lev_CooCheck )
{
   void   CoordAt();
   double ConvertToCoord();
   double nearest[2], nearestcoo[2], frac[2];

   double leftcoo[2],  leftedgecoo[2];
   double rightcoo[2], rightedgecoo[2], prcoo[2];

   AXIS   n;

   if( option == 1 && axis==AXIS1 ) {
   for( n=AXIS1; n<=AXIS2; n++ ) {
   nearest[n] =
      (double)nint( (SetCoo->project?SetCoo->prpix[n]:SetCoo->crpix[n]) );
   nearestcoo[n] = ConvertToCoord( nearest[n], SetCoo, n );
   frac[n]       = SetCoo->prpix[n] - nearest[n];
   }
   CoordAt( "crpix  ", SetCoo->crval[RA_AXIS], SetCoo->crpix[RA_AXIS],
                       SetCoo->crval[DC_AXIS], SetCoo->crpix[DC_AXIS] );
   CoordAt( "prpix  ", SetCoo->prval[RA_AXIS], SetCoo->prpix[RA_AXIS],
                       SetCoo->prval[DC_AXIS], SetCoo->prpix[DC_AXIS] );
   CoordAt( "Nearest", nearestcoo[RA_AXIS],    nearest[RA_AXIS],
                       nearestcoo[DC_AXIS],    nearest[DC_AXIS]       );
   CoordAt( "Frac   ", frac[RA_AXIS]*SetCoo->cdelt[RA_AXIS], frac[RA_AXIS],
                       frac[DC_AXIS]*SetCoo->cdelt[DC_AXIS], frac[DC_AXIS] );
   }


   if( option == 2 ) {
      dprintf("Set up mosaic map, taking convolvable part from each input\n");
   }
   if( option == 3 ) {
      for( n=AXIS1; n<=AXIS2; n++ ) {
         leftcoo[n]      = ConvertToCoord( (double)left[n],  SetCoo, n );
         rightcoo[n]     = ConvertToCoord( (double)right[n], SetCoo, n );
         leftedgecoo[n]  = ConvertToCoord( leftedge[n],      RefCoo, n );
         rightedgecoo[n] = ConvertToCoord( rightedge[n],     RefCoo, n );
         prcoo[n]        = ConvertToCoord( RefCoo->prpix[n], RefCoo, n );
      }
      dprintf("Find common frame\n");
      CoordAt( "crpix     ", SetCoo->crval[RA_AXIS], SetCoo->crpix[RA_AXIS],
                             SetCoo->crval[DC_AXIS], SetCoo->crpix[DC_AXIS] );
      CoordAt( "prpix     ", SetCoo->prval[RA_AXIS], SetCoo->prpix[RA_AXIS],
                             SetCoo->prval[DC_AXIS], SetCoo->prpix[DC_AXIS] );
      CoordAt( "left IQ   ", leftcoo[RA_AXIS],       (double)left[RA_AXIS],
                             leftcoo[DC_AXIS],       (double)left[DC_AXIS]  );
      CoordAt( "right IQ  ", rightcoo[RA_AXIS],      (double)right[RA_AXIS],
                             rightcoo[DC_AXIS],      (double)right[DC_AXIS] );
      CoordAt( "left(mos) ", leftedgecoo[RA_AXIS],   leftedge[RA_AXIS],
                             leftedgecoo[DC_AXIS],   leftedge[DC_AXIS]      );
      CoordAt( "right(mos)", rightedgecoo[RA_AXIS],  rightedge[RA_AXIS],
                             rightedgecoo[DC_AXIS],  rightedge[DC_AXIS]     );
      dprintf( "new map size: %d x %d\n", RefCoo->axlen[RA_AXIS],
                                          RefCoo->axlen[DC_AXIS] );
      CoordAt( "prpix->   ", prcoo[RA_AXIS],         RefCoo->prpix[RA_AXIS],
                             prcoo[DC_AXIS],         RefCoo->prpix[DC_AXIS] );
   }
}}

void CoordAt( text, RaCoo, RaPix, DecCoo, DecPix )
char  *text;
double RaCoo, RaPix, DecCoo, DecPix;
{  if( MessageLevel >= Lev_CooCheck )
{
   void radra(), raddec();
   char string[15];
   int  i;
   radra(  RaCoo,  string );
   Sprintf(  MES, "%-8s ra : %11s @ %7.3f", text, string, RaPix );
   raddec( DecCoo, string ); i = strlen(MES);
   Sprintf( &MES[i], "     dec: %11s @ %7.3f",    string, DecPix );
   dprintf( "%s\n", MES );
}}

/******************************************************************************/
/*
   Some messages must be written to standard output, and to the history file.
   Solve this problem via routine TerHisOut.
*/
/******************************************************************************/

private void TerHisOut( Lun, s )
int   Lun;
char *s;
{
   void hiswrite_c();
   char line[OUTSTRLEN];
   if( Lun == 0 ) {
      dprintf( s );
   } else {
      StrCpy( line, "MOSAIC: " ); StrCat( line, s );
      line[ strlen(line)-1 ] = '\0';
      hiswrite_c( Lun, line );
   }
}

/******************************************************************************/
/*
   Fill out the line with '-' from the end of the string to column OUTLINELEN.
*/
/******************************************************************************/

private void dashfill( string, nindent )
char *string;
int   nindent;
{
#define OUTLINELEN 79
   int  len = strlen(string);
   int  i=0, j=0; MES[0]='\0';
   while( j<nindent ) { StrCpy( MES, "   " ); j++; i+=3; }
   if( len != 0 ) Sprintf( &MES[i], "%s ", string );
   for( i=strlen(MES); i<OUTLINELEN; i++ ) MES[i] = '-';
   StrCpy( &MES[i], "\n" );
   dprintf( MES );
#undef OUTLINELEN
}

/*

/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*    <<< Overview >>>                                  40 +   13 =   53 USERIO
/******************************************************************************/
/*
   Give the user all kinds of information concerning the input data.
*/
/******************************************************************************/

void Overview( MosMap, Maps, Flags, CTRL )
MOSMAP  *MosMap;
ONEMAP  *Maps;
logical  Flags[];
CONTROL *CTRL;
{
   private void  Messages_Memory();
   private void  Messages_DataSet();
   private void  Messages_PB();
           void  Messages_BM();
   private void  Messages_Region();
           void  Messages_Where();
   private void  Messages_CTRL();
   ONEMAP       *MapI;

   TRACE("Overview");

   Messages_Memory( MosMap, Maps, Flags );
   for( ALLMAPSI ) {

      Messages_DataSet( &MapI->Observation   );

      Messages_PB(      &MapI->PB            );

      if( Flags[READBEAMS] && MapI->IsIFmap ) {
         Messages_DataSet( &MapI->SynthBeam     );
         if(MessageLevel>=Lev_Init)
         Messages_BM( "   Synthesized beam ", &MapI->BM );
      }

      Messages_Region(  &MapI->Region        );

   }
   if( Flags[PBC] ) return;


                        Messages_DataSet( &MosMap->MosaicMap );
   if( Flags[READREF] ) Messages_DataSet( &MosMap->Reference );
   if( Flags[READINI] ) Messages_DataSet( &MosMap->Initial   );

   if( Maps->NextMap!=NULL) Messages_Where( 0, MosMap, Maps );

   Messages_CTRL( Flags, CTRL, Maps );
}
