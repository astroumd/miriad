/*----------------------------------------------------------------------------
-- mosaic_alloc.c --
/*----------------------------------------------------------------------------*/
#include "mosaic.h"
/*----------------------------------------------------------------------------*/

/******************************************************************************/
/* <<< INITIALIZE MEMORY >>>                           375 +  168 =  543 SETUP
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*
   ALLOCATIONS AND INITIALIZATION OF ARRAYS
*/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*    <<< Create datapointers >>>                      264 +   90 =  354 SETUP
/******************************************************************************/
/*
   Allocation utilities.
   BufferAddress is the place where the allocation starts.
   OFFSET is used to get the start of individual arrays (OFFSET in bytes)

   The Palloc macros hides the differences between the allocations.
   - On CM5: use the Create... routines to allocate parallel arrays.
   - On SGI: allocate a single array of total length, then in Create... routines
     set pointers to areas within the large array.
   - Elsewhere: allocate each array individually in the Create... routines.
*/
/******************************************************************************/

private int OFFSET;
private char *BufferAddress;
private Real *ScratchAddress;
        Real *GetScrAddress() { return( ScratchAddress ); }

private void AllocateBuffer( Sizes )
int Sizes[];
{
   int size = Sizes[0]+Sizes[1]+Sizes[2]+Sizes[3]+Sizes[4];
   Malloc( BufferAddress, char, size );
   ScratchAddress = (Real *)(BufferAddress+size-Sizes[4]);
}

#ifdef __CSTAR__
#  define Palloc(v,t,s,nx,ny) if(doalloc) v=palloc(s,sizeof(t:(s)))
#elif  mips
#  define Palloc(v,t,s,nx,ny) if(doalloc) v=(t *)(BufferAddress+OFFSET); \
                                          OFFSET+=sizeof(t)*(nx)*(ny)+60
#else
#  define Palloc(v,t,s,nx,ny) if(doalloc) Malloc(v,t,(nx)*(ny))
#endif

/******************************************************************************/
/*
   First calculate the total needed space to allocate, using the Create...
   routines.
   Then use one of three schemes to allocate parallel arrays, on the remote
   machine or when running locally. Always allocate IO and FT scratch space.

   During the first pass, doalloc is false, which means that the Create...
   routines only do the calculation of arrays sizes, but the actual allocation
   is skipped. This is done during the second pass.

   After the second loop, also set the global pointers for the mosaic arrays.
*/
/******************************************************************************/

void CreateDataPointers( MosMap, Maps, Flags )
MOSMAP  *MosMap;
ONEMAP  *Maps;
logical  Flags[];
{
   logical DTMremoteExec();

   private int  CreateMosMemory();
   private int  CreateMapMemory();
   private int  CreateBeaMemory();
   private int  CreateGauMemory();
   int          CalcScratch();
   private void AllocateBuffer();
   ONEMAP      *MapI;
   int          PASS;
   int          Sizes[5];
   logical      doalloc;
   Sizes[0]=Sizes[1]=Sizes[2]=Sizes[3]=Sizes[4]=0;

   TRACE("CreateDataPointers");

if( DTMremoteExec("CREATEDATAPOINTERS") ) {

   for( PASS=1; PASS<=2; PASS++ ) {
      doalloc = PASS == 2;
      OFFSET  = 0;

      if( Flags[MOSAIC] ) {
                              Sizes[0]  = CreateMosMemory(doalloc,MosMap,Flags);
         if( Flags[CALCGAU] ) Sizes[1]  = CreateGauMemory(doalloc,MosMap      );
         for( ALLMAPSI ) {
                              Sizes[2] += CreateMapMemory(doalloc,MapI,MosMap);
         if(Flags[READBEAMS]) Sizes[3] += CreateBeaMemory(doalloc,MapI       );
         }
      } else {
         for( ALLMAPSI )      Sizes[2] += CreateMapMemory(doalloc,MapI,MosMap);
      }

      if( PASS==1 ) Sizes[4] = CalcScratch( MosMap, Maps, Flags );

      if( PASS==1 ) AllocateBuffer( Sizes );
   }

   (void)DTMremoteExec("READY");

} else { /* !DTMremoteExec (two CPU, local machine) */

   Sizes[4] = CalcScratch( MosMap, Maps, Flags );
   AllocateBuffer( Sizes );

}}

/******************************************************************************/
/*
   Create memory array to hold the estimate, the old estimate, the reference,
   the gradients, and the second derivative.

   (Palloc increases OFFSET, if needed).
*/
/******************************************************************************/

