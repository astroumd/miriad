/*= XCORF - X-window correlator setup application. */
/*& jm */
/*: visual display */
/*+
      XCORF is an X-window application that permits the user to explore
      different correlator arrangements for use with observations at
      the BIMA observatory.

      Syntax:   xcorf [options]

      The command line options are few and can also be entered after
      the program has started.  Reasonable defaults exist for all
      inputs if they are not specified.  In general, these defaults
      need not be entered when starting the program.  The command line
      options are provided to help experienced users re-create earlier
      efforts.  Consult the individual help items under the HELP
      pulldown menu in the upper right corner once the application is
      started for further information.

      No information is saved unless done so explicitly; as a result,
      exploration is encouraged.
 */
/*--*/

#include "xcorf.h"
#include "icon.h"

#include <X11/Shell.h>
#include <Xm/MessageB.h>

GLOBAL *Global = (GLOBAL *)NULL;
static Display *thisDisplay;
static Pixel undefinedColor;
static Pixel noFluxColor;
static Pixel restfqsColor;
static Pixel birdieColor;

static struct resource_struct {
  String   icon_geometry;                /* Size and position of icon. */
  String   infile;                       /* Name of initial line file. */
  float    restfreq;                 /* Initial line frequency in GHz. */
  float    iffreq;                     /* Initial IF frequency in MHz. */
  float    vlsr;            /* Initial velocity of main source in kms. */
  int      cormode;                  /* Initial correlator mode [1-8]. */
  Boolean  usb;    /* True if initial upper sideband; False for lower. */
  Boolean  onemm;          /* True if initially at 1mm; False for 3mm. */
  float    fmin;        /* Minimum allowed frequency for ruler in GHz. */
  float    fmax;        /* Maximum allowed frequency for ruler in GHz. */
  float    rulerwidth;    /* Initial frequency width for ruler in GHz. */
  int      debug;    /* 0 turns off messages; 1 most; 2 program level. */
  int      coropt;        /* 0 if initial option is cross; 1 for auto. */
  String   corbw;                     /* Array of 4 bandwidths in MHz. */
  String   corf;                /* Array of 4 corf frequencies in MHz. */
  String   restfqs;   /* Array of 16 rest frequency references in GHz. */
  String   setupFile;                   /* Name of initial setup file. */
  String   setupName;                  /* Name of initial setup entry. */
  String   birdString;                       /* Comma list of birdies. */
  XFontStruct *rulerFont;                /* Font for main slider rule. */
  XFontStruct *usbRulerFont;                    /* Font for usb ruler. */
  XFontStruct *usbDrawFont;              /* Font for usb drawing area. */
  XFontStruct *lsbRulerFont;                    /* Font for lsb ruler. */
  XFontStruct *lsbDrawFont;              /* Font for lsb drawing area. */
  Pixel undefinedColor;         /* Color of undefined molecular lines. */
  Pixel noFluxColor;     /* Color of molecular lines w/o known fluxes. */
  Pixel restfqsColor;           /* Color of lines identifying restfqs. */
  Pixel birdieColor;            /* Color of lines identifying birdies. */
};

