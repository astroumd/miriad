/*----------------------------------------------------------------------------
-- mosaic.h --
/*----------------------------------------------------------------------------*/
#include "mosaic_stc.h"
/*----------------------------------------------------------------------------*/

/******************************************************************************/
/* <<< MOSAIC DEFINITIONS >>>                           19 +   36 =   55 SETUP
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*
  DEFINITIONS OF MOSAIC PARAMETERS
*/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*
   DEFINITIONS OF ORGANIZATIONAL STRUCTS

   Define MEMARR, ONEMAP and MOSMAP structs
   These are specific to the mosaicing.

   Define MOSFLAGS, CONTROL and STATS structs
   These are specific to the MEM algorithm.
*/
/******************************************************************************/
/*    <<< MEMARR struct >>>                             49 +   47 =   96 SETUP
/******************************************************************************/
/*
    - Below, an "image" is one 2-d array representing one image.
             A  "dataset" refers to the image and its description.
             A  "map" is a set of related images.

   - The "MEMARR" struct contains pointers to addresses in memory where the data
     can be found. Each MEMARR struct belongs to one particular map.
   - For any map there are several images.
   - For observations these are the observed image (Obs/Drt), [for
     interferometer images these are identical, for single-dish images Drt is
     a regridded Obs], the primary beam, the synthesized beam and the current
     and previous residual. There is also an array that connects the individual
     input maps to the mosaiced map by giving for each pixel the index in the
     mosaiced array of the corresponding pixel. Values of -1 indicate pixels
     outside the mosaic map.
     For interferometer maps the shapeofObs, shapeofDrt and shapeofPrB shapes
     are identical, and the assoc array is filled.
     For single-dish maps the three shapes are all different and the Drt array
     is filled with the regridded observation.
   - For the mosaiced map there are the current and the previous estimate, the
     reference image, the gradient of X, H and J images and the second-derivate
     image. There is also an array of logicals to indicate the selected area.
     Some of these arrays are used for multiple purposes, to store intermediate
     results at times that they are not needed for their real purpose (e.g the
     second estimate array is used to store the metric).
   - Arrays are defined to hold the gaussian with which an image may be
     convolved. This array is the next power of 2 larger in x and y than the
     mosaiced map array.
   - Data storage can be organized in several ways.
     1) __CSTAR__ is defined:
        This only works on the CM5, with C*. All images are parallel variables.
     2) __CSTAR__ is not defined:
        Each image is stored as a single contiguous array. Addresses are found
        by adding the offset counter MemPixNum to the each of the start
        addresses (one for each image).

   - In the code itself data is accessed using the set of p_... defines, so that
     the code sees no difference for different memory organizations (and thus is
     easier to read).
*/
/******************************************************************************/

typedef struct memarr {
             Real_void *Obs;           shape *shapeofObs;

             Real_void *Drt;
             Real_void *Res[2];
              int_void *assoc;         shape *shapeofDrt;
             int        fs, sf;

             Real_void *PrB;           shape *shapeofPrB;

             Real_void *SyB;           shape *shapeofBea;
            cmplx_void *Cov;           shape *shapeofCov;
             int        ftid;

             Real_void *Mos[2];
             int        FS, SF;
             Real_void *Ref;
             Real_void *GrH;
             Real_void *GrX;
             Real_void *GrJ;
             Real_void *GGX;
          logical_void *Sel;           shape *shapeofMos;

             Real_void *Gau;           shape *shapeofGau;
            cmplx_void *GCv;           shape *shapeofGCv;
             int        gauftid;

        } MEMARR;

