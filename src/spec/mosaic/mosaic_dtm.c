/*----------------------------------------------------------------------------
-- mosaic_dtm.c --
/*----------------------------------------------------------------------------*/
#include "mosaic_def.h"
/*----------------------------------------------------------------------------*/

/******************************************************************************/
/*    <<< DTM >>>                                      365 +  121 =  486 DTM
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*
   Shell around DTM for use in miriad-like programs.

   Programmer sees these routines:

   DTMsetup        set up connection

   LocallyRun      TRUE if program is run locally
   DTMmaster       TRUE on master (or run locally), FALSE on slave

   DTMsendSignal   pushes a button remotely
   DTMgotoSignal   pushes a button locally
   DTMreceive      receives message containing variables; does preliminary check

   DTMm2s          port selection to send from master to slave
   DTMs2m          port selection to send from slave to master

   DTMrclass       returns TRUE if the received message is of a certain class
   DTMexchange     encode or decode variables of given class according to format

   DTMputdata      send a dataset
   DTMgetdata      receive a dataset
   DTMexchArray    send/receive a float array

   DTMprint        print a message, sending it accross using DTM
   DTM_IDCHAR      '>', 'M' or 'S', depending on machine

   Programmer needs to adapt DTMremoteExec to catch all signals that the
   remote machine may send back.
*/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*
   DTMIO is set to TRUE if the DTM library is actually to be included. Generally
   this is the case, but sometimes a machine may not have it, or it may be
   disabled for test purposes.

   Standard, include the dtm.h file to allow working with DTM. However, if it
   is not included, define dummy DTM routines.
*/
/******************************************************************************/

#ifdef DTMIO

#include <dtm.h>

#else
#define DTM_DEFAULT 0
#define DTM_ASYNC   1
#define DTMERROR 0
#define DTM_MAX_HEADER 1024
#define DTM_CHAR 0
#define DTM_FLOAT 4
#define DTM_INT 4
#define DTM_WAIT_TIMEOUT 0
int  DTMmakeInPort( a,v)       char *a; int v; {;}
int  DTMmakeOutPort(a,v)       char *a; int v; {;}
void DTMgetPortAddr(p,a,l)     int p; char *a; int l; {;}
void DTMgetAddress(m,a,l)      char *m; char *a; int l; {;}
void DTMsetAddress(m,a)        char *m; char *a; {;}
void DTMsetClass(m)            char *m; {;}
int  DTMbeginRead(p,m,l)       int p; char *m; int l; {;}
void DTMendRead(p)             int p; {;}
int  DTMreadMsg( p,m,l,d,n,dc) int p; char *m; int l, d, n, dc; {;}
int  DTMwriteMsg(p,m,l,d,n,dc) int p; char *m; int l, d, n, dc; {;}
#endif

/******************************************************************************/
/*
  Global variable definitions
*/
/******************************************************************************/

private logical LOCALLY_RUN     = TRUE;
private logical ThisIsDTMmaster = TRUE;
logical LocallyRun() { return( LOCALLY_RUN     ); }
logical DTMmaster()  { return( ThisIsDTMmaster ); }

private int DTM_INPORT=-1, DTM_OUTPORT=-1;
int DTMgetport(flag) char flag;
{  int port;
   switch(flag) { case 'i': port = DTM_INPORT;  break;
                  case 'o': port = DTM_OUTPORT; break; }
   return( port );
}
int DTMm2s() { return( ThisIsDTMmaster ? DTM_OUTPORT : DTM_INPORT  ); }
int DTMs2m() { return( ThisIsDTMmaster ? DTM_INPORT  : DTM_OUTPORT ); }

#define ADDRLEN 64
private char host[ADDRLEN];
private char DTMmessage[DTM_MAX_HEADER];
void DBGDTM();