#define Offset(field) (XtOffset(struct resource_struct *, field))
static XtResource Resources[] = {
  {"iconGeometry", "IconGeometry", XtRString,      sizeof(String),
     Offset(icon_geometry),     XtRString,      (XtPointer)NULL},
  {"infile",       "Infile",       XtRString,      sizeof(String),
     Offset(infile),            XtRString,      (XtPointer)NULL},
  {"restfreq",     "Restfreq",     XtRFloat,       sizeof(float),
     Offset(restfreq),          XtRString,      (XtPointer)NULL},
  {"iffreq",       "Iffreq",       XtRFloat,       sizeof(float),
     Offset(iffreq),            XtRString,      (XtPointer)"150.0"},
  {"vlsr",         "Vlsr",         XtRFloat,       sizeof(float),
     Offset(vlsr),              XtRString,      (XtPointer)"0.0"},
  {"cormode",      "Cormode",      XtRInt,         sizeof(int),
     Offset(cormode),           XtRImmediate,   (XtPointer)8},
  {"usb",          "Usb",          XtRBoolean,     sizeof(Boolean),
     Offset(usb),               XtRImmediate,   (XtPointer)True},
  {"onemm",        "Onemm",        XtRBoolean,     sizeof(Boolean),
     Offset(onemm),             XtRImmediate,   (XtPointer)False},
  {"fmin",         "Fmin",         XtRFloat,       sizeof(float),
     Offset(fmin),              XtRString,      (XtPointer)NULL},
  {"fmax",         "Fmax",         XtRFloat,       sizeof(float),
     Offset(fmax),              XtRString,      (XtPointer)NULL},
  {"rulerwidth",   "Rulerwidth",   XtRFloat,       sizeof(float),
     Offset(rulerwidth),        XtRString,      (XtPointer)"10.0"},
  {"debug",        "Debug",        XtRInt,         sizeof(int),
     Offset(debug),             XtRImmediate,   (XtPointer)0},
  {"coropt",       "Coropt",       XtRInt,         sizeof(int),
     Offset(coropt),            XtRImmediate,   (XtPointer)0},
  {"corbw",        "Corbw",        XtRString,      sizeof(String),
     Offset(corbw),             XtRString,      (XtPointer)"100,100,100,100"},
  {"corf",         "Corf",         XtRString,      sizeof(String),
     Offset(corf),              XtRString,      (XtPointer)"200,400,600,800"},
  {"restfqs",      "Restfqs",      XtRString,      sizeof(String),
     Offset(restfqs),           XtRString,      (XtPointer)NULL},
  {"setupFile",    "SetupFile",    XtRString,      sizeof(String),
     Offset(setupFile),         XtRString,      (XtPointer)NULL},
  {"setupName",    "SetupName",    XtRString,      sizeof(String),
     Offset(setupName),         XtRString,      (XtPointer)NULL},
  {"birdie",       "Birdie",       XtRString,      sizeof(String),
     Offset(birdString),        XtRString,      (XtPointer)NULL},
  {"rulerFont",    XtCFont,        XtRFontStruct,  sizeof(XFontStruct *),
     Offset(rulerFont),         XtRString,      XtDefaultFont},
  {"usbRulerFont", XtCFont,        XtRFontStruct,  sizeof(XFontStruct *),
     Offset(usbRulerFont),      XtRString,      XtDefaultFont},
  {"usbDrawFont",  XtCFont,        XtRFontStruct,  sizeof(XFontStruct *),
     Offset(usbDrawFont),       XtRString,      XtDefaultFont},
  {"lsbRulerFont", XtCFont,        XtRFontStruct,  sizeof(XFontStruct *),
     Offset(lsbRulerFont),      XtRString,      XtDefaultFont},
  {"lsbDrawFont",  XtCFont,        XtRFontStruct,  sizeof(XFontStruct *),
     Offset(lsbDrawFont),       XtRString,      XtDefaultFont},
  {"undefinedColor", "UndefinedColor", XtRPixel,   sizeof(Pixel),
     Offset(undefinedColor),    XtRString,      (XtPointer)"yellow"},
  {"noFluxColor",  "NoFluxColor",  XtRPixel,       sizeof(Pixel),
     Offset(noFluxColor),       XtRString,      (XtPointer)"orange"},
  {"restfqsColor", "RestfqsColor", XtRPixel,       sizeof(Pixel),
     Offset(restfqsColor),       XtRString,      (XtPointer)"green"},
  {"birdieColor",  "BirdieColor",  XtRPixel,       sizeof(Pixel),
     Offset(birdieColor),        XtRString,      (XtPointer)"blue"},
};
#undef Offset

