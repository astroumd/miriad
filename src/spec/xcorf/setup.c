#include "xcorf.h"

#include <ctype.h>
#include <time.h>
#include <math.h>

#ifndef Null
#define Null '\0'
#endif

#define MAXSTRING 256
#define MAXKEYS    10

typedef struct ckeys {
    String key;              /*  Malloc'd string holding the key name. */
    String Pvalue;               /* Malloc'd string holding the value. */
    char *value;                 /* Pointer to current spot in Pvalue. */
    struct ckeys *fwd;              /* Pointer to next ckey structure. */
} KEYS;

static KEYS *KeyHead = (KEYS *)NULL;
static KEYS *KeyTmp[MAXKEYS];

static int loadSetup ARGS((const char *file, const char *setup, int nest));

/************************************************************************/
#ifdef __STDC__
static char *getTime(void)
#else
static char *getTime()
#endif /*__STDC__*/
{
    char *format;
    static char string[MAXSTRING];
    time_t now;

    format = "%b %d %H:%M:%S %Z %Y";

    if (((now = time((time_t *)NULL)) == (time_t)-1) ||
        ((strftime(string, MAXSTRING, format, localtime(&now))) == (size_t)0))
      (void)strcpy(string, "Date unknown");

    return(string);

}

/************************************************************************/
#ifdef __STDC__
static void clearKeys(KEYS **thisList)
#else
static void clearKeys(thisList)
KEYS **thisList;
#endif /*__STDC__*/
{
    KEYS *t, *next;

    next = (KEYS *)NULL;
    for (t = *thisList; t != (KEYS *)NULL; t = next) {
      next = t->fwd;
      XtFree((char *)t->Pvalue);
      XtFree((char *)t->key);
      XtFree((char *)t);
    }

    *thisList = (KEYS *)NULL;

    return;
}


/************************************************************************/
#ifdef __STDC__
static void mergeKeys(KEYS **prevList, KEYS *thisList)
#else
static void mergeKeys(prevList, thisList)
KEYS **prevList;
KEYS *thisList;
#endif /*__STDC__*/
{
    KEYS *that, *this;

    /*
     *  See if this keyword already exists.  If so, replace the
     *  previous reference of this key with this version.  If it
     *  does not exist, make a copy and add it to the top of the
     *  previous list.
     */
    for (this = thisList; this != (KEYS *)NULL; this = this->fwd) {
      for (that = *prevList; that != (KEYS *)NULL; that = that->fwd)
        if (strcmp(this->key, that->key) == 0)
          break;

      if (that != (KEYS *)NULL) {
        XtFree((char *)that->Pvalue);
      } else {
        that = XtNew(KEYS);
        that->key = XtNewString(this->key);
        that->fwd = *prevList;
        *prevList = that;
      }

      that->Pvalue = XtNewString(this->Pvalue);
      that->value = (char *)that->Pvalue;
    }

    return;
}

/************************************************************************/
#ifdef __STDC__
static KEYS *getKey(const char *key)
#else
static KEYS *getKey(key)
const char *key;
#endif /*__STDC__*/
{
    char *ptr;
    KEYS *t;

    /*
     *  Search for the keyword.  If it is not found or the value list
     *  is exhausted, return a NULL pointer.
     */

    for (ptr = (char *)key; ((*ptr != Null) && isspace(*ptr)); ptr++)
      /* NULL */ ;

    for (t = KeyHead; t != (KEYS *)NULL; t = t->fwd)
      if (strcmp(ptr, t->key) == 0)
        break;

    return(t);
}

/*
 *  Returns 1 if string is name=xxx and xxx does not equal setup string;
 *  returns -1 if infinitely recursive; and returns 0 otherwise.
 */
