/*----------------------------------------------------------------------------
-- mosaic_maps.c --
/*----------------------------------------------------------------------------*/
#include "mosaic_arrays.h"
/*----------------------------------------------------------------------------*/

void OperCount();
#define OpCnt(sh,npl,nps,nm,na,nd) \
        TimerStopParallel OperCount(0,sh,0,npl,nps,nm,na,nd)

/******************************************************************************/
/* <<< MAP DATA IO >>>                                 344 +  157 =  501 DISKIO
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*
   READ/WRITE MAPS
*/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*    <<< Read input data >>>                           45 +   21 =   66 DISKIO
/******************************************************************************/
/*
   - ReadBeams is placed here, since it is a data reading operation, although
     it is called from a different place than ReadMaps.

   - First read the input maps, including the masks.

   - Then read reference and initial estimate arrays, if necessary.

   - It can happen that the mosaic map must be read in, instead of calculated.
     Do that here too.
*/
/******************************************************************************/

void ReadBeams( Maps )
ONEMAP  *Maps;
{
   void    ReadData();
   void    CheckSyB();
   void    Timer_End();
   ONEMAP *MapI;
   TRACE("-- ReadBeams");

   for( ALLMAPSI ) { if(MapI->IsIFmap) {
      MapI->SynthBeam.Coords.CurPlane = 1;
      ReadData( ps_SyB, NOMASK, Bea_Shape, &MapI->SynthBeam );
      CheckSyB(MapI);
      assert( fEq( MapI->SynthBeam.DataMax, 1. ),
             "Maximum of beam (%8.6g) not close enough to 1",
              MapI->SynthBeam.DataMax );
   }}
   Timer_End("beam");
}

void ReadMaps( MosMap, Maps, Flags, plane )
MOSMAP  *MosMap;
ONEMAP  *Maps;
logical  Flags[];
int      plane;
{
   private void SetPlanes();
   void    ReadData();
   void    Timer_End();
   ONEMAP *MapI;
   TRACE("-- ReadMaps");

   SetPlanes( MosMap, Maps, Flags, plane );

   for( ALLMAPSI ) {
      if( MapI->Region.MaskPresent )
      ReadData( ps_Obs, ps_RegMsk, Obs_Shape, MapI->Region.Mask  );
      ReadData( ps_Obs, ps_Msk,    Obs_Shape, &MapI->Observation );
   }
   if( Flags[READMOD] ) ReadData( ps_Mos,NOMASK,Mos_Shape,&MosMap->MosaicMap );
   if( Flags[READINI] ) ReadData( ps_Mos,NOMASK,Mos_Shape,&MosMap->Initial   );
   if( Flags[READREF] ) ReadData( ps_Ref,NOMASK,Mos_Shape,&MosMap->Reference );

   Timer_End("map");
}

/******************************************************************************/
/*
   Indicate which plane we are working on by setting the CurPlane variable.
   This is used to read/write datasets.
   - In standard mode (apply mem), the output is written starting with plane
     1, etc.
   - In non-standard mode (read mosaiced image in order to do convolution),
     the input plane to be read is given by the Region struct of the first
     input map.
*/
/******************************************************************************/

private void SetPlanes( MosMap, Maps, Flags, plane )
MOSMAP  *MosMap;
ONEMAP  *Maps;
logical  Flags[];
int      plane;
{
#define CPL Coords.CurPlane
   ONEMAP *MapI;
   TRACE("-- SetPlanes");

   for( ALLMAPSI ) {
      MapI->Observation.CPL   =
      MapI->DirtyMap.CPL      =
      MapI->PrimaryBeam.CPL   = *( MapI->Region.Planes + plane - 1 );
      if( MapI->Region.MaskPresent )
      MapI->Region.Mask->CPL = MapI->Observation.CPL;
   }

   MosMap->Reference.CPL = MosMap->Reference.Coords.ZLEN == 1 ? 1 : plane;
   MosMap->Initial.CPL   = MosMap->Initial.Coords.ZLEN   == 1 ? 1 : plane;

   MosMap->MosaicMap.CPL = Flags[WRITEMOS] ? plane : Maps->Observation.CPL;

   MosMap->Residual.CPL  =
   MosMap->Convolved.CPL =
   MosMap->Final.CPL     = plane;
   MosMap->Gaussian.CPL  = 1;
#undef CPL
}