static XrmOptionDescRec options[] = {
  {"-icongeometry",  "iconGeometry", XrmoptionSepArg,    (XtPointer)NULL},
  {"-iconGeometry",  "iconGeometry", XrmoptionSepArg,    (XtPointer)NULL},
  {"-ig",            "iconGeometry", XrmoptionSepArg,    (XtPointer)NULL},
  { "in=",           "infile",       XrmoptionStickyArg, (XtPointer)NULL},
  { "infile=",       "infile",       XrmoptionStickyArg, (XtPointer)NULL},
  { "freq=",         "restfreq",     XrmoptionStickyArg, (XtPointer)NULL},
  { "restfreq=",     "restfreq",     XrmoptionStickyArg, (XtPointer)NULL},
  { "iffreq=",       "iffreq",       XrmoptionStickyArg, (XtPointer)NULL},
  { "vlsr=",         "vlsr",         XrmoptionStickyArg, (XtPointer)NULL},
  { "cormode=",      "cormode",      XrmoptionStickyArg, (XtPointer)NULL},
  { "coropt=",       "coropt",       XrmoptionStickyArg, (XtPointer)NULL},
  { "corf=",         "corf",         XrmoptionStickyArg, (XtPointer)NULL},
  { "corbw=",        "corbw",        XrmoptionStickyArg, (XtPointer)NULL},
  { "restfqs=",      "restfqs",      XrmoptionStickyArg, (XtPointer)NULL},
  { "setup=",        "setupFile",    XrmoptionStickyArg, (XtPointer)NULL},
  { "name=",         "setupName",    XrmoptionStickyArg, (XtPointer)NULL},
  { "birdie=",       "birdie",       XrmoptionStickyArg, (XtPointer)NULL},
  { "-usb",          "usb",          XrmoptionNoArg,     (XtPointer)"True"},
  { "-lsb",          "usb",          XrmoptionNoArg,     (XtPointer)"False"},
  { "-1mm",          "onemm",        XrmoptionNoArg,     (XtPointer)"True"},
  { "-3mm",          "onemm",        XrmoptionNoArg,     (XtPointer)"False"},
  { "-debug",        "debug",        XrmoptionNoArg,     (XtPointer)"1"},
  { "-Debug",        "debug",        XrmoptionNoArg,     (XtPointer)"2"},
};

static String fallback_resources[] = {
  "*Font:                   -misc-fixed-bold-r-*-*-*-120-*-*-*-*-*-*",
  "*sideband.XmToggleButtonGadget.indicatorOn:     False",
  "*sideband.XmToggleButtonGadget.fillOnSelect:     True",
  "*sideband.XmToggleButtonGadget.shadowThickness:     1",
  "*corfBWForm.XmRowColumn.XmToggleButtonGadget.indicatorOn: False",
  "*corfBWForm.XmRowColumn.XmToggleButtonGadget.fillOnSelect: True",
  "*corfBWForm.XmRowColumn.XmToggleButtonGadget.shadowThickness: 1",
  "*dialogForm.XmTextField.columns:                    5",
  "*restFQRowColumn*dialogForm.XmTextField.columns:   10",
  "*mainRuler.shadowThickness:                         2",
  "*corfDraw.XmDrawingArea.shadowThickness:            1",
  "*rulerFrame.XmDrawingArea.width:                   30",
  "*commands.height:                                 100",
  "*smallForm.height:                                250",
  NULL,
};

/***********************************************************************/
#ifdef __STDC__
static void ParseIconGeometry(Widget w, String iconString, int *x, int *y,
  int iconw, int iconh)
#else
static void ParseIconGeometry(w, iconString, x, y, iconw, iconh)
Widget w;
String iconString;
int *x, *y;
int iconw, iconh;
#endif /*__STDC__*/
{
    int bitmask, RootWidth, RootHeight;
    int screenNumber;
    unsigned int width, height;

    screenNumber = DefaultScreen(XtDisplay(w));
    RootWidth = XDisplayWidth(XtDisplay(w), screenNumber) - 1;
    RootHeight = XDisplayHeight(XtDisplay(w), screenNumber) - 1;

    *x = 0;
    *y = 0;
    bitmask = XParseGeometry(iconString, x, y, &width, &height);
    if ((bitmask & (XNegative|XValue)) == (XNegative|XValue))
      *x += (RootWidth - iconw);
    if ((bitmask & (YNegative|YValue)) == (YNegative|YValue))
      *y += (RootHeight - iconh);
}

