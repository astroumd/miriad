/*----------------------------------------------------------------------------
-- mosaic_io.c --
/*----------------------------------------------------------------------------*/
#include "mosaic_stc.h"
/*----------------------------------------------------------------------------*/

/******************************************************************************/
/* <<< IO ROUTINES >>>                                1172 +  548 = 1720 DISKIO
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*
   Opening, Closing, Header IO, Disk IO
*/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*    <<< Library routines >>                           53 +   27 =   80 DISKIO
/******************************************************************************/
/*
   Different versions of the xyzio/header IO may be used:

      XYZIO or XYIO   decide between using xyzio of xyio
      LINEIO/PLANEIO  select IO method: line by line or plane by plane
      DODISKIO        TRUE -> this machine can access the miriad IO routines

   Depending on whether XYIO or XYZIO is defined, a different open, close and
   read/write routines are called.

   If DODISKIO is defined, the machine this is compiled on can access the miriad
   IO routines. If it is undefined, only DTM IO is possible, and dummy IO
   routines (as in xyzio.c and headio.c) are declared to fool the linker. They
   are never called. Bug replacement routines are also defined.

   Data are to be read in line by line, so LINEIO is set true. If there is
   sufficient memory, it may sometimes help to set PLANEIO true instead.
*/
/******************************************************************************/

#define XYIO
#define LINEIO

#ifdef XYZIO
#define XYZopen(l,N,S,n,A)  xyzopen_c(l,N,S,&n,A)
#define getnaxis(l,n)
#define XYZclose            xyzclose_c
#define XYZprfrd(l,p,D,M,L) xyzprfrd_c(l,p,D,M,L)
#define XYZprfwr(l,p,D,M,L) xyzprfwr_c(l,p,D,M,L)
void xyzmkbuf_c(), xyzopen_c(), xyzclose_c();
void xyzsetup_c(), xyzprfrd_c(), xyzprfwr_c(), xyzplnrd_c(), xyzplnwr_c();
#endif
#ifdef XYIO
#define XYZopen(l,N,S,n,A)  xyopen_c(l,N,S,n,A)
#define getnaxis(l,n)       rdhdi_c(l,"naxis",(int *)&n,MAXNAX)
#define XYZclose            xyclose_c
#define XYZprfrd(l,p,D,M,L) xyread_c(l,p,D); xyflgrd_c(l,p,M)
#define XYZprfwr(l,p,D,M,L) xywrite_c(l,p,D); xyflgwr_c(l,p,M)
void xyopen_c(), xyclose_c(), xymkopen_c();
void xysetpl_c(), xyread_c(), xywrite_c(), xyflgrd_c(), xyflgwr_c();
#endif

#ifndef DODISKIO      /* if defined: use actual routines */
                      /* if not defined: use these dummies */

void XYZopen(t,n,s,N,a) int *t; char *n, *s; int *N, a[]; {;}
void XYZclose(t) int t; {;}
#ifdef XYZIO
void xyzmkbuf_c() {;}
void xyzsetup_c(t,s,B,T,va,vc) int t; char *s; int B[], T[], va[], vc[]; {;}
void xyzprfrd_c(t,p,d,m,n) int t, p, *n; float *d; int *m; {;}
void xyzprfwr_c(t,p,d,m,n) int t, p, *n; float *d; int *m; {;}
void xyzplnrd_c(t,p,d,m,n) int t, p, *n; float *d; int *m; {;}
void xyzplnwr_c(t,p,d,m,n) int t, p, *n; float *d; int *m; {;}
#else
void xysetpl_c(t,n,c) int t, n, *c; {;}
void xyread_c( t,p,d) int t, p; float *d; {;}
void xywrite_c(t,p,d) int t, p; float *d; {;}
void xyflgrd_c(t,p,m) int t, p; int   *m; {;}
void xyflgwr_c(t,p,m) int t, p; int   *m; {;}
#endif

void rdhda_c(t,k,v,d,l)  int t,l; char *k; char   *v,*d; {;}
void wrhda_c(t,k,v)      int t;   char *k; char   *v;    {;}
void rdhdd_c(t,k,v,d)    int t;   char *k; double *v,*d; {;}
void wrhdd_c(t,k,v)      int t;   char *k; double *v;    {;}
void rdhdi_c(t,k,v,d)    int t;   char *k; int    *v,*d; {;}
void wrhdi_c(t,k,v)      int t;   char *k; int    *v;    {;}
void hdcopy_c(ti,to,k)   int ti,to; char *k; {;}