/*

/******************************************************************************/
/*    <<< MAP structs >>>                               99 +  100 =  199 SETUP
/******************************************************************************/
/*
      A datatype ONEMAP is defined that consists of structs describing the
   related datasets of the observation: one struct for the input data
   (.Observation), one for the regridded input data in case of single-dish
   data (.DirtyMap) [identical to .Observation for interferometer data], one for
   the primary beam (.PrimaryBeam), one for the synthesized beam (.SynthBeam).
   There are the .PB and .SB structs for the beams. Then there is a struct that
   described the selected region (.Region).
      A MEMARR struct holds the pointers to the memory arrays of this map.
   Finally, there is a pointer to the address of the next ONEMAP variable,
   making a linked list of ONEMAP structs so that there is no hard limit to the
   number of input datasets.

      The MOSMAP variable contains pointers to structs containing information to
   describe the mosaiced map: the .MosaicMap DATASET points to the result; the
   the .Initial DATASET contains the parameters of the initial model; the
   .Reference DATASET is the reference used in the calculation of entropy, and
   can be read in, or have a fixed value. The .Convolved, .Residual and .Final
   DATASETs describe the possible output maps. The .Gaussian DATASET is used to
   describe the convolving gaussian.
   RestoringBeam holds the parameters of the restoring gaussian beam.


   MosMap and Maps are declared as global variables in routine MapStructs, for
   a subtle technical reason, having to do with being able to use two CPUs. It
   is not safe to send over actual addresses from one machine to another. Thus,
   when using the Read/WriteData functions, the arguments are numbers, not real
   addresses, even though it is logical to make them look like real addresses
   in the function calls. Deep down, in routine ArraySelection_To_Pointer, a
   conversion is done, on the remote machine only. But then the addresses of
   the MosMap and Maps structs are needed.

   The global variables are assigned to local ones in Local_main, Remote_main
   and SaveSet are further only transferred via function calls, except during
   IO.

   The ALLMAPS define is used to loop over maps.
*/
/******************************************************************************/

/* Full description of single image */
typedef struct onemap {
           logical IsIFmap, IsSDmap;
           DATASET Observation;
           DATASET DirtyMap;
           DATASET PrimaryBeam;
           DATASET SynthBeam;
           PBPAR   PB;
           BMPAR   BM;
           REGION  Region;
           MEMARR  MemArr;
           struct  onemap *NextMap;
        } ONEMAP;

/* Full description of mosaiced image */
typedef struct {
           DATASET MosaicMap;
           DATASET Initial;
           DATASET Reference;
           DATASET Convolved;
           DATASET Residual;
           DATASET Final;
           DATASET Gaussian;
           BMPAR   RestoringBeam;
           MEMARR  MemArr;
        } MOSMAP;

#define ALLMAPSI MapI=Maps; MapI!=NULL; MapI=MapI->NextMap
#define ALLMAPS  MapI=MapArrays(0,Maps); MapI!=NULL; MapI=MapArrays(1,MapI)

/*

/******************************************************************************/
/*    <<< CONTROL structs >>>                           38 +   99 =  137 SETUP
/******************************************************************************/
/*
  The Flags array (defined in 'main') contains some flags that are used to make
  decisions.
*/
/******************************************************************************/

#define N_MOSFLAGS 17
enum MOSFLAG {
   MOSCALC,                        /* actually calculate model (mode=m)       */
   LINMOS,    NOISE,               /* linear mosaic/noise map (mode=l,n)      */
   MAPRES,                         /* write individual residuals              */
   WRITERES,  WRITECNV, WRITEFIN,  /* write other outputs (mode=r,c,f)        */
   PBC,       PBCINV,              /* primary beam correction (mode=p)        */

   READREF,   READINI,             /* reference/initial (from keywords)       */

   MOSAIC,                         /* calculate mosaic map (mode=m|r|c|f|l|n) */
   WRITEMOS,                       /* write model output (mode=m|l|n)         */
   READMOD,                        /* read model (mode=r|c|f, not m)          */
   READBEAMS,                      /* read beams (mode=m|r|f)                 */
   CALCGAU,                        /* calculate gaussian (mode=c|f)           */
   FULLSIZE                        /* determines size of mosaic (mode=l|n)    */
};

