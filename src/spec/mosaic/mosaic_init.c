/*----------------------------------------------------------------------------
-- mosaic_init.c --
/*----------------------------------------------------------------------------*/
#include "mosaic.h"
/*----------------------------------------------------------------------------*/

/******************************************************************************/
/* <<< INITIALIZATIONS >>>                            1243 +  508 = 1751 USERIO
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*
   READ KEYWORDS AND INITIALIZE VARIABLES
*/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*    <<< List of calls >>>                            102 +   33 =  135 USERIO
/******************************************************************************/
/*
   Read all inputs and set everything up.

   - Start with setting a time marker, initializing the keyword routines,
     setting the Mos and Res array pointers, and getting control information.
   - Read the keywords related to map names (MapInputs). This returns the names
     and parameters of all input datasets (input, beam, reference, initial) and
     of the output dataset. The size and other parameters for the combined map
     are calculated. Several checks are made to make sure the inputs are
     compatible.
   - Determine a clean beam, based either on the beamsize keyword or on a
     combination of the synthesized beams.
   - Allocate memory.
   - Initialize the primary beam, second derivative and synthesized beam arrays.
   - Give the user information.
*/
/******************************************************************************/

#define TLI(s) Timer_List("LOCAL_INIT",s)
void Timer_List();

int Initialize( MosMap, Maps, Flags, CTRL, Stats )
MOSMAP  *MosMap;
ONEMAP  *Maps;
logical  Flags[];
CONTROL *CTRL;
STATS   *Stats;
{
   void keyfin_c(), keyl_c(); int keytest;
   void Timer_Start();
   void Abort();

   private void CTRLInputs();
   private void ModeInput();
   private void MapInputs();
   private void FluxInput();
   private void GetRestoringBeam();
           void ExchangeVariables();
           void Overview();
   TRACE("Initialize");

   Timer_Start("LOCAL_INIT"); /* Ends in SetupArrays */

   CTRLInputs(                              CTRL );
   ModeInput(                        Flags, CTRL );
   MapInputs(          MosMap, Maps, Flags, CTRL );
   FluxInput( MosMap->MosaicMap.Coords.ZLEN,CTRL );            TLI("keywords");

   if(Flags[READBEAMS])
   GetRestoringBeam(  &MosMap->RestoringBeam, Maps );

   ExchangeVariables(
           "SENDVARS", MosMap, Maps, Flags, CTRL, Stats );     TLI("exchange");

   Overview(           MosMap, Maps, Flags, CTRL );

   keyl_c( "keytest", &keytest, FALSE );
   keyfin_c();
   if( keytest ) Abort();

   return( Maps->Region.nPlanes );
}

/*

/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*    <<< Control IO >>>                                33 +   22 =   55 USERIO
/******************************************************************************/
/*
   Read all parameters necessary to steer the mosaicing.
   - The target flux; if given and >0 the flux is constrained to be this value
     If > 0: constrain the flux, if < 0: use as initial estimate
   - The maximum allowed number of iterations (default 20)
   - The tolerance in chi^2 and flux (default 5%)
     How close GradJ gets to 0 (1%)
     The maximum relative step (15%)
   - The entropy measure; eiter Gull's or Cornwell's (default Gull's)
   - Initial values for the alpha and beta multipliers (zero) [for continuation]
   - Algorithm selections
*/
/******************************************************************************/

private void CTRLInputs( CTRL )
CONTROL *CTRL;
{
   void keyd_c(), keyi_c(), keya_c(), keyl_c();
   char string[INSTRLEN];
   TRACE("CTRLInputs");

   keyi_c( "maxen",   &CTRL->SameAsMaxen,             0 );
   keyl_c( "interp",  &CTRL->Choice_Interpolate,   TRUE );
   keyi_c( "magicq",  &CTRL->Choice_MagicQ,           1 );
   keyi_c( "norm1",   &CTRL->Choice_Norm1,            1 );
   keyi_c( "magiclm", &CTRL->Choice_MagicLM,          1 );
   keyl_c( "posa",    &CTRL->Choice_PosLM,         TRUE );
   assert( (CTRL->Choice_Norm1==1)   | (CTRL->Choice_Norm1==2),
           "norm1= must be 1 or 2");
   assert( (0<=CTRL->Choice_MagicLM) & (CTRL->Choice_MagicLM<=5),
           "magiclm= must in range 0-5");

   CTRL->NLM = nLM;

   keyi_c( "maxiters", &CTRL->MaxIters, 20 );

   keyd_c( "tol", &CTRL->Tolerance, 0.05 );
   keyd_c( "tol", &CTRL->Epsilon,   0.01 );

   keya_c( "measure", string, "gull" );  CTRL->EntropyMeasure = NOMEAS;
   if( StrEqX( "gull",     string ) )    CTRL->EntropyMeasure = GULL;
   if( StrEqX( "cornwell", string ) )    CTRL->EntropyMeasure = CORN;
   assert( CTRL->EntropyMeasure != NOMEAS, "Illegal Entropy Measure" );

   switch( CTRL->EntropyMeasure ) {
   case GULL: CTRL->ClipIt = CTRL->SameAsMaxen < 4 ? 1 : 2; break;
   case CORN: CTRL->ClipIt = 0;                             break; }
   keyi_c( "clip", &CTRL->ClipIt, CTRL->ClipIt );

   CTRL->RefClip = ZERO;
   CTRL->RefOption = -1;

   Malloc( CTRL->LM0, double, CTRL->NLM );
   keyd_c( "lm0", &CTRL->LM0[LMint], ZERO );
   keyd_c( "lm0", &CTRL->LM0[LMflx], ZERO );
   keyd_c( "lm0", &CTRL->LM0[LMsd],  CTRL->LM0[LMint] );

}

/******************************************************************************/
/*
   Read the mode= keyword and set the appropriate flags.
*/
/******************************************************************************/

private void ModeInput( Flags, CTRL )
logical  Flags[];
CONTROL *CTRL;
{
   void    keya_c();
   void    SaveInput();
   char    string[INSTRLEN];
   int     mode=0;
   logical first=TRUE;

   Flags[MOSCALC] =
   Flags[MAPRES]  = Flags[WRITERES] = Flags[WRITECNV] = Flags[WRITEFIN] =
   Flags[LINMOS]  = Flags[NOISE]    =
   Flags[PBC]     = Flags[PBCINV]   =
   FALSE;

   keya_c( "mode", string, "\0" );
   if( string[0] == '\0' ) {
      Flags[MOSCALC]  = TRUE;
      Flags[WRITEFIN] = TRUE;
      mode = 1;
   } else {
      while( string[0] != '\0' ) {
         if( first ) {
            if( StrEq("model",    string) | StrEq("residual",string) |
                StrEq("convolved",string) | StrEq("final",   string) |
                StrEq("obsres",   string)                             ) mode=1;
            if( StrEq("linmos",   string) | StrEq("noise",   string) |
                StrEq("pbc",      string) | StrEq("invpbc",  string)  ) mode=2;
            first = FALSE;
         } else {
            assert( mode == 1 && (
                StrEq("model",    string) | StrEq("residual",string) |
                StrEq("convolved",string) | StrEq("final",   string) |
                StrEq("obsres",   string)
                                   ), "Illegal combination of modes" );
         }
         assert( mode != 0, "Illegal mode: %s", string );

         if( StrEq( "model",     string ) ) Flags[MOSCALC]  = TRUE;
         if( StrEq( "residual",  string ) ) Flags[WRITERES] = TRUE;
         if( StrEq( "convolved", string ) ) Flags[WRITECNV] = TRUE;
         if( StrEq( "final",     string ) ) Flags[WRITEFIN] = TRUE;
         if( StrEq( "obsres",    string ) ) Flags[MAPRES]   = TRUE;
         if( StrEq( "linmos",    string ) ) Flags[LINMOS]   = TRUE;
         if( StrEq( "noise",     string ) ) Flags[NOISE]    = TRUE;
         if( StrEq( "pbc",       string ) ) Flags[PBC]      = TRUE;
         if( StrEq( "invpbc",    string ) ) Flags[PBCINV]   =
                                            Flags[PBC]      = TRUE;
         keya_c( "mode", string, "\0" );
      }
   }

   Flags[MOSAIC]    = !Flags[PBC];
   Flags[WRITEMOS]  = Flags[MOSCALC] | Flags[LINMOS] | Flags[NOISE];
   Flags[READMOD]   = mode == 1 && !Flags[MOSCALC];
   Flags[READBEAMS] = mode == 1 &&
                      ( Flags[MOSCALC] | Flags[WRITERES] | Flags[WRITEFIN] |
                        Flags[MAPRES]  );
   Flags[READREF]   = FALSE;
   Flags[READINI]   = FALSE;
   Flags[CALCGAU]   = Flags[WRITECNV] | Flags[WRITEFIN];
   Flags[FULLSIZE]  = FALSE;

   SaveInput( CTRL->MaxIters, Flags[PBC], Flags[MAPRES] );
}

