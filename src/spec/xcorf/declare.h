#ifndef XCORF_PROTOS
#define XCORF_PROTOS

/* Define a macro that aides in presenting prototypes. */
#ifndef ARGS
#ifdef __STDC__
#define ARGS(alist) alist
#else
#define ARGS(alist) ()
#endif /* __STDC__ */
#endif /* ARGS */

#ifndef __STDC__
#define const /* NULL */
#endif /*__STDC__*/

/* -- actions.c -- */
/* -- -- static routines -- -- */
/*
static void cancelCorf();
static void okCorf();
 */
extern void setCorfCB ARGS((Widget w, XtPointer client_data, XtPointer call_data));
extern void sidebandCallback ARGS((Widget w, XtPointer client_data, XtPointer call_data));
extern void modeCallback ARGS((Widget w, XtPointer client_data, XtPointer call_data));
extern void optionCallback ARGS((Widget w, XtPointer client_data, XtPointer call_data));
extern void corfCallback ARGS((Widget w, XtPointer client_data, XtPointer call_data));
extern void bwCallback ARGS((Widget w, XtPointer client_data, XtPointer call_data));
extern void smallRulerCallback ARGS((Widget w, XtPointer client_data, XtPointer call_data));
extern void drawingCallback ARGS((Widget w, XtPointer client_data, XtPointer call_data));
extern void corfdrawCallback ARGS((Widget w, XtPointer client_data, XtPointer call_data));
extern void rulerCallback ARGS((Widget w, XtPointer client_data, XtPointer call_data));
extern void arrowCallback ARGS((Widget w, XtPointer client_data, XtPointer call_data));
extern void channelRulerCB ARGS((Widget w, XtPointer client_data, XtPointer call_data));
extern void channelDrawCB ARGS((Widget w, XtPointer client_data, XtPointer call_data));

/* -- corfs.c -- */
/* -- -- static routines -- -- */
/*
static void positionCorf();
static void redrawCorf();
 */
extern void updateCorfs ARGS((void));
extern void redisplayCorfs ARGS((Boolean isusb));
extern void resizeCorfs ARGS((Widget w, Boolean usb));
extern void moveCorf ARGS((int whichCorf));
extern void scaleCorf ARGS((int whichCorf));
extern void initCorfs ARGS((Widget w, Boolean isusb));

/* -- draw.c -- */
/* -- -- static routines -- -- */
/*
static void getStartStop();
static int redrawDrawing();
static int redrawChannelDrawing();
 */
extern void redisplayDrawing ARGS((Boolean isusb));
extern void resizeDrawing ARGS((Widget w, Boolean isusb, Boolean isChannel));
extern void setDrawingValue ARGS((Boolean isusb, double value));
extern void initDrawingArea ARGS((Widget w, Boolean isusb, Boolean isChannel));
extern void redisplayChannels ARGS((Boolean isusb));
extern void updateChannels ARGS((void));
extern void channelPress ARGS((Boolean isusb, Boolean reset, int ypos));
extern void setBirdies ARGS((int count, double mhzarray[]));

/* -- file.c -- */
/* -- -- static routines -- -- */
/*
static void addEntry();
static void clearEntry();
static int readFile();
static void addRFEntry();
 */
extern double getMaxIntensity ARGS((void));
extern int getEntry ARGS((XtPointer *marker, double *freq, char *name,
  char *trans, double *intensity));
extern int nearestEntry ARGS((double *freq, double range, char *name,
  char *trans, double *intensity));
extern void setInputFile ARGS((String filename, Boolean addon));
extern void resetAllRestFQ ARGS((void));
extern int getRestFQ ARGS((int which, Boolean isusb, double *freq));
extern void setRestFQ ARGS((int which, Boolean isusb, double freq));

/* -- help.c -- */
/* -- -- static routines -- -- */
/*
static void initHelpStrings();
static Widget CreateHelp();
 */
extern void HelpCB ARGS((Widget w, XtPointer client_data, XtPointer call_data));

/* -- rulers.c -- */
/* -- -- static routines -- -- */
/*
static void drawRuler();
static void createRuler();
 */
extern void computeStepSize ARGS((Dimension width, double low, double high, double *increment, int *numTicks));
extern void redrawChannelRuler ARGS((Boolean isusb));
extern void redrawSmallRuler ARGS((Boolean isusb));
extern void resizeSmallRuler ARGS((Widget w, Boolean isChannel, Boolean isusb));
extern void initSmallRuler ARGS((Widget w, Boolean isChannel, Boolean isusb));
extern void redrawSliderRuler ARGS((Widget w, double left, double right, double step, int numTicks));
extern void resizeSliderRuler ARGS((Widget w, Dimension margin, Dimension width, Dimension height));

