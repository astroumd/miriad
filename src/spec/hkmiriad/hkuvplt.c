/*
 * HKUVPLT.C: hack miriad plot & flag routine
 *   Copyright (c) 2007 by Jin Koda, Pasadena, CA
 #
 * gcc -g -I$MIRINC -I$MIRSUBS -o hkuvplt hkuvplt.c $MIRLIB/libmir.a -lm libZeno.a -L/usr/local/pgplot -lcpgplot -lpgplot -lg2c -lX11 -lpng
 */

#include "maxdimc.h"
#include "miriad.h"
#include "stdinc.h"
#include "getparam.h"
#include "cpgplot.h"
#include "hkuvplt.h"

/*
 * Default values for input parameters.
 */

string defv[] = {               ";HKUVPLT: hkuvplt test ",
    "vis=xxx.mir",              ";Input uv data",
    "out=",                     ";Output file",
    "yaxis=amp",                ";Yaxis [amp/pha]",
    "VERSION=1.2",              ";Jin Koda    Dec 2007",
    NULL,
};

/*
 * Prototypes and variables for local procedures
 */

local void loaddefv(void);       /* load input params from command line */
local void loaddata(void);       /* load miriad data to hkmiriad structures */
local void makectab(void);       /* make color index table for plots */
local void showinfo(void);       /* show track information */
local void showhelp(void);       /* show help */
local void linkbrec(void);       /* link baselines and records */
local void setpldef(void);       /* set default plot parameters */
local panelptr setmultwin(int);  /* set window positions for multiple plots */
local int *sepitems(string,int *,int *,char *);
                                 /* get items in line from terminal */
local int *listbase(char,int *,int, int *);/* list baseline numbers */
local void selsour(void);        /* select sources */
local int *sepsour(string,int *,char *); /* separate sources in line */
local char **splitline(string,char,int *); /* split line to items */
local int getantid(int);         /* get antenna id */
local int getbaseid(int);        /* get baseline id */
local int getrange(float *,float *,char); /* get range in wc */
local int getwcinp(float *, float *, char *); /* get wld coord in panel */
local void blplot(panelptr);     /* plot one baseline */
local void applyflg(flag);       /* apply flags */
local void outflags(void);       /* output 'select' for uvflag */
local void printflag(flag,stream); /* print flag in miriad select format */

track tra;                       /* track parameters */
recordptr toprec[MAXANT][MAXANT];/* pointer to top record for baseline */
recordptr rec;                   /* record data */
int nfiles;                      /* number of input miriad data */
char **files;                    /* input miriad data */
int npan;                        /* number of panels */
panelptr pan;                    /* pointer to plot panel */
int nflags;                      /* maximum num. of flags */
flag flags[MAXFLAG];             /* flags */
prange pldef;                    /* default plot range */
prange plrng;                    /* plot range to use */
string headline;                 /* headline */
string yaxis;                    /* y-axis parameter [pha/amp] */
string vis;                      /* parameter for input visibility files */
string outfile;                  /* output file name */
int cindtab[MAXSOU];             /* color index table for plots */

/*
 * MAIN: toplevel routine
 */