/*

/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*    <<< Map Initializations >>>                      345 +  113 =  458 USERIO
/******************************************************************************/
/*
   Get keyword values for:
     in= region#= planes= pbpar= beam= rms=
     sdin= sdpbpar= sdrms=
     initial= reference=
     out=
*/
/******************************************************************************/

private void MapInputs( MosMap, Maps, Flags, CTRL )
MOSMAP  *MosMap;
ONEMAP  *Maps;
logical  Flags[];
CONTROL *CTRL;
{
   private void MapInput();
   private void OutInput();
   private void SetSDmaps();
   private void ReferenceInput();
   private void InitialInput();
   TRACE("MapInputs");

      MapInput(               Maps, Flags, CTRL, TRUE  );   /* IF maps */
   if( Flags[MOSCALC] ) {
      MapInput(               Maps, Flags, CTRL, FALSE );   /* SD maps */
      OutInput(       MosMap, Maps, Flags              );
      SetSDmaps(      MosMap, Maps                     );
      ReferenceInput( MosMap,       Flags, CTRL        );
      InitialInput(   MosMap,       Flags              );
   } else {
      OutInput(       MosMap, Maps, Flags              );
   }
}

/******************************************************************************/
/*
   Read "in" or "sdin" keyword to get list of maps and single-dish maps. The
   IFmap variable makes the difference between the two. Each map is assigned a
   'ONEMAP' struct. Single-dish input maps are later regridded to the
   gridspacing of the mosaic map.

   The process goes as follows:
   - The pointers to the single maps are created.
   - The description of the observation is read from disk by GetSetCoords.
   - All projection centers are made equal by GetProjection.
   - For interferometer maps find out which region to deconvolve.
   - For interferometer maps, the full description is copied into the
     'DirtyMap' dataset.
     For single-dish maps, only the descriptory variables are copied, as a
     regridding is done, and the coordinate description in the 'DirtyMap'
     dataset is later made equal to that of the mosaic map.

   - Copy the description of the observation to the primary beam dataset.
     For single-dish maps this description will later be changed, using the fwhm
     found, to create a beam on the grid of the mosaic map.
   - PBPkeyword fills in the description of the primary beam dataset.

   - For interferometer maps, get the parameters of the synthesized beam and
     check if they are compatible with the observation.
   - The output map size in the linmos/noise mode is the merged inner quarters,
     unless at least one of the primary beams is 'none'.

   - Finally, the rms is read.
*/
/******************************************************************************/

private void MapInput( Maps, Flags, CTRL, IFmap )
ONEMAP  *Maps;
logical  Flags[];
CONTROL *CTRL;
logical  IFmap;
{
   void            keyf_c();
           void    InitSet();
           void    CloseDataSet();
   private void    GetSetCoords();
           void    CooCopy();
   private void    GetProjection();
   private void    GetRegion();
   private logical Compatibility();
           void    PBkeyword();
   private void    SBparams();
   private void    GetRMS();
   private void    Check();

   logical         MORE=TRUE;
   char            string[FILENAMELEN];
   ONEMAP         *NewMap, *MapI;
   int             SetNum;
   DATASET        *ObsSet, *DrtSet, *PrBSet, *SyBSet, *RefSet;
   COORDS         *ObsCoo, *DrtCoo, *PrBCoo, *SyBCoo, *RefCoo;
   REGION         *ObsReg,                            *RefReg;
   logical         Cmp=TRUE;

   TRACE("-- MapInput");

   if(  IFmap ) {
      MapI=Maps; MapI->NextMap=NewMap=NULL;
      SetNum=0;
   } else {
      MapI=Maps; while( MapI->NextMap!=NULL ) MapI=MapI->NextMap; NewMap=MapI;
      SetNum=MapI->Observation.SetNum;
   }
   RefSet = &Maps->Observation;
   RefCoo = &RefSet->Coords;
   RefReg = &Maps->Region;

   while( MORE ) {

/* Allocate ONEMAP */
      keyf_c( IFmap?"in":"sdin", string, "\0" );  if( string[0]=='\0' ) break;
      if( NewMap == NULL ) NewMap = MapI;
      else { Malloc(NewMap,ONEMAP,1); MapI->NextMap=NewMap; MapI=MapI->NextMap;}

/* Initialize general parameters */
      MapI->IsIFmap =  IFmap;
      MapI->IsSDmap = !IFmap;
      MapI->MemArr.Obs = NULL;
      SetNum++;

/* Set abbreviations */
      ObsSet = &MapI->Observation;  ObsCoo = &ObsSet->Coords;
      DrtSet = &MapI->DirtyMap;     DrtCoo = &DrtSet->Coords;
      PrBSet = &MapI->PrimaryBeam;  PrBCoo = &PrBSet->Coords;
      SyBSet = &MapI->SynthBeam;    SyBCoo = &SyBSet->Coords;
      ObsReg = &MapI->Region;

/* Initialize Observation DATASET */
      InitSet(       ObsSet, string, IFmap?"input":"sdinput", "new", SetNum );
      GetSetCoords(  ObsSet, TRUE, FALSE );
      GetProjection( ObsCoo, RefCoo );
      GetRegion(     ObsCoo, ObsReg, "region", IFmap?SetNum:0 );
      Cmp = Compatibility( IFmap, ObsSet,ObsReg, RefSet,RefReg ) & Cmp;

/* Initialize DirtyMap DATASET */
      StrCpy( DrtSet->Object, ObsSet->Object );
      InitSet(       DrtSet, string, "dirtymap", "new", SetNum );
      if(IFmap) CooCopy( DrtCoo, ObsCoo );

/* Initialize Primarybeam DATASET */
      InitSet(       PrBSet, string, IFmap?"prb":"sdprb", "new", SetNum );
      CooCopy(       PrBCoo, ObsCoo );
      PBkeyword(     IFmap?"pbpar":"sdpbpar", &MapI->PB, ObsSet->Lun, PrBCoo );
      CloseDataSet(  ObsSet, FALSE );

      if( Flags[PBC] ) {
         MapI->PB.inverse = !Flags[PBCINV];
         InitSet( &MapI->PrimaryBeam, string, "pbc", "append", SetNum );
         MapI->Observation.Coords.project =
         MapI->DirtyMap.Coords.project    =
         MapI->PrimaryBeam.Coords.project = FALSE;
      }

/* Initialize SynthBeam DATASET */
      MapI->BM.Qcircle = CTRL->SameAsMaxen < 5;
      if( Flags[READBEAMS] && IFmap ) {
         keyf_c( "beam", string, "\0" );
         assert( string[0]!='\0', "Not enough beam datasets given" );
         InitSet(       SyBSet, string, "synthesized beam", "new", SetNum );
         GetSetCoords(  SyBSet, TRUE, FALSE );
         Check(        "SynthBeam", SyBSet, ObsSet );
         SBparams(     &MapI->SynthBeam, &MapI->BM );
         CloseDataSet(  SyBSet, FALSE );
      }

/* Mapsize for LINMOS/NOISE */
      if( Flags[LINMOS] | Flags[NOISE] ) {
         Flags[FULLSIZE] = Flags[FULLSIZE] || MapI->PB.pbtype == 0;
         InitSet( SyBSet, "extent", "extent", "new", SetNum );
         CooCopy( SyBCoo, ObsCoo );
      }

/* Get rms */
      if( Flags[MOSAIC] ) GetRMS( IFmap?"rms":"sdrms", DrtSet );
      ObsSet->rms      = DrtSet->rms;
      ObsSet->variance = DrtSet->variance;
   }

   assert( NewMap != NULL, "No maps given" );
   assert( Cmp,            "Map descriptions do not match" );

   MapI->NextMap = NULL;
   CTRL->N = SetNum + 1;
}

