#include "xcorf.h"

#include <Xm/DrawingA.h>

typedef struct {
   double value;                                        /* LO1 in GHz. */
   double minimum;                   /* The left extreme value in GHz. */
   double maximum;                  /* The right extreme value in GHz. */
   double slider_size;                            /* (2*SBMAX) in GHz. */
   double slider_bucket;                                /* LO2 in GHz. */

   double aspect_x;                 /* The scale factor in pixels/GHz. */

   double step;                    /* The major tick step size in GHz. */
   int numTicks;  /* The number of tick marks between each major step. */

   short slider_x;           /* The left edge of the slider in pixels. */
   short slider_y;            /* The top edge of the slider in pixels. */
   short slider_width;           /* The width of the slider in pixels. */
   short slider_height;         /* The height of the slider in pixels. */
   short slider_gap;                    /* The value of LO2 in pixels. */

   short slider_area_x;     /* Left edge of the slider area in pixels. */
   short slider_area_y;      /* Top edge of the slider area in pixels. */
   short slider_area_width;     /* The width of slider area in pixels. */
   short slider_area_height;   /* The height of slider area in pixels. */

   Dimension shadowThickness;
   Drawable pixmap;
   GC foreground_GC;
   GC top_shadow_GC;
   GC bottom_shadow_GC;
   Widget widget;

   struct {
     Boolean inMotion;                   /* Slider motion in progress. */
     Position dx;                       /* Initial position of slider. */
     Position x;                                  /* Current location. */
   } tmp;
} SLIDER;

static SLIDER *slider = (SLIDER *)NULL;

/***********************************************************************/
#ifdef __STDC__
static void calcSliderRect(void)
#else
static void calcSliderRect()
#endif /*__STDC__*/
{
    int minSliderWidth = 6;
    int minSliderHeight = 1;
    int hitTheWall = 0;
    double range, trueSize, factor, slideSize, bucket, offset;

    trueSize = slider->slider_area_width;

    /* Total number of user units displayed */
    range = slider->maximum - slider->minimum;

    /* A niave notion of pixels per user unit */
    factor = trueSize / range;

    /* A naive notion of the size of the slider in pixels */
    slideSize = slider->slider_size * factor;
    bucket = slider->slider_bucket * factor;

    /* Don't let the slider get too small */
    slider->slider_width = (int)(slideSize + 0.5);
    if (slider->slider_width <= minSliderWidth)
      slider->slider_width = hitTheWall = minSliderWidth;

    slider->slider_height = slider->slider_area_height;
    if (slider->slider_height < minSliderHeight)
      slider->slider_height = minSliderHeight;

    slider->slider_gap = (int)(bucket + 0.5);
    if (slider->slider_gap > (slider->slider_width / 2))
      slider->slider_gap = (slider->slider_width / 2);

    if (hitTheWall > 0) {
      /*
       *  The slider has not been allowed to take on its true
       *  proportionate size (it would have been too small).  This
       *  breaks proportionality of the slider and the conversion
       *  between pixels and user units.
       *
       *  The factor needs to be tweaked in this case.
       */
      trueSize -= hitTheWall; /* actual pixels available */
      range -= slider->slider_size; /* actual range */
      if (range == 0) range = 1;
      factor = trueSize / range;
    }

    /* Many parentheses to explicitly control type conversion. */
    offset = slider->value - (slider->slider_size / 2) - slider->minimum;
    slider->slider_x = ((int)((offset * factor) + 0.5)) + slider->slider_area_x;
    slider->slider_y = slider->slider_area_y;
    /*
     *  One final adjustment (of questionable value--preserved
     *  for visual backward compatibility).
     */
    if ((slider->slider_x + slider->slider_width) > (slider->slider_area_x
        + slider->slider_area_width)) {
      slider->slider_x = slider->slider_area_x
        + slider->slider_area_width - slider->slider_width;
    }

    slider->aspect_x = factor;

    computeStepSize((Dimension)slider->slider_area_width,
      slider->minimum, slider->maximum, &slider->step, &slider->numTicks);

    return;
}

