#include "xcorf.h"

#include <Xm/DrawingA.h>

#define LSB 0
#define USB 1
#define DRAWING 0
#define CHANNEL 1
#define SBINDEX(a) (((a) == True) ? USB : LSB )
#define DCINDEX(a) (((a) == True) ? CHANNEL : DRAWING )

typedef struct {
  double value;                    /* Current offset of window in GHz. */
  double range;                            /* Extent of window in GHz. */
  double scale;                 /* Current scale factor in pixels/GHz. */

  Dimension width;          /* Current width of drawingArea in pixels. */
  Dimension height;        /* Current height of drawingArea in pixels. */
  XFontStruct *font;                      /* Font to use to draw text. */
  GC gc;                          /* GC to use to draw text and lines. */
  GC undefdgc;                   /* GC to use to draw undefined lines. */
  GC nofluxgc;                /* GC to use when the flux is undefined. */
  GC birdgc;                        /* GC to use when drawing birdies. */
  GC dashed_gc;       /* GC used to draw dashed lines in channel plot. */
  GC restfqs_gc;    /* GC used to draw location of channel rest freqs. */
  Widget widget;                             /* Widget of drawingArea. */
  Boolean isusb;         /* Is this for the USB (True) or LSB (False). */
} DRAW;

static DRAW drawList[USB+1][CHANNEL+1];

static int BirdieCount = 0;
static double *Birdies = (double *)NULL;

/***********************************************************************/
#ifdef __STDC__
static void getStartStop(double lo1, Boolean isusb, double *start, double *stop)
#else
static void getStartStop(lo1, isusb, start, stop)
double lo1;
Boolean isusb;
double *start;
double *stop;
#endif /*__STDC__*/
{
    double scale;

    scale = 1000.0 * Global->doppler;

    if (isusb == True) {
      *start = lo1 + (SBMIN / scale);
      *stop = lo1 + (SBMAX / scale);
    } else {
      *start = lo1 - (SBMAX / scale);
      *stop = lo1 - (SBMIN / scale);
    }

    return;
}

/***********************************************************************/
#ifdef __STDC__
static int redrawDrawing(DRAW *draw)
#else
static int redrawDrawing(draw)
DRAW *draw;
#endif /*__STDC__*/
{
    char lastname[80], name[80], trans[80];
    int j, nlines;
    int xpos, ypos, lastypos;
    double value, ylen;
    double intensity, maxIntensity;
    double lo1, offset, scale;
    double start, stop;
    Boolean dolabel;
    Display *dpy;
    GC lineGC;
    Position thresh;
    Window win;
    XtPointer marker;

    if (!XtIsRealized(draw->widget))
      return(0);

    dpy = XtDisplay(draw->widget);
    win = XtWindow(draw->widget);

    /*  First, clear the Window. */
    XClearWindow(dpy, win);

    /*  Set up some variables needed through the loop. */

    maxIntensity = getMaxIntensity();
    nlines = 0;
    (void)strcpy(lastname, "");
    lastypos = 0;
    thresh = (2 * XTextHeight(draw->font, "U", 1)) / 3;
    offset = ((draw->isusb == True) ? SBMIN : SBMAX) / 1000.0;
    scale = (draw->isusb == True) ? draw->scale : -draw->scale ;
    lo1 = getLO1();

    /*  Initialize "value"; getEntry uses this to find the next value. */
    getStartStop(lo1, draw->isusb, &start, &stop);
    value = start;
    marker = NULL;              /* Resets search to beginning of file. */
    while (getEntry(&marker, &value, name, trans, &intensity)) {
      ylen = (value - lo1) * Global->doppler;
      if (draw->isusb == True) {
        ylen = ylen - offset;
      } else {
        ylen = -ylen - offset;
      }
      ylen *= scale;
      ypos = ylen + 0.5;
      if (ypos < 0) continue;
      if (ypos > (int)draw->height) break;

      dolabel = True;
      if (strcmp(name, "U") == 0) {
        xpos = draw->width / 5;
        dolabel = False;
        lineGC = draw->undefdgc;
      } else if (intensity <= -10) {
        xpos = draw->width / 5;
        lineGC = draw->nofluxgc;
      } else {
        xpos = draw->width * (intensity / maxIntensity);
        lineGC = draw->gc;
      }

      if (xpos > (int)draw->width) xpos = (int)draw->width;
      if (xpos < 1) xpos = 5;

      XDrawLine(dpy, win, lineGC, 0, ypos, xpos, ypos);

      if (dolabel == True) {
        if ((strcmp(lastname, name) != 0) || ((ypos - lastypos) > thresh)) {
          xpos = draw->width;
          xpos -= XTextWidth(draw->font, name, strlen(name));
          if (xpos < 0) xpos = 0;
          ypos += (XTextHeight(draw->font, name, strlen(name)) / 2);
          XDrawString(dpy, win, draw->gc, xpos, ypos, name, strlen(name));
          (void)strcpy(lastname, name);
          lastypos = ypos;
        }
      }

      nlines++;
    }

    /* Now display birdie lines. */
    if (BirdieCount > 0) {
      xpos = draw->width;
      offset = (draw->isusb == True) ? (SBMIN - LO2) : (SBMAX - LO2) ;
      scale = ((draw->isusb == True) ? draw->scale : -draw->scale) / 1000.0;

      for (j = 0; j < BirdieCount; j++) {
        ylen = scale * (Birdies[j] - offset);
        ypos = ylen + 0.5;
        if (ypos < 0) continue;
        if (ypos > (int)draw->height) break;

        XDrawLine(dpy, win, draw->birdgc, 0, ypos, xpos, ypos);
      }
    }

    return(nlines);
}