/*

/******************************************************************************/
/*    <<< Write output maps >>>                         74 +   21 =   95 DISKIO
/******************************************************************************/
/*
   Close open SaveSets, if necessary.
   Create output datasets on first pass.
   Write out one plane of result.
   Which datasets are written depends on the settings of the Flag array.
   Finish off by writing history file.
*/
/******************************************************************************/

void WriteResult( MosMap, Maps, Flags, CTRL, Stats, plane )
MOSMAP  *MosMap;
ONEMAP  *Maps;
logical  Flags[];
CONTROL *CTRL;
STATS   *Stats;
int      plane;
{
   void         SaveSetsClose();
   private void OpenNewSets();
   private void WriteOutputSets();
   private void Histories();
   void         Timer_End();
   TRACE("WriteResult");

   SaveSetsClose();
   if( plane == 1 ) OpenNewSets(     MosMap, Maps, Flags              );
                    WriteOutputSets( MosMap, Maps, Flags              );
                    Histories(plane, MosMap, Maps, Flags, CTRL, Stats );
   Timer_End("output");
}

/******************************************************************************
/*
   Open the datasets as implied by the Flags arrays.
*/
/******************************************************************************/

private void OpenNewSets( MosMap, Maps, Flags )
MOSMAP  *MosMap;
ONEMAP  *Maps;
logical  Flags[];
{
   void     Open_NewDataSet();
   DATASET *HeadSet = &Maps->Observation;

   if( Flags[WRITEMOS] ) Open_NewDataSet( &MosMap->MosaicMap, HeadSet );
   if( Flags[WRITERES] ) Open_NewDataSet( &MosMap->Residual,  HeadSet );
   if( Flags[WRITECNV] ) Open_NewDataSet( &MosMap->Convolved, HeadSet );
   if( Flags[WRITEFIN] ) Open_NewDataSet( &MosMap->Final,     HeadSet );
}

/******************************************************************************
/*
   Actually write out the wanted output sets.
*/
/******************************************************************************/

private void WriteOutputSets( MosMap, Maps, Flags )
MOSMAP  *MosMap;
ONEMAP  *Maps;
logical  Flags[];
{
   void    WriteData();

   if(Flags[WRITEMOS]) WriteData( ps_Mos,NOMASK,Mos_Shape,&MosMap->MosaicMap );
   if(Flags[WRITERES]) WriteData( ps_MRs,NOMASK,Mos_Shape,&MosMap->Residual  );
   if(Flags[WRITECNV]) WriteData( ps_Cnv,ps_Sel,Mos_Shape,&MosMap->Convolved );
   if(Flags[WRITEFIN]) WriteData( ps_Fin,NOMASK,Mos_Shape,&MosMap->Final     );
}

/******************************************************************************/
/*
   Histories is called after writing all the data.
*/
/******************************************************************************/

private void Histories( plane, MosMap, Maps, Flags, CTRL, Stats )
int      plane;
MOSMAP  *MosMap;
ONEMAP  *Maps;
logical  Flags[];
CONTROL *CTRL;
STATS   *Stats;
{
   void         ExchangeVariables();
   private void History();
   TRACE("Histories");

   ExchangeVariables( "RESULTS", MosMap, Maps, Flags, CTRL, Stats );

   if(Flags[WRITEMOS])
      History(plane,&MosMap->MosaicMap,MosMap,Maps,Flags,CTRL,Stats);
   if(Flags[WRITERES])
      History(plane,&MosMap->Residual, MosMap,Maps,Flags,CTRL,Stats);
   if(Flags[WRITECNV])
      History(plane,&MosMap->Convolved,MosMap,Maps,Flags,CTRL,Stats);
   if(Flags[WRITEFIN])
      History(plane,&MosMap->Final,    MosMap,Maps,Flags,CTRL,Stats);
}

private void History( plane, Set, MosMap, Maps, Flags, CTRL, Stats )
int      plane;
DATASET *Set;
ONEMAP  *Maps;
MOSMAP  *MosMap;
logical  Flags[];
CONTROL *CTRL;
STATS   *Stats;
{
   void hisopen_c(), hisclose_c(), hisinput_c();
   void Messages_Where();
   void Messages_Converge_Long();
   TRACE("History");

   hisopen_c( Set->Lun, "append" );
   if( plane==1 ) {
      hisinput_c( Set->Lun, "MOSAIC" );
      if(Maps->NextMap!=NULL) Messages_Where( Set->Lun, MosMap, Maps );
   }
   if( Flags[MOSCALC] & ( Stats->Iteration > 0 ) ) {
      Messages_Converge_Long( Set->Lun, CTRL, Stats,
                              MosMap->MosaicMap.Coords.CurPlane );
   }
   hisclose_c( Set->Lun );
}

