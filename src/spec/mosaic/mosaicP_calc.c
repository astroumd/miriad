/*----------------------------------------------------------------------------
-- mosaic_calc.c --
/*----------------------------------------------------------------------------*/
#include "mosaic_arrays.h"
/*----------------------------------------------------------------------------*/

/******************************************************************************/
/* <<< DECONVOLUTION ADMIN >>>                         344 +  157 =  501 DISKIO
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*
   INITIALIZE, DECONVOLVE
*/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*    <<< Abbreviations >>>                              x +    x =    x SETUP
/******************************************************************************/

void OperCount();
#define CINIT 0
#define CFINI 1
#define CCONV 2
#define CCALC 3
#define OpCntM(C,npl,nps,nm,na,nd) \
        TimerStopParallel OperCount(C,MosShape,1,npl,nps,nm,na,nd)
#define OpCntA(C,npl,nps,nm,na,nd) \
        TimerStopParallel OperCount(C,MosShape,0,npl,nps,nm,na,nd)
#define OpCntd(C,npl,nps,nm,na,nd)  \
        TimerStopParallel OperCount(C,DrtShape,0,npl,nps,nm,na,nd)
#define OpCntP(C,npl,nps,nm,na,nd)  \
        TimerStopParallel OperCount(C,PrBShape,0,npl,nps,nm,na,nd)
#define OpCntPs(C,npl,nps,nm,na,nd) \
        TimerStopParallel OperCount(C,PrBShape,1,npl,nps,nm,na,nd)

#define TLI(s) Timer_List("LOCAL_INIT",s)
#define TRI(a) Timer_List("REMOTE_INIT",a);
#define TC(a)  Timer_List("CALC",a);
void Timer_List();

/******************************************************************************/
/*    <<< Plane loop >>>                                63 +   23 =   86 SETUP
/******************************************************************************/
/*
   Do the deconvolution/mosaicing for a particular frequency.
   ReadMaps/WriteResult will send data back and forth, if requested.
   Calculations will run remotely, if requested.
*/
/******************************************************************************/

void DeConvolve( MosMap, Maps, Flags, CTRL, Stats, nPlanes )
MOSMAP  *MosMap;
ONEMAP  *Maps;
logical  Flags[];
CONTROL *CTRL;
STATS   *Stats;
int      nPlanes;
{
   void         Timer_Start(), Timer_End();
   void         Messages_Plane(), Messages_Count();
   private void SetupArrays();
   void         ReadMaps();
   void         Calculations();
   void         WriteResult();
   int          plane;
   char         string[10];
   TRACE("DeConvolve");

   SetupArrays( MosMap, Maps, Flags );

   for( plane=1; plane<=nPlanes; plane++ ) {
      Timer_Start("PLANE");
      Messages_Plane( plane );

      ReadMaps(     MosMap, Maps, Flags,              plane );
      Calculations( MosMap, Maps, Flags, CTRL, Stats, plane );
      WriteResult(  MosMap, Maps, Flags, CTRL, Stats, plane );

      Sprintf(string,"PLANE%d",plane); Timer_End(string);
      Messages_Count();
   }
}

/******************************************************************************/
/*
   Create the arrays and initialize the beams and association array.
   CreateDataPointers and InitArrays may run remotely.
*/
/******************************************************************************/

private void SetupArrays( MosMap, Maps, Flags )
MOSMAP  *MosMap;
ONEMAP  *Maps;
logical  Flags[];
{
   void Timer_End();
   void CreateDataPointers();
   void ReadBeams();
   void InitArrays();

   CreateDataPointers( MosMap, Maps, Flags ); TLI("memory alloc");
   if(Flags[READBEAMS])
   ReadBeams(                  Maps        ); TLI("reading beams");
   InitArrays(         MosMap, Maps, Flags );

   Timer_End("LOCAL_INIT"); /* Started in Initialize */
}


/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*    <<< Initialize arrays >>>                        117 +   58 =  175 SETUP
/******************************************************************************/
/*
   Initialize the primary beam array.
   Return if the beams are not read.
   Initialize the synthesized beam array.
*/
/******************************************************************************/

void InitArrays( MosMap, Maps, Flags )
MOSMAP  *MosMap;
ONEMAP  *Maps;
logical  Flags[];
{
logical DTMremoteExec();
if( DTMremoteExec("INITARRAYS") ) {

           void Timer_Start(), Timer_End();
   private void InitPrB();
   private void InitSyB();
   private void InitAssoc();
   ONEMAP      *MapI;
   TRACE("InitArrays");

   Timer_Start("REMOTE_INIT");

   for( ALLMAPS ) {
                             InitPrB(           MapI        );    TRI("PrB");
      if( Flags[READBEAMS] ) InitSyB(           MapI        );    TRI("SyB");
      if( Flags[MOSAIC] )    InitAssoc( MosMap, MapI, Flags );    TRI("Assoc");
   }

   Timer_End("REMOTE_INIT");

   (void)DTMremoteExec("READY");
}}

