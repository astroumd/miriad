/*----------------------------------------------------------------------------
-- mosaic_save.c --
/*----------------------------------------------------------------------------*/
#define ARRNUMONLY
#include "mosaic_arrays.h"
/*----------------------------------------------------------------------------*/

/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*    <<< Save intermediate results >>>                383 +  179 =  562 DISKIO
/******************************************************************************/
/*
   Define some parameters that serve as indices to the Save array which is a
   logical array indicating which images must be saved. The SV_data, SV_shape
   and 'extensions' arrays give the place of the data to write and the extension
   of the output save set.
   SaveInput is used to read the keyword input.

   SV_VIS, SV_MVIS are not really working, since the scratch arrays for the FT
   and the IO are the same, which causes problems.
   SV_UVARR is not to be used by the user.
   SV_UVGAUSS is not called, because of array-shaped problems that are not
   worth solving.
*/
/******************************************************************************/

#define SV_PAR enum SAVE_PAR
SV_PAR { SV_PRB,    SV_COV,    SV_VIS,     SV_MVIS,     SV_UVARR,  SV_BEAM,
         SV_SDBEAM, SV_SDCOV,  SV_SDOBS,
         SV_PBC,    SV_CONV,   SV_RESITER, SV_INTRES,   SV_RESFINAL,
         SV_GGRADX, SV_REF,    SV_GRADX,   SV_INTGRADX, SV_EST,    SV_STEP,
         SV_GAUSS,  SV_UVGAUSS };
private char *extensions[] = {
        "prb",     "cov",     "vis",      "mvis",      "uvarr",   "beam",
        "sdbeam",  "sdcov",   "sdobs",
        "pbc",     "conv",    "res_iter", "res_int",   "res",
        "ggradx",  "ref",     "gradx",    "gradx_int", "est",     "step",
        "gauss",   "uvgauss", "" };
private enum arrayselections SV_data[] = {
         ps_PrB,    ps_Cov,    ps_Vis,     ps_Vis,      ps_Vis,    ps_SyB,
         ps_PrB,    ps_Cov,    ps_Drt,
         ps_PBC,    ps_Con,    ps_Res,     ps_Res,      ps_Res,
         ps_GGX,    ps_Ref,    ps_GrX,     ps_GrX,      ps_Mos,    ps_Stp,
         ps_Gau,    ps_Gau     };
private enum shapeselections SV_shape[] = {
         PrB_Shape, Cov_Shape, Cov_Shape,  Cov_Shape,   Cov_Shape, Bea_Shape,
         PrB_Shape, Cov_Shape, Drt_Shape,
         Drt_Shape, Drt_Shape, Drt_Shape,  Drt_Shape,   Drt_Shape,
         Mos_Shape, Mos_Shape, Mos_Shape,  Mos_Shape,   Mos_Shape, Mos_Shape,
         Gau_Shape, Gau_Shape  };

#define NSAVE SV_UVGAUSS+1
private logical Save[NSAVE];
private int     SaveIteration, MaxIteration;
private logical EXTENDSAVES; /* Whether savesets have MaxIters planes or not */

/******************************************************************************/
/*
   Read save= keyword, decode strings into logicals.
   (input on master)
*/
/******************************************************************************/

void SaveInput( MaxIter, pbc, finres )
int     MaxIter;
logical pbc, finres;
{
   void           keyi_c(), keyl_c(), keya_c();
   logical        MORE=TRUE;
   register int   i;
   char           SaveInp[INSTRLEN];
   extern logical Save[];
   extern int     SaveIteration, MaxIteration;

   keyi_c( "saveiter", &SaveIteration, 1    );
   assert( SaveIteration>=1, "saveiter must have value >1" );

   keyl_c( "extsav",   &EXTENDSAVES,  FALSE );
   MaxIteration  = MaxIter;

   for( i=0; *extensions[i]; i++ ) Save[i]=FALSE;
   while( MORE ) {
      keya_c( "save", SaveInp, "\0" ); if( SaveInp[0]=='\0' ) break;
      for( i=0; *extensions[i]; i++ ) {
         if( StrEqX(SaveInp,extensions[i]) ) { Save[i]=TRUE; break; }
      }
      assert( *extensions[i]!='\0', "Unknown save option (no minimal match)" );
   }
   Save[SV_PBC]      = pbc;
   Save[SV_RESFINAL] = finres;

   assert( !(Save[SV_VIS] & Save[SV_MVIS]), "Cannot save both vis and mvis" );
}