/******************************************************************************/
/*
   DTMsetup first checks which remote machine the user wants to run this on:
   keyword remote=. If the answer is "local", run locally. If the answer is
   some sort of host name: split the program in two:

   Master                                 Slave
   Read MASTER->default
   makeInPort, get its a
   rsh host mosaic input address
                                          does not get remote=
                                          reads MASTER=inputaddress
                                          creates OutPort to inputaddress
                                          makeInPort, get its address
                                          Send InPort through OutPort to master
   receive address of slave's InPort
   (if timed out: run locally)
   create OutPort to this address
*/
/******************************************************************************/

void DTMsetup( program, version, MesLev )
char *program, *version;
int   MesLev;
{
   void         keya_c(), keyl_c();
   private void DTMmasterPORTS(), DTMslavePORTS();
   private void SetMSGchar();
   char         masteraddress[ADDRLEN], slaveaddress[ADDRLEN];
   logical      hippi;
   TRACE("DTMsetup");

   keya_c( "MASTER", masteraddress, "EMPTY_IF_ON_MASTER" );
#ifdef DTM_2CONN
   keyl_c( "hippi", &hippi, FALSE );
#define DTM_HIPPICONN DTM_ASYNC | DTM_2CONN
#else
#define DTM_HIPPICONN DTM_ASYNC
   hippi = FALSE;
#endif

   if( StrEqX( masteraddress, "EMPTY_IF_ON_MASTER" ) ) {      /* -> master */

      dprintf( "%s version %s\n", program, version );

      keya_c( "remote", host, "local" );
      if( StrEqX( host, "local") )  {
        LOCALLY_RUN     = TRUE;
        ThisIsDTMmaster = TRUE;
      } else {
        LOCALLY_RUN     = FALSE;
        ThisIsDTMmaster = TRUE;
        DTMmasterPORTS(program,version,masteraddress,slaveaddress,hippi,MesLev);
      }

   } else {                                                    /* -> slave */

      LOCALLY_RUN     = FALSE;
      ThisIsDTMmaster = FALSE;
      DTMslavePORTS( version, masteraddress,slaveaddress,hippi );
   }


   SetMSGchar();
   if( !LOCALLY_RUN ) {
      DBGVAL( "master address: %s\n", masteraddress );
      DBGVAL( "slave  address: %s\n", slaveaddress );
      DBGVAL( "Hippi connection? - %s\n", hippi?"yes":"no" );
   }
}

private void DTMmasterPORTS( program,version,
                             masteraddress,slaveaddress,hippi,
                             MesLev )
char    *program, *version;
char    *masteraddress, *slaveaddress;
logical  hippi;
int      MesLev;
{
   void            keyi_c();
   private void    DTM_err();
   private logical CheckVersion(), OK;
   void            DTMsendSignal();
   private int     DTMmakeINPORT(), DTMmakeOUTPORT();
   char            command[128];
   FILE           *runfile;
   int             remotedbg;

   DBGVAL( "Run rsh on %s\n", host );

/* Create input port, and get local address */
   DTM_INPORT = DTMmakeINPORT( masteraddress );

/* Start program remotely */
   keyi_c( "remotedbg", &remotedbg, 0 );
   switch( remotedbg ) {
   case 0: Sprintf( command, "rsh -n %s %s meslev=%d hippi=%c MASTER=%s &",
                    host, program, MesLev, hippi?'t':'f', masteraddress );
           system(  command );
           DBGVAL( "%s\n", command );
           break;
   case 1: runfile = fopen( ".runmosaic", "w+" );
           Fprintf( runfile, "%s meslev=%d hippi=%c MASTER=%s",
                    program, MesLev, hippi?'t':'f', masteraddress );
           (void)fclose(  runfile );
           Sprintf( command, "rcp .run%s %s:", program, host );
           system(  command );
           DBGVAL( "%s\n", command );
           break;
   case 2: Fprintf( stderr, "%s meslev=%d hippi=%c MASTER=%s\n",
                    program, MesLev, hippi?'t':'f', masteraddress );
           break;
   }

/* Read back remote address and program version */
   if( DTMbeginRead( DTM_INPORT, DTMmessage, DTM_MAX_HEADER ) == DTMERROR ) {
      LOCALLY_RUN = TRUE;
      wwarning( TRUE, "Cannot make connection, running locally after all" );
   } else {
      DTMendRead( DTM_INPORT );
      DTMgetAddress( DTMmessage, slaveaddress, ADDRLEN );
      OK = CheckVersion( version );

      DTM_OUTPORT = DTMmakeOUTPORT( slaveaddress, hippi );

      if( !OK ) { DTMsendSignal("ABORT");
                  DTM_err("Remote machine has different version"); }

   }
}