/******************************************************************************/
/*
   Take care of closing output datasets.
*/
/******************************************************************************/

void CloseDataSets( MosMap, Maps, Flags )
MOSMAP  *MosMap;
ONEMAP  *Maps;
logical  Flags[];
{
   void    CloseDataSet();
   ONEMAP *MapI;
   TRACE("CloseDataSets");

#ifdef cm5
   TRACE("Did not close datasets, will bomb otherwise\n");
#else
   if( Flags[WRITEMOS] ) CloseDataSet( &MosMap->MosaicMap, TRUE  );
   if( Flags[WRITERES] ) CloseDataSet( &MosMap->Residual,  TRUE  );
   if( Flags[WRITECNV] ) CloseDataSet( &MosMap->Convolved, TRUE  );
   if( Flags[WRITEFIN] ) CloseDataSet( &MosMap->Final,     TRUE  );
#endif
}

/*

/******************************************************************************/
/*    <<< Transfer data >>>                             20 +   11 =   31 DISKIO
/******************************************************************************/
/*
   DataIO - shift the data between disk/local machine/remote machine/parallel
   memory.

   DataIO is called on the master. It first gives some info, then opens the
   given dataset.
   Next it kicks the remote machine into calling routine DataIO. It then sends
   the array information to the remote machine, then tells it to do data IO.
   Having done all this, it goes into wait mode, until MINMAX is sent.
   The remote machine first gets the array info, then signal "SENDDATA". After
   the transfer, it is told to go to MINMAX, and sends the min and max, then
   sends READY.

   Old datasets that need to be read have to be opened first and closed after
   reading. This to avoid having too many datasets open at the same time.
   New datasets, however, are open all the time, and the setup is for the whole
   datacube.
*/
/******************************************************************************/

void ReadData(                          Data, Mask, aShape,          Set )
enum arrayselections Data, Mask; enum shapeselections aShape; DATASET *Set;
{ private void DataIO(); DataIO( READ,  Data, Mask, aShape,          Set ); }

void WriteData(                         Data, Mask, aShape,          Set )
enum arrayselections Data, Mask; enum shapeselections aShape; DATASET *Set;
{ private void DataIO(); DataIO( WRITE, Data, Mask, aShape,          Set ); }

private void DataIO( mode, Data, Mask, aShape, Set )
IOmodes               mode;
enum arrayselections  Data, Mask;
enum shapeselections  aShape;
DATASET              *Set;
{
   void    Messages_RW();
   logical LocallyRun(), DTMmaster(), DTMreceive(), DTMrclass();
   logical DTMm2s(), DTMs2m();
   void    DTMsendSignal(), DTMgotoSignal(), DTMexchange();
   void    Open_OldDataSet(), SetupDataSet(), CloseDataSet();
   private void TransferData();

   int     Lun, SetNum, plane;
   int     xlen, ylen;
   double  MinMax[2];
   if(Set!=0) TRACE("DataIO");

   if( DTMmaster() ) {

      if( mode==READ  ) DTMsendSignal("READDATA");    /* caught by RemoteMain */
      if( mode==WRITE ) DTMsendSignal("WRITEDATA");   /* caught by RemoteMain */

      plane  = Set->Coords.CurPlane;
      SetNum = Set->SetNum;
      xlen   = Set->Coords.XLEN;
      ylen   = Set->Coords.YLEN;

      if( mode==READ  ) Messages_RW( "Reading", plane, Set->name );
      if( mode==WRITE ) Messages_RW( "Writing", plane, Set->name );

      if( mode==READ  ) Open_OldDataSet( Set );
                        SetupDataSet( Set->Lun, &Set->Coords );
      Lun = Set->Lun;

      DTMgotoSignal("ARRSEL");
   } else {
      plane = SetNum = xlen = ylen = Lun = 0;
   }

   while( DTMreceive() ) {

      if(        DTMrclass("ARRSEL") ) {
         DTMexchange( DTMm2s(), "ARRSEL", "iiiiii",
                      &SetNum, &Data, &Mask, &aShape, &xlen, &ylen );
         if(DTMmaster()) DTMgotoSignal( "SENDDATA");

      } else if( DTMrclass("SENDDATA") ) {
         if( DTMmaster()) DTMsendSignal("SENDDATA");
         TransferData( mode, Lun, SetNum, plane,
                             Data, Mask, aShape, xlen, ylen, MinMax );
         if( DTMmaster()) DTMgotoSignal("WAIT");
         if(!DTMmaster()) DTMgotoSignal("MINMAX");
         if(LocallyRun()) DTMgotoSignal("READY");

      } else if( DTMrclass("MINMAX") ) {
         DTMexchange( DTMs2m(), "MINMAX", "dd", &MinMax[0], &MinMax[1] );
         if(!DTMmaster()) DTMgotoSignal("READY");

      }

   }

   if( DTMmaster() ) {
      Set->DataMin=MinMax[0]; Set->DataMax=MinMax[1];
      if( mode==READ ) CloseDataSet( Set, FALSE );
   }
}