void hisopen_c(t,s)      int t; char *s; {;}
void hisclose_c(t)       int t; {;}
void hiswrite_c(t,ln)    int t; char *ln; {;}
/*
logical hexists_c(t,p)   int t; char *p; {;}
void bug_c(s,m)   char s; char* m;{ assert(FALSE,m); }
void bugno_c(s,n) char s; int   n;
{ if(n==-1) assert(FALSE,"End of file detected");
  else      assert(FALSE,"Error #%d",n); }
*/

#endif /* DODISKIO */

/*

/******************************************************************************/
/*    <<< Open / close / setup >>                      146 +   67 =  213 DISKIO
/******************************************************************************/
/*
   The program itself sees some simple routines that take variables of type
   DATASET as input. These are here converted to actual miriad i/o calls.

   - Open_OldDataSet(Set)              Open datasets; sorting axes so that they
     Open_NewDataSet(Set,HeadSet)      are in ra,dec,freq order on input, in
                                       actual disk order when using xyzopen.
   - CloseDataSet(Set,flag)            Close dataset; if flag=TRUE also write
                                       the DataMin and DataMax to the header.
   - SetupDataSet(Set)                 Sort blc/trc, then call xyzsetup

   - GetItem.(Lun,item,axis,value)     .=A,R,I  reads header item
     PutItem.(Lun,item.axis,value)     .=A,R,I  writes header item
     CopyItem(OutLun,InLun,item)       copy header item

   - CopyDisk(IOmode,lun1,lun2,plane,xlen,ylen) Do actual disk IO
   - CopyDTM(IOmode,xlen,ylen)         send something across with DTM
   - CopyPar(IOmode,pData,pMask,aShape,xlen,ylen) copy parallel<->serial array
*/
/******************************************************************************/
/******************************************************************************/
/*
   Read or write a header element, using some macros for more natural access
   elsewhere. ItemIO is an interface to miriad's rdhd and wrhd. The reason
   for its existence is to be able to call different actual IO routines without
   changing anything in the rest of the program.
*/
/******************************************************************************/

private char *Header[] = {
     "history ",
     "instrume", "telescop", "object", "observer", "epoch", "restfreq",
     "vobs",     "bunit",
     "MAP_SPECIFIC",
     "date-obs", "obsdec",   "obsra",  "pbfwhm",
     "ltype",    "lstart",   "lwidth", "lstep",
     "bmaj",     "bmin",     "bpa",
     "xshift",   "yshift",   "btype",  "niters",   "" };

private void ItemIO( RWmode, Lun, Template, item, axis, string, dValue, iValue )
IOmodes  RWmode;
int      Lun;
int      Template;
char    *item;
AXIS     axis;
char    *string;
double  *dValue;
int     *iValue;
{
   void rdhda_c(), rdhdd_c(), rdhdi_c();
   void wrhda_c(), wrhdd_c(), wrhdi_c();
   void hdcopy_c();
   char Itm[AITEMLEN];

   if( axis == NOAX ) Sprintf( Itm, "%s",   item                  );
   else               Sprintf( Itm, "%s%d", item, AxisToInt(axis) );

   if(         RWmode == READ  ) {
      if( string != NULL ) rdhda_c( Lun, Itm,  string, "\0", AITEMLEN );
      if( dValue != NULL ) rdhdd_c( Lun, Itm,  dValue, ZERO );
      if( iValue != NULL ) rdhdi_c( Lun, Itm,  iValue,   0  );
   } else if ( RWmode == WRITE ) {
      if( string != NULL ) wrhda_c( Lun, Itm,  string );
      if( dValue != NULL ) wrhdd_c( Lun, Itm, *dValue );
      if( iValue != NULL ) wrhdi_c( Lun, Itm, *iValue );
   } else if ( RWmode == COPY  ) {
      hdcopy_c( Template, Lun, Itm );
   }
}

void GetItemA(l,it,ax,v) int l; char *it; AXIS ax; char   *v; {
     ItemIO( READ, l,-1,it,ax, v,             (double *)NULL, (int *)NULL ); }
void PutItemA(l,it,ax,v) int l; char *it; AXIS ax; char   *v; {
     ItemIO( WRITE,l,-1,it,ax, v,             (double *)NULL, (int *)NULL ); }
void GetItemR(l,it,ax,v) int l; char *it; AXIS ax; double *v; {
     ItemIO( READ, l,-1,it,ax,  (char *)NULL,  v,             (int *)NULL ); }
