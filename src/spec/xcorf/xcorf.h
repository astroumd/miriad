#ifndef XCORF_H
#define XCORF_H

#include <stddef.h>
#include <stdlib.h>
#include <stdio.h>

#include <Xm/Xm.h>

#include "declare.h"                      /* Extern code declarations. */

#include "version.h"

#define CKMS 299792.458

/* ---------- Definition of Correlator specific parameters. ---------- */

/*
 * |               |                 |                 |               |
 * |      LSB      |<===== LO2 =====>|<===== LO2 =====>|      USB      |
 * ---------------------------------------------------------------------
 * ^               ^                 ^                 ^               ^
 * CORFMAX+BWMAX   CORFMIN-BWMAX    LO1    CORFMIN-BWMAX   CORFMAX+BWMAX
 */

#define LO2       1270                                          /* MHz */
#define CORFMAX    900                                          /* MHz */
#define CORFMIN     90                                          /* MHz */
#define BWMAX      100                                          /* MHz */
#define BWMIN     6.25                                          /* MHz */

#define IFMAX      900                                          /* MHz */
#define IFMIN       90                                          /* MHz */

#define NUMCHANS  1024
#define SYNTHSTEP (6.25 / (double)NUMCHANS)  /* 6.25 MHz / 1024 chans. */

/*
 *  SBMIN/MAX are the inner/outer most valid frequencies of
 *  any corf (in MHz).
 */

#define SBMIN   (LO2 + CORFMIN - BWMAX)
#define SBMAX   (LO2 + CORFMAX + BWMAX)

/*
 *  The structure defined below is used to keep all the "global"
 *  variables in one concise location.
 */

typedef struct {
    int debug;         /* Level used for printing messages (0 is off). */
    int numchans;  /* Number of channels available in cross/auto mode. */
    int mode;                                   /* The selection mode. */
    double freqmin;           /* The minimum allowed frequency in GHz. */
    double freqmax;           /* The maximum allowed frequency in GHz. */
    double restfreq;                     /* The rest frequency in GHz. */
    double iffreq;                         /* The IF frequency in MHz. */
    double vlsr;                                  /* The VLSR in km/s. */
    double doppler;       /* The "radio" doppler correction (1 - v/c). */
    double corfs[4];             /* The correlator frequencies in MHz. */
    double bw[4];                            /* The bandwidths in MHz. */
    Boolean usb;         /* Flag which is True for USB; False for LSB. */
    Boolean option;    /* Flag is True for Cross mode; False for Auto. */
    Boolean active[4];                 /* True if this corf is active. */
    Widget mainWindow;                       /* Widget of main window. */
} GLOBAL;

extern GLOBAL *Global;

#define HELPGENERAL   0
#define HELPAPPDEFS   1
#define HELPCMDLINE   2
#define HELPSLIDER    3
#define HELPCORF      4
#define HELPCHANS     5
#define HELPMISC      6
#define HELPINFILES   7
#define HELPOUTFILES  8
#define HELPSETUP     9
#define HELPINCORF   10
#define HELPMODE     11
#define HELPEXAMPLE  12
#define HELPDRAWING  13
#define HELPRESTFQS  14
#define MAXHELPITEMS 15     /* Always one plus the highest help entry. */

#define UNDEFINEDCOLOR 0
#define NOFLUXCOLOR    1
#define RESTFQSCOLOR   2
#define BIRDIECOLOR    3

#endif /* XCORF_H */
