/*----------------------------------------------------------------------------
-- mosaic_exch.c --
/*----------------------------------------------------------------------------*/
#include "mosaic.h"
/*----------------------------------------------------------------------------*/

/******************************************************************************/
/* <<< EXCHANGE VARIABLES >>>                         1172 +  548 = 1720 DTM
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*
   Exchange Variables between machines.
*/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*
   ExchangeVariables sends many variables back and forth.

   - It is originally called on the controlling machine.
   - First send a signal to Remote_main to call ExchangeVariables on the remote
     machine, with the proper value of "mode".
   - Depending on the value of "mode", either the local machine is sent to a
     particular signal. The remote machine goes into the receive loop.
   - The local machine will send something, then go to the next signal, until
     it is told to go to "WAIT", which puts it into the receiving loop, or
     "READY", which quits the loop.
   - The remote machine gets a sequence of signals, and does something with
     them. At the last received signal, it sends back "READY" to the active
     machine, which by now is in the wait loop.

   - The Exch... functions consist of a single call to DTMstring. They might
     have been incorporated directly in ExchangeVariables, but are not because
     of readability.

   - In short:
     master: DTMreceive always returns TRUE (because of use of DTMgotoSignal)
             use Exch... with DTMm2s: encode; use DTMwriteMsg to send
                                              (could be failure -> abort)
                at end: goto "WAIT" -> master now receives with DTMreadMsg
                         should receive READY->break loop
             use Exch... with DTMs2m: send signal; use DTMreadMsg to receive
                                              (if wrong->break loop)
                                      then decode
                at end: send "READY"->break loop
      slave: DTMreceive will use DTMreadMsg to read (incl. ABORT)
             use Exch... with DTMm2s: decode; then go back to receiving
                at end: goto "READY" ->break loop (also sends "READY")
             use Exch... with DTMs2m: encode, send with DTMwriteMsg
                                      then go back to receiving
*/
/******************************************************************************/

