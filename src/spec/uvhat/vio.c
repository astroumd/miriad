/*   VMS I/O routines for Unix IEEE/twos complement machines 
 *   This file is for UVHAT only...and only works on machine
 *   with the above mentioned native format!!
 *
 *   Public routines:
 *	vopen (int *lun, char *name, int namelen)
 *	vclose(int *lun)
 *	vread (int *lun, short *n, short *n, int *ierr)
 *      cvti2 (int *n, char *a)
 *      cvtr4 (int *n, char *a)
 *
 *	NOTE: C in Fortran callable mode: routine names have
 *	trailing underscore, and all parameters are called by
 *	reference, except the trailing integers which represent
 *	length of the fortran character string
 *
 *      Since the actual data, pointed to in these routine in bunches
 *      of 2bytes, is still unswapped, the user program must still
 *      call routines like cvtr4_ and cvti2_ !!!
 *
 *	21-dec-90  pjt created in use with uvhat to read oldhat data format...  
 *      26-jan-91  pjt when vms-header==1 some extra two bytes to be read ???
 *		       it seems to almost work, but totally unknown why
 *                     see vread_()
 *	 4-oct-91  pjt added #ifdef convex to external linker names section
 *                     warning message now suggests to use HCCONV
 *	10-oct-91  pjt appease mjs and use the __convexc__; previously used
 *		       convex trigger was his invention (see mir.* scripts)
 */

#include <stdio.h>

static int mylun=-1;		/* only maintaine one slot for now */
static FILE *myfp=NULL;
static char fname[256];
static debug=0;                 /* default: no debug output */

/*	Define proper symbol names such that linker finds them: */
#if defined(sun) || defined(__convexc__) || defined (mips)
#define vopen  vopen_
#define vclose vclose_
#define vread  vread_
#define cvti2  cvti2_
#define cvtr4  cvtr4_
#else
/* If all else fails this should trigger compiler error */
/* make sure your system has the proper redefines for fortran to c */
#define vopen  badname
#define vclose badname
#define vread  badname
#define cvti2  badname
#define cvtr4  badname
#endif

vopen(lun,name,namelen)
int *lun, namelen;
char *name;
{
    char i, *getenv();

    if (getenv("DEBUG"))
        debug=1;

    strncpy(fname,name,namelen);
    for (i=namelen; i>=0; i--)      /* make sure fortran padding */
        if (fname[i]==' ') {		/* by reading from the back */
            fname[i] = '\0';		/* and put zero's on spaces */
            break;
        }
    if ( *lun == mylun) {
        printf("VOPEN> Error : no slot to open %s\n",fname);
        exit(0);
    }
    myfp = fopen(fname,"r");
    if (myfp == NULL) {
        printf("VOPEN> Error : cannot open \"%s\" fo read\n",fname);
        exit(0);
    } else
        if (debug) printf("Opened \"%s\" for read\n",fname);
    mylun = *lun;
}

vclose(lun)
int *lun;
{
    if ( *lun != mylun && mylun != -1) {
        printf("VCLOSE> Error: unit %d to close, but unit %s was open\n",
            *lun, mylun);
        exit(0);
    }
    mylun = -1;    
}

vread(lun,n,dat,ierr)
int *lun, *ierr;
short int *n, *dat;
{
    int nread, cnt, k1, hd;
    short int i2;

    if (*lun != mylun) {
        printf("vread: Illegal lun=%d\n",*lun);
        exit(0);
    }
    if (debug) printf("Expecting VMS header at 0x%x\n",ftell(myfp));
    cnt = fread(&i2,sizeof(short),1,myfp); /* read VMS header (3*256) */
    swap2(1,&i2);    
    hd = i2;
    if (cnt==0) {
        *ierr = 1;      /* EOF */
        return;
    } else if (cnt != 1) {
        *ierr = 2;      /* ERROR */
        return;
    }
    if (hd != 3 && i2 != 1) { 
        printf("### Warning: phase error: unexpected VMS record 0x%x\n",i2);
	printf("### Possibly not the right format\n");
    }
    cnt =  fread(&i2,sizeof(short),1,myfp);        /* read count */
    swap2(1,&i2);
    if (i2 == 256 || hd==1) {			/* in these cases */
        cnt = i2;
        if (debug) printf("vread(hed): cnt=%d\n",cnt);
        k1 = fread(dat,sizeof(short),cnt,myfp);
        if (dat[0]==0 || hd==1) {		/* and these : */
            if (debug) 			/* read extra two bytes */
		printf("vread: dat[0]=0 => reading another two bytes\n");
            k1 = fread(&dat[cnt],sizeof(short),1,myfp);
            cnt++;
        }
    } else {
        cnt = i2;
        if (debug) printf("vread(dat): cnt=%d\n",cnt);
        k1 = fread(dat,sizeof(short),cnt,myfp);
    }
    *ierr = 0;
    *n = cnt;
}


/* Conversion routines:
 *   only the i2 and r4 have been coded here, since those we needed
 *   the i4 is straightforward, but r8 is more complex; see hcconv.c
 *   for details, or ask Peter Teuben. 
 */
cvti2(n,a)
int *n;
char *a;
{
    swap2(*n, a);
}

cvtr4(n,a)	/* convert VMS float's to IEEE float's */
int *n;
char *a;
{
    int i, len;

    union {
        char c[4] ;
        float r ;
    } x ;

    len = 4 * (*n);
    for (i=0; i<len; i+=4) {
        x.c[0] = a[i+1];        /* SWAP into the union */
        x.c[1] = a[i+0];
        x.c[2] = a[i+3];
        x.c[3] = a[i+2];
        x.r /= 4.0;             /* div. by 4: same as Convex */
        a[i+0] = x.c[0];        /* copy back to a */
        a[i+1] = x.c[1];
        a[i+2] = x.c[2];
        a[i+3] = x.c[3];
    }
}    

static int swap2(n,a)
int n;
char *a;
{
    int i;
    char c;
    
    for (i=0; i<2*n; i += 2){
        c = a[i];
        a[i] = a[i+1];
        a[i+1] = c;
    }
}

