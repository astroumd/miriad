/*----------------------------------------------------------------------------
-- mosaic_mem.c --
/*----------------------------------------------------------------------------*/
#include "mosaic_arrays.h"
/*----------------------------------------------------------------------------*/

/******************************************************************************/
/* <<< MOSAICING >>>                                   630 +  253 =  883 MOSAIC
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*
   MEM LOOP
*/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*    <<< Mosaic Loop >>>                               63 +   22 =   85 MOSAIC
/******************************************************************************/
/*
   Do the mosaicing algorithm:
   loop over:
   - calculate residuals
   - determine gradient of X
   - determine gradient of H
   - determine gradient of J
   - check if interpolation needed; return TRUE if so
   - check if Q changes; return TRUE if so
   - if interpolation: recalculate residual, GradX, GradH, GradJ
   - if Q changes: recalculate GradJ
   - determine metric
   - determine new parameters
   - save the current estimate (after interpolation; this means: save initial
     estimate on first iteration)
   - check convergence
   - adapt estimate
*/
/******************************************************************************/

enum EntSel { GRADH, GRADJ, METRIC, GRADHJM, GRADHJ, GRADJM };

int SameAsMaxen();
void OperCount();
#define CCALC 3
#define OpCntM(npl,nps,nm,na,nd) \
        TimerStopParallel OperCount(CCALC,MosShape,1,npl,nps,nm,na,nd)
#define OpCntA(npl,nps,nm,na,nd) \
        TimerStopParallel OperCount(CCALC,MosShape,0,npl,nps,nm,na,nd)
#define OpCntd(npl,nps,nm,na,nd) \
        TimerStopParallel OperCount(CCALC,DrtShape,0,npl,nps,nm,na,nd)
#define OpCntI(npl,nps,nm,na,nd) \
        TimerStopParallel OperCount(CCALC,DrtShape,1,npl,nps,nm,na,nd)
#define OpCntP(npl,nps,nm,na,nd) \
        TimerStopParallel OperCount(CCALC,PrBShape,0,npl,nps,nm,na,nd)

/*#define TLP(s)      Timer_List("LOOP",s);*/
#define TLP(s)
#define Timer_Iter(s) Timer_List("LOOP",s);

void InitMosArrays(MosMap) MOSMAP *MosMap; { MosArrays(MosMap); }

void Mosaic( MosMap, Maps, CTRL, Stats )
MOSMAP  *MosMap;
ONEMAP  *Maps;
CONTROL *CTRL;
STATS   *Stats;
{
   void             Timer_Start(), Timer_List();
   void             Messages_Iter();
   void             Messages_Step();
   void             Messages_rms();
   void             SaveSet();

   void             CalcResiduals();
   private void     CalcGradX();
   private void     CalcGradGradX();
   private void     Entropy();
   enum Measures    EntM = CTRL->EntropyMeasure;
   private logical  C, CorrectStep();
   private logical  Q, MagicQ();
   private void     MultiplierSteps();
   private logical  Converge(); logical Converged=FALSE;
   private void     TakeStep();
   ONEMAP          *MapI;
   logical          MORE = TRUE;
   TRACE("Mosaic");

   InitMosArrays(MosMap);

   while( MORE ) {
      Timer_Start("LOOP");

      Stats->Iteration++;
      Messages_Iter(   CTRL, Stats,         Maps );

      CalcResiduals(         Stats, MosMap, Maps, FALSE ); TLP("Residual");
      CalcGradX(             Stats, MosMap, Maps, FALSE ); TLP("GradX");
      Entropy( GRADHJ, EntM, Stats, MosMap              ); TLP("GradHJ");

      C = CorrectStep( CTRL, Stats, MosMap              ); TLP("Correct");

      CalcGradGradX(                MosMap, Maps        );
      Q = MagicQ(      CTRL, Stats                      );

      if( C ) {
        CalcResiduals(       Stats, MosMap, Maps, TRUE  ); TLP("C-Resid");
        CalcGradX(           Stats, MosMap, Maps, TRUE  ); TLP("C-GradX");
        Entropy(GRADHJM,EntM,Stats, MosMap              );
      } else {
        if( Q )
        Entropy(GRADJM, EntM,Stats, MosMap              );
        else
        Entropy(METRIC, EntM,Stats, MosMap              );
      }                                                    TLP("GradXX");

      MultiplierSteps( CTRL, Stats, MosMap              ); TLP("LM");


      Messages_Step(   CTRL, Stats                      );
      SaveSet( "est", &MosMap->MosaicMap, Stats->Iteration );

      Converged =
          Converge (   CTRL, Stats                      );

      MORE = !Converged && Stats->Iteration < CTRL->MaxIters;

      if(MORE)TakeStep(CTRL, Stats, MosMap              );

      Timer_Iter("Iteration ----------------------------------------");
   }

   Messages_rms( Maps );
}

/*

/******************************************************************************/
/*    <<< Entropy >>>                                   95 +   11 =  106 MOSAIC
/******************************************************************************/
/*
   Calculate entropy from estimate and reference and set the gradient arrays.
*/
/******************************************************************************/