/*

/******************************************************************************/
/*
   - The out= keyword is read.
   - If mode=model or mode=linmos was given, Flag[WRITEMOS] is TRUE. Then,
     prepare a dataset with the input string as name. For mode=model also append
     'model'. Next GetMosCoords figures out how to paste together all input maps
     and thus generates a description of the mosaiced dataset.
   - If mode=model was not given, Flag[READMOD] is TRUE. Then read the
     description of the out= dataset, and also do a calculation of what it
     should be using the input datasets. Then a compatibility check is made.
   - Lastly, the descriptions of the other output datasets are generated.
*/
/******************************************************************************/

private void OutInput( MosMap, Maps, Flags )
MOSMAP  *MosMap;
ONEMAP  *Maps;
logical  Flags[];
{
   void         keyf_c();
           void InitSet();
   private void GetSetCoords(), GetMosCoords(), GetGauCoords();
           void CooCopy();
   private void Check();
        logical SetPresent();

   char         string[FILENAMELEN];
   int          n; char num[3];
   ONEMAP      *MapI;
   COORDS      *MosCoo = &MosMap->MosaicMap.Coords;
   TRACE("-- OutInput");

   keyf_c( "out", string, "\0" );

   if(        Flags[WRITEMOS] ) {

      assert( string[0]!='\0', "No output dataset specified" );
      if( Flags[MOSCALC] ) {
         InitSet( &MosMap->MosaicMap, string, "estimate", "new",    0 );
         InitSet( &MosMap->MosaicMap, string, "model",    "append", 0 );
      }
      if( Flags[LINMOS] | Flags[NOISE] ) {
         InitSet( &MosMap->MosaicMap, string, "linmos",   "new",    0 );
      }
      GetMosCoords( &MosMap->MosaicMap, Maps, Flags );

   } else if( Flags[READMOD] ) {

      assert( string[0]!='\0', "No input model specified" );
      assert( SetPresent(string), "Input model %s does not exist", string );
      InitSet(      &MosMap->MosaicMap, string, "estimate", "new", 0 );
      GetSetCoords( &MosMap->MosaicMap, TRUE, TRUE );

      InitSet(      &MosMap->Final, "calculation", "comparison", "new", 0 );
      GetMosCoords( &MosMap->Final, Maps, Flags );
      CooCopy(      &MosMap->MosaicMap.Coords, &MosMap->Final.Coords );/*prpix*/

      Check(        "MosMap", &MosMap->MosaicMap, &MosMap->Final );

   } else if( Flags[PBC] ) {

      MosMap->MosaicMap.Coords.ZLEN = Maps->Observation.Coords.ZLEN;
   }

   if( Flags[MOSCALC] || Flags[READMOD] ) {
      InitSet( &MosMap->Residual,  string, "residual",  "append", 0 );
      InitSet( &MosMap->Convolved, string, "convolved", "append", 0 );
      InitSet( &MosMap->Final,     string, "final",     "append", 0 );
      InitSet( &MosMap->Gaussian,  string, "",          "append", 0 );

      CooCopy( &MosMap->Residual.Coords,  MosCoo );
      CooCopy( &MosMap->Convolved.Coords, MosCoo );
      CooCopy( &MosMap->Final.Coords,     MosCoo );
      GetGauCoords( &MosMap->Gaussian.Coords, &MosMap->MosaicMap.Coords );
   }

#define CheckPresence(name) \
assert( !SetPresent(name), "Dataset %s already exists", name )
   if( Flags[WRITEMOS] ) CheckPresence( MosMap->MosaicMap.name );
   if( Flags[WRITERES] ) CheckPresence( MosMap->Residual.name  );
   if( Flags[WRITECNV] ) CheckPresence( MosMap->Convolved.name );
   if( Flags[WRITEFIN] ) CheckPresence( MosMap->Final.name     );
   if( Flags[PBC]      ) {for(ALLMAPSI)CheckPresence( MapI->PrimaryBeam.name );}
}

/*

/******************************************************************************/
/*
   Read the reference= keyword. If given, open the reference dataset and check
   its compatibility with the mosaiced dataset, else only copy the coordinate
   description.
   Also check the clipping of the reference set used to define a mask.
*/
/******************************************************************************/

private void ReferenceInput( MosMap, Flags, CTRL )
MOSMAP  *MosMap;
logical  Flags[];
CONTROL *CTRL;
{
   void         keyf_c(), keyd_c(), keya_c();
           void InitSet();
           void CooCopy(), CooSetp();
   private void GetSetCoords();
   private void Check();
   char         string[FILENAMELEN];
   DATASET     *RefMap = &MosMap->Reference;
   TRACE("-- ReferenceInput");

   keyf_c( "reference", string, "\0" );

   if( string[0] == '\0' ) {

      Flags[READREF]  = FALSE;
      CTRL->RefOption = REF_FLAT;
      InitSet( RefMap, MosMap->MosaicMap.name, "reference", "append", 0 );
      CooCopy( &RefMap->Coords, &MosMap->MosaicMap.Coords );

   } else if( StrEqX( string, "PBPATTERNS" ) ) {

      Flags[READREF]  = FALSE;
      CTRL->RefOption = REF_PB;
      InitSet( RefMap, MosMap->MosaicMap.name, "reference", "append", 0 );
      CooCopy( &RefMap->Coords, &MosMap->MosaicMap.Coords );

   } else {

      Flags[READREF]  = TRUE;
      CTRL->RefOption = REF_MAP;
      InitSet(      RefMap, string, "reference", "new", 0 );
      GetSetCoords( RefMap, TRUE, TRUE );
      CooSetp(     &RefMap->Coords );
      Check(       "Reference", RefMap, &MosMap->MosaicMap );

      keyd_c( "reference", &CTRL->RefClip, MIN_REAL );
      if( CTRL->RefClip != MIN_REAL ) {
         if( CTRL->EntropyMeasure == GULL )
         assert( CTRL->RefClip>0, "Clip in reference= must be > 0." );
         keya_c( "reference", string, "mask" );
                                     CTRL->RefOption = -1;
         if( StrEqX("mask",string) ) CTRL->RefOption = REF_FLAT;
         if( StrEqX("use", string) ) CTRL->RefOption = REF_CLIPPED;
         assert( CTRL->RefOption>-1, "unknown mode for clipping reference" );
      }

   }
}

/******************************************************************************/
/*
   Read the initial= keyword. If given, open the initial dataset and check its
   compatibility with the mosaiced dataset, else only copy the coordinate
   description.
*/
/******************************************************************************/

private void InitialInput( MosMap, Flags )
MOSMAP  *MosMap;
logical  Flags[];
{
   void         keyf_c();
           void InitSet();
           void CooCopy(), CooSetp();
   private void GetSetCoords();
   private void Check();
   DATASET     *IniMap = &MosMap->Initial;
   char         string[FILENAMELEN];
   TRACE("-- InitialInput");

   keyf_c( "initial", string, "\0" );

   Flags[READINI] = string[0] != '\0';
   if( Flags[READINI] ) {
      InitSet(      IniMap, string, "initial", "new", 0 );
      GetSetCoords( IniMap, TRUE, TRUE );
      CooSetp(     &MosMap->Initial.Coords );
      Check(       "Initial", IniMap, &MosMap->MosaicMap );
   } else {
      InitSet( IniMap, MosMap->MosaicMap.name, "initial", "append", 0 );
      CooCopy( &IniMap->Coords, &MosMap->MosaicMap.Coords );
   }
}