/******************************************************************************/
/*
   Initialize an array with the primary beam for a map.
   Use the PrimaryBeam dataset to figure out which pointing center etc to use.
*/
/******************************************************************************/

private void InitPrB( MapI )
ONEMAP *MapI;
{
   void Messages_Init();
   void CheckPrB(), SaveSet();
   void CalculatePB();
   TRACE("InitPrB");

   Messages_Init( "primary beam", MapI->PrimaryBeam.name );

   CalculatePB( &MapI->PB, p0_PrB, PrBShape );

   CheckPrB( MapI );
   SaveSet( "prb", &MapI->PrimaryBeam, -1 );

   if( MapI->IsSDmap ) MapI->BM.Q = MapI->PB.Q;

   MapI->DirtyMap.weight = 1.;
}

/******************************************************************************/
/*
   Fourier transform the beam to prepare for convolutions.
*/
/******************************************************************************/

private void InitSyB( MapI )
ONEMAP *MapI;
{
   void    Messages_Init();
   void    SaveSet();
   int     BeamFT();
   COORDS *BeamCoo;
   TRACE("InitSyB");

   if(MapI->IsIFmap) {
      Messages_Init( "synthesized beam transform", MapI->SynthBeam.name );
      BeamCoo = &MapI->SynthBeam.Coords;
      MapI->MemArr.ftid = BeamFT( p0_SyB, BeaShape, p0_Cov, CovShape,
                          BeamCoo->crpix[RA_AXIS], BeamCoo->crpix[DC_AXIS],
                          BeamCoo->XLEN,           BeamCoo->YLEN           );
      SaveSet( "beam", &MapI->SynthBeam, -1 );
      SaveSet( "cov",  &MapI->SynthBeam, -1 );
   }
   if(MapI->IsSDmap) {
      Messages_Init( "primary beam transform", MapI->PrimaryBeam.name );
      BeamCoo = &MapI->PrimaryBeam.Coords;
      MapI->MemArr.ftid = BeamFT( p0_PrB, PrBShape, p0_Cov, CovShape,
                          BeamCoo->crpix[RA_AXIS], BeamCoo->crpix[DC_AXIS],
                          BeamCoo->XLEN,           BeamCoo->YLEN           );
      SaveSet( "sdbeam", &MapI->PrimaryBeam, -1 );
      SaveSet( "sdcov",  &MapI->PrimaryBeam, -1 );
   }
}

/******************************************************************************/
/*
   Initialize the connection array.

   Calculate the parameters of the connection (each element gives the
   pixel offset in the mosaic map of an input map.
   - The ConvertPixel function returns the pixel number of pixel 0 in the
     observation in the system of the mosaiced map. This is the same as the
     offset of pixel 1. Use the offsets to calculate the origin, i.e. where in
     the mosaiced map the single map starts.
   - Since the assoc numbers represent offsets, as do xorg and yorg, pcoord_x
     and pcoord_y, while x/ymin and x/ymax represent pixel numbers, correct the
     latter to offsets too.
   - The assoc numbers are set negative for pixels outside the inner quarter of
     the input map so that the chi^2 can be calculated on the inner quarter
     only.
*/
/******************************************************************************/

private void InitAssoc( MosMap, MapI, Flags )
MOSMAP  *MosMap;
ONEMAP  *MapI;
logical  Flags[];
{
   void         Messages_Init();
   double       ConvertPixel();
   void         Extent();

   COORDS      *SetCoo, *BeaCoo;
   COORDS      *MosCoo = &MosMap->MosaicMap.Coords;
   register int xorg, yorg, offset, mxlen;
            int xmin, xmax, ymin, ymax;
            int count;

   TRACE("InitAssoc");

   if( MapI->IsIFmap ) {

      Messages_Init( "association", MapI->DirtyMap.name );

      SetCoo = &MapI->DirtyMap.Coords;
      BeaCoo = &MapI->SynthBeam.Coords;

      xorg  = nint(ConvertPixel(ZERO,SetCoo,MosCoo,RA_AXIS));
      yorg  = nint(ConvertPixel(ZERO,SetCoo,MosCoo,DC_AXIS));
      mxlen  = MosCoo->XLEN;
      offset = yorg * mxlen + xorg;

      Extent( SetCoo, BeaCoo, Flags[FULLSIZE], &xmin,&xmax,RA_AXIS );
      Extent( SetCoo, BeaCoo, Flags[FULLSIZE], &ymin,&ymax,DC_AXIS );
      xmin-=1; xmax-=1; ymin-=1; ymax-=1;

      with( *DrtShape ) {
         if( (xmin<=pcoord_x) & (pcoord_x<=xmax) &
             (ymin<=pcoord_y) & (pcoord_y<=ymax)   )
              *p_assoc = pcoord_x + pcoord_y * mxlen + offset;
         else *p_assoc = -1;
      } OpCntd(CINIT,1,0, 18, 9,3);

      count = 0;
      with( *DrtShape ) {
         where( *p_assoc != -1 ) count++;
      }
      DrtShape->nsel = count;
   }
}