/* -- setup.c -- */
/* -- -- static routines -- -- */
/*
static char *getTime();
static void clearKeys();
static void mergeKeys();
static KEYS *getKey();
static void ckeyput();
static char *ckeyget();
static double ckeyd();
static int ckeyi();
static int loadSetup();
 */
extern void parseFileList ARGS((String rsrcString));
extern void parseBirdies ARGS((String birdieString));
extern void extractResources ARGS((String rsrcString, double array[],
  Cardinal nsize));
extern void readSetup ARGS((const char *file, const char *setup));
extern void writeSetup ARGS((const char *file, const char *setup));

/* -- slider.c -- */
/* -- -- static routines -- -- */
/*
static void calcSliderRect();
static void drawSliderPixmap();
static void createSlider();
 */
extern GC getForegroundGC ARGS((Widget w, Pixel fg));
extern GC getShadowGC ARGS((Widget w, Pixel fg, Pixel bg, Pixmap pix));
extern void resizeSlider ARGS((Widget w));
extern void redisplaySlider ARGS((Widget w));
extern void redrawSliderWindow ARGS((Widget w));
extern void setSliderRange ARGS((Widget w, double low, double high));
extern void adjustSliderRange ARGS((Boolean increase));
extern void setSliderValue ARGS((double value));
extern void sliderStart ARGS((Widget w, int xpos));
extern void sliderStop ARGS((Widget w, int xpos));
extern void sliderMove ARGS((Widget w, int xpos));

/* -- widgets.c -- */
/* -- -- static routines -- -- */
/*
static Boolean exitWorkProc();
static void quitCB();
static void cancelCB();
static void setupCB();
static void acceptCB();
static void openCB();
static Widget buildDialog();
static void okayFQCB();
static void resetFQCB();
static void restFQCB();
static void restFQPopup();
static void debugCB();
static Widget buildCommandLevel();
static Widget buildInputs();
static void buildMainRuler();
static Widget buildCorfBW();
static void buildToggleCommands();
static void buildSB();
static void buildChannelWindow();
 */
extern Widget buildWindows ARGS((Widget parent, Boolean usb, Boolean cross,
  int mode, double restfreq, double iffreq, double vlsr, double rulerWidth,
  double bws[], double corfs[], XFontStruct *rulerFont,
  XFontStruct *usbRulerFont, XFontStruct *usbDrawFont,
  XFontStruct *lsbRulerFont, XFontStruct *lsbDrawFont));
extern void setOption ARGS((Widget parent, Boolean cross));
extern void setSB ARGS((Widget parent, Boolean usb));
extern void setVelocityRange ARGS((Widget parent, int which, int nvals, double range[]));
extern void setVelocityResol ARGS((Widget parent, int which, int nvals, double resol[]));
extern void updateRestFQ ARGS((void));

/* -- work.c -- */
/* -- -- static routines -- -- */
/*
static double fpfmt();
static void setState();
static void setSensitive();
static void checkSampling();
static double getLUChans();
static double checkBW();
 */
extern void setLastPos ARGS((Widget w));
extern void getCorfSizes ARGS((int which, double *extent, double *offset));
extern Boolean isValidCorf ARGS((int mode, int whichCorf));
extern int isValidIF ARGS((Boolean isusb, int chan[], int nchan,
  double freq, int ifchan[]));
extern double getValidIF ARGS((Boolean isusb, int chan[], int nwins,
  int ichan, int *window));
extern void updateVelocity ARGS((int which));
extern double getLO1 ARGS((void));
extern void updateLO1 ARGS((void));
extern void setLO1 ARGS((double value));
extern int getChannels ARGS((int chans[], int *nschan));
extern void checkDoppler ARGS((int which));
extern void checkMode ARGS((void));
extern void setMode ARGS((Widget w, int mode));
extern void setRestFreq ARGS((Widget w, double restfreq));
extern void setIFFreq ARGS((Widget w, double iffreq));
extern void setVlsr ARGS((Widget w, double vlsr));
extern void setCorf ARGS((Widget w, int which, double corf));
extern void setBW ARGS((Widget w, int which, double bw));
extern void refreshAllDrawings ARGS((void));

/* -- xcorf.c -- */
/* -- -- static routines -- -- */
/*
static void ParseIconGeometry();
 */
extern void Warning ARGS((String message));
extern int XTextHeight ARGS((XFontStruct *font, const char *string, int nchar));
extern Pixel getInputColor ARGS((int which));

#endif /* XCORF_PROTOS */