/******************************************************************************/
/*
  Exchange save logicals.
  (input on slave)
*/
/******************************************************************************/

void ExchSavePar()
{
   void    DTMexchange();
   logical DTMm2s();
   DTMexchange( DTMm2s(), "SAVEPAR", "lllllllllllllllllllllli",
   &Save[SV_PRB],     &Save[SV_BEAM],   &Save[SV_COV],
   &Save[SV_SDBEAM],  &Save[SV_SDCOV],  &Save[SV_SDOBS],
   &Save[SV_VIS],     &Save[SV_MVIS],   &Save[SV_UVARR],
   &Save[SV_PBC],     &Save[SV_CONV],
   &Save[SV_RESITER], &Save[SV_INTRES], &Save[SV_RESFINAL],
   &Save[SV_GGRADX],  &Save[SV_REF],    &Save[SV_GRADX],   &Save[SV_INTGRADX],
   &Save[SV_EST],     &Save[SV_STEP],   &Save[SV_GAUSS],   &Save[SV_UVGAUSS],
   &SaveIteration );
}

/******************************************************************************/
/*
   Define some variables and functions needed to save the steps of the
   convolution.
/*
/******************************************************************************/

/*
#ifndef CMSSLFFT
private DATASET *VisSet;
private int      SvIter;
private Real    *VisArr;
private int      VisCnt;

void SaveConvInit(Set,Iter) DATASET *Set;int Iter; { VisSet=Set; SvIter=Iter; }

void SaveVisInit(Vis_Arr) Real *Vis_Arr; { VisArr=Vis_Arr; VisCnt=0; }

private void SaveTheVis(Cover,Carr2) Real *Cover; cmplx *Carr2;
{  if(VisSet!=NULL) {
   if(Save[SV_VIS])  *(VisArr+VisCnt) = cpxAbs(*Carr2);
   if(Save[SV_MVIS]) *(VisArr+VisCnt) = cpxAbs(*Carr2) * *Cover;
   VisCnt++; }
}
private void SaveThePln(uvPln,size) cmplx *uvPln; int size;
{  int n;
   if(VisSet!=NULL) { if(Save[SV_UVARR]) {
   for(n=0;n<size;n++) { *(VisArr+n)=cpxAbs(*uvPln); uvPln++; }} }
}*/
/* Does nothing now, since the uv plane scratch area is the same as the
   IO scratch area, so that saving it would overwrite the visibilities
   that were just so painstakingly generated.
   For later thought on how to save the memory, while allowing the
   writing....
private void SaveVisibilities(VisArrSer,VisArrPar,ParShape)
Real      *VisArrSer;
Real_void *VisArrPar;
shape     *ParShape;
{  void SaveSet();
#ifdef __CSTAR__
   with( *ParShape ) *VisArrPar = write_to_pvar( VisArrSer ) ;
#endif
   SaveSet( "vis",   VisSet, SvIter );
   SaveSet( "mvis",  VisSet, SvIter );
   SaveSet( "uvarr", VisSet, SvIter );
}
private void SaveVisEnd() { VisSet = NULL; }
#endif
*/

/******************************************************************************/
/*
   SaveSet is called in the calculation routines, and by DTMremoteExec.
   - If running only locally, get the name of the SaveSet and call WriteData
   - If running remotely:
     remote: send the SAVE info; tell DTMremoteExec to call SaveSet; call
             WriteData
     local:  receive SAVE info; decode name to find the corresponding set;
             find the SaveSet name; call WriteData; close saveset.
*/
/******************************************************************************/