/***********************************************************************/
#ifdef __STDC__
void Warning(String message)
#else
void Warning(message)
String message;
#endif /*__STDC__*/
{
    Arg arg[1];
    Cardinal i;
    XmString string;
    static Widget warning = (Widget)NULL;

    if ((Global->mainWindow == (Widget)NULL) ||
        (XtIsRealized(Global->mainWindow) == False)) {
      XBell(thisDisplay, 0);
      XtAppWarning(XtDisplayToApplicationContext(thisDisplay), message);
    } else {
      if (warning == (Widget)NULL) {
        i = 0;
        warning = XmCreateWarningDialog(Global->mainWindow, "warning", arg, i);
        XtUnmanageChild(XmMessageBoxGetChild(warning, XmDIALOG_CANCEL_BUTTON));
        XtUnmanageChild(XmMessageBoxGetChild(warning, XmDIALOG_HELP_BUTTON));
      }

      string = XmStringCreateLtoR(message, XmFONTLIST_DEFAULT_TAG);
      i = 0;
      XtSetArg(arg[i], XmNmessageString, (XtArgVal)string);  i++;
      XtSetValues(warning, arg, i);
      XmStringFree(string);

      XBell(XtDisplay(warning), 0);
      XtManageChild(warning);
    }

    return;
}

/***********************************************************************/
#ifdef __STDC__
int XTextHeight(XFontStruct *font, const char *string, int nchar)
#else
int XTextHeight(font, string, nchar)
XFontStruct *font;
const char *string;
int nchar;
#endif /*__STDC__*/
{
    int dir, asc, dsc;
    XCharStruct char_return;

    XTextExtents(font, string, nchar, &dir, &asc, &dsc, &char_return);

    return(asc + dsc);
}

/***********************************************************************/
#ifdef __STDC__
Pixel getInputColor(int which)
#else
Pixel getInputColor(which)
int which;
#endif /*__STDC__*/
{
    Pixel color;

    switch (which) {
      case UNDEFINEDCOLOR: color = undefinedColor; break;
      case NOFLUXCOLOR:    color = noFluxColor;    break;
      case RESTFQSCOLOR:   color = restfqsColor;   break;
      case BIRDIECOLOR:    color = birdieColor;    break;
      default:             color = undefinedColor; break;
    }

    return(color);
}