/******************************************************************************/
/*
   Read the flux= keyword.
   First, find the type of flux keyword given.
   Then, do an appropriate decoding of the other arguments.

   Allowed formats are:
     flux=#,#,#, .     convert string to numbers
                       one value per channel, last one replicated
     flux=gauss,a,v,w  read 'gauss'
                       read parameters (amp, midch, widthch)
                       calculate function for all channels
     flux=dataset,name read 'dataset'
                       read name of dataset
                       open dataset and check description
                       read all channels in the dataset
*/
/******************************************************************************/

private void FluxInput( nchan, CTRL )
int      nchan;
CONTROL *CTRL;
{
           void keya_c(), keyd_c(), keyf_c();
           void InitSet();
   private void GetSetCoords();
           void XYZrdprof(), CloseDataSet();
         double AtoF();

   float  *TargetFluxes;
   char    string[INSTRLEN];
   int     n;
   double  par[3];
   DATASET FluxSet;
   TRACE("FluxInput");

   Malloc( CTRL->TargetFluxes, double, nchan );

   CTRL->nchan = nchan;
   keya_c( "flux", string, "0." );

   if( StrEq( "gauss", string ) ) {
      keyd_c( "flux", &par[0], ZERO );
      keyd_c( "flux", &par[1], ZERO );
      keyd_c( "flux", &par[2], ONE  );
      for( n=1; n<=nchan; n++ ) *(CTRL->TargetFluxes+n-1) =
           par[0] * EXP( -FOURLN2 * square((n-par[1])/par[2]) );

   } else if( StrEq( "dataset", string ) ) {
      keyf_c( "flux", string, "\0" );
      assert(string[0]!='\0',"No dataset given with flux=dataset,... keyword");
      InitSet( &FluxSet, string, "flux", "new", 0 );
      GetSetCoords( &FluxSet, TRUE, FALSE );
      assert( FluxSet.Coords.XLEN==1 && FluxSet.Coords.YLEN==1 &&
              FluxSet.Coords.ZLEN==nchan,
              "Flux dataset size not 1 x 1 x #channels" );
      Malloc( TargetFluxes, float, 2*nchan );
      XYZrdprof( FluxSet.Lun, FluxSet.Coords.blc,FluxSet.Coords.trc,
                 TargetFluxes, TargetFluxes+nchan );
      for(n=0;n<nchan;n++) *(CTRL->TargetFluxes+n)=(double)(*(TargetFluxes+n));
      CloseDataSet( &FluxSet, FALSE );

   } else {
      *(CTRL->TargetFluxes) = AtoF(string);
      if( nchan > 1 ) {
         for( n=1; n<nchan; n++ )
         keyd_c( "flux", CTRL->TargetFluxes+n, *(CTRL->TargetFluxes+n-1) );
      }

   }
}

/*

/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*    <<< Initialization utilities >>>                 434 +  160 =  594 USERIO
/******************************************************************************/
/*
   Allocate the space for name and type of Set and initialize them.
   Called once from mosaic_save.c, otherwise only from this file.
*/
/******************************************************************************/

void InitSet( Set, name, type, status, SetNum )
DATASET *Set;
char    *name;
char    *type;
char    *status;
int      SetNum;
{
   TRACE("InitSet");
   if(        StrEq(status,"new") ) {
      Calloc( Set->name, strlen(name)+1 );
      StrCpy( Set->name, name );
   } else if( StrEq(status,"append") ) {
      Calloc( Set->name, strlen(name)+1+strlen(type)+1 );
      StrCpy( Set->name, name );
      StrCat( Set->name, "_"  );
      StrCat( Set->name, type );
   }
   Calloc( Set->type, strlen(type)+1 );
   StrCpy( Set->type, type );
   Set->Lun = 0;
   Set->SetNum = SetNum;
   Set->Coords.project = TRUE;
}

/*

/******************************************************************************/
/*
   Open dataset.
   Read Object string
   Read dataset parameters naxis, axlen, crpix, crval, cdelt, ctype.
   Find which axes are the lon, lat and freq axes.
   Calculate cubesize, orgcubesize, blc, trc and nPoints.
*/
/******************************************************************************/

private void GetSetCoords( Set, OpenIt, CloseIt )
DATASET *Set;
logical  OpenIt, CloseIt;
{
   void    Open_OldDataSet(), CloseDataSet();
   void    GetItemA(), GetItemR();
   void    fndaxnum();

   COORDS *SetCoo = &Set->Coords;
   char    axname;
   AXIS    n, j;
   int     AXLEN[MAXNAX];
   TRACE("-- GetSetCoords");

   if( OpenIt ) {
   for( n=0; n<MAXNAX; n++ ) {
      SetCoo->axisnr[n] = n;
      SetCoo->axlen[n]  = SetCoo->cubesize[n+1] = SetCoo->orgcubesize[n+1] =
      SetCoo->blc[n]    = SetCoo->trc[n]        = 1;
      SetCoo->crval[n]  = SetCoo->cdelt[n]      = SetCoo->crpix[n] = ZERO;
      SetCoo->crshf[n]  = ZERO;
      SetCoo->prval[n]  = SetCoo->pdelt[n]      = SetCoo->prpix[n] = ZERO;
   }

   SetCoo->axisnr[0] = -1;

   Open_OldDataSet( Set ); }

   GetItemA( Set->Lun, "object", NOAX, Set->Object );

   fndaxnum(  &Set->Lun, "lon",  &axname, &SetCoo->axisnr[RA_AXIS] );
   fndaxnum(  &Set->Lun, "lat",  &axname, &SetCoo->axisnr[DC_AXIS] );
   fndaxnum(  &Set->Lun, "freq", &axname, &SetCoo->axisnr[FQ_AXIS] );
   for( n=AXIS4; n<=SetCoo->naxis; n++ )   SetCoo->axisnr[n] = n;

   for(n=AXIS1;n<=SetCoo->naxis;n++) AXLEN[n]        =SetCoo->axlen[n];
   for(n=AXIS1;n<=SetCoo->naxis;n++) SetCoo->axlen[n]=AXLEN[SetCoo->axisnr[n]];
   SetCoo->nPoints = SetCoo->XLEN * SetCoo->YLEN;

   SetCoo->cubesize[AXIS1] = SetCoo->orgcubesize[AXIS1] = 1;
   for( n=AXIS1+1; n<=SetCoo->naxis+1; n++ ) {
      SetCoo->cubesize[n]    = SetCoo->cubesize[n-1]    * SetCoo->axlen[n-1];
      SetCoo->orgcubesize[n] = SetCoo->orgcubesize[n-1] * AXLEN[n-1];
   }

   for( n=AXIS1; n<=SetCoo->naxis; n++ ) { j = SetCoo->axisnr[n];
     GetItemA( Set->Lun, "ctype", j,  SetCoo->ctype[n] );
     GetItemR( Set->Lun, "crval", j, &SetCoo->crval[n] );
     GetItemR( Set->Lun, "cdelt", j, &SetCoo->cdelt[n] );
     GetItemR( Set->Lun, "crpix", j, &SetCoo->crpix[n] );
     SetCoo->blc[n] = 1;
     SetCoo->trc[n] = SetCoo->axlen[n];
   }
   SetCoo->cdelt[RA_SEC] = SetCoo->cdelt[RA_AXIS] / cos(SetCoo->crval[DC_AXIS]);

   GetItemR( Set->Lun, "xshift", NOAX, &SetCoo->crshf[RA_AXIS] );
   GetItemR( Set->Lun, "yshift", NOAX, &SetCoo->crshf[DC_AXIS] );

   if( CloseIt ) CloseDataSet( Set, FALSE );
}

/******************************************************************************/
/*
   The calculations pertaining to the dataset within MosMap that describe the
   final combined map are done.

   Each plane has a size encompassing all input datasets; some parameters, like
   crval and cdelt, are determined from the first input dataset.

   Also adapt the frequency-axis description of the output datasets. crpix is
   adapted such that the definition of crval is still OK. I.e. if plane N of the
   inputs is the first plane to deconvolve, crpix shifts by 1-N. The trc and
   z-length are set to the number of planes to do.
   (This will give faulty results if the selected planes are not contiguous, but
   that is inherent to the description anyway).
*/
/******************************************************************************/