/*

/******************************************************************************/
/* <<< CALCULATIONS >>>                                425 +  210 =  635 CALC
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*
   ALL CALCULATIONS EXCEPT FOR MOSAICING ALGORITHM
*/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*    <<< Select Calculation >>>                        63 +   47 =  110 CALC
/******************************************************************************/
/*
   Concentrate all actual calculations here, including setting up the initial
   estimate and reference if they are not read in and calculating the possible
   outputs.
   - If the primary beam correction flag is set, just do that.
   - If the linear mosaic must be made, make it.
   - If the model is read in, calculate the residual if necessary.
   - In other cases: do the non-linear mosaicing.
   - Then restore.
*/
/******************************************************************************/

void Calculations( MosMap, Maps, Flags, CTRL, Stats, plane )
MOSMAP  *MosMap;
ONEMAP  *Maps;
logical  Flags[];
CONTROL *CTRL;
STATS   *Stats;
int      plane;
{
logical DTMremoteExec();
if( DTMremoteExec("CALCULATIONS") ) {

           void CalcTimers();
   private void PrimaryBeamCorrection();
   private void LinearMosaic();
   private void ResetParameters();
   private void InitRefEst();
   private void RegridSD();
           void Mosaic();
   private void Restore();
   TRACE("Calculations");

   CalcTimers(0);
   ResetParameters( MosMap, Maps, CTRL, Stats, plane );

   if(        Flags[PBC] ) {

      PrimaryBeamCorrection( Maps );

   } else if( Flags[LINMOS] ) {

      LinearMosaic( MosMap, Maps, "linmos" );

   } else if( Flags[NOISE] ) {

      LinearMosaic( MosMap, Maps, "noisemap" );

   } else if( Flags[READMOD] ) {

      Restore( MosMap, Maps, Flags, Stats );

   } else if( Flags[MOSCALC] ) {

      InitRefEst( MosMap, Maps, Flags, CTRL, Stats ); CalcTimers(1);
      RegridSD(           Maps                     ); CalcTimers(2);
      Mosaic(     MosMap, Maps,        CTRL, Stats ); CalcTimers(3);
      Restore(    MosMap, Maps, Flags,       Stats ); CalcTimers(4);

   }
   CalcTimers(5);

   (void)DTMremoteExec("READY");
}}

/******************************************************************************/
/*
   Set some parameters that are going to change to initial values.
*/
/******************************************************************************/

private void ResetParameters( MosMap, Maps, CTRL, Stats, plane )
MOSMAP  *MosMap;
ONEMAP  *Maps;
CONTROL *CTRL;
STATS   *Stats;
{
   int     SameAsMaxen();
   int     N;
   ONEMAP *MapI;

   MosArrays(MosMap);

   Stats->Iteration = 0;
   Stats->MagicQ    = ONE;
   Stats->Scale     = 2.; /* so that MagicQ is not changed on 1st iter */
   Stats->Frac      = 1.;

      Stats->LM[LMflx]  = CTRL->LM0[LMflx];
      Stats->dLM[LMflx] = ZERO;
   for( N=LMint, ALLMAPSI, N++ ) {
      Stats->LM[N]      = CTRL->LM0[ MapI->IsIFmap ? LMint : LMsd ];
      Stats->dLM[N]     = ZERO;
   }

   CTRL->TargetFlux         = *(CTRL->TargetFluxes+plane-1);
   CTRL->TargetChiSq[LMflx] = CTRL->TargetFlux;
   Stats->ChiSq[LMflx]      = ZERO;

   for( N=LMint, ALLMAPS, N++ ) {
      CTRL->TargetChiSq[N] = MapI->DirtyMap.Coords.nPoints / 4. *
                             ( SameAsMaxen()<6?1.:MapI->DirtyMap.variance );
      Stats->ChiSq[N] = ZERO;
   }

   Stats->rms = Stats->H = Stats->J = Stats->modelFlux =
   Stats->NormGJ = Stats->Norm1 = ZERO;
}

/*

/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*    <<< Primary Beam correction >>>                   10 +   13 =   23 CALC
/******************************************************************************/
/*
   Calculate the primary beam corrected input map.
*/
/******************************************************************************/

private void PrimaryBeamCorrection( Maps )
ONEMAP *Maps;
{
   void    SaveSet(), History();
   ONEMAP *MapI;
   TRACE("PrimaryBeamCorrection");

   for( ALLMAPS ) {
      with( *DrtShape ) {
         *p_PBC = *p_Drt * *p_PrB;
      } OpCntd(CCALC,1,2, 0, 1,0);
      SaveSet( "pbc", &MapI->PrimaryBeam, -1 );
   }
}

/*

/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*    <<< Linear mosaic >>>                             33 +   17 =   50 CALC
/******************************************************************************/
/*
   Calculate the linear mosaic:
   sum   p_Drt/p_PrB  *  (p_PrB^2/rms^2) / (sum weights)

   Or a map giving the rms across the field:
   sum    rms /p_PrB  *  (p_PrB^2/rms^2) / (sum weights)
*/
/******************************************************************************/

