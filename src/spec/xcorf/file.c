#include "xcorf.h"

#include <ctype.h>
#include <math.h>

#ifndef Null
#define Null '\0'
#endif

typedef struct lines {
    char name[20];
    char transition[30];
    double freq;
    double intensity;
    struct lines *next;
} LINES;

static double maxIntensity = -1.0;
static double maxLogIntensity = -1.0;

static LINES *LinesHead = (LINES *)NULL;
static LINES *LinesTail = (LINES *)NULL;
static LINES RestFqs[16];
static short InitRestFqs = 1;

/***********************************************************************/
#ifdef __STDC__
static void addEntry(const char *name, const char *trans, double freq, double intensity)
#else
static void addEntry(name, trans, freq, intensity)
const char *name;
const char *trans;
double freq;
double intensity;
#endif /*__STDC__*/
{
    LINES *ptr, *lptr, *last;

    ptr = XtNew(LINES);
    (void)strcpy(ptr->name, name);
    (void)strcpy(ptr->transition, trans);
    ptr->freq = freq;
    if (intensity > 0) {
      ptr->intensity = 5 + log(intensity);
      if (ptr->intensity < -5)
        ptr->intensity = -5;
    } else {
      ptr->intensity = -10;
    }
    ptr->next = (LINES *)NULL;

    /*  First, test the easy case: no entries. */
    if (LinesHead == (LINES *)NULL) {
      LinesHead = ptr;
      LinesTail = ptr;
      return;
    }

    /*  Next, see if the frequency is greater than the last entry. */
    if (ptr->freq > LinesTail->freq) {
      LinesTail->next = ptr;
      LinesTail = ptr;
      return;
    }

    /*  Next, see if the frequency is less than the first entry. */
    if (ptr->freq < LinesHead->freq) {
      ptr->next = LinesHead;
      LinesHead = ptr;
      return;
    }
    /*
     *  Alas, the input frequency is somewhere between the first and
     *  the last entry.  Do the hard job of inserting this inside the
     *  list (sorted by increasing frequency).
     */
    last = LinesHead;
    for (lptr = LinesHead; lptr->next != (LINES *)NULL; lptr = lptr->next) {
      if (ptr->freq < lptr->freq)
        break;
      last = lptr;
    }

    ptr->next = last->next;
    last->next = ptr;

    if (Global->debug > 1)
      (void)printf("Had to insert the hard way for freq = %G\n", freq);

    return;
}

/***********************************************************************/
#ifdef __STDC__
static void clearEntry(void)
#else
static void clearEntry()
#endif /*__STDC__*/
{
    LINES *ptr, *next;

    next = (LINES *)NULL;
    for (ptr = LinesHead; ptr != (LINES *)NULL; ptr = next) {
      next = ptr->next;
      XtFree((char *)ptr);
    }

    LinesHead = (LINES *)NULL;
    LinesTail = (LINES *)NULL;
    maxIntensity = -1.0;

    return;
}

