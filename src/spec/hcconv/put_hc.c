/*
 *  put_hc -- put a Hat Creek variable into Mirth format
 *
 *	Currently this version does not scale with or accept data
 *	from future configurations of Hat Creek; ie, nant not 3, etc.
 *
 *	xx-sep-89	Created 		Brian Sutin 
 *	25-sep-89	added <ctype.h>		PJT
 *       8-dec-89       fixed systemp bug       PJT & LGM
 *	13-dec-89 	fixed antpos bug	PJT
 *	13-may-90 	renamed deltara->dra etc	PJT
 *	30-jul-90 	plmaj/plmin from radians to arcsec	PJT
 *	29-aug-90	forgot a break; statement	PJT
 *	25-jan-91       npols->npol, evector, pbfwhm, 
 *	 5-feb-91       fixed type of pbfwhm PJT
 *	29-jul-91	always write MIN(newlen,length) for array variables
 *			where RALINT screwed up
 *
 *
 */

#include <stdio.h>
#include <ctype.h>

#define PI	3.14159265358979
#define UNKNOWN	-1

struct {
    char *name ;
    char type ;
    char size ;
    } oldvar[] = {	/* hc_var.h is created by vlist & vlist.awk */
#include "hc_var.h"
	} ;

int find() ;
char *lower() ;

extern int hcconv_debug;
extern int warnings;

/*
 *  variables on which other variables' lengths depend are:
 *
 *	nants	-- b1, b2, b3, systemp, tpower, temp, focus, phase[m1,lo1,lo2]
 *	nchan	-- corr, acorr
 *	npol	-- corr, pol
 *	nspect	-- ischan, nschan, sfreq, sdf, restfreq, systemp
 *	ntemp	-- temp
 *	ntpower	-- tpower
 *	nwide	-- wcorr, wfreq, wwidth
 *
 */

int v_nants	=  3 ;		/* three antennas */
int v_npol	=  1 ;		/* one polarization */
int a_pol       =  1 ;          /* array pol (lenght 1 !!!)  */
int v_nwide	=  4 ;		/* (LSB,USB) * (TWIDE,AWIDE) MAY CHANGE??? */
int v_ntemp	=  8 ;		/* 8 thermisters */
int v_ntpower	=  1 ;		/* one total power measurement */
int v_npoint    =  1 ;          /* one pointing center */
int v_nchan	= -1 ;		/* given as NUMCHAN */
int v_nspect	= -1 ;		/* given as NSPECT */

float v_evector = 0.0;          /* polarization angle == for now 0.0 */
float v_cortaper = 1.0;         /* in agreement with UVHAT */

int ischan_save[100] ;		/* for systemp calculation */
float wsystemp[12];		/* (nants,nwide) is correct dimension */
int cormode, coropt ;

int nschan[8];
double sdf[8];
float wide, pbfwhm;
int Qhead = 0;
int sdf_done, nschan_done;  /* to make sure wwidth is done properly */

