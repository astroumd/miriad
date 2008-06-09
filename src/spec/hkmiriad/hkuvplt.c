/*
 * gcc -g -I$MIRINC -I$MIRSUBS -o hkuvplt hkuvplt.c $MIRLIB/libmir.a -lm libZeno.a -L/usr/local/pgplot -lcpgplot -lpgplot -lg2c -lX11 -lpng
 */

#include "maxdimc.h"
#include "miriad.h"
#include "stdinc.h"
#include "getparam.h"
#include "cpgplot.h"
#include "hkmirdefs.h"


/*
 * Default values for input parameters.
 */

string defv[] = {               ";HKTEST: hackmiriad test ",
    "vis=m061224.sour.ave",     ";Input uv data",
    "out=",                     ";Output file",
    "param=",                   ";Parameter file",
    "VERSION=0.0",              ";Jin Koda    Nov 2007",
    NULL,
};

/*
 * Prototypes and variables for local procedures
 */

local void loaddefv(void);       /* load input params from command line      */
local void loaddata(void);       /* load miriad data to hkmiriad structures  */
local void makehash(void);       /* make hashtable from bl to records        */
local panelptr setmultwin(int);  /* set window positions for multiple plots  */
local int *getitems(string,int *,char *);/* get items in line from terminal  */
local int *getbases(char,int *,int, int *);/* get baseline numbers           */
local int getantid(int);         /* get antenna id                           */
local int getblid(int);          /* get antenna id                           */
local char **splitline(string,char,int *);
                                 /* split line with comma separator to items */
local int getwcinp(float *, float *);
                                 /* get world coordinate in panel            */
local void blplot(panelptr);     /* plot ith baseline in ith panel           */
local void applyflg(flag);       /* apply flags                              */
local void outflags(void);       /* output select for uvflag                 */

track tr;                        /* track parameters */
recordptr rectab;                /* record data */
recordptr blhash[MAXANT][MAXANT];/* baseline<->record hash table */

int npan;                        /* number of panels */
panelptr pantab;                 /* pointer to plot panel */

#define MAXFLAG 256
int nflags;
flag flags[MAXFLAG];

string headline;
string vis;


#if (READLINE == 1)
  char *readline();
  static void ini_readline();
  static void end_readline();
  static void stripwhite();
#endif /* READLINE */



/*
 * MAIN: toplevel routine
 */