int main(int argc, string argv[])
{
    int nit,*it,nb,*bl,i;
    char line[256],mode,type,dum;
    float x1,y1,x2,y2;
    panelptr p;
    recordptr r;
    

    initparam(argv, defv);                       /* initialize param access  */
    headline = defv[0] + 1;                      /* headline                 */
    loaddefv();                                  /* parm from command line   */
    loaddata();                                  /* load data in hk struct.  */
    cpgbeg(0,"/xs",1,1);                         /* start-up PGPLOT          */
    makectab();                                  /* make color tbl. for plots*/
    showinfo();                                  /* show track information   */
    linkbrec();                                  /* link baseline and record */
    setpldef();                                  /* set default plot params  */
    nflags = 0;                                  /* initialize flags         */
    mode = 'd';                                  /* start with default       */
    nit = 0; it = (int *) NULL;                  /* init. items              */
    sprintf(line,"t,%d",tra.ant[0]);             /* pick first antenna       */
    it = sepitems(line,it,&nit,&type);           /* separate items           */
    bl = listbase(type,it,nit,&nb);              /* itialize lists of bl,    */
    pan = setmultwin(npan);                      /* initialize panel pointer */

    while (mode != 'q') {

        if (mode == 'p' || mode == 'd' || mode == 'r') { /* plot modes       */

            if (mode != 'r') {
                if (mode == 'd') {               /* default plot range       */
                    setpldef();
                } else {                         /* standard input           */
                    printf("Plot: [A]ll/[T]elescope/[B]aseline (e.g. \"a\",\"t,5\",\"b,2-3\") =\n");
                    scanf("%s",line);
		    it = sepitems(line,it,&nit,&type); /* separate items     */
		    if (bl != (int *) NULL) free(bl);
		    bl = listbase(type,it,nit,&nb);

                }
            } else {
                mode = 'd';                      /* skip asking mode         */
            }
            if (nb > 0) {                        /* if something to plot     */
                if (pan != (panelptr) NULL) free(pan);
                npan = nb;
                pan = setmultwin(npan);          /* setup panels             */
                for (p=pan; p<pan+npan; p++)     /* connect bl and panel     */
                    (*p).bl = bl[(int) (p-pan)];
                cpgpage(); printf("\n");         /* clean up window          */
                for (p=pan; p<pan+nb; p++)       /* plot each bl             */
                    blplot(p);
            } else {
                printf("No valid baseline.\n");
            }

        } else if (mode == 'f') {                /* flag mode                */

            if (getrange(&x1,&x2,'x')==0) {
                printf("\tFLAG: (x1,x2) = (%f,%f)\n",x1,x2);
                flags[nflags].type   = type;     /* setup flag               */
                flags[nflags].nitem  = nit;
                flags[nflags].item   = (int *) allocate(nit * sizeof(int));
                for (i=0;i<nit;i++) flags[nflags].item[i] = it[i];
                flags[nflags].tstart = MIN(x1,x2);
                flags[nflags].tend   = MAX(x1,x2);
                applyflg(flags[nflags]);         /* apply flag to record     */
                nflags++;
                mode = 'r';                     /* don't ask mode           */
            }

        } else if (mode == 'u') {                /* undo flag mode           */

            free(flags[nflags].item);            /* clear last flag          */
            nflags--;
            for (r=rec; r<rec+tra.nrec; r++)     /* initialize all flags     */
                (*r).flag = NONE;
            for (i=0;i<nflags;i++)               /* apply all but last       */
                applyflg(flags[i]);
            mode = 'r';                          /* don't ask mode           */

        } else if (mode == 'x') {                /* zoom in x-axis           */

            if (getrange(&x1,&x2,'x')==0) {
                plrng.xmin = x1;
                plrng.xmax = x2;
                printf("\tXzoom: (x1,x2) = (%f,%f)\n",x1,x2);
                mode = 'r';
            }

        } else if (mode == 'y') {                /* zoom in y-axis           */

            if (getrange(&y1,&y2,'y')==0) {
                if (strcmp(yaxis,"amp")==0) {
                    plrng.ymin1 = y1;
                    plrng.ymax1 = y2;
                    printf("\tYzoom: (y1,y2) = (%f,%f)\n",y1,y2);
                } else {
                    plrng.ymin2 = y1;
                    plrng.ymax2 = y2;
                    printf("\tYzoom: (y1,y2) = (%f,%f)\n",y1,y2);
                }
                mode = 'r';
            }

        } else if (mode == 'c') {                /* cycle yaxis: pha<->amp  */

            if (strcmp(yaxis,"amp")==0) {
                strcpy(yaxis,"pha");
            } else {
                strcpy(yaxis,"amp");
            }
            mode = 'r';

        } else if (mode == 's') {                /* select sources          */
            selsour();
            mode = 'r';

        } else if (mode == 'i') {                /* show track info         */
            showinfo();
            mode = 't';                          /* through                 */
        } else if (mode == 'h') {                /* help page               */
	    showhelp();
	    mode = 't';
	}

        if (mode != 'r') {                       /* if not replot mode      */

            printf("Mode: [P]lot/[X]oom/[Y]oom/[D]efault/[F]lag/[U]ndo/[C]ycle/[S]ource/[I]nfo/[H]elp/[Q]uit =\n");
            scanf("%s",line);
            mode = line[0];
            mode = tolower(mode);
        }
    }
    outflags();                                  /* output select= commands */

    for (i=0;i<nflags;i++) free(flags[i].item);
    free(it);
    free(bl);
    free(pan);
    cpgend();                                    /* end pgplot              */
}

/*
 * MAKECTAB: make color table for plots
 */

void makectab(void)
{
    int i;
    for (i=0; i<tra.nsour; i++) cindtab[i] = i+5;
}

/*
 * SELSOUR: select sources (mask others)
 */