/*
 *  Draw the slider graphic (shadowed rectangle) into the pixmap.
 */
/***********************************************************************/
#ifdef __STDC__
static void drawSliderPixmap(Widget w)
#else
static void drawSliderPixmap(w)
Widget w;
#endif /*__STDC__*/
{
    register int xpos;
    register int slider_width = slider->slider_width;
    register int slider_height = slider->slider_height;
    register Dimension shadowThickness = slider->shadowThickness;
    register Drawable sliderPixmap = slider->pixmap;

    XFillRectangle(XtDisplay(w), sliderPixmap, slider->foreground_GC,
      0, 0, slider_width, slider_height);

    (void)_XmDrawShadows(XtDisplay(w), sliderPixmap,
      slider->top_shadow_GC, slider->bottom_shadow_GC,
      0, 0, slider_width, slider_height, shadowThickness,
      XmSHADOW_OUT);

    /*  Draw a line in the middle. */
    xpos = (slider_width / 2) - 1;
    XDrawLine(XtDisplay(w), sliderPixmap, slider->bottom_shadow_GC,
      xpos, ((slider_height / 2) + 1), xpos, (slider_height - 2));

    xpos = slider_width / 2;
    XDrawLine(XtDisplay(w), sliderPixmap, slider->top_shadow_GC,
      xpos, ((slider_height / 2) + 1), xpos, (slider_height - 2));

    /*  Now, draw a line on the inside of each bucket. */
    xpos = (slider_width / 2) - slider->slider_gap - 1;
    XDrawLine(XtDisplay(w), sliderPixmap, slider->bottom_shadow_GC,
      xpos, 1, xpos, (slider_height - 2));

    xpos = (slider_width / 2) - slider->slider_gap;
    XDrawLine(XtDisplay(w), sliderPixmap, slider->top_shadow_GC,
      xpos, 1, xpos, (slider_height - 2));

    xpos = (slider_width / 2) + slider->slider_gap - 1;
    XDrawLine(XtDisplay(w), sliderPixmap, slider->bottom_shadow_GC,
      xpos, 1, xpos, (slider_height - 2));

    xpos = (slider_width / 2) + slider->slider_gap;
    XDrawLine(XtDisplay(w), sliderPixmap, slider->top_shadow_GC,
      xpos, 1, xpos, (slider_height - 2));

    return;
}

/***********************************************************************/
#ifdef __STDC__
GC getForegroundGC(Widget w, Pixel fg)
#else
GC getForegroundGC(w, fg)
Widget w;
Pixel fg;
#endif /*__STDC__*/
{
    XGCValues values;
    XtGCMask  valueMask;

    valueMask = GCForeground | GCGraphicsExposures;
    values.foreground = fg;
    values.graphics_exposures = False;

    return(XtGetGC(w, valueMask, &values));
}

/*  Get the graphics context used for drawing the top shadow. */
/***********************************************************************/
#ifdef __STDC__
GC getShadowGC(Widget w, Pixel fg, Pixel bg, Pixmap pix)
#else
GC getShadowGC(w, fg, bg, pix)
Widget w;
Pixel fg;
Pixel bg;
Pixmap pix;
#endif /*__STDC__*/
{
   XGCValues values;
   XtGCMask valueMask;

   valueMask = GCForeground | GCBackground;
   values.foreground = fg;
   values.background = bg;

   if ((pix != None) && (pix != XmUNSPECIFIED_PIXMAP)) {
      valueMask |= GCFillStyle | GCTile;
      values.fill_style = FillTiled;
      values.tile = pix;
   }

    return(XtGetGC(w, valueMask, &values));
}