put_hc( type, name, data, length )
int length ;
char *name, *data, type ;
{
    int i, var, na, ns, sampler, newlen , j, jj;
    static float temp[9*10], temp2[9*10] ;	/* MAXANTS * MAXTEMPS */
    static double tempd[9*3];                   /* MAXANTS * 3 (3d=x,y,z) */
    float  antdiam[3];
    int *INT ;
    float *REAL ;
    double *DBLE ;

    INT = (int *) data ;		/* make it point to data */
    REAL = (float *) data ;		/* make it point to data */
    DBLE = (double *) data ;		/* make it point to data */

    if( !Qhead ) {       /* if no header had been written, write it */
       uvput( 'I' , "nants"	, (char *) &v_nants,	1 ) ;
       uvput( 'I' , "nwide"    , (char *) &v_nwide,    1 ) ;
       uvput( 'I' , "ntemp"    , (char *) &v_ntemp,    1 ) ;
       uvput( 'I' , "ntpower"  , (char *) &v_ntpower,  1 ) ; /* not in UVHAT*/
       uvput( 'I' , "npol"     , (char *) &v_npol,     1 ) ;
       uvput( 'I' , "pol"      , (char *) &a_pol,  v_npol) ;
       uvput( 'I' , "npoint"   , (char *) &v_npoint,   1 ) ; /* not in UVHAT*/
       uvput( 'R' , "evector"  , (char *) &v_evector,  1 ) ;
       uvput( 'R' , "cortaper" , (char *) &v_cortaper, 1 ) ;
       uvput( 'A' , "version"  , (char *) "newhat",    6 ) ; /* as in UVHAT */
       uvput( 'A' , "telescop" , (char *) "HATCREEK",  8 ) ; /* as in UVHAT */
       uvput( 'A' , "obsline"  , (char *) "unknown",   7 ) ; /* as in UVHAT */
       uvput( 'A' , "operator" , (char *) "unknown",   7 ) ; /* as in UVHAT */
       for (i=0; i<v_nants; i++) {
           antdiam[i] = 6.0;           /* Hat Creek: 6m dishes */
       }
/*     uvput( 'R' , "antdiam" , (char *) antdiam,      v_nants);       */
       Qhead = 1;      /* flag that primary header has been written */
       sdf_done = nschan_done = 0;     /* reset flags for writing wwidth */
    }

    var = find(name) ;
    if( type != oldvar[var].type ) {
	if (hcconv_debug >= 0) {
	   (void) fprintf( stderr, "%s has inconsistent type: %c -> %c\n",
	    name, type, oldvar[var].type ) ;
	}
        warnings++;
    }
    switch( oldvar[var].size ) {
	case 'A': newlen = v_nants ;	/* what about shadowing here ??? */
                  break;
	case 'S': newlen = v_nspect ;
                  break;
	default:  newlen = oldvar[var].size - '0' ;
                  break;
    }
    if( length != newlen ) {
	if (hcconv_debug>=0) {
	   fprintf(stderr, "RALINT/UV variable %s(%d) expected, %d found, ",
	       name, newlen, length);
	}
	if (length>newlen)length=newlen;	/* find minimum !!! */
	if (hcconv_debug>=0) {
	   fprintf(stderr, "will write %d elements!\n",length);
	}
        warnings++;
    }

    switch(var) {

/*  			Catch a mistake? */
    case UNKNOWN: 
            if (hcconv_debug>=0) {
                fprintf( stderr, "UNKNOWN: %s\n", name ) ;
            }
            warnings++;
	    uvput( type, lower(name), data, length ) ;
            break;
/* 			The following variables don't change at all */
/*			only their name is now in lower case	    */
    case AIRTEMP:
    case ATTEN:
    case AXISNUM:
    case AXISAVE:
    case AXISRMS:
    case CORBIT:
    case DDEC:
    case DEWPOINT:
    case DRA:
    case FREQ:
    case INTTIME:
    case IVALUED:
    case PHASELO1:
    case PHASELO2:
    case PLANGLE:
    case PLTB:
    case PRECIPMM:
    case RELHUMID:
    case WINDMPH:
    case RESTFREQ:
	    uvput( type, lower(name), data, length ) ;
	    break;
/*                      Planet sizes from radians to arcseconds */
    case PLMAJ:
    case PLMIN:
            REAL[0] /= 4.848136811e-06;
            uvput( type, lower(name), data, length ) ;
            break;
    case NSCHAN:
            for (i=0; i<8; i++)      /* CHECK if 8 is OK */
               nschan[i] = INT[i];
	    uvput( type, lower(name), data, length ) ;
            nschan_done = 1;
            break;
    case ISCHAN:
	    for( i = 0 ; i < v_nspect ; i++ )
		ischan_save[i] = INT[i] ;
	    uvput( type, lower(name), data, length ) ;
            break;
    case NSPECT:
	    v_nspect = INT[0] ;
	    uvput( type, lower(name), data, length ) ;
            break;
/*                      The following variables change name and/or value */
    case DEC:		uvput( type, "obsdec" , data, length ) ;
                        break;
    case DEC1950:	uvput( type, "dec"    , data, length ) ;
                        break;
    case ICMODE:	uvput( type, "cormode", data, length ) ;
	                cormode = INT[0] ;
                        break;
    case ICOPTION:	uvput( type, "coropt" , data, length ) ;
	                coropt = INT[0] ;
                        break;
    case LO:		uvput( type, "lo1"    , data, length ) ;
			pbfwhm = 11040.0/DBLE[0];
			REAL[0] = pbfwhm;
			uvput( 'R', "pbfwhm", data, length ) ;
                        break;
    case RA:		uvput( type, "obsra"  , data, length ) ;
                        break;
    case RA1950:	uvput( type, "ra"     , data, length ) ;
                        break;
    case NUMCHAN:	uvput( type, "nchan"  , data, length ) ;
	                v_nchan = INT[0] ;
                        break;
    case VELDOP:	uvput( type, "veldop" , data, length ) ;
                        break;
    case VELOC:		uvput( type, "vsource", data, length ) ;
                        break;
    case TPWR:		uvput( type, "tpower", data, length ) ;   
                        break;
    case VSUBIO:	uvput( type, "focus", data, length ) ;    
                        break;

/* these variables change data type or units or more complex */

    case DELTARA:                               /* second to radians */
        REAL[0] *= 4.848136811e-06;
        uvput(type,"dra",data,length);		/* name change */
        break;                        
    case DELTADEC:                              /* second to radians */
        REAL[0] *= 4.848136811e-06;
        uvput(type,"ddec",data,length);		/* name change */
        break;                        
    case CORBW:					/* MHz ---> GHz */
	REAL[0] *= 0.001 ; REAL[1] *= 0.001 ;
	uvput( type, lower(name), data, length ) ;
        break;                        
    case CORFIN:				/* MHz ---> GHz */
	REAL[0] *= 0.001 ; REAL[1] *= 0.001 ;
	REAL[2] *= 0.001 ; REAL[3] *= 0.001 ;
	uvput( type, lower(name), data, length ) ;
        break;                        
    case FREQIF:				/* real ---> double */
	DBLE[0] = REAL[0] ;
	uvput( 'D', lower(name), data, length ) ;
        break;                        
    case LO2:					/* real ---> double */
	DBLE[0] = REAL[0] ;			/* (currently 1.23 GHz) */
	uvput( 'D', lower(name), data, length ) ;
        break;                        
    case SDF:					/* real ---> double */
	for( i = length-1 ; i >= 0 ; i-- ) {
	    DBLE[i] = REAL[i] ;
            sdf[i] = DBLE[i];
        }
	uvput( 'D', lower(name), data, length ) ;
	sdf_done = 1;
        break;                        
    case SFREQ:					/* real ---> double */
	for( i = length-1 ; i >= 0 ; i-- )
	    DBLE[i] = REAL[i] ;
	uvput( 'D', lower(name), data, length ) ;
        break;                        
    case PHASEM1:				/* turns ---> radians */
	for( i = 0 ; i < length ; i++ )
	    REAL[i] *= 2 * PI ;
	uvput( type, lower(name), data, length ) ;
        break;                        
    case SOURCE:				/* ---> variable length */
    case WINDDIR:
	for( i = 0 ; (i < length) && (data[i] != ' ') ; i++ ) ;
	data[i] = '\0' ;
	uvput( type, lower(name), data, strlen(data) ) ;
        break;                        
/* these variables change name and format */
    case EPHFLAG:			/* always currently "RL" */
	REAL[0] = 1950.0 ;
	uvput( 'R', "epoch" , data, 1 ) ;
	uvput( 'A', "veltype", "VELO-LSR", 8 ) ;
        break;                        
    case WFREQ:				/* value for TWIDE */
	REAL[2] = REAL[0] ;		/* kludge! guess for AWIDE */
	REAL[3] = REAL[1] ;
	for( i = 4 ; i < v_nwide ; i++ )
	    REAL[i] = 0.0 ;
	uvput( type, lower(name), data, v_nwide ) ;

        break;                        
/* these variables doesn't exist in the new format */
    case DELAY0:
        break;

/* The following variables are identical except that several HC variables
   are combined into fewer MIRTH variables. */

/* WARNING these may change format */
    case B1:
    case B2:
    case B3:
	for( i = 0 ; i < v_nants ; i++ )
	    tempd[ v_nants * (var - B1) + i ] = DBLE[i] ;
	if( var == B3 ) /* when B3 comes about, assume B1, B2 have passed */
	    uvput( type, "antpos", (char *) tempd, v_nants * 3 ) ;
        break;                        
    case SYSTEMP1:
    case SYSTEMP2:
    case SYSTEMP3:
    case SYSTEMP4:
    case SYSTEMP5:
    case SYSTEMP6:
    case SYSTEMP7:
    case SYSTEMP8:
	for( i = 0 ; i < v_nants ; i++ )
	    temp[ v_nants * (var - SYSTEMP1) + i ] = REAL[i] ;
	if( var == SYSTEMP8 ) {			/* SYSTEMP8 always here? */
            if (hcconv_debug>0) {
              printf("DEBUG: systemps= nspect=%d nant=%d\n",v_nspect,v_nants);
              for (ns= 0; ns < v_nspect; ns++)
                for (na=0; na<v_nants; na++)
                    printf(" %g",temp[ns*v_nants+na]);
              printf("\n");
            }
	    for( ns = 0 ; ns < v_nspect ; ns++ ) {
		sampler = qsam( cormode, coropt, ischan_save[ns] ) ;
		for( na = 0 ; na < v_nants ; na++ )
		    REAL[ v_nants * ns + na ] = temp[ v_nants * sampler + na ] ;
            }
	    uvput( type, "systemp", (char *) data, v_nants * v_nspect ) ;

	    for (jj=0;jj<v_nants;jj++)
               for(j=0;j<v_nwide;j++)
                  wsystemp[j*v_nants+jj] = REAL[jj];
            uvput( type, "wsystemp", (char *) wsystemp, v_nants * v_nwide ) ;
        } /* if */
        break;                        

    case TEMPS1:
    case TEMPS2:
    case TEMPS3:
    case TEMPS4:
    case TEMPS5:
    case TEMPS6:
    case TEMPS7:
    case TEMPS8:
	for( i = 0 ; i < v_nants ; i++ )
	    temp[ v_nants * (var - TEMPS1) + i ] = REAL[i] ;
	if( var == TEMPS8 )
	    uvput( type, "temp", (char *) temp, v_nants * v_ntemp ) ;
	break;
    default:				/* how did we get here? */
        if (hcconv_debug>=0) {
	    fprintf( stderr, "default %d: %s\n", var, name ) ;	
        }
        warnings++;
        break;
    }  /* switch */


    /* Delayed actions == this may screw up if files are appended (Qrec) */

    if (sdf_done && nschan_done) {
        /* with CHECK if sdf and nschan has been done */
	width_(&v_nspect, sdf, nschan, &wide);	/* Call fortran routine */
        REAL[0] = wide;   REAL[1] = wide;
	REAL[2] = 0.28 ; REAL[3] = 0.28 ;		/* for AWIDE */
	uvput( 'R', "wwidth" , data, v_nwide ) ;
        sdf_done = nschan_done = 0;             /* and reset */
    }
} /* put_hc */