local void selsour(void)
{
    int nm,*ma,i,k;
    char code,line[256];
    recordptr r;

    printf("\tSources:\n");
    for (i=0;i<tra.nsour;i++)
        printf("\t\t%2d: %s\n",i,tra.sour[i]);
    printf("\n");
    printf("Select sources: [A]ll/[S]elect/[M]ask/[U]nmask (e.g. \"a\",\"s,1,2\",\"m,2\",\"u,1,3\") =\n");
    scanf("%s",line);

    ma  = sepsour(line,&nm,&code);       /* separate items           */
    if (code == 'a') {
        for (r=rec; r<rec+tra.nrec; r++)
            (*r).flag &= ~MASK;          /* set maskbit to unmask    */
    } else if (code == 's') {
        for (r=rec; r<rec+tra.nrec; r++) {
            k = 0;
            for (i=0; i<nm; i++)
                if ((*r).souid == ma[i]) k++;
            if (k>0) {
                (*r).flag &= ~MASK;      /* set maskbit to unmask    */
            } else {
                (*r).flag |= MASK;       /* set maskbit to mask      */
            }
        }
    } else if (code == 'm') {
        for (r=rec; r<rec+tra.nrec; r++) {
            for (i=0; i<nm; i++) {
                if ((*r).souid == ma[i])
                    (*r).flag |= MASK;   /* set maskbit to mask      */
            }
        }
    } else if (code == 'u') {
        for (r=rec; r<rec+tra.nrec; r++) {
            for (i=0; i<nm; i++) {
                if ((*r).souid == ma[i])
                    (*r).flag &= ~MASK;  /* set maskbit to unmask    */
            }
        }
    }
    if (ma != (int *) NULL) free(ma);
}


/*
 * SEPSOUR: separate sources from line, check their presenses
 */

local int *sepsour(string line,int *nitem, char *type)
{
    int nelem,nit,*it;
    char **elem,**a;
    int i,j,k,n,b,a1,a2,s;

    elem = splitline(line,',',&nelem);          /* split line               */

    if (line[0] == 'a') {                       /* selected all             */

        *type = 'a';
        nit = 0;
        it = (int *) NULL;

    } else if (line[0] == 's') {

        *type = 's';
        nit = 0;
        for (i=1; i<nelem; i++) {
            s = atoi(elem[i]);                  /* count num of ant in line */
            if (s >= 0 && s < tra.nsour) nit++; /* if sour exists, count it */
        }
        it = (int *)allocate(nit * sizeof(int));/* alloc memory             */
        k = 0;
        for (i=1; i<nelem; i++) {
            s = atoi(elem[i]);                  /* this source              */
            if (s >= 0 && s < tra.nsour) { /* if exists in this track  */
                it[k] = s;
                k++;
            }
        }
    } else if (line[0] == 'm') {

        *type = 'm';
        nit = 0;
        for (i=1; i<nelem; i++) {
            s = atoi(elem[i]);                  /* count num of ant in line */
            if (s >= 0 && s < tra.nsour) nit++; /* if sour exists, count it */
        }
        it = (int *)allocate(nit * sizeof(int));/* alloc memory             */
        k = 0;
        for (i=1; i<nelem; i++) {
            s = atoi(elem[i]);                  /* this source              */
            if (s >= 0 && s < tra.nsour) { /* if exists in this track  */
                it[k] = s;
                k++;
            }
        }
    } else if (line[0] == 'u') {

        *type = 'u';
        nit = 0;
        for (i=1; i<nelem; i++) {
            s = atoi(elem[i]);                  /* count num of ant in line */
            if (s >= 0 && s < tra.nsour) nit++; /* if sour exists, count it */
        }
        it = (int *)allocate(nit * sizeof(int));/* alloc memory             */
        k = 0;
        for (i=1; i<nelem; i++) {
            s = atoi(elem[i]);                  /* this source              */
            if (s >= 0 && s < tra.nsour) { /* if exists in this track  */
                it[k] = s;
                k++;
            }
        }

    } else {
        it = (int *) NULL;
    } 

    free(elem);
    *nitem = nit;

    return(it);
}

/*
 * SETPLDEF: set default plot parameters
 */

local void setpldef(void)
{
    recordptr r;
    float xmin,xmax,ymin,ymax,x,y,dx,dy;

    xmin =  999.9;
    xmax = -999.9;
    ymin =  999.9;
    ymax = -999.9;
    for (r=rec; r<rec+tra.nrec; r++) {
        if (((*r).flag & MASK) != MASK) {
            x = (*r).ut;
            xmin = MIN(xmin,x);
            xmax = MAX(xmax,x);
            y = (float) (*r).amp;
            ymin = MIN(ymin,y);
            ymax = MAX(ymax,y);
        }
    }
    dx = ABS(xmax - xmin);
    dy = ABS(ymax - ymin);

    pldef.xmin  = xmin - 0.03 * dx;
    pldef.xmax  = xmax + 0.03 * dx;
    pldef.ymin1 = ymin - 0.03 * dy;
    pldef.ymax1 = ymax + 0.03 * dy;
    pldef.ymin2 = -180.0;
    pldef.ymax2 =  180.0;

    plrng.xmin = pldef.xmin;
    plrng.xmax = pldef.xmax;
    plrng.ymin1 = pldef.ymin1;
    plrng.ymax1 = pldef.ymax1;
    plrng.ymin2 = pldef.ymin2;
    plrng.ymax2 = pldef.ymax2;
}

/*
 * LOADDEFV: load variables defined in defv or command line
 */