int main(int argc, string argv[])
{
    int i,b,ok;
    panelptr p;
    recordptr q;
    char line[256],mode,ch[32];
    float x1,y1,x2,y2,t;

    int nitems,nbases;
    char type;
    int *items,*bases;
    

    initparam(argv, defv);                      /* initialize param access  */
    headline = defv[0] + 1;                     /* headline                 */
    loaddefv();                                 /* parm from command line   */
    loaddata();                                 /* load data in hk struct.  */
    makehash();                                 /* make hashtable to record */

    cpgbeg(0,"/xs",1,1);                        /* start-up PGPLOT          */
    nflags = 0;
    mode = 'd';                                 /* start with default       */
    items = (int *) NULL;                       /* initialize pointers      */
    bases = (int *) NULL; 
    pantab = (panelptr) NULL;

#if (READLINE == 1)
  ini_readline();
#endif /* READLINE */

    
    while (mode != 'q') {

        if (mode == 'p' || mode == 'd' || mode == 'r') { /* plot modes     */

            if (mode != 'r') {

                if (mode == 'd') {              /* default                  */
                    sprintf(line,"t,%d",tr.ant[0]);
                } else {                        /* standard input           */
                    printf("Plot: [A]ll/[T]elescope/[B]aseline (e.g. \"a\",\"t,5\",\"b,2-3\") =\n");
                    scanf("%s",line);
                }

                if (items != (int *) NULL) free(items);
                items  = getitems(line,&nitems,&type); /* separate items    */
                if (bases != (int *) NULL) free(bases);
                bases  = getbases(type,items,nitems,&nbases);
                                                /* list baselines to plot   */
            } else {

                mode = 'd';
            }

            if (nbases > 0) {                   /* if something to plot     */

                npan = nbases;
                if (pantab != (panelptr) NULL) free(pantab);
                pantab = setmultwin(npan);      /* setup panels             */
                for (i=0; i<npan; i++) Pbl(pantab+i) = bases[i];
                                                /* connect bl and panel     */
                cpgeras();                      /* clean-up window          */
                for (p=pantab; p<pantab+nbases; p++) blplot(p);
                                                /* plot each bl             */
            } else {
                printf("No valid baseline selected.\n");
            }

        } else if (mode == 'f') {               /* flag mode                */
            
            printf("\tFlag: click the left\n"); /* find boundaries          */
            if (getwcinp(&x1,&y1) == 0) {
                printf("\t\tX: %f Y: %f\n",x1,y1);
                printf("\tFlag: click the right\n");
                if (getwcinp(&x2,&y2) == 0) {
                    printf("\t\tX: %f Y: %f\n",x2,y2);
                    if (x1 > x2) {
                        t = x1;
                        x2 = x1;
                        x1 = t;
                    }
                    flags[nflags].type   = type; /* setup flag              */
                    flags[nflags].nitem  = nitems;
                    flags[nflags].item   = (int *) allocate(nitems * sizeof(int));
                    for (i=0;i<nitems;i++) flags[nflags].item[i] = items[i];
                    flags[nflags].tstart = x1;
                    flags[nflags].tend  = x2;

                    applyflg(flags[nflags]);     /* apply flag to record    */
                    nflags++;

                    mode = 'r';                  /* don't ask mode          */
                }
            }

        } else if (mode == 'u') {                /* undo flag mode          */
            free(flags[nflags].item);            /* clear last flag         */
            nflags--;
            for (q=rectab; q<rectab+tr.nrec; q++) Flag(q) = FALSE;
                                                 /* initialize all flags    */
            for (i=0;i<nflags;i++) applyflg(flags[i]);
                                                 /* apply all but last      */
            mode = 'r';                          /* don't ask mode          */
        }

        if (mode != 'r') {                       /* if not replot mode      */
            printf("nflag = %d\n",nflags);       /* find next action        */
            printf("Mode: [P]lot/[R]eplot/[D]efault/[F]lag/[U]ndo/[Q]uit =\n");
            scanf("%s",&mode);
            mode = tolower(mode);
        }
    }

    outflags();


    for (i=0;i<nflags;i++) free(flags[i].item);
    free(items);
    free(bases);
    free(pantab);

    cpgend();                                    /* end pgplot               */

#if (READLINE == 1)
    end_readline();
#endif /* READLINE */

}

/*
 * GETBASES: get baseline numbers
 */

local int *getbases(char type, int *a, int na, int *nb)
{
    int i,j,k,a1,a2,b,n,*bl;

    if (type == 't') {

        n = 0;
        for (i=0; i<na; i++) {                 /* count num of baselines   */
            a1 = a[i];
            for (j=0; j<tr.nant; j++) {
                a2 = tr.ant[j];
                if (a1 != a2) {
                    if (a1 < a2) b = 256*a1+a2;
                    if (a1 > a2) b = 256*a2+a1;
                    if (getblid(b) >= 0) n++;
                }
            }
        }
        *nb = n;
        bl = (int *) allocate(*nb * sizeof(int));

        k = 0;
        for (i=0; i<na; i++) {                 /* store base in memory     */
            a1 = a[i];
            for (j=0; j<tr.nant; j++) {
                a2 = tr.ant[j];
                if (a1 != a2) {
                    if (a1 < a2) b = 256*a1+a2;
                    if (a1 > a2) b = 256*a2+a1;
                    if (getblid(b) >= 0) {
                        bl[k] = b;
                        k++;
                    }
                }
            }
        }


    } else if (type == 'b') {

        *nb = na;
        bl = (int *) allocate(*nb * sizeof(int));
        for (i=0; i<*nb; i++) bl[i] = a[i];

    } else if (type == 'a') {

        *nb = tr.nbase;
        bl = (int *) allocate(*nb * sizeof(int));        
        for (i=0; i<*nb; i++) bl[i] = tr.base[i];

    }

    return(bl);
}


/*
 * OUTFLAGS: output flag in miriad/select format
 */