void ExchangeVariables( mode, MosMap, Maps, Flags, CTRL, Stats )
char    *mode;
MOSMAP  *MosMap;
ONEMAP  *Maps;
logical  Flags[];
CONTROL *CTRL;
STATS   *Stats;
{
   logical      LocallyRun(), DTMmaster(), DTMreceive(), DTMrclass();
   void         DTMsendSignal(), DTMgotoSignal();
   private void ExchCTRL();
   private void ExchMapI(),    ExchMosMap(),    ExchCoords(), ExchRegion();
   private void ExchStats(),   ExchTimers();
           void ExchSavePar(), ExchDatMesLev(), ExchCounts();
   ONEMAP *MapI;
   TRACE("ExchangeVariables");

   if( LocallyRun() ) {
      if( StrEq(mode,"SENDVARS") ) ExchCTRL(Flags,CTRL,Stats);
      return;
   }

   if( DTMmaster() ) {
      DTMsendSignal(mode); /* caught in RemoteMain */
      if( StrEq(mode,"SENDVARS") ) DTMgotoSignal("CTRL");
      if( StrEq(mode,"RESULTS" ) ) DTMgotoSignal("STATS");
      if( StrEq(mode,"TIMERS"  ) ) DTMgotoSignal("TIMERS");
   }
   MapI=NULL;

   while( DTMreceive() ) {
      if(        DTMrclass("CTRL") ) {
         ExchCTRL( Flags, CTRL, Stats );
         if(DTMmaster()) DTMgotoSignal("SAVEPAR");

      } else if( DTMrclass("SAVEPAR") ) {
      	 ExchSavePar();
         if(DTMmaster()) DTMgotoSignal("DATMESLEV");

      } else if( DTMrclass("DATMESLEV") ) {
      	 ExchDatMesLev();
         if(DTMmaster()) DTMgotoSignal("NEXTMAP");


      } else if( DTMrclass("NEXTMAP") ) {
         if(DTMmaster()) {
            MapI = MapI==NULL ? Maps : MapI->NextMap;
            if(MapI!=NULL) { DTMsendSignal("NEXTMAP"); DTMgotoSignal("MAPI"); }
            else                                       DTMgotoSignal("MOSMAP");
         } else {
            if(MapI==NULL) MapI=Maps;
            else { Malloc(MapI->NextMap,ONEMAP,1); MapI=MapI->NextMap; }
            MapI->NextMap = NULL;
         }

      } else if( DTMrclass("MAPI") ) {
         ExchMapI( MapI );
         if(DTMmaster()) DTMgotoSignal("OBSCOO");

      } else if( DTMrclass("OBSCOO") ) {
         ExchCoords( "OBSCOO", &MapI->Observation.Coords );
         if(DTMmaster()&&MapI->IsIFmap) DTMgotoSignal("PRBCOO");
         if(DTMmaster()&&MapI->IsSDmap) DTMgotoSignal("DRTCOO");

      } else if( DTMrclass("DRTCOO") ) {
         ExchCoords( "DRTCOO", &MapI->DirtyMap.Coords );
         if(DTMmaster()) DTMgotoSignal("PRBCOO");

      } else if( DTMrclass("PRBCOO") ) {
         ExchCoords( "PRBCOO", &MapI->PrimaryBeam.Coords );
         if(DTMmaster()&&MapI->IsIFmap) DTMgotoSignal("SYBCOO");
         if(DTMmaster()&&MapI->IsSDmap) DTMgotoSignal("REGION");

      } else if( DTMrclass("SYBCOO") ) {
         ExchCoords( "SYBCOO", &MapI->SynthBeam.Coords );
         if(DTMmaster()) DTMgotoSignal("REGION");

      } else if( DTMrclass("REGION") ) {
         ExchRegion( MapI );
         if(DTMmaster()) DTMgotoSignal("NEXTMAP");


      } else if( DTMrclass("MOSMAP") ) {
         ExchMosMap( MosMap, Flags );
         if(DTMmaster()) DTMgotoSignal("MOSCOO");

      } else if( DTMrclass("MOSCOO") ) {
         ExchCoords( "MOSCOO", &MosMap->MosaicMap.Coords );
         if( DTMmaster()) DTMgotoSignal("GAUCOO");

      } else if( DTMrclass("GAUCOO") ) {
         ExchCoords( "GAUCOO", &MosMap->Gaussian.Coords );
         if( DTMmaster()) DTMgotoSignal("READY");


      } else if( DTMrclass("STATS") ) {
         if( DTMmaster() ) { DTMsendSignal("STATS"); if(!DTMreceive())break; }
         ExchStats( Stats, CTRL );
         if(DTMmaster()) DTMgotoSignal("TIMERS");

      } else if( DTMrclass("TIMERS") ) {
         if( DTMmaster() ) { DTMsendSignal("TIMERS"); if(!DTMreceive())break; }
         ExchTimers();
         if(DTMmaster()) DTMgotoSignal("COUNTS");

      } else if( DTMrclass("COUNTS") ) {
         if( DTMmaster() ) { DTMsendSignal("COUNTS"); if(!DTMreceive())break; }
         ExchCounts();
         if(DTMmaster()) DTMgotoSignal("READY");

      }
   }
}

/******************************************************************************/
/*
   Exchange the control variables.

   CreateDataPointers needs:
     Flags[]
   InitArrays needs:
     Flags[]
     CTRL.TargetChiSq[]
     CTRL.Tolerance
   Calculations calculates:
     CTRL.MaxRatio/ClipFactor/TargetFlux
   Calculations needs:
     Flags[]
     CTRL.EntropyMeasure/TargetFluxes[]/LM0[]/ClipIt/RefOption/RefClip
   Mosaic needs:
     CTRL.SameAsMaxen/Choice_MagicQ/Choice_Norm1/Choice_MagicLM
          Choice_Interpolate/Choice_PosLM
          TargetChiSq[]/TargetFluxes[]
          EntropyMeasure/MaxIters/Tolerance/Epsilon/MaxRatio
          ClipIt/ClipFactor
*/
/******************************************************************************/