void PutItemR(l,it,ax,v) int l; char *it; AXIS ax; double  v; {
     ItemIO( WRITE,l,-1,it,ax,  (char *)NULL, &v,             (int *)NULL ); }
void GetItemI(l,it,ax,v) int l; char *it; AXIS ax; int    *v; {
     ItemIO( READ, l,-1,it,ax,  (char *)NULL, (double *)NULL,  v          ); }
void PutItemI(l,it,ax,v) int l; char *it; AXIS ax; int     v; {
     ItemIO( WRITE,l,-1,it,ax,  (char *)NULL, (double *)NULL, &v          ); }
void CopyItem(l,t,it)    int l; int t; char *it; {
     ItemIO( COPY, l, t,it,NOAX,(char *)NULL, (double *)NULL, (int *)NULL ); }

/******************************************************************************/
/*
   Open a dataset.
   - For old datasets: first set # of axes to MAXNAX, then read in # of axes
     and axislengths. Next, set SetCoo->naxis to the proper enum AXIS value.
   - For new datasets: first set # of axes to proper #, decoding the enum AXIS
     value, and reorder the axeslengths. Then open new dataset. Next copy header
     items from a template.
*/
/******************************************************************************/

void Open_OldDataSet( Set          ) DATASET *Set;
{ private void OpenDataSet(); OpenDataSet( Set, "old", (DATASET *)Set ); }
void Open_NewDataSet( Set, HeadSet ) DATASET *Set, *HeadSet;
{ private void OpenDataSet(); OpenDataSet( Set, "new", HeadSet        ); }

#ifdef XYZIO
private logical xyzmkbuf_called=FALSE;
#endif

private void OpenDataSet( Set, status, HeadSet )
DATASET *Set;
char    *status;
DATASET *HeadSet;
{
   logical SetPresent();
   void    PutItemA(), PutItemR(), rdhdi_c();
   AXIS    n, j;
   COORDS  Coo;
   COORDS *SetCoo = &Set->Coords;
   int     HeadLun;
   DBGVAL("-- -- OpenDataSet -- %s\n",Set->name);

#ifdef XYZIO
   if( !xyzmkbuf_called ) { xyzmkbuf_c(); xyzmkbuf_called=TRUE; }
#endif

   if( StrEq( status, "old" ) ) {
      n = MAXNAX;
   } else if( StrEq( status, "new" ) ) {
      assert(!SetPresent(Set->name),"Output file %s already exists",Set->name);
/* sort axes on axisnr */
      for( n=AXIS1; n<=SetCoo->naxis; n++ )
      Coo.axlen[ SetCoo->axisnr[n] ] = SetCoo->axlen[n];
      n = AxisToInt( SetCoo->naxis );
   }

   XYZopen( &Set->Lun, Set->name, status, n, &Coo.axlen[AXIS1] );
   getnaxis(Set->Lun,n);

   if( StrEq( status, "old" ) ) {
/* sort axes on axisnr */
      SetCoo->naxis = IntToAxis( n );
      if( SetCoo->axisnr[0] == -1 ) for( n=AXIS1;n<=SetCoo->naxis;n++ )
      SetCoo->axlen[n] = Coo.axlen[n];
      else                          for( n=AXIS1;n<=SetCoo->naxis;n++ )
      SetCoo->axlen[n] = Coo.axlen[ SetCoo->axisnr[n] ];
   } else if( StrEq( status, "new" ) ) {
/* write new header */
      if( HeadSet != NULL ) {
         if( HeadSet->Lun == 0 ) {
           n=MAXNAX; XYZopen( &HeadLun, HeadSet->name, "old", n, Coo.axlen );
           getnaxis(Set->Lun,n);
         } else {
            HeadLun = HeadSet->Lun;
         }
         for( n=0; *Header[n]; n++ ) {
            if( StrEqX(Header[n],"MAP_SPECIFIC") ) {
                if( StrEqX(Set->type,"model") ) break; else continue; }
            CopyItem( Set->Lun, HeadLun, Header[n] );
         }
         if( HeadSet->Lun == 0 ) XYZclose( HeadLun );
      }
      for( n=AXIS1; n<=SetCoo->naxis; n++ ) {
         j = SetCoo->axisnr[n];
         PutItemR( Set->Lun, "crval", j, SetCoo->crval[n] );
         PutItemR( Set->Lun, "cdelt", j, SetCoo->cdelt[n] );
         PutItemR( Set->Lun, "crpix", j, SetCoo->crpix[n] );
         PutItemA( Set->Lun, "ctype", j, SetCoo->ctype[n] );
      }
      Set->DataMin = MAX_REAL; Set->DataMax = -MAX_REAL;
   }
}

