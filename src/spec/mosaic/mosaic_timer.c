/*----------------------------------------------------------------------------
-- mosaic_timer.c --
/*----------------------------------------------------------------------------*/

/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*    <<< Timer functions >>>                           79 +   37 =  116 USERIO
/******************************************************************************/
/*
   Timer functions
   (all have alternative version, ending in 'N')

   Timer_Reset    - sets values to 0
   Timer_Start    - mark the time (MAXTIMERS marks possible)
   Timer_Stop     - stop the timer
   Timer_Return   - return the current value
   Timer_Increase - add timings of remote timer to those of local timer
   Timer_Print    - print current value
   Timer_List     - user output, giving current value, without stopping timer

   settimer      - sets a single simple timer
   elapsed       - time elapsed since call to settimer
   date          - date as YYMMMDD:HH:MM:SS.S

   array timings stores the times:
   element [N][i][MEASURE]   stores the time of the call
   element [N][i][STARTT]    stores the time of the previous call
   element [N][i][CUMULT]    is the cumulative elapsed time
   element [N][i][CUMULT_SV] is the cumulative elapsed time at last print

   In routine MeasureTime first get user and system time in tms struct pt.
   For SYV times returns the time since a point in the past, in clock ticks.
   This is converted to seconds.
   Elsewhere, times returns an error code, and an extra call to ftime and a
   conversion are needed to get the elapsed time in seconds
*/
/******************************************************************************/

#if defined(sun) || defined(mips)
#define private static
#else
#define private
#endif

#include <string.h>

#include <time.h>

#include <sys/types.h>
#include <sys/times.h>
#include <limits.h>

#ifdef SYSV
#define CLKUNIT (double)CLK_TCK
clock_t times();
#else
#define CLKUNIT 60.
#include <sys/timeb.h>
struct timeb tp;
#endif


#define MAXTIMERS 50

#define ELAPS 0
#define USER  1
#define SYSTM 2

#define MEASURE    0
#define STARTT     1
#define CUMUL      2

private double timings[MAXTIMERS][3][3];


private char timerstrings[MAXTIMERS][20];
private int  Ntimerstrings = 0;

private int TimerString(string)
char *string;
{
   int n=0;
   while( n<Ntimerstrings ) {
      if( !memcmp( string, timerstrings[n], strlen(string) ) ) return( n );
      n++;
   }
   (void)strcpy( timerstrings[Ntimerstrings], string );
   Ntimerstrings++;
   return( Ntimerstrings-1 );
}



private int TIMERINITIALIZED = 0;

private void MeasureTime(n)
int n;
{
  void   Timer_ResetN();
  int    i;
  struct tms pt;

  if( !TIMERINITIALIZED ) {
      for( i=0; i<MAXTIMERS; i++ ) Timer_ResetN(i);
      TIMERINITIALIZED=1;
   }

#ifdef SYSV
   timings[n][ELAPS][MEASURE] = (double)times(&pt) / CLKUNIT;
#else
   timings[n][ELAPS][MEASURE] = (double)times(&pt); ftime(&tp);
   timings[n][ELAPS][MEASURE] = (tp.time+(double)(tp.millitm)/1000.);
#endif
   timings[n][USER ][MEASURE] = (double)pt.tms_utime / CLKUNIT;
   timings[n][SYSTM][MEASURE] = (double)pt.tms_stime / CLKUNIT;
}


void Timer_ResetN(N) int N;
{  timings[N][ELAPS][CUMUL] = 0.;
   timings[N][USER ][CUMUL] = 0.;
   timings[N][SYSTM][CUMUL] = 0.;
}
void Timer_Reset(string) char *string; { Timer_ResetN( TimerString(string) ); }


void Timer_ContN(N) int N;
{  MeasureTime(N);
   timings[N][ELAPS][STARTT] = timings[N][ELAPS][MEASURE];
   timings[N][USER ][STARTT] = timings[N][USER ][MEASURE];
   timings[N][SYSTM][STARTT] = timings[N][SYSTM][MEASURE];
}
void Timer_Cont(string) char *string; { Timer_ContN( TimerString(string) ); }


