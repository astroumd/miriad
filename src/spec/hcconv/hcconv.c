#define VERSION_ID "V4.5 6-mar-92"
/**************************************************************************
 *
 *  hcconv -- convert Hat Creek format to MIRIAD format
 *
 *	This program is the Unix equivalent of UVHAT, it assumes
 *	IEEE format for float's and twos-complement for int's
 *
 **************************************************************************/

/*= hcconv - Convert Hat Creek uv format into MIRIAD uv format    */
/*& pjt                                                           */
/*: data transfer                                                 */
/*+     Converts Hat Creek (RALINT) data on a UNIX system to MIRIAD format.
        The RALINT data are usually obtained by exploding a 
        backup saveset. Giving no arguments at all will turn program
        in auto scanning mode...                                  
        As said, HCCONV only runs on SUN Unix (not CRAY); on VMS
        use the program UVHAT.
        HCCONV will also repair any obvious synchronization problems
        that occasionally occur when the VMS Day80 changes, this will
        be announced, and you should not worry about it.
        HCCONV will also complain when RALINT variables have an 
        inconsistent array length. It will then write the minimum
        length appropriate. This can happen when RALINT has written
        one sideband only, or in the case of shadowing.
/*@ in
        The Hat Creek data file(s). In no input given, it autoscans
        for files of the form '*.ddmmm'. Formally in UNIX wildcard
	notation: *.[0-9][0-9][a-z][a-z][a-z] Default: empty.     */
/*@ out
        Name of the MIRIAD dataset to be created. If no name provided
        hcconv chooses a name. See the ``mode'' keyword for how this 
        can be done. If multiple input files, and one output file,
        the input files are merged into one output file. Make sure the
        type of the input files (auto/cross correlation) are all the 
        same.
        Default: empty, meaning auto-filename generation.         */
/*@ mode
        Option denoting how the output filename is formed from the
        input filename. Options are: ``underscore'' (replaces the dot
        by an underscore), ``strip'' (strips name from the dot onwards).
        Default: ``underscore''                                   */
/*@ debug
        Debug level - note: lots of output appears. It is better to
        redirect output to a logfile for this, or use it in a
        pipe to ``grep'' or ``more''. The higher the debug level, the 
	more output may appear. Default: 0                        */