void SaveSet( SaveType, Set, Iteration )
char    *SaveType;
DATASET *Set;
int      Iteration;
{
   logical          LocallyRun(), DTMmaster(), DTMs2m();
   void             DTMexchange();
   void             MapStructs();
   private DATASET *SaveSetGet();
   void             WriteData();
   private void     SaveSetClose();

   char             svtype[10], name[FILENAMELEN];
   int              i;
   SV_PAR           SaveIndex=0;
   DATASET         *TheSaveSet;
   extern logical   Save[];
   extern int       SaveIteration, MaxIteration;

   MOSMAP          *MosMap;
   ONEMAP          *Maps, *MapI;

   if( LocallyRun() ) {
      if( Iteration < SaveIteration && Iteration != -1 ) return;
      i=0; while( !StrEqX(SaveType,extensions[i])&&(*extensions[i]!='\0') ) i++;
      if(!Save[i]) return;
      TRACE("SaveSet");
      StrCpy(svtype,SaveType); StrCpy(name,Set->name);
      SaveIndex = (SV_PAR)i;

   } else {

   if( !DTMmaster() ) {
      if( Iteration < SaveIteration && Iteration != -1 ) return;
      i=0; while( !StrEqX(SaveType,extensions[i])&&(*extensions[i]!='\0') ) i++;
      if(!Save[i]) return;
      TRACE("SaveSet");
      DTMexchange( DTMs2m(), "SAVE", "ssii", SaveType,Set->name,&Iteration,&i);
      WriteData(0,0,0,DNULL); /* wait till get READY if no save, or do IO
                                 this call synchronizes with the call to
                                 WriteData below */
      return;
   }

   if( DTMmaster() ) {
      TRACE("SaveSet");
      DTMexchange( DTMs2m(), "SAVE", "ssii", svtype, name, &Iteration, &i );
      SaveIndex = (SV_PAR)i;

      MapStructs( &MosMap, &Maps );
      if(   StrEqX(name,MosMap->MosaicMap.name)){Set=&MosMap->MosaicMap;       }
      else { for( ALLMAPSI ) {
         if(StrEqX(name,MapI->DirtyMap.name   )){Set=&MapI->DirtyMap;   break; }
         if(StrEqX(name,MapI->PrimaryBeam.name)){Set=&MapI->PrimaryBeam;break; }
        if(MapI->IsIFmap &&
            StrEqX(name,MapI->SynthBeam.name  )){Set=&MapI->SynthBeam;  break; }
      }}
   }
   }

   TheSaveSet = SaveSetGet( Set, SaveIndex,
                            SaveIteration, Iteration, MaxIteration );

   WriteData( SV_data[SaveIndex], NOMASK, SV_shape[SaveIndex], TheSaveSet );

   SaveSetClose( TheSaveSet, SaveIndex );
}

/******************************************************************************/
/*
   String together the routines that create a description of the set to save.
   Return value is a pointer to this description.

   The DATASET pointer Set contains a template to get information describing
   the dataset being saved. SaveIndex drives the details and selects the array.

   There are two ways:
   - EXTENDSAVES == TRUE:
     A new plane is added to the saved dataset for each iteration. To achieve
     this a trick has to be applied because miriad disallows appending; this
     trick is done by ExtendDataSet. On each entry of SaveDataSet the dataset
     is opened and closed.
   - EXTENDSAVES == FALSE:
     The dataset is opened with MaxIters planes, and each plane is subsequently
     written.
     After an input plane is finished, all open datasets are closed and all name
     strings are reset. Some unwritten planes will remain.

   Both options need to remain present. EXTENDSAVES=FALSE is faster, since the
   save set is not copied, which can slow things down considerably for later
   iterations, especially if there are multiple save sets. But EXTENDSAVES=TRUE
   is the only way to obtain test output if the program crashes or is aborted.

   SaveSetParameters figures out the description of the saveset, and sets the
   CurPlane pointer that WriteData uses to write the proper plane. It returns a
   pointer to the description. WriteData writes the plane. SaveSetClose always
   closes the set if EXTENDSAVES is TRUE, but else only closes the savesets that
   have only a single plane written to them (e.g. coverage, primary beam).

   - A list of pointers to previously created savesets is kept elsewhere. If the
   saveset was already created, a pointer to it is returned. If this is the
   first time this saveset is needed, it is created and the description is
   filled in.
   - Then the plane to write to is determined.
   - svSet->Lun is 0 if the saveset was just created, or if it was previously
   closed. In the first case, plane will be 1 and a new dataset is opened.
   In the second case, it depends on EXTENDSAVES. If that is FALSE, a new
   dataset is opened only on the first plane; if it is TRUE, the dataset is
   extended and left open to append. The lun of the dataset is always filled in
   on exit.

   The routines called do the following:
   - SaveSetName     makes the name, using the Set-name, Set-plane and save mode
   - SaveSetPlane    determines the current plane and the z description of svset
   - SaveSetParams   finds the coordinate description
   - SaveSetPresent  tells whether save set description was already created
   - SaveSetAddition allocates space for a save set and returns a pointer to it
   - SaveSetAssignment return pointer to save set that was already created
*/
/******************************************************************************/