#define EntFunGull    *p_Mos * ( *p_GradH + ONE )
#define EntDer1Gull   -log( *p_Mos / *p_Ref )
#define EntDer2Gull   -1. / *p_Mos
#define EntFunCorn    -log( cosh( *p_Mos / *p_Ref ) )
#define EntDer1Corn   -tanh( *p_Mos / *p_Ref ) / *p_Ref
#define EntDer2Corn   square(*p_GradH) - square(1. / *p_Ref)

private void Entropy( ENTSEL, EntropyMeasure, Stats, MosMap )
enum EntSel   ENTSEL;
enum Measures EntropyMeasure;
STATS        *Stats;
MOSMAP       *MosMap;
{
   Real alpha = (Real)Stats->LM[LMint];
   Real beta  = (Real)Stats->LM[LMflx];
   Real alpQ  = (Real)(Stats->LM[LMint] * Stats->MagicQ);
   TRACE("Entropy");

   switch( ENTSEL ) {
   case GRADH:
      switch( EntropyMeasure ) {
      case GULL: with( *MosShape ) { where(Selected) {
      	            *p_GradH = EntDer1Gull;
      	         }} OpCntM(1,2, 0, 0+74,1); /*74=log*/ break;
      case CORN: with( *MosShape ) { where(Selected) {
                    *p_GradH = EntDer1Corn;
                 }} OpCntM(1,3, 0, 100,2); /*100=tanh*/ break;
      }
      break;
   case GRADJ:
                               {
                 with( *MosShape ) { where(Selected) {
                    *p_GradJ = *p_GradH - alpha * *p_GradX - beta;
                 }} OpCntM(1,3, 2, 3,0);
      }
      break;
   case METRIC:
      switch( EntropyMeasure ) {
      case GULL: with( *MosShape ) { where(Selected) {
                    *p_DelJ  = EntDer2Gull - alpQ * *p_GGX;
                    where( *p_DelJ != 0. ) *p_Metric = -ONE / *p_DelJ;
      	         }} OpCntM(2,4, 2, 4,2); break;
      case CORN: with( *MosShape ) { where(Selected) {
                    *p_DelJ  = EntDer2Corn - alpQ * *p_GGX;
                    where( *p_DelJ != 0. ) *p_Metric = -ONE / *p_DelJ;
                 }} OpCntM(2,7, 1, 6,3); break;
      }
      break;
   case GRADHJ:
      switch( EntropyMeasure ) {
      case GULL: with( *MosShape ) { where(Selected) {
      	            *p_GradH = EntDer1Gull;
                    *p_GradJ = *p_GradH - alpha * *p_GradX - beta;
      	         }} OpCntM(2,4, 2, 4+74,1);  /*74=log*/ break;
      case CORN: with( *MosShape ) { where(Selected) {
                    *p_GradH = EntDer1Corn;
                    *p_GradJ = *p_GradH - alpha * *p_GradX - beta;
                 }} OpCntM(2,5, 2, 4+100,2); /*100=tanh*/ break;
      }
      break;
   case GRADJM:
      switch( EntropyMeasure ) {
      case GULL: with( *MosShape ) { where(Selected) {
                    *p_GradJ = *p_GradH - alpha * *p_GradX - beta;
                    *p_DelJ  = EntDer2Gull - alpQ * *p_GGX;
                    where( *p_DelJ != 0. ) *p_Metric = -ONE / *p_DelJ;
      	         }} OpCntM(3,6, 3, 6,2); break;
      case CORN: with( *MosShape ) { where(Selected) {
                    *p_GradJ = *p_GradH - alpha * *p_GradX - beta;
                    *p_DelJ  = EntDer2Corn - alpQ * *p_GGX;
                    where( *p_DelJ != 0. ) *p_Metric = -ONE / *p_DelJ;
                 }} OpCntM(3,9, 3, 9,3); break;
      }
      break;
   case GRADHJM:
      switch( EntropyMeasure ) {
      case GULL: with( *MosShape ) { where(Selected) {
      	            *p_GradH = EntDer1Gull;
                    *p_GradJ = *p_GradH - alpha * *p_GradX - beta;
                    *p_DelJ  = EntDer2Gull - alpQ * *p_GGX;
                    where( *p_DelJ != 0. ) *p_Metric = -ONE / *p_DelJ;
      	         }} OpCntM(4,8, 3, 7+74,3); /*74=log*/ break;
      case CORN: with( *MosShape ) { where(Selected) {
                    *p_GradH = EntDer1Corn;
                    *p_GradJ = *p_GradH - alpha * *p_GradX - beta;
                    *p_DelJ  = EntDer2Corn - alpQ * *p_GGX;
                    where( *p_DelJ != 0. ) *p_Metric = -ONE / *p_DelJ;
                 }} OpCntM(4,12, 3,9+100,5); /*100=tanh*/ break;
      }
      break;
   }

   return;
}