private logical CheckVersion( version )
char   *version;
{
   char    *c;
   logical  OK;
   c = strstr(DTMmessage,"/");
   if( c!=NULL && StrEq(c+1,version) ) { OK=TRUE;*c='\0'; } else OK=FALSE;
   return( OK );
}

private void DTMslavePORTS( version, masteraddress, slaveaddress, hippi )
char    *version;
char    *masteraddress, *slaveaddress;
logical  hippi;
{
   private int DTMmakeINPORT(), DTMmakeOUTPORT();

   DBGVAL( "Slave of %s\n", masteraddress );
   DTM_OUTPORT = DTMmakeOUTPORT( masteraddress, hippi );
   DTM_INPORT  = DTMmakeINPORT(  slaveaddress );

/* Send address and version to master */
   DTMsetClass(   DTMmessage );
   DTMsetAddress( DTMmessage, slaveaddress );
   StrCat(        DTMmessage, "/" ); StrCat( DTMmessage, version );
   DTMwriteMsg( DTM_OUTPORT, DTMmessage, DTM_MAX_HEADER, 0,0, DTM_CHAR );
}


private int DTMmakeINPORT( address )
char *address;
{
   int          port;
   private void DTMcheckPortCreate();
   port = DTMmakeInPort( ":0", DTM_ASYNC );
   DTMcheckPortCreate( port, "input" );
   DTMgetPortAddr( port, address, ADDRLEN );
   return( port );
}
private int DTMmakeOUTPORT( address, hippi )
char    *address;
logical  hippi;
{
   int          port;
   private void DTMcheckPortCreate();
   port = DTMmakeOutPort( address, hippi ? DTM_HIPPICONN : DTM_ASYNC );
   DTMcheckPortCreate( port, "outport" );
   return( port );
}
private void DTMcheckPortCreate( port, string )
int   port;
char *string;
{
   private void DTM_err();
   Sprintf( DTMmessage, "Failed to create %s port", string );
   if( port==DTMERROR ) DTM_err( DTMmessage );
   Sprintf( DTMmessage, "Create %s port %d\n%%s", string, port );
   DBGVAL(  DTMmessage, "\0" );
}

/*

/******************************************************************************/
/*
   The routines the programmer sees while interacting with DTM.
*/
/******************************************************************************/

private logical LocalSet=FALSE;

void DTMsendSignal( Signal ) char *Signal;
{  private void DTMsendVars();
   LocalSet=FALSE;
   Sprintf( DTMmessage, "%s ", Signal );
   DTMsendVars( "++ Send signal %s\n" );
}

void DTMgotoSignal( Signal )
char *Signal;
{  private void DTMsendVars();
   LocalSet=TRUE;
   Sprintf(DTMmessage,"%s ",Signal);
   if(StrEq(Signal,"READY")) DTMsendVars( "++ Send signal %s\n" );
}
private void DTMsendVars(string)
char *string;
{
   void Pause(), AbortIt(), DTM_err();
   void Timer_Cont(), Timer_Stop();
   if( LOCALLY_RUN ) return;

   DBGDTM( string, DTMmessage ); Pause("send message");
   Timer_Cont("DTM_WRITE");
   if( DTMwriteMsg( DTM_OUTPORT, DTMmessage,strlen(DTMmessage)+1, 0,0,DTM_CHAR )
       == DTMERROR ) {
       if( StrEq(DTMmessage,"ABORT") ) AbortIt();
       else DTM_err("Failure sending message");
   }
   Timer_Stop("DTM_WRITE");
}

