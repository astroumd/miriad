/*----------------------------------------------------------------------------
-- mosaic_arrays.h --
/*----------------------------------------------------------------------------*/
#include "mosaic.h"
/*----------------------------------------------------------------------------*/

#ifndef ARRNUMONLY
/******************************************************************************/
/* <<< ARRAY DEFINITIONS >>>                           211 +  185 =  396 SETUP
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*
  DEFINITIONS OF DATA ARRAYS
*/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*    <<< Array management >>>                         140 +  267 =  407 SETUP
/******************************************************************************/
/*
   Start addresses and dereferencing of arrays
   Here multiple uses are defined. The rest of the program does not see the
   MEMARR struct directly, only the p_... symbols and the ...Shape definitions.

   Examples of translations:
   machine  use in with() equivalent to            translates into
   CM5      *p_Obs        *MemAddr(Obs,MemPixNum)  *(MapI->MemArr.Obs)
   mips     *p_Obs        *MemAddr(Obs,MemPixNum)  *(Obs+MemPixNum)
   other    *p_Obs        *MemAddr(Obs,MemPixNum)  *(MapI->MemArr.Obs+MemPixNum)

   On the SGI power, parallization requires that the pointers used in a loop
   are not members of structs. In that case therefore, create global variables
   which can be used instead. For individual images assign the values during
   each ALLMAPS loop, for the mosaic map, assign the values as part of the
   initialization process. On other machines the routines get called also, but
   the assignments are ignored.
   The names of the global pointers must be the same as the member names of the
   MEMARR struct, so that the definition of the MemAddr and MosAddr macros below
   stays simple.
*/
/******************************************************************************/

#define ObsShape (MapI->MemArr.shapeofObs)
#define DrtShape (MapI->MemArr.shapeofDrt)
#define PrBShape (MapI->MemArr.shapeofPrB)
#define BeaShape (MapI->MemArr.shapeofBea)
#define CovShape (MapI->MemArr.shapeofCov)
#define MosShape (MosMap->MemArr.shapeofMos)
#define GauShape (MosMap->MemArr.shapeofGau)
#define GCvShape (MosMap->MemArr.shapeofGCv)

#ifdef  __CSTAR__
#define MemStrt(p)     (MapI->MemArr.p)
#define MosStrt(p)     (MosMap->MemArr.p)
#define MemAddr(p,off) (MapI->MemArr.p)
#define MosAddr(p,off) (MosMap->MemArr.p)
#else
/*#elif   mips*/
#define MemStrt(p)     (p)
#define MosStrt(p)     (p)
#define MemAddr(p,off) (p+off)
#define MosAddr(p,off) (p+off)
/*#else
#define MemStrt(p)     (MapI->MemArr.p)
#define MosStrt(p)     (MosMap->MemArr.p)
#define MemAddr(p,off) (MapI->MemArr.p+off)
#define MosAddr(p,off) (MosMap->MemArr.p+off)*/
#endif

#define p0_Obs      MemStrt(Obs)
#define p_Obs       MemAddr(Obs,MemPixNum)
#define p0_Msk      MemStrt(Res[sf])
#define p_Msk       MemAddr(Res[sf],MemPixNum)
#define ip_Msk      ((int *)MemAddr(Res[sf],MemPixNum))
#define p0_RegMsk   MemStrt(Res[fs])
#define p_RegMsk    MemAddr(Res[fs],MemPixNum)
#define p0_Drt      MemStrt(Drt)
#define p_Drt       MemAddr(Drt,MemPixNum)
#define p0_SyB      MemStrt(SyB)
#define p_SyB       MemAddr(SyB,MemPixNum)
#define p0_Cov      MemStrt(Cov)
#define p_Cov       MemAddr(Cov,MemPixNum)
#define p0_PrB      MemStrt(PrB)
#define p_PrB       MemAddr(PrB,MemPixNum)
#define p0_PBC      MemStrt(Res[fs])
#define p_PBC       MemAddr(Res[fs],MemPixNum)
#define p0_MxP      MemStrt(Res[fs])
#define p_MxP       MemAddr(Res[fs],MemPixNum)
#define p0_Vis      MemStrt(Res[fs])
#define p_Vis       MemAddr(Res[fs],MemPixNum)
#define p0_Con      MemStrt(Res[fs])
#define p_Con       MemAddr(Res[fs],MemPixNum)
#define p0_Res      MemStrt(Res[fs])
#define p_Res       MemAddr(Res[fs],MemPixNum)
#define p0_oRes     MemStrt(Res[sf])
#define p_oRes      MemAddr(Res[sf],MemPixNum)
#define p0_assoc    MemStrt(assoc)
#define p_assoc     MemAddr(assoc,MemPixNum)
#define InnerQrt  (*MemAddr(assoc,MemPixNum)>=0)