private void LinearMosaic( MosMap, Maps, mode )
MOSMAP *MosMap;
ONEMAP *Maps;
char   *mode;
{
   Real    inv_variance, inv_rms;
   ONEMAP *MapI;
   TRACE("-- LinearMosaic");

   with( *MosShape ) {
      *p_Wgt=ZERO; *p_Mos=ZERO;
   } OpCntA(CCALC,2,0, 0, 0,0);

   for( ALLMAPS ) { if(MapI->IsIFmap) {
      inv_variance = ONE/MapI->DirtyMap.variance;
       with( *PrBShape ) {
         p_Assoc(p0_Wgt) += square(*p_PrB) * inv_variance;
      } OpCntP(CCALC,1,5, 1, 3,0);
   }}

   for( ALLMAPS ) { if(MapI->IsIFmap) {
      if( StrEq( mode, "linmos" ) ) {
        inv_variance = ONE/MapI->DirtyMap.variance;
         with( *PrBShape ) { where(*p_PrB!=0.) {
            p_Assoc(p0_Mos) += *p_Drt * *p_PrB * inv_variance / p_Assoc(p0_Wgt);
         }} OpCntPs(CCALC,1,7, 1, 3,1);
      }
      if( StrEq( mode, "noisemap" ) ) {
         inv_rms = ONE/sqrt(MapI->DirtyMap.variance);
         with( *PrBShape ) { where(*p_PrB!=0.) {
            p_Assoc(p0_Mos) += *p_PrB * inv_rms / p_Assoc(p0_Wgt);
         }} OpCntPs(CCALC,1,6, 1, 2,1);
      }
   }}

   for( ALLMAPS ) { if(MapI->IsSDmap) {
      with(*MosShape) {
         *p_Mos += *p_Drt;
      } OpCntA(CCALC,1,2,0,1,0);
   }}
}

/*

/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*    <<< Init reference/estimate >>>                  193 +   57 =  250 CALC
/******************************************************************************/
/*
   Set up the reference map.
   To fill the reference arrays requires a complex interplay between the
   reference=, initial= and flux= keywords.

   First find the reference array from the primary beams, masks and regions.
   Also find its flux.
   Then find the initial value, from the keywords, and the rms-es.
   Next, the calculated initial value is set, and the reference is scaled.
*/
/******************************************************************************/

private void InitRefEst( MosMap, Maps, Flags, CTRL, Stats )
MOSMAP  *MosMap;
ONEMAP  *Maps;
logical  Flags[];
CONTROL *CTRL;
STATS   *Stats;
{
   void         Messages_Par();
   void         SaveSet();
   private void FindRef(), FindIni();
   private void SetRefIni();
   int          nSelected;
   Real         RefFlux, RefScale;
   Real         IniFlux, MinVal;

   FindRef(MosMap,Maps,Flags,CTRL,&nSelected,&RefFlux);               TC("Ref");

   FindIni(MosMap,Maps,Flags,CTRL,nSelected,RefFlux,&IniFlux,&MinVal);TC("Ini");

   Stats->Clip = CTRL->ClipFactor * MinVal;
   if( CTRL->TargetFlux == ZERO ) CTRL->TargetFlux = -IniFlux;
   RefScale    = fabs(CTRL->TargetFlux) / RefFlux;
   Messages_Par( "Flux in initial map",    IniFlux );
   Messages_Par( "Minimum of initial map", MinVal );
   Messages_Par( "Clip level",             Stats->Clip );
   Messages_Par( "Scale reference with",   RefScale );

   SetRefIni( MosMap, Flags, CTRL, Stats, RefScale, MinVal );         TC("set");


   SaveSet( "ref", &MosMap->MosaicMap, -1 );
}

/******************************************************************************/
/*
   - The reference array may have been read-in before. If so, it may be clipped
     and used, or clipped and made flat. The clipping then in effect defines a
     mask.
   - If the reference was not read in, it may be set to a flat map or to the sum
     of the primary beam attenuations. The reference also defines a mask as the
     merged inner quarters.
   Next, define the model area: for each input map, AND the mask, primary beam,
   reference "mask", and the region keyword. OR those together for different
   input maps.
   Finally, calculate the flux in the reference map. This is used to scale the
   reference map at the end of InitIni, to make the flux equal to that of the
   initial estimate.
*/
/******************************************************************************/