local void loaddefv(void)
{
    vis = getparam("vis");                       /* get file names          */
    files = splitline(vis,',',&nfiles);          /* split file names        */
    yaxis = getparam("yaxis");                   /* y-axis of plot          */
    outfile = getparam("out");                   /* output file             */
}

/*
 * BLPLOT: baseline plot
 */

local void blplot(panelptr p)
{
    
    float xs,ys;
    int i,k,npanel,a1,a2,cind;
    char line[256], title[36], ytitle[36];
    recordptr r;

    (*p).xwld[0] = plrng.xmin;
    (*p).xwld[1] = plrng.xmax;

    if (strcmp(yaxis,"amp")==0) {
        (*p).ywld[0] = plrng.ymin1;
        (*p).ywld[1] = plrng.ymax1;
        strcpy(ytitle,"Amplitude");
    }
    if (strcmp(yaxis,"pha")==0) {
        (*p).ywld[0] = plrng.ymin2;
        (*p).ywld[1] = plrng.ymax2;
        strcpy(ytitle,"Phase");
    }

    a1 = (*p).bl / 256;                         /* antenna numbers          */
    a2 = (*p).bl - 256*a1;
    sprintf(title,"%2d-%2d",a1,a2);             /* baseline name            */

    cpgsvp( (*p).xdev[0],(*p).xdev[1],(*p).ydev[0],(*p).ydev[1]);
    cpgswin((*p).xwld[0],(*p).xwld[1],(*p).ywld[0],(*p).ywld[1]);

    cpgslw(1);
    cpgsch(0.6);
    cpgsci(1);                                  /* while for frame          */
    if ((*p).xlab == TRUE) {                    /* x-coordinage and label   */
            cpgbox("bncts", 0.0, 0, "", 0.0, 0);
            cpgmtxt("b",2.5,0.5,0.5,"UT [h]");
        } else {
            cpgbox("bcts", 0.0, 0, "", 0.0, 0);
        }
    if ((*p).ylab == TRUE) {                    /* y-coordinage and label   */
            cpgbox("", 0.0, 0, "bncts", 0.0, 0);
            cpgmtxt("l",2.5,0.5,0.5,ytitle);
        } else {
            cpgbox("", 0.0, 0, "bcts", 0.0, 0);
    }
    cpgsch(0.8);
    cpgslw(4);
    cpgsci(1);
    cpgmtxt("t",-1.2,0.95,1.0,title);

    cpgsch(1.0);
    cpgslw(7);
    for (r=toprec[a1-1][a2-1]; r!=NULL; r=(*r).next) {
        xs = (*r).ut;
        if (strcmp(yaxis,"amp")==0) {
            ys = (*r).amp;
        } else {
            ys = (*r).pha;
        }

          if (((*r).flag & MASK) != MASK) {
            if (((*r).flag & FLAG) == FLAG) {
                cpgsci(2);
                cpgpt(1,&xs,&ys,-1);
            } else {
	        cind = cindtab[(*r).souid];
		cpgsci(cind);
                cpgpt(1,&xs,&ys,-1);
            }
        }
    }
    cpgslw(1);
    cpgsch(1.0);
    cpgsci(1);
}

/*
 * GETRANGE: get range in world coordinate with some checks
 */

local int getrange(float *val1,float *val2,char ax)
{
    float x1,x2,y1,y2;
    char ch,buf[32];

    printf("\tClick the left/bottom  [manual edit: 'e' on window]\n");
    if (getwcinp(&x1,&y1,&ch) == 0) {
        if (ch == 'e') {
            printf("\t\tInput value: ");
            scanf("%s",buf);
            x1 = (float) atof(buf);
            y1 = x1;
        }
        printf("\tClick the right/top    [manual edit: 'e' on window]\n");
        if (getwcinp(&x2,&y2,&ch) == 0) {
            if (ch == 'e') {
                printf("\t\tInput value: ");
                scanf("%s",buf);
                x2 = (float) atof(buf);
                y2 = x2;
            }
            if (ax == 'x') {
                *val1 = MIN(x1,x2);
                *val2 = MAX(x1,x2);
            } else {
                *val1 = MIN(y1,y2);
                *val2 = MAX(y1,y2);
            }
            return(0);
        } else {
            printf("\tClick inside panels\n");
            return(-1);
        }
    } else {
        printf("\tClick inside panels\n");
        return(-1);
    }
}


/*
 * GETWCINP: get world coordinate in panel
 */