private DATASET *SaveSetGet( Set, SaveIndex, SaveIter, Iteration, MaxIter )
DATASET *Set;
SV_PAR   SaveIndex;
int      SaveIter, Iteration, MaxIter;
{
   private void     SaveSetName();
   private int      SaveSetPlane(); int plane;
   private void     SaveSetParams();
   private logical  SaveSetPresent();
   private DATASET *SaveSetAddition(), *SaveSetAssignment(); DATASET *svSet;
   void             Open_NewDataSet();
   private void     ExtendDataSet();
   char             name[FILENAMELEN];
   TRACE("-- SaveSetGet");

   SaveSetName( Set, SaveIndex, name );
   if( ! SaveSetPresent( name ) ) {
      svSet = SaveSetAddition( SaveIndex );
      SaveSetParams( svSet,name,&Set->Coords,SaveIndex,Set->SetNum,SaveIter );
   } else {
      svSet = SaveSetAssignment();
   }

   plane = svSet->Coords.CurPlane =
   SaveSetPlane( SaveIndex, &Set->Coords, &svSet->Coords,
                 SaveIter, Iteration, MaxIter );

   if( svSet->Lun == 0 ) {
      if( plane == 1 )     Open_NewDataSet( svSet, DNULL );
      else if(EXTENDSAVES) ExtendDataSet(   svSet        );
   }

   return( svSet );
}

/******************************************************************************/
/*
   Return a string with the name of the save set. This is constructed from the
   template set's name, with appropriate extension.
*/
/******************************************************************************/

private void SaveSetName( Set, SaveIndex, name )
DATASET *Set;
SV_PAR   SaveIndex;
char    *name;
{
   switch( SaveIndex ) {
   case SV_GGRADX: case SV_REF:
   case SV_GRADX:  case SV_INTGRADX:
   case SV_STEP:   case SV_EST:
            Sprintf( name, "%s", Set->name );
           *( name+strlen(name)-1-strlen(Set->type) ) = '\0';
            StrCat( name, "_" ); StrCat( name, extensions[SaveIndex] ); break;
   case SV_GAUSS: case SV_UVGAUSS:
            Sprintf( name, "%s%s",  Set->name, extensions[SaveIndex] ); break;
   case SV_PBC:
            Sprintf( name, "%s",    Set->name );                        break;
   default:
            Sprintf( name, "%s_%s", Set->name, extensions[SaveIndex] ); break;
   }

   switch( SaveIndex ) {
   case SV_BEAM:   case SV_COV:     case SV_PRB:
   case SV_SDBEAM: case SV_SDCOV:   case SV_SDOBS:
   case SV_PBC:    case SV_RESFINAL:
   case SV_GGRADX: case SV_REF:
   case SV_GAUSS:  case SV_UVGAUSS:                                    break;
   default: Sprintf( name+strlen(name), "_%d", Set->Coords.CurPlane ); break;
   }
}

/******************************************************************************/
/*
   Find the plane number in the dataset that is saved
   - for some one-time savings: it is 1
   - for reference saving: from the current plane
   - normally from the current iteration
   Also determine the length of the third axis.
*/
/******************************************************************************/

private int SaveSetPlane( SaveIndex,SetCoo,SaveCoo,SaveIter,Iteration,MaxIters )
SV_PAR  SaveIndex;
COORDS *SetCoo, *SaveCoo;
int     SaveIter, Iteration, MaxIters;
{
   int plane;
   int FirstSave;
   switch( SaveIndex ) {
   case SV_BEAM:   case SV_COV:   case SV_PRB:
   case SV_SDBEAM: case SV_SDCOV:
   case SV_GGRADX: case SV_GAUSS: case SV_UVGAUSS:
        plane = 1;
        SaveCoo->trc[FQ_AXIS] = SaveCoo->ZLEN = 1;
        break;
   case SV_SDOBS: case SV_REF: case SV_RESFINAL: case SV_PBC:
        plane = SetCoo->CurPlane;
        SaveCoo->trc[FQ_AXIS] = SaveCoo->ZLEN = SetCoo->ZLEN;
        break;
   default:
        FirstSave = SaveIter;
        plane = Iteration - FirstSave + 1;
        SaveCoo->trc[FQ_AXIS] =
        SaveCoo->ZLEN = EXTENDSAVES ? plane : MaxIters - FirstSave + 1;
        break;
   }
   return( plane );
}

/******************************************************************************/
/*
   Determine the parameters of a dataset that is to be saved.
   SaveIndex tells the function what is being saved.
   In the case of visibilility datasets some shuffling of axes is done because
   the visibility plane is rotated and only half as big in x as the image plane.
   This gets in a name, coordinates and flag, from which everything is made.
*/
/******************************************************************************/