private int SAMEAS_MAXEN;
int SameAsMaxen() { return( SAMEAS_MAXEN ); }

private void ExchCTRL( Flags, CTRL, Stats )
logical  Flags[];
CONTROL *CTRL;
STATS   *Stats;
{
   logical LocallyRun(), DTMmaster(), DTMm2s();
   void    DTMexchange();
   void    DTMexchArray();

   if( !LocallyRun() )
   DTMexchange( DTMm2s(), "CTRL", "lllllllllllllllliiiilliiddiiilid",
   /*                              ^               ^     ^   ^  ^     */
   /*                              Flag            C     EM  ^N ^Cl   */
   &Flags[MOSCALC],  &Flags[LINMOS],    &Flags[NOISE],
   &Flags[MAPRES],   &Flags[WRITERES],  &Flags[WRITECNV], &Flags[WRITEFIN],
   &Flags[PBC],
   &Flags[READREF],  &Flags[READINI],
   &Flags[MOSAIC],   &Flags[WRITEMOS],  &Flags[READMOD],  &Flags[READBEAMS],
   &Flags[CALCGAU],  &Flags[FULLSIZE],
   &CTRL->SameAsMaxen,    &CTRL->Choice_MagicQ,      &CTRL->Choice_Norm1,
   &CTRL->Choice_MagicLM, &CTRL->Choice_Interpolate, &CTRL->Choice_PosLM,
   &CTRL->EntropyMeasure,
   &CTRL->MaxIters,       &CTRL->Tolerance,          &CTRL->Epsilon,
   &CTRL->NLM,            &CTRL->N,                  &CTRL->nchan,
   &CTRL->ClipIt,         &CTRL->RefOption,          &CTRL->RefClip );

   if( !DTMmaster() ) {
   Malloc( CTRL->TargetFluxes, double, CTRL->nchan );
   Malloc( CTRL->LM0,          double, CTRL->NLM   ); }
   Malloc( CTRL->TargetChiSq,  double, CTRL->N     );
   Malloc( Stats->ChiSq,       double, CTRL->N     );
   Malloc( Stats->X,           double, CTRL->N     );
   Malloc( Stats->JX,          double, CTRL->NLM   );
   Malloc( Stats->XX,          double, CTRL->NLM * CTRL->NLM );
   Malloc( Stats->LM,          double, CTRL->N     );
   Malloc( Stats->dLM,         double, CTRL->N     );

   CTRL->MaxRatio   = 0.15;
   CTRL->ClipFactor = 0.10;

   SAMEAS_MAXEN = CTRL->SameAsMaxen;

   DTMexchArray( DTMm2s(), CTRL->TargetFluxes, CTRL->nchan );
   DTMexchArray( DTMm2s(), CTRL->LM0,          CTRL->NLM   );
}

