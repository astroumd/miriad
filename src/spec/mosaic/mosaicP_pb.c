/*----------------------------------------------------------------------------
-- mosaic_pb.c --
/*----------------------------------------------------------------------------*/
#include "mosaic_stc.h"
/*----------------------------------------------------------------------------*/

/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*    <<< Primary beam >>>                             372 +  134 =  506 USERIO
/******************************************************************************/
/*
   DTM NOTE: PRIMARY BEAM CALCULATION ROUTINES MAY RUN REMOTELY
*/
/******************************************************************************/
/*
   Routines to obtain the primary beam corrections.

   Only uses PBPAR and COORDS structs from mosaic_stc.h

   The WSRT and FST parameters are from the GIPSY task PBCORR.
   The VLA parameters are from the AIPS task PBCOR.
       VLA coefficients are surely wrong beyond 3-20 cm.
   The AT parameters come from the ATNF memo by Wieringa & Kesteven.
   The Hat Creek gaussian fwhm comes from the BIMA users guide (jan89).

   For each telescope several frequency ranges are given, in which a given set
   of coefficients is valid.
   - The first element of (tel)freqs gives the number of ranges.
   - For each range the first member of (tel)polys gives the order of the
     polynomial expansion for PBCORR, or the value 1 for non-polynomials.
   - The rest of array (tel)polys gives all these coefficients, which are
     coefficients for a polynomial in r^2, with r being the distance to the
     center (in degrees for WSRT, in arcminutes for VLA and AT).
   - Finally, a variable (tel)fwhm_dG gives the approximate FWHM of the beam in
     units of deg GHz, which allows one to calculate an approximate gaussian if
     the frequency is known.
   The telescop item from the header is checked against the list of known
   telescopes and converted into a number.

   The variables in struct PBPAR (defined above) are:
   - Telescope: name of telescope as read from the header
   - Tel:       the corresponding telescope number
   - fwhm:      fwhm of primary beam in degrees
   - freq:      frequency of observation in GHz
   - LimFreq    gives the frequency above which input units are arcsec, below
                which they are arcsec.
   - func:      type of the primary beam function (gaussian, polynomial ...)
   - cutoff:    inverse corrections that end up above this cutoff are set to 0
   - coeff[0]:  for poly:   order of polynomial
                for other:  1
   - coeff[1]:  for gauss:  4ln(2)/fwhm^2
                for Airy:   2.*1.616340/fwhm (x of the first zero)
                poly:       coeff[1]->coeff[5] describes a polynomial
     NPOLYCOEFF is maximum number of coefficients
*/
/******************************************************************************/

/*private char *Telescopes[] = {
   "NOPB",     "GAUSSIAN", "AIRY",   "WSRT", "VLA",   "FST", "DRAO", "ATCA",
   "HATCREEK", "IRAM",     "NRO",    "OVRO", "\0" };*/
enum telescopes {
    NONE,       GAUSSIAN,   AIRYDISK, WSRT,   VLA,     FST,   DRAO,   AT,
    BIMA,       IRAM,       NOBEYAMA, OVRO,   UNKNOWNTEL };
enum pbtypes { NOPB, GAUSS, AIRY, AIRYC, POLY, INVPOLY, COS6 };

private double wsrtfwhm_dG[] = { 0.858938, 0.847777, 0.8862846 };
private double wsrtfreqs[]   = { 3,   0.2, 0.49,   0.5, 1.29,   1.3, 14.0 };
private double wsrtpolys[]   = { 0.,  62.9,
                                 3.,  1.0, -3.51964, 4.44904, -1.93508,
                                 3.,  1.0, -3.29134, 4.18568, -1.99085 };

private double vlafwhm_dG = 0.73758;
private double vlafreqs[] = { 7,  0.071, 0.075,  0.297, 0.345,  1.240, 1.810,
                                  4.240, 5.110,  7.540, 9.060, 14.240,15.710,
                                 21.690,24.510 };
