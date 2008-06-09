/****************************************************************************/
/* HKUVPLT.H: include file for hackmiriad routines.                         */
/* Written by Jin Koda, 2007                                                */
/****************************************************************************/

#define MAXSOU    128
#define MAXFLAG   256

#define PI         3.14159265358979323846

/*
 * TRACK: data common over a track.
 */

typedef struct _track {
    int nrec;               /* num. of records */
    int nchan;              /* max num. of channels per record */
    int nsour;              /* num. of sources in track */
    char sour[MAXSOU][9];   /* source names */
    int nbase;              /* num. of baselines */
    int base[MAXBASE];      /* baseline number */
    int nant;               /* num. of antennas */
    int ant[MAXANT];        /* antenna number */
} track, *trackptr;

/*
 * RECORD: data structure used to represent visibility records.
 */

typedef struct _record {
//    double u;             /* u-coordinate [nsec] */
//    double v;             /* v-coordinate [nsec] */
    float ut;               /* UT time [hour] */
    unsigned short bl;      /* baseline: bl = 256A1+A2 */ 
    unsigned short souid;   /* source id */
    float amp;              /* real part of visibility */
    float pha;              /* imaginary part of visibility */
    short flag;             /* flag */
    struct _record *next;   /* pointer to next record */
} record, *recordptr;

#define NONE 000
#define FLAG 001
#define MASK 002


/*
 * PANEL: parameter sets for panel plotting
 */

typedef struct _panel {
    int bl;                 /* baseline number: = 256A1+A2 */
    float xdev[2];          /* x range in device coordinate */
    float ydev[2];          /* y range in device coordinate */
    float xwld[2];          /* y range in world coordinate */
    float ywld[2];          /* y range in world coordinate */
    bool  xlab;             /* boolian for x-label */
    bool  ylab;             /* boolian for y-label */
} panel, *panelptr;

/*
 * FLAG: parameters to set flags
 */

typedef struct _flag {
    char type;              /* type: a: ant-base, b: base-base */
    int nitem;              /* number of antennas/baselines */
    int *item;              /* antenna or baseline number */
    float tstart;           /* start time */
    float tend;             /* end time */
} flag, flagptr;

/*
 * PRANGE: parameters for plot
 */

typedef struct _prange {
    float xmin;             /* minimum of plot range in x-axis */
    float xmax;             /* maximum of plot range in x-axis */
    float ymin1;            /* minimum of plot range in y1-axis */
    float ymax1;            /* maximum of plot range in y1-axis */
    float ymin2;            /* minimum of plot range in y2-axis */
    float ymax2;            /* maximum of plot range in y2-axis */
} prange;

/*
 * PARAMETERS
 */

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
string out;                      /* output file name */