logical DTMreceive()
{
   void Timer_Cont(), Timer_Stop();
   void AbortIt(), DTM_err(), MESSAGE();
   void settimer(); int elapsed();
   char rClass[40];

   if( !LocalSet ) {
   if( !LOCALLY_RUN ) {
      DBGDTM( "++ DTM receiving\n", "\0" );
      settimer();
      Timer_Cont("DTM_READ");
      if( DTMreadMsg( DTM_INPORT, DTMmessage, DTM_MAX_HEADER, 0,0,DTM_CHAR )
          == DTMERROR ) {
          if(elapsed()>=DTM_WAIT_TIMEOUT)DTM_err("Timed out");
          else                           DTM_err("Failure receiving message");}
      Timer_Stop("DTM_READ");
   }
   }
   if(!LocalSet) DBGDTM( "++ DTMread:  %s\n", DTMmessage );
   else          DBGDTM( "++ DTMgoto:  %s\n", DTMmessage );

   (void)sscanf( DTMmessage, "%s ", rClass );
   if(     StrEq(rClass,"READY")  ){LocalSet=FALSE;          return FALSE; }
   else if(StrEq(rClass,"MESSAGE")){MESSAGE(&DTMmessage[8]); return TRUE;  }
   else if(StrEq(rClass,"WAIT")   ){LocalSet=FALSE;          return TRUE;  }
   else if(StrEq(rClass,"ABORT")  ){AbortIt();                             }
   return TRUE;
}

logical DTMrclass( Class )
char *Class;
{
   char rClass[40];
   (void)sscanf( DTMmessage, "%s ", rClass );
   return( StrEq( rClass, Class ) );
}

/******************************************************************************/
/*
   Messages and errors generated via DTM.
*/
/******************************************************************************/

private int DTM_IDchar = '?';
char DTM_IDCHAR() { return( DTM_IDchar ); }

private void SetMSGchar()
{
   logical      DTMmaster(), DTMreceive();
   private void DTMsendVars();

   if(  LOCALLY_RUN                    ) DTM_IDchar = '>';
   if( !LOCALLY_RUN &  ThisIsDTMmaster ) DTM_IDchar = 'M';
   if( !LOCALLY_RUN & !ThisIsDTMmaster ) DTM_IDchar = 'S';

   if(DTMmaster()){StrCpy(DTMmessage,host);DTMsendVars("++ remote host %s\n"); }
   else           { (void)DTMreceive(); StrCpy(host,DTMmessage); }
}

void DTMprint( stream, message ) FILE *stream; char *message;
{  private void DTMsendVars();
   if( ThisIsDTMmaster ) {
      Fprintf( stream, message );
   } else {
      Sprintf( DTMmessage, "MESSAGE %s", message );
      DTMsendVars( "++ DTMprint %s" );
   }
}

private void DTM_err(message) char *message;
{ void AbortIt();
  if( DTM_IDchar == 'S' ) Fprintf( stderr,"%s: ", host );
  Fprintf(stderr,message);
  Fprintf(stderr,"\n");
  AbortIt();
}

/******************************************************************************/
/*
   Transfer of arrays, making some assumptions.
*/
/******************************************************************************/

void DTMgetData( Port, flag, Data, Mask, size )
int     Port;
logical flag;
float  *Data;
int    *Mask;
int     size;
{
   private void DTM_err();
   char Head[5]; StrCpy(Head,"DATA");
   if( DTMreadMsg( Port, Head,5, Data,size, DTM_FLOAT ) == DTMERROR )
       DTM_err("Failure receiving data");
   if( flag ) {
   if( DTMreadMsg( Port, Head,5, Mask,size, DTM_INT   ) == DTMERROR )
       DTM_err("Failure receiving mask"); }
}