private double vlapolys[] = {
             4.,  0.9920378,9.956885e-4,3.814573e-6,-5.311695e-9,3.980963e-12,
             4.,  0.9920378,9.956885e-4,3.814573e-6,-5.311695e-9,3.980963e-12,
             4.,  0.9920378,9.956885e-4,3.814573e-6,-5.311695e-9,3.980963e-12,
             4.,  0.9920378,9.956885e-4,3.814573e-6,-5.311695e-9,3.980963e-12,
             4.,  0.9920378,9.956885e-4,3.814573e-6,-5.311695e-9,3.980963e-12,
             4.,  0.9920378,9.956885e-4,3.814573e-6,-5.311695e-9,3.980963e-12,
             4.,  0.9920378,9.956885e-4,3.814573e-6,-5.311695e-9,3.980963e-12 };

private double fstfwhm_dG = 1.11589;
private double fstfreqs[] = { 1,     1.0,    2.0 };

private double atfwhm_dG[] = { 0.80681, 0.83557, 0.81482, 0.85010 };
private double atfreqs[]   = { 4,  1.15,1.88, 2.10,2.60, 4.30,6.70, 7.90,9.30 };
private double atpolys[]   = { 4., 1.0, 8.99e-4, 2.15e-6, -2.23e-09, 1.56e-12,
                               4., 1.0, 1.02e-3, 9.48e-7, -3.68e-10, 4.88e-13,
                               4., 1.0, 1.08e-3, 1.31e-6, -1.17e-09, 1.07e-12,
                               4., 1.0, 1.04e-3, 8.36e-7, -4.68e-10, 5.50e-13 };

private double hcfwhm_dG    = 3.0666; /* 11040.0; */
private double hcfreqs[]    = { 1.,   74.0,  116.0 };

/******************************************************************************/
/*
   Initialize coefficients for primary beam of a known telescope, at a given
   frequency.
*/
/******************************************************************************/

private logical TelescopePB( PB )
PBPAR *PB;
{
   private int  MatchFreq();
   private void GaussPB();
   private int  PolyPB();
           int freqnum;
   TRACE("-- TelescopePB");

  assert(PB->freq!=ZERO,"No frequency in header, can't calculate primary beam");

   if(        StrEq( PB->Telescope, "WSRT" ) ) {
      freqnum = PolyPB( PB, wsrtfreqs, wsrtpolys, 0.063, "deg", FALSE );
      if(PB->coeff[0]==0) { PB->coeff[1] *= dtor(PB->freq); PB->pbtype = COS6; }
      PB->fwhm = wsrtfwhm_dG[freqnum] / PB->freq;

   } else if( StrEq( PB->Telescope, "VLA" ) ) {
      freqnum = PolyPB( PB, vlafreqs, vlapolys, 0.023, "arcmin", TRUE );
      PB->fwhm = vlafwhm_dG / PB->freq;

   } else if( StrEq( PB->Telescope, "FST" ) ) {
      freqnum = MatchFreq( PB->freq, fstfreqs, PB->Telescope );
      GaussPB( PB, fstfwhm_dG / PB->freq );

   } else if( StrEq( PB->Telescope, "DRAO" ) ) {
      freqnum = 0;
      assert( FALSE, "No primary beam constants known for DRAO" );

   } else if( StrEq( PB->Telescope, "ATCA" ) ) {
      freqnum = PolyPB( PB, atfreqs, atpolys, 0.030, "arcmin", TRUE );
      PB->fwhm = atfwhm_dG[freqnum] / PB->freq;

   } else if( StrEq( PB->Telescope, "HATCREEK" ) ) {
      freqnum = MatchFreq( PB->freq, hcfreqs, PB->Telescope );
      GaussPB( PB, hcfwhm_dG / PB->freq );

   } else if( StrEq( PB->Telescope, "IRAM" ) ) {
      freqnum = 0;
      assert( FALSE, "No primary beam constants known for IRAM" );

   } else if( StrEq( PB->Telescope, "NRO" ) ) {
      freqnum = 0;
      assert( FALSE, "No primary beam constants known for NOBEYAMA" );

   } else if( StrEq( PB->Telescope, "OVRO" ) ) {
      freqnum = 0;
      assert( FALSE, "No primary beam constants known for OVRO" );

   } else if( *PB->Telescope == '\0' ) {
      freqnum = 0;
      wwarning( TRUE, "No telescope name in header" );
      return FALSE;
   } else {
      freqnum = 0;
      wwarning( TRUE, "Telescope %s unknown", PB->Telescope );
      return FALSE;
   }
   PB->freqnum = freqnum;
   return TRUE;
}

