#include "xcorf.h"

#include <Xm/DrawingA.h>

#define MAXCORFS    4
#define MAXEXTENT 200

/*  For two dimension arrays below, index 0 is LSB; 1 is USB. */

typedef struct {
  int which;                   /* Marker identifying this corf [0..3]. */
  double offset;     /* Offset in MHz of edge of widget to corf value. */
  double extent;                        /* Size in MHz of corf widget. */
  Boolean valid;       /* True if this corf is selectable and visible. */
  Boolean isusb;        /* True if this corf is in the upper sideband. */
  Widget widget;         /* Toggle widgets in each drawingArea widget. */
  Dimension bw;                  /* BorderWidth of each toggle widget. */
  Dimension width;               /* Current width of toggle in pixels. */
  Dimension height;             /* Current height of toggle in pixels. */
  struct {          /* Structure which contains information on pixmap. */
    int depth;                                     /* Depth of Widget. */
    Pixmap pixmap;                                  /* Private Pixmap. */
    Dimension shadowThickness;     /* ShadowThickness of Label Widget. */
    GC bottomShadowGC;                         /* GC of bottom shadow. */
    GC topShadowGC;                               /* GC of top shadow. */
    GC foregroundGC;                        /* GC of foreground color. */
  } pixmapStruct;
} CORF;

static Dimension parentWidth[2];       /* Width of drawingArea widget. */
static Dimension parentHeight[2];     /* Height of drawingArea widget. */
static double parentScale[2];               /* Pixel/MHz scale factor. */

static CORF corfList[MAXCORFS+MAXCORFS];

/***********************************************************************/
#ifdef __STDC__
static void redrawCorfPixmap(CORF *corf)
#else
static void redrawCorfPixmap(corf)
CORF *corf;
#endif /*__STDC__*/
{
    register int ypos, ymax;

    XFillRectangle(XtDisplay(corf->widget), corf->pixmapStruct.pixmap,
      corf->pixmapStruct.foregroundGC, 0, 0, corf->width, corf->height);

    (void)_XmDrawShadows(XtDisplay(corf->widget), corf->pixmapStruct.pixmap,
      corf->pixmapStruct.topShadowGC, corf->pixmapStruct.bottomShadowGC,
      0, 0, corf->width, corf->height, corf->pixmapStruct.shadowThickness,
      XmSHADOW_OUT);

    /*  Draw a line at the offset position. */

    if (corf->extent > 0) {
      ymax = corf->height - 2;
      ypos = ymax * corf->offset / corf->extent;
      if (corf->isusb != True) ypos = ymax - ypos;

      if ((ypos > 1) && (ypos < ymax)) {
        XDrawLine(XtDisplay(corf->widget), corf->pixmapStruct.pixmap,
          corf->pixmapStruct.bottomShadowGC, 1, ypos, (corf->width - 2), ypos);

        ypos--;
        XDrawLine(XtDisplay(corf->widget), corf->pixmapStruct.pixmap,
          corf->pixmapStruct.topShadowGC, 1, ypos, (corf->width - 2), ypos);
      }
    }

    return;
}

/***********************************************************************/
#ifdef __STDC__
static void positionCorf(CORF *corf)
#else
static void positionCorf(corf)
CORF *corf;
#endif /*__STDC__*/
{
    int indx;
    double offset;
    Position x, y;

    offset = ((LO2 + Global->corfs[corf->which]) * Global->doppler) - LO2;
    offset -= corf->offset;
    if (corf->isusb == True) {
      indx = 1;
      offset = offset - (SBMIN - LO2);
    } else {
      indx = 0;
      offset = (SBMAX - LO2) - offset - corf->extent;
    }

#if 0
    if (offset < 0)
      offset = 0;
#else
    if (offset + corf->extent < 0)
      offset = -corf->extent;
#endif

    if (offset > (SBMAX - SBMIN))
      offset = (double)(SBMAX - SBMIN);

    x = (Position)(corf->which * corf->width);
    if (x > (Position)(parentWidth[indx] - corf->width))
      x = (Position)(parentWidth[indx] - corf->width);

    y = (Position)((offset * parentScale[indx]) + 0.5);

    XtMoveWidget(corf->widget, x, y);

    return;
}