/*--*/
/*
 *	Originally written: Brian Sutin, September 24, 1989
 *
 *	25-sep-89	Continuing the saga....	Peter Teuben
 *	 8-nov-89	standard keywords		    PJT
 *	10-nov-89	fixed bugs - added autoscan	    PJT
 *	 5-dec-89	2.1 added ATTEN keyword		    PJT
 *	13-dec-89	antpos fixed in put_hc()	    PJT
 *	30-jan-90	fixed Julian Day calculation        PJT
 *	 6-feb-90	2.3 extra time-jump check + repair  PJT
 *	 9-apr-90	2.4 fix, verbose parameter          PJT
 *			skip log, biglog, cbee, notes...
 *	11-may-90	2.5: deltara -> dra, deltadec-ddec 
 *			     (see puty_hc.c) 		    PJT
 *	12-jun-90	2.7: fixed march bug (mrt->mar) silly dutch  PTJ 
 *	xx-jun-90       2.8  attempt to use mkeyf()	    PJT
 *	14-jul-90	3.0: Also flip phases/UV if ant1>ant2   PJT+LGM
 *		<< THIS WAS A MAJOR BAD DIFFERENCE BETWEEN 
 *		<< UVHAT AND HCCONV - someone should either merge
 *		<< the two programs or carefully compare the actions
 *		<< of both these programs.
 *   19-jul-90   pjt   - extra security in fread() for early EOF detection
 *			 in vmsget.c
 *	30-jul-90	pjt  forced all wflags=TRUE, corrected units
 *			     of plmaj/plmin
 *	20-aug-90	pjt+alr  Terrible Bug in put_hc - put extraneous stuff
 *				 in visibility file....in funny units
 *	29-aug-90	pjt  forgot a break; in put_hc, not fatal
 *	17-oct-90	pjt  included inline doc (bpw?)
 *	14-nov-90	pjt  autodetect ascii files...
 *	16-dec-90	pjt  fixed julian day 1-day-too-much bug
 *	18-dec-90 3.5a       added 'baseline*' to list of auto-skip files
 *      18-jan-91 4.0   pjt  write wcorr using uvwwrite
 *	25-jan-90 4.1   pjt  obstype handled differently, evector, npol, pbfwhm
 *			     if no channels, write no flags...
 *                           use uvset() when number of narrow channels 0
 *	 2-feb-90       pjt  cross/autocorellation via 'obstype'
 *			     fixed very old correct[i] indexing bug
 *	 5-feb-91 4.2	pjt  fixed type of pbfwhm to real, not double!!!
 *			     and so many other small things to make UVHAT
 *                           and HCCONV produce more equal data files.
 *	 4-apr-91	pjt  added IVALUED to possible uv variable
 *	 8-apr-91	pjt  increased MAXFILES
 *       3-may-91       pjt  Amazing: it never did autocorr correct!!! 
 *	16-may-91	pjt  added antdiam uv-variable
 *      28-may-91 4.3b  pjt  formally added debug= as 0,1 keyword before
 *                           hcconv becomes totally obsolete.
 *      29-jul-91 4.4   pjt  write smallest length of array variables (put_hc)
 *			     more history and wrote HATopen()
 *                4.4a  pjt  some new ifdef's for __convex__
 *			     returned the *baseline* files to normal status
 *      18-nov-91    c  pjt  caught another midnight daemon bug in Day80
 *       3-mar-92    d  pjt  some old day80 -> jd conversion was wrong (leapyear)
 *			     and day80 is 1 based, not 0 based.
 *       6-mar-92  4.5  pjt  formal version with correct JD
 *
 * Known Bugs and deficiencies:
 *
 *	Works only on BSD UNIX because of hardcoded f_to_c interface
 *	Number of AWIDE channels is fixed at 1
 *	*** Number of correlator channels is fixed at 0 or 512 *** "fixed"???
 *	Does not deal with unexpected variables elegantly
 *	Reads multiple input files, but does not time order.
 *
 *      [I NOW CONSIDER MERGING THEM DANGEROUS - PJT]
 *
 *  Check:   does shadowing still work??? since array lenght now shorter...
 */

#include <stdio.h>
#include "vmsget.h"

#define NCHAR	128

char *malloc() ;

static void error() ;

#if defined(__convex__)
# define FORT_TRUE (-1)
#else
# define FORT_TRUE 1
#endif
/*************************************************************************
 *
 *  records are either data or header.  The main program is just a
 *  dispatcher for the correct reader.  The first character in the
 *  record signals which type of record to read.  Letters are header
 *  and numbers are data.
 */

#define MAXFILES	256
#define MAXHIST         256

int nf ;
char *files[MAXFILES]; 		          /* all input files */
/*char files[MAXFILES][NCHAR];            /* all input files for MKEYF */

int HANDLE ;
extern FILE *VMSin ;                    /* see: vmsget.c */

int xargc ;				/* fortran-C kludge */
char **xargv ;                          /* for command line args */

int hcconv_debug = 0;
int warnings=0;                         /* count how many warnings */
extern int Qhead;			/* make sure UV 'header' is written */
int Qobstype = 0;			/* make sure obstype item is written */
int totcount = 0;			/* keep track how many bytes read */

int counter=0;                          /* counting records */
int count_wide=0;
int count_narrow=0;
double lasttime;                        /* saved last time */
char fix[NCHAR];                        /* string if fix is needed */
char *my_history[MAXHIST];                 /* pointer to strings of history */
int nhist=0;                            /* current active number of history */