private void SaveSetParams( TheSaveSet,name,SetCoo,SaveIndex,SetNum,SaveIter )
DATASET *TheSaveSet;
char    *name;
COORDS  *SetCoo;
SV_PAR   SaveIndex;
int      SetNum;
int      SaveIter;
{
   void    InitSet();
   void    CooCopy();
   COORDS *SaveCoo = &TheSaveSet->Coords;
   TRACE("-- SaveSetParams");

   InitSet( TheSaveSet, name, "saveset", "new", SetNum );

   CooCopy( SaveCoo, SetCoo );
   switch( SaveIndex ) {
   case SV_COV: case SV_SDCOV:
   case SV_VIS: case SV_MVIS:
#ifdef POWERFFT
      SaveCoo->XLEN = SaveCoo->trc[RA_AXIS] = SetCoo->XLEN / 2 + 1;
      SaveCoo->YLEN = SaveCoo->trc[DC_AXIS] = SetCoo->YLEN;         break;
#else
      SaveCoo->XLEN = SaveCoo->trc[RA_AXIS] = SetCoo->YLEN;
      SaveCoo->YLEN = SaveCoo->trc[DC_AXIS] = SetCoo->XLEN / 2 + 1; break;
#endif
   case SV_UVARR:
      SaveCoo->XLEN = SaveCoo->trc[RA_AXIS] = SetCoo->XLEN / 2 + 1;
      SaveCoo->YLEN = SaveCoo->trc[DC_AXIS] = SetCoo->YLEN;         break;
   default:                                                         break; }
                      SaveCoo->blc[FQ_AXIS] = 1;

   SaveCoo->crval[FQ_AXIS] = SaveIter;
   SaveCoo->crpix[FQ_AXIS] = SaveCoo->cdelt[FQ_AXIS] = ONE;
   switch( SaveIndex ) {
   case SV_BEAM:   case SV_COV:   case SV_PRB:
   case SV_SDBEAM: case SV_SDCOV:
   case SV_GGRADX: case SV_GAUSS: case SV_UVGAUSS:
                StrCpy( SaveCoo->ctype[FQ_AXIS], "NONE" );    break;
   case SV_SDOBS: case SV_REF: case SV_PBC: case SV_RESFINAL: break;
   default:     StrCpy( SaveCoo->ctype[FQ_AXIS], "ITER" );    break; }
}

/******************************************************************************/
/*
   Keep a linked list of previously constructed datasets.
   Some functions return info:
   - SaveSetPresent:    if TRUE, datasets was created
   - SaveSetAddition:   allocates space for another save set
   - SaveSetAssignment: returns a pointer to found save set
*/
/******************************************************************************/

typedef struct saves { DATASET *Set; SV_PAR SaveIndex; struct saves *next;
                     } SAVES;
private SAVES *SaveList = NULL;
private SAVES *sv;

private logical SaveSetPresent( name )
char *name;
{
   logical present = FALSE;
   sv = SaveList;
   while( sv != NULL ) {
      if( StrEqX( sv->Set->name, name ) ) { present = TRUE; break; }
      sv = sv->next;
   }
   return( present );
}

private DATASET *SaveSetAddition( SaveIndex )
SV_PAR SaveIndex;
{
   if( SaveList == NULL ) { Malloc( SaveList, SAVES, 1 ); sv = SaveList; }
   else                   { sv=SaveList; while(sv->next!=NULL) sv=sv->next;
                            Malloc( sv->next, SAVES, 1 ); sv = sv->next; }
   Malloc( sv->Set, DATASET, 1 );
   sv->SaveIndex = SaveIndex;
   sv->next      = NULL;
   return( sv->Set );
}
private DATASET *SaveSetAssignment() { return( sv->Set ); }

/******************************************************************************/
/*
   Close savesets that are open.
   In any mode, close _cov, _prb, _ggradx, _gauss on first pass.
   When extending, close other datasets always.
   Without extending, other datasets are closed when the program is finished
   with a plane; then SaveSetsClose is called by WriteResult.
   Closing sets the Lun to 0, a feature that SaveSetGet depends on.
*/
/******************************************************************************/

private void SaveSetClose( TheSaveSet, SaveIndex )
DATASET *TheSaveSet;
SV_PAR   SaveIndex;
{
   void CloseDataSet();
   TRACE("-- SaveSetClose");

   if( EXTENDSAVES ) {
      CloseDataSet( TheSaveSet, TRUE );
   } else {
      switch( SaveIndex ) {
      case SV_BEAM:   case SV_COV:   case SV_PRB:
      case SV_SDBEAM: case SV_SDCOV:
      case SV_GGRADX: case SV_GAUSS: case SV_UVGAUSS:
         CloseDataSet( TheSaveSet, TRUE );
      }
   }
}

