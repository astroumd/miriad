/****************************************************************************/
/* HKMIRDEFS.H: include file for hackmiriad routines.                         */
/* Written by Jin Koda, 2007                                                */
/****************************************************************************/

#define MAXSOU    100

/*
 * TRACK: data common over a track.
 */

typedef struct _track {
    int nrec;               /* num. of records */
    int nchan;              /* max num. of channels per record */
    int nsour;              /* num. of sources in track */
    char source[MAXSOU][9]; /* source names */
    int nbase;              /* num. of baselines */
    int base[MAXBASE];      /* baseline number */
    int nant;               /* num. of antennas */
    int ant[MAXANT];        /* antenna number */
    double tstart;          /* track start time */
} track, *trackptr;

/*
 * RECORD: data structure used to represent visibility records.
 */

typedef struct _record {
    double u;               /* u-coordinate [nsec] */
    double v;               /* v-coordinate [nsec] */
    double time;            /* time [Julian date] */
    int bl;                 /* baseline: bl = 256A1+A2 */ 
    int souid;              /* source id */
    float amp;              /* real part of visibility */
    float pha;              /* imaginary part of visibility */
    bool flag;              /* flag */
    struct _record *next;   /* pointer to next record */
} record, *recordptr;

#define UU(x)     (((recordptr) (x))->u)
#define VV(x)     (((recordptr) (x))->v)
#define Time(x)   (((recordptr) (x))->time)
#define Bl(x)     (((recordptr) (x))->bl)
#define Souid(x)  (((recordptr) (x))->souid)
#define Amp(x)    (((recordptr) (x))->amp)
#define Pha(x)    (((recordptr) (x))->pha)
#define Next(x)   (((recordptr) (x))->next)
#define Flag(x)   (((recordptr) (x))->flag)

/*
 * PANEL: parameter sets for panel plotting
 */

typedef struct _panel {
    int pbl;                /* baseline number: = 256A1+A2 */
    float xdev[2];          /* x range in device coordinate */
    float ydev[2];          /* y range in device coordinate */
    float xwld[2];          /* y range in world coordinate */
    float ywld[2];          /* y range in world coordinate */
    bool  xlab;             /* boolian for x-label */
    bool  ylab;             /* boolian for y-label */
} panel, *panelptr;

#define Pbl(x)    (((panelptr) (x))->pbl)
#define Xdev(x)   (((panelptr) (x))->xdev)
#define Ydev(x)   (((panelptr) (x))->ydev)
#define Xwld(x)   (((panelptr) (x))->xwld)
#define Ywld(x)   (((panelptr) (x))->ywld)
#define Xlab(x)   (((panelptr) (x))->xlab)
#define Ylab(x)   (((panelptr) (x))->ylab)

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
