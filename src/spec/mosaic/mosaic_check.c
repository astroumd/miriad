/*----------------------------------------------------------------------------
-- mosaic_check.c --
/*----------------------------------------------------------------------------*/
#include "mosaic_arrays.h"
/*----------------------------------------------------------------------------*/

/******************************************************************************/
/* <<< CHECKING >>>                                   1142 +  297 = 1439 USERIO
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*
   - First read in some keywords that specify how much to write.
   - DATCHECK check whether the MessageLevel is high enough and whether the
     current pixel is within the selected range.
   - ADDR transforms the pixel number (MemPixNum) to a x,y position and also
     prints a memory address; all this for one image.
   - MOS_ADDR mimics ADDR, but is used to print the coordinates and address of
     a mosaiced image when looping over a single image.
   - The WhereSelected macro is complex for real parallel arrays, in order to
     print the elements one by one.
*/
/******************************************************************************/

#define Lev_StepCheck 31
#define Lev_IntCheck  32
#define Lev_GradCheck 33
#define Lev_ResCheck  34
#define Lev_GrXCheck  35
#define Lev_ExtrCheck 36
#define Lev_RegCheck  41
#define Lev_PrBCheck  42
#define Lev_GGXCheck  45
#define Lev_S1Check   46
#define Lev_SyBCheck  47
#define Lev_uvCheck   48

#define MESSTRLEN 512
private char    MES[MESSTRLEN], *mes;
private int     MessageLevel;
private logical AllTimers;
private int     DatModulo, DatLowLimit, DatHighLimit;
private int     uvModulo,  uvLow,       uvHigh;
void MESSAGE();

void DatModInp(MesLev,AllTim)
int     MesLev;
logical AllTim;
{
   void keyi_c();
   MessageLevel = MesLev;
   AllTimers    = AllTim;
   keyi_c( "datmod", &DatModulo,           64 );
   keyi_c( "datmod", &DatLowLimit,          0 );
   keyi_c( "datmod", &DatHighLimit, 2048*2048 );
   keyi_c( "uvmod",  &uvModulo,            64 );
   keyi_c( "uvmod",  &uvLow,                0 );
   keyi_c( "uvmod",  &uvHigh,               0 );
}
void ExchDatMesLev()
{
   void    DTMexchange();
   logical DTMm2s();
   DTMexchange( DTMm2s(), "DATMESLEV", "iiiiiil",
   &DatModulo, &DatLowLimit, &DatHighLimit,
   &uvModulo,  &uvLow,       &uvHigh,
   &AllTimers );
}


#define CheckMessage(str,name) dprintf("Check %s; dataset %s\n",(str),(name))
#define CheckMosMessage(str)   dprintf("Check %s\n",            (str) )

#define PrtEl(format,value) Sprintf(mes,format,value); mes = &MES[0]+strlen(MES)
#define LogVal(x) ( x>ZERO ? 'T' : 'F' )

private logical DATCHECK()
{ if( DatModulo == 0 ) return( FALSE );
  return( MemPixNum%DatModulo == 0 &&
          between(DatLowLimit,MemPixNum,DatHighLimit) ); }