/******************************************************************************/
/*
   Initialize the parameters for no primary beam corrections
*/
/******************************************************************************/

private void NoPB( PB )
PBPAR *PB;
{
   PB->pbtype = NOPB;
}

/******************************************************************************/
/*
   Initialize the parameters for a gaussian primary beam.
*/
/******************************************************************************/

private void GaussPB( PB, fwhm )
PBPAR *PB;
double fwhm;
{
   PB->fwhm     = fwhm;
   PB->coeff[0] = 1.;
   PB->coeff[1] = FOURLN2 / square(fwhm);
   PB->cutoff   = -log(1/20.);
   PB->pbtype   = GAUSS;
}

/******************************************************************************/
/*
   Initialize the parameters for an Airy disk primary beam.
*/
/******************************************************************************/

private void AiryPB( PB, fwhm )
PBPAR  *PB;
double  fwhm;
{
   PB->fwhm     = fwhm;
   PB->coeff[0] = 1.;
   PB->coeff[1] = 2. * 1.616340 / PB->fwhm;
   PB->cutoff   = 1.e30;
   PB->pbtype   = AIRY;
}

/******************************************************************************/
/*
   Initialize the parameters for an Airy disk primary beam cut off at 1st zero.
*/
/******************************************************************************/

private void AiryCPB( PB, fwhm )
PBPAR  *PB;
double  fwhm;
{
   PB->fwhm     = fwhm;
   PB->coeff[0] = 1.;
   PB->coeff[1] = 2. * 1.616340 / PB->fwhm;
   PB->cutoff   = 3.;
   PB->pbtype   = AIRYC;
}

/******************************************************************************/
/*
   Initialize the parameters for a polynomial primary beam.
   poly contains the order and the coefficients, one set for each possible
   frequency range.
*/
/******************************************************************************/

private int PolyPB( PB, freqranges, coeff, cutoff, units, invpoly )
PBPAR  *PB;
double  freqranges[];
double  coeff[];
double  cutoff;
char   *units;
logical invpoly;
{
   int          freqnum;
   private int  MatchFreq();
   private void GetCoeffs();
   int          i=0, j=0;
   freqnum = MatchFreq( PB->freq, freqranges, PB->Telescope );
   while( i<freqnum ) { j += 2 + coeff[j];  i++; }
   GetCoeffs( PB, &coeff[j], units );
   if( !invpoly ) { PB->pbtype = POLY;    PB->cutoff =     cutoff; }
   else           { PB->pbtype = INVPOLY; PB->cutoff = ONE/cutoff; }
   return( freqnum );
}

private int MatchFreq( freq, freqranges, Telescope )
double freq;
double freqranges[];
char  *Telescope;
{
   int  freqnum = -1, i=0;
   while( i < (int)freqranges[0] ) {
      if( between(freqranges[i*2+1],freq,freqranges[i*2+2]) ) freqnum=i;
      i++;
   }
   assert( freqnum != -1, "%8.4g GHz invalid frequency for %s",freq,Telescope );
   return( freqnum );
}

private void GetCoeffs( PB, coeff, units )
PBPAR *PB;
double coeff[];
char  *units;
{
   int    i=0;
   double conv=-1., fac;
   if( StrEq( units, "radian" ) ) conv = square( dtor(PB->freq) );
   if( StrEq( units, "deg"    ) ) conv = square(      PB->freq  );
   if( StrEq( units, "arcmin" ) ) conv = square( dtom(PB->freq) );
   if( StrEq( units, "arcsec" ) ) conv = square( dtos(PB->freq) );
   assert(conv!=-1.,"GetCoeffs: unknown units");
   fac = conv;
   PB->coeff[0] = coeff[0];
   PB->coeff[1] = coeff[1];
   i=0; while( i<(int)coeff[0] ) {
   PB->coeff[i+2] = coeff[i+2] * fac; fac*=conv; i++; }
}