private int CreateMosMemory( doalloc, MosMap, Flags )
logical doalloc;
MOSMAP *MosMap;
logical Flags[];
{
   void         Messages_Init();
   private void AllocateShape();
   int          BASE=OFFSET;
   MEMARR      *MemArr = &MosMap->MemArr;
   int          xlen   =  MosMap->MosaicMap.Coords.XLEN;
   int          ylen   =  MosMap->MosaicMap.Coords.YLEN;
   int          gxlen  =  MosMap->Gaussian.Coords.XLEN;
   int          gylen  =  MosMap->Gaussian.Coords.YLEN;

   if(doalloc) TRACE("CreateMosMemory");
   if(doalloc) Messages_Init( "Memory", MosMap->MosaicMap.name );

   if(doalloc) AllocateShape( &MemArr->shapeofMos, xlen, ylen );

   MemArr->FS=0; MemArr->SF=1;
   Palloc( MemArr->Mos[0], Real,    *(MemArr->shapeofMos), xlen, ylen );
   Palloc( MemArr->Mos[1], Real,    *(MemArr->shapeofMos), xlen, ylen );
   Palloc( MemArr->Ref,    Real,    *(MemArr->shapeofMos), xlen, ylen );
#ifdef __CSTAR__
   Palloc( MemArr->GrX,    Real,    *(MemArr->shapeofMos), xlen, ylen );
#else
   if( Flags[CALCGAU] ) {
   Palloc( MemArr->GrX,    Real,    *(MemArr->shapeofMos), 2*(gxlen+2), gylen );
   } else {
   Palloc( MemArr->GrX,    Real,    *(MemArr->shapeofMos), xlen, ylen );  }
#endif
   Palloc( MemArr->GrH,    Real,    *(MemArr->shapeofMos), xlen, ylen );
   Palloc( MemArr->GrJ,    Real,    *(MemArr->shapeofMos), xlen, ylen );
   Palloc( MemArr->GGX,    Real,    *(MemArr->shapeofMos), xlen, ylen );
   Palloc( MemArr->Sel,    logical, *(MemArr->shapeofMos), xlen, ylen );

   MemArr->Obs   = NULL;
   MemArr->Drt   = MemArr->Res[0] = MemArr->Res[1] = NULL;
   MemArr->assoc = NULL;
   MemArr->PrB   = NULL;
   MemArr->SyB   = NULL;
   MemArr->Cov   = NULL;
   MemArr->Gau   = NULL;
   MemArr->GCv   = NULL;

   return(OFFSET-BASE);
}

/******************************************************************************/
/*
   Create array to hold 1) input and dirty map data, 2) association, 3) primary
   beam, 4) residuals.

   For single-dish maps, create array to hold 1) input data, 2) dirty map,
   3) primary beam, 4) residuals.

   Palloc increases OFFSET, if needed.
*/
/******************************************************************************/

private int CreateMapMemory( doalloc, MapI, MosMap )
logical doalloc;
ONEMAP *MapI;
MOSMAP *MosMap;
{
   void         Messages_Init();
   private void AllocateShape();
   int          BASE=OFFSET;
   MEMARR      *MemArr  = &MapI->MemArr;
   MEMARR      *MosMem  = &MosMap->MemArr;
   int          Obsxlen = MapI->Observation.Coords.XLEN;
   int          Obsylen = MapI->Observation.Coords.YLEN;
   int          Mapxlen = MapI->DirtyMap.Coords.XLEN;
   int          Mapylen = MapI->DirtyMap.Coords.YLEN;
   int          PrBxlen = MapI->PrimaryBeam.Coords.XLEN;
   int          PrBylen = MapI->PrimaryBeam.Coords.YLEN;
   int          Mosxlen = MosMap->MosaicMap.Coords.XLEN;
   int          Mosylen = MosMap->MosaicMap.Coords.YLEN;

   if(doalloc) TRACE("CreateMapMemory");
   if(doalloc) Messages_Init( "Memory", MapI->Observation.name );

   if(doalloc) AllocateShape(     &MemArr->shapeofObs,  Obsxlen, Obsylen );
   Palloc( MemArr->Obs,    Real, *(MemArr->shapeofObs), Obsxlen, Obsylen );

   if( MapI->IsIFmap ) {
   MemArr->shapeofDrt = MemArr->shapeofObs;
   MemArr->Drt        = MemArr->Obs;
   Palloc( MemArr->assoc,  int,  *(MemArr->shapeofDrt), Mapxlen, Mapylen );
   } else {
   if(doalloc) AllocateShape(     &MemArr->shapeofDrt,  Mapxlen, Mapylen );
   Palloc( MemArr->Drt,    Real, *(MemArr->shapeofDrt), Mapxlen, Mapylen );
   }

   if(doalloc) AllocateShape(     &MemArr->shapeofPrB,  PrBxlen, PrBylen );
   Palloc( MemArr->PrB,    Real, *(MemArr->shapeofPrB), PrBxlen, PrBylen );

   MemArr->fs=0; MemArr->sf=1;
   Palloc( MemArr->Res[0], Real, *(MemArr->shapeofDrt), Mapxlen, Mapylen );
   Palloc( MemArr->Res[1], Real, *(MemArr->shapeofDrt), Mapxlen, Mapylen );

   if( doalloc ) {
   MemArr->Mos[0] = MosMem->Mos[0];     MemArr->Mos[1] = MosMem->Mos[1];
   MemArr->Sel    = MosMem->Sel;        MemArr->Ref    = MosMem->Ref;
   MemArr->GrX    = MosMem->GrX;        MemArr->GrH    = MosMem->GrH;
   MemArr->GrJ    = MosMem->GrJ;        MemArr->GGX    = MosMem->GGX;
   }
   MemArr->Gau = NULL;

   return(OFFSET-BASE);
}