main(argc, argv)
int argc ;
char *argv[] ;
{
    int i , Qrec, max_nf, fnmode;
    char type, dataset[NCHAR], temp[NCHAR] , verbose , namemode[NCHAR];
    char mesg[NCHAR];
    FILE *HATopen();

    setbuf(stdout, 0);           /* No buffering on output */
    setbuf(stderr, 0);

/*  Read arguments */

    xargc = argc ;
    xargv = argv ;

    printf("%s: %s\n",argv[0],VERSION_ID);

/*----------------------------------------------------------------------------*/
    keyini_() ;         /* call BSD fortran */

    keya_( "out", dataset, "", 3, NCHAR-1, 0 );
    for( i = 0 ; i < NCHAR ; i++ ) {
	if( dataset[i] == ' ' ) {
	    dataset[i] = '\0';
            break;
        }
    }
    keya_("mode", namemode, "under", 4, NCHAR-1, 5);
    if (namemode[0] == 'u')         
        fnmode=0;                   /* underscore: replace . by _ */
    else if (namemode[0] == 's')
        fnmode=1;                   /* strip from . onwards */
    else {
        printf("Illegal mode %s, mode=underscore assumed\n",namemode);
        fnmode=0;
    }
#if 1
    /* old technique: keya and do our own processing */
    for( nf = 0 ; nf < MAXFILES ; nf++ ) {
	files[nf] = malloc( NCHAR ) ;
	keya_( "in", files[nf], "", 2, NCHAR-1, 0 ) ;   /* call BSD fortran */
	for( i = 0 ; i < NCHAR ; i++ ) {
	    if( (files[nf])[i] == ' ' ) {
		(files[nf])[i] = '\0' ;
                break;
            }
        }
	if( strlen( files[nf] ) == 0 ) {
	    free( files[nf] ) ;
	    break ;
	}
    }
#else
    max_nf = MAXFILES;		/* Not sure if this works already */
    mkeyf_("in",files,&max_nf,&nf,2,NCHAR);
#endif
    if( nf == MAXFILES )
	error( "too many input files" ) ;
    if (nf == 0) {
        printf("Attempting to find all local Hat Creek files ");
	printf("of the form *.ddmmm   ... \n");
        nf = gethcfiles(files, MAXFILES);
    }

    if (strlen(dataset)==0)
	Qrec = 1;	/* set silly flag , multiple outfile */
    else
	Qrec = 0;
#if 0
    keya_( "fix", fix, "", 3, NCHAR-1, 0 ) ;    /* call BSD fortran */
    if (fix[0] != ' ') {
        printf("Warning: fix=%s used\n",fix);
    }
#endif
    keyi_("debug", &hcconv_debug, &hcconv_debug, 5);
    if (hcconv_debug)
        printf("Note: Set debug level=%d\n",hcconv_debug);

    keyfin_() ;     /* finish up with keywords - call BSD fortran */
/*----------------------------------------------------------------------------*/

    if (!Qrec) {    /* open ONE dataset for output before we enter loop */
    	uvopen_c( &HANDLE, dataset, "new" ) ;
        if (nf>1) {
            printf("### Warning: Appending all input files to %s\n",dataset);
            printf("###  Be sure to convert associated files\n");
            printf("###  No guarantee that all UV vars are properly tracked\n");
        }
    }

    for( i = 0 ; i < nf ; i++ ) {                  /* loop over all in files */
        if (Qrec) {                                 /* multiple output files */
            strcpy(dataset,files[i]);
            if (fnmode==0) 
                dataset[strlen(dataset)-6] = '_';        /* replace . with _ */
            else if (fnmode==1)
                dataset[strlen(dataset)-6] = '\0';  /* terminate string at . */
            else
                dataset[strlen(dataset)-6] = '_'; /* default underscore mode */
            VMSin = fopen( dataset, "r");         /* open for existence test */
            if (VMSin) {
                printf("%-20s: dataset %s already exists, skip processing.\n",
                        files[i],dataset);
                fclose(VMSin);
                continue;
            } else {
                uvopen_c( &HANDLE, dataset, "new");
		Qhead = 0;    /* reset, to make sure extra header is written */
		Qobstype = 0; /* reset, make sure obstype is set too */
            }
        }
	sprintf(mesg,"%-20s:  %s to miriad format in %s", 
            files[i], Qrec ? "converting" : "appending", dataset) ;
        printf("%s\n",mesg);
	VMSin = HATopen(files[i]) ;  /* open input file; and check for HAT */
	if( !VMSin ) continue;
        myaddhist(mesg);
	counter = 0;			             /* reset record counter */
	totcount = 0;				       /* reset byte counter */
	while( VMSget( 1, &type ), VMSin ) {
	    VMSunget(type) ;			      /* need this character */
	    if( (type >= 'A') && (type <= 'Z') )
		header() ;				/* variables */
	    else
	    if( (type >= '0') && (type <= '9') )
		data() ;				/* correlations */
	    else {
		error( "unknown record label" ) ;
                break;
            }
	} /* while */
        sprintf(mesg," Read %d bytes; %d wide and %d narrow time records",
            totcount,count_wide, count_narrow);
        printf("%s\n",mesg);
        myaddhist(mesg);
        if (Qrec) 
	    myuvclose(HANDLE);
    } /* for */
    if (!Qrec)
        myuvclose(HANDLE);
    stop(0);
} /* main */