/************************************************************************/
#ifdef __STDC__
static int ckeyput(char *string, const char *file, const char *setup, int nest)
#else
static int ckeyput(string, file, setup, nest)
char *string;
const char *file;
const char *setup;
int nest;
#endif /*__STDC__*/
{
    char *s, *key, *value;
    char errmsg[MAXSTRING];
    KEYS *t;

    s = string;
    while ((*s != Null) && isspace(*s))   /* Skip leading white space. */
      s++;

    if ((*s == Null) || (*s == '#')) {
      /* Quietly return on blank or comment lines. */
      return(0);
    }

    /* Get the key name. */
    key = s;
    while ((*s != Null) && (isalnum(*s) || (*s == '$'))) s++;
    if (*s == Null) {
      (void)sprintf(errmsg, "Warning: Badly formed parameter: [%s].\n", string);
      Warning(errmsg);
      return(0);
    }
    *s++ = Null;                    /* Properly terminate the keyword. */

    /* Now move to the value part of this keyword. */
    while ((*s != Null) && (isspace(*s) || (*s == '='))) s++;
    if (*s == Null) {
      (void)sprintf(errmsg, "Warning: Badly formed parameter: [%s].\n", string);
      Warning(errmsg);
      return(0);
    }

    value = s;
    while ((*s != Null) && (!isspace(*s) && (*s != '\n'))) s++;
    *s = Null;

    if (*value == Null) {
      (void)sprintf(errmsg,
        "Warning: No value associated with keyword: [%s].\n", string);
      Warning(errmsg);
      return(0);
    }
    /*
     *  Always ignore the name= keyword; but if the name is not the
     *  same as the input setup name, set a flag so that this setup
     *  will not be merged later.  Otherwise, just quietly return.
     */
    if (strcmp(key, "name") == 0)
      return(strcmp(value, setup) != 0);

    if (strcmp(key, "setup") == 0) {
      while ((value != (char *)NULL) && (*value != Null)) {
        if ((s = strchr(value, ',')) != (char *)NULL)
          *s++ = Null;

        /* Try to avoid infinite recursion. */
        if ((setup == (const char *)NULL) || (strcmp(setup, value) != 0)) {
          if (loadSetup(file, value, nest + 1) < 0)
            return(-1);
        }
        value = s;
      }
      return(0);
    }
    /*
     *  See if this keyword already exists.  If so, replace the
     *  previous reference of this key with this version.
     */
    for (t = KeyTmp[nest]; t != (KEYS *)NULL; t = t->fwd) {
      if (strcmp(key, t->key) == 0)
        break;
    }
    /*
     *  The three XtNew... steps call fatal error routines if
     *  they fail to allocate memory.  Hence, there is no need
     *  to test their return value.
     */
    if (t == (KEYS *)NULL) {
      t = XtNew(KEYS);
      t->key = XtNewString(key);
      t->fwd = KeyTmp[nest];
      KeyTmp[nest] = t;
    } else {
      XtFree((char *)t->Pvalue);
    }
    t->Pvalue = XtNewString(value);
    t->value = (char *)t->Pvalue;

    return(0);
}

/************************************************************************/
#ifdef __STDC__
static char *ckeyget(const char *key)
#else
static char *ckeyget(key)
const char *key;
#endif /*__STDC__*/
{
    char *r, *s;
    int depth;
    KEYS *t;
    Boolean quoted, more;

    if ((t = getKey(key)) == (KEYS *)NULL)
      return((char *)NULL);
    if ((t->value == (char *)NULL) || (*(t->value) == Null))
      return((char *)NULL);

    /*
     *  There is a value to return.  Scan through to the end of the
     *  parameter value.
     */

    for (s = t->value; ((*s != Null) && isspace(*s)); s++)
      /* NULL */ ;

    r = s;
    quoted = False;
    depth = 0;
    more = True;
    while ((*s != Null) && (more == True)) {
      if (*s == '\'') quoted = ((quoted == True) ? False : True);
      else if (quoted == False) {
        if (*s == '(') depth++;
        else if (*s == ')') depth--;
        else if (isspace(*s) || (*s == ','))
          more = (depth > 0) ? True : False;
      }
      if (more == True) s++;
    }
    t->value = (*s == Null) ? s : s + 1;
    *s = Null;
    return((*r == Null) ? (char *)NULL : r);
}
/***********************************************************************/
#ifdef __STDC__
static char *ckeya(const char *keyword, char *keydef)
#else
static char *ckeya(keyword, keydef)
const char *keyword;
char *keydef;
#endif /*__STDC__*/
{
    char *s;

    s = ckeyget(keyword);
    return((s == (char *)NULL) ? keydef : s);
}

/************************************************************************/
#ifdef __STDC__
static double ckeyd(const char *keyword, double value)
#else
static double ckeyd(keyword, value)
const char *keyword;
double value;
#endif /*__STDC__*/
{
    char *s;
    char temp[MAXSTRING];
    int dummy, expon;
    double darg, retval;

    if ((s = ckeyget(keyword)) == (char *)NULL)
      return(value);

    (void)sprintf(temp, "%s~~1", s);
    if ((sscanf(temp, "%lg~~%d", &darg, &dummy) == 2) && (dummy == 1)) {
      retval = darg;                /* Token was just a simple number. */
    } else if ((sscanf(temp, "%lg%*[dD]%d~~%d", &darg, &expon, &dummy) == 3) &&
               (dummy == 1)) {          /* Token was a Fortran double. */
      retval = darg;
      darg = expon;
      if (expon != 0)
        retval *= pow(10.0, darg);
    } else {
      (void)sprintf(temp,
        "Conversion error decoding parameter [%s=%s]\n", keyword, s);
      Warning(temp);
      return(value);
    }

    return(retval);
}