#define p0_Mos      MosStrt(Mos[FS])
#define p_Mos       MosAddr(Mos[FS],MemPixNum)
#define p_nMos      MosAddr(Mos[SF],MemPixNum)
#define p0_oMos     MosStrt(Mos[SF])
#define p_oMos      MosAddr(Mos[SF],MemPixNum)
#define p0_Sel      MosStrt(Sel)
#define p_Sel       MosAddr(Sel,MemPixNum)
#define Selected   *MosAddr(Sel,MemPixNum)
#define p0_Cnt      MosStrt(GrX)
#define p_Cnt       MosAddr(GrX,MemPixNum)
#define p0_Ref      MosStrt(Ref)
#define p_Ref       MosAddr(Ref,MemPixNum)
#define p0_GrX      MosStrt(GrX)
#define p_GrX       MosAddr(GrX,MemPixNum)
#define p0_GGX      MosStrt(GGX)
#define p_GGX       MosAddr(GGX,MemPixNum)
#define p0_Stp      MosStrt(GrH)
#define p_Stp       MosAddr(GrH,MemPixNum)
#define p0_MRs      MosStrt(Mos[SF])
#define p_MRs       MosAddr(Mos[SF],MemPixNum)
#define p0_Cnv      MosStrt(GrH)
#define p_Cnv       MosAddr(GrH,MemPixNum)
#define p0_Fin      MosStrt(GrJ)
#define p_Fin       MosAddr(GrJ,MemPixNum)
#define p0_Wgt      MosStrt(GrX)
#define p_Wgt       MosAddr(GrX,MemPixNum)
#define p_GradH     MosAddr(GrH,MemPixNum)
#define p_GradJ     MosAddr(GrJ,MemPixNum)
#define p_GradX     MosAddr(GrX,MemPixNum)
#define p_GradF         ONE
#define p_DelJ      MosAddr(Mos[SF],MemPixNum)
#define p_Metric    MosAddr(Mos[SF],MemPixNum)

#define p0_Gau      MosStrt(Gau)
#define p_Gau       MosAddr(Gau,MemPixNum)
#define p0_GCv      MosStrt(GCv)
#define p_GCv       MosAddr(GCv,MemPixNum)

/******************************************************************************/
/*
   How to get a single element from an array differs between C and C*. Thus,
   p_Assoc is defined, giving the connection between input and mosaiced arrays.

   Examples of translations:
   machine used in with   translates into
   CM5   *p_Assoc(p0_GGX) [abs(*p_assoc)]*p0_GGX =
                            [abs(*(MapI->MemArr.assoc)]*(MosMap->MemArr.GGX);
   mips  *p_Assoc(p0_GGX) *(p0_GGX + *p_assoc) =
                            *( MosAddr(GGX) + *(MemAddr(assoc,MemPixNum)) =
                            *( (GGX)        + *(assoc+MemPixNum) )
   other *p_Assoc(p0_GGX) *(p0_GGX + *p_assoc) =
                            *( MosAddr(GGX) + *(MemAddr(assoc,MemPixNum)) =
                            *( (MosMap->MemArr.GGX) +
                                         *(MapI->MemArr.assoc+MemPixNum) )
*/
/******************************************************************************/