private void GetMosCoords( MosSet, Maps, Flags )
DATASET *MosSet;
ONEMAP  *Maps;
logical  Flags[];
{
   void     CooCopy();
   double   ConvertPixel();
   void     Extent();
   void     Messages_Coords();

   ONEMAP  *MapI;
   COORDS  *MosCoo = &MosSet->Coords;
   COORDS  *SetCoo, *BeaCoo;
   AXIS     n;
   int      left[2], right[2];
   double   leftedge[2], rightedge[2];
   TRACE("-- GetMosCoords");

   StrCpy( MosSet->Object, Maps->Observation.Object );
   CooCopy( MosCoo, &Maps->Observation.Coords );
   Messages_Coords( 2, MosCoo,MosCoo, NOAX, left,right,leftedge,rightedge );

   for( ALLMAPSI ) { for( n=AXIS1; n<=AXIS2; n++ ) {
      SetCoo = &MapI->Observation.Coords;
      BeaCoo = MapI->IsIFmap ? &MapI->SynthBeam.Coords
                             : &MapI->PrimaryBeam.Coords;

      /* find pixel limits of area to use, in system of Set */
      Extent( SetCoo, BeaCoo, Flags[FULLSIZE], &left[n],&right[n],n );

      if( MapI == Maps ) {
         leftedge[n]      = (double)left[n];
         rightedge[n]     = (double)right[n];
         MosCoo->blc[n]   = nint(leftedge[n]);
         MosCoo->trc[n]   = nint(rightedge[n]);;
      } else {
         /* convert pixel limits of area to use to system of Mos */
         leftedge[n]      = ConvertPixel( (double)left[n],  SetCoo, MosCoo, n );
         rightedge[n]     = ConvertPixel( (double)right[n], SetCoo, MosCoo, n );
         /* find blc/trc of merged map and new axis lengths */
         MosCoo->blc[n]   = min( MosCoo->blc[n], nint(leftedge[n])  );
         MosCoo->trc[n]   = max( MosCoo->trc[n], nint(rightedge[n]) );
      }
      MosCoo->axlen[n] = MosCoo->trc[n] - MosCoo->blc[n] + 1;
      /* shift reference pixel */
      MosCoo->prpix[n] = MosCoo->prpix[n] - MosCoo->blc[n]+1;
      /* reset blc and trc to actual edges */
      MosCoo->blc[n]   = 1;
      MosCoo->trc[n]   = MosCoo->axlen[n];
   }
   Messages_Coords( 3, SetCoo, MosCoo, n, left,right,leftedge,rightedge );
   }

   /* Make crval/crpix of Mos give the description again */
   MosCoo->crval[RA_AXIS] = MosCoo->prval[RA_AXIS];
   MosCoo->crval[DC_AXIS] = MosCoo->prval[DC_AXIS];
   MosCoo->crpix[RA_AXIS] = MosCoo->prpix[RA_AXIS];
   MosCoo->crpix[DC_AXIS] = MosCoo->prpix[DC_AXIS];
   MosCoo->nPoints        = MosCoo->XLEN * MosCoo->YLEN;

   if( Flags[WRITEMOS] ) {
   MosCoo->crpix[FQ_AXIS] += 1 - *(Maps->Region.Planes);
   MosCoo->prpix[FQ_AXIS]  = MosCoo->crpix[FQ_AXIS];
   MosCoo->trc[FQ_AXIS]    = Maps->Region.nPlanes;
   MosCoo->axlen[FQ_AXIS]  = MosCoo->trc[FQ_AXIS];
   }
}

/******************************************************************************/
/*
   Calculate the coordinate description of the gaussian convolving beam, mainly
   to be able to save a dataset with it. Only axlen, crpix and cdelt are needed
   to calculate the gaussian.
*/
/******************************************************************************/

private void GetGauCoords( GauCoo, MosCoo )
COORDS *GauCoo;
COORDS *MosCoo;
{
   int  NextPow2();
   AXIS n;
   TRACE("GetGauCoords");

   GauCoo->naxis = AXIS2;
   for( n=RA_AXIS; n<=DC_AXIS; n++ ) {
      GauCoo->axisnr[n] = n;
      GauCoo->axlen[n]  = NextPow2( MosCoo->axlen[n] );
      GauCoo->blc[n]    = 1;
      GauCoo->trc[n]    = GauCoo->axlen[n];
      GauCoo->prpix[n]  = GauCoo->crpix[n]  = GauCoo->axlen[n] / 2. - 1;
      GauCoo->prval[n]  = GauCoo->crval[n]  = 0.;
      GauCoo->pdelt[n]  = GauCoo->cdelt[n]  = MosCoo->cdelt[n];
      StrCpy(GauCoo->ctype[n],MosCoo->ctype[n]);
   }
   GauCoo->nPoints  = GauCoo->XLEN * GauCoo->YLEN;
}

/******************************************************************************/
/*
   Find the extent of the primary beam associated with the single-dish dataset.

   The PrimaryBeam.Coords struct originally describes the single-dish
   observation.

   This primary beam will be filled later, and used to extract a 'single-dish
   observation' from the model by convolution.
   Point the beam at the center of the map. Make the size the next power of 2
   bigger than the model.

   Copy the crval/crpix/cdelt into the PB struct.

   Then copy the coordinates of the mosaic to the dataset describing the
   regridded observation.
*/
/******************************************************************************/

private void SetSDmaps( MosMap, Maps )
MOSMAP *MosMap;
ONEMAP *Maps;
{
   int     NextPow2();
   double  ConvertToCoord();
   void    InitSet();
   void    CooCopy(), PBkeyCoords();

   COORDS *MosCoo = &MosMap->MosaicMap.Coords;
   COORDS *PrBCoo;
   double  center;
   AXIS    n;
   char    string[10];
   ONEMAP *MapI;

   TRACE("-- SetSDmaps");

   for( ALLMAPSI ) { if( MapI->IsSDmap ) {
      PrBCoo = &MapI->PrimaryBeam.Coords;
      for( n=AXIS1; n<=AXIS2; n++ ) {
         center = (double)( NextPow2(MosCoo->axlen[n]) / 2 + 1 );
         PrBCoo->crpix[n] = PrBCoo->prpix[n] = center;
         PrBCoo->crval[n] = PrBCoo->prval[n] = ConvertToCoord(center,MosCoo,n);
         PrBCoo->cdelt[n] = PrBCoo->pdelt[n] = MosCoo->cdelt[n];
         PrBCoo->axlen[n] = NextPow2( MosCoo->axlen[n] );
         PrBCoo->blc[n]   = 1;
         PrBCoo->trc[n]   = PrBCoo->axlen[n];
      }
      PrBCoo->nPoints = PrBCoo->XLEN * PrBCoo->YLEN;
      PBkeyCoords( &MapI->PB, string, PrBCoo );


      CooCopy( &MapI->DirtyMap.Coords, MosCoo );
   }}
}

/*

/******************************************************************************/
/*
   To align the mosaic maps, take two steps. This is to ensure that the right
   answer is obtained whether or not offset= was used in invert.
   - First, add the xshift and yshift values to get the actual projection
     centers. These are stored in prval/prpix. If there are shifts such that
     the maps were made with the same projection center, the second step
     effectively does nothing. If there are no shifts, the first step does
     nothing.
   - Next, calculate new shifts from the difference of prval_i with prval_1, so
     that all maps are referred to the projection center of the first.
   - Finally, apply the shifts to get the prval values. If xshift/yshift was
     present this may do nothing. Else, it will simulate using invert's offset=.
     (All prval values will actually become equal).
   - If the shifts were such that crval+shift is not equal for all input maps,
     then this routine will apply both corrections.
*/
/******************************************************************************/