/***********************************************************************/
#ifdef __STDC__
static int redrawChannelDrawing(DRAW *draw)
#else
static int redrawChannelDrawing(draw)
DRAW *draw;
#endif /*__STDC__*/
{
    char lastname[80], name[80], trans[80];
    register int i, j, k;
    int nchans, nwins, nifchan;
    int nlines, length;
    int begchan;
    int xpos, ypos, xsplit, lastypos;
    int chans[8], ifchan[8];
    double lo1, scale;
    double value, range, ylen;
    double intensity, maxIntensity;
    Boolean state, isusb, dolabel;
    GC lineGC;
    Display *dpy;
    Position thresh;
    Window win;
    XtPointer marker;

    if ((draw->widget == (Widget)NULL) || (!XtIsRealized(draw->widget)))
      return(0);

    dpy = XtDisplay(draw->widget);
    win = XtWindow(draw->widget);
    isusb = draw->isusb;

    /*  First, clear the Window. */
    XClearWindow(dpy, win);

    nchans = getChannels(chans, &nwins);
    if ((nchans < 1) || (nwins < 1))
      return(0);

    scale = (double)draw->height / (double)nchans;  /* Pixels/channel. */

    /*  Draw the window boundaries. */
    xpos = draw->width;
    begchan = 0;
    for (i = 0; i < nwins; i++) {
      begchan += chans[i];
      ylen = scale * begchan;
      ypos = ylen + 0.5;
      XDrawLine(dpy, win, draw->dashed_gc, 0, ypos, xpos, ypos);
    }

    /* Draw the positions of the channel rest frequencies. */
    for (k = 0; k < 2; k++) { /* Loop over both sidebands. */
      state = (k == 0) ? False : True ;
      if ((Global->option == True) && (state != isusb))
        continue;

      xpos = draw->width;
      begchan = 0;

      for (j = 0; j < nwins; begchan += chans[j++]) {
        if (getRestFQ(j, state, &value) == 0)
          continue;

        if ((nifchan = isValidIF(state, chans, nwins, value, ifchan)) > 0) {
          for (i = 0; i < nifchan; i++) {
            if ((ifchan[i] < begchan) || (ifchan[i] > (begchan + chans[j])))
              continue;
            ylen = scale * ifchan[i];
            ypos = ylen + 0.5;
            if (ypos < 0) continue;
            if (ypos > (int)draw->height) continue;
            XDrawLine(dpy, win, draw->restfqs_gc, 0, ypos, xpos, ypos);
          }
        }
      }
    }

    /*  Set up some variables needed through the loop. */

    maxIntensity = getMaxIntensity();
    xsplit = 0.7 * draw->width;
    nlines = 0;
    (void)strcpy(lastname, "");
    lastypos = 0;
    thresh = (2 * XTextHeight(draw->font, "U", 1)) / 3;
    lo1 = getLO1();

    /*  Initialize "value"; getEntry uses this to find the next value. */
    for (k = 0; k < 2; k++) { /* Loop over both sidebands. */
      state = (k == 0) ? False : True ;
      if ((Global->option == True) && (state != isusb))
        continue;

      getStartStop(lo1, state, &value, &range);
      marker = NULL;            /* Resets search to beginning of file. */
      while (getEntry(&marker, &value, name, trans, &intensity)) {
        if (value > range)
          break;

        if ((nifchan = isValidIF(state, chans, nwins, value, ifchan)) > 0) {
          for (i = 0; i < nifchan; i++) {
            ylen = scale * ifchan[i];
            ypos = ylen + 0.5;
            if (ypos < 0) continue;
            if (ypos > (int)draw->height) continue;

            dolabel = True;
            if (strcmp(name, "U") == 0) {
              xpos = xsplit / 10;
              dolabel = False;
              lineGC = draw->undefdgc;
            } else if (intensity <= -10) {
              xpos = xsplit / 10;
              lineGC = draw->nofluxgc;
            } else {
              xpos = xsplit * (intensity / maxIntensity);
              lineGC = draw->gc;
            }

            if (xpos > xsplit) xpos = xsplit;
            if (xpos < 1) xpos = 5;

            XDrawLine(dpy, win, lineGC, 0, ypos, xpos, ypos);

            if (dolabel == True) {
              if ((strcmp(lastname, name) != 0) ||
                 ((ypos - lastypos) > thresh)) {
                xpos = xsplit;
                length = strlen(name);
                xpos -= XTextWidth(draw->font, name, length);
                if (xpos < 0) xpos = 0;
                ypos += (XTextHeight(draw->font, name, length) / 2);
                XDrawString(dpy, win, draw->gc, xpos, ypos, name, length);
                xpos = xsplit + 4;
                length = strlen(trans);
                XDrawString(dpy, win, draw->gc, xpos, ypos, trans, length);
                (void)strcpy(lastname, name);
                lastypos = ypos;
              }
            }

            nlines++;
          }
        }
      }
    }

    return(nlines);
}