void DTMputData( Port, flag, Data, Mask, size )
int     Port;
logical flag;
float  *Data;
int    *Mask;
int     size;
{
   private void DTM_err();
   char Head[5]; StrCpy(Head,"DATA");
   if( DTMwriteMsg( Port, Head,5, Data,size, DTM_FLOAT ) == DTMERROR )
       DTM_err("Failure sending data");
   if( flag ) {
   if( DTMwriteMsg( Port, Head,5, Mask,size, DTM_INT   ) == DTMERROR )
       DTM_err("Failure sending mask"); }
}

private int    exchArray_alloc=0;
private float *exchArray;
void DTMexchArray( Port, Array, len )
int     Port;
double *Array;
int     len;
{
   logical      DTMm2s();
   private void DTM_err();
   int          n;
   char         Head[5]; StrCpy(Head,"DATA");

   if( LOCALLY_RUN ) return;

   if( exchArray_alloc < len ) { Malloc( exchArray, float, len );
                                 exchArray_alloc = len; }

   if(  ThisIsDTMmaster && Port==DTMm2s() ||
       !ThisIsDTMmaster && Port==DTMs2m()    ) {
      for(n=0;n<len;n++) *(exchArray+n) = *(Array+n);
      if( DTMwriteMsg(DTM_OUTPORT,Head,5,exchArray,len,DTM_FLOAT) == DTMERROR )
          DTM_err("Failure sending data");
   }
   if(  ThisIsDTMmaster && Port==DTMs2m() ||
       !ThisIsDTMmaster && Port==DTMm2s()    ) {
      if( DTMreadMsg( DTM_INPORT, Head,5,exchArray,len,DTM_FLOAT) == DTMERROR )
          DTM_err("Failure receiving data");
      for(n=0;n<len;n++) *(Array+n) = *(exchArray+n);
   }
}

/******************************************************************************/
/*
   DTMexchange is a which prepares a message for DTM to send.
   It takes several arguments:
   - mode          READ or WRITE
   - Class         a string that is used to identify the type of message send or
                   received
   - VarTypes      a string consisting of one character for each following
                   variable; the string indicates the types of the variables
                   to exchange:
                   l for logical
                   i for int
                   f for float
                   d for double
                   c for char
                   s for char*
                   S for unallocated char*
   - arguments     there should be as many arguments as there are characters in
                   the VarTypes variable, with a one-to-one type correspondence
*/
/******************************************************************************/

