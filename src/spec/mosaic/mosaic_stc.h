/*----------------------------------------------------------------------------
-- mosaic_stc.h --
/*----------------------------------------------------------------------------*/
#include "mosaic_def.h"
/*----------------------------------------------------------------------------*/

/******************************************************************************/
/* <<< ORGANIZATIONAL STRUCTS >>>                      423 +  602 = 1025 SETUP
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*
   DEFINITIONS OF ORGANIZATIONAL STRUCTS:
   COORDS, PBPAR, BMPAR, DATASET, REGION
*/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*    <<< COORDS struct >>>                             97 +   73 =  170 SETUP
/******************************************************************************/
/*
   - Coordinates:
      naxis                   = number of axes;
      axisnr                  = ordering of axes in dataset;
      axlen                   = length of axes;
      cubesize                = size of subcubes = Prod(j<i) axlen
      orgcubesize             = size of subcubes, axes in original order
      blc,trc                 = lower,upper edge counts in absolute pixels
      crpix,crval,cdelt,ctype = defines coordinate system
      CurPlane                = plane program currently is working on
   - cubesize and orgcubesize are one longer than the others, to hold the
     cubesize of a pixel; relative to the other arrays they are shifted by 1.
   - crval gives the reference coordinate.
   - crshf stores by how much the image center was shifted from the pointing
     center.
   - cdelt[RA_SEC] contains the value of cdelt[RA_AXIS]/cos(cdelt[DC_AXIS]),
     which is the grid spacing in the right ascension coordinate corrected for
     the declination, in radians (and the reason the cdelt array is 1 longer
     than the others).
   - crpix is defined as the pixel number corresponding to the position of
     coordinate crval; it is defined in a system in which the first pixel is
     number 1, i.e. as a counter.
   - prval, pdelt and prval represent crval, cdelt and crpix, but now referred
     to the projection center of the map, as determined from crval+crshf.
   - axlen through ctype are sorted so that the RA-axis is the first, the
     DEC-axis the second and the FREQ-axis the third.
     OpenDataSet, SetupDataSet, GetSetCoords and axprint are the only places
     where the program knows about the possibility that axes can be in any
     order, elsewhere they are sorted as above.
   - project determines whether the crpix or the prpix coordinates are
     used in the conversion from pixels to coordinates.
     Use pr... if project=TRUE, and cr... if project=FALSE.
*/
/******************************************************************************/

#define AITEMLEN   10  /* maximum length of a character header element        */

typedef struct {
           AXIS    naxis;
           AXIS    axisnr[MAXNAX];
           int     axlen[MAXNAX];
           int     cubesize[MAXNAX+1], orgcubesize[MAXNAX+1];
           int     nPoints;
           int     blc[MAXNAX], trc[MAXNAX];
           double  crval[MAXNAX], crshf[MAXNAX], prval[MAXNAX];
           double  cdelt[MAXNAX+1],              pdelt[MAXNAX+1];
           double  crpix[MAXNAX],                prpix[MAXNAX];
           char    ctype[MAXNAX][AITEMLEN];
           int     CurPlane;
           logical project;
        } COORDS;

#define XLEN axlen[RA_AXIS]
#define YLEN axlen[DC_AXIS]
#define ZLEN axlen[FQ_AXIS]

#ifdef DEFVARS

/******************************************************************************/
/*
   CooCopy copies the COORDS struct.
*/
/******************************************************************************/

void CooCopy( CoordsOut, CoordsIn )
COORDS *CoordsOut;
COORDS *CoordsIn;
{
   register AXIS n;
   CoordsOut->naxis   = CoordsIn->naxis;
   CoordsOut->nPoints = CoordsIn->nPoints;
   for( n=AXIS1; n<=CoordsIn->naxis; n++ ) {
      CoordsOut->axisnr[n]      = CoordsIn->axisnr[n];
      CoordsOut->axlen[n]       = CoordsIn->axlen[n];
      CoordsOut->cubesize[n]    = CoordsIn->cubesize[n];
      CoordsOut->orgcubesize[n] = CoordsIn->orgcubesize[n];
      CoordsOut->blc[n]         = CoordsIn->blc[n];
      CoordsOut->trc[n]         = CoordsIn->trc[n];
      CoordsOut->crval[n]       = CoordsIn->crval[n];
      CoordsOut->cdelt[n]       = CoordsIn->cdelt[n];
      CoordsOut->crpix[n]       = CoordsIn->crpix[n];
      CoordsOut->crshf[n]       = CoordsIn->crshf[n];
      CoordsOut->prval[n]       = CoordsIn->prval[n];
      CoordsOut->pdelt[n]       = CoordsIn->pdelt[n];
      CoordsOut->prpix[n]       = CoordsIn->prpix[n];
      StrCpy( CoordsOut->ctype[n], CoordsIn->ctype[n] );
   }
   CoordsOut->cubesize[n]    = CoordsIn->cubesize[n];
   CoordsOut->orgcubesize[n] = CoordsIn->orgcubesize[n];
   CoordsOut->cdelt[RA_SEC]  = CoordsIn->cdelt[RA_SEC];
   CoordsOut->pdelt[RA_SEC]  = CoordsIn->pdelt[RA_SEC];
   CoordsOut->CurPlane       = CoordsIn->CurPlane;
}

void CooSetp( Coords )
COORDS *Coords;
{
   AXIS n;
   for( n=AXIS1; n<Coords->naxis; n++ ) {
      Coords->prval[n] = Coords->crval[n];
      Coords->prpix[n] = Coords->crpix[n];
      Coords->pdelt[n] = Coords->cdelt[n];
   }
   Coords->pdelt[RA_SEC] = Coords->cdelt[RA_SEC];
}