#ifdef __CSTAR__
#define WITH(S)   START=0; END=sizeof(S); with(S) { \
                  for(MemPixNum=START;MemPixNum<END;MemPixNum++) { mes=&MES[0];
#define EndWith   }}
#define el(p)     [MemPixNum](*p)
#define mel(p)    ([MemPixNum]*p_assoc>0?[[MemPixNum]*p_assoc]*p:-1.)
#define MosPix    [MemPixNum]*p_assoc
#else
#define WITH(S)   START=(&S)->start; END=(&S)->end; XFOLD=(&S)->xlen; \
                  for(MemPixNum=START;MemPixNum<END;MemPixNum++) { mes=&MES[0];
#define EndWith   }
#define el(p)     *p
#define mel(p)    (*p_assoc>0 ? *(p - MemPixNum + *p_assoc) : -1)
#define MosPix    *p_assoc
#endif

/*
#define OBSADDR(p) \
        Sprintf( mes, "Obs#%5d(%3d,%3d)@%9u ",         \
        MemPixNum+1, MemPixNum%XFOLD+1, MemPixNum/XFOLD+1, p ); mes+=29
#define MOSADDR(p) \
        Sprintf( mes, "Mos#%5d(%3d,%3d)@%9u ",           \
        MemPixNum+1, MemPixNum%XFOLD+1, MemPixNum/XFOLD+1, p ); mes+=29
#define MOS_ADDR(p) \
        Sprintf( mes, "Mos#%5d(%3d,%3d)@%9u ",           \
        MosPix+1,    MosPix%xfold+1,    MosPix/xfold+1,    p ); mes+=29
*/
#define OBSADDR(p) \
        Sprintf( mes, "Obs#%5d(%3d,%3d) ",         \
        MemPixNum+1, MemPixNum%XFOLD+1, MemPixNum/XFOLD+1 ); mes+=19
#define MOSADDR(p) \
        Sprintf( mes, "Mos#%5d(%3d,%3d) ",           \
        MemPixNum+1, MemPixNum%XFOLD+1, MemPixNum/XFOLD+1 ); mes+=19
#define MOS_ADDR(p) \
        Sprintf( mes, "Mos#%5d(%3d,%3d) ",           \
        MosPix+1,    MosPix%xfold+1,    MosPix/xfold+1    ); mes+=19

void CheckSyB(MapI)
ONEMAP *MapI;
{logical LocallyRun();
 if( MessageLevel==Lev_SyBCheck && LocallyRun() )
{
   CheckMessage("synthesized beam",MapI->SynthBeam.name);
   (void)MapArrays(0,MapI);

   WITH(*BeaShape) { if(DATCHECK()) {
      OBSADDR(p_SyB);
      PrtEl( "SyB %10.8f\n", el(p_SyB) );
      MESSAGE(MES);
   }} EndWith
/*
Obs#.....(...,...)@......... SyB ......
*/
}}

void CheckPrB(MapI)
ONEMAP *MapI;
{  if( MessageLevel==Lev_PrBCheck )
{
   PBPAR *PB = &MapI->PB;
   double xref   =        PB->xref;
   double yref   =        PB->yref;
   double xdelt2 = square(PB->xdelt);
   double ydelt2 = square(PB->ydelt);
   double r2;
   CheckMessage("primary beam",MapI->PrimaryBeam.name);
   (void)MapArrays(0,MapI);

   WITH(*PrBShape) { if(DATCHECK()) {
      r2 = square(pcoord_x-xref)*xdelt2 + square(pcoord_y-yref)*ydelt2;
      OBSADDR(p_PrB);
      PrtEl( "r %6.0f'' ",  dtos( sqrt(r2) ) );
      PrtEl( "PBC %6.2f\n", el(p_PrB) );
      MESSAGE(MES);
   }} EndWith
/*
Obs#.....(...,...)@......... r ......'' PBC ......
*/
}}

void CheckGGX(MapI,MosMap)
ONEMAP *MapI;
MOSMAP *MosMap;
{  if( MessageLevel==Lev_GGXCheck )
{
   int xfold=MosMap->MosaicMap.Coords.XLEN;
   CheckMessage("second gradient",MapI->PrimaryBeam.name);
   (void)MapArrays(0,MapI); MosArrays(MosMap);

   WITH(*PrBShape) { if(DATCHECK()) {
      MOS_ADDR(p_GGX);
      PrtEl( "GG %9.2e ", mel(p_GGX) );
      OBSADDR(p_PrB);
      PrtEl( "P %6.2f\n",  el(p_PrB) );
      MESSAGE(MES);
   }} EndWith
/*
Mos#.....(...,...)@......... GG ....... Obs#.....(...,...)@......... P ......
*/
}}

void CheckMask(MapI,MosMap)
ONEMAP *MapI;
MOSMAP *MosMap;
{  if( MessageLevel==Lev_RegCheck & MapI->IsIFmap )
{
   int xfold=MosMap->MosaicMap.Coords.XLEN;
   CheckMessage("mask",MapI->Observation.name);
   (void)MapArrays(0,MapI); MosArrays(MosMap);

   WITH(*ObsShape) { if(DATCHECK()) {
      OBSADDR(p_Obs);
      PrtEl( "m %c",    LogVal( el(p_Msk) ) );
      PrtEl( "%c ",     LogVal( el(p_RegMsk) ) );
      PrtEl( "P%7.3f ", el(p_PrB) );
      MOS_ADDR(p_Ref);
      PrtEl( "R%8.1e ", mel(p_Ref) );
      PrtEl( "%c\n",    LogVal( mel(p_Sel)==1 ) );
      MESSAGE(MES);
   }} EndWith
/*
Obs#.....(...,...)@......... mM.. P...... Mos#.....(...,...)@......... R...... .
*/
}}

void CheckExtr(MapI,MosMap)
ONEMAP *MapI;
MOSMAP *MosMap;
{  if( MessageLevel==Lev_ExtrCheck && MapI->IsIFmap )
{
   int xfold=MosMap->MosaicMap.Coords.XLEN;
   CheckMessage("extraction",MapI->DirtyMap.name);
   (void)MapArrays(0,MapI); MosArrays(MosMap);

   WITH(*PrBShape) { if( DATCHECK() && mel(p_Sel)==1 ) {
      MOS_ADDR(p_Mos);
      PrtEl( "M %10.3e ",   mel(p_Mos) );
      OBSADDR(p_PrB);
      PrtEl( "P %6.3f ",    el(p_PrB) );
      PrtEl( "MP %15.9f\n", el(p_MxP) );
      MESSAGE(MES);
   }} EndWith
/*
Mos#.....(...,...)@......... M ......... Obs#.....(...,...)@......... P ......
*/
}}

void CheckRes(MapI)
ONEMAP *MapI;
{  if( MessageLevel==Lev_ResCheck )
{
   CheckMessage("residual",MapI->DirtyMap.name);
   (void)MapArrays(0,MapI);

   WITH(*ObsShape) { if( DATCHECK() && *p_assoc>0 ) {
      OBSADDR(p_Res);
      PrtEl( "C %12.8f ",  el(p_Con) );
      PrtEl( "O %12.8f ",  el(p_Obs) );
      PrtEl( "P %12.8f ",  el(p_PrB) );
      PrtEl( "R %12.8f\n", el(p_Con)-el(p_Obs) );
      MESSAGE(MES);
   }} EndWith
/*
Obs#.....(...,...)@......... C ...... O ...... P ...... R ......
*/
}}

void CheckGrX(MosMap)
MOSMAP *MosMap;
{  if( MessageLevel==Lev_GrXCheck )
{
   CheckMosMessage("grad X");
   MosArrays(MosMap);

   WITH(*MosShape) { if( DATCHECK() & el(p_Sel) ) {
      MOSADDR(p_GrX);
      PrtEl( "GX %13.9f\n", el(p_GrX) );
      MESSAGE(MES);
   }} EndWith
/*
Mos#.....(...,...)@......... GX ......
*/
}}

void CheckS1(MosMap)
MOSMAP *MosMap;
{  if( MessageLevel==Lev_S1Check )
{
   double S1=ZERO;
   CheckMosMessage("the sum S1");
   MosArrays(MosMap);

   WITH(*MosShape) { where(Selected) {
      S1 += ( el(p_Mos) - el(p_oMos) ) * el(p_GradJ); if( DATCHECK() ) {
      MOSADDR(p_Mos);
      PrtEl( "M %10.3e ",  el(p_Mos)   );
      PrtEl( "<- %10.3e ", el(p_oMos)  );
      PrtEl( "GJ %9.2e ",  el(p_GradJ) );
      PrtEl( "S1 %6.2f\n", S1 );
      MESSAGE(MES);
   }}} EndWith
/*
Mos#.....(...,...)@......... M ......... <- ......... GJ ......... S1 .......
*/
}}

void CheckInt(MosMap,Frac)
MOSMAP *MosMap;
double  Frac;
{  if( MessageLevel==Lev_IntCheck )
{
   CheckMosMessage("interpolation");
   MosArrays(MosMap);

   WITH(*MosShape) { if( DATCHECK() & el(p_Sel) ) {
      MOSADDR(p_Mos);
      PrtEl( "M %10.3e ",   el(p_oMos) );
      PrtEl( "%10.3e ",     el(p_Mos)  );
      PrtEl( "-> %10.3e\n", (1.-Frac)*el(p_oMos)+Frac*el(p_Mos) );
      MESSAGE(MES);
   }} EndWith
/*
Mos#.....(...,...)@......... M ......... ......... -> .........
*/
}}

void CheckGrads(MosMap)
MOSMAP *MosMap;
{  if( MessageLevel==Lev_GradCheck )
{
   CheckMosMessage("mosaic map and gradients");
   MosArrays(MosMap);

   WITH(*MosShape) { if( DATCHECK() & el(p_Sel) ) {
     MOSADDR(p_Mos); mes = &MES[0]+18;
     PrtEl( "MRG %13.6e ",  el(p_Mos)    );
     PrtEl( "%7.1e ",       el(p_Ref)    );
     PrtEl( "%10.4f ",      el(p_GrX)    );
     PrtEl( "gHJm%11.4e ",  el(p_GradH)  );
     PrtEl( "%11.4e ",      el(p_GradJ)  );
     PrtEl( "%12.6e\n",     el(p_Metric) );
     MESSAGE(MES);
   }} EndWith
/*
Mos#.....(...,...)MRG ......... ....... ...... gHJm......... ........ ........
*/
}}

void CheckStep(MosMap,Scale,Clip)
MOSMAP  *MosMap;
double   Scale;
Real     Clip;
{  if( MessageLevel==Lev_StepCheck )
{
   double Val;
   CheckMosMessage("step");
   MosArrays(MosMap);

   WITH(*MosShape) { if( DATCHECK() & el(p_Sel) ) {
      MOSADDR(p_Mos); mes = &MES[0]+18;
      PrtEl( "MRG %13.6e ", el(p_Mos) );
      PrtEl( "%7.1e ",      el(p_Ref) );
      PrtEl( "%10.4f ",     el(p_GrX) );
      PrtEl( "gJm%11.4e ",  el(p_GradJ) );
      PrtEl( "%11.4e",      el(p_Metric) );
      Val = el(p_Mos) + Scale * el(p_Stp); Val = Val>Clip ? Val : Clip;
      PrtEl( " -> %12.6e\n", Val );
      MESSAGE(MES);
   }} EndWith
/*
Mos#.....(...,...)MRG ......... ....... ...... gJm........ ........ -> .........
*/
}}

/*

/******************************************************************************/
/*
   Test output for doing the convolution.
*/
/******************************************************************************/
/*
void Check_uv( flag, c, clen, uvPln,SCR_Line,SCR_CData1,SCR_CData2,SCR_uvPln )
int    flag, c, clen;
cmplx *uvPln;
Real  *SCR_Line;
cmplx *SCR_CData1, *SCR_CData2, *SCR_uvPln;
{
   private void    Check_uv_real_line();
   private void    Check_uv_cmplx_line();
   register Real  *Im;
   register cmplx *VisIn, *VisOut, *Vis;
   register int    uvlow, uvhigh;

   if( MessageLevel == Lev_uvCheck && uvModulo != 0 && c%uvModulo == 0 )
{
   uvlow  = uvLow;
   uvhigh = uvHigh == 0 ? clen/2 : uvHigh;

   switch( flag ) {
   case 1: Sprintf( MES, "--- FT input row y= "           ); break;
   case 2: Sprintf( MES, "--- FT interm column u= "       ); break;
   case 3: Sprintf( MES, "--- Back FT column * cover u= " ); break;
   case 4: Sprintf( MES, "--- Back FT row * cover v= "    ); break; }

   mes = &MES[0]+strlen(MES);
   Sprintf( mes, "%3d --- uvPln=%8u (%8u)\n", c, uvPln, (uvPln-SCR_uvPln) );
   MESSAGE(MES);

   switch( flag ) {
   case 1: dprintf("x axis:         In        -> Re(Out)+Im(Out)i \n"); break;
   case 2: dprintf("v axis:  Re(In) +Im(In) i -> Re(Out)+Im(Out)i \n"); break;
   case 3: dprintf("v axis:  Re(In) +Im(In) i -> Re(Out)+Im(Out)i \n"); break;
   case 4: dprintf("v axis:  Re(Out)+Im(Out)i ->   Out            \n"); break; }

   switch( flag ) {
   case 1: Im    = SCR_Line   + uvlow;   Vis    =   uvPln    + uvlow; break;
   case 2: VisIn = SCR_CData1 + uvlow;   VisOut = SCR_CData2 + uvlow; break;
   case 3: VisIn = SCR_CData2 + uvlow;   VisOut = SCR_CData1 + uvlow; break;
   case 4: Vis   =   uvPln    + uvlow;   Im     = SCR_Line   + uvlow; break; }

   switch( flag ) {
   case 1: Check_uv_real_line(  Im,            uvlow,uvhigh     );
           Check_uv_cmplx_line( Vis,   Vis+1,  uvlow, uvhigh, 2 ); break;
   case 2: Check_uv_cmplx_line( VisIn, VisOut, uvlow, uvhigh, 1 ); break;
   case 3: Check_uv_cmplx_line( VisIn, VisOut, uvlow, uvhigh, 1 ); break;
   case 4: Check_uv_cmplx_line( Vis,   Vis+1,  uvlow, uvhigh, 2 );
           Check_uv_real_line(  Im,            uvlow, uvhigh    ); break; }
}}

private void Check_uv_cmplx_line( VisIn, VisOut, uvlow, uvhigh, inc )
register cmplx *VisIn, *VisOut;
register int    uvlow, uvhigh;
register int    inc;
{
   register int i;
   for( i=uvlow; i<=uvhigh; i+=inc, VisIn+=inc, VisOut+=inc ) { mes = &MES[0];
                                   PrtEl( "  %3d", i );
                                   PrtEl( "  %13.9f",  VisIn->real  );
                                   PrtEl(" + %13.9fi", VisIn->imag  );
      if( inc == 1 )               PrtEl("  --%c", '>' );
      if( inc == 2 && i<uvhigh )   PrtEl( "  %3d", i+1 );
      if( inc == 1 || i<uvhigh ) { PrtEl( "  %13.9f",  VisOut->real );
                                   PrtEl(" + %13.9fi", VisOut->imag ); }
      PrtEl("%c\n",'|'); MESSAGE(MES);
   }
}

private void Check_uv_real_line( ImIn, uvlow, uvhigh )
register Real *ImIn;
register int   uvlow, uvhigh;
{
   register int i;
   for( i=uvlow; i<2*uvhigh; ) { mes = &MES[0];
      PrtEl(" %3d", i );  PrtEl("  %13.9f", *ImIn );  i++; ImIn++;
      PrtEl(" %3d", i );  PrtEl("  %13.9f", *ImIn );  i++; ImIn++;
      PrtEl(" %3d", i );  PrtEl("  %13.9f", *ImIn );  i++; ImIn++;
      PrtEl(" %3d", i );  PrtEl("  %13.9f", *ImIn );  i++; ImIn++;
      PrtEl("%c\n",'|'); MESSAGE(MES);
   }
}
*/
