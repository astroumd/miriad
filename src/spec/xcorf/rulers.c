#include "xcorf.h"

#include <math.h>
#include <Xm/DrawingA.h>

typedef struct {
  int numberOfMinors;
  double low;
  double high;
  double step;
  GC gc;
  Dimension width;
  Dimension height;
  Dimension margin;
  XFontStruct *font;
  Widget widget;
} RULER;

static RULER lsbChanRuler;
static RULER usbChanRuler;
static RULER lsbRuler;
static RULER usbRuler;
static RULER mainRuler;

/***********************************************************************/
#ifdef __STDC__
static void drawRuler(RULER *ruler, Boolean horiz)
#else
static void drawRuler(ruler, horiz)
RULER *ruler;
Boolean horiz;
#endif /*__STDC__*/
{
    char numb[5];
    int xpos, ypos, xbeg, xend, medtick;
    int x1, y1, x2, y2;
    double increment;
    double scale, value, xlen;
    Cardinal i;
    Dimension length, Width, Height;
    Display *dpy;
    Window win;

    if ((ruler->widget == (Widget)NULL) || (!XtIsRealized(ruler->widget)))
      return;

    dpy = XtDisplay(ruler->widget);
    win = XtWindow(ruler->widget);

    /*  First, clear the Window. */
    XClearWindow(dpy, win);

    if (horiz == True) {
      Width = ruler->width;
      Height = ruler->height;
    } else {
      Width = ruler->height;
      Height = ruler->width;
    }

    xbeg = ruler->margin;
    xend = Width + xbeg;      /* Margin is already removed from Width. */
    scale = (double)Width / (ruler->high - ruler->low);
    ypos = (int)(ruler->low / ruler->step);
    if (ypos <= 0) ypos--;
    value = ruler->step * ypos;
    increment = ruler->step / ruler->numberOfMinors;
    medtick = (ruler->numberOfMinors == 10) ? 5 : 1;

    for (i = 0; /* NULL */ ; i++, value += increment) {
      xlen = scale * (value - ruler->low);
      xpos = (xlen + 0.5) + xbeg;
      if (xpos < xbeg) continue;
      if (xpos > xend) break;

      if ((i % ruler->numberOfMinors) == 0) {
        length = 3;
      } else if ((i % medtick) == 0) {
        length = 4;
      } else {
        length = 6;
      }

      ypos = Height / length;
      if (ypos < 1) ypos = 3;
      if (horiz == True) {
        x1 = x2 = xpos;
        y1 = 0;
        y2 = ypos;
      } else {
        y1 = y2 = xpos;
        x1 = Height - ypos;
        x2 = Height;
      }
      XDrawLine(dpy, win, ruler->gc, x1, y1, x2, y2);

      if ((i % ruler->numberOfMinors) == 0) {
        if ((xpos <= xbeg) || (xpos >= xend)) continue;
        if (value > 0)
          y2 = value + 0.5;
        else
          y2 = value - 0.5;
        (void)sprintf(numb, "%d", y2);

        if (horiz == True) {
          x1 -= (XTextWidth(ruler->font, numb, strlen(numb)) / 2);
          y1 = 0.8 * Height;
        } else {
          x1 -= XTextWidth(ruler->font, numb, strlen(numb));
          if (x1 < 0) x1 = 0;
          y1 += (XTextHeight(ruler->font, numb, strlen(numb)) / 2);
        }
        XDrawString(dpy, win, ruler->gc, x1, y1, numb, strlen(numb));
      }
    }

    return;
}

/************************************************************************/
#ifdef __STDC__
static void createRuler(Widget w, RULER *ruler)
#else
static void createRuler(w, ruler)
Widget w;
RULER *ruler;
#endif /*__STDC__*/
{
    Arg arg[10];
    Cardinal i;
    Dimension Width, Height;
    Pixel bg, fg;
    XGCValues gcv;
    XtGCMask gcmask;
    XtPointer xptr;

    i = 0;
    XtSetArg(arg[i], XmNuserData, (XtArgVal)&xptr);  i++;
    XtSetArg(arg[i], XmNforeground, (XtArgVal)&fg);  i++;
    XtSetArg(arg[i], XmNbackground, (XtArgVal)&bg);  i++;
    XtSetArg(arg[i], XmNwidth,   (XtArgVal)&Width);  i++;
    XtSetArg(arg[i], XmNheight, (XtArgVal)&Height);  i++;
    XtGetValues(w, arg, i);

    ruler->widget = w;
    ruler->width = Width;
    ruler->height = Height;
    ruler->font = (XFontStruct *)xptr;

    /*  Set up the GCs. */
    gcmask = GCFunction | GCForeground | GCBackground | GCFont;

    gcv.function = GXcopy;
    gcv.foreground = fg;
    gcv.background = bg;
    gcv.font = ruler->font->fid;
    ruler->gc = XtGetGC(w, gcmask, &gcv);

    ruler->step = 1.0;
    ruler->numberOfMinors = 10;

    return;
}

/***********************************************************************/
#ifdef __STDC__
void computeStepSize(Dimension width, double low, double high,
  double *increment, int *numTicks)