/***********************************************************************/
#ifdef __STDC__
static void redrawCorf(CORF *corf)
#else
static void redrawCorf(corf)
CORF *corf;
#endif /*__STDC__*/
{
    int indx;
    double extent, offset;

    indx = (corf->isusb == True);
    getCorfSizes((corf->which + 1), &extent, &offset);
    corf->offset = offset;
    corf->extent = extent;

    corf->width = parentWidth[indx] / 4;
    corf->height = (corf->extent * parentScale[indx]) + 0.5;
    if (corf->height < 10)
      corf->height = 10;

    if (corf->pixmapStruct.pixmap != None)
      redrawCorfPixmap(corf);

    XtResizeWidget(corf->widget, corf->width, corf->height, corf->bw);

    /*  Dump the pixmap that contains the corf graphics. */

    if (corf->pixmapStruct.pixmap != None)
      XCopyArea(XtDisplay(corf->widget), corf->pixmapStruct.pixmap,
        XtWindow(corf->widget), corf->pixmapStruct.foregroundGC,
        0, 0, corf->width, corf->height, 0, 0);

    positionCorf(corf);

    return;
}

/***********************************************************************/
#ifdef __STDC__
void updateCorfs(void)
#else
void updateCorfs()
#endif /*__STDC__*/
{
    register int j, corfNumber;
    CORF *corf;

    for (j = 0; j < (MAXCORFS+MAXCORFS); j++) {
      corf = &corfList[j];
      corfNumber = (j % MAXCORFS) + 1;

      if (isValidCorf(Global->mode, corfNumber) == True) {
        corf->valid = True;
        if (XtIsRealized(corf->widget)) {
          XtMapWidget(corf->widget);
          redrawCorf(corf);
        }
      } else {
        corf->valid = False;
        if (XtIsRealized(corf->widget))
          XtUnmapWidget(corf->widget);
      }
    }

    return;
}

/***********************************************************************/
#ifdef __STDC__
void redisplayCorfs(Boolean isusb)
#else
void redisplayCorfs(isusb)
Boolean isusb;
#endif /*__STDC__*/
{
    register int j, offset;

    offset = (isusb == True) ? MAXCORFS : 0;

    for (j = 0; j < MAXCORFS; j++)
      redrawCorf(&corfList[j + offset]);

    return;
}
/*
 *  This routine gets called ONLY when the parent that holds the
 *  corfs is resized.  If the corfs have Pixmaps, release them and
 *  then re-create them at the new size.  Also set the sizes for the
 *  corf widgets.
 */
/***********************************************************************/
#ifdef __STDC__
void resizeCorfs(Widget w, Boolean isusb)
#else
void resizeCorfs(w, isusb)
Widget w;
Boolean isusb;                        /* True if parent is usb window. */
#endif /*__STDC__*/
{
    register int j, indx, offset;
    Arg arg[10];
    Cardinal i;
    Dimension width, height;
    CORF *corf;

    i = 0;
    XtSetArg(arg[i], XmNwidth,        (XtArgVal)&width);  i++;
    XtSetArg(arg[i], XmNheight,      (XtArgVal)&height);  i++;
    XtGetValues(w, arg, i);

    indx = (isusb == True);
    offset = (isusb == True) ? MAXCORFS : 0;

    parentScale[indx] = (double)height / (double)(SBMAX - SBMIN);
    parentHeight[indx] = height;
    parentWidth[indx] = width;
    if (parentWidth[indx] < 16)
      parentWidth[indx] = 16;

    for (j = 0; j < MAXCORFS; j++) {
      corf = &corfList[j + offset];

      width = parentWidth[indx] / 4;
      height = (MAXEXTENT * parentScale[indx]) + 0.5;
      if (height < 10)
        height = 10;

      if (corf->pixmapStruct.pixmap != None)
        XFreePixmap(XtDisplay(corf->widget), corf->pixmapStruct.pixmap);

      corf->pixmapStruct.pixmap = XCreatePixmap(XtDisplay(corf->widget),
        RootWindowOfScreen(XtScreen(corf->widget)),
        width, height, corf->pixmapStruct.depth);

      redrawCorfPixmap(corf);
    }

    return;
}