/*

/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*    <<< Primary Beam IO >>>                          127 +   78 =  205 USERIO
/******************************************************************************/
/*
   Initialize the primary beam constants. This requires an interplay between
   a keyword and the header values of telescop, pbfwhm and restfreq (or crval3
   if restfreq not present and crtype3 is FREQ)

   Possibilities:
     - ""         => tel
     - ...        => repeats the last given value for the remaining inputs
     - none       => no primary beam correction
     - tel        => find "telescop" and "restfreq" from header, use
                     formula for telescope described below
                     if "telescop" is unknown, make a gaussian with fwhm
                     from header item "pbfwhm".
     - gauss,fwhm => create a gaussian primary beam (cut off at 0.05)
     - airy,fwhm  => create an airy disk
     - airyc,fwhm => create an airy disk, but only out to the first zero
     If fwhm > 0  => make primary beam of given type with this fwhm
                    (if restfreq>10 GHz units are arcsec, else arcmin)
     If fwhm = 0  => read fwhm from header item "pbfwhm"; if this is not
                     present, use "restfreq" and "telescop" to get fwhm
    For "type=tel", the header items "telescop" and "restfreq" are used
    to construct the primary beam: a polynomial for the WSRT, VLA and AT,
    a gaussian for FST and BIMA; both types of functions cut off at a
    level of about 0.05. If "restfreq" is not present, but the type of
    the "freq" axis is "FREQ", then its crval, crpix and cdelt are used
    to calculate the frequency of plane 1.

   The header that is read is given by the 'Observation' dataset within map. The
   results go into the primary beam description connected with the 'Map'
   dataset.


   - Read the fwhm, telescop and restfreq from header of template.
   - Get the pb keyword value, using PBkeyRead. This guarantees a valid value
     comes back, giving the pb type and the fwhm.
   - Set the appropriate PB parameters.
   - Check the maxcorr keyword.
   - Check the pboff keyword.
   - Set the reference pixel and gridspacing.
*/
/******************************************************************************/

void PBkeyword( keyword, PB, Lun, Coords )
char   *keyword;
PBPAR  *PB;
int     Lun;
COORDS *Coords;
{
   private void PBkeyInfo();
   private void PBkeyRead();
   private void PBkeySetPar();
   private void PBkeyCutoff();
           void PBkeyCoords();
   char         string[INSTRLEN];
   TRACE("-- PBkeyword");

   PBkeyInfo(   PB, Lun, Coords );
   PBkeyRead(   PB, string, keyword );
   PBkeySetPar( PB, string );
   PBkeyCutoff( PB );
   PBkeyCoords( PB, string, Coords );
   PB->inverse = FALSE;
}

/******************************************************************************/
/*
   Read the pbfwhm, telescop items from the header of Template.
   Read restfreq. If not found, check that axistype is FREQ and use crval3.
*/
/******************************************************************************/

private void PBkeyInfo( PB, Lun, Coords )
PBPAR  *PB;
int     Lun;
COORDS *Coords;
{
   void   GetItemA(), GetItemR();
   double ConvertToCoord();

   GetItemR( Lun, "pbfwhm",   NOAX,&PB->fwhm      ); PB->fwhm=stod(PB->fwhm);

   GetItemA( Lun, "telescop", NOAX, PB->Telescope );

   PB->LimFreq = 10.;

   GetItemR( Lun, "restfreq", NOAX,&PB->freq      );
   if( PB->freq == ZERO ) {
      assert( StrEqN(Coords->ctype[FQ_AXIS],"freq",4) |
              StrEqN(Coords->ctype[FQ_AXIS],"FREQ",4),
              "No frequency axis and no restfreq in header" );
      PB->freq = ConvertToCoord( ONE, Coords, FQ_AXIS );
   }
}