/******************************************************************************/
/*
   Supply two functions to convert from pixels to coordinates and vice versa.
   This includes a possible shift of the projection center from crval, as
   expressed by the fact that prpix, prval and pdelt are used.
*/
/******************************************************************************/

double  ConvertToPixel( Coordinate, Coords, axis )
double  Coordinate;
COORDS *Coords;
AXIS    axis;
{ double cdelt;
  if( Coords->project==TRUE ) {
  cdelt = axis==RA_AXIS ? Coords->pdelt[RA_SEC] : Coords->pdelt[axis];
  return( ( Coordinate - Coords->prval[axis]) / cdelt + Coords->prpix[axis] );
  } else {
  cdelt = axis==RA_AXIS ? Coords->cdelt[RA_SEC] : Coords->cdelt[axis];
  return( ( Coordinate - Coords->crval[axis]) / cdelt + Coords->crpix[axis] );
  }
}

double  ConvertToCoord( Pixel, Coords, axis )
double  Pixel;
COORDS *Coords;
AXIS    axis;
{ double cdelt;
  if( Coords->project==TRUE ) {
  cdelt = axis==RA_AXIS ? Coords->pdelt[RA_SEC] : Coords->pdelt[axis];
  return( ( Pixel      - Coords->prpix[axis] ) * cdelt + Coords->prval[axis] );
  } else {
  cdelt = axis==RA_AXIS ? Coords->cdelt[RA_SEC] : Coords->cdelt[axis];
  return( ( Pixel      - Coords->crpix[axis] ) * cdelt + Coords->crval[axis] );
  }
}

/******************************************************************************/
/*
   Function ConvertPixel converts the pixel # in the system of the set described
   by SetCoo, to the pixel # in the system of the set described by RefCoo.
*/
/******************************************************************************/

double ConvertPixel( pixel, SetCoo, RefCoo, axis )
double  pixel;
COORDS *SetCoo, *RefCoo;
AXIS    axis;
{
   double  ConvertToCoord(), ConvertToPixel();
   return( ConvertToPixel( ConvertToCoord(pixel,SetCoo,axis), RefCoo, axis ) );
}

/******************************************************************************/
/*
   OrgPixelToSortPixel converts a pixel offset of a coordinate in the original
   axis ordering to the offset in the ordering given by the axisnr array (the
   inverse operation is never needed, thus not defined).
   (The cubesize array is one offset with respect to the others, in order to
   hold the size of a cube of dimension 0 (1), which is in cubesize[0])
*/
/******************************************************************************/

int OrgPixelToSortPixel( pixel, Coords )
int     pixel;
COORDS *Coords;
{
   register AXIS i, j;
   register int  offset;

   for( offset=0, i=AXIS1; i<=Coords->naxis; i++ ) {
      j = Coords->axisnr[i];
      offset += (  ( pixel / Coords->orgcubesize[j] ) % Coords->axlen[j]  ) *
                Coords->cubesize[i];
   }
   return( offset );
}

#endif /* DEFVARS */

/*

/******************************************************************************/
/*    <<< BEAM structs >>>                              49 +   47 =   96 SETUP
/******************************************************************************/
/*
   A primary beam can in principle be a dataset read from disk, but now it is
   assumed it is described by some parameters, stored in the PBPAR struct. An
   array with the primary beam corrections is created.

   The BMPAR struct collects a parametrization of the synthesized beam: the
   beam major and minor axis FWHM; the beam position angle; the power in the
   main beam lobe Q.
*/
/******************************************************************************/

#define NPOLYCOEFF 6
typedef struct {
           char    Telescope[AITEMLEN];
           double  freq, LimFreq; int freqnum;
           int     pbtype; double cutoff, coeff[NPOLYCOEFF];
           double  fwhm;
           double  xref, yref, xdelt, ydelt;
           int     npb; double Q;
           logical inverse;
        } PBPAR;

typedef struct {
           double  bmaj, bmin, bpa, Q;
           logical Qcircle;
           logical CreatedRB;
        } BMPAR;

/*

/******************************************************************************/
/*    <<< DATASET struct >>>                            99 +  100 =  199 SETUP
/******************************************************************************/
/*
   The DATASET struct collects all the information that describes a single
   dataset. The struct gives the name and unit the set is connected to, a string
   telling some routines whether this is an input, beam, mask, initial,
   reference or estimate dataset, a description of the coordinates, the min and
   max, the rms (input values, and rms of residual) and the variance (input
   value).
*/
/******************************************************************************/

typedef struct {
           char   *name; int Lun;
           char   *type;
           char    Object[AITEMLEN];
           COORDS  Coords;
           double  DataMin, DataMax, mean, rms, variance, weight;
           int     SetNum;
        } DATASET;
#define DNULL (DATASET *)NULL

/*

/******************************************************************************/
/*    <<< REGION struct >>>                             99 +  100 =  199 SETUP
/******************************************************************************/
/*
   The region selected in a dataset is described in the struct REGION. For a
   a full description, see the description of routine RegionDecode.
*/
/******************************************************************************/

#define MAXPOLYS   10  /* maximum number of polygons; Region struct array size*/
typedef struct {
           char     UserString[256];
           int      nPlanes, *Planes;
           int      nVertLists; int *VertList[MAXPOLYS];
           logical  MaskPresent;
           DATASET *Mask;
        } REGION;