#ifdef __CSTAR__
#define p_Assoc(p0) [*p_assoc]*p0
#else
#define p_Assoc(p0) *(p0 + *p_assoc)
#endif

/*

/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*    <<< Pointer init >>>                             211 +  185 =  396 SETUP
/******************************************************************************/
/*
   Define non-struct pointers to the arrays.

   Manage the pointers to the mosaic and residual arrays; for interpolations
   FS=0,SF=1: Mos[0] is Mos array, Mos[1] the old or new array
   FS=1,SF=0: Mos[1] is Mos array, Mos[0] the old or new array
   fs=0,sf=1: Res[0] is Res array, Res[1] the old or new array
   fs=1,sf=0: Res[1] is Res array, Res[0] the old or new array

   Set the array pointers in routines MapArrays, MosArray, SwapMosArrays and
   SwapResArrays. These are made local to several files (calc, mem, check and
   maps), and refer to separate local (static) variables. They are the only
   functions that are not explicitly declared again in the functions in which
   they are used.
*/
/******************************************************************************/

private int      FS, SF, fs, sf;
private Real    *Obs, *Drt, *Res[2], *PrB, *SyB;
private Real    *Mos[2], *Ref, *GrX, *GrH, *GrJ, *GGX, *Gau;
private cmplx   *Cov, *GCv;
private logical *Sel;
private int     *assoc;

#define local static

local void SwapMosArrays(MosMap)
MOSMAP *MosMap;
{ FS = MosMap->MemArr.FS = MosMap->MemArr.FS==0?1:0;
  SF = MosMap->MemArr.SF = MosMap->MemArr.SF==0?1:0;
}
local void SwapResArrays(Maps)
ONEMAP *Maps;
{ ONEMAP *MapI;
  for( ALLMAPSI ) { MapI->MemArr.fs = MapI->MemArr.fs==0?1:0;
                    MapI->MemArr.sf = MapI->MemArr.sf==0?1:0; }
  fs = fs==0?1:0;
  sf = sf==0?1:0;
}

local ONEMAP *MapArrays(n,Map)
int     n;
ONEMAP *Map;
{
   ONEMAP *MapI = n==0 ? Map : Map->NextMap;
   MEMARR *MA;
#ifndef __CSTAR__
   if( MapI != NULL ) { MA = &MapI->MemArr; if( MA->Obs != NULL ) {
   Obs = MA->Obs;
   Drt = MA->Drt;   Res[0] = MA->Res[0];   Res[1] = MA->Res[1];
   PrB = MA->PrB;   assoc  = MA->assoc;
   SyB = MA->SyB;   Cov    = MA->Cov;
   fs  = MA->fs;    sf     = MA->sf;
   }}
#endif
   return( MapI );
}

local void MosArrays(MosMap)
MOSMAP *MosMap;
{
#ifndef __CSTAR__
   MEMARR *MA = &MosMap->MemArr;
   Mos[0] = MA->Mos[0]; Mos[1] = MA->Mos[1]; Ref = MA->Ref; Sel = MA->Sel;
   GrX    = MA->GrX;    GrH    = MA->GrH;    GrJ = MA->GrJ; GGX = MA->GGX;
   Gau    = MA->Gau;    GCv    = MA->GCv;
   FS     = MA->FS;     SF     = MA->SF;
#endif
}

#endif /* !ARRNUMONLY */

/*

/******************************************************************************/
/*
   Convert array numbers into pointers.
*/
/******************************************************************************/

enum arrayselections {
   ps_Obs, ps_Msk, NOMASK, ps_RegMsk,
   ps_Drt, ps_PrB, ps_PBC, ps_MxP,
   ps_SyB, ps_Cov,
   ps_Res, ps_Vis, ps_Con,
   ps_assoc,
   ps_Mos, ps_Sel, ps_Cnt, ps_Stp, ps_Ref, ps_GrX, ps_GGX,
   ps_MRs, ps_Cnv, ps_Fin, ps_Wgt,
   ps_Gau, ps_GCv
};
enum shapeselections {
   Obs_Shape, Drt_Shape, PrB_Shape, Bea_Shape, Cov_Shape,
   Mos_Shape, Gau_Shape, GCv_Shape
};