/***********************************************************************/
#ifdef __STDC__
static void createSlider(Widget w)
#else
static void createSlider(w)
Widget w;
#endif /*__STDC__*/
{
    Arg arg[10];
    Cardinal i;
    Pixel background, foreground, top_shadow_color, bottom_shadow_color;
    Pixmap top_shadow_pixmap, bottom_shadow_pixmap;

    slider = XtNew(SLIDER);

    i = 0;
    XtSetArg(arg[i], XmNbackground,                   &background);  i++;
    XtSetArg(arg[i], XmNforeground,                   &foreground);  i++;
    XtSetArg(arg[i], XmNtopShadowColor,         &top_shadow_color);  i++;
    XtSetArg(arg[i], XmNbottomShadowColor,   &bottom_shadow_color);  i++;
    XtSetArg(arg[i], XmNtopShadowPixmap,       &top_shadow_pixmap);  i++;
    XtSetArg(arg[i], XmNbottomShadowPixmap, &bottom_shadow_pixmap);  i++;
    XtGetValues(w, arg, i);

    slider->widget = w;
    slider->foreground_GC = getForegroundGC(w, background);
    slider->top_shadow_GC = getShadowGC(w,
      top_shadow_color, foreground, top_shadow_pixmap);
    slider->bottom_shadow_GC = getShadowGC(w,
      bottom_shadow_color, foreground, bottom_shadow_pixmap);

    slider->pixmap = None;

    slider->slider_size = (SBMAX + SBMAX) / 1000.0;   /* (MHz -> GHz). */
    slider->slider_bucket = LO2 / 1000.0;             /* (MHz -> GHz). */

    slider->aspect_x = 1.0;
    slider->tmp.inMotion = False;

    return;
}

/*
 *  Process resizes on the widget by destroying and recreating the
 *  slider pixmap.  Also draws the correct sized slider onto the pixmap.
 */
/***********************************************************************/
#ifdef __STDC__
void resizeSlider(Widget w)
#else
void resizeSlider(w)
Widget w;
#endif /*__STDC__*/
{
    int depth;
    Arg arg[10];
    Cardinal i;
    Dimension ht, st;
    Dimension width, height;

    ht = 2; /* primitive.highlight_thickness */

    i = 0;
    XtSetArg(arg[i], XmNshadowThickness, (XtArgVal)&st);  i++;
    XtSetArg(arg[i], XmNwidth,        (XtArgVal)&width);  i++;
    XtSetArg(arg[i], XmNheight,      (XtArgVal)&height);  i++;
    XtSetArg(arg[i], XmNdepth,        (XtArgVal)&depth);  i++;
    XtGetValues(w, arg, i);

    height /= 2;

    slider->shadowThickness = st;
    slider->slider_area_x = ht + st;
    slider->slider_area_width = width - (2 * (ht + st));
    if ((Dimension)(2 * (ht + st)) > height)
      slider->slider_area_y = height / 2;
    else
      slider->slider_area_y = height + ht + st;
    slider->slider_area_height = height - (2 * (ht + st));

    if (slider->slider_area_width <= 0)
      slider->slider_area_width = 1;
    if (slider->slider_area_height <= 0)
      slider->slider_area_height = 1;

    if (slider->pixmap != None)
      XFreePixmap(XtDisplay(w), slider->pixmap);

    slider->pixmap = XCreatePixmap(XtDisplay(w),
      RootWindowOfScreen(XtScreen(w)), slider->slider_area_width,
      slider->slider_area_height, depth);

    resizeSliderRuler(w, (Dimension)slider->slider_area_x,
      (Dimension)slider->slider_area_width, height);

    calcSliderRect();

    drawSliderPixmap(w);

    return;
}