/************************************************************************/
#ifdef __STDC__
static int ckeyi(const char *keyword, int value)
#else
static int ckeyi(keyword, value)
const char *keyword;
int value;
#endif /*__STDC__*/
{
    char *s;
    char temp[MAXSTRING];
    int dummy, expon;
    int iarg;
    double darg, dval;

    if ((s = ckeyget(keyword)) == (char *)NULL)
      return(value);

    (void)sprintf(temp, "%s~~1", s);
    if ((sscanf(temp, "%i~~%d", &iarg, &dummy) == 2) && (dummy == 1))
      return(iarg);                /* Token was just a simple integer. */

    if ((sscanf(temp, "%lg~~%d", &darg, &dummy) == 2) && (dummy == 1)) {
      dval = darg;                     /* Token was a floating number. */
    } else if ((sscanf(temp, "%lg%*[dD]%d~~%d", &darg, &expon, &dummy) == 3) &&
               (dummy == 1)) {        /* Token had a Fortran exponent. */
      dval = darg;
      darg = expon;
      if (expon != 0)
        dval *= pow(10.0, darg);
    } else {
      (void)sprintf(temp,
        "Conversion error decoding parameter [%s=%s]\n", keyword, s);
      Warning(temp);
      return(value);
    }

    iarg = (dval >= 0) ? floor(dval + 0.5) : ceil(dval - 0.5);

    return(iarg);
}

/*
 *  This routine trys to open the setup file, and read the variables
 *  (recursively, if necessarily).  It returns 1 on error; -1 if the
 *  nesting level is >MAXKEYS; or 0 if all went okay.
 */
/************************************************************************/
#ifdef __STDC__
static int loadSetup(const char *file, const char *setup, int nest)
#else
static int loadSetup(file, setup, nest)
const char *file;
const char *setup;
int nest;
#endif /*__STDC__*/
{
    char *p, *s;
    char string[MAXSTRING];
    register int i;
    FILE *fp;
    KEYS *prevList;
    Boolean continued, merge;
    static Boolean firstTime = True;

    if (firstTime == True) {
      for (i = 0; i < MAXKEYS; i++)
        KeyTmp[i] = (KEYS *)NULL;
      firstTime = False;
    }

    if (nest >= MAXKEYS) {
      (void)sprintf(string, "Possible infinite nesting of setup [%s]?\n", file);
      Warning(string);
      return(-1);
    }

    if (nest == 0) {
      clearKeys(&KeyHead);
      prevList = KeyHead;
    } else {
      prevList = KeyTmp[nest-1];
    }

    if ((fp = fopen(file, "r")) == (FILE *)NULL) {
      (void)sprintf(string, "Failed to open setup file [%s].\n", file);
      Warning(string);
      return(1);
    }

    continued = False;
    while (fgets(string, MAXSTRING, fp) != (char *)NULL) {
      s = string;
      while ((*s != Null) && isspace(*s)) /* Skip leading white space. */
        s++;

      if ((*s == Null) || (*s == '#')) {
        /* Quietly continue on blank or comment lines. */
        continue;
      }

    /*
     *  Only continue if this line contains the command 'setup' and the
     *  name argument matches the string setup (as in "setup name=xxx ...)
     *  or if the previous line(s) did and are continued.
     */

      if ((continued == True) || (strncmp(s, "setup", 5) == 0)) {
        if (strncmp(s, "setup", 5) == 0) {
          s += 5;
          clearKeys(&KeyTmp[nest]);
          merge = True;
        }
        for (p = s; ((s = strchr(p, '=')) != (char *)NULL); p = s) {
          while ((*s != Null) && ((isspace(*s)) || (*s == '='))) s++;
          while ((*s != Null) && (!isspace(*s)) && (*s != '\n')) s++;
          if (*s != Null) *s++ = Null;
          if (merge == True) {
            if ((i = ckeyput(p, file, setup, nest)) > 0) {
              merge = False;
            } else if (i < 0) {
              return(-1);
            }
          }
        }
        while ((*p != Null) && isspace(*p)) p++;
        continued = (*p == '\\') ? True : False ;
        if ((continued == False) && (merge == True))
          mergeKeys(&prevList, KeyTmp[nest]);
      }
    }

    (void)fclose(fp);

    /*  In case any new items were merged, reassign list heads. */
    if (nest == 0)
      KeyHead = prevList;
    else
      KeyTmp[nest-1] = prevList;

    return(0);
}