local int getwcinp(float *xw, float *yw, char *ch)
{
    float xc,yc,xd,yd,xd1,xd2,yd1,yd2,xw1,xw2,yw1,yw2;
    char buf[32];
    panelptr p,q;

    cpgqwin(&xw1,&xw2,&yw1,&yw2);                /* get world coord. setting */
    cpgqvp(0,&xd1,&xd2,&yd1,&yd2);               /* get view point setting   */
    cpgcurs(&xc,&yc,buf);                        /* get wld coord from mouse */
    xd = (xd2-xd1)/(xw2-xw1)*(xc-xw1) + xd1;     /* calc dev coord           */
    yd = (yd2-yd1)/(yw2-yw1)*(yc-yw1) + yd1;

    q = (panelptr) NULL;
    for (p=pan; p<pan+npan; p++){                /* panel where cursol is    */
        if ((xd > (*p).xdev[0]) && (xd < (*p).xdev[1]) &&
            (yd > (*p).ydev[0]) && (yd < (*p).ydev[1])) q = p;
    }
    if (q != (panelptr) NULL) {                  /* calc wld coord in panel  */
        *xw = ((*q).xwld[1]-(*q).xwld[0])/((*q).xdev[1]-(*q).xdev[0])*
            (xd-(*q).xdev[0])+(*q).xwld[0];
        *yw = ((*q).ywld[1]-(*q).ywld[0])/((*q).ydev[1]-(*q).ydev[0])*
            (yd-(*q).ydev[0])+(*q).ywld[0];
        *ch = tolower(buf[0]);
        return(0);
    } else {
        return(-1);
    }
}


/*
 * APPLYFLG: apply flag to records
 */

local void applyflg(flag flg)
{
    int i,a1,a2,*bl,nbl;
    recordptr r;

    bl = listbase(flg.type,flg.item,flg.nitem,&nbl);

    for (i=0; i<nbl; i++) {
        a1 = bl[i] / 256;
        a2 = bl[i] - 256*a1;
        for (r=toprec[a1-1][a2-1]; r!=NULL; r=(*r).next)
            if ((*r).ut > flg.tstart && (*r).ut < flg.tend)
                (*r).flag |= FLAG;
    }
    if (bl != (int *) NULL) free(bl);
}

/*
 * OUTFLAGS: output flag in miriad/select format
 */

local void outflags(void)
{
    int i,j,a1,a2,bl,h,m,s;
    float t;
    flagptr f;
    char line[256];
    stream outstr;

    if (nflags > 0) {
      if (! strnull(outfile)) outstr = fopen(outfile,"w");
      for (i=0; i<nflags; i++) {
        printflag(flags[i],stdout);
        if (! strnull(outfile)) printflag(flags[i],outstr);
      }
      if (! strnull(outfile)) fclose(outstr);
    } else {
      if (! strnull(outfile)) printf("No output because of no flag.\n");
    }
}

/*
 * PRINGFLAG: pring flag in miriad/select format
 */

local void printflag(flag flg, stream unit)
{
    int j,a1,a2,bl,h,m,s;
    float t;
    char utstart[9],utend[9],line[256];
    FILE *outstr;

    t = flg.tstart;
    if (t <  0.0) t += 24.0;
    if (t > 24.0) t -= 24.0;
    h = floor(t);
    m = floor((t - h) * 60.0);
    s = floor((((t - h) * 60.0) - m)*60);
    sprintf(utstart,"%02d:%02d:%02d",h,m,s);

    t = flg.tend;
    if (t <  0.0) t += 24.0;
    if (t > 24.0) t -= 24.0;
    h = floor(t);
    m = floor((t - h) * 60.0);
    s = floor((((t - h) * 60.0) - m)*60);
    sprintf(utend,"%02d:%02d:%02d",h,m,s);

    if (flg.type == 'a') {
        sprintf(line,"select=time(%s,%s)",utstart,utend);
	if (unit == stdout) fprintf(unit,"\t\t");
	fprintf(unit,"%s\n",line);
    } else if (flg.type == 't') {
        for (j=0; j<flg.nitem; j++) {
	    sprintf(line,"select=ant(%d),time(%s,%s)",flg.item[j],utstart,utend);
	    if (unit == stdout) fprintf(unit,"\t\t");
	    fprintf(unit,"%s\n",line);
	}
    } else if (flg.type == 'b') {
        for (j=0; j<flg.nitem; j++) {
	  a1 = flg.item[j] / 256;
	  a2 = flg.item[j] - 256*a1;
	  sprintf(line,"select=ant(%d)(%d),time(%s,%s)",a1,a2,utstart,utend);
	  if (unit == stdout) fprintf(unit,"\t\t");
	  fprintf(unit,"%s\n",line);
	}
    }
}

/*
 * LOADDATA: load data from miriad dataset to hkmiriad structures.
 */