/******************************************************************************/
/*
   Close the dataset, and possibly write the min and max value to the header.
*/
/******************************************************************************/

void CloseDataSet( Set, flag )
DATASET *Set;
logical  flag;
{  void PutItemR();
   TRACE("-- -- CloseDataSet");
   if( flag ) { PutItemR( Set->Lun, "datamin", NOAX, Set->DataMin );
                PutItemR( Set->Lun, "datamax", NOAX, Set->DataMax ); }
   XYZclose( Set->Lun );
   Set->Lun = 0;
}

/******************************************************************************/
/*
   Set up for reading with xyzplnrd.
   The axes are first sorted to the order they were in the dataset on disk,
   xyzsetup is called to initialize xyzio.

   Of input SetCoo, the axisnr, blc and trc arrays are needed.
*/
/******************************************************************************/

void SetupDataSet( Lun, SetCoo )
int     Lun;
COORDS *SetCoo;
{
#ifdef XYZIO
   COORDS Coo;
   AXIS   n, j;
   TRACE("-- -- SetupDataSet");

   for( n=AXIS1; n<=SetCoo->naxis; n++ ) {
      j = SetCoo->axisnr[n];
      Coo.blc[j] = SetCoo->blc[n];
      Coo.trc[j] = SetCoo->trc[n];
   }
#ifdef LINEIO
   xyzsetup_c( Lun, "x",  &Coo.blc[AXIS1],&Coo.trc[AXIS1],Coo.axlen,Coo.axlen );
#endif
#ifdef PLANEIO
   xyzsetup_c( Lun, "xy", &Coo.blc[AXIS1],&Coo.trc[AXIS1],Coo.axlen,Coo.axlen );
#endif

#endif /* XYZIO */

#ifdef XYIO
   Lun=Lun; SetCoo=SetCoo; /* keep lint quiet */
#endif
}

/******************************************************************************/
/*
   SetPresent checks whether or not the named dataset already exists.
*/
/******************************************************************************/

logical SetPresent( name ) char *name;
{ logical hexists_c(); return( hexists_c(0,name) ); }

/*

/******************************************************************************/
/*    <<< Data transfer >>                             146 +   67 =  213 DISKIO
/******************************************************************************/
/*
   Define the IO buffer, to receive/send data from disk or parallel memory.
   There is a buffer on both the local and the remote machines.
*/
/******************************************************************************/

private struct {
         float *Data;
         int   *Mask;
         logical d, m;
       } IObuf;

void InitIObuffer( size, pData, pMask, flag )
int        size;
Real_void *pData;
Real_void *pMask;
logical    flag;
{
   logical  LocallyRun(), DTMmaster();
   Real    *GetScrAddress();

   TRACE("-- InitIObuffer");

#if defined(REAL_IS_DOUBLE) || defined(__CSTAR__)
   IObuf.Data = (float *)(GetScrAddress()     ); IObuf.d=TRUE;
   IObuf.Mask = (int   *)(GetScrAddress()+size); IObuf.m=TRUE;
#else
   if( !LocallyRun() && DTMmaster() ) {
     IObuf.Data = (float *)(GetScrAddress()     ); IObuf.d=TRUE;
     IObuf.Mask = (int   *)(GetScrAddress()+size); IObuf.m=TRUE;
   } else {
     if(flag) { IObuf.Data=(float *)(GetScrAddress());     IObuf.d=TRUE;
                IObuf.Mask=(int   *)(GetScrAddress()+size);IObuf.m=TRUE;
     } else {   IObuf.Data=(float *)(pData);               IObuf.d=FALSE;
                                 IObuf.m=(pMask==NULL)|(pMask==(Real_void *)1);
                IObuf.Mask=(int   *)(IObuf.m?GetScrAddress()+size:pMask);
     }
   }
#endif
}

void SetIObuffer( length )
int length;
{
   int i;
   for( i=0; i<length; i++ ) { *(IObuf.Data+i)=0.; *(IObuf.Mask+i)=FORT_TRUE; }
}

/******************************************************************************/
/*
   Do the actual disk IO.
*/
/******************************************************************************/

private int hyperplane[MAXNAX-2] = { 1,1,1,1,1 };