/******************************************************************************/
/*
   Read the value of the pb keyword.
   The following possibilities exist:
   - pbpar missing :    CheckKeyPresence=FALSE, stays FALSE
                        then keya() -> string<-tel
   - pbpar=tel     : a) CheckKeyPresence=FALSE, becomes TRUE
                        then keya() -> string<-tel
                     b) CheckKeyPresence=TRUE -> keyprsnt=FALSE -> bug out
   - pbpar=...     :    CheckKeyPresence=FALSE, becomes TRUE
                        then keya() -> string<-... -> repeatPB=TRUE
                        -> previousPBfwhm still -1 -> bug out
   - pbpar=tel,... : a) CheckKeyPresence=FALSE, becomes TRUE
                        then keya() -> string<-tel, set previousPB...
                     b) CheckKeyPresence=TRUE, stays TRUE
                        then keya() -> string<-... -> repeatPB=TRUE
                        previousPBfwhm!=-1 -> string<-tel
                     c) repeatPB=TRUE ->
                        previousPBfwhm!=-1 -> string<-tel
*/
/******************************************************************************/

private logical CheckKeyPresence=FALSE;
private logical repeatPB=FALSE;
private char    previousPBtype[INSTRLEN];
private double  previousPBfwhm = -1;
private char    prev_pbkey[10] = { "\0" };

private void PBkeyRead( PB, string, keyword )
PBPAR *PB;
char  *string;
char  *keyword;
{
   void           keya_c();
   logical        keyprsnt_c();
   private double PBkeyFWHM();

   if(!StrEqX(keyword,prev_pbkey)) repeatPB=FALSE; StrCpy(prev_pbkey,keyword);

   if( !repeatPB ) {
      if(  CheckKeyPresence ) assert( keyprsnt_c(keyword),
          "need primary beam parameters for each input map" );
      else CheckKeyPresence = keyprsnt_c(keyword);
      keya_c( keyword, string, "tel" );
      if( StrEqX( string, "..."     ) ) repeatPB = TRUE;
      if( StrEqX( string, "gauss"   ) |
          StrEqX( string, "airy"    ) |
          StrEqX( string, "airyc"   ) ) PB->fwhm = PBkeyFWHM( PB, keyword );
   }
   if( repeatPB ) {
      assert( previousPBfwhm != -1, "can't start %s= with ...", keyword );
      StrCpy( string, previousPBtype ); PB->fwhm = previousPBfwhm;	
   } else {
      StrCpy( previousPBtype, string ); previousPBfwhm = PB->fwhm;
   }
}

/******************************************************************************/
/*
   Read the fwhm from the pbpar keyword and interpret it.
*/
/******************************************************************************/

private double PBkeyFWHM( PB, keyword )
PBPAR   *PB;
char    *keyword;
{
   void            keyd_c();
   private logical TelescopePB();
   double          fwhm;
   TRACE("-- PBkeyFWHM");

   keyd_c( keyword, &fwhm, -ONE );
   assert( fwhm >= 0., "fwhm must be >= 0." );
   if( fwhm == 0 ) {
      if( PB->fwhm == ZERO )
      assert( TelescopePB(PB), "restfreq or telescop not in header" );
      fwhm = PB->fwhm;
   } else {
      if(      PB->freq == 0       ) {
         wwarning( TRUE, "No freq in header, assume fwhm given in arcsec" );
                                           fwhm = stod(fwhm); }
      else if( PB->freq <= PB->LimFreq ) { fwhm = mtod(fwhm); }
      else if( PB->freq >  PB->LimFreq ) { fwhm = stod(fwhm); }
   }
   return( fwhm );
}

/******************************************************************************/
/*
   Set the appropriate PB parameters.
*/
/******************************************************************************/