private void GetProjection( Coo, RefCoo )
COORDS *Coo;
COORDS *RefCoo;
{
   void   CoordAt();
   double xoffset, yoffset;
   TRACE("GetProjection");

   /* Add crshf to crval */
   Coo->prval[DC_AXIS] = Coo->crval[DC_AXIS] + Coo->crshf[DC_AXIS];
   Coo->prval[RA_AXIS] = Coo->crval[RA_AXIS] + Coo->crshf[RA_AXIS]
                                             / cos(Coo->prval[DC_AXIS]);
   Coo->prval[FQ_AXIS] = Coo->crval[FQ_AXIS];

   Coo->prpix[RA_AXIS] = Coo->crpix[RA_AXIS]
                       + Coo->crshf[RA_AXIS] / Coo->cdelt[RA_AXIS];
   Coo->prpix[DC_AXIS] = Coo->crpix[DC_AXIS]
                       + Coo->crshf[DC_AXIS] / Coo->cdelt[DC_AXIS];

   xoffset             = ( RefCoo->prval[RA_AXIS] - Coo->prval[RA_AXIS] )
                         * cos(RefCoo->prval[DC_AXIS]);
   yoffset             = RefCoo->prval[DC_AXIS] - Coo->prval[DC_AXIS];

   CoordAt( "Original",  Coo->crval[RA_AXIS],Coo->crpix[RA_AXIS],
                         Coo->crval[DC_AXIS],Coo->crpix[DC_AXIS] );
   CoordAt( "Proj Cen",  Coo->prval[RA_AXIS],Coo->prpix[RA_AXIS],
                         Coo->prval[DC_AXIS],Coo->prpix[DC_AXIS] );
   CoordAt( "Shift of",  xoffset, xoffset/Coo->cdelt[RA_AXIS],
                         yoffset, yoffset/Coo->cdelt[DC_AXIS] );

   /* Store new description */
   Coo->prval[RA_AXIS]  = RefCoo->prval[RA_AXIS];
   Coo->prval[DC_AXIS]  = RefCoo->prval[DC_AXIS];

   Coo->prpix[RA_AXIS] += xoffset / Coo->cdelt[RA_AXIS];
   Coo->prpix[DC_AXIS] += yoffset / Coo->cdelt[DC_AXIS];

   Coo->pdelt[RA_AXIS]  = Coo->cdelt[RA_AXIS];
   Coo->pdelt[RA_SEC]   = Coo->pdelt[RA_AXIS] / cos(Coo->prval[DC_AXIS]);
   Coo->pdelt[DC_AXIS]  = Coo->cdelt[DC_AXIS];

   Coo->crshf[RA_AXIS] /= cos(Coo->prval[DC_AXIS]);

   CoordAt( "Final   ", Coo->prval[RA_AXIS],Coo->prpix[RA_AXIS],
                        Coo->prval[DC_AXIS],Coo->prpix[DC_AXIS] );

   Coo->prval[FQ_AXIS]  = Coo->crval[FQ_AXIS];
   Coo->prpix[FQ_AXIS]  = Coo->crpix[FQ_AXIS];
   Coo->pdelt[FQ_AXIS]  = Coo->cdelt[FQ_AXIS];
}

/******************************************************************************/
/*
   Return convolvable part of map.
*/
/******************************************************************************/

void Extent( SetCoo, BeamCoo, full, left, right, axis )
COORDS  *SetCoo, *BeamCoo;
logical  full;
int     *left, *right;
AXIS     axis;
{
   int center;
   if( full ) {
      *left  = SetCoo->blc[axis];
      *right = SetCoo->trc[axis];
   } else {
      center = SetCoo->axlen[axis] / 2 + 1;
      *left  = max( SetCoo->blc[axis], center - BeamCoo->axlen[axis]/4   );
      *right = min( SetCoo->trc[axis], center + BeamCoo->axlen[axis]/4-1 );
   }
}


/*

/******************************************************************************/
/*
   Read the region# keyword with RegionDecode. This fills in the Region struct,
   selecting an area and possibly planes.

   It decodes the region keyword, which creates the region pointer and fills it
   with the list of planes and boxes. If no region keyword was given for a
   dataset, either the reference dataset is used as a mask, or the combined
   inner quarters will be used. If a mask was specified with the keyword,
   RegionDecode gets the description of the mask dataset, but does not yet
   read it. This is done when the data is read in.

   Next, on the first call read the planes= keyword. This supersedes the image
   specifications. On later calls, copy the planes. A compatibility check is
   done.

   The "REGION Planes" variable is needed because RegionDecode sets the selected
   area to the whole map if only an "image()" subcommand is given.
*/
/******************************************************************************/

private REGION  Planes;
private logical planes;

private void GetRegion( Coords, Region, keyword, SetNum )
COORDS  *Coords;
REGION  *Region;
char    *keyword;
int      SetNum;
{
   logical keyprsnt_c();
   void    RegionDecode();
   char    string[INSTRLEN];

   if( SetNum != 0 ) Sprintf( string, "%s%d", keyword, abs(SetNum) );
   else              string[0] = '\0';
   RegionDecode( string, Coords, Region );
   if( Region->MaskPresent ) Region->Mask->SetNum = SetNum;


   if( SetNum == 1 ) {
      planes = keyprsnt_c("planes");
      if(planes) RegionDecode( "planes", Coords, &Planes );
   }
   if( planes ) {
      Region->nPlanes = Planes.nPlanes;
      Region->Planes  = Planes.Planes;
   }
}

/*******************************************************************************/
/*
   Set up a mask file. First the Region.Mask pointer is created and the
   information on the mask dataset is stored. A check is done whether the mask
   set is compatible with the corresponding input dataset. The mask is only
   actually read in routine ReadMaps, since only there is the shape of the array
   to put it in known.
*/
/******************************************************************************/

void MaskFile( name, Coords, Region )
char   *name;
COORDS *Coords;
REGION *Region;
{
   int          index_c();
           void InitSet();
   private void GetSetCoords();
           void CooCopy();
   private void Check();
   DATASET InpSet;
   TRACE("-- MaskFile");

   InitSet( &InpSet, "mask set", "input", "new",0);/* temporary dataset with */
   CooCopy( &InpSet.Coords, Coords );              /* input coordinates      */

   Malloc( Region->Mask, DATASET, 1 );
   name++; *(name + index_c(')',name) ) = '\0';
   InitSet(      Region->Mask, name, "mask", "new", 0 );
   GetSetCoords( Region->Mask, TRUE, TRUE );
   Check(        "Mask", Region->Mask, &InpSet );
}

/*

/******************************************************************************/
/*
   Find out whether two input datasets are compatible with each other.
   - same number of axes
   - same axis types and gridspacings
   - integer number of pixels shifted from each other
   - same number of channels and same frequencies selected
*/
/******************************************************************************/

private logical Compatibility( IFmap, Set,Region, RefSet,RefRegion )
logical  IFmap;
DATASET *Set,    *RefSet;
REGION  *Region, *RefRegion;
{
   void     Messages_Coords();
   double   ConvertToCoord();
   char     axnames[MAXNAX+1];

   COORDS  *SetCoo = &Set->Coords;
   COORDS  *RefCoo = &RefSet->Coords;
   AXIS     n;
   char     ax[2];
   double   nearest, frac;
   logical  incompatible=FALSE;
   int      i;
   TRACE("-- Compatibility");
   StrCpy( axnames, "xyzabcd" );

   if( IFmap )
       assert( SetCoo->naxis==RefCoo->naxis,
       "number of axes differs for %s and %s", Set->name, RefSet->name );
   else
       assert( SetCoo->naxis==RefCoo->naxis | SetCoo->naxis==RefCoo->naxis-1,
       "number of axes differs for %s and %s", Set->name, RefSet->name );

   for( n=AXIS1; n<=SetCoo->naxis; n++ ) {

   ax[0] = axnames[n-AXIS1]; ax[1]='\0';
   assert( StrEq(SetCoo->ctype[n], RefCoo->ctype[n]),
          "type of %s axis differs for %s and %s", ax,Set->name,RefSet->name );

   if( IFmap && ( ax[0]=='x' || ax[0]=='y' ) ) {
      assert( fEq(SetCoo->cdelt[n], RefCoo->cdelt[n]),
      "gridspacing of %s axis differs for %s and %s",ax,Set->name,RefSet->name);
      Messages_Coords( 1, SetCoo, RefCoo, n, 0,0,0,0 );
      nearest = (double)nint(SetCoo->prpix[n]);
      frac    = SetCoo->prpix[n] - nearest;
      if(       fabs(frac) > 0.05 ) incompatible=TRUE;
      wwarning( fabs(frac) > 0.05,
               "axis %d of %s does not align; use %s offset=%.2g'' in invert",
                n-AXIS1+1, Set->name, ax, rtos(frac*SetCoo->cdelt[n]) );
   }
   if( ax[0]=='z' ) {
      assert( fEq(SetCoo->cdelt[n], RefCoo->cdelt[n]),
      "gridspacing of %s axis differs for %s and %s",ax,Set->name,RefSet->name);
      assert( SetCoo->axlen[FQ_AXIS]==RefCoo->axlen[FQ_AXIS],
      "length of %s axis differs for %s and %s", ax,Set->name,RefSet->name );
      assert( Region->nPlanes == RefRegion->nPlanes,
             "Number of planes in region= differs for %s and %s",
              Set->name, RefSet->name );
      for( i=0; i<Region->nPlanes; i++ ) {
        if( ConvertToCoord( (double)*(Region->Planes+i), SetCoo, FQ_AXIS ) !=
            ConvertToCoord( (double)*(Region->Planes+i), RefCoo, FQ_AXIS )   ){
           incompatible=TRUE;
           wwarning( TRUE, "Frequencies do not match up for %s and %s",
                            Set->name, RefSet->name );
        }
      }
   }
   }

   return(!incompatible);
}