/*  Returns number of frequency lines (not file lines) read. */
/***********************************************************************/
#ifdef __STDC__
static int readFile(String linefile)
#else
static int readFile(linefile)
String linefile;
#endif /*__STDC__*/
{
    char *ptr, *nptr;
    char uline;
    char name[20];
    char trans[30];
    char string[BUFSIZ];
    register int i;
    int lastlines, numlines;
    double freq, intensity;
    double fmin, fmax;          /* Range of allowed frequencies (GHz). */
    FILE *fp;

    fmin = Global->freqmin;
    fmax = Global->freqmax;

    numlines = 0;

    /*  Try to open the input file locally and in $MIRCAT. */
    if ((fp = fopen(linefile, "r")) == (FILE *)NULL) {
      if ((ptr = getenv("MIRCAT")) == NULL) {
        (void)sprintf(string, "\
Could not find the environment variable MIRCAT.\n\
Trouble opening the file [%s]", linefile);
        Warning(string);
        return(-1);
      }
      if ((nptr = strrchr(linefile, '/')) == (char *)NULL)
        nptr = linefile;
      else
        nptr++;
      (void)sprintf(string, "%s/%s", ptr, nptr);
      if ((fp = fopen(string, "r")) == (FILE *)NULL) {
        (void)sprintf(string, "Trouble opening the file [%s]", linefile);
        Warning(string);
        return(-1);
      }
    }

    /*  Open successful; skip first 8 lines. */

    for (i = 0; i < 8; i++) {
      if ((ptr = fgets(string, BUFSIZ, fp)) == NULL) {
        (void)sprintf(string, "Trouble reading header lines of file [%s]",
          linefile);
        Warning(string);
        break;
      }
    }

    if (ptr == NULL) {                    /*  File empty or incorrect. */
      (void)fclose(fp);
      return(-1);
    }

    /* Read the file until the full frequency range is covered. */

    lastlines = numlines;
    while ((ptr = fgets(string, BUFSIZ, fp)) != NULL) {
      uline = *ptr++;
      freq = atof(ptr) / 1000.0;                        /* MHz -> GHz. */

      if (freq < fmin)        /* Haven't got to the minumum value yet. */
        continue;

      if (freq > fmax)       /* Have passed the maxumum allowed value. */
        break;

      (void)strcpy(name, "U");
      trans[0] = Null;
      if ((uline != 'U') && (uline != 'u')) {
        nptr = ptr = string + 18;      /* The start of the freq. name. */
        while (isspace(*ptr) && (*ptr != '\n')) ptr++;
        i = 11 - (ptr - nptr);
        if (i > 0) {
          (void)strncpy(name, ptr, i);
          name[i] = Null;
          for (ptr = &name[i-1]; ((ptr >= name) && isspace(*ptr)); ptr--)
            *ptr = Null;
        }

        nptr = ptr = string + 29;      /* The start of the freq. name. */
        while (isspace(*ptr) && (*ptr != '\n')) ptr++;
        i = 28 - (ptr - nptr);
        if (i > 0) {
          (void)strncpy(trans, ptr, i);
          trans[i] = Null;
          for (ptr = &trans[i-1]; ((ptr >= trans) && isspace(*ptr)); ptr--)
            *ptr = Null;
        }
      }

      intensity = -1;
      if (strlen(string) > (size_t)65) {
        ptr = string + 59;       /*  Skip to start of intensity value. */
        while (isspace(*ptr) && (*ptr != '\n')) ptr++;
        if (isdigit(*ptr) && (*ptr != '\n'))
          intensity = atof(ptr);            /* Get relative intensity. */
      }

      addEntry(name, trans, freq, intensity);
      numlines++;
      if (intensity > maxIntensity)
        maxIntensity = intensity;
    }                                           /* while in file loop. */

    if (Global->debug > 1)
      (void)printf("[%d] lines read from the file [%s].\n",
        (numlines - lastlines), linefile);

    (void)fclose(fp);                               /* Close the file. */

    if (maxIntensity > 0)
      maxLogIntensity = 5 + log(maxIntensity) - 0.2;
    else
      maxLogIntensity = -1;

    return(numlines);
}

/***********************************************************************/
#ifdef __STDC__
static void addRFEntry(int which, double freq, double intensity)
#else
static void addRFEntry(which, freq, intensity)
int which;
double freq;
double intensity;
#endif /*__STDC__*/
{
    LINES *ptr;

    if ((which < 0) || (which >= 16))
      return;

    ptr = &RestFqs[which];
    ptr->freq = freq;
    ptr->intensity = (intensity >= 0) ? intensity : -1;
    (void)strcpy(ptr->name, "none");                 /* Not used here. */
    (void)strcpy(ptr->transition, "none");           /* Not used here. */
    ptr->next = (LINES *)NULL;                       /* Not used here. */

    return;
}

/*
 *  Returns the maximum intensity found from the last file(s) read.
 *  If no files have been read successfully, -1 is returned.
 */
/***********************************************************************/
#ifdef __STDC__
double getMaxIntensity(void)
#else
double getMaxIntensity()
#endif /*__STDC__*/
{
    return(maxLogIntensity);
}

/*
 *  Returns first entry with frequency greater than `freq' (GHz);
 *  input and output frequency values passed through call statement.
 *  If found, name, transition, and intensity are also returned.
 *  Routine returns 1 if successful; 0 on error.
 */
/***********************************************************************/
#ifdef __STDC__
int getEntry(XtPointer *marker, double *freq, char *name, char *trans, double *intensity)
#else
int getEntry(marker, freq, name, trans, intensity)
XtPointer *marker;
double *freq;
char *name;
char *trans;
double *intensity;
#endif /*__STDC__*/
{
    register LINES *ptr;
    LINES *start;

    if (*marker == (XtPointer)NULL)
      start = LinesHead;
    else
      start = (LINES *)(*marker);

    for (ptr = start; ptr != (LINES *)NULL; ptr = ptr->next)
      if (ptr->freq > *freq) break;

    *marker = (XtPointer)ptr;
    if (ptr == (LINES *)NULL)
      return(0);

    (void)strcpy(name, ptr->name);
    (void)strcpy(trans, ptr->transition);
    *intensity = ptr->intensity;
    *freq = ptr->freq;

    return(1);
}