/*  General redisplay function called on exposure events. */
/***********************************************************************/
#ifdef __STDC__
void redisplaySlider(Widget w)
#else
void redisplaySlider(w)
Widget w;
#endif /*__STDC__*/
{
    calcSliderRect();

    if (slider->pixmap != None)
      drawSliderPixmap(w);

    redrawSliderRuler(w, slider->minimum, slider->maximum, slider->step,
      slider->numTicks);

    /*  Dump the pixmap that contains the slider graphics. */
    if (slider->pixmap != None)
      XCopyArea(XtDisplay(w), slider->pixmap, XtWindow(w),
        slider->foreground_GC, 0, 0, slider->slider_width,
        slider->slider_height, slider->slider_x, slider->slider_y);

    return;
}

/*
 *  Clear the through area at the current slider position,
 *  recompute the slider coordinates and redraw the slider
 *  the window by copying from the pixmap graphics.
 */
/***********************************************************************/
#ifdef __STDC__
void redrawSliderWindow(Widget w)
#else
void redrawSliderWindow(w)
Widget w;
#endif /*__STDC__*/
{
    if (XtIsRealized(w))
      XClearArea(XtDisplay(w), XtWindow(w),
        (int)slider->slider_area_x, (int)slider->slider_area_y,
        (unsigned int)slider->slider_area_width,
        (unsigned int)slider->slider_area_height, (Bool)FALSE);

    calcSliderRect();

    /*  Dump the pixmap that contains the slider graphics. */
    if ((XtIsRealized(w)) && (slider->pixmap != None))
      XCopyArea(XtDisplay(w), slider->pixmap, XtWindow(w),
        slider->foreground_GC, 0, 0, slider->slider_width,
        slider->slider_height, slider->slider_x, slider->slider_y);

    return;
}

/***********************************************************************/
#ifdef __STDC__
void setSliderRange(Widget w, double low, double high)
#else
void setSliderRange(w, low, high)
Widget w;
double low, high;
#endif /*__STDC__*/
{
    double offset;

    if (slider == (SLIDER *)NULL) {
      createSlider(w);
      slider->value = (low + high) / 2;
    }

    if ((high - low) < slider->slider_size)
      high = low + slider->slider_size;

    slider->minimum = low;          /* Minimum window Frequency (GHz). */
    slider->maximum = high;         /* Maximum window Frequency (GHz). */

    /*  Truncate and redraw as appropriate. */
    offset = slider->value - (slider->slider_size / 2);  /* Left edge. */
    if (offset >= (slider->maximum - slider->slider_size))
      offset = slider->maximum - slider->slider_size;

    if (offset <= slider->minimum)
      offset = slider->minimum;

    offset += (slider->slider_size / 2);  /* Reset position to middle. */
    slider->value = offset;

    redisplaySlider(w);

    return;
}

/***********************************************************************/
#ifdef __STDC__
void adjustSliderRange(Boolean increase)
#else
void adjustSliderRange(increase)
Boolean increase;
#endif /*__STDC__*/
{
    double low, high, offset;

    if (slider == (SLIDER *)NULL)
      return;

    low = slider->minimum;
    high = slider->maximum;
    offset = high - low;

    if (increase == True)
      offset *= 2;
    else
      offset /= 2;

    /* Limit requests that are too small or too large. */
    if (offset < (2 * slider->slider_size))
      offset = 2 * slider->slider_size;
    else if (offset > (Global->freqmax - Global->freqmin))
      offset = (Global->freqmax - Global->freqmin);
    /*
     *  Try to center this new range around the slider's current
     *  value.  Also, truncate with respect to the Global limits,
     *  as appropriate.
     */
    slider->minimum = slider->value - (offset / 2);
    if (slider->minimum < Global->freqmin)
      slider->minimum = Global->freqmin;

    slider->maximum = slider->minimum + offset;
    if (slider->maximum > Global->freqmax) {
      slider->maximum = Global->freqmax;
      slider->minimum = slider->maximum - offset;
      if (slider->minimum < Global->freqmin)
        slider->minimum = Global->freqmin;
    }

    redisplaySlider(slider->widget);

    return;
}

/*
 *  The input value is the slider value in GHz.  It represents LO1, or
 *  the center of the slider.
 */