local void outflags(void)
{
    int i,j,a1,a2,bl;
    flagptr f;

    for (i=0; i<nflags; i++) {
        f = flags[i];
        if (f.type == 'a') {
            printf("select=time(%f,%f)\n",f.tstart,f.tend);
        } else if (f.type == 't') {
            for (j=0; j<f.nitem; j++)
                printf("select=ant(%d),time(%f,%f)\n",f.item[j],f.tstart,f.tend);
        } else if (f.type == 'b') {
            for (j=0; j<f.nitem; j++) {
                a1 = f.item[j] / 256;
                a2 = f.item[j] - 256*a1;
                printf("select=ant(%d)(%d),time(%f,%f)\n",a1,a2,f.tstart,f.tend);
            }
        }
    }

}



/*
 * APPLYFLG: apply flag to record
 */

local void applyflg(flag flg)
{
    int i,a1,a2,*bl,nbl;
    recordptr p;

    bl = getbases(flg.type,flg.item,flg.nitem,&nbl);

    for (i=0; i<nbl; i++) {
        a1 = bl[i] / 256;
        a2 = bl[i] - 256*a1;
        for (p=blhash[a1-1][a2-1]; p!=NULL; p=Next(p))
            if (Time(p) > flg.tstart && Time(p) < flg.tend)
                Flag(p)=TRUE;
    }

    free(bl);
}


/*
 * GETITEMS: get antenas/baselines from line
 */

local int *getitems(string line,int *nitem, char *type)
{
    int nelem,nit,*it;
    char **elem,**a;
    int i,j,k,n,b,a1,a2;

    elem = splitline(line,',',&nelem);          /* split line                */

    if (line[0] == 't') {                       /* selected telescopes       */

        *type = 't';                            /* set item type             */
        nit = 0;
        for (i=1; i<nelem; i++) {
            a1 = atoi(elem[i]);                 /* count num of ant in line  */
            if (getantid(a1) >= 0) nit++;       /* if a1 exists, count it    */
        }
        it = (int *)allocate(nit * sizeof(int));/* alloc memory              */
        k = 0;
        for (i=1; i<nelem; i++) {
            a1 = atoi(elem[i]);                 /* this antenna              */
            if (getantid(a1) >= 0) {            /* if exists in this track   */
                it[k] = a1;
                k++;
            }
        }

    } else if (line[0] == 'b') {                /* selected baselines        */

        *type = 'b';
        nit = 0;                                /* count num of baselines    */
        for (i=1; i<nelem; i++) {
            a = splitline(elem[i],'-',&n);
            if (n == 2) {
                a1 = atoi(a[0]);
                a2 = atoi(a[1]);
                if (a1 != a2) {
                    if (a1 < a2) b = 256*a1+a2;
                    if (a1 > a2) b = 256*a2+a1;
                    if (getblid(b) >= 0) nit++; /* if b exists, count it     */
                }
            }
            free(a);
        }
        it = (int *) allocate(nit * sizeof(int));
                                                /* alloc memory              */
        k = 0;
        for (i=1; i<nelem; i++) {
            a = splitline(elem[i],'-',&n);
            if (n == 2) {
                a1 = atoi(a[0]);
                a2 = atoi(a[1]);
                if (a1 != a2) {
                    if (a1 < a2) b = 256*a1+a2;
                    if (a1 > a2) b = 256*a2+a1; /* this baseline             */
                    if (getblid(b) >= 0) {      /* if exist in this track    */
                        it[k] = b;              /* add it to list            */
                        k++;
                    }
                }
            }
        }

    } else {                                    /* selected all, or illegal  */

        *type = 'a';
        nit = 0;
        it = (int *) NULL;
    }

    free(elem);
    *nitem = nit;

    return(it);
}


/*
 * GETWCINP: get world coordinate in panel
 */