private void FindRef( MosMap, Maps, Flags, CTRL, nSelected, RefFlux )
MOSMAP  *MosMap;
ONEMAP  *Maps;
logical  Flags[];
CONTROL *CTRL;
int     *nSelected;
Real    *RefFlux;
{
   logical_current Inside();
   void            CheckMask(), Messages_Par();
   ONEMAP         *MapI;
   logical         AnyRegion;
   Real            RefMin;      /* local variables so that loops parallelize */
   Real            Clip;
   register int    count=0;
   register Real   flux=ZERO;
   TRACE("-- FindRef");


   if( Flags[READREF] ) {
      Clip = (Real)CTRL->RefClip;
      switch( CTRL->RefOption ) {
      case REF_MAP:     if( CTRL->EntropyMeasure == GULL ) {
                           RefMin=MAX_REAL;
                           with( *MosShape ) {
                              assmin(RefMin,*p_Ref);
                           } OpCntA(CINIT,1,2, 1, 1,0);
                           assert( RefMin>=ZERO,
                                  "Reference dataset not definite positive" );
                        }
                        break;
      case REF_FLAT:
      case REF_CLIPPED: with( *MosShape ) {
                           *p_Ref = *p_Ref>Clip ? *p_Ref : ZERO;
                        } OpCntA(CINIT,1,2, 1, 1,0);
                        break;
      }
   } else {
                        with( *MosShape ) {
                           *p_Ref=ZERO;
                        } OpCntA(CINIT,1,0, 0, 0,0);
      switch( CTRL->RefOption ) {
      case REF_FLAT:    for( ALLMAPS ) { if(MapI->IsIFmap) {
                           with( *PrBShape ) { where(InnerQrt) {
                              p_Assoc(p0_Ref) = ONE;
                           }} OpCntP(CINIT,1,1, 0, 0,0);
                        }}
                        break;
      case REF_PB:      for( ALLMAPS ) { if(MapI->IsIFmap) {
                           with( *PrBShape ) { where(InnerQrt) {
                              p_Assoc(p0_Ref) += *p_PrB;
                           }} OpCntP(CINIT,1,4, 0, 1,0);
                        }}
                        break;
      }
   }

   AnyRegion = FALSE;
   for( ALLMAPS ) { if( MapI->Region.UserString[0] != '\0' ) AnyRegion = TRUE; }

   with( *MosShape ) {
      *p_Sel=FALSE;
   } OpCntA(CINIT,1,0, 0, 0,0);

   for( ALLMAPS ) { if( MapI->IsIFmap ) {
      if( AnyRegion ) {
       if( MapI->Region.UserString[0] != '\0' ) {
         with( *PrBShape ) { where(InnerQrt) {
            p_Assoc(p0_Sel) |=
                 ((*p_PrB!=ZERO) && (p_Assoc(p0_Ref)>ZERO) && (*ip_Msk)
                 && Inside(&MapI->Region,Pcoord_X,Pcoord_Y,p_RegMsk));
         }} OpCntP(CINIT,1,8, 0, 6,0);
       }
      } else {
         with( *PrBShape ) { where(InnerQrt) {
            p_Assoc(p0_Sel) |=
                 ((*p_PrB!=ZERO) && (p_Assoc(p0_Ref)>ZERO) && (*ip_Msk));
         }} OpCntP(CINIT,1,8, 0, 6,0);
      }
   }}

   with( *MosShape ) { where(Selected) {
      count += (int_current)1; flux += *p_Ref;
   }} OpCntM(CINIT,2,1, 2, 2,0);
   MosShape->nsel = *nSelected = count; *RefFlux = flux;

   for(ALLMAPS) CheckMask( MapI, MosMap );

   Messages_Par( "# selected pixels in reference", (Real)count );
   Messages_Par( "Flux of reference map", flux );
   assert( *nSelected != 0, "All pixels were masked out" );
}

/*

/******************************************************************************/
/*
   Set up the initial estimate. How this is done depends on an interplay between
   the reference=, initial= and flux= keywords.

   - If initial estimate must be read from a dataset: use read in map, then:
     a) get flux by summing in selected area, b) find minimum to get clip level
   - If initial estimate must be calculated, it depends on the flux= and
     reference= keywords how it is found. It is a constant in the selected
     region, and zero outside it. The value of the constant is such that the
     flux adds up to the proper value.
     - If flux= was given (>0 or <0), this gives the initial flux
     - If flux= was not given:
       - If reference= was given: the flux is that of the reference image
       - If reference= not given: calculate the average of the (var/Q^2) for
         each map to get the value in the selected region

     nSelected  gives the number of points in the selected area
     RefFlux    gives the sum of the pixels in the reference map

   After leaving the decision making section, Value is the minimum value in the
   map, and Flux is the flux. These are used to find the target flux and the
   cliplevel. Then the clip is applied to p_Mos and pixels outside selected
   areas are set to zero.
*/
/******************************************************************************/