/***********************************************************************/
#ifdef __STDC__
int main(int argc, char *argv[])
#else
int main(argc, argv)
int argc;
char *argv[];
#endif /*__STDC__*/
{
    char title[100];
    int x, y;
    int maxentry;
    double bws[4], corfs[4];
    double restfqs[16];
    struct resource_struct resources;
    Arg args[10];
    Boolean cross;
    Cardinal i, j;
    Pixmap iconPixmap;
    Widget toplevel;
    XtAppContext context;

    /*  First, create a structure that will hold the global variables. */
    if ((Global = XtNew(GLOBAL)) == (GLOBAL *)NULL) {
      (void)fprintf(stderr, "Could not allocate any memory in %s.\n", argv[0]);
      (void)exit(1);
    }

    toplevel = XtAppInitialize(&context, "XCorf", options, XtNumber(options),
               &argc, argv, fallback_resources, NULL, (Cardinal)0);
    thisDisplay = XtDisplay(toplevel);        /* Needed for Warning(). */

    XtGetApplicationResources(toplevel, &resources, Resources,
               XtNumber(Resources), NULL, (Cardinal)0);

    (void)sprintf(title,
      "Xcorf - BIMA Application to Model Correlator Settings - %s", VERSION);

    /*
     * If not set by the user, set up some reasonable defaults.
     * This can not be done in the resources because of the possible
     * choice by the user of 1mm or 3mm settings.
     */

    if (resources.fmin == resources.fmax) {
      resources.fmin = (resources.onemm == True) ? 215.0 : 65.0 ;
      resources.fmax = resources.fmin + 55.0;
    }

    if (resources.restfreq == 0.0) {
      resources.restfreq = (resources.onemm == True) ? 230.5 : 110.0 ;
    }

    if (resources.infile == (String)NULL) {
      resources.infile = (resources.onemm == True) ? "lovas.1mm" : "lovas.3mm" ;
    }

    /* Store the colors for later retrieval. */
    undefinedColor = resources.undefinedColor;
    noFluxColor = resources.noFluxColor;
    restfqsColor = resources.restfqsColor;
    birdieColor = resources.birdieColor;

    /*  Initialize the global variables. */
    if (resources.fmin < resources.fmax) {
      Global->freqmin  = (double)resources.fmin;
      Global->freqmax  = (double)resources.fmax;
    } else {
      Global->freqmin  = (double)resources.fmax;
      Global->freqmax  = (double)resources.fmin;
    }
    if ((Global->freqmax - Global->freqmin) < ((SBMAX + SBMAX) / 1000.0))
      Global->freqmax = Global->freqmin + ((SBMAX + SBMAX) / 1000.0);

    Global->debug    = resources.debug;
    Global->usb      = resources.usb;
    Global->option   = True;
    Global->numchans = NUMCHANS;
    Global->doppler = 1.0;        /* Initialize this in case vlsr = 0. */

    corfs[0] = 200; corfs[1] = 400;
    corfs[2] = 600; corfs[3] = 800;
    extractResources(resources.corf, corfs, 4);
    bws[0] = bws[1] = bws[2] = bws[3] = 100;
    extractResources(resources.corbw, bws, 4);

    if (resources.iffreq < 0) {
      resources.iffreq = -resources.iffreq;
      if (resources.usb)
        resources.usb = False;
    }

    cross = (resources.coropt == 0) ? True : False ;

    Global->mainWindow = buildWindows(toplevel, resources.usb, cross,
      resources.cormode, (double)resources.restfreq, (double)resources.iffreq,
      (double)resources.vlsr, (double)resources.rulerwidth, bws, corfs,
      resources.rulerFont, resources.usbRulerFont, resources.usbDrawFont,
      resources.lsbRulerFont, resources.lsbDrawFont);

    if ((resources.setupFile) && (resources.setupName))
      readSetup(resources.setupFile, resources.setupName);

    XtSetMappedWhenManaged(toplevel, False);
    XtRealizeWidget(toplevel);

    iconPixmap = XCreateBitmapFromData(XtDisplay(toplevel),
      XtWindow(toplevel), icon_bits, icon_width, icon_height);

    i = 0;
    XtSetArg(args[i], XtNminWidth,          (XtArgVal)100); i++;
    XtSetArg(args[i], XtNminHeight,         (XtArgVal)100); i++;
    XtSetArg(args[i], XtNinput,            (XtArgVal)True); i++;
    XtSetArg(args[i], XtNiconPixmap, (XtArgVal)iconPixmap); i++;
    XtSetArg(args[i], XtNtitle,           (XtArgVal)title); i++;
    XtSetValues(toplevel, args, i);

    if (resources.icon_geometry) {
      ParseIconGeometry(toplevel, resources.icon_geometry, &x, &y,
        icon_width, icon_height);
      i = 0;
      XtSetArg(args[i], XtNiconX, (XtArgVal)x); i++;
      XtSetArg(args[i], XtNiconY, (XtArgVal)y); i++;
      XtSetValues(toplevel, args, i);
    }

    /*  Do some final checks and then load in the line file. */
    checkMode();
    updateLO1();

    for (i = 0; i < 16; i++)         /* Initialize restfqs. */
      restfqs[i] = 0.0;
    extractResources(resources.restfqs, restfqs, 16);
    maxentry = Global->mode;
    for (j = i = 0; i < maxentry; j++, i++) /* LSB restfqs. */
      setRestFQ(i, False, restfqs[j]);
    for (i = 0; i < maxentry; j++, i++)     /* USB restfqs. */
      setRestFQ(i, True, restfqs[j]);

    parseFileList(resources.infile);
    parseBirdies(resources.birdString);

    /* Display the rest of the windows. */
    XtSetMappedWhenManaged(toplevel, True);
    XtMapWidget(toplevel);

    XtAppMainLoop(context);
    return(0);
}