/***********************************************************************/
#ifdef __STDC__
void redisplayDrawing(Boolean isusb)
#else
void redisplayDrawing(isusb)
Boolean isusb;
#endif /*__STDC__*/
{
    register int nlines;

    nlines = redrawDrawing(&drawList[SBINDEX(isusb)][DRAWING]);

    if (Global->debug > 1)
      (void)printf("Number of lines written to %s sideband = %d\n",
        ((isusb == True) ? "upper" : "lower"), nlines);

    return;
}

/***********************************************************************/
#ifdef __STDC__
void resizeDrawing(Widget w, Boolean isusb, Boolean isChannel)
#else
void resizeDrawing(w, isusb, isChannel)
Widget w;
Boolean isusb;                        /* True if parent is usb window. */
Boolean isChannel;           /* True if channel window; False if corf. */
#endif /*__STDC__*/
{
    Arg arg[10];
    Cardinal i;
    Dimension width, height;
    DRAW *draw;

    draw = &drawList[SBINDEX(isusb)][DCINDEX(isChannel)];

    i = 0;
    XtSetArg(arg[i], XmNwidth,        (XtArgVal)&width);  i++;
    XtSetArg(arg[i], XmNheight,      (XtArgVal)&height);  i++;
    XtGetValues(w, arg, i);

    draw->width = width;
    draw->height = height;
    draw->scale = (double)draw->height / draw->range;

    return;
}