/******************************************************************************/
/*
   Exchange the essential variables of the individual maps.

   CreateDataPointers needs:
     MapI.IsIFmap             MapI.IsSDmap
     MapI.Observation.name   (->msg)
     MapI.Observation.Coords (xlen/ylen/nPoints)
     MapI.DirtyMap.Coords    (xlen/ylen/nPoints)
     MapI.DirtyMap.variance
     MapI.PrimaryBeam.Coords (xlen/ylen/nPoints)
     MapI.PB.Telescope        MapI.PB.freqnum
     MapI.SynthBeam.name
     MapI.SynthBeam.Coords   (xlen/ylen/nPoints)
   InitArrays calculates:
     MapI.DirtyMap.weight
     MapI.PB.Q   MapI.PB.npb
     MapI.BM.Q
   InitArrays needs:
     MapI.IsIFmap             MapI.IsSDmap
     MapI.DirtyMap.name      (->msg)
     MapI.DirtyMap.Coords    (xlen/ylen/blc/trc)   (Convert->pdelt/prval/prpix)
     MapI.PrimaryBeam.name   (->msg/sav)
     MapI.SynthBeam.name     (->msg/sav)
     MapI.SynthBeam.Coords   (xlen/ylen/crpix)
     MapI.PB                 (calc: pbtype/cutoff/coeff[]/fwhm
                                    xref/yref/xdelt/ydelt/inverse
                              test: Telescope/freq/LimFreq/freqnum)
   Calculations needs:
     MapI.IsIFmap
     MapI.Observation.Coords (xlen/ylen/blc/trc)
     MapI.DirtyMap.Coords    (xlen/ylen/blc/trc)
     MapI.DirtyMap.variance
     MapI.SynthBeam.Coords   (xlen/ylen)
     MapI.Region.UserString
     MapI.BM.Q
   Mosaic calculates:
     MapI.DirtyMap.mean       MapI.DirtyMap.rms
   Mosaic needs:
     MapI.IsIFmap             MapI.IsSDmap
     MapI.DirtyMap.name      (->msg/sav)
     MapI.DirtyMap.Coords    (xlen/ylen/nPoints)
     MapI.DirtyMap.variance
     MapI.DirtyMap.mean       MapI.DirtyMap.rms (->msg)
     MapI.SynthBeam.Coords   (xlen/ylen)
     MapI.DirtyMap.weight
     MapI.PB.npb
     MapI.BM.Q
     MosMap.RestoringBeam    (bmaj/bmin/bpa->msg)

   Send Is.., names, obs.variance, PB..., BM...
   Send .Region.UserString separately, recalculate Region
   Send .Coords separately
*/
/******************************************************************************/

private void ExchMapI( MapI )
ONEMAP *MapI;
{
   void    DTMexchange();
   logical DTMm2s();
   PBPAR  *PB = &MapI->PB;
   BMPAR  *BM = &MapI->BM;
   DTMexchange( DTMm2s(), "MAPI", "llSSfSSsddiiddddddddddddldddd",
                               /*  ^ ^  ^^^                 ^    */
                               /*  I O  PSpb                sb   */
   &MapI->IsIFmap, &MapI->IsSDmap,
   &MapI->Observation.name,
   &MapI->DirtyMap.name,          &MapI->DirtyMap.variance,
   &MapI->PrimaryBeam.name,
   &MapI->SynthBeam.name,
    PB->Telescope, &PB->freq,     &PB->LimFreq,  &PB->freqnum,
   &PB->pbtype,    &PB->cutoff,
   &PB->coeff[0],  &PB->coeff[1], &PB->coeff[2], &PB->coeff[3], &PB->coeff[4],
   &PB->coeff[5],  &PB->fwhm,
   &PB->xref,      &PB->yref,     &PB->xdelt,    &PB->ydelt,
   &PB->inverse,
   &BM->Q, &BM->bmaj, &BM->bmin, &BM->bpa );
}

private int SetNum=0;
private void ExchRegion( MapI )
ONEMAP  *MapI;
{
   logical DTMmaster(), DTMm2s();
   void    DTMexchange();
   void    keywrite();
   void    RegionDecode();
   REGION *Region = &MapI->Region;
   char    keyword[12];

   if( DTMmaster() ) {
      if( Region->UserString[0]=='\0' ) StrCpy( Region->UserString, "NULL" );
   }
   DTMexchange( DTMm2s(), "REGION", "s", Region->UserString );
   if( !DTMmaster() ) {
      SetNum++;
      if(StrEqX(Region->UserString,"NULL")) {
         Region->UserString[0] = *keyword = '\0';
      } else {
         Sprintf(  keyword, "%s%d", "region", SetNum );
         keywrite( keyword, Region->UserString );
      }
      RegionDecode( keyword, &MapI->Observation.Coords, Region );
   }
}