/*
 *   myuvclose:   close file, but append some history
 */

myuvclose( tno)
int tno;
{
    char msg[NCHAR];
    int i;

    hisopen_(&tno,"append",6);              /* first add history */
    sprintf(msg,"HCCONV: Version %s",VERSION_ID);
    hiswrite_(&tno,msg,strlen(msg));        /* version & date */
    hisinput_(&tno,"HCCONV",6);             /* command line */
    for (i=0; i<nhist; i++) {               /* add accumulated history */
        hiswrite_(&tno,my_history[i],strlen(my_history[i]));
        free(my_history[i]);
    }
    hisclose_(&tno);
    nhist=0;                                /* reset history counter */

    count_wide = 0;                         /* reset record counters */
    count_narrow = 0;

    uvclose_c(tno);                         /* and finally close */
}

/* 
 *  myaddhist:  buffer comments for history, to be flushed when myuvclose
 *              is called 
 */
myaddhist(mesg)
char *mesg;
{
    char line[NCHAR], *cp, *malloc();

    sprintf(line,"HCCONV: %s",mesg);
    cp = malloc(strlen(line)+1);
    if (cp==NULL) {
        printf("### Warning: Could not allocate space for history\n");
        return ;
    }
    if (nhist>=MAXHIST) {
        printf("### Warning: No more space to write history. Increase MAXHIST\n");
        return ;
    }
    strcpy(cp,line);
    my_history[nhist++] = cp;
}

/**************************************************************************
 *  header -- reads the header variables
 */

#define MAX	256			/* MAX -- longest possible array */

header()
{
    char c ;
    char type ;					/* variable type */
    char name[9] ;				/* variable name */
    unsigned char count ;
    static char data[8*MAX] ;			/* data buffer */
    static char   *CHAR = (char *) data ;
    static int    *INTG = (int *) data ;
    static float  *REAL = (float *) data ;
    static double *DBLE = (double *) data ;
    int spot, length ;

    for(;;) {

	VMSget( 1, &type ) ;
	if( type == 'X' ) {		/* end of header */
	    VMSend() ;
	    return ;
	}

	VMSget( 8, name ) ;		/* variable name */
	name[8] = '\0' ;
	length = 0 ;
	for( c = '"' ; c == '"' ; VMSget( 1, &c ) ) {
	    VMSget( 1, (char *) &count ) ;
	    spot = count - 1 ;
	    length++ ;
	    if( count > length ) {
                if (hcconv_debug>=0) {
		    fprintf( stderr,
	          "Warning: missing values in header variable: %s ", name ) ;
		    fprintf( stderr,
		  "         expected=%d found=%d\n",count,length);
                }
                warnings++;
		length = count ;
            }
	    switch(type) {
		case 'C': VMSget( 4, &CHAR[4*spot] ) ;
                          break;
		case 'R': REAL[spot] = VMSgetR() ;
                          break;
		case 'D': DBLE[spot] = VMSgetD() ;
                          break;
		case 'I': INTG[spot] = VMSgetI() ;
                          break;
		default:  error( "unknown header variable record label" ) ;
			  stop(-1);
	    }
	}
	VMSunget(c) ;

	if( type == 'C' ) {
	    type = 'A' ;
	    length *= 4 ;
        }

	put_hc( type, name, data, length ) ;
    } /* for (;;) */
}