local int getwcinp(float *xw, float *yw)
{
    float xc,yc,xd,yd,xdev1,xdev2,ydev1,ydev2,xwld1,xwld2,ywld1,ywld2;
    char ch[32];
    panelptr p,q;

    cpgqwin(&xwld1,&xwld2,&ywld1,&ywld2);       /* get world coord. setting  */
    cpgqvp(0,&xdev1,&xdev2,&ydev1,&ydev2);      /* get view point setting    */
    cpgcurs(&xc,&yc,ch);                        /* read world coord.wt/mouse */
    xd = (xdev2-xdev1)/(xwld2-xwld1)*(xc-xwld1) + xdev1;
    yd = (ydev2-ydev1)/(ywld2-ywld1)*(yc-ywld1) + ydev1;
                                                /* device coord from world   */
    q = (panelptr) NULL;
    for (p=pantab; p<pantab+npan; p++){         /* find panel where cursol is*/
        if ((xd > Xdev(p)[0]) && (xd < Xdev(p)[1]) &&
            (yd > Ydev(p)[0]) && (yd < Ydev(p)[1])) q = p;
    }
    if (q != (panelptr) NULL) {                 /* calc world coord in panel */
        *xw = (Xwld(q)[1]-Xwld(q)[0])/(Xdev(q)[1]-Xdev(q)[0])*(xd-Xdev(q)[0])+Xwld(q)[0];
        *yw = (Ywld(q)[1]-Ywld(q)[0])/(Ydev(q)[1]-Ydev(q)[0])*(yd-Ydev(q)[0])+Ywld(q)[0];
        return(0);
    } else {
        return(-1);
    }
}

/*
 * GETANTID: get antenna id
 */

local int getantid(int ant)
{
    int i,k;

    i = -1;
    for (k=0; k<tr.nant; k++)
        if (tr.ant[k] == ant) i = k;
    return(i);
}

/*
 * GETANTID: get antenna id
 */

local int getblid(int bl)
{
    int i,k;

    i = -1;
    for (k=0; k<tr.nbase; k++)
        if (tr.base[k] == bl) i = k;
    return(i);
}


/*
 * BLPLOT: baseline plot
 */

local void blplot(panelptr pp)
{
    
    float xs,ys,x,dx,xmin,xmax,ymin,ymax;
    recordptr r;
    int i,k,npanel,a1,a2;
    char line[256], title[36];
    recordptr q;

    xmin =  999.9;                              /* plot range               */
    xmax = -999.9;
    for (q=rectab; q<rectab+tr.nrec; q++) {
        x = Time(q);
        xmin = MIN(xmin,x);
        xmax = MAX(xmax,x);
    }
    dx = (xmax - xmin) * 0.05;
    xmin = xmin - dx;
    xmax = xmax + dx;

    Xwld(pp)[0] = xmin;
    Xwld(pp)[1] = xmax;
    Ywld(pp)[0] =  0.0;
    Ywld(pp)[1] = 30.0;

    for (i=0;i<npan;i++) {

    }


    a1 = Pbl(pp) / 256;                         /* antenna numbers            */
    a2 = Pbl(pp) - 256*a1;
    sprintf(title,"%2d-%2d",a1,a2);

    cpgsvp(Xdev(pp)[0],Xdev(pp)[1],Ydev(pp)[0],Ydev(pp)[1]);
    cpgswin(Xwld(pp)[0],Xwld(pp)[1],Ywld(pp)[0],Ywld(pp)[1]);
    cpgsch(0.6);

    if (Xlab(pp) == TRUE) {              /* x-coordinage and label    */
            cpgbox("bncts", 0.0, 0, "", 0.0, 0);
            cpgmtxt("b",2.5,0.5,0.5,"Relative Time [h]");
        } else {
            cpgbox("bcts", 0.0, 0, "", 0.0, 0);
        }
    if (Ylab(pp) == TRUE) {              /* y-coordinage and label    */
            cpgbox("", 0.0, 0, "bncts", 0.0, 0);
            cpgmtxt("l",2.5,0.5,0.5,"Phase/Amplitude");
        } else {
            cpgbox("", 0.0, 0, "bcts", 0.0, 0);
    }
    cpgsch(0.8);
    cpgmtxt("t",-1.2,0.95,1.0,title);

    for (q=blhash[a1-1][a2-1]; q!=NULL; q=Next(q)) {
        xs = Time(q);
        ys = Re(q);
        if (Flag(q) == FALSE) {
            cpgpt(1,&xs,&ys,3);
        } else {
            cpgpt(1,&xs,&ys,-1);
        }
    }
}

/*
 * MAKEHASH: make hashtable to link from baselines to records
 */