/***********************************************************************/
#ifdef __STDC__
void parseFileList(String rsrcString)
#else
void parseFileList(rsrcString)
String rsrcString;
#endif /*__STDC__*/
{
    char *s;
    KEYS *save;
    Boolean addon;

    if (rsrcString == (String)NULL)
      return;

    save = KeyHead;
    KeyHead = XtNew(KEYS);
    KeyHead->fwd = (KEYS *)NULL;
    KeyHead->key = XtNewString("thiskey");
    KeyHead->Pvalue = XtNewString(rsrcString);
    KeyHead->value = (char *)KeyHead->Pvalue;

    addon = False;                  /* False only for the first entry. */
    while ((s = ckeyget("thiskey")) != (char *)NULL) {
      setInputFile(s, addon);
      addon = True;
    }

    clearKeys(&KeyHead);
    KeyHead = save;

    return;
}

/***********************************************************************/
#ifdef __STDC__
void parseBirdies(String birdieString)
#else
void parseBirdies(birdieString)
String birdieString;
#endif /*__STDC__*/
{
    register int j;
    int count;
    double *array;
    KEYS *save;

    if (birdieString == (String)NULL)
      return;

    save = KeyHead;
    KeyHead = XtNew(KEYS);
    KeyHead->fwd = (KEYS *)NULL;
    KeyHead->key = XtNewString("thiskey");
    KeyHead->Pvalue = XtNewString(birdieString);
    KeyHead->value = (char *)KeyHead->Pvalue;

    count = ckeyi("thiskey", 0);
    if (count > 0) {
      array = (double *)XtMalloc(sizeof(double) * count);
      for (j = 0; j < count; j++)
        array[j] = ckeyd("thiskey", 0.0);
      setBirdies(count, array);
      XtFree((char *)array);
    }

    clearKeys(&KeyHead);
    KeyHead = save;

    return;
}

/***********************************************************************/
#ifdef __STDC__
void extractResources(String rsrcString, double array[], Cardinal nsize)
#else
void extractResources(rsrcString, array, nsize)
String rsrcString;
double array[];
Cardinal nsize;
#endif /*__STDC__*/
{
    register int j;
    KEYS *save;

    if (rsrcString == (String)NULL)
      return;

    save = KeyHead;
    KeyHead = XtNew(KEYS);
    KeyHead->fwd = (KEYS *)NULL;
    KeyHead->key = XtNewString("thiskey");
    KeyHead->Pvalue = XtNewString(rsrcString);
    KeyHead->value = (char *)KeyHead->Pvalue;

    for (j = 0; j < nsize; j++)
      array[j] = ckeyd("thiskey", array[j]);

    clearKeys(&KeyHead);
    KeyHead = save;

    return;
}

/************************************************************************/
#ifdef __STDC__
void readSetup(const char *file, const char *setup)
#else
void readSetup(file, setup)
const char *file;
const char *setup;
#endif /*__STDC__*/
{
    char *option, *ptr;
    char defvalue[5];
    register int j;
    double iffreq;
    Boolean cross;

    if (loadSetup(file, setup, 0) != 0)
      return;

    (void)strcpy(defvalue, ((Global->option == True) ? " " : "auto"));
    option = ckeya("coptions", defvalue);
    for (ptr = option; *ptr != Null; ptr++) {
      if (isupper(*ptr))
        *ptr = tolower(*ptr);
    }
    cross = (strstr("auto", option) != (char *)NULL) ? False : True;

    if (Global->option != cross)
      setOption(Global->mainWindow, cross);

    setMode(Global->mainWindow, ckeyi("cormode", Global->mode));

    setRestFreq(Global->mainWindow, ckeyd("freq", Global->restfreq));

    iffreq = ckeyd("iffreq", Global->iffreq);
    if (iffreq < 0) {
      iffreq = -iffreq;
      if (Global->usb == True)
        setSB(Global->mainWindow, False);
    }
    setIFFreq(Global->mainWindow, iffreq);

    for (j = 0; j < 4; j++) {
      setCorf(Global->mainWindow, (j + 1), ckeyd("corf", Global->corfs[j]));
      setBW(Global->mainWindow, (j + 1), ckeyd("corbw", Global->bw[j]));
    }

    for (j = 0; j < 8; j++) {
      if (j < Global->mode)
        setRestFQ(j, False, ckeyd("restfqs", -1.0));
      else
        setRestFQ(j, False, -1.0);
    }
    for (j = 0; j < 8; j++) {
      if (j < Global->mode)
        setRestFQ(j, True, ckeyd("restfqs", -1.0));
      else
        setRestFQ(j, True, -1.0);
    }

    return;
}