void CopyDisk( IOmode, Lun1, Lun2, plane, xlen, ylen )
IOmodes  IOmode;
int      Lun1, Lun2;
int      plane;
int      xlen, ylen;
{
   void Timer_Cont(), Timer_Stop();
   int profile, first, last, off;
   if(IOmode==READ ) TRACE("-- CopyDisk - READ");
   if(IOmode==WRITE) TRACE("-- CopyDisk - WRITE");

   Timer_Cont("DISK_IO");
#ifdef LINEIO
#ifdef XYZIO
   first = ( plane - 1 ) * ylen + 1;
#endif
#ifdef XYIO
   first = 1; hyperplane[0]=plane; xysetpl_c( Lun1, 1, hyperplane );
#endif
   last = first + ylen - 1;
   for( profile=first; profile<=last; profile++ ) {
   off = (profile-first)*xlen;
   switch( IOmode ) {
   case READ:  XYZprfrd( Lun1, profile,IObuf.Data+off,IObuf.Mask+off, &xlen );
               break;
   case WRITE: XYZprfwr( Lun1, profile,IObuf.Data+off,IObuf.Mask+off, &xlen );
               break;
   case COPY:  XYZprfrd( Lun1, profile,IObuf.Data+off,IObuf.Mask+off, &xlen );
               XYZprfwr( Lun2, profile,IObuf.Data+off,IObuf.Mask+off, &xlen );
               break;
   }
   }
#endif
#ifdef PLANEIO
   int length;
   TRACE("-- CopyDisk");
   length = xlen * ylen;
   switch( IOmode ) {
   case READ:  xyzplnrd_c( Lun1, plane, IObuf.Data, IObuf.Mask, &length );
               break;
   case WRITE: xyzplnwr_c( Lun1, plane, IObuf.Data, IObuf.Mask, &length );
               break;
   case COPY:  xyzplnrd_c( Lun1, plane, IObuf.Data, IObuf.Mask, &length );
               xyzplnwr_c( Lun2, plane, IObuf.Data, IObuf.Mask, &length );
               break;
   }
#endif
   Timer_Stop("DISK_IO");
}

/******************************************************************************/
/*
   Send and receive data with DTM.
   I.e. write from local  machine's IObuf to remote machine's IObuf
        read  from remote machine's IObuf to local  machine's IObuf
*/
/******************************************************************************/

void CopyDTM( IOmode, xlen, ylen )
IOmodes IOmode;
int     xlen, ylen;
{
   void    Timer_Cont(), Timer_Stop();
   logical LocallyRun();
   if( !LocallyRun() ) {

   void    DTMgetData(), DTMputData();
   int     DTMgetport();
   int     Port = IOmode==READ ? DTMgetport('i') : DTMgetport('o');

   if(IOmode==READ ) TRACE("-- CopyDTM - READ");
   if(IOmode==WRITE) TRACE("-- CopyDTM - WRITE");

   Timer_Cont("DATA_EXCHANGE");
   switch( IOmode ) {
   case READ:  DTMgetData( Port, TRUE,IObuf.Data,IObuf.Mask, xlen*ylen ); break;
   case WRITE: DTMputData( Port, TRUE,IObuf.Data,IObuf.Mask, xlen*ylen ); break;
   }
   Timer_Stop("DATA_EXCHANGE");
}}

/******************************************************************************/
/*
   Copy between parallel and serial memory.
   I.e. write IObuf array in serial front-end memory to a parallel array
        read a parallel array to serial front-end memory IObuf array

   This also takes care of float <-> double conversion in case Real==double.

   When running on serial machines, this is usually skipped.

   But: when reading with pMask set to NULL the mask is set to all TRUE.
        when writing out the Cov array (IOmode=WRITE on master, IOmode=READ
           on slave), pMask is -1, and only half the input is copied into
           IObuf.Data.
   (not checked for working under CSTAR)
*/
/******************************************************************************/

#ifndef __CSTAR__
private void   readR_from_pvar(s,p)float *s;Real p; {         *(s+MemPixNum)=p;}
private double writeR_to_pvar( s  )float *s;{return( (double)(*(s+MemPixNum)));}
private void   readI_from_pvar(s,p)int   *s;Real p; {         *(s+MemPixNum)=p;}
private double writeI_to_pvar( s  )int   *s;{return( (double)(*(s+MemPixNum)));}
#else
#define readR_from_pvar read_from_pvar
#define writeR_to_pvar  write_from_pvar
#define readI_from_pvar read_from_pvar
#define writeI_to_pvar  write_from_pvar
#endif