/******************************************************************************/
/*
   Create array to hold beams.
   For interferometer maps, this is the synthesized beam and the coverage array.
   For single-dish maps, this is just the coverage array.

   On non-CM the FT of the beam is xlen/2+1 wide, not xlen/2, so space for one
   extra line in y at the end is created.
   On the CM, this is not needed, since the FFTs are done differently.

   (Palloc increases OFFSET, if needed).
*/
/******************************************************************************/

private int CreateBeaMemory( doalloc, MapI )
logical doalloc;
ONEMAP *MapI;
{
   void         Messages_Init();
   private void AllocateShape();
   int          BASE=OFFSET;
   MEMARR      *MemArr = &MapI->MemArr;
   int          xlen = MapI->IsIFmap ? MapI->SynthBeam.Coords.XLEN
                                     : MapI->PrimaryBeam.Coords.XLEN;
   int          ylen = MapI->IsIFmap ? MapI->SynthBeam.Coords.YLEN
                                     : MapI->PrimaryBeam.Coords.YLEN;

   if(doalloc) TRACE("CreateBeaMemory");
   if(doalloc) {
   if(MapI->IsIFmap) Messages_Init( "Memory",         MapI->SynthBeam.name   );
   else              Messages_Init( "Memory of beam", MapI->PrimaryBeam.name );
   }

   if(doalloc) AllocateShape(   &MemArr->shapeofCov,  (xlen+2)/2, ylen );
   Palloc( MemArr->Cov, cmplx, *(MemArr->shapeofCov), (xlen+2)/2, ylen );

   if(doalloc) AllocateShape(   &MemArr->shapeofBea,  xlen, ylen );
   if( MapI->IsIFmap ) {
#ifdef __CSTAR__
   Palloc( MemArr->SyB, Real,  *(MemArr->shapeofBea), xlen, ylen );
#else
   if(doalloc) MemArr->SyB = (Real *)MemArr->Cov;
#endif
   }

   return(OFFSET-BASE);
}

/******************************************************************************/
/*
   Create the array to hold the gaussian with which to convolve the result.

   The size of the gaussian array is the next power of 2 larger than the size
   of the mosaiced map. This allocation is not done if neither the convolved nor
   the final map is written.

   For non-cm5, the memory for the GrX array is re-used. Its allocation takes
   this possibility into account.

   (Palloc increases OFFSET, if needed).
*/
/******************************************************************************/

private int CreateGauMemory( doalloc, MosMap )
logical doalloc;
MOSMAP *MosMap;
{

   private void AllocateShape();
   int          BASE=OFFSET;
   MEMARR      *MemArr = &MosMap->MemArr;
   int          xlen   = MosMap->Gaussian.Coords.XLEN;
   int          ylen   = MosMap->Gaussian.Coords.YLEN;

   if(doalloc) TRACE("CreateGauMemory");

   if(doalloc) AllocateShape( &MemArr->shapeofGau,  xlen,      ylen );
   if(doalloc) AllocateShape( &MemArr->shapeofGCv, (xlen+2)/2, ylen );

#ifdef __CSTAR__
   Palloc( MemArr->Gau, Real,  *(MemArr->shapeofBea),  xlen *      ylen );
   Palloc( MemArr->GCv, cmplx, *(MemArr->shapeofGCv), (xlen+2)/2 * ylen );
#else
   if(doalloc) MemArr->Gau = (Real  *)MemArr->GrX;
   if(doalloc) MemArr->GCv = (cmplx *)MemArr->GrX;
#endif
   return(OFFSET-BASE);
}