/*
 *  This routine tries to find the nearest matching line to the input
 *  value of frequency (GHz) within the range provided (MHz).  If a
 *  match is found, it is returned along with its name, transition,
 *  and intensity.  The routine returns 1 if successful in finding a
 *  match; 0 otherwise.
 */
/***********************************************************************/
#ifdef __STDC__
int nearestEntry(double *freq, double range, char *name, char *trans, double *intensity)
#else
int nearestEntry(freq, range, name, trans, intensity)
double *freq;
double range;
char *name;
char *trans;
double *intensity;
#endif /*__STDC__*/
{
    double minval, maxval;
    double mdiff, ldiff;
    LINES *less, *more;
    register LINES *ptr;

    range /= 1000.0;
    minval = *freq - (range / 2.0);
    maxval = minval + range;
    less = (LINES *)NULL;
    more = (LINES *)NULL;
    for (ptr = LinesHead; ptr != (LINES *)NULL; ptr = ptr->next) {
      if (ptr->freq < minval)
        continue;
      if (ptr->freq > maxval)
        break;
      if (ptr->freq < *freq) {
        less = ptr;
      } else if (more == (LINES *)NULL) {
        more = ptr;
        break;
      }
    }

    if ((less == (LINES *)NULL) && (more == (LINES *)NULL)) {
      return(0);
    } else if ((less != (LINES *)NULL) && (more == (LINES *)NULL)) {
      ptr = less;
    } else if ((less == (LINES *)NULL) && (more != (LINES *)NULL)) {
      ptr = more;
    } else {
      ldiff = *freq - less->freq;
      mdiff = more->freq - *freq;
      ptr = (mdiff > ldiff) ? less : more;
    }

    (void)strcpy(name, ptr->name);
    (void)strcpy(trans, ptr->transition);
    *intensity = ptr->intensity;
    *freq = ptr->freq;

    return(1);
}

/***********************************************************************/
#ifdef __STDC__
void setInputFile(String filename, Boolean addon)
#else
void setInputFile(filename, addon)
String filename;
Boolean addon;
#endif /*__STDC__*/
{
    char errmsg[256];

    if (Global->debug > 0)
      (void)printf("Input file to be loaded: [%s]\n", filename);

    if (addon != True)
      clearEntry();

    if (readFile(filename) == 0) {
      (void)sprintf(errmsg,
        "Did not read any useful information from the file:\n[%s]\n", filename);
      Warning(errmsg);
    }

    if (Global->debug > 1)
      (void)printf("Max intensity/log = [%G] [%G]\n",
        maxIntensity, maxLogIntensity);

    return;
}

/***********************************************************************/
#ifdef __STDC__
void resetAllRestFQ(void)
#else
void resetAllRestFQ()
#endif /*__STDC__*/
{
    register int j;

    for (j = 0; j < 16; j++)
      addRFEntry(j, 0.0, -1.0);

    return;
}

/*
 *  This routine returns the restfqs entry (0..7) for the input
 *  sideband.  It returns (along with a return status of 1) the
 *  frequency (GHz) associated with that line if it exists.  If
 *  no restfq has yet been assigned to the particular entry, then
 *  the current (Global) restfreq value is returned along with a
 *  status of 0; errors also generate a return of 0.
 */
/***********************************************************************/
#ifdef __STDC__
int getRestFQ(int which, Boolean isusb, double *freq)
#else
int getRestFQ(which, isusb, freq)
int which;       /* [0..7] */
Boolean isusb;
double *freq;
#endif /*__STDC__*/
{
    register LINES *ptr;

    if (InitRestFqs == 1) {     /* If necessary, initialize the array. */
      InitRestFqs = 0;
      resetAllRestFQ();
    }

    *freq = Global->restfreq;

    if ((which < 0) || (which >= Global->mode))
      return(0);

    if ((isusb == True) && (Global->option == True))
      which += 8;
    ptr = &RestFqs[which];

    if (ptr->intensity < 0)
      return(0);

    *freq = ptr->freq;

    return(1);
}

/***********************************************************************/
#ifdef __STDC__
void setRestFQ(int which, Boolean isusb, double freq)
#else
void setRestFQ(which, isusb, freq)
int which;
Boolean isusb;
double freq;
#endif /*__STDC__*/
{
    if (InitRestFqs == 1) {     /* If necessary, initialize the array. */
      InitRestFqs = 0;
      resetAllRestFQ();
    }

    if ((which >= 0) && (which < 8)) {
      if ((isusb == True) && (Global->option == True))
        which += 8;
      if (freq > 0)
        addRFEntry(which, freq, 1.0);
      else
        addRFEntry(which, 0.0, -1.0);
    }

    return;
}