local void loaddata(void)
{

#define MAXNAME 9

    int unit;
    int flg[MAXCHAN];
    float data[2*MAXCHAN];
    double pre[5],re,im,tmin;
    int nr,nc,ns,nb,na,b,bl[MAXBASE],a1,a2,an[MAXANT],nbytes;
    char s[MAXNAME],sour[MAXSOU][MAXNAME];
    recordptr r;
    int f,i,j,k,n,c;

    nr = 0;                                      /* initialize record, chan */
    nc = 0;                                      /* source, and bl counters */
    ns = 0;
    nb = 0;
    tmin = 1.0e30;

    for (f=0; f<nfiles; f++) {                   /* read over all files     */
        uvopen_c(&unit,files[f],"old");          /* open miriad data        */
        n = 1;                                   /* initialize for loop     */
        while (n > 0) {                          /* loop over records       */
            uvread_c(unit,pre,data,flg,MAXCHAN,&n); /* read data            */
            c = 0;
            for (i=0; i<n; i++)
                if (flg[i] == 1) c++;            /* if not flagged,count it */

            if (c>0) {
                nr++;                            /* update record counter   */
                nc = MAX(nc,n);                  /* find max for chan count */
                tmin = MIN(tmin,pre[2]);         /* min time                */
                b = (int) pre[3];                /* get baseline number     */
                i = 0;                           /* search through bl list  */
                while (i<nb && bl[i] != b) i++;
                if (i == nb) {                   /* if not in list, add it  */
                    bl[nb] = b;
                    nb++;
                }
                uvgetvra_c(unit,"source",s,sizeof(s)); /* get source name   */
                i = 0;                           /* search thrgh sour list  */
                while (i<ns && !streq(sour[i],s)) i++;
                if (i == ns) {                   /* if not in list, add it  */
                    strcpy(sour[ns],s);
                    ns++;
                }
            }
        }
        uvclose_c(unit);                         /* close miriad data       */
    }
    na = 0;                                      /* make ant list from bl   */
    for (i=0; i<nb; i++) {                       /* loop over baselines     */
        a1 = bl[i] / 256;                        /* antennas in this bl     */
        a2 = bl[i] - 256*a1;
        k = 0;                                   /* search through ant list */
        while (k<na && an[k] != a1) k++;         /* if not in list yet,     */
        if (k == na) {                           /* add it.                 */
            an[na] = a1;
            na++;
        }
        k = 0;
        while (k<na && an[k] != a2) k++;
        if (k == na) {
            an[na] = a2;
            na++;
        }
    }
    nbytes = nr * sizeof(record);
    printf("Need %d bytes of memory to read data\n",nbytes);
    rec = (recordptr) allocate(nbytes);          /* mem for records     */
    j = 0;
    for (f=0; f<nfiles; f++) {                   /* read over all files     */
        uvopen_c(&unit,files[f],"old");          /* open miriad data        */
        n = 1;                                   /* initialize for loop     */
        while (n > 0) {                          /* loop over records       */
            uvread_c(unit,pre,data,flg,MAXCHAN,&n); /* read data            */
            c = 0;
            re = 0.0;
            im = 0.0;
            for (i=0; i<n; i++)                  /* average over channels   */
                if (flg[i] == 1) {
                    re += data[2*i  ];
                    im += data[2*i+1];
                    c++;
                }
            if (c > 0) {
                r = rec + j;
                re /= (double) c;
                im /= (double) c;
                (*r).amp = sqrt(re*re + im*im);
                (*r).pha = atan2(re,im) * 180.0/PI;
                (*r).ut  = (float) (pre[2] - floor(tmin-0.5) -0.5)*24.0;
                                                 /* calc ut from julian date*/
                (*r).bl  = pre[3];               /* baseline number         */
                (*r).next= NULL;                 /* init next pointer       */
                uvgetvra_c(unit,"source",s,sizeof(s)); /* find source id    */
                k = 0;
                while (k<ns && !streq(sour[k],s) ) k++;
                (*r).souid = k;
                (*r).flag = NONE;                /* initialize flag         */
                j++;
            }
        }
        uvclose_c(unit);                         /* close miriad data       */
    }
    tra.nrec  = nr;                              /* set par common in track */
    tra.nchan = nc;
    tra.nsour = ns;
    for (i=0; i<ns; i++) strcpy(tra.sour[i],sour[i]);
    tra.nbase = nb;
    for (i=0; i<nb; i++) tra.base[i] = bl[i];
    tra.nant = na;
    for (i=0; i<na;  i++) tra.ant[i] = an[i];

}

/*
 * SHOWINFO: show track information
 */

local void showinfo(void)
{
    int i,a1,a2;
    char line[256];

    printf("\n\tNum of antennas  = %d",tra.nant);
    for (i=0;i<tra.nant;i++) {
        if (i % 15 == 0) printf("\n\t\t");
        printf("%d ",tra.ant[i]);
    }
    printf("\n");

    printf("\tNum of baselines = %d",tra.nbase);
    for (i=0;i<tra.nbase;i++) {
        if (i % 8 == 0) printf("\n\t\t");
        a1 = tra.base[i] / 256;
        a2 = tra.base[i] - 256*a1;
        printf("%2d-%2d ",a1,a2);
    }
    printf("\n");

    printf("\tNum of sources   = %d\n\t\t",tra.nsour);
    for (i=0;i<tra.nsour;i++)
        printf("%s ",tra.sour[i]);
    printf("\n");

    printf("\tNum of flags = %d\n",nflags);
    for (i=0;i<nflags;i++) {
        printflag(flags[i],stdout);
    }
    printf("\n");

    cpgsvp(0.1,0.9,0.1,0.9);                    /* show sourname on pg window*/
    cpgslw(8);
    for (i=0;i<tra.nsour;i++) {
      cpgsci(cindtab[i]);
      cpgmtxt("t",-1.1*i,0.0,0.0,tra.sour[i]);
    }
    cpgslw(1);
}