/*

/******************************************************************************/
/*
   Input the rms= keyword.
*/
/******************************************************************************/

private double  previous_rms;
private logical repeatRMS=FALSE;
private char    prev_rmskey[10] = { "\0" } ;

private void    GetRMS( keyword, Set )
char    *keyword;
DATASET *Set;
{
   void   keya_c();
   double AtoF();
   char   string[FILENAMELEN];
   double inrms;
   if(!StrEqX(keyword,prev_rmskey)) repeatRMS=FALSE;
   StrCpy(prev_rmskey,keyword);
   keya_c( keyword, string, "0." );
   if( StrEqX(string,"...") ) repeatRMS = TRUE;
   if( repeatRMS ) inrms = previous_rms;
   else            inrms = previous_rms = AtoF(string);
   assert( inrms > ZERO, "rms must be given for all input maps" );
   Set->rms      = inrms;
   Set->variance = square( Set->rms );
}

/*

/******************************************************************************/
/*
   Sel=="Mask":          compare mask <-> corresponding input
   Sel=="SynthBeam":     compare beam <-> corresponding input
   Sel=="MosMap":        compare read-in estimate <-> calculated coordinates
   Sel=="Reference":     compare reference <-> estimate
   Sel=="Initial":       compare initial  <-> estimate

   Do several simple checks.
   - inputs, masks and estimate must have same number of axes
     beam must have one plane
     reference and initial must have same number of axes as estimate or 1 plane

   - gridspacings and axis types must be the same
   - for mask and read-in estimate all axis lengths must be the same, for inputs
     the lengths of only the x and y axis may differ
   - for mask, read-in estimate, initial and reference the reference coordinate
     and pixel must be the same

   - the beam dataset must be bigger than the map dataset and should have axis
     lengths that are a power of two.
   - the initial or reference must encompass the estimate in x and y; set the
     blc and trc of the Set to the area within the MosMap.
*/
/******************************************************************************/

private void Check( Sel, Set, RefSet )
char    *Sel;
DATASET *Set, *RefSet;
{
   double   ConvertPixel();
   int      NextPow2();
   char     axnames[MAXNAX+1];

   COORDS  *SetCoo = &Set->Coords;
   COORDS  *RefCoo = &RefSet->Coords;
   AXIS     n;
   int      ncheck=-1;
   char     m[OUTSTRLEN];
   TRACE("-- Check");
   StrCpy( axnames, "xyzabcd" );

   if( !StrEq( Sel, "SynthBeam" ) ) {
      assert( SetCoo->naxis == RefCoo->naxis,
             "number of axes differs for %s and %s", Set->name,RefSet->name );
   }

/* Mask  <-> Map */
   if( StrEq( Sel, "Mask" ) ) {
      ncheck = SetCoo->naxis;
   }

/* Beam  <-> Map */
   if( StrEq( Sel, "SynthBeam" ) ) {
     assert( SetCoo->ZLEN == 1, "beam %s has more than one plane", Set->name );
     ncheck = -1;
     for( n=AXIS1; n<=AXIS2; n++ ) {
     Sprintf( m, "of %c axis differs for %s and %s",
                  axnames[n-AXIS1], Set->name, RefSet->name );
     assert(StrEq(SetCoo->ctype[n], RefCoo->ctype[n]), "type %s",            m);
     assert(  fEq(SetCoo->cdelt[n], RefCoo->cdelt[n]), "gridspacing %s",     m);
     assert(      SetCoo->axlen[n]>=RefCoo->axlen[n],
                 "beam dataset %s too small to do convolutions", Set->name );
     assert(      SetCoo->axlen[n]==NextPow2(SetCoo->axlen[n]),
                 "length of beam axis of %s not a power of 2", Set->name );
     }
   }

/* Model <-> calc */
   if( StrEq( Sel, "MosMap" ) ) {
     ncheck = SetCoo->naxis;
   }

/* Ref or Init <-> Model */
   if( StrEq( Sel, "Reference" ) | StrEq( Sel, "Initial" ) ) {
      ncheck = SetCoo->ZLEN!=1 ? SetCoo->naxis : AXIS2;
      for( n=AXIS1; n<=ncheck; n++ ) {
         SetCoo->blc[n] = nint( ConvertPixel( ZERO, RefCoo, SetCoo, n )) + 1;
         SetCoo->trc[n] = SetCoo->blc[n] + RefCoo->axlen[n] - 1;
      assert(SetCoo->blc[n]<=RefCoo->blc[n],"blc of %s set too high",Set->type);
      assert(SetCoo->trc[n]>=RefCoo->trc[n],"trc of %s set too low", Set->type);
      }
   }


/* ALL */
  for( n=AXIS1; n<=ncheck; n++ ) {
  Sprintf( m, "of %c axis differs for %s and %s",
               axnames[n-AXIS1], Set->name, RefSet->name );
  assert(StrEq(SetCoo->ctype[n], RefCoo->ctype[n]),"type %s",                m);
  assert(  fEq(SetCoo->cdelt[n], RefCoo->cdelt[n]),"gridspacing %s",         m);
  assert(  fEq(SetCoo->crval[n], RefCoo->crval[n]),"reference coordinate %s",m);
  assert(  fEq(SetCoo->crpix[n], RefCoo->crpix[n]),"reference pixel %s",     m);
  assert(     (SetCoo->axlen[n]==RefCoo->axlen[n]),"length %s",              m);
  }

}

/*

/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*    <<< Synthesized Beam IO >>>                      162 +   75 =  237 USERIO
/******************************************************************************/
/*
   SBparams fits the beam to get a fwhm and position angle, and also calculates
   the Q-factor.
   Returns values for Map->BM.Q, Map->BM.bmaj, Map->BM.bmin and Map->BM.bpa.

   GetRestoringBeam determines a clean beam from individual beams or a keyword.
*/
/******************************************************************************/
/*
   - set up a dataset to hold the special coordinate limits that are needed
   - read a 17x17 patch of the beam
     calculate Q by summing the pixels within a radius of 8 pixels from the
     center, which must be at crpix
   - read a 11x11 patch of the beam
     fit the synthesized beam to get a parametrized description
   - write the fitted beam to the header
*/
/******************************************************************************/

#define QRADIUS    8
#define FRADIUS    5
#define PATCHWIDTH (2 * QRADIUS + 1)
#define PATCHSIZE  PATCHWIDTH * PATCHWIDTH
private struct { int xlen,ylen; double xref,yref; double xdelt,ydelt; } xypar;

private void SBparams( Beam, BeamPar )
DATASET *Beam;
BMPAR   *BeamPar;
{
   private void   SBreadpatch();
   private double SBQcalc();
   private void   SBfitbeam();
   private void   SBputbeam();
           float  BeamPatch[2][PATCHSIZE];
   TRACE("SBparams");

   if( Beam !=  NULL ) {

      SBreadpatch(    Beam, QRADIUS, BeamPatch );
      BeamPar->Q = SBQcalc( QRADIUS, BeamPar->Qcircle, BeamPatch );

      SBreadpatch(    Beam, FRADIUS, BeamPatch );
      SBfitbeam(      Beam, FRADIUS, BeamPatch, BeamPar );

      SBputbeam( Beam->Lun, BeamPar );

   } else {
      BeamPar->Q = BeamPar->bmaj = BeamPar->bmin = BeamPar->bpa = ZERO;
   }

}