private void FindIni( MosMap,Maps,Flags,CTRL,nSelected,RefFlux,IniFlux,MinVal )
MOSMAP  *MosMap;
ONEMAP  *Maps;
logical  Flags[];
CONTROL *CTRL;
int      nSelected;
Real     RefFlux;
Real    *IniFlux, *MinVal;
{
   ONEMAP        *MapI;
   register Real  Value = MAX_REAL;
   register Real  Flux  = 0.;
   int            Count = 0;
   register Real  avgrms=ZERO;
   TRACE("-- FindIni");

   if( Flags[READINI] ) {
#ifdef mips
#pragma concurrent
#pragma reduction(Flux,Value)
#endif
      with( *MosShape ) { where(Selected) {
         Flux      += *p_Mos;
         assmin(Value,*p_Mos);
      }} OpCntM(CINIT,2,3, 2, 2,0);
      if( CTRL->EntropyMeasure == GULL )
      assert( Value>=ZERO, "Initial estimate dataset not definite positive" );
   } else {
      for( ALLMAPS ) {
         if(MapI->IsIFmap) { /* Interferometer map */
            avgrms += MapI->DirtyMap.variance/square(MapI->BM.Q); Count++;
         }
      } avgrms = sqrt(avgrms/Count);
      if( CTRL->TargetFlux != ZERO ) Flux = (Real)fabs(CTRL->TargetFlux);
      else if( Flags[READREF]      ) Flux = RefFlux;
      else                           Flux = avgrms * nSelected;
      Value = Flux / nSelected;
   }
   assert( Flux != ZERO, "Flux of initial estimate is zero" );

   *IniFlux = Flux;
   *MinVal  = Value;

}

/******************************************************************************/
/*
   Use the results of the calculations of clip and flux parameters to
   initialize the Initial and Reference arrays.

   *p_Metric and *p_Mos (where !Selected) must be zeroed also.
*/
/******************************************************************************/

private void SetRefIni( MosMap, Flags, CTRL, Stats, RefScale, InitVal )
MOSMAP  *MosMap;
logical  Flags[];
CONTROL *CTRL;
STATS   *Stats;
Real     RefScale;
Real     InitVal;
{
   TRACE("SetRefIni");

   if( Flags[READREF] && CTRL->RefOption==REF_FLAT ) {
      Stats->Clip = (Real)CTRL->RefClip;
      with( *MosShape ) {
         *p_Ref = InitVal;
      } OpCntA(CINIT,1,0, 1, 0,0);
   }
   if(         Flags[READINI] &&  Flags[READREF] ) {
      if( CTRL->ClipIt ) { InitClip;
         with( *MosShape ) { where(Selected) { ApplyClip(*p_Mos);    }
                             else            { *p_Mos    = ZERO;
                                               *p_Ref    = ZERO;     }
                                               *p_Metric = ZERO;
         } OpCntA(CINIT,2,1, 1, 1,0); OpCntM(CINIT,1,0,0,0,0); }

   } else if(  Flags[READINI] && !Flags[READREF] ) {
      if( CTRL->ClipIt ) { InitClip;
         with( *MosShape ) { where(Selected) { ApplyClip(*p_Mos);
                                               *p_Ref   *= RefScale; }
                             else            { *p_Mos    = ZERO;
                                               *p_Ref    = ZERO;     }
                                               *p_Metric = ZERO;
         } OpCntA(CINIT,3,0, 0, 0,0); OpCntM(CINIT,0,3, 2,2,0); }

   } else if( !Flags[READINI] &&  Flags[READREF] ) {
         with( *MosShape ) { where(Selected) { *p_Mos    = InitVal;  }
                             else            { *p_Mos    = ZERO;
                                               *p_Ref    = ZERO;     }
                                               *p_Metric = ZERO;
         } OpCntA(CINIT,3,0,0,0,0); OpCntM(CINIT,0,0,1,0,0);

   } else if( !Flags[READINI] && !Flags[READREF] ) {
         with( *MosShape ) { where(Selected) { *p_Mos    = InitVal;
                                               *p_Ref   *= RefScale; }
                             else            { *p_Mos    = ZERO;
                                               *p_Ref    = ZERO;     }
                                               *p_Metric = ZERO;
         } OpCntA(CINIT,3,0,0,0,0); OpCntM(CINIT,0,1,2,1,0);
   }
}

/*

/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*    <<< Create single-dish observation >>>           126 +   60 =  186 CALC
/******************************************************************************/
/*
   Regrid the single-dish map to the mosaic grid

   Spread out an single-dish pointing, using sinc weighting, with first zero
   at one gridspacing in original read-in image.

   Argument of sinc is (scale)*(X), with X # of pixels in new grid
   First zero is at X = dx_old/dx_new
   So: sinc( X = dx_old/dx_new*scale ) = 0
   Thus dx_old/dx_new*scale = pi => scale = pi*dx_new/dx_old
   Do the interpolation out to two old gridspacings: X < 2 dx_old/dx_new
   I.e, argument of sinc < 2pi
*/
/******************************************************************************/

extern double_current sinc();
#ifdef mips
#pragma no side effects (sinc)
#endif

