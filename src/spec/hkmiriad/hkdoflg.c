/*
 * HKDOFLG.C: hack miriad automated basic flagging routine
 *   Copyright (c) 2008 by Jin Koda, Pasadena, CA
 #
 * gcc -g -I$MIRINC -I$MIRSUBS -o hkdoflg hkdoflg.c $MIRLIB/libmir.a -lm -I$MIR/borrow/zeno $MIR/borrow/zeno/libZeno.a -lg2c
 */

/*= hkdoflg - hack miriad automated basic flagging routine
/*& jk
/*: vis
/*+
    Automated program to flag visibilties in way uvflag cannot. For example
    based on system temperatures.

/*@ vis
    Input file
/*@ tsyscut
    Cut-off Tsys for flagging
/*--
 */

#include "maxdimc.h"
#include "miriad.h"
#include "stdinc.h"
#include "getparam.h"

/*
 * Default values for input parameters.
 */

string defv[] = {               ";HKDOFLG: ",
    "vis=xxx.mir",              ";Input uv data",
    "tsyscut=2000.0",           ";Cut-off Tsys for flagging",
    "VERSION=1.0",              ";Jin Koda    Aug 2008",
    NULL,
};

/*
 * Prototypes and variables for local procedures
 */

local void loaddefv(void);       /* load input params from command line */
local char **splitline(string,char,int *); /* split line to items */

int nfiles;                      /* number of input miriad data */
char **files;                    /* input miriad data */
string headline;                 /* headline */
string vis;                      /* parameter for input visibility files */
float tsyscut;                   /* cutoff tsys value */

/*
 * MAIN: toplevel routine
 */

int main(int argc, string argv[])
{

    int unit;
    int flg[MAXCHAN];
    float data[2*MAXCHAN];
    double pre[5];
    float tsys[MAXANT*MAXWIN],tsys1,tsys2,maxtsys;
    int b,a1,a2;
    int nants,nspect,ntsys,ischan[MAXWIN],nschan[MAXWIN];
    int f,n,w,i,c,nr,nf;

    initparam(argv, defv);                       /* initialize param access */
    headline = defv[0] + 1;                      /* headline                */
    printf("%s",headline);
    loaddefv();                                  /* parm from command line  */

    for (f=0; f<nfiles; f++) {                   /* loop over all files     */

        nr = 0;                                  /* record counter          */
        nf = 0;                                  /* flag counter            */
        uvopen_c(&unit,files[f],"old");          /* open miriad data        */
	uvread_c(unit,pre,data,flg,MAXCHAN,&n);  /* start reading data      */
        while (n > 0) {                          /* loop over records       */

	    b = (int) pre[3];                    /* get baseline number     */
	    a1 = b / 256;                        /* antennas in this bl     */
	    a2 = b - 256*a1;

	    if (tsyscut != 0.0) {                /* if tsys criterion set   */
	        uvgetvri_c(unit,"nants",&nants,1);      /* # of antennas    */
		uvgetvri_c(unit,"nspect",&nspect,1);    /* # of spec windows*/
		uvgetvri_c(unit,"nschan",nschan,nspect);/* # of chan in wind*/
		uvgetvri_c(unit,"ischan",ischan,nspect);/* start_chan of win*/
		ntsys = nspect * nants;                 /* # of tsys measure*/
		uvgetvrr_c(unit,"systemp",tsys,ntsys);  /* system temp      */
		maxtsys = 0.0;
		for (i=0;i<nspect;i++) {         /* loop over windows       */
		    tsys1 = tsys[nants*i+a1-1];  /* tsys of 1st antenna     */
		    tsys2 = tsys[nants*i+a2-1];  /* tsys of 2nd antenna     */
		    maxtsys = MAX(maxtsys,tsys1);/* record max              */
		    maxtsys = MAX(maxtsys,tsys2);
		    if (tsys1 >= tsyscut || tsys2 >= tsyscut) {
		        for (c=ischan[i]-1;c<ischan[i]+nschan[i]-1;c++) {
			    flg[c] = FALSE;
			}
			uvflgwr_c(unit,flg);
		    }
		}
		if (maxtsys >= tsyscut) nf++;    /* flag counter            */
	    }

	    nr++;
	    uvread_c(unit,pre,data,flg,MAXCHAN,&n);/* read data             */
        }
        uvclose_c(unit);                         /* close miriad data       */

	printf("%20-s\n",files[f]);
	printf("%10s: Processed %10d records, flagged %10d\n","Tsys",nr,nf);
                                                 /* statistics              */
    }
}

/*
 * LOADDEFV: load variables defined in defv or command line
 */

local void loaddefv(void)
{
    vis = getparam("vis");                       /* get file names          */
    tsyscut = getdparam("tsyscut");               /* cutoff tsys             */
    files = splitline(vis,',',&nfiles);          /* split file names        */
}

/*
 * SPLITLINE: split line with comma separator to items
 */

local char **splitline(string line, char ch, int *nn)
{
    int n,i,ni;
    char *c,*str,*start,**arr;

    if (*line == (char) NULL) return(NULL);     /* return null if nothing   */
    str = strdup(line);                         /* copy line to temp. param */
    ni = 1;                                     /* initialize item counter  */
    for (c=str; *c!= (char) NULL; c++)          /* loop over characters     */
        if (*c == ch) {                         /* found a separator        */
            *c = '\0';                          /* replace it to string end */
            ni++;                               /* increase item counter    */
        }
    arr = (char **) allocate((ni+1) * sizeof(char **));
                                                /* alloc mem for output     */
    start = str;                                /* start from 1st character */
    for (i=0; i<ni; i++) {                      /* loop over items          */
        arr[i] = (char *) strdup(start);        /* copy string to the arary */
        while (*start != (char) NULL) start++;  /* find next string         */
        start++;
    }
    arr[ni] = 0;
    free(str);
    *nn = ni;
    return(arr);
}