/*
 * SHOWHELP: show help
 */

local void showhelp(void)
{
    int i,a1,a2;
    char line[256];

    printf("\n");
    printf("\tHelp:\n");
    printf("\t\t[P]lot     : Select antennas/baselines and plot\n");
    printf("\t\t[X]oom     : Zoom in x-axis\n");
    printf("\t\t[Y]oom     : Zoom in y-axis\n");
    printf("\t\t[D]efault  : Default range [depends on selected sources]\n");
    printf("\t\t[F]lag     : Flag data\n");
    printf("\t\t[U]ndo     : Undo last flag\n");
    printf("\t\t[C]ycle    : Cycle y-axis [amp <-> pha]\n");
    printf("\t\t[S]ource   : Select and mask sources\n");
    printf("\t\t[I]nfo     : Show track information\n");
    printf("\t\t[H]elp     : Show help\n");
    printf("\t\t[Q]uit     : Quit and output flags\n");
    printf("\n");
}

/*
 * SEPITEMS: separate items, i.e. ant/bass, from line, check their presenses
 */

local int *sepitems(string line,int *item, int *nitem, char *type)
{
    int nelem,nit,*it;
    char **elem,**a,t;
    int i,j,k,n,b,a1,a2,s;

    nit = *nitem;                               /* initialize param. return */
    it = item;                                  /* prev if invalid input    */
    t = *type;

    elem = splitline(line,',',&nelem);          /* split line               */
    if (line[0] == 't') {                       /* items are telescopes     */
        nit = 0;
        for (i=1; i<nelem; i++) {
            a1 = atoi(elem[i]);                 /* count num of ant in line */
            if (getantid(a1) >= 0) nit++;       /* if a1 exists, count it   */
        }
	if (nit > 0) {
	    t = 't';                            /* set item type            */
	    it = (int *)allocate(nit * sizeof(int)); /* alloc memory        */
	    k = 0;
	    for (i=1; i<nelem; i++) {
	        a1 = atoi(elem[i]);             /* this antenna             */
		if (getantid(a1) >= 0) {        /* if exists in track       */
		    it[k] = a1;
		    k++;
		}
	    }
	    if (item != (int *) NULL) free(item);
	} else {
	    nit = *nitem;
	}
    } else if (line[0] == 'b') {                /* items are baselines      */

        nit = 0;                                /* count num of baselines   */
        for (i=1; i<nelem; i++) {
            a = splitline(elem[i],'-',&n);
            if (n == 2) {
                a1 = atoi(a[0]);
                a2 = atoi(a[1]);
                if (a1 != a2) {
                    if (a1 < a2) b = 256*a1+a2;
                    if (a1 > a2) b = 256*a2+a1;
                    if (getbaseid(b) >= 0) nit++;/* if b exists, count it   */
                }
            }
            free(a);
        }
	if (nit > 0) {
	    t = 'b';
	    it = (int *) allocate(nit * sizeof(int)); /* alloc memory       */
	    k = 0;
	    for (i=1; i<nelem; i++) {
	        a = splitline(elem[i],'-',&n);
		if (n == 2) {
		    a1 = atoi(a[0]);
		    a2 = atoi(a[1]);
		    if (a1 != a2) {
		        if (a1 < a2) b = 256*a1+a2;
			if (a1 > a2) b = 256*a2+a1; /* this baseline        */
			if (getbaseid(b) >= 0) { /* if exist in track       */
			    it[k] = b;           /* add it to list          */
			    k++;
			}
		    }
		}
		free(a);
	    }
	    if (item != (int *) NULL) free(item);
	} else {
	    nit = *nitem;
	}
    } else if (line[0] == 'a') {                /* selected all             */
        t = 'a';
        nit = 0;
        it = (int *) NULL;
	if (item != (int *) NULL) free(item);
    }
    free(elem);

    *nitem = nit;
    *type = t;
    return(it);

}

/*
 * LISTBASE: list baseline numbers that include selected items
 */