/******************************************************************************/
/*
   Exchange the essential variables of the mosaiced map.

   CreateDataPointers needs:
     MosMap.MosaicMap.Coords (xlen/ylen/nPoints)
     MosMap.Gaussian.Coords  (xlen/ylen/nPoints)
   InitArrays needs:
     MosMap.MosaicMap.Coords (xlen/ylen/nPoints)   (Convert->pdelt/prval/prpix)
   Calculations calculates:
     MosMap.RestoringBeam.CreatedRB
   Calculations needs:
     MosMap.MosaicMap.name   (->sav)
     MosMap.MosaicMap.Coords (xlen/ylen)
     MosMap.Gaussian.name    (->sav)
     MosMap.Gaussian.Coords  (xlen/ylen/crpix/cdelt)
     MosMap.RestoringBeam    (bmaj/bmin/bpa/CreatedRB)
   Mosaic needs:
     MosMap.MosaicMap.name   (->sav)

   Send name/RestoringBeam
   Send .Coords separately (then recalculate .Gaussian.Coords)
*/
/******************************************************************************/

private void ExchMosMap( MosMap, Flags )
MOSMAP *MosMap;
logical Flags[];
{
   void    DTMexchange();
   logical DTMm2s();
   if( Flags[MOSCALC] ) {
      DTMexchange( DTMm2s(), "MOSMAP", "SSddd",
      &MosMap->MosaicMap.name,
      &MosMap->Gaussian.name,
      &MosMap->RestoringBeam.bmaj, &MosMap->RestoringBeam.bmin,
      &MosMap->RestoringBeam.bpa );
   } else if( Flags[MOSAIC] ) {
      DTMexchange( DTMm2s(), "MOSMAP", "Sddd",
      &MosMap->MosaicMap.name,
      &MosMap->RestoringBeam.bmaj, &MosMap->RestoringBeam.bmin,
      &MosMap->RestoringBeam.bpa );
   }
   MosMap->RestoringBeam.CreatedRB = FALSE;
}

/******************************************************************************/
/*
   Exchange a COORDS struct.
*/
/******************************************************************************/

private void ExchCoords( Class, Coo )
char   *Class;
COORDS *Coo;
{
   void    DTMexchange();
   logical DTMm2s();
   DTMexchange( DTMm2s(), Class, "iiiidddddddddddddddddddd",
   &Coo->nPoints,
   &Coo->axlen[RA_AXIS], &Coo->axlen[DC_AXIS], &Coo->axlen[FQ_AXIS],
   &Coo->crval[RA_AXIS], &Coo->crval[DC_AXIS], &Coo->crval[FQ_AXIS],
   &Coo->crpix[RA_AXIS], &Coo->crpix[DC_AXIS], &Coo->crpix[FQ_AXIS],
   &Coo->cdelt[RA_AXIS], &Coo->cdelt[DC_AXIS], &Coo->cdelt[FQ_AXIS],
   &Coo->cdelt[RA_SEC],
   &Coo->prval[RA_AXIS], &Coo->prval[DC_AXIS], &Coo->prval[FQ_AXIS],
   &Coo->prpix[RA_AXIS], &Coo->prpix[DC_AXIS], &Coo->prpix[FQ_AXIS],
   &Coo->pdelt[RA_AXIS], &Coo->pdelt[DC_AXIS], &Coo->pdelt[FQ_AXIS],
   &Coo->pdelt[RA_SEC] );
   Coo->blc[RA_AXIS]=1;                   Coo->blc[DC_AXIS]=1;
   Coo->trc[RA_AXIS]=Coo->axlen[RA_AXIS]; Coo->trc[DC_AXIS]=Coo->axlen[DC_AXIS];
}