/*

/******************************************************************************/
/*    <<< Calculate residuals, GradX >>>               120 +   38 =  158 MOSAIC
/******************************************************************************/
/*
   - Predict the observations, obtain the residuals, calculate GradX.

   - For interferometer maps an extraction is done, consisting of applying the
     primary beam correction to part of the model.
   - Perform the convolution with the beam.
   - Subtract the observation and save in a residual map.
   - There are two modes:
     a) on first pass: do the convolution; start with saving the old residuals
        by changing the pointer; then convolve.
     b) on possible second pass: interpolate old and new residual.
*/
/******************************************************************************/

void CalcResiduals( Stats, MosMap, Maps, Interpolate )
STATS   *Stats;
MOSMAP  *MosMap;
ONEMAP  *Maps;
logical  Interpolate;
{
   void         CheckExtr(), CheckRes();
   void         SaveSet();
   void         Convolution();
   private void Interpolation();
   ONEMAP      *MapI;
   Real        *Model;
   int          mxlen, mylen, bxlen, bylen;
   TRACE("CalcResiduals");

   if( !Interpolate ) SwapResArrays(Maps);

   for( ALLMAPS ) {

      if( !Interpolate ) {

         if( MapI->IsIFmap ) { /* Interferometer map */
            with( *DrtShape ) {
               *p_MxP = (InnerQrt?p_Assoc(p0_Mos):ZERO) * *p_PrB;
            } OpCntd(1,4, 0, 2,0);
            Model = p0_MxP;
            bxlen = MapI->SynthBeam.Coords.XLEN;
            bylen = MapI->SynthBeam.Coords.YLEN;
         } else { /* Single-dish map */
            Model = p0_Mos;
            bxlen = MapI->PrimaryBeam.Coords.XLEN;
            bylen = MapI->PrimaryBeam.Coords.YLEN;
         }
         CheckExtr( MapI, MosMap );
         mxlen = MapI->DirtyMap.Coords.XLEN;
         mylen = MapI->DirtyMap.Coords.YLEN;

         Convolution( MapI->MemArr.ftid,
                      p0_Con, Model, DrtShape, p0_Cov, CovShape,
                      mxlen, mylen, bxlen, bylen );

         SaveSet( "conv", &MapI->DirtyMap, Stats->Iteration );
         CheckRes( MapI );

         with( *DrtShape ) {
            *p_Res = *p_Drt - *p_Con;
         } OpCntd(1,2, 0, 1,0);

      } else {

         Interpolation( p0_Res, p0_Res, p0_oRes, (logical_void *)NULL, DrtShape,
                        Stats->Frac, FALSE, 0. );

      }

      if(!Interpolate) SaveSet( "res_iter", &MapI->DirtyMap, Stats->Iteration );
                       SaveSet( "res_int",  &MapI->DirtyMap, Stats->Iteration );
   }
}

/******************************************************************************/
/*
   Make the residuals into the gradient of Chi^2, and calculate Chi^2 itself.

   To get GradX, multiply residual by 2*Q*primary_beam/variance.
*/
/******************************************************************************/

private void CalcGradX( Stats, MosMap, Maps, Interpolate )
STATS   *Stats;
MOSMAP  *MosMap;
ONEMAP  *Maps;
logical  Interpolate;
{
   void           Messages_ChiSq();
   void           CheckGrX(), SaveSet();
   ONEMAP        *MapI;
   DATASET       *Set;
   int            N;
   register Real  nPnt, variance, weight, TwoWQ_v;
   register Real  sum, sumsq, tsumsq=ZERO, totnPnt=ZERO;
   TRACE("CalcGradX");

   with( *MosShape ) {
      *p_GrX=ZERO;
   } OpCntA(1,0, 0, 0,0);

   for( N=LMint, ALLMAPS, N++ ) {

      Set      = &MapI->DirtyMap;
      nPnt     = Set->Coords.nPoints / 4.;
      variance = Set->variance;
      weight   = Set->weight;
      TwoWQ_v  = -2. * weight * MapI->BM.Q*sqrt(Stats->MagicQ) / variance;

      sum = sumsq = 0.;
      if( MapI->IsIFmap ) {
         with( *DrtShape ) { where(InnerQrt) {
            sum += *p_Res; sumsq += square(*p_Res);
         }} OpCntI(2,3, 2, 3,0);
      } else {
         with( *DrtShape ) {
            sum += *p_Res; sumsq += square(*p_Res);
         } OpCntI(2,3, 2, 3,0);
      }
      Messages_ChiSq( MapI, sum, sumsq, Stats->MagicQ );

      tsumsq         += weight * sumsq;
      totnPnt        += weight * nPnt;
      Stats->ChiSq[N] = weight * sumsq * (SameAsMaxen()<6?ONE/variance:ONE);
      Set->mean       = sum / nPnt;
      Set->rms        = nPnt>1. ? sqrt( ( sumsq - sum*sum/nPnt ) / (nPnt-1.) )
                                : sqrt(   sumsq / variance   );

      if( MapI->IsIFmap ) {
         with( *PrBShape ) { where(InnerQrt) {
            p_Assoc(p0_GrX) += TwoWQ_v * *p_Res * *p_PrB;
         }} OpCntI(1,5, 1, 3,0);
      } else {
         with( *DrtShape ) {
                    *p_GrX  += TwoWQ_v * *p_Res;
         } OpCntI(1,3, 1, 2,0);
      }
   }

   Stats->rms = sqrt( tsumsq / totnPnt );

   CheckGrX( MosMap );
   if(!Interpolate) SaveSet( "gradx",    &MosMap->MosaicMap,Stats->Iteration );
                    SaveSet( "gradx_int",&MosMap->MosaicMap,Stats->Iteration );

}