/******************************************************************************/
/*
   Find the amount of necessary scratch space. These addresses are used for
   multiple purposes. Allocate the minimum amount of space necessary.

   - First figure out the space needed for fourier transforms.
     If a convolution with a gaussian is to be done, a mosaicmap plane extended
     to the next power of two is needed, else a plane as large as the largest
     map. This plane is of type complex.
     Add to this some smaller scratch arrays.
     For C*: add space for extra front-end arrays.
     Use this space in SetFTScratch() for (cmplx *)uvPln, etc
     Result in ScrSize[0].
   - Find largest plane to do IO on. Use this space in InitIObuffer() for
     (float *)IObuf.Data, (int *)IObuf.Mask
     Result in ScrSize[1].
   - Get space to calculate gaussian convolution, only if not C*. Use for
     (Real *)p_x, (Real *)p_y in GaussCreate().
     Result in ScrSize[2].

   - Required scratch space is maximum value of the three cases.
*/
/******************************************************************************/

int CalcScratch( MosMap, Maps, Flags )
MOSMAP  *MosMap;
ONEMAP  *Maps;
logical  Flags[];
{

   int     NextPow2();
   COORDS *Coo;
   int     ScrSize[3];
   int     maxxlen, maxylen, planesize;
   ONEMAP *MapI;
   TRACE("CalcScratch");

   if( Flags[CALCGAU] ) {
      maxxlen = NextPow2( MosMap->MosaicMap.Coords.XLEN );
      maxylen = NextPow2( MosMap->MosaicMap.Coords.YLEN );
   } else {
      maxxlen =           MosMap->MosaicMap.Coords.XLEN;
      maxylen =           MosMap->MosaicMap.Coords.YLEN;
   }
   for(ALLMAPSI) {
      Coo = MapI->IsIFmap ?
               (Flags[READBEAMS]?&MapI->SynthBeam.Coords:&MapI->DirtyMap.Coords)
                          :
                &MapI->PrimaryBeam.Coords;
      maxxlen = max( maxxlen, Coo->XLEN );
      maxylen = max( maxylen, Coo->YLEN );
   }
   planesize = (maxxlen/2+1) * maxylen;
   ScrSize[0]  = 2 * planesize;
#ifdef mips
   ScrSize[0] += 2 * planesize;
#else
   ScrSize[0] += 2*(maxxlen+2);
#endif
#ifdef __CSTAR__
   ScrSize[0] += 4 * planesize;
#endif

   planesize = maxxlen * maxylen;
   ScrSize[1] = ( 1 + sizeof(int)/sizeof(float) ) * planesize;

   return( sizeof(Real) * max(ScrSize[0],ScrSize[1]) );
}

/******************************************************************************/
/*
   Calculate how much actual space to allocate, making it a multiple of the
   number of nodes under C*, to avoid an extra mask. The extra memory will not
   be a problem, and the dummy calculations neither.
*/
/******************************************************************************/

private int n_to_Allocate( nx, ny )
int nx, ny;
{
#ifdef __CSTAR__
   return(  ( (int)( (nx*ny-1)/N_NODES) + 1 ) * N_NODES  );
#else
   return( nx * ny );
#endif
}

/******************************************************************************/
/*
   Create a variable of type shape that can be pointed to by ShapeInStruct.
   Then create a new shape in that space.
*/
/******************************************************************************/

private void AllocateShape( aShape, xlen, ylen )
shape   **aShape;
int       xlen, ylen;
{
   private int n_to_Allocate();
   Malloc( *aShape, shape, 1 );
#ifdef __CSTAR__
   **aShape = allocate_shape( *aShape, 1, n_to_Allocate(xlen,ylen) );
#else
   (*aShape)->start = 0;
   (*aShape)->end   = n_to_Allocate(xlen,ylen);
   (*aShape)->size  = (*aShape)->end - (*aShape)->start;
   (*aShape)->xlen  = xlen;
   (*aShape)->ylen  = ylen;
   (*aShape)->nsel  = (*aShape)->size;
#endif
}