/******************************************************************************/
/*
   The ALLLM   define is used to loop over all Lagrange Multipliers.
   The ALLXLM  define is used to loop over all X-related Lagrange Multipliers.

   The CONTROL struct contains the parameters that make choices.

   * First some that allow fine tuning of some steps in the algorithm.
     Normally, only the default values should be used. The choices exist to
     allow testing, and some control for development.
   - SameAsMaxen: To fake MAXEN, for testing (may no longer be accurate)
          SameAsMaxen means:
          0:   more correct... (default)
          1:   GradJ calc for interpolation before Q change
               change Lagrange multipliers right away
          2: + recalculate metric before stepping
          3: + scale limits by target
          4: + clip does not always decrease
          5: + Q from square
          6: + variance=1
   - Choice_Interpolate: If TRUE, do interpolation of step using J_0 and J_1.
          default: TRUE
   - Choice_MagicQ: Choose the magic formula for changing Q.
          default: 1
          1: use MAXEN magic formula
   - Choice_Norm1: Use GradH.GradH or Grad1.Grad1 for norm.
          default: 1
          1: Norm1 = HH + sum( lm^2 * XX )
          2: Norm1 = FF
   - Choice_MagicLM: Apply magic formula to limit Lagrange Multipliers.
          default: 1
          0: no changes
          1: change with quadratic solution if |dlm/lm|<0.5, damping otherwise
          2: change by damping, always
          3: change with quadratic solution, always
          4: change by damping if normB>normA
          5: change with quadratic solution, using oldNorm
          (normB=JJ/HH; normA=JJ/norm1; oldNorm=normA on previous iteration
   - Choice_PosLM: If true, Lagrange Multipliers are definite positive.
          default: TRUE

   * Control parameters decoded from the input the user gives for keywords
     measure=, reference=, tol=, maxiters=, lm0= and flux=,
   - EntropyMeasure indicates which entropy measure is used
   - RefOption tells which reference map to make
     RefClip is used to clip the reference in order to define a region
   - ClipIt indicates how the model must be clipped, which depends on the
     measure chosen.
          0: no clipping
          1: new clip becomes min of old clip and factor*datamin
          2: new clip becomes factor*datamin
          3: new clip becomes factor*old clip
   - Tolerance is the required accuracy in the chi^2 and F fit
     Epsilon is the required accuracy in the MEM convergence criterion
     MaxRatio limits the step taken.
   - MaxIters tell how many passes may at most be made.

   - NLM is the actual number of Lagrange multiplier used, set equal to nLM.
   - N is the apparent number of Lagrange multipliers, one for each input map.
   - LM0: array with initial values of Lagrange multipliers
   - TargetChiSq gives the targets for the Chi squared, one for each map.
     The array is allocated after the number of maps is known.
   - TargetFlux is the target for the flux.
     At the start of an iteration 'TargetFlux' is set equal to an element of
     'TargetFluxes', corresponding to the plane mosaic is working on.
     If the flux is not fitted, 'TargetFlux' is allowed to change'
   - TargetFluxes is the user specification for the target flux, one per channel
     used to constrain if >0; estimated if =0; used as initial estimate if <0);
     Saved to be able to start anew for each plane.
*/
/******************************************************************************/

#define nLM 2
#define LMflx 0
#define LMint 1
#define LMsd  1
#define ALLLM  N=0; N<CTRL->N; N++
#define ALLXLM N=1; N<CTRL->N; N++

typedef struct {
           int     SameAsMaxen, Choice_MagicQ, Choice_Norm1, Choice_MagicLM;
           logical Choice_Interpolate, Choice_PosLM;

           enum Measures { NOMEAS, GULL, CORN } EntropyMeasure;
           enum RefOptions { REF_FLAT, REF_PB, REF_MAP, REF_CLIPPED } RefOption;
           double  RefClip;

           double  Tolerance, Epsilon, MaxRatio;
           int     MaxIters;

           int     ClipIt; double ClipFactor;

           int     NLM, N;
           double *LM0;
           double *TargetChiSq;
           double *TargetFluxes, TargetFlux; int nchan;

        } CONTROL;

/******************************************************************************/
/*
   The STATS struct contains variables to store changing intermediate results
   that are used for control during the calculations.

   - Iteration is the number of iterations
   - Clip is the cliplevel imposed to limit the step for very small values
   - MagicQ is used to change Q^2 in later iterations
   - NormGJ, Norm2GJ, oldNormGJ, Norm1:
                       vector lengths needed to limit change in Lagrange mults
   - S_0, S_1:         inproducts needed to calculate interpolation fraction
   - Scale:            scalefactor to limit step size
   - Frac:             fraction by which step must be interpolated

   - many different sums, some of which are pointers to an array allocated
     after the number of input maps is known.

   - LM:               array with Lagrange multipliers
   - dLM:              array with changes in Lagrange multipliers
*/
/******************************************************************************/

typedef struct {
           int     Iteration;
           Real    Clip;

           double  MagicQ;
           double  NormGJ, Norm2GJ, oldNormGJ, Norm1;
           double  S_0, S_1;
           Real    Scale, Frac;

           double *ChiSq, modelFlux, rms;
           double   H,  J,  *X;
           double  HH, JJ, *JX, *XX;

           double *LM, *dLM;

        } STATS;

Global Real G_Clip;
#define InitClip G_Clip=Stats->Clip;
#ifdef __CSTAR__
#define ApplyClip(a) a >?= G_Clip
#else
#define ApplyClip(a) a = a > G_Clip ? a : G_Clip
#endif