local void makehash(void)
{
    int ma,bl,a1,a2,i,j;
    recordptr p,q,bp[MAXANT][MAXANT];

    ma = 0;
    for (i=0; i<tr.nant; i++) ma = MAX(ma,tr.ant[i]);
                                               /* find maximum ant number    */
    for (i=0;i<ma;i++)
        for (j=0;j<ma;j++) {                   /* initialize bl hashtable    */
            blhash[i][j] = (recordptr) NULL;
            bp[i][j] = blhash[i][j];
        }
        
    for (p=rectab; p<rectab+tr.nrec; p++) {    /* loop over records          */
        bl = Bl(p);                            /* find baseline number, and  */
        a1 = bl / 256;                         /* antenna numbers            */
        a2 = bl - 256*a1;
        if (blhash[a1-1][a2-1] == NULL) {      /* first record in this bl,   */
            blhash[a1-1][a2-1] = p;            /* link to it from the top    */
        } else {                               /* if not the first           */
            Next(bp[a1-1][a2-1]) = p;          /* link from prev. rec.       */
        }
        bp[a1-1][a2-1] = p;                    /* last record is updated     */
    }
}


/*
 * LOADDEFV: load variables defined in defv or command line
 */

local void loaddefv(void)
{
    vis = getparam("vis");                     /* set output file name      */
}

/*
 * LOADDATA: load data from miriad dataset to hkmiriad structures.
 */

local void loaddata(void)
{

#define MAXNAME 9

    int unit;
    int flg[MAXCHAN];
    float data[MAXCHAN];
    double pre[5],ts;

    int nrec,nchan,nsour,nbase,nant,b,base[MAXBASE],a1,a2,ants[MAXANT];
    char s[MAXNAME],sour[MAXSOU][MAXNAME];
    recordptr p;
    int i,k,n;


    uvopen_c(&unit,vis,"old");                 /* open miriad data           */

                                               /* 1st scan to get basic par. */
    nrec  = 0;                                 /* initialize record, chan.,  */
    nchan = 0;                                 /* source, and bl counters    */
    nsour = 0;
    nbase = 0;

    n = 1;                                     /* initialize for loop        */
    ts = 1.0e9;                                /* initialize track start time*/
    while (n > 0) {                            /* loop over records          */
        uvread_c(unit,pre,data,flg,MAXCHAN,&n);
                                               /* read data from miriad file */
        nrec++;                                /* update record counter      */
        nchan = MAX(nchan,n);                  /* find max for chan. counter */
        ts = MIN(ts,pre[2]);                   /* find track start time      */

        b = (int) pre[3];                      /* get baseline number        */
        i = 0;                                 /* search through bl list     */
        while (i<nbase && base[i] != b) i++;
        if (i == nbase) {                      /* if not in list, add it     */
            base[nbase] = b;
            nbase++;
        }

        uvgetvra_c(unit,"source",s,sizeof(s));  /* get source name            */
        i = 0;                                  /* search through source list */
        while (i<nsour && !streq(sour[i],s)) i++;
        if (i == nsour) {                       /* if not in list, add it     */
            strcpy(sour[nsour],s);
            nsour++;
        }
    }
    nant = 0;                                   /* make antennas list from bl */
    for (i=0; i<nbase; i++) {                   /* loop over baselines        */
        a1 = base[i] / 256;                     /* antennas in this bl        */
        a2 = base[i] - 256*a1;
        k = 0;                                  /* search through ant list    */
        while (k<nant && ants[k] != a1) k++;    /* and if not in list yet,    */
        if (k == nant) {                        /* add it.                    */
            ants[nant] = a1;
            nant++;
        }
        k = 0;
        while (k<nant && ants[k] != a2) k++;
        if (k == nant) {
            ants[nant] = a2;
            nant++;
        }
    }
    rectab = (recordptr) allocate(nchan * nrec * sizeof(record));
                                                /* alloc mem for records     */
    uvrewind_c(unit);                           /* go back to file head      */
    for (p=rectab; p<rectab+nrec; p++) {        /* loop over records         */
        uvread_c(unit,pre,data,flg,MAXCHAN,&n); /* read preambles,           */
        UU(p)    = pre[0];                      /* u-coordinate in nsec      */
        VV(p)    = pre[1];                      /* v-coordinate in nsec      */
        Time(p)  = (pre[2] - ts)*24.0;          /* time from start in hours  */
        Bl(p)    = pre[3];                      /* baseline number           */
        Re(p)    = data[0];                     /* real part of vis          */
        Im(p)    = data[1];                     /* imaginary part of vis     */
        Next(p)  = NULL;                        /* init next pointer         */
        uvgetvra_c(unit,"source",s,sizeof(s));  /* find source id            */
        k = 0;
        while (k<nsour && !streq(sour[k],s) ) k++;
        Souid(p) = k;
        Flag(p) = FALSE;                        /* initialize flag           */
    }
    uvclose_c(unit);                            /* close miriad data         */

    tr.nrec  = nrec;                            /* set param common in track */
    tr.nchan = nchan;
    tr.nsour = nsour;
    for (i=0; i<nsour; i++) strcpy(tr.source[i],sour[i]);
    tr.nbase = nbase;
    for (i=0; i<nbase; i++) tr.base[i] = base[i];
    tr.nant = nant;
    for (i=0; i<nant;  i++) tr.ant[i] = ants[i];
    tr.tstart = ts;

    if (tr.nchan > 1)                           /* current limitation        */
        error("loaddata: nchan must be 1.\n");
}