void Timer_StartN(N) int N; { Timer_ResetN(N); Timer_ContN(N); }
void Timer_Start(string) char *string; { Timer_StartN( TimerString(string) ); }


void Timer_StopN(N) int N;
{  MeasureTime(N);
   timings[N][ELAPS][CUMUL] +=
                         timings[N][ELAPS][MEASURE] - timings[N][ELAPS][STARTT];
   timings[N][USER ][CUMUL] +=
                         timings[N][USER ][MEASURE] - timings[N][USER ][STARTT];
   timings[N][SYSTM][CUMUL] +=
                         timings[N][SYSTM][MEASURE] - timings[N][SYSTM][STARTT];
}
void Timer_Stop(string) char *string; { Timer_StopN( TimerString(string) ); }


void Timer_ReturnN(N,Times) int N; double Times[3];
{  Times[ELAPS] = timings[N][ELAPS][CUMUL];
   Times[USER ] = timings[N][USER ][CUMUL];
   Times[SYSTM] = timings[N][SYSTM][CUMUL];
}
void Timer_Return(string,Times) char *string; double Times[3];
{ Timer_ReturnN( TimerString(string), Times ); }


void Timer_IncreaseN(N,Times) int N; double Times[3];
{  timings[N][ELAPS][CUMUL] += Times[0];
   timings[N][USER ][CUMUL] += Times[1];
   timings[N][SYSTM][CUMUL] += Times[2];
}
void Timer_Increase(string,Times) char *string; double Times[3];
{ Timer_IncreaseN( TimerString(string), Times ); }


void Timer_Change(timer1,sign,timer2) char *timer1, *sign, *timer2;
{  double Times[3];
   Timer_Return(timer2,Times);
   if(*sign =='-'){ Times[0]=-Times[0]; Times[1]=-Times[1]; Times[2]=-Times[2];}
   Timer_Increase(timer1,Times);
}



private char *fillerspaces = "                                   ";
private int   LIST;
int           TimerLevel();

void Timer_PrintN( N, mess ) int N; char *mess;
{if( TimerLevel(0) )
{  void dprintf();
   char message[35];

   if( LIST ) MeasureTime(N);

   (void)strncpy(message,mess,34); if((int)strlen(mess)>=34) message[34]='\0';
   dprintf( "%s:%s Elapsed %5.2fs; User %5.2fs; System %5.2fs\n",
            message, &fillerspaces[strlen(message)],
            LIST ? timings[N][ELAPS][CUMUL] + timings[N][ELAPS][MEASURE]
                                            - timings[N][ELAPS][STARTT]
                 : timings[N][ELAPS][CUMUL],
            LIST ? timings[N][USER ][CUMUL] + timings[N][USER ][MEASURE]
                                            - timings[N][USER ][STARTT]
                 : timings[N][USER ][CUMUL],
            LIST ? timings[N][SYSTM][CUMUL] + timings[N][SYSTM][MEASURE]
                                            - timings[N][SYSTM][STARTT]
                 : timings[N][SYSTM][CUMUL]
          );
}}
void Timer_Print( string, mess ) char *string; char *mess;
{if(TimerLevel(0)){         Timer_PrintN(TimerString(string), mess );         }}
void Timer_ListN(      N, mess ) int        N; char *mess;
{if(TimerLevel(1)){ LIST=1; Timer_PrintN(                 N,  mess ); LIST=0; }}
void Timer_List(  string, mess ) char *string; char *mess;
{if(TimerLevel(1)){ LIST=1; Timer_PrintN(TimerString(string), mess ); LIST=0; }}


private time_t t_timer[2];
void settimer() { (void)time(&t_timer[0]); }
int  elapsed()  { (void)time(&t_timer[1]); return( t_timer[1]-t_timer[0] ); }

void date(string) char *string;
{
   time_t thetime;
   (void)time( &thetime );
   (void)strftime( string, 20, "%y%b%d:%H:%M:%S", localtime(&thetime) );
   *(string+3) += 'A'-'a'; *(string+4) += 'A'-'a';
}