/*

/******************************************************************************/
/*
   TransferData does the requested transfer between disk/IObuffer and parallel
   memory, depending on whether it is called on the master or on the slave, with
   OUTPORT or INPORT and whether or not the program really has two CPUs.

   OUTPORT on master:  read data from disk in master's IObuffer
                       send    master's IObuffer   to slave's parallel
   INPORT  on slave:   receive master's IObuffer into slave's parallel
   OUTPORT on slave:   send    slave's  parallel to   master's IObuffer
   INPORT  on master:  receive slave's  parallel into master's IObuffer
                       write data to disk from master's IObuffer

   It ends with a determination of the min and max in the current buffer.
*/
/******************************************************************************/

private void TransferData( mode, Lun, SetNum,plane,Data,Mask,aShape,
                                      xlen,ylen,MinMax )
IOmodes              mode;
int                  Lun, SetNum, plane;
enum arrayselections Data, Mask;
enum shapeselections aShape;
int                  xlen, ylen;
double               MinMax[2];
{
   logical      LocallyRun(), DTMmaster();
   void         InitIObuffer();
   private void ArraySelection_To_Pointer();
   void         CopyDisk(), CopyDTM(), CopyPar();

   Real_void   *pData;
   Real_void   *pMask;
   shape       *pShape;
   Real         minimum, maximum;

   TRACE("TransferData");

   if( LocallyRun() || !DTMmaster() )
   ArraySelection_To_Pointer(SetNum,Data,&pData,Mask,&pMask,aShape,&pShape);

   if( Data == ps_Cov ) pMask = (Real_void *)1;
   InitIObuffer( xlen*ylen, pData, pMask, Data==ps_Cov );

   if(  DTMmaster() && mode==READ ) {
                         CopyDisk( READ,  Lun, 0, plane,        xlen, ylen );
      if( LocallyRun() ) CopyPar(  WRITE, pData, pMask, pShape, xlen, ylen );
      else               CopyDTM(  WRITE,                       xlen, ylen );
   }
   if(  DTMmaster() && mode==WRITE ) {
      if( LocallyRun() ) CopyPar(  READ,  pData, pMask, pShape, xlen, ylen );
      else               CopyDTM(  READ,                        xlen, ylen );
                         CopyDisk( WRITE, Lun, 0, plane,        xlen, ylen );
   }
   if( !DTMmaster() && mode==READ ) {
                         CopyDTM(  READ,                        xlen, ylen );
                         CopyPar(  WRITE, pData, pMask, pShape, xlen, ylen );
   }
   if( !DTMmaster() && mode==WRITE ) {
                         CopyPar(  READ,  pData, pMask, pShape, xlen, ylen );
                         CopyDTM(  WRITE,                       xlen, ylen );
   }


   if( LocallyRun() | !DTMmaster() ) {
      minimum=MAX_REAL; maximum=-MAX_REAL;
#ifdef mips
#pragma parallel shared(pData) local(MemPixNum) reduction(minimum,maximum)
#pragma pfor iterate(MemPixNum=START;END;1)
#endif
      with(*pShape) everywhere {
         assmin( minimum, *p_arr(pData) );
         assmax( maximum, *p_arr(pData) );
      } OpCnt(pShape,2,4, 2, 2,0);
      MinMax[0]=minimum; MinMax[1]=maximum;
   }
}