/******************************************************************************/
/*
   Exchange the part of the STATS struct used to write a history file.
   Calculations calculates:
     Stats.Iteration/MagicQ/Scale/Frac/LM[]
   Mosaic calculates:
     Stats.Iteration/MagicQ/Frac/Scale/Clip/modelFlux/S_0/ChiSq[]/rms
           Norm1/OldNormGJ/NormGJ/Norm2GJ
           LM[]/dLM[]/X[]/H/HH/J/JJ/JX/XX
   Mosaic needs:
     Stats.Iteration/MagicQ/Frac/Scale/Clip/modelFlux/S_0/ChiSq[]/rms
           Norm1/OldNormGJ/NormGJ/Norm2GJ
           LM[]/dLM[]/X[]/HH/JJ/JX/XX
   History needs:
     Stats.Iteration/rms/Clip/H/J/ChiSq[]/modelFlux/LM[]/dLM[]/NormGJ/Norm1
     CTRL.TargetFlux/TargetChiSq[] (calc in History/set in init)
*/
/******************************************************************************/

private void ExchStats( Stats, CTRL )
STATS   *Stats;
CONTROL *CTRL;
{
   logical DTMs2m();
   void    DTMexchange();
   void    DTMexchArray();

   DTMexchange( DTMs2m(), "STATS", "iddddddd",
   &Stats->Iteration,  &Stats->rms,
   &Stats->H,          &Stats->J,
   &Stats->modelFlux,  &CTRL->TargetFlux,
   &Stats->NormGJ,     &Stats->Norm1 );

   DTMexchArray( DTMs2m(), Stats->ChiSq,      CTRL->N );
   DTMexchArray( DTMs2m(), CTRL->TargetChiSq, CTRL->N );
   DTMexchArray( DTMs2m(), Stats->LM,         CTRL->N );
   DTMexchArray( DTMs2m(), Stats->dLM,        CTRL->N );
}

/******************************************************************************/
/*
   Exchange the timing information.

   On local machine: If the program is locally run, nothing happens.

   With two cpus:
     on remote machine: get timings and send them over.
     on local machine: receive timings. Then:
       - remote's user and system time for REMOTE_INIT is added to local
         times (LOCAL_INIT); REMOTE_INIT is the time spent in 'InitArrays'.
       - remote's user and system time for CALC is added to local time for
         PLANE and CALC; CALC is the time spent in 'Calculations'.
       - the sum of remote user and system times for REMOTE_INIT and CALC are
         added to TOTAL time.
       - the TOTCALC time is sent over and stored locally.
*/
/******************************************************************************/

private void ExchTimers()
{
   logical LocallyRun(), DTMmaster(), DTMs2m();
   void    DTMexchange();
   void    Timer_Return(), Timer_Increase(), Timer_Reset();
   double  RemInit[3], RemCalc[3], TotCalc[3]; /* 1=elapsed; 2=user; 3=system */

   if( LocallyRun() ) return;

   if( !DTMmaster() ) {
      Timer_Return( "REMOTE_INIT", RemInit );
      Timer_Return( "CALC",        RemCalc );
      Timer_Return( "TOTCALC",     TotCalc );
   }

   DTMexchange( DTMs2m(), "TIMERS", "ddddddd",
                &RemInit[1], &RemInit[2],
                &RemCalc[1], &RemCalc[2],
                &TotCalc[0], &TotCalc[1], &TotCalc[2] );

   if( DTMmaster() ) {
      RemInit[0] = 0.;          Timer_Increase( "LOCAL_INIT", RemInit );
      RemCalc[0] = 0.;          Timer_Increase( "PLANE",      RemCalc );
      RemCalc[0] = 0.;          Timer_Increase( "CALC",       RemCalc );
      RemCalc[1] += RemInit[1];
      RemCalc[2] += RemInit[2]; Timer_Increase( "TOTAL",      RemCalc );
      Timer_Reset("TOTCALC");   Timer_Increase( "TOTCALC",    TotCalc );
   }
}