/***********************************************************************/
#ifdef __STDC__
void moveCorf(int whichCorf)
#else
void moveCorf(whichCorf)
int whichCorf;
#endif /*__STDC__*/
{
    CORF *corf;

    if ((whichCorf < 1) || (whichCorf > MAXCORFS))     /* Corf number. */
      return;

    corf = &corfList[whichCorf-1];                        /* LSB Corf. */

    if (corf->widget && XtIsRealized(corf->widget))
      positionCorf(corf);

    corf = &corfList[whichCorf-1+MAXCORFS];               /* USB Corf. */

    if (corf->widget && XtIsRealized(corf->widget))
      positionCorf(corf);

    return;
}

/***********************************************************************/
#ifdef __STDC__
void scaleCorf(int whichCorf)
#else
void scaleCorf(whichCorf)
int whichCorf;
#endif /*__STDC__*/
{
    CORF *corf;

    if ((whichCorf < 1) || (whichCorf > MAXCORFS))     /* Corf number. */
      return;

    corf = &corfList[whichCorf-1];                        /* LSB Corf. */

    if ((corf->valid == True) && corf->widget && XtIsRealized(corf->widget))
      redrawCorf(corf);

    corf = &corfList[whichCorf-1+MAXCORFS];               /* USB Corf. */

    if ((corf->valid == True) && corf->widget && XtIsRealized(corf->widget))
      redrawCorf(corf);

    return;
}

/***********************************************************************/
#ifdef __STDC__
void initCorfs(Widget parent, Boolean isusb)
#else
void initCorfs(parent, isusb)
Widget parent;      /* DrawingArea widget where toggles will be drawn. */
Boolean isusb;       /* True if DrawingArea represents the USB window. */
#endif /*__STDC__*/
{
    char name[50];
    register int j, offset;
    int depth;
    Arg arg[10];
    Cardinal i;
    Dimension bw, st;
    Pixel background, foreground;
    Pixel topShadowColor, bottomShadowColor;
    Pixmap topShadowPixmap, bottomShadowPixmap;
    Widget sb;
    CORF *corf;

    offset = (isusb == True) ? MAXCORFS : 0;

    for (j = 0; j < MAXCORFS; j++) {
      corf = &corfList[j + offset];
      corf->which = j;
      corf->isusb = isusb;

      (void)sprintf(name, "corfPixmap_%d", (j+1));

      i = 0;
      sb = XmCreateDrawingArea(parent, name, arg, i);
      XtManageChild(sb);

      i = 0;
      XtSetArg(arg[i], XmNdepth,                 (XtArgVal)&depth);  i++;
      XtSetArg(arg[i], XmNborderWidth,              (XtArgVal)&bw);  i++;
      XtSetArg(arg[i], XmNshadowThickness,          (XtArgVal)&st);  i++;
      XtSetArg(arg[i], XmNbackground,       (XtArgVal)&background);  i++;
      XtSetArg(arg[i], XmNforeground,       (XtArgVal)&foreground);  i++;
      XtSetArg(arg[i], XmNtopShadowColor,         &topShadowColor);  i++;
      XtSetArg(arg[i], XmNbottomShadowColor,   &bottomShadowColor);  i++;
      XtSetArg(arg[i], XmNtopShadowPixmap,       &topShadowPixmap);  i++;
      XtSetArg(arg[i], XmNbottomShadowPixmap, &bottomShadowPixmap);  i++;
      XtGetValues(sb, arg, i);

      corf->bw = bw;
      corf->widget = sb;
      corf->offset = 0;
      corf->extent = 1;
      corf->pixmapStruct.depth = depth;
      corf->pixmapStruct.shadowThickness = st;
      corf->pixmapStruct.foregroundGC = getForegroundGC(sb, background);
      corf->pixmapStruct.bottomShadowGC = getShadowGC(sb,
        bottomShadowColor, foreground, bottomShadowPixmap);
      corf->pixmapStruct.topShadowGC = getShadowGC(sb,
        topShadowColor, foreground, topShadowPixmap);
      corf->pixmapStruct.pixmap = None;
    }

    return;
}