/* void DTMexchange( Port, Class, VarTypes, args ) */
void va_FUNC( DTMexchange, int, Port )
{
   char *Class;
   char *VarTypes;

   logical      DBGDTMDCD();
   private void DTMstrErr(), DTMstrMess();
   private void DTMsendVars();

   char     fmt[10];
   char    *DTMmsg;
   logical *pL; int *pI; float *pF; double *pD; char *pC; char *pS; char **PS;
   int      n, l, tl;
   va_list  args;
   va_START( args, int, Port );

   if( !LOCALLY_RUN ) {

   Class    = va_arg( args, char* );
   VarTypes = va_arg( args, char* );

   DTMmsg = &DTMmessage[0];
   if( Port==DTM_OUTPORT ) { Sprintf(DTMmsg,"%s ",Class); }
   l = strlen(Class)+1; DTMmsg += l; tl = l;

   fmt[0]='%';
   while( *VarTypes ) {
      switch( *VarTypes ) {
      case 'l': StrCpy( &fmt[1], "1d "  ); l= 2; break;
      case 'i': StrCpy( &fmt[1], "9d "  ); l=10; break;
      case 'f': StrCpy( &fmt[1], "15e " ); l=16; break;
      case 'd': StrCpy( &fmt[1], "15e " ); l=16; break;
      case 'c': StrCpy( &fmt[1], "c "   ); l= 2; break;
      case 's': StrCpy( &fmt[1], "s "   ); l= 0; break;
      case 'S': StrCpy( &fmt[1], "s "   ); l= 0; break; }
      if( Port == DTM_OUTPORT ) {
         switch( *VarTypes ) {
         case 'l': pL=va_arg(args,logical *); Sprintf(DTMmsg,fmt,*pL); break;
         case 'i': pI=va_arg(args,int     *); Sprintf(DTMmsg,fmt,*pI); break;
         case 'f': pF=va_arg(args,float   *); Sprintf(DTMmsg,fmt,*pF); break;
         case 'd': pD=va_arg(args,double  *); Sprintf(DTMmsg,fmt,*pD); break;
         case 'c': pC=va_arg(args,char    *); Sprintf(DTMmsg,fmt,*pC); break;
         case 's': pS=va_arg(args,char    *); Sprintf(DTMmsg,fmt, pS); break;
         case 'S': PS=va_arg(args,char   **); Sprintf(DTMmsg,fmt,*PS); break;
         }
      } else {
         if(!*DTMmsg) DTMstrErr( "Too few variables sent", Class );
         switch( *VarTypes ) {
         case 'l': pL=va_arg(args,logical *); n=sscanf(DTMmsg,fmt, pL); break;
         case 'i': pI=va_arg(args,int     *); n=sscanf(DTMmsg,fmt, pI); break;
         case 'f': pF=va_arg(args,float   *); n=sscanf(DTMmsg,fmt, pF); break;
         case 'd': pD=va_arg(args,double  *);
                   pF=(float *)pD;            n=sscanf(DTMmsg,fmt, pF);
                   *pD = *pF;                                           break;
         case 'c': pC=va_arg(args,char    *); n=sscanf(DTMmsg,fmt, pC); break;
         case 's': pS=va_arg(args,char    *); n=sscanf(DTMmsg,fmt, pS); break;
         case 'S': PS=va_arg(args,char   **);
                   l=0; while(*(DTMmsg+l)!=' '&&*(DTMmsg+l)) l++;
                   Calloc(*PS,l+2);           n=sscanf(DTMmsg,fmt,*PS); break;
         }
         if(DBGDTMDCD()) DTMstrMess(VarTypes, pL,pI,pF,pD,pC,pS,PS, DTMmsg );
         if( n!=1 ) DTMstrErr( "DTM: Failed to receive information", Class );
      }
      l = *VarTypes=='s' ? strlen(pS)+1 : (*VarTypes=='S' ? strlen(*PS)+1 : l);
      tl += l;
      if( tl >= DTM_MAX_HEADER ) DTMstrErr( "Trying to send too much", Class );
      DTMmsg += l; VarTypes++;
   }

   }
   va_end( args );
   if( Port==DTM_OUTPORT ) DTMsendVars( "++ DTMwrite: %s\n" );
}

private void DTMstrErr( Mess, Class ) char *Mess, *Class;
{ private void DTM_err();
  Sprintf( DTMmessage, "%s; class=%s\n", Mess, Class ); DTM_err(DTMmessage);
}

private void DTMstrMess( mode, pL, pI, pF, pD, pC, pS, PS, DTMmsg )
char    *mode;
logical *pL; int *pI; float *pF; double *pD; char *pC; char *pS; char **PS;
char    *DTMmsg;
{
   int  zc=45;
   char c;
   c = *(DTMmsg+zc); *(DTMmsg+zc)='\0';
   dprintf( "------------------------------------------------\n");
   dprintf( "decode type :%s: from :%s: --> ", mode, DTMmsg );
   switch( *mode ) {
   case 'l':           dprintf( "%c", *pL ? 'T' : 'F' ); break;
   case 'i': case 'p': dprintf( "%d", *pI );             break;
   case 'f':           dprintf( "%f", *pF );             break;
   case 'd':           dprintf( "%f", *pD );             break;
   case 'c':           dprintf( "%c", *pC );             break;
   case 's':           dprintf( "%s",  pS );             break;
   case 'S':           dprintf( "%s", *PS );             break;
   }
   dprintf( "\n" );
   *(DTMmsg+zc)=c;
}