/******************************************************************************/
/*
   Read the small center portion of a beam dataset into the BeamPatch array.
   Return in the Beam->Coords struct the axes lengths and reference pixel offset
   of the patch.

   Note the +1 when setting blc and trc: xyzio requires the input pixels to be
   pixelnumbers, not offsets.
*/
/******************************************************************************/

private void SBreadpatch( Beam, radius, BeamPatch )
DATASET *Beam;
int      radius;
float    BeamPatch[2][PATCHSIZE];
{
   void    XYZpatch();
   COORDS *BCoo = &Beam->Coords;
   int     xliml, yliml, xlimu, ylimu;
   int     blc[3], trc[3];
   int     n = square(2*radius+1);
   TRACE("SBreadpatch");

   xypar.xlen = BCoo->XLEN;              xypar.ylen = BCoo->YLEN;
   xypar.xref = BCoo->crpix[RA_AXIS]-1.; xypar.yref = BCoo->crpix[DC_AXIS]-1.;
   xypar.xdelt= BCoo->cdelt[RA_AXIS];    xypar.ydelt= BCoo->cdelt[DC_AXIS];
   xliml = nint(xypar.xref) - radius;    yliml = nint(xypar.yref) - radius;
   xlimu = nint(xypar.xref) + radius;    ylimu = nint(xypar.yref) + radius;

   assert( xliml>=0 && xlimu<xypar.xlen && yliml>=0 && ylimu<xypar.ylen,
           "Cannot calculate Q: crpix too close to or outside of edge" );

   blc[0] = xliml + 1;    blc[1] = yliml + 1;    blc[2] = 1;
   trc[0] = xlimu + 1;    trc[1] = ylimu + 1;    trc[2] = 1;
   XYZpatch( Beam->Lun, blc,trc, &BeamPatch[0][0], &BeamPatch[1][0] );

   assert(  fabs((double)(BeamPatch[0][(int)(n/2)]-ONE)) < 1.E-4,
           "Value at crpix_x,crpix_y is not 1." );

   xypar.xlen  = xlimu - xliml + 1;  xypar.ylen  = ylimu - yliml + 1;
   xypar.xref -= xliml;              xypar.yref -= yliml;
}

/******************************************************************************/
/*
   Calculate the Q power-value by summing the data inside a radius.
*/
/******************************************************************************/

private double SBQcalc( radius, Qcircle, BeamPatch )
int     radius;
logical Qcircle;
float   BeamPatch[2][PATCHSIZE];
{
   double Q = ZERO;
   int    x, y;
   TRACE("-- SBQcalc");

   for( y=0; y<xypar.ylen; y++ ) { for( x=0; x<xypar.xlen; x++ ) {
      if( Qcircle )
         Q += square(x - xypar.xref) + square(y - xypar.yref) < square(radius)
               ? square( BeamPatch[0][y*xypar.xlen+x] ) : 0.;
      else
         Q += (x - xypar.xref) <= radius && (y - xypar.yref) <= radius
               ? square( BeamPatch[0][y*xypar.xlen+x] ) : 0.;
   }}
   Q = sqrt( radius * Q );
   return( Q );
}

/******************************************************************************/
/*
   Get the full-width-half-max parameters. The algorithm was stolen from
   restor.for. The fitting routines were rewritten in C to keep mosaic.c
   self-contained.
   - Fit a 2-d gaussian, in units of pixels, get the xx, xy and yy coefficient
   - Convert to major axis/minor axis/position angle in arcseconds and degrees
*/
/******************************************************************************/

private void SBfitbeam( Beam, radius, BeamPatch, BM )
DATASET *Beam;
int      radius;
float    BeamPatch[2][PATCHSIZE];
BMPAR   *BM;
{
   int    Fit_2D_Gaussian(), i;
   void   Convert_GauPar();
   int    nx = 2*radius + 1;
   int    ny = 2*radius + 1;
   double b[3];
   TRACE("-- SBfitbeam");

   i=Fit_2D_Gaussian( BeamPatch,nx,ny, xypar.xref,xypar.yref, b );
   if( i == 0 ) {
      Convert_GauPar( b, xypar.xdelt, xypar.ydelt, TRUE );
      BM->bmaj = b[0];
      BM->bmin = b[1];
      BM->bpa  = b[2];
   } else {
      assert( i==0, "Failed to fit gaussian to %s, error %d\n", Beam->name, i );
   }
}

/******************************************************************************
/*
   Check whether the fitted beam is different from the one in the set header.
   If so, write it out.
*/
/******************************************************************************/

private void SBputbeam( Lun, BeamPar )
int    Lun;
BMPAR *BeamPar;
{
   void   GetItemR(), PutItemR();
   double bmaj, bmin, bpa;

   GetItemR( Lun, "bmaj", NOAX, &bmaj );
   GetItemR( Lun, "bmin", NOAX, &bmin );
   GetItemR( Lun, "bpa",  NOAX, &bpa  );
   if( !(   fEq(bmaj,BeamPar->bmaj) && fEq(bmin,BeamPar->bmin) &&
            fEq(bpa,rtod(BeamPar->bpa))                           ) ) {
      PutItemR( Lun, "bmaj", NOAX, BeamPar->bmaj );
      PutItemR( Lun, "bmin", NOAX, BeamPar->bmin );
      bpa = rtod(BeamPar->bpa);
      PutItemR( Lun, "bpa",  NOAX, bpa );
   }
}

/*

/******************************************************************************/
/*
   - Find a clean beam.
     This can either be read from the beamsize keyword, or be some suitable
     average of the parameters of all fitted dirty beams.
   - Then calculate the coordinates describing the convoling gaussian.
   - All results are stored in MosMap->RestoringBeam.
*/
/******************************************************************************/

private void GetRestoringBeam( RestoringBeam, Maps )
BMPAR  *RestoringBeam;
ONEMAP *Maps;
{
   private void BeamAverage();
           void keyd_c();
   TRACE("GetRestoringBeam");

   keyd_c( "beamsize", &RestoringBeam->bmaj, -ONE );

   if( RestoringBeam->bmaj == -ONE ) {
      BeamAverage( RestoringBeam, Maps );
   } else {
      keyd_c( "beamsize", &RestoringBeam->bmin, -ONE );
      RestoringBeam->bmin =
      RestoringBeam->bmin==-ONE ? RestoringBeam->bmaj : RestoringBeam->bmin;
      keyd_c( "beamsize", &RestoringBeam->bpa,   ZERO );
      assert( RestoringBeam->bmaj > ZERO, "Beam major axis must be >0" );
      assert( RestoringBeam->bmin > ZERO, "Beam minor axis must be >0" );
      RestoringBeam->bmaj = stor(RestoringBeam->bmaj);
      RestoringBeam->bmin = stor(RestoringBeam->bmin);
      RestoringBeam->bpa  = dtor(RestoringBeam->bpa);
   }
}

/******************************************************************************/
/*
   Average the fitted beams to get a restoring beam.
*/
/******************************************************************************/

private void BeamAverage( RestoringBeam, Maps )
BMPAR  *RestoringBeam;
ONEMAP *Maps;
{
   ONEMAP *MapI;
   int     Count;
   TRACE("BeamAverage");

   RestoringBeam->bmaj = RestoringBeam->bmin = RestoringBeam->bpa = ZERO;
   for( Count=0, ALLMAPSI ) { if(MapI->IsIFmap) {
      RestoringBeam->bmaj += MapI->BM.bmaj;
      RestoringBeam->bmin += MapI->BM.bmin;
      RestoringBeam->bpa  += MapI->BM.bpa;
      Count++;
   }}
   RestoringBeam->bmaj /= Count;
   RestoringBeam->bmin /= Count;
   RestoringBeam->bpa  /= Count;
}