void SaveSetsClose()
{
   private void  FillWithZeroes();
   private void  SaveHistory();
   void          CloseDataSet();
   int           PASS;
   logical       doclose;
   DATASET      *SvSet;
   if( EXTENDSAVES      || /* sets were already closed  */
       SaveList == NULL )  /* no saveset present at all */ return;
   TRACE("SaveSetsClose");

   for( PASS=1; PASS<=2; PASS++ ) {
   sv = SaveList;
   do {
      SvSet = sv->Set;
      doclose = TRUE;
      if( SvSet->Lun == 0 ) doclose = FALSE;
      if( ( (sv->SaveIndex == SV_SDOBS) | (sv->SaveIndex == SV_REF) |
            (sv->SaveIndex == SV_PBC)   | (sv->SaveIndex == SV_RESFINAL) ) &&
          ( SvSet->Coords.CurPlane < SvSet->Coords.ZLEN )  ) doclose = FALSE;
      if( doclose ) {
         if( PASS==1 ) {
            if( SvSet->Coords.CurPlane < SvSet->Coords.ZLEN ) {
               FillWithZeroes( SvSet->Lun, SvSet->name, &SvSet->Coords );
            }}
         if( PASS==2 ) {
            SaveHistory( SvSet );
            CloseDataSet( SvSet, TRUE );
         }
      }
      sv = sv->next;
   } while( sv );
   }
}

private void SaveHistory( Set )
DATASET *Set;
{
   void hisopen_c(), hisclose_c(), hisinput_c();
   hisopen_c(  Set->Lun, "append" );
   hisinput_c( Set->Lun, "MOSAIC" );
   hisclose_c( Set->Lun           );
}



private void FillWithZeroes( Lun, name, SaveCoo )
int     Lun;
char   *name;
COORDS *SaveCoo;
{
   void SetupDataSet();
   void CopyDisk();
   void SetIObuffer();
   int  plane;
   int  xlen   = SaveCoo->XLEN;
   int  ylen   = SaveCoo->YLEN;
   int  length = xlen * ylen;
   TRACE("FillWithZeroes");

   SetIObuffer( length );

   plane = ++SaveCoo->CurPlane;
   for( ; SaveCoo->CurPlane <= SaveCoo->ZLEN; SaveCoo->CurPlane++ ) {
      SetupDataSet( Lun, SaveCoo );
      CopyDisk(     WRITE, Lun, 0, SaveCoo->CurPlane, xlen, ylen );
   }
   wwarning( TRUE, "zeroes were written to planes %d to %d of %s",
             plane, SaveCoo->ZLEN, name );
}

/******************************************************************************/
/*
   Prepare an output image for appending. This is done by renaming the output,
   then opening it and also opening the a dataset with the original name, but
   adding one plane to it. The data is then copied line by line from the renamed
   original to the new dataset and in the end the renamed dataset is deleted.
*/
/******************************************************************************/

private void ExtendDataSet( Set )
DATASET *Set;
{
   void    CooCopy();
   void    Open_OldDataSet(), Open_NewDataSet(), SetupDataSet(), CloseDataSet();
   void    CopyDisk();

   DATASET PrevSet;
   COORDS *SetCoo  = &Set->Coords;
   COORDS *PrevCoo = &PrevSet.Coords;

   Calloc( PrevSet.name, strlen(Set->name)+strlen("_previous")+1 );
   StrCpy( PrevSet.name, Set->name ); StrCat( PrevSet.name, "_previous" );
   CooCopy( PrevCoo, SetCoo );
   PrevCoo->ZLEN = PrevCoo->trc[FQ_AXIS] = SetCoo->CurPlane-1;
   assert( rename( Set->name, PrevSet.name ) == 0,
           "Error renaming test output set %s", Set->name );

   Open_OldDataSet(    &PrevSet); SetupDataSet(PrevSet.Lun, &PrevSet.Coords );
   Open_NewDataSet(Set,&PrevSet); SetupDataSet(   Set->Lun,    &Set->Coords );

   CopyDisk( COPY, PrevSet.Lun, Set->Lun, Set->Coords.CurPlane,
                                          Set->Coords.XLEN, Set->Coords.YLEN );
   CloseDataSet( &PrevSet, FALSE );
   assert( remove(PrevSet.name) == 0, "Could not remove %s",PrevSet.name );
}