/*

/******************************************************************************/
/*
   Initialize the array with the second derivative of chi^2.
*/
/******************************************************************************/

private logical Have_GradGradX = FALSE;
private void CalcGradGradX( MosMap, Maps )
MOSMAP  *MosMap;
ONEMAP  *Maps;
{  if( !Have_GradGradX ) {

   void    Messages_Init();
   void    CheckGGX(), SaveSet();
   ONEMAP *MapI;
   Real    TwoWQ2_v;
   TRACE("CalcGradGradX");

   with( *MosShape ) {
      *p_GGX=ZERO;
   } OpCntA(1,0, 0, 0,0);

   for( ALLMAPS ) {
      Messages_Init( "second gradient map", MapI->DirtyMap.name );

      TwoWQ2_v = 2. * MapI->DirtyMap.weight * square(MapI->BM.Q)
                    * (SameAsMaxen()<6?ONE/MapI->DirtyMap.variance:ONE);

      if( MapI->IsIFmap ) {
         with( *PrBShape ) { where(InnerQrt) {
            p_Assoc(p0_GGX) += TwoWQ2_v * square(*p_PrB);
         }} OpCntI(1,5, 1, 3,0);
      } else {
         with( *DrtShape ) {
            *p_GGX          += TwoWQ2_v;
         } OpCntI(1,3, 1, 1,0);
      }
      CheckGGX( MapI, MosMap );
   }
   SaveSet( "ggradx", &MosMap->MosaicMap, -1 );
   Have_GradGradX = TRUE;
}}

/*

/******************************************************************************/
/*    <<< Correct Step >>>                              40 +   36 =   76 MOSAIC
/******************************************************************************/
/*
   Correct the step taken for overshooting introduced by the approximations for
   GradX and GradGradX.
   S_0  is GradJ.GradJ for the step taken earlier, corrected for the possible
        scaling back of the step. This was calculated in routine LimitStep.
   S_1  is GradJold.GradJ_new, i.e. the inner product of the old with the new
        GradJ vectors.
   Frac is the fraction of the step that should have been taken to make the
        function GradJold.GradJ zero (if things were linear).
   If Frac is small (0<f<0.9) correct the step just taken back by interpolating
   between the old and new images.

   After doing the interpolation of the model, also interpolate the residuals
   and recalculate the gradient of J.
*/
/******************************************************************************/

private logical CorrectStep( CTRL, Stats, MosMap )
CONTROL *CTRL;
STATS   *Stats;
MOSMAP  *MosMap;
{
   void          Messages_Par();
   void          Messages_Scaling();
   void          CheckS1(), CheckInt();
   private void  Interpolation();

   Real          S_0;
   register Real S_1;

   if( !CTRL->Choice_Interpolate ) return FALSE;
   if( Stats->Iteration == 1     ) return FALSE;
   TRACE("CorrectStep");

   S_0 = (Real)Stats->S_0;
   S_1 = ZERO;
   with( *MosShape ) { where(Selected) {
      S_1 += ( *p_Mos - *p_oMos ) * *p_GradJ;
   }} OpCntM(0,3, 2, 3,0);
   CheckS1( MosMap );

   Stats->Frac = S_1 != S_0 ? S_0 / ( S_0 - S_1 ) : ONE;

   Messages_Par( "The sum S_0", S_0 );
   Messages_Par( "The sum S_1", S_1 );
   Messages_Par( "Interpolation fraction", Stats->Frac );

   if( between(ZERO,Stats->Frac,0.95) ) {

      Messages_Scaling( Stats->Scale, Stats->Frac, TRUE );
      CheckInt( MosMap, Stats->Frac );

      Interpolation( p0_Mos, p0_Mos, p0_oMos, p0_Sel, MosShape,
                     Stats->Frac, CTRL->ClipIt, Stats->Clip );
   }

   return( between(ZERO,Stats->Frac,0.95) );
}

/*

/******************************************************************************/
/*    <<< New Parameters >>>                           215 +   79 =  294 MOSAIC
/******************************************************************************/
/*
   Apply the magic formula for the change in Q.
*/
/******************************************************************************/

private logical MagicQ( CTRL, Stats )
CONTROL *CTRL;
STATS   *Stats;
{
   void Messages_Par();
   switch( CTRL->Choice_MagicQ ) {
   case 1:  if( fabs(Stats->Scale-ONE) < CTRL->Tolerance ) {
                Stats->MagicQ *= ( ONE /
                                   max( 0.5,min(2.,Stats->Frac ) ) + 3.
                                  ) / 4.;
            }
            Messages_Par( "Magic Q factor", (Real)Stats->MagicQ );
            return( fabs(Stats->Scale-ONE) < CTRL->Tolerance );
   default: break;
   }
   return FALSE;
}