private void RegridSD( Maps )
ONEMAP *Maps;
{
   void       SaveSet();
   double     ConvertPixel();
   ONEMAP    *MapI;
   COORDS    *ObsCoo, *DrtCoo;
   int        x, y;
   Real       InpObs;
   int        xref,   yref;
   double     xscale, yscale;
   Real_void *dx, *dy;
   TRACE("RegridSD");

   for( ALLMAPS ) { if( MapI->IsSDmap ) {

      ObsCoo = &MapI->Observation.Coords;
      DrtCoo = &MapI->DirtyMap.Coords;

      dx = (Real_void *)p0_Res;
      dy = (Real_void *)p0_oRes;

      with( *DrtShape ) { *p_Drt = ZERO; } OpCntd(CCALC,1,0, 0, 0,0);

      for( y=0; y<ObsCoo->YLEN; y++ ) { for( x=0; x<ObsCoo->XLEN; x++ ) {

         InpObs = *( p0_Obs + y*ObsCoo->XLEN + x );
         xref   = nint(ConvertPixel((double)(x+1),ObsCoo,DrtCoo,RA_AXIS));
         yref   = nint(ConvertPixel((double)(y+1),ObsCoo,DrtCoo,DC_AXIS));
         xscale = M_PI * DrtCoo->cdelt[RA_AXIS] / ObsCoo->cdelt[RA_AXIS];
         yscale = M_PI * DrtCoo->cdelt[DC_AXIS] / ObsCoo->cdelt[DC_AXIS];

         with( *DrtShape ) {
            *p_arr(dx) = (pcoord_x-xref) * xscale; where( *p_arr(dx)<M_TWOPI ) {
            *p_arr(dy) = (pcoord_y-yref) * yscale; where( *p_arr(dy)<M_TWOPI ) {
            *p_Drt += sinc(p_arr(dx)) * sinc(p_arr(dy)) * InpObs; }}
         } OpCntd(CCALC,3,1, 10, 8,4+2*20);

      }}

      SaveSet( "sdobs", &MapI->DirtyMap, -1 );
   }}
}

/*

/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*    <<< Calculate outputs >>>                        126 +   60 =  186 CALC
/******************************************************************************/
/*
   Then set the mosaic pointers in this file. And also in the mosaicP_mem.c
   file, to be able to calculate the residual.

   If needed, recalculate the mask array, since it is not found automatically
   when the [READMOD] option is used.

   Calculate the residual, if necessary.

   Save it, if asked for.

   Then the final residual, convolved model and final are calculated if asked
   for.
*/
/******************************************************************************/

private void Restore( MosMap, Maps, Flags, Stats )
MOSMAP  *MosMap;
ONEMAP  *Maps;
logical  Flags[];
STATS   *Stats;
{
           void  InitMosArrays();
           void  SaveSet();
           void  CalcResiduals();
   private void  ConvolveModel();
   private void  ConstructResidual();
   private void  ConstructFinal();
         ONEMAP *MapI;
   TRACE("Restore");

   MosArrays(MosMap);

   if( Flags[READMOD] ) {
   with(*MosShape) { *p_Sel = *p_Mos != ZERO ? TRUE : FALSE; }
   OpCntM(CFINI,1,1,0,1,0); }

   if( Flags[MAPRES] | Flags[WRITEFIN] | Flags[WRITERES] ) {
   InitMosArrays(MosMap);
   CalcResiduals( Stats, MosMap, Maps, FALSE ); }

   if( Flags[MAPRES] ) {
   for(ALLMAPS) SaveSet( "res", &MapI->DirtyMap, Stats->Iteration ); }

   if( Flags[WRITECNV] )      ConvolveModel(     MosMap              );
   if( Flags[WRITEFIN] ) {
       if( !Flags[WRITECNV] ) ConvolveModel(     MosMap              );
                              ConstructResidual( MosMap, Maps, TRUE  );
                              ConstructFinal(    MosMap              ); }
   if( Flags[WRITERES] )      ConstructResidual( MosMap, Maps, FALSE );
}

/*

/******************************************************************************/
/*
   Convolve the model with a clean beam, stored in MosMap.RestoringBeam.
   First create an array with the gaussian restoring beam, then apply the
   convolution.
*/
/******************************************************************************/

private void ConvolveModel( MosMap )
MOSMAP *MosMap;
{
   private void  GaussCreate();
   void          Convolution();
   COORDS       *MosCoo = &MosMap->MosaicMap.Coords;
   COORDS       *GauCoo = &MosMap->Gaussian.Coords;
   TRACE("-- ConvolveModel");

   if( !MosMap->RestoringBeam.CreatedRB ) {
      GaussCreate( MosMap );
      MosMap->RestoringBeam.CreatedRB = ( p0_Gau != p0_GrX );
   }

   Convolution( MosMap->MemArr.gauftid,
                p0_Cnv, p0_Mos, MosShape, p0_GCv, GCvShape,
                MosCoo->XLEN, MosCoo->YLEN, GauCoo->XLEN, GauCoo->YLEN );
}

/*

/******************************************************************************/
/*
   Add the convolved and residual maps
*/
/******************************************************************************/

private void ConstructFinal( MosMap )
MOSMAP  *MosMap;
{
   TRACE("-- ConstructFinal");
   with( *MosShape ) {
      *p_Fin = *p_Cnv + *p_MRs;
   } OpCntA(CFINI,1,2, 0, 1,0);
}