/* find the old variable in the list */
/* binary hack search */

int find( string )
char *string ;
{
    int lo, hi, new, cmp ;

    lo = -1 ;
    hi = MAXVAR ;
    while( lo + 1 < hi ) {
	new = (lo + hi) / 2 ;
	cmp = strcmp( string, oldvar[new].name ) ;
	if( cmp > 0 )
	    lo = new ;
	else
	if( cmp < 0 )
	    hi = new ;
	else
	    return new ;
	}
    return UNKNOWN ;
    }

/* convert to lower case and nuke spaces */

char *lower( string )
char *string ;
{
    int i ;
    static char buff[9] ;

    for( i = 0 ; i < 8 ; i++ ) {
	if( string[i] == ' ' )
	    break ;
	else
	if( isupper( string[i] ) )
	    buff[i] = tolower( string[i] ) ;
	else
	    buff[i] = string[i] ;
	}
    buff[i] = '\0' ;
    return buff ;
    }

int qsam( mode, opt, chan )
int mode, opt, chan ;
{
    int i, seg ;

    chan-- ;					/* start at zero */

    if( opt )					/* correlation */
	seg = 64 ;
    else {					/* autocorrelation */
	seg = 32 ;
	chan %= 256 ;
	}

    i = chan / seg ;

    switch(mode) {
	case 0: return 0 ;			/* 0 0 0 0 0 0 0 0 */
	case 1: return 1 ;			/* 1 1 1 1 1 1 1 1 */
	case 2: return 3*(i/4) ;		/* 0 0 0 0 3 3 3 3 */
	case 3: return 2*(i/2) + (i/4) ;	/* 0 0 2 2 5 5 7 7 */
	case 4: return i ;			/* 0 1 2 3 4 5 6 7 */
	}
    return -1 ;
    }