/*

/******************************************************************************/
/*
   To help avoid some confusion, here is an overview of which arrays are
   actually used and/or needed during all the calculations.

   Many arrays are used for multiple purposes to minimize memory use as much as
   possible.

   Call Sequence:
     ReadBeams
     InitArrays
     loop: ReadMaps
           Mosaic
           loop: CalcResiduals
                 CalcGradX
                 CalcGradGradX
                 Entropy
                 CorrectStep
                 NewParameters
                 TakeStep
           WriteResult
     endloop

   (1): arrays of individual map size
   (2): arrays of of mosaic map size

--------------------------------------------------------------------------------
 InitArrays does one-time assignments:
 assoc, PrB, Cov and GGX cannot be changed
                                 (1)                          (2)
                         assign           use         assign           use
 ReadBeams             p_SyB
 InitArrrays
   InitPrB             p_PrB
   InitSyB
     BeamFT            p0_Cov=Cov     p_SyB
   InitAssoc           p_assoc

--------------------------------------------------------------------------------
 ReadMaps: assignments of Obs, Ref should stay constant during mosaic loop
                                 (1)                          (2)
                         assign           use         assign           use
 ReadMaps
   ReadData ps_RegMsk  p_RegMsk=Res[fs]
            ps_Obs     p_Obs&p_Drt
                       p_Msk=Res[sf]
   ReadData ps_Mos                                   p_Mos=Mos[FS]
   ReadData ps_Ref                                   p_Ref

--------------------------------------------------------------------------------
 Initializations: assignments of Drt, Ref, Sel should stay constant

   FindRef(R_MAP)                                                  p_Ref
          (R_F/C)                                    p_Ref         p_Ref
          (D_F/P)                     p_assoc        p_Ref
          (Set)                       p_PrB          p_Sel         p_Ref
                                      p_assoc
                                      ip_Msk=Res[sf]
                                      p_RegMsk=Res[fs]
          (Sum)                                                    p_Ref
                                                                   p_Sel
   FindIni(R)                                                      p_Mos=Mos[FS]
          (D)
   SetRefIni                                         p_Mos=Mos[FS] p_Mos=Mos[FS]
                                                     p_Ref
                                                     p_Metric=Mos[SF]

   RegridSD            p_Drt          p_Obs

--------------------------------------------------------------------------------
 Restore: Use GrX for intermediates
          Gau assignment does not change
          ConvolveModel assigns GrH
          ConstructFinal assigns GrJ
          ConstructResidual assign Mos[SF]

                                 (2)                          (1)
                         assign           use         assign           use
  PrimaryBeamC                                      p_PBC=Res[fs]  p_Drt
                                                                   p_PrB

  LinearMosaic         p_Mos=Mos[FS]     p_Wgt=GrX                 p_Drt
                                                                   p_PrB
                                                                   p_assoc
  NoiseMap             p_Mos=Mos[FS]     p_Wgt=GrX                 p_PrB
                                                                   p_assoc

  WRITECNV:
  ConvolveModel
    GaussCreate(a)     p_x=Gau=GrX
                       p_y=scr
                       p_Gau=Gau=GrX     p_x, p_y
               (b)     p_GCv=GCv=GrX     p_Gau=Gau=GrX
    Convolution        p_Cnv=GrH         p_Mos=Mos[FS]
                                         p_GCv=GCv=GrX

  WRITEFIN:
  ConvolveModel...     -> GrH
  ConstructResidual... -> Mos[SF]
  ConstructFinal       p_Fin=GrJ         p_Cnv=GrH
                                         p_MRs=Mos[SF]

  WRITERES:
  ConstructResidual    p_Wgt=GrX                                   p_assoc
                       p_MRs=Mos[SF]     p_Wgt=GrX                 p_Res=Res[fs]
                                                                   p_PrB
--------------------------------------------------------------------------------
 Mosaic: Mos[FS] is result
         Drt, Cov, PrB, Ref, Sel, GGX are constant
         Res[fs], Res[sf], Mos[SF], GrX, GrH and GrJ vary
                                 (1)                          (2)
                         assign           use         assign           use
   CalcResiduals
     (a)
     SwapResArrays Res[fs]<=>Res[sf]
     with(*DrtShape)   p_MxP=Res[fs]  p_PrB=PrB                   p0_Mos=Mos[FS]
                                      p_assoc
     Convolution
        Pass-1         scratch        Map=p0_MxP=Res[fs]
        Pass-2         scratch        scratch
                                      Cover=p_Cov=SyB
        Pass-3         Conv=p_Con=Res[fs] scratch
     with(*DrtShape)   p_Res=Res[fs]  p_Con=Res[fs]
                                      p_Drt=Drt
     (b)
     with(*DrtShape)   p_Res=Res[fs]  p_Res=Res[fs]
                                      p_oRes=Res[sf]

   CalcGradX
     with(*MosShape)                                 p0_GrX=GrX
     with(*DrtShape)                  p_Res=Res[fs]
     with(*PrBShape)                  p_PrB=PrB      p0_GrX=GrX
                                      p_Res=Res[fs]
                                      p_assoc

   CalcGradGradX                      p_PrB          p_GGX
                                      p_assoc

                                 (2)
                        assign             use
   Entropy(GRADHJ)     p_GradH=GrH       p_Mos=Mos[FS]
                                         p_Ref=Ref
                       p_GradJ=GrJ       p_GradH=GrH
                                         p_GradX=GrX

   CorrectStep
     with(*MosShape)                     p_Mos=Mos[FS]
                                         p_oMos=Mos[SF]
                                         p_GradJ=GrJ
     with(*MosShape)   p_Mos=Mos[FS]     p_Mos=Mos[SF]
                                         p_oMos=Mos[SF]

   MagicQ

   CalcResiduals
   CalcGradX
   Entropy(GRADHJM)    p_GradH=GrH       p_Mos=Mos[FS]
                                         p_Ref=Ref
                       p_GradJ=GrJ       p_GradH=GrH
                                         p_GradX=GrX
                       p_DelJ=Mos[SF]    p_Mos=Mos[FS]
                       p_Metric=Mos[SF]  p_Ref=Ref
                                         p_GradH=GrH
                                         p_GGX=GGX
   Entropy(GRADJM)     p_GradJ=GrJ       p_GradH=GrH
                                         p_GradX=GrX
                       p_DelJ=Mos[SF]    p_Mos=Mos[FS]
                       p_Metric=Mos[SF]  p_Ref=Ref
                                         p_GradH=GrH
                                         p_GGX=GGX
   Entropy(METRIC)     p_DelJ=Mos[SF]    p_Mos=Mos[FS]
                       p_Metric=Mos[SF]  p_Ref=Ref
                                         p_GradH=GrH
                                         p_GGX=GGX

   MultiplierSteps                       p_Mos=Mos[FS]
                                         p_Ref=Ref
                                         p_GradH=GrH
                                         p_GradX=GrX
                                         p_GradJ=GrJ
                                         p_Metric=Mos[SF]

   TakeStep
     GetStep           p_GradJ=GrJ       p_GradJ=GrJ
                       p_Stp=GrH         p_GradX=GrX
                                         p_Metric=Mos[SF]
                                         p_GradJ=GrJ
                                         p_Stp=GrH
                                         p_Mos=Mos[FS]
                                         p_GradJ=GrJ
     TakeTheStep       p_nMos=Mos[SF]    p_Mos=Mos[FS]
                                         p_Stp=GrH
     SwapMosArrays     Mos[FS]<=>MosSF]

SF]

*/
/******************************************************************************/