local int *listbase(char type, int *a, int na, int *nb)
{
    int i,j,k,a1,a2,b,n,*bl;

    if (type == 't') {                          /* all bl with selected ant */
        n = 0;
        for (i=0; i<na; i++) {                  /* count num of baselines   */
            a1 = a[i];
            for (j=0; j<tra.nant; j++) {
                a2 = tra.ant[j];
                if (a1 != a2) {
                    if (a1 < a2) b = 256*a1+a2;
                    if (a1 > a2) b = 256*a2+a1;
                    if (getbaseid(b) >= 0) n++;
                }
            }
        }
        *nb = n;
        bl = (int *) allocate(*nb * sizeof(int));
        k = 0;
        for (i=0; i<na; i++) {                  /* store base in memory     */
            a1 = a[i];
            for (j=0; j<tra.nant; j++) {
                a2 = tra.ant[j];
                if (a1 != a2) {
                    if (a1 < a2) b = 256*a1+a2;
                    if (a1 > a2) b = 256*a2+a1;
                    if (getbaseid(b) >= 0) {
                        bl[k] = b;
                        k++;
                    }
                }
            }
        }
    } else if (type == 'b') {                   /* list all selected bls    */
        *nb = na;
        bl = (int *) allocate(*nb * sizeof(int));
        for (i=0; i<*nb; i++) bl[i] = a[i];
    } else if (type == 'a') {                   /* list all baselines       */
        *nb = tra.nbase;
        bl = (int *) allocate(*nb * sizeof(int));        
        for (i=0; i<*nb; i++) bl[i] = tra.base[i];
    } else {
      bl = (int *) NULL;
    }
    return(bl);                                 /* return bl list           */
}

/*
 * LINKBREC: link baselines and recoreds
 */

local void linkbrec(void)
{
    int ma,bl,a1,a2,i,j;
    recordptr r,bp[MAXANT][MAXANT];

    ma = 0;
    for (i=0; i<tra.nant; i++) ma = MAX(ma,tra.ant[i]);
                                                /* find maximum ant number  */
    for (i=0;i<ma;i++)
        for (j=0;j<ma;j++) {                    /* initialize bl hashtable  */
            toprec[i][j] = (recordptr) NULL;
            bp[i][j] = toprec[i][j];
        }
        
    for (r=rec; r<rec+tra.nrec; r++) {          /* loop over records        */
        bl = (*r).bl;                           /* find baseline number, and*/
        a1 = bl / 256;                          /* antenna numbers          */
        a2 = bl - 256*a1;
        if (toprec[a1-1][a2-1] == NULL) {       /* first record in this bl, */
            toprec[a1-1][a2-1] = r;             /* link to it from the top  */
        } else {                                /* if not the first         */
            (*bp[a1-1][a2-1]).next = r;         /* link from prev. rec.     */
        }
        bp[a1-1][a2-1] = r;                     /* last record is updated   */
    }
}

/*
 * SETMULTWIN: set window positions for multiple plots
 */

local panelptr setmultwin(int np)
{
    panelptr p,q;
    float tm,bm,rm,lm,vs,hs;
    int nc,nr;
    int r,c,k;

    p = (panelptr) allocate(np * sizeof(panel));
                                                /* mem for panel param.     */
    nc = (np-1)/7 + 1;                          /* num. of column           */
    nr = np/nc;                                 /* num. of rows             */
    if (np > nc*nr) nr = nr + 1;

    tm = 0.05;                                  /* top margin               */
    bm = 0.05;                                  /* bottom margin            */
    lm = 0.05;                                  /* left margin              */
    rm = 0.00;                                  /* right margin             */

    vs = (1.0 -tm -bm) / (float) nr;            /* verti. max space of panel*/
    hs = (1.0 -rm -lm) / (float) nc;            /* horiz. max space of panel*/

    for (k=0; k<np; k++) {
        c = k/nr;                               /* column number of panel   */
        r = nr - (k-c*nr) -1;                   /* row number of panel      */
        q = p + k;                              /* this panel               */
        (*q).xdev[0] = lm + hs * c;             /* set panel frames         */
        (*q).xdev[1] = (*q).xdev[0] + hs * 0.95;
        (*q).ydev[1] = bm + vs * (r+1);
        (*q).ydev[0] = (*q).ydev[1] - vs * 0.95;
        if (r == 0 || k == np-1) {              /* boolian for x-label      */
            (*q).xlab = TRUE;
        } else {
            (*q).xlab = FALSE;
        }
        if (c == 0) {                           /* boolian for y-label      */
            (*q).ylab = TRUE;
        } else {
            (*q).ylab = FALSE;
        }
    }
    return(p);
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

/*
 * GETANTID: get antenna id
 */

local int getantid(int an)
{
    int i,k;

    i = -1;
    for (k=0; k<tra.nant; k++)
        if (tra.ant[k] == an) i = k;
    return(i);
}

/*
 * GETBASEID: get baseline id
 */

local int getbaseid(int bl)
{
    int i,k;

    i = -1;
    for (k=0; k<tra.nbase; k++)
        if (tra.base[k] == bl) i = k;
    return(i);
}