/*
 * SPLITLINE: split line with comma separator to items
 */

local char **splitline(string line, char ch, int *nn)
{
    int n,i,ni;
    char *c,*str,*start,**arr;

    if (*line == (char) NULL) return(NULL);     /* return null if nothing    */
    str = strdup(line);                         /* copy line to temp. param  */
    ni = 1;                                     /* initialize item counter   */
    for (c=str; *c!= (char) NULL; c++)          /* loop over characters      */
        if (*c == ch) {                         /* found a separator         */
            *c = '\0';                          /* replace it to string end  */
            ni++;                               /* increase item counter     */
        }
    arr = (char **) allocate((ni+1) * sizeof(char **));
                                                /* alloc mem for output      */
    start = str;                                /* start from first character*/
    for (i=0; i<ni; i++) {                      /* loop over items           */
        arr[i] = (char *) strdup(start);        /* copy string to the arary  */
        while (*start != NULL) start++;         /* find next string          */
        start++;
    }
    arr[ni] = 0;
    free(str);
    *nn = ni;
    return(arr);
}

/*
 * SETMULTWIN: set window positions for multiple plots
 */

local panelptr setmultwin(int npanel)
{
    panelptr p;
    float tmarg,bmarg,rmarg,lmarg,vsize,hsize;
    int nc,nr;
    int r,c,k;

    p = (panelptr) allocate(npanel * sizeof(panel));
                                                /* alloc mem for panel param.*/
    nc = (npanel-1)/7 + 1;                      /* num. of column            */
    nr = npanel/nc;                             /* num. of rows              */
    if (npanel > nc*nr) nr = nr + 1;

    tmarg = 0.05;                               /* top margin                */
    bmarg = 0.05;                               /* bottom margin             */
    lmarg = 0.05;                               /* left margin               */
    rmarg = 0.00;                               /* right margin              */

    vsize = (1.0 -tmarg -bmarg) / (float) nr;   /* verti. max space of panel */
    hsize = (1.0 -rmarg -lmarg) / (float) nc;   /* horiz. max space of panel */

    for (k=0; k<npanel; k++) {
        c = k/nr;                               /* column number of panel    */
        r = nr - (k-c*nr) -1;                   /* row number of panel       */
        p[k].xdev[0] = lmarg + hsize * c;       /* set panel frames          */
        p[k].xdev[1] = p[k].xdev[0] + hsize * 0.95;
        p[k].ydev[1] = bmarg + vsize * (r+1);
        p[k].ydev[0] = p[k].ydev[1] - vsize * 0.95;
        if (r == 0 || k == npanel-1) {          /* boolian for x-label       */
            p[k].xlab = TRUE;
        } else {
            p[k].xlab = FALSE;
        }
        if (c == 0) {                           /* boolian for y-label       */
            p[k].ylab = TRUE;
        } else {
            p[k].ylab = FALSE;
        }
    }
    return(p);
}