/*
 *  This routine will write the current settings to the named file in
 *  the form of a setup command (with name setup).
 */
/************************************************************************/
#ifdef __STDC__
void writeSetup(const char *file, const char *setup)
#else
void writeSetup(file, setup)
const char *file;
const char *setup;
#endif /*__STDC__*/
{
    char *mode;
    char string[MAXSTRING];
    register int j, maxcorf;
    double freq, iffreq;
    FILE *fp;

    if ((setup == (const char *)NULL) || (*setup == Null)) {
      Warning("A setup name must be supplied.");
      return;
    }

    if ((file == (const char *)NULL) || (*file == Null)) {
      Warning("An output file name must be supplied.");
      return;
    }

    /*
     *  First, test to see if the file exists.  If it does, open it in
     *  append mode; otherwise, in write mode.  This should just be a
     *  call with append mode; but some systems may fail if the file
     *  does not already exist.
     */
    mode = "w";
    if ((fp = fopen(file, "r")) != (FILE *)NULL) {
      (void)fclose(fp);
      mode = "a";
    }

    if ((fp = fopen(file, mode)) == (FILE *)NULL) {
      (void)sprintf(string, "Failed to open setup file [%s].\n", file);
      Warning(string);
      return;
    }

    /*  Write a title line comment to the file. */
    (void)fprintf(fp, "#\n#  Setup created by xcorf [%s] on [%s]\n#\n",
      VERSION, getTime());

    iffreq = Global->iffreq;
    if (Global->usb == False)
      iffreq = -iffreq;

    (void)fprintf(fp, "setup name=%s ", setup);
    (void)fprintf(fp, "freq=%.6f ", Global->restfreq);
    (void)fprintf(fp, "iffreq=%G ", iffreq);
    (void)fprintf(fp, "cormode=%d ", Global->mode);
    if (Global->option != True)
      (void)fprintf(fp, "coptions=auto ");
    (void)fprintf(fp, "\\\n\t");

    /*  If any restfqs have been set, then add the proper keyword. */
    for (j = 0; j < Global->mode; j++) {
      if (getRestFQ(j, False, &freq))
        break;
      if (getRestFQ(j, True, &freq))
        break;
    }

    if (j < Global->mode) {
      (void)fprintf(fp, "restfqs=");

      if (getRestFQ(0, False, &freq))
        (void)fprintf(fp, "%.6f", freq);
      else
        (void)fprintf(fp, "0");

      for (j = 1; j < Global->mode; j++) {
        if (getRestFQ(j, False, &freq))
          (void)fprintf(fp, ",%.6f", freq);
        else
          (void)fprintf(fp, ",0");
      }

      if (Global->option == True) {
        for (j = 0; j < Global->mode; j++) {
          if (getRestFQ(j, True, &freq))
            (void)fprintf(fp, ",%.6f", freq);
          else
            (void)fprintf(fp, ",0");
        }
      }

      (void)fprintf(fp, " \\\n\t");
    }

    /*  Corf/BW 1 are always active; now find the last active corf/BW. */
    for (maxcorf = 3; maxcorf > 0; maxcorf--)
      if (Global->active[maxcorf] == True)
        break;

    (void)fprintf(fp, "corf=%.3f", Global->corfs[0]);
    for (j = 1; j <= maxcorf; j++) {
      if (Global->active[j] == True)
        (void)fprintf(fp, ",%.3f", Global->corfs[j]);
      else
        (void)fprintf(fp, ",%d", (j+1)*200);
    }

    (void)fprintf(fp, " corbw=%G", Global->bw[0]);
    for (j = 1; j <= maxcorf; j++) {
      if (Global->active[j] == True)
        (void)fprintf(fp, ",%G", Global->bw[j]);
      else
        (void)fprintf(fp, ",100");
    }

    (void)fprintf(fp, "\n");

    (void)fclose(fp);

    return;
}