/*

/******************************************************************************/
/*
   Make a total residual map.

   Also apply the primary beam correction to the residual. This makes the
   weight: pbcorr/variance; and the final residual is:
   p_MRs = p_Res/p_PrB  *  (p_PrB**2/variance) / (sum weights)

   if PBcorr=FALSE don't apply the primary beam correction:
   p_MRs =    p_Res     *       ( 1 /variance) / (sum weights )
*/
/******************************************************************************/

private void ConstructResidual( MosMap, Maps, PBcorrec )
MOSMAP  *MosMap;
ONEMAP  *Maps;
logical  PBcorrec;
{
   Real    inv_variance;
   ONEMAP *MapI;
   TRACE("-- ConstructResidual");

   with( *MosShape ) {
      *p_Wgt=ZERO; *p_MRs=ZERO;
   } OpCntA(CFINI,2,0, 0, 0,0);

   for( ALLMAPS ) { if(MapI->IsIFmap) {
      inv_variance = ONE/MapI->DirtyMap.variance;
      if( PBcorrec ) {
         with( *PrBShape ) { where(InnerQrt) {
            p_Assoc(p0_Wgt) += square(*p_PrB) * inv_variance;
         }} OpCntP(CFINI,1,5, 1, 3,0);
      } else {
         with( *DrtShape ) { where(InnerQrt) {
            p_Assoc(p0_Wgt) +=                  inv_variance;
         }} OpCntd(CFINI,1,3, 1, 1,0);
      }
   }}

   for( ALLMAPS ) { if(MapI->IsIFmap) {
      inv_variance = ONE/MapI->DirtyMap.variance;
      if( PBcorrec ) {
         with( *PrBShape ) { where(InnerQrt && *p_PrB!=0) {
            p_Assoc(p0_MRs) += *p_Res * *p_PrB * inv_variance / p_Assoc(p0_Wgt);
         }} OpCntP(CFINI,1,7, 1, 3,1);
      } else {
         with( *DrtShape ) { where(InnerQrt) {
            p_Assoc(p0_MRs) += *p_Res          * inv_variance / p_Assoc(p0_Wgt);
         }} OpCntd(CFINI,1,6, 1, 2,1);
      }
   }}
}

/*

/******************************************************************************/
/*
   Put the values of the smoothing gaussian in an array. The gaussian is
   centered in this array.
   BeamFT transforms the gaussian.
*/
/******************************************************************************/

private void GaussCreate( MosMap )
MOSMAP *MosMap;
{
   void                Messages_BM();
   void                SaveSet();
   int                 BeamFT();
   DATASET            *GauSet = &MosMap->Gaussian;
   COORDS             *GauCoo = &GauSet->Coords;
   BMPAR              *RestBm = &MosMap->RestoringBeam;
   int                 xlen, ylen;
   double              xref, yref;
   register Real       dx_s_pa, dx_c_pa, dy_s_pa, dy_c_pa, f_xc, f_yc;
   register Real_void *p_x, *p_y;
   Real               *GetScrAddress();
   TRACE("-- GaussCreate");

   xlen    = GauCoo->XLEN;             ylen = GauCoo->YLEN;
   xref    = GauCoo->crpix[RA_AXIS];   yref = GauCoo->crpix[DC_AXIS];
   dx_s_pa =  sin(RestBm->bpa) * GauCoo->cdelt[RA_AXIS] / RestBm->bmaj;
   dx_c_pa = -cos(RestBm->bpa) * GauCoo->cdelt[RA_AXIS] / RestBm->bmin;
   dy_s_pa =  sin(RestBm->bpa) * GauCoo->cdelt[DC_AXIS] / RestBm->bmin;
   dy_c_pa =  cos(RestBm->bpa) * GauCoo->cdelt[DC_AXIS] / RestBm->bmaj;
   f_xc    = -( xref * dx_s_pa + yref * dy_c_pa );
   f_yc    = -( xref * dx_c_pa + yref * dy_s_pa );

   p_x = (Real_void *)(p0_Gau);
#ifdef __CSTAR__
   p_y = (Real_void *)(p0_GCv);
#else
   p_y = (Real_void *)(GetScrAddress());
#endif

   with( *GauShape ) {
      *p_arr(p_x) = pcoord_x * dx_s_pa + pcoord_y * dy_c_pa + f_xc;
      *p_arr(p_y) = pcoord_x * dx_c_pa + pcoord_y * dy_s_pa + f_yc;
      pEXP( *p_Gau, -FOURLN2 * ( square(*p_arr(p_x)) + square(*p_arr(p_y)) ) );
   } OperCount(CINIT,GauShape,0, 3,4, 15, 12+80,4); /*80=exp*/
   SaveSet( "gauss", GauSet, -1 );

   MosMap->MemArr.gauftid = BeamFT( p0_Gau, GauShape, p0_GCv, GCvShape,
                                    xref, yref, xlen, ylen );

   Messages_BM( "Gaussian convolving beam: ", RestBm );
}