/**************************************************************************
 *  data -- get a data record
 */

#define MAXCHAN	512
static int first = 1;

extern int v_nchan ;			/* v_nchan is set in put_hc !! */
data()
{
    char type ;
    int i, flags[MAXCHAN], wflags[4]; 
    int ant, year80, day80, leapdays;
    double log80, ut, lst, preamble[4] ;
    float data[2*MAXCHAN+10], wcorr[8], correct[4], swap_fac, tscale;
    char jdtime[40];
    /* must save a few STATIC variables for fixing time seq problem !! */
    static double ut_save, lst_save ;

    VMSget(1, &type ) ;

    ant = VMSgetI();        /* old ``antenna number'': in A1+A2*10 format */
    /* convert the old format to new format
       note that auto-correlation needs another fix later in this routine */
    if (ant/10 > ant%10) {          /* FITS convention:   Ant1 < Ant2 */
        preamble[3] = 256 * ( ant % 10 ) + ( ant / 10 ) ;
        swap_fac = -1.0;
    } else {
        preamble[3] = 256 * ( ant / 10 ) + ( ant % 10 ) ;
        swap_fac = 1.0;
    }   


    log80 = VMSgetD() ;				/* log number */

    /* log80, or day80 as some call it, is an encoded time in the format */
    /* YYDDD.XXX, where YY is the year since 1980, DDD the day number in */
    /* that year, and .XXX the fractional time. It is double precision   */

    if(hcconv_debug>0) printf("Day80 = %lf\n",log80);

/******* Elaborate check to see if date-jump occurred (A Hat Creek BUG) */

    if (counter>0) {
        if (log80-lasttime > 0.8) {           /* trouble !!! */
            log80 -= 1.0;                   /* correct for it */
            printf("### Record: %d Repairing Day80-1 to %lf\n",counter+1,log80);
        } else if (log80-lasttime < -0.8) {
            log80 += 1.0;
            printf("### Record: %d Repairing Day80+1 to %lf\n",counter+1,log80);
        } else if (log80-lasttime < 0.0) {	/* extra first record check */
            printf("### Warning: Time is running backwards at record %d\n",
                counter+1);
        }
    }
    lasttime = log80;		/* and save the previous day80 for next scan */
    counter++;

/******* End of Elaborate check */

    year80 = log80 / 1000 ;			/* years since 1980 */
    day80 = 365 * year80 + (year80 + 3) / 4 ;
#if 0
	/* following two are both wrong - kept for historical reasons */
    preamble[2] = 2401040.0 + day80 + ( log80 - 1000 * year80 ) ; /* Brian */
    preamble[2] = 2444239.5 + day80 + ( log80 - 1000 * year80 ) ; /* Peter */
#endif

	/* This code is now direct from uvhat: */
    /*  leapdays = log80/4000;    This OLD code from UVHAT is wrong */
    leapdays = ((log80+3000.0)/4000.0);
    preamble[2] = 2444239.5 + year80*365.0 + leapdays
                + log80 - year80*1000 - 1.0;   /* log80 1 based !! */
#if 0
   if (hcconv_debug>0) {
	printf("Day80=%16.10g ",log80);
        julcal_(&preamble[2],jdtime,40);        /* call the fortran routine */
        jdtime[16]='\0';
        printf(" JD = %20.10g = %s\n",preamble[2],jdtime);
    }
#endif
    ut  = VMSgetD() ;				/* universal time */
    if( ut != ut_save ) {
	uvput( 'D', "ut", (char *) &ut, 1 ) ;
	ut_save = ut ;
	}
    lst = VMSgetD() ;				/* local standard time */
    if( lst != lst_save ) {
	uvput( 'D', "lst", (char *) &lst, 1 ) ;
	lst_save = lst ;
	}

    preamble[0] = VMSgetD() * swap_fac ;		/* u in ns */
    preamble[1] = VMSgetD() * swap_fac ;		/* v in ns */

    wcorr[0] = VMSgetR() ;    		        /* LSB Twide real */
    wcorr[1] = VMSgetR() * swap_fac;		/* LSB Twide imaginary */
    wcorr[2] = VMSgetR() ;			/* USB Twide real */
    wcorr[3] = VMSgetR() * swap_fac;		/* USB Twide imaginary */

    wcorr[4] = VMSgetR() ;			/* LSB Awide real */
    wcorr[5] = VMSgetR() * swap_fac ;		/* LSB Awide imaginary */
    wcorr[6] = VMSgetR() ;			/* USB Awide real */
    wcorr[7] = VMSgetR() * swap_fac ;		/* USB Awide imaginary */
    for (i=0; i<4; i++)
        wflags[i] = FORT_TRUE;
    count_wide++;

    switch(type) {
	case '1':       /* only wideband stuff ?? */
            if (!Qobstype) {
		printf(" Only wide band - cross correlation data found\n");
                wrhda_c(HANDLE,"obstype","crosscorrelation");
                uvset_c( HANDLE, "data","wide",4,1.0,1.0,1.0); /* set wide */
                Qobstype = 1;
            }
            uvwrite_c( HANDLE, preamble, wcorr, wflags, 4); /* now wideband */
            break;
	case '2':       /* cross-corr's */
            if (!Qobstype) {
		printf(" Narrow and Wide band - cross correlation data found\n");
                wrhda_c(HANDLE,"obstype","crosscorrelation");
                uvset_c( HANDLE, "corr","j",0,0.0,0.0,0.0);   /* set scaled */
                Qobstype = 1;
            }
            /* Although correct[] needs to read, it is never used??? */
            /* Fixed very old indexing bug here. pjt 4-feb-91 - remarkable !!*/
	    correct[0] = VMSgetR() ;		/* LSB correct real */
	    correct[1] = VMSgetR() * swap_fac ; /* LSB correct imaginary */
	    correct[2] = VMSgetR() ;		/* USB correct real */
	    correct[3] = VMSgetR() * swap_fac;	/* USB correct imaginary */
	    tscale = VMSgetR() ;			/* scaling */
	    if (hcconv_debug>0) printf("DEBUG: =%g  correct=%g %g %g %g\n",
                           tscale,correct[0],correct[1],correct[2],correct[3]);

	    for( i = 0 ; i < v_nchan ; i++ ) {        /* get all narrow band */
		data[2*i  ] = tscale * VMSgetS() ;
		data[2*i+1] = tscale * VMSgetS() * swap_fac ;
		flags[i] = FORT_TRUE ;
	    }
            count_narrow++;
            uvwwrite_c( HANDLE, wcorr, wflags, 4);   /* write wideband stuff */
	    uvwrite_c( HANDLE, preamble, data, flags, v_nchan ) ;  /* narrow */
            break;
	case '3':       /* auto-corr's */ 
            if (!Qobstype) {
		printf(" Narrow and Wide band - auto correlation data found\n");
                wrhda_c(HANDLE,"obstype","autocorrelation");
                uvset_c( HANDLE, "corr","r",0,0.0,0.0,0.0); /* set real */
                Qobstype = 1;
            }

            /* We're assuming auto also has these 5 extra 'reals'
            /* but in this case none of them is used */
	    correct[0] = VMSgetR() ;		/* LSB correct real */
	    correct[1] = VMSgetR() * swap_fac ; /* LSB correct imaginary */
	    correct[2] = VMSgetR() ;		/* USB correct real */
	    correct[3] = VMSgetR() * swap_fac;	/* USB correct imaginary */
	    tscale = VMSgetR() ;			/* scaling */
            if (hcconv_debug>0) printf("DEBUG: =%g  correct=%g %g %g %g\n",
                    tscale,correct[0],correct[1],correct[2],correct[3]);
	    for( i = 0 ; i < v_nchan ; i++ ) {        /* get all narrow band */
		data[2*i] = VMSgetR() ;     /* auto is real only */
		data[2*i+1] = 0.0;          /* imag == 0 */
		flags[i] = FORT_TRUE ;
	    }
            count_narrow++;
            if (ant>3) error("auto: unexpected antenna number");
            preamble[3] = 256*ant + ant;
            uvwwrite_c( HANDLE, wcorr, wflags, 4);   /* write wideband stuff */
	    uvwrite_c( HANDLE, preamble, data, flags, v_nchan ) ;
            break;
	default:
	    error( "unknown data record label" ) ;
	    stop(-1);
    } /* switch */
    VMSend() ;
}