/******************************************************************************/
/*
   Interpolate between array A1 and A2, possible in limited area, possibly clip.
*/
/******************************************************************************/

private void Interpolation( A0, A1, A2, Select, aShape, Frac, ClipIt, Clip )
Real_void    *A0, *A1, *A2;
logical_void *Select;
shape        *aShape;
Real          Frac;
logical       ClipIt;
Real          Clip;
{
   register Real f       = Frac;
   register Real oneminf = 1. - Frac;
   TRACE("Interpolation");
   if(         ClipIt && Select != NULL ) {
      with( *aShape ) { where(*p_arr(Select)) {
         *p_arr(A0) = f * *p_arr(A1) + oneminf * *p_arr(A2);
         *p_arr(A0) = *p_arr(A0) > Clip ? *p_arr(A0) : Clip;
      }}
   } else if(  ClipIt && Select == NULL ) {
      with( *aShape ) {{
         *p_arr(A0) = f * *p_arr(A1) + oneminf * *p_arr(A2);
         *p_arr(A0) = *p_arr(A0) > Clip ? *p_arr(A0) : Clip;
      }}
   } else if( !ClipIt && Select != NULL ) {
      with( *aShape ) { where(*p_arr(Select)) {
         *p_arr(A0) = f * *p_arr(A1) + oneminf * *p_arr(A2);
      }}
   } else if( !ClipIt && Select == NULL ) {
      with( *aShape ) {{
         *p_arr(A0) = f * *p_arr(A1) + oneminf * *p_arr(A2);
      }}
   }
   if( Select == NULL ) OperCount(CCALC,aShape,0, 1,2, 2, 3,0);
   if( Select != NULL ) OperCount(CCALC,aShape,0, 2,4, 3, 4,0);
}

/*

/******************************************************************************/
/*
   Adapt the Lagrange multipliers, based on the sums.
   First calculate the sums (and norms).
   Then invert the matrix equation to get the changes in the multipliers
   Next, adapt the multipliers, based on some criteria.
   Finally, change the clip level.
*/
/******************************************************************************/

private void MultiplierSteps( CTRL, Stats, MosMap )
CONTROL *CTRL;
STATS   *Stats;
MOSMAP  *MosMap;
{
   void         Messages_Par();
   void         CheckGrads();
   private void CalcSums();
   private void CalcNorms();
   private void InvertLM_Matrix();
   private void AdaptMultipliers();
   int          N;
   char         str[10];
   TRACE("MultiplierSteps");

   CheckGrads( MosMap );

   CalcSums(  CTRL, Stats, MosMap );
   CalcNorms( CTRL, Stats         );

   for(ALLLM) Stats->X[N] = Stats->ChiSq[N] - CTRL->TargetChiSq[N];

              Stats->J    = Stats->H;
   for(ALLLM) Stats->J   -= Stats->LM[N] * Stats->X[N];

   for(ALLLM) { Sprintf(str,"X[%2d]",N); Messages_Par(str,(Real)Stats->X[N]); }

   InvertLM_Matrix(  CTRL, Stats );
   AdaptMultipliers( CTRL, Stats );

   if(SameAsMaxen()>=1) { for(ALLLM) Stats->LM[N] += Stats->dLM[N]; }

   assert( ( Stats->LM[LMint] != 0 ) | ( Stats->dLM[LMint] != 0 ),
           "alpha does not change from being 0; change your rms target" );
}

/******************************************************************************/
/*
   Loop over the mosaic map and gradient map to obtain the sums needed to steer
   MEM.
   Using local variables to obtain the sums is needed because otherwise the
   automatic parallelization of the loop would not work on the SGI.

   This routine knows how many LM there actually are (2 so far).
   To extend program: extend JX, XX, change the summation code.
*/
/******************************************************************************/