/***********************************************************************/
#ifdef __STDC__
void setDrawingValue(Boolean isusb, double value)
#else
void setDrawingValue(isusb, value)
Boolean isusb;                    /* True if window is upper sideband. */
double value;                           /* LO1 frequency value in GHz. */
#endif /*__STDC__*/
{
    double newValue;
    DRAW *draw;

    draw = &drawList[SBINDEX(isusb)][DRAWING];

    if (isusb == True)
      newValue = value + (SBMIN / 1000.0);
    else
      newValue = value - (SBMAX / 1000.0);

    if (draw->value == newValue)
      return;

    draw->value = newValue;

    redisplayDrawing(isusb);

    /*  Also set the drawing area value for the channel plots. */

    draw = &drawList[SBINDEX(isusb)][CHANNEL];
    draw->value = newValue;
    redisplayChannels(isusb);

    return;
}

/***********************************************************************/
#ifdef __STDC__
void initDrawingArea(Widget w, Boolean isusb, Boolean isChannel)
#else
void initDrawingArea(w, isusb, isChannel)
Widget w;
Boolean isusb;                    /* True if window is upper sideband. */
Boolean isChannel;       /* True for channel windows; False for corfs. */
#endif /*__STDC__*/
{
    Arg arg[10];
    Cardinal i;
    Dimension width, height;
    Pixel bg, fg;
    XGCValues gcv;
    XtGCMask gcmask;
    XtPointer xptr;
    DRAW *draw;

    draw = &drawList[SBINDEX(isusb)][DCINDEX(isChannel)];

    i = 0;
    XtSetArg(arg[i], XmNuserData,  (XtArgVal)&xptr);  i++;
    XtSetArg(arg[i], XmNforeground,  (XtArgVal)&fg);  i++;
    XtSetArg(arg[i], XmNbackground,  (XtArgVal)&bg);  i++;
    XtSetArg(arg[i], XmNwidth,    (XtArgVal)&width);  i++;
    XtSetArg(arg[i], XmNheight,  (XtArgVal)&height);  i++;
    XtGetValues(w, arg, i);

    draw->width = width;
    draw->height = height;
    draw->range = (SBMAX - SBMIN) / 1000.0;           /* Range in GHz. */
    draw->scale = (double)draw->height / draw->range;
    draw->font = (XFontStruct *)xptr;
    draw->widget = w;
    draw->isusb = isusb;

    /*  Set up the GCs. */
    gcmask = GCFunction | GCForeground | GCBackground | GCFont;

    gcv.function = GXcopy;
    gcv.foreground = fg;
    gcv.background = bg;
    gcv.font = draw->font->fid;
    draw->gc = XtGetGC(w, gcmask, &gcv);

    gcv.foreground = getInputColor(UNDEFINEDCOLOR);
    draw->undefdgc = XtGetGC(w, gcmask, &gcv);

    gcv.foreground = getInputColor(NOFLUXCOLOR);
    draw->nofluxgc = XtGetGC(w, gcmask, &gcv);

    gcmask |= GCLineStyle;
    gcv.line_style = LineDoubleDash;
    gcv.foreground = getInputColor(BIRDIECOLOR);
    draw->birdgc = XtGetGC(w, gcmask, &gcv);

    if (isChannel == True) {
      gcv.function = GXcopy;
      gcv.foreground = fg;
      gcv.background = bg;
      gcv.font = draw->font->fid;
      gcv.line_style = LineOnOffDash;
      draw->dashed_gc = XtGetGC(w, gcmask, &gcv);

      gcv.foreground = getInputColor(RESTFQSCOLOR);
      draw->restfqs_gc = XtGetGC(w, gcmask, &gcv);
    } else {
      draw->dashed_gc = (GC)NULL;  /* Unused. */
      draw->restfqs_gc = (GC)NULL;  /* Unused. */
    }

    return;
}