/***********************************************************************/
#ifdef __STDC__
void setSliderValue(double value)
#else
void setSliderValue(value)
double value;
#endif /*__STDC__*/
{
    double offset, range;
    Boolean adjust;

    if (slider == (SLIDER *)NULL)
      return;

    if (value == slider->value)                   /* No change needed. */
      return;

    slider->value = value;

    offset = slider->value - (slider->slider_size / 2);  /* Left edge. */
    range = slider->maximum - slider->minimum;
    adjust = False;

    if (offset > (slider->maximum - slider->slider_size)) {
      slider->maximum = offset + slider->slider_size;
      slider->minimum = slider->maximum - range;
      adjust = True;
    } else if (offset < slider->minimum) {
      slider->minimum = offset;
      slider->maximum = slider->minimum + range;
      adjust = True;
    }

    if (adjust == True)
      setSliderRange(slider->widget, slider->minimum, slider->maximum);
    else
      redrawSliderWindow(slider->widget);

    setDrawingValue(False, slider->value);
    setDrawingValue(True, slider->value);

    return;
}

/***********************************************************************/
#ifdef __STDC__
void sliderStart(Widget w, int xpos)
#else
void sliderStart(w, xpos)
Widget w;
int xpos;
#endif /*__STDC__*/
{
    if ((!XtIsRealized(w)) || (slider == (SLIDER *)NULL))
      return;

    slider->tmp.inMotion = True;
    slider->tmp.dx = (Position)xpos - slider->slider_x;
    slider->tmp.x = slider->slider_x;

    return;
}

/***********************************************************************/
#ifdef __STDC__
void sliderStop(Widget w, int xpos)
#else
void sliderStop(w, xpos)
Widget w;
int xpos;
#endif /*__STDC__*/
{
    int maxx;
    double value;

    if ((!XtIsRealized(w)) || (slider == (SLIDER *)NULL))
      return;

    slider->tmp.x = (Position)xpos - slider->tmp.dx;

    if (slider->tmp.x < 0)
      slider->tmp.x = 0;

    maxx = slider->slider_area_x + slider->slider_area_width;
    maxx -= slider->slider_width;

    if (slider->tmp.x > (Position)maxx)
      slider->tmp.x = (Position)maxx;

    value = (slider->tmp.x - slider->slider_area_x) / slider->aspect_x;
    value += slider->minimum;

    if (value < slider->minimum)
      value = slider->minimum;
    else if (value > (slider->maximum - slider->slider_size))
      value = slider->maximum - slider->slider_size;

    value += (slider->slider_size / 2);       /* Move to LO1 position. */
    setLO1(value);

    slider->tmp.inMotion = False;

    return;
}

/***********************************************************************/
#ifdef __STDC__
void sliderMove(Widget w, int xpos)
#else
void sliderMove(w, xpos)
Widget w;
int xpos;
#endif /*__STDC__*/
{
    int maxx;
    double value;

    if ((!XtIsRealized(w)) || (slider == (SLIDER *)NULL))
      return;

    if (slider->tmp.inMotion != True)
      return;

    slider->tmp.x = (Position)xpos - slider->tmp.dx;

    if (slider->tmp.x < slider->slider_area_x)
      slider->tmp.x = slider->slider_area_x;

    maxx = slider->slider_area_x + slider->slider_area_width;
    maxx -= slider->slider_width;

    if (slider->tmp.x > (Position)maxx)
      slider->tmp.x = (Position)maxx;

    value = (slider->tmp.x - slider->slider_area_x) / slider->aspect_x;
    value += slider->minimum;

    if (value < slider->minimum)
      value = slider->minimum;
    else if (value > (slider->maximum - slider->slider_size))
      value = slider->maximum - slider->slider_size;

    value += (slider->slider_size / 2);       /* Move to LO1 position. */
    setLO1(value);

    return;
}