private void PBkeySetPar( PB, string )
PBPAR *PB;
char  *string;
{
   int             SameAsMaxen();
   private logical TelescopePB();
   private void    NoPB(), GaussPB(), AiryPB(), AiryCPB();

   if(SameAsMaxen()>0) { NoPB(PB); PB->fwhm=0.; StrCpy(PB->Telescope,""); }

   if(      StrEqX(string,"tel"    ) ) {
      if( !TelescopePB( PB ) ) {
         wwarning( TRUE, "Using gaussian primary beam with width from header" );
         assert(  PB->fwhm != ZERO, "No pbfwhm in header" );
         GaussPB( PB, PB->fwhm );
      }                                                           }
   else if( StrEqX(string,"none"   ) ) { NoPB(    PB           ); }
   else if( StrEqX(string,"gauss"  ) ) { GaussPB( PB, PB->fwhm ); }
   else if( StrEqX(string,"airy"   ) ) { AiryPB(  PB, PB->fwhm ); }
   else if( StrEqX(string,"airyc"  ) ) { AiryCPB( PB, PB->fwhm ); }
   else { assert( FALSE, "Unknown primary beam function: %s", string ); }
}

/******************************************************************************/
/*
   Change the cutoff given as the maximum correction factor into the PB->cutoff
   value.
*/
/******************************************************************************/

private double MaxCorr = -1.;
private void PBkeyCutoff( PB )
PBPAR *PB;
{
   void keyd_c();

   keyd_c( "maxcorr", &MaxCorr, MaxCorr );
   if( MaxCorr != -1. ) {
      switch( PB->pbtype ) {
      case NOPB:
      case AIRY:
      case AIRYC: wwarning(TRUE,
                  "maxcorr= keyword not allowed for given pb type, ignored");
                                                       break;
      case GAUSS:   PB->cutoff = -log( 1. / MaxCorr ); break;
      case POLY:
      case COS6:    PB->cutoff =       1. / MaxCorr;   break;
      case INVPOLY: PB->cutoff =            MaxCorr;   break;
      }
   }
}

/******************************************************************************/
/*
   Set the coordinate description values of the PB struct.
*/
/******************************************************************************/

private int pboffcount=0;

void PBkeyCoords( PB, string, Coords )
PBPAR  *PB;
char   *string;
COORDS *Coords;
{
   void   keyd_c();
   double ConvertToPixel();
   double xoff, yoff;

   pboffcount++;
   Sprintf( string, "pboff%d", pboffcount );
   keyd_c( string, &xoff, 0. );
   keyd_c( string, &yoff, 0. );

   PB->xref  = Coords->crval[RA_AXIS] + stor(xoff);
   PB->yref  = Coords->crval[DC_AXIS] + stor(yoff);
   PB->xref  = ConvertToPixel( PB->xref, Coords, RA_AXIS ) - 1.;
   PB->yref  = ConvertToPixel( PB->yref, Coords, DC_AXIS ) - 1.;
   PB->xdelt = rtod(Coords->cdelt[RA_AXIS]);
   PB->ydelt = rtod(Coords->cdelt[DC_AXIS]);
}

/*

/******************************************************************************/
/*
   Generate a string describing the primary beam
*/
/******************************************************************************/

void PBdescription( PB, string )
PBPAR *PB;
char  *string;
{
   if( PB->pbtype == NOPB ) return;

   Sprintf( string, "   Primary beam described by " );
   string += strlen(string);

   if( PB->pbtype==GAUSS )   Sprintf( string, "a gaussian" );
   if( PB->pbtype==AIRY  )   Sprintf( string, "an Airy disk" );
   if( PB->pbtype==AIRYC )   Sprintf( string, "an Airy disk" );
   if( PB->pbtype==POLY  )   Sprintf( string, "a polynomial" );
   if( PB->pbtype==INVPOLY ) Sprintf( string, "a polynomial" );
   if( PB->pbtype==COS6  )   Sprintf( string, "a cos^6 approximation" );
   string += strlen(string);

   Sprintf( string, " cut off at the " );
   string += strlen(string);

   if( PB->pbtype==GAUSS )   Sprintf( string, "%4.2f level", exp(-PB->cutoff) );
   if( PB->pbtype==AIRY  )   Sprintf( string, "edge"                          );
   if( PB->pbtype==AIRYC )   Sprintf( string, "first zero"                    );
   if( PB->pbtype==POLY  )   Sprintf( string, "%4.2f level", PB->cutoff       );
   if( PB->pbtype==INVPOLY ) Sprintf( string, "%4.2f level", ONE/PB->cutoff   );
   if( PB->pbtype==COS6  )   Sprintf( string, "%4.2f level", PB->cutoff       );
   string += strlen(string);

   Sprintf( string, "\n" );
}