#else
void computeStepSize(width, low, high, increment, numTicks)
Dimension width;
double low;
double high;
double *increment;
int *numTicks;
#endif /*__STDC__*/
{
   int ilog;
   double xlog, ratio;

    /*  Finds a good value for the major tick mark interval. */

   ratio = 70.0 / (double)width;
   if (ratio > 0.20)
     ratio = 0.20;
   else if (ratio < 0.05)
     ratio = 0.05;
   ratio *= (high - low);

   xlog = log10(ratio);
   ilog = xlog;
   if (xlog < 0) ilog--;
   xlog = pow(10.0, (double)ilog);
   ratio /= xlog;
   ilog = 10;
   if (ratio <= 5.0) ilog = 5;
   if (ratio <= 2.0) ilog = 2;
   xlog *= ilog;

   *increment = xlog;
   *numTicks = 10;
   if (ilog == 5)
     *numTicks = 5;

   return;
}

/************************************************************************/
#ifdef __STDC__
void redrawChannelRuler(Boolean isusb)
#else
void redrawChannelRuler(isusb)
Boolean isusb;
#endif /*__STDC__*/
{
    int numTicks, nchans;
    int chans[8];
    double left, right, step;
    RULER *ruler;

    ruler = (isusb == True) ? &usbChanRuler : &lsbChanRuler;

    step = 0;
    nchans = getChannels(chans, &numTicks);
    left = ((isusb == True) && (Global->option == True)) ? (double)nchans : 0;
    right = left + (double)nchans;

    if (ruler->widget && XtIsRealized(ruler->widget))
      computeStepSize(ruler->height, left, right, &step, &numTicks);

    if (step < 1) {
      step = 50;
      numTicks = 10;
    }

    ruler->low = left;
    ruler->high = right;
    ruler->step = step;
    ruler->numberOfMinors = numTicks;

    drawRuler(ruler, False);

    return;
}

/************************************************************************/
#ifdef __STDC__
void redrawSmallRuler(Boolean isusb)
#else
void redrawSmallRuler(isusb)
Boolean isusb;
#endif /*__STDC__*/
{
    RULER *ruler;

    ruler = (isusb == True) ? &usbRuler : &lsbRuler;

    drawRuler(ruler, False);

    return;
}

/************************************************************************/
#ifdef __STDC__
void resizeSmallRuler(Widget w, Boolean isChannel, Boolean isusb)
#else
void resizeSmallRuler(w, isChannel, isusb)
Widget w;
Boolean isChannel;
Boolean isusb;
#endif /*__STDC__*/
{
    Arg arg[2];
    Cardinal i;
    Dimension Width, Height;
    RULER *ruler;

    if (isChannel == True)
      ruler = (isusb == True) ? &usbChanRuler : &lsbChanRuler;
    else
      ruler = (isusb == True) ? &usbRuler : &lsbRuler;

    i = 0;
    XtSetArg(arg[i], XmNwidth,    (XtArgVal)&Width);  i++;
    XtSetArg(arg[i], XmNheight,  (XtArgVal)&Height);  i++;
    XtGetValues(w, arg, i);

    ruler->width = Width;
    ruler->height = Height;

    return;
}

/************************************************************************/
#ifdef __STDC__
void initSmallRuler(Widget w, Boolean isChannel, Boolean isusb)
#else
void initSmallRuler(w, isChannel, isusb)
Widget w;
Boolean isChannel;
Boolean isusb;
#endif /*__STDC__*/
{
    RULER *ruler;

    if (isChannel == True)
      ruler = (isusb == True) ? &usbChanRuler : &lsbChanRuler;
    else
      ruler = (isusb == True) ? &usbRuler : &lsbRuler;

    createRuler(w, ruler);

    /*  Set up ramp values (doesn't really matter for channel rulers). */

    ruler->margin = 0;
    ruler->step = 200;
    if (isusb == True) {
      ruler->low = SBMIN - LO2;
      ruler->high = SBMAX - LO2;
    } else {
      ruler->low = SBMAX - LO2;
      ruler->high = SBMIN - LO2;
      ruler->step = -ruler->step;
    }

    return;
}

/************************************************************************/
#ifdef __STDC__
void redrawSliderRuler(Widget w, double left, double right, double step, int numTicks)
#else
void redrawSliderRuler(w, left, right, step, numTicks)
Widget w;
double left, right, step;
int numTicks;
#endif /*__STDC__*/
{
    RULER *ruler = &mainRuler;

    if (ruler->widget == (Widget)NULL)
      createRuler(w, ruler);

    ruler->low = left;
    ruler->high = right;
    ruler->step = step;
    ruler->numberOfMinors = numTicks;

    if (ruler->step < 1) {
      ruler->step = 1;
      ruler->numberOfMinors = 10;
    }

    drawRuler(ruler, True);

    return;
}

/************************************************************************/
#ifdef __STDC__
void resizeSliderRuler(Widget w, Dimension margin, Dimension width, Dimension height)
#else
void resizeSliderRuler(w, margin, width, height)
Widget w;
Dimension margin;
Dimension width, height;
#endif /*__STDC__*/
{
    RULER *ruler = &mainRuler;

    if (ruler->widget == (Widget)NULL) {
      createRuler(w, ruler);

      /*  Set up (reasonable) initial ramp values. */
      ruler->low = SBMIN - LO2;
      ruler->high = ruler->low + (2 * SBMAX) + (SBMAX - SBMIN);
    }

    ruler->margin = margin;
    ruler->width = width;
    ruler->height = height;
    if (ruler->height < 1)
      ruler->height = 1;

    return;
}