void CopyPar( IOmode, pData, pMask, aShape, xlen, ylen )
IOmodes    IOmode;
Real_void *pData;
Real_void *pMask;
shape     *aShape;
int        xlen, ylen;
{
   logical      DTMmaster();
   private void ConvertMask();
   int          i;
   shape        aS, *pS;
   if(IOmode==READ ) TRACE("-- CopyPar - READ");
   if(IOmode==WRITE) TRACE("-- CopyPar - WRITE");

#ifdef __CSTAR__
   pS = aShape;
#else
   aS.start=0; aS.end=aShape->size-1; aS.xlen=aShape->xlen;
   pS = &aS;
#endif

   if( IObuf.d ) {
      if(IOmode==READ ){ with(*pS) readR_from_pvar(IObuf.Data,*p_arr(pData));  }
      if(IOmode==WRITE){ with(*pS) *p_arr(pData) =
                                          (Real)writeR_to_pvar(IObuf.Data);    }
                         TimerStopParallel
   }


   if( pMask == (Real_void *)NULL ) {

    if(IOmode==READ ) { for(i=0;i<xlen*ylen;i++) *(IObuf.Mask+i)=FORT_TRUE; }
/*  if(IOmode==WRITE) { ignore mask;                                        } */

   } else if( (pMask == (Real_void *)1) && (IOmode == READ) ) {
    for(i=0;i<xlen*ylen;i++) { *(IObuf.Data+i) = *(pData+2*i);
                               *(IObuf.Mask+i) = FORT_TRUE;    }

   } else {

    if(IOmode==WRITE) { if(DTMmaster()) ConvertMask( IObuf.Mask,xlen*ylen ); }

    if( IObuf.m ) {
      if(IOmode==READ ){ with(*pS) readI_from_pvar(IObuf.Mask,*p_arr(pMask));  }
      if(IOmode==WRITE){ with(*pS) *p_arr(pMask) =
                                          (Real)writeI_to_pvar(IObuf.Mask);    }
                         TimerStopParallel
    }
   }
}

/******************************************************************************/
/*
   Converts between conventions for TRUE and FALSE
*/
/******************************************************************************/

private void ConvertMask( Mask, length )
int *Mask;
int  length;
{
   int i;
   if( ( TRUE != FORT_TRUE ) | ( FALSE != FORT_FALSE ) ) {
#ifdef mips
#pragma parallel byvalue(length) local(i) shared(Mask)
#pragma pfor iterate(i=0;length;1)
#endif
      for( i=0; i<length; i++ ) *(Mask+i) = *(Mask+i)==FORT_TRUE ? TRUE : FALSE;
   }
}

/******************************************************************************/
/*
   Read in a small patch from a single plane.
   Necessary as subroutine because things are fundamentally different when
   using xyzio as compared to xyio.
*/
/******************************************************************************/

void XYZpatch( Lun, blc, trc, patch, mask )
int    Lun;
int   *blc, *trc;
float *patch, *mask;
{
#ifdef XYZIO
   void xyzsetup_c(), xyzplnrd_c();
   int  cubesize[MAXNAX], ndata;
   xyzsetup_c( Lun, "xy", blc, trc, cubesize,cubesize );
   xyzplnrd_c( Lun, blc[2], patch, mask, &ndata );
#endif
#ifdef XYIO
   void  xysetpl_c(), xyread_c();
   int   xlen = trc[0] - blc[0] + 1;
   int   x, y, off;
   float temp[2048];
   xysetpl_c( Lun, 1, &blc[2] );
   for( y=blc[1]; y<=trc[1]; y++ ) {
      xyread_c( Lun, y, temp ); off=(y-blc[1])*xlen - blc[0];
      for( x=blc[0]; x<=trc[0]; x++ ) *(patch+off+x) = *(temp+x-1);
   }
   *mask = 1.; /* keep lint quiet */
#endif
}

void XYZrdprof( Lun, blc, trc, prof, mask )
int    Lun;
int   *blc, *trc;
float *prof, *mask;
{
#ifdef XYZIO
   void xyzsetup_c(), xyzprfrd_c();
   int  cubesize[MAXNAX], ndata;
   xyzsetup_c( Lun, "z", blc, trc, cubesize,cubesize );
   xyzprfrd_c( Lun, 1, prof, mask, &ndata );
#endif
#ifdef XYIO
   void xysetpl_c(), xyread_c();
   int  z;
   for( z=blc[2]; z<=trc[2]; z++ ) {
      xysetpl_c( Lun, 1, &z ); xyread_c( Lun, 1, prof+z-1 );
   }
   *mask = 1.; /* keep lint quiet */
#endif
}