/***********************************************************************/
#ifdef __STDC__
void redisplayChannels(Boolean isusb)
#else
void redisplayChannels(isusb)
Boolean isusb;
#endif /*__STDC__*/
{
    register int nlines;

    nlines = redrawChannelDrawing(&drawList[SBINDEX(isusb)][CHANNEL]);

    redrawChannelRuler(isusb);

    if (Global->debug > 1)
      (void)printf("Number of channels written to %s sideband = %d\n",
        ((isusb == True) ? "upper" : "lower"), nlines);

    return;
}

/***********************************************************************/
#ifdef __STDC__
void updateChannels(void)
#else
void updateChannels()
#endif /*__STDC__*/
{
    redisplayChannels(False);
    redisplayChannels(True);

    return;
}

/***********************************************************************/
#ifdef __STDC__
void channelPress(Boolean isusb, Boolean reset, int ypos)
#else
void channelPress(isusb, reset, ypos)
Boolean isusb;
Boolean reset;
int ypos;
#endif /*__STDC__*/
{
    char name[80], trans[80];
    char errmsg[1000];
    int ivalue, window;
    int nchans, nwins;
    int chans[8];
    double intensity;
    double freq, value, scale;
    DRAW *draw;

    draw = &drawList[SBINDEX(isusb)][CHANNEL];

    nchans = getChannels(chans, &nwins);
    if ((nchans < 1) || (nwins < 1) || (draw->height < 1))
      return;

    scale = (double)draw->height / (double)nchans;    /* Pixels / MHz. */
    ivalue = ((double)ypos / scale) + 0.5;             /* ypos -> MHz. */

    freq = getValidIF(isusb, chans, nwins, ivalue, &window);

    if (Global->debug > 0)
      (void)printf("Frequency found = [%G] [GHz] in [%s] Window [%d]\n",
        freq, ((isusb == True) ? "USB" : "LSB"), window);

    if (reset == True) {
      if ((window < 1) || (window > 8)) {
        (void)sprintf(errmsg,
          "Can not match the cursor position to a valid window");
        Warning(errmsg);
        return;
      }
      value = -1.0;
    } else {
      value = freq;
      scale = 100;
      if (nearestEntry(&value, scale, name, trans, &intensity) == 0) {
        if (Global->option == True)
          (void)sprintf(errmsg, "\
Can not find a match to the frequency line of [%G] GHz using\n\
a [%G] MHz wide window.  Go to the `Rest Frequencies...' window\n\
(under the Option menu) to set this rest frequency manually.",
            freq, scale);
        else
          (void)sprintf(errmsg, "\
Can not find a match to the frequency line of [%G] GHz using\n\
a [%G] MHz wide window.  This might be due to overlap of the channel\n\
windows in Auto Correlation mode.  Try selecting the same line in\n\
the other channel window.  Or, go to the `Rest Frequencies...'\n\
window (under the Option menu) to set this rest frequency manually.",
            freq, scale);
        Warning(errmsg);
        return;
      }

      if (Global->debug > 0)
        (void)printf("Frequency matched = [%G] [GHz] of [%s %s]\n",
          value, name, trans);
    }

    if (Global->option == True) {
      setRestFQ((window - 1), isusb, value);
      redisplayChannels(isusb);
    } else {
      setRestFQ((window - 1), False, value);
      setRestFQ((window - 1), True, value);
      updateChannels();
    }

    updateRestFQ();

    return;
}

/***********************************************************************/
#ifdef __STDC__
void setBirdies(int count, double mhzarray[])
#else
void setBirdies(count, mhzarray)
int count;
double mhzarray[];
#endif /*__STDC__*/
{
    register int j;

    if (BirdieCount > 0)
      XtFree((char *)Birdies);

    BirdieCount = count;
    Birdies = (double *)XtMalloc(sizeof(double) * BirdieCount);
    for (j = 0; j < BirdieCount; j++)
      Birdies[j] = mhzarray[j];

    return;
}