/*
 *  uvput -- add a variable to the output uv dataset
 *
 */

#define H_BYTE		1
#define H_INT		2
#define H_REAL		4
#define H_DBLE		5
#define H_CMPLX		7

uvput( type, name, data, length )
int length ;
char *name, *data, type ;
{
    if (length<=0) {
        printf("UV Variable %s has %d length - not written\n",name,length);
        return;
    }
    if (hcconv_debug>1)
        printf("uvput: %10s[%d]\n",name,length);

    switch(type) {
	case 'A': uvputvr_c( HANDLE, H_BYTE , name, data, length ) ;
                  break;
	case 'R': uvputvr_c( HANDLE, H_REAL , name, data, length ) ;
                  break;
	case 'D': uvputvr_c( HANDLE, H_DBLE , name, data, length ) ;
                  break;
	case 'I': uvputvr_c( HANDLE, H_INT  , name, data, length ) ;
                  break;
	case 'C': uvputvr_c( HANDLE, H_CMPLX, name, data, length ) ;
                  break;
        default:  error("unknow type in uvput");
		  stop(-1);
    }
}

static void error(string)
char *string ;
{
    (void) fprintf( stderr, "Bad Hat Creek format: %s\n", string ) ;
    uvclose_c(HANDLE) ;
}

stop(lev)
int lev;
{
    if (warnings > 0) {
        printf("### Note: There were a total of %d warning messages\n",
            warnings);
        if (hcconv_debug>=0) 
            printf("     Setting debug=-1 ignores all warning messages\n");
    }
    exit(lev);
}

/* 
 * Open a file, and only return valid FILE descriptor if it seems like
 *  a Hat Creek map
 */

FILE *HATopen(name)
char *name;
{
    FILE *fp;
    char buf[10];

    fp = fopen(name, "r");
    if (fp==NULL) {
        printf("### Error: File cannot be opened\n");
        return(NULL);
    }
    if (fgets(buf,10,fp)==NULL) {
        printf("### Error: Could not read first two bytes of file\n");
        return(NULL);
    }
    if (buf[0] != 0x03 && buf[1] != 0x00) {
        printf("### Error: Bad VMS record indicator. Is it a HAT file\n");
        return(NULL);
    }
    if (strncmp(&buf[2],"CSOURCE",7)!=0) {
        printf("### Warning: HAt file file does not start with SOURCE\n");
    }
    fclose(fp);
    fp = fopen(name, "r");
    if (fp==NULL) {
        printf("### Bizarre Error: File cannot be re-opened\n");
        return(NULL);
    }
    return(fp);
}