private void CalcSums( CTRL, Stats, MosMap )
CONTROL *CTRL;
STATS   *Stats;
MOSMAP  *MosMap;
{
   int     N, M;
   Real    DataMin, totFlux, H, HH, JJ, JX[nLM], XX[nLM][nLM];
   logical ConstrainFlux = CTRL->TargetFlux > ZERO;

   DataMin = MAX_REAL;
   totFlux = H = HH = JJ = ZERO;
   for(N=0;N<CTRL->NLM;N++) { JX[N]    = ZERO;
   for(M=0;M<CTRL->NLM;M++)   XX[N][M] = ZERO; }

#ifdef should_be_the_way_on_mips
   Timer_Cont("PARALLEL"); SIZE=(&(*MosShape))->size;
#pragma parallel byvalue(SIZE) local(MemPixNum)
#pragma          reduction(DataMin) shared(Mos,Sel)
#pragma pfor iterate(MemPixNum=0;SIZE;1)
   for( MemPixNum=0; MemPixNum<SIZE; MemPixNum++ ) { where(Selected) {
#else
   with( *MosShape ) { where(Selected) {
#endif
      assmin( DataMin, *p_Mos );
   }} OpCntM(0,2, 2, 1,0);

   if( CTRL->EntropyMeasure == GULL ) {
      with( *MosShape ) { where(Selected) {
         H += EntFunGull;
      }} OpCntM(0,2, 3, 3,0);
   }
   if( CTRL->EntropyMeasure == CORN ) {
      with( *MosShape ) { where(Selected) {
         H += EntFunCorn;
      }} OpCntM(0,2, 2, 2+100+74,1); /* 100=cosh, 74=log */
   }

   with( *MosShape ) { where(Selected) {
      totFlux          += *p_Mos;
      HH               += *p_GradH * *p_Metric * *p_GradH;
      JJ               += *p_GradJ * *p_Metric * *p_GradJ;
      JX[LMint]        += *p_GradJ * *p_Metric * *p_GradX;
      XX[LMint][LMint] += *p_GradX * *p_Metric * *p_GradX;
      XX[LMflx][LMflx] +=            *p_Metric;
      if( ConstrainFlux ) {
      JX[LMflx]        += *p_GradJ * *p_Metric *  p_GradF;
      XX[LMint][LMflx] += *p_GradX * *p_Metric *  p_GradF; }
   }} XX[LMflx][LMint]  = XX[LMint][LMflx];
   if(ConstrainFlux) { OpCntM(3,17, 7, 15,0); } else { OpCntM(5,25, 7, 21,0); }

   Stats->modelFlux    = totFlux;
   Stats->ChiSq[LMflx] = CTRL->TargetFlux<=ZERO ? CTRL->TargetChiSq[LMflx]
                                                : Stats->modelFlux;
   Stats->H = H; Stats->HH = HH; Stats->JJ = JJ;

   for(N=0;N<CTRL->NLM;N++) { Stats->JX[N]             = JX[N];
   for(M=0;M<CTRL->NLM;M++)   Stats->XX[N*CTRL->NLM+M] = XX[N][M]; }

   switch( CTRL->ClipIt ) {
   case 0:                                                        break;
   case 1:  assmin( Stats->Clip , CTRL->ClipFactor * DataMin );   break;
   case 2:          Stats->Clip = CTRL->ClipFactor * DataMin;     break;
   case 3:          Stats->Clip = CTRL->ClipFactor * Stats->Clip; break;
   }
}

/******************************************************************************/
/*
   Combine some sums to get vector norms.
*/
/******************************************************************************/

private void CalcNorms( CTRL, Stats )
CONTROL *CTRL;
STATS   *Stats;
{
   void Messages_Par();
   int  N;

   switch( CTRL->Choice_Norm1 ) {
   case 1: Stats->Norm1  = Stats->HH;
           for( N=0; N<CTRL->NLM; N++ )
           Stats->Norm1 += square(Stats->LM[N]) * Stats->XX[N*CTRL->NLM+N];
           break;
   case 2: Stats->Norm1  = Stats->XX[LMflx*CTRL->NLM+LMflx];
   }

   Stats->oldNormGJ = Stats->Iteration > 1 ? Stats->NormGJ : 10.;
   Stats->NormGJ    = Stats->Norm1 > ZERO && Stats->JJ > ZERO ?
                      Stats->JJ/Stats->Norm1 : ONE;
   Stats->Norm2GJ   = Stats->HH != 0. ? Stats->JJ / Stats->HH : 10.;

   Messages_Par( "oldNormGJ", (Real)Stats->oldNormGJ );
   Messages_Par( "NormGJ",    (Real)Stats->NormGJ    );
   Messages_Par( "Norm2GJ",   (Real)Stats->Norm2GJ   );
   Messages_Par( "Norm1",     (Real)Stats->Norm1     );
}

/******************************************************************************/
/*
   Calculate the change in Lagrange Multipliers by matrix inversion.

   This routine knows how many Lagrange Multipliers there actually are.
   To extend program: update matrix inversion.
*/
/******************************************************************************/

private void InvertLM_Matrix( CTRL, Stats )
CONTROL *CTRL;
STATS   *Stats;
{
   void   Messages_Par();
   double D;
   int    N;
   int    Nii = LMint * CTRL->NLM + LMint;
   int    Nif = LMint * CTRL->NLM + LMflx;
   int    Nfi = LMflx * CTRL->NLM + LMint;
   int    Nff = LMflx * CTRL->NLM + LMflx;

   for( N=LMint+1; N<CTRL->N; N++ ) Stats->X[LMint] += Stats->X[N];
   Messages_Par("X",Stats->X[LMint]);

   D = Stats->XX[Nii] * Stats->XX[Nff] - Stats->XX[Nif] * Stats->XX[Nfi];
   Stats->dLM[LMint] = D==ZERO ? ZERO :
         (   Stats->XX[Nff] * ( Stats->X[LMint] + Stats->JX[LMint] )
           - Stats->XX[Nfi] * ( Stats->X[LMflx] + Stats->JX[LMflx] ) ) / D;
   Stats->dLM[LMflx] = D==ZERO ? ZERO :
         ( - Stats->XX[Nif] * ( Stats->X[LMint] + Stats->JX[LMint] )
           + Stats->XX[Nii] * ( Stats->X[LMflx] + Stats->JX[LMflx] ) ) / D;
}

/******************************************************************************/
/*
   Find an adaptation to the calculate multipliers to avoid overshooting.
   The outside parameter Choice_MagicLM determines how (default value=1).
      0: no changes
      1: change with quadratic solution if |dlm/lm|<0.5, damping otherwise
      2: change by damping, always
      3: change with quadratic solution, always
      4: change by damping if normB>normA
      5: change with quadratic solution, using oldNorm
      (normB=JJ/HH; normA=JJ/norm1; oldNorm=normA on previous iteration
*/
/******************************************************************************/

private void AdaptMultipliers( CTRL, Stats )
CONTROL *CTRL;
STATS   *Stats;
{
   void    Messages_LM();
   int     N, M;
   double  D=ZERO, G=ZERO, d=ZERO;
   int     Change=0;
   double  lm, dlm, dlm2, mindlm=ZERO, maxdlm=ZERO;

   for( N=0; N<CTRL->NLM; N++ ) {
      lm  = Stats->LM[N];
      dlm = Stats->dLM[N];

      if( (Stats->Iteration==1) | (lm==ZERO) | (dlm==ZERO) ) {
         Change=0;
      } else {
      switch( CTRL->Choice_MagicLM ) {
      case 0:                     Change = 0;                             break;
      case 1: G=Stats->Norm2GJ;   Change = lm==0.?0.:(fabs(dlm/lm)>.5?2:1);
                                                                          break;
      case 2:                     Change = lm==0. ? 0: 2;                 break;
      case 3: G=Stats->Norm2GJ;   Change = 1;                             break;
      case 4: G=Stats->Norm2GJ;   Change = G>Stats->NormGJ?1:(lm==0.?0:2);break;
      case 5: G=Stats->oldNormGJ; Change = 1;                             break;
      }}

      switch( Change ) {
      case 0:
         dlm2 = dlm;
         break;
      case 1:
         M      = N * CTRL->NLM + N;
         d      = Stats->JJ - G*Stats->Norm1;
         D      = max( ZERO,   square(Stats->JX[N]) - Stats->XX[M] * d   );
         mindlm = ( Stats->JX[N] - sqrt(D) ) / Stats->XX[M];
         maxdlm = ( Stats->JX[N] + sqrt(D) ) / Stats->XX[M];
         dlm2   = max( mindlm, min( maxdlm, dlm ) );
         break;
      case 2:
         dlm2 = dlm * 0.5 / ( ONE + fabs(dlm/lm) );
         break;
      default:
         dlm2 = dlm;
         break;
      }
      Messages_LM(N,dlm,dlm2,Change,mindlm,maxdlm);

      if( CTRL->Choice_PosLM ) Stats->dLM[N] = lm+dlm2 >= ZERO ? dlm2 : -lm;
   }

   if( CTRL->N != CTRL->NLM ) {
   for( N=LMint+1; N<CTRL->N-1; N++ ) Stats->dLM[N] = Stats->dLM[LMint]; }
}

/*

/******************************************************************************/
/*    <<< Step >>>                                      75 +   40 =  115 MOSAIC
/******************************************************************************/
/*
   Find and take the step.
   Calculate deltab = -GGJinv GradJ
   Then find the limiting factor s, and also S_0
   Take step b <- b + s deltab
*/
/******************************************************************************/

private void TakeStep( CTRL, Stats, MosMap )
CONTROL *CTRL;
STATS   *Stats;
MOSMAP  *MosMap;
{
   private void GetStep();
   private void TakeTheStep();

   GetStep(     CTRL, Stats, MosMap );
   TakeTheStep( CTRL, Stats, MosMap );
}

/******************************************************************************/
/*
   Calculate the step for each point.
   The formula is (with lagrange multipliers yet unchanged, and GradJ as it was
   while calculating the sums):
     step = Stats->Scale*(-1./DelJ)*(GradJ - Stats->dAlpha*GradX - Stats->dBeta)
   First calculate GradJ-alphaGradX-beta, since this is later needed again.
   Then find the unscaled step.

   Calculate the function used to limit the step: L = Sum{ step^2/b }.
   Also find the inproduct for the interpolation: S = Step . GradJ.
*/
/******************************************************************************/

private void GetStep( CTRL, Stats, MosMap )
CONTROL *CTRL;
STATS   *Stats;
MOSMAP  *MosMap;
{
   private void Entropy();
   void Messages_Scaling();
   void Messages_Par();

   Real dalpha = (Real)Stats->dLM[LMint];
   Real dbeta  = (Real)Stats->dLM[LMflx];
   Real L=ZERO, S_0=ZERO;
   Real Flx;

   TRACE("GetStep");
   if( SameAsMaxen()>=2 ) Entropy(METRIC,CTRL->EntropyMeasure,Stats,MosMap);

   with( *MosShape ) { where(Selected) {
      *p_GradJ -= dalpha * *p_GradX + dbeta;
      *p_Stp    = *p_Metric * *p_GradJ;
      L        += *p_Stp * *p_Stp / fabs((double)*p_Mos);
      S_0      += *p_Stp * *p_GradJ;
   }} OpCntM(2,9, 6, 9,1);
   Stats->S_0 = S_0;

   if( SameAsMaxen()<3 ) Flx = Stats->modelFlux;
   else { Flx = CTRL->TargetFlux > ZERO ? CTRL->TargetFlux : Stats->modelFlux; }
   Stats->Scale = Flx>ZERO && L>ZERO ?  sqrt( CTRL->MaxRatio * Flx / L ) : ONE;

   Messages_Par( "The sum L", L );
   Messages_Par( "Ratio L/F", Flx != ZERO  ? L/Flx : ZERO );
   Messages_Par( "sqrt(max*sum/L)", (Real)Stats->Scale );
   Stats->Scale = min( ONE, Stats->Scale );
   Messages_Scaling( Stats->Scale, Stats->Frac, FALSE );

   Messages_Par( "The sum S_0", (Real)Stats->S_0 );
   Stats->S_0 *= Stats->Scale;
}

/******************************************************************************/
/*
   - Actually take the step.
   - The new model is automatically zero outside the selected area, because the
     use of the Mos arrays to hold the metric only changes it inside the
     selected area.
   - When done, save the old mosaic array by swapping a pointer.
*/
/******************************************************************************/

private void TakeTheStep( CTRL, Stats, MosMap )
CONTROL *CTRL;
STATS   *Stats;
MOSMAP  *MosMap;
{
   void SaveSet(), CheckStep();
   int  N;
   Real Scale = Stats->Scale;
   TRACE("TakeTheStep");

   CheckStep( MosMap, Stats->Scale, CTRL->ClipIt?Stats->Clip:-MAX_REAL );
   SaveSet( "step", &MosMap->MosaicMap, Stats->Iteration );

   if( CTRL->ClipIt ) { InitClip;
      with( *MosShape ) { where(Selected) {
         *p_nMos = *p_Mos + Scale * *p_Stp; ApplyClip(*p_nMos);
      }} OpCntM(2,4, 2, 3,0);
   } else {
      with( *MosShape ) { where(Selected) {
         *p_nMos = *p_Mos + Scale * *p_Stp;
      }} OpCntM(1,2, 1, 2,0);
   }

   for(ALLLM) Stats->LM[N] += Stats->dLM[N];

   SwapMosArrays(MosMap);
}

/*

/******************************************************************************/
/*    <<< Convergence >>>                               22 +   11 =   33 MOSAIC
/******************************************************************************/
/*
   Test for convergence.
   (modelFlux == ChiSq[LMflx]; TargetFlux == TargetChiSq[LMflx])
*/
/******************************************************************************/

void SumChiSq( CTRL, Stats, ratio, ChiSq, TargetChiSq, Cdiff,
                                   mFlux, TargetFlux,  Fdiff, ConstrainFlux )
CONTROL *CTRL;
STATS   *Stats;
double  *ratio;
double  *ChiSq, *TargetChiSq, *Cdiff;
double  *mFlux, *TargetFlux,  *Fdiff;
logical *ConstrainFlux;
{
   int N;
   *ChiSq = *TargetChiSq = ZERO;
   for(ALLXLM) { *ChiSq+=Stats->ChiSq[N];  *TargetChiSq+=CTRL->TargetChiSq[N]; }
                 *mFlux =Stats->modelFlux; *TargetFlux  =CTRL->TargetFlux;
                 *ConstrainFlux = *TargetFlux > ZERO;

   if( *ConstrainFlux ) *Fdiff = Procent( fabs( *mFlux / *TargetFlux  ) - ONE );
   else                 *Fdiff = ZERO;
   *Cdiff = Procent( fabs( *ChiSq / *TargetChiSq ) - ONE );
   *ratio = Stats->NormGJ != 0. ? Stats->NormGJ : ONE;
}

private logical Converge( CTRL, Stats )
CONTROL *CTRL;
STATS   *Stats;
{
   void    SumChiSq();
   double  ratio;
   double  ChiSq, TargetChiSq, Cdiff;
   double  mFlux, TargetFlux,  Fdiff;
   logical ConstrainFlux;
   TRACE("Converge");

   SumChiSq( CTRL,Stats, &ratio, &ChiSq, &TargetChiSq, &Cdiff,
                                 &mFlux, &TargetFlux,  &Fdiff, &ConstrainFlux );

   return(
      ( ( ConstrainFlux && fabs(Fdiff) < Procent(CTRL->Tolerance) ) ||
         !ConstrainFlux                                                )  &&
      (                    fabs(Cdiff) < Procent(CTRL->Tolerance)      )  &&
      (                    ratio       < CTRL->Epsilon                 )
         );
}