/*

/******************************************************************************/
/*
   Convert array numbers into pointers.

   These are the input variables for the Read/WriteData and Save... routines.
   The values are percolated down to function ArraySelection_To_Pointer, which
   converts these numbers into actual addresses.

   - SetNum indicates which of the many possible input maps to select. If 0, it
     is the mosaiced map. If necessary, loop over the input maps to get the
     right one.
   - SelectArray returns the pointer to the array indicate by the Array
     variable.
   - SelectShape turns a shape number into an actual pointer to shape.

   This is (almost) the only place that uses the fact that MosMap and Maps are
   global variables (and it is the reason that they are global).
*/
/******************************************************************************/

private void ArraySelection_To_Pointer( SetNum, Data,pData, Mask,pMask,
                                                aShape,pShape )
int                    SetNum;
enum arrayselections   Data, Mask;
enum shapeselections   aShape;
Real_void            **pData;
Real_void            **pMask;
shape                **pShape;
{
   void               MapStructs();
   private Real_void *SelectArray();
   private shape     *SelectShape();
   int                i;
   MOSMAP            *MosMap;
   ONEMAP            *Maps, *MapI;
   TRACE("-- ArraySelection_To_Pointer");

   MapStructs( &MosMap, &Maps ); MapI=Maps;
   if(SetNum==0)   MosArrays(MosMap);
   if(SetNum>0)  { i=1; while(i<SetNum) { i++; MapI=MapI->NextMap; }
                   MapI=MapArrays(0,MapI); }

   *pData  = (Real_void *)SelectArray( MosMap, MapI,  Data  );
   *pMask  = (Real_void *)SelectArray( MosMap, MapI,  Mask  );
   *pShape = (shape     *)SelectShape( MosMap, MapI, aShape );
}

private Real_void *SelectArray( MosMap, MapI, Array )
MOSMAP               *MosMap;
ONEMAP               *MapI;
enum arrayselections  Array;
{
   Real_void *p;
   switch( Array ) {
   case ps_Obs: p=p0_Obs; break;   case ps_Msk: p=p0_Msk; break;
   case ps_RegMsk: p=p0_RegMsk; break;
   case ps_Drt: p=p0_Drt; break;
   case ps_MxP: p=p0_MxP; break;   case ps_Res: p=p0_Res; break;
   case ps_PrB: p=p0_PrB; break;   case ps_PBC: p=p0_PBC; break;
   case ps_Vis: p=p0_Vis; break;   case ps_Con: p=p0_Con; break;
   case ps_SyB: p=p0_SyB; break;   case ps_Cov: p=(Real_void *)p0_Cov; break;
   case ps_assoc: p=(Real_void *)p0_assoc; break;
   case ps_Mos: p=p0_Mos; break;   case ps_Stp: p=p0_Stp; break;
   case ps_Cnt: p=p0_Cnt; break;   case ps_Ref: p=p0_Ref; break;
   case ps_GrX: p=p0_GrX; break;   case ps_GGX: p=p0_GGX; break;
   case ps_MRs: p=p0_MRs; break;   case ps_Cnv: p=p0_Cnv; break;
   case ps_Fin: p=p0_Fin; break;   case ps_Wgt: p=p0_Wgt; break;
   case ps_Gau: p=p0_Gau; break;   case ps_GCv: p=(Real_void *)p0_GCv; break;
   case NOMASK: p=NULL;   break;
   case ps_Sel: p=(Real_void *)p0_Sel; break;
   default:     p=NULL;   break;
   }
#ifndef __CSTAR__
   MosMap=MosMap; MapI=MapI; /* keep lint quiet */
#endif
   return( p );
}

private shape *SelectShape( MosMap, MapI, aShape )
MOSMAP               *MosMap;
ONEMAP               *MapI;
enum shapeselections  aShape;
{
   shape *p;
   switch( aShape ) {
   case Obs_Shape: p=ObsShape; break;
   case Drt_Shape: p=DrtShape; break;
   case PrB_Shape: p=PrBShape; break;
   case Bea_Shape: p=BeaShape; break;
   case Cov_Shape: p=CovShape; break;
   case Mos_Shape: p=MosShape; break;
   case Gau_Shape: p=GauShape; break;
   case GCv_Shape: p=GCvShape; break;
   default:        p=NULL;     break;
   }
   return( p );
}