/******************************************************************************/
/*
   A test function to see if the primary beam correction comes out properly.
*/
/******************************************************************************/

private logical PBTEST( PB, x,x0,x1,dx )
PBPAR  *PB;
double *x, *x0, *x1, *dx;
{
   logical keyprsnt_c();
   void    keyd_c();
   int     i;
   if( !keyprsnt_c("pbx") ) return FALSE;

   TRACE("PBTEST");
   dprintf( "fwhm " );
   if( PB->freq >= PB->LimFreq ) dprintf( "%6.2f''", dtos(PB->fwhm) );
   else                          dprintf( "%6.2f'",  dtom(PB->fwhm) );
   dprintf( " for %s; freq %5.1f; #%d\n",
             PB->Telescope, PB->freq, PB->freqnum );
   dprintf( "PBtype %d; cutoff %f\n", PB->pbtype, PB->cutoff );
   dprintf( "GaussFac or AiryFac %f\n", PB->coeff[1] );
   dprintf( "order %d -- ", (int)PB->coeff[0] );
             for(i=0;i<=PB->coeff[0];i++) dprintf( "%g  ", PB->coeff[i+1] );
   dprintf( "\n" );

   keyd_c( "pbx", x0, 0.0 ); *x = *x0;
   keyd_c( "pbx", x1, 1.2 );
   keyd_c( "pbx", dx, 0.1 );

   return TRUE;
}

/*

/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*    <<< Primary Beam Calculation >>>                 127 +   78 =  205 USERIO
/******************************************************************************/
/*
   Return the primary beam attenuation at the radius r (in degrees) as given by
   the description PB.

   On serial machines, some testing statements are included. Normally TestMode
   is FALSE, and the while loop is executed only once. If the pbx= keyword was
   given, testing is done. Then PBshape is made to point to a special shape of
   size 1.

   Some copying of PBPAR struct elements to local variables is done in order
   to make PCA parallelize code on SGI machines.
*/
/******************************************************************************/

void OperCount();
#define CINIT 0
#define OpCnt(npl,nps,nm,na,nd) OperCount(CINIT,PBshape,0,npl,nps,nm,na,nd)

#ifdef __CSTAR__
#define pb   pPrB
#define R2   pPrB
#define tmp  pPrB
#else
#define pb   (pPrB+MemPixNum)
#define R2   (pPrB+MemPixNum)
#define tmp  (pPrB+MemPixNum)
#endif

extern double_current polynomial();
extern double_current airy();
#ifdef mips
#pragma no side effects (polynomial)
#pragma no side effects (airy)
#endif

void CalculatePB( PB, pPrB, PBshape )
PBPAR     *PB;
Real_void *pPrB;
shape     *PBshape;
{
   Real    cutoff = PB->cutoff;
   Real    GAcoeff; int order; double PolyCoeff[NPOLYCOEFF];
   double  xref = PB->xref;
   double  yref = PB->yref;
   double  xdelt2 = square(PB->xdelt);
   double  ydelt2 = square(PB->ydelt);
   double  Q=ZERO; int n=0;

   logical TestMode;
   private logical PBTEST();
   void    Abort();
   double  x, x0, x1, dx, r=ZERO;
#ifndef __CSTAR__
   shape   PBtestshape; PBtestshape.start=0; PBtestshape.end=1;
                        PBtestshape.xlen=PBshape->xlen;
   TestMode = PBTEST( PB, &x, &x0, &x1, &dx );
   if(TestMode) PBshape = &PBtestshape;
#else
   TestMode = FALSE;
#endif
   TRACE("CalculatePB");
   order   = (int)PB->coeff[0];
   GAcoeff = PB->coeff[1];
   for( n=1; n<NPOLYCOEFF; n++ ) PolyCoeff[n-1] = PB->coeff[n];

   do { MemPixNum=0;

   if(TestMode) { r=x*PB->fwhm; *R2=r*r; }
   else {
      with(*PBshape) {
         *R2  = square(pcoord_x-xref)*xdelt2 + square(pcoord_y-yref)*ydelt2;
      } OpCnt(1,0,14,7,4);
   }

   switch( PB->pbtype ) {
   case NOPB:
      with(*PBshape) {
         *pb  = ONE;
      } OpCnt(1,0, 0, 0,0);
      break;
   case GAUSS:
      with(*PBshape) {
         *tmp = *R2 * GAcoeff;
         *pb  = *tmp < cutoff ? exp(-(*tmp)) : ZERO;
         where( *pb != 0 ) { Q+=square(*pb); n+=(int_current)1; }
      } OpCnt(4,6, 4, 5+80,0); /* 80=exp */
      break;
   case AIRY: case AIRYC:
      with(*PBshape) {
         *tmp = sqrt(*R2) * GAcoeff;
         *pb  = *tmp < cutoff ? airy(tmp) : ZERO;
         where( *pb != 0 ) { Q+=square(*pb); n+=(int_current)1; }
      } OpCnt(4,5, 4+16, 6+17, 0+2); /* 16,17,2=airy */
      break;
   case POLY:
      with(*PBshape) {
         *tmp = polynomial( order, PolyCoeff, R2 );
         *pb  = *tmp > cutoff ? *tmp : ZERO;
         where( *pb != 0 ) { Q+=square(*pb); n+=(int_current)1; }
      } OpCnt(4,6, 3+21, 5+16, 0); /* 21+16+0=poly,order4 */
      break;
   case INVPOLY:
      with(*PBshape) {
         *tmp = polynomial( order, PolyCoeff, R2 );
         *pb  = *tmp < cutoff ? ONE/(*tmp) : ZERO;
         where( *pb != 0 ) { Q+=square(*pb); n+=(int_current)1; }
      } OpCnt(4,6, 3+21, 5+16, 1+0); /* 21+16+0=poly,order4 */
      break;
   case COS6:
      with(*PBshape){
         *tmp = cos( GAcoeff * sqrt(*R2) );
         *tmp *= *tmp; *tmp *= *tmp * *tmp;
         *pb  = *tmp > cutoff ? *tmp : ZERO;
         where( *pb != 0 ) { Q+=square(*pb); n+=(int_current)1; }
      } OpCnt(6,10, 4, 10+15, 0); /* 15=cos */
      break;
   }
   if(TestMode) {dprintf("r=%13.11f fwhm (%13.11fd %6.2f' %6.2f'') PBC=%8.6f\n",
                          x,        r,           dtom(r),dtos(r), *pPrB      );
      x+=dx; }
   } while( TestMode && x<x1 ); if(TestMode)Abort();

#ifndef __CSTAR__
{
   int minx, miny, maxx, maxy, count;
   minx=PBshape->xlen; miny=PBshape->ylen; maxx=maxy=count=0;
   with(*PBshape) { where( *pb != 0 ) {
      assmin(minx,pcoord_x); assmax(maxx,pcoord_x);
      assmin(miny,pcoord_y); assmax(maxy,pcoord_y); count++;
   }} OpCnt(4,1, 16,4, 2);
   PBshape->start = miny * PBshape->xlen + minx;
   PBshape->end   = maxy * PBshape->xlen + maxx + 1;
   PBshape->nsel  = count;
}
#endif

   if(PB->inverse) {
      with( *PBshape ) { where(*pb!=0) {
         *pb = ONE/(*pb);
      }} OpCnt(1,2, 0, 1,1);
   }

   PB->Q   = sqrt( sqrt((double)n) * Q );
   PB->npb = n;
}
#undef pb
#undef R2
#undef tmp
