#include "xcorf.h"

#include <Xm/ArrowB.h>
#include <Xm/DrawingA.h>
#include <Xm/RowColumn.h>
#include <Xm/SelectioB.h>
#include <Xm/TextF.h>
#include <Xm/ToggleB.h>

/***********************************************************************/
/* ARGSUSED */
#ifdef __STDC__
static void cancelCorf(Widget w, XtPointer client_data, XtPointer call_data)
#else
static void cancelCorf(w, client_data, call_data)
Widget w;
XtPointer client_data;  /* Unused. */
XtPointer call_data;    /* Unused. */
#endif /*__STDC__*/
{
    XtDestroyWidget(w);

    return;
}

/***********************************************************************/
#ifdef __STDC__
static void okCorf(Widget w, XtPointer client_data, XtPointer call_data)
#else
static void okCorf(w, client_data, call_data)
Widget w;
XtPointer client_data;
XtPointer call_data;
#endif /*__STDC__*/
{
    char *string;
    int which;
    double corfValue;
    Boolean okay;
    XmSelectionBoxCallbackStruct *scb;

    which = (int)client_data;
    scb = (XmSelectionBoxCallbackStruct *)call_data;

    /* Get the corf value string from the file selection box. */
    okay = XmStringGetLtoR(scb->value, XmFONTLIST_DEFAULT_TAG, &string);
    if (okay == True) {
      if (sscanf(string, "%lg", &corfValue) != 1)
        okay = False;
      XtFree(string);
    }

    XtDestroyWidget(w);

    if ((okay == True) && (which > 0) && (which <= 4))
      setCorf(Global->mainWindow, which, corfValue);

    return;
}

/***********************************************************************/
/* ARGSUSED */
#ifdef __STDC__
void setCorfCB(Widget w, XtPointer client_data, XtPointer call_data)
#else
void setCorfCB(w, client_data, call_data)
Widget w;
XtPointer client_data;
XtPointer call_data;   /* Unused */
#endif /*__STDC__*/
{
    int which;
    Cardinal i;
    Arg arg[5];
    Widget popup;
    XmString Label;

    which = (int)client_data;
    if ((which < 1) || (which > 4))
      return;

    i = 0;
    Label = XmStringCreateLocalized("Input Corf Frequency (MHz):");
    XtSetArg(arg[i], XmNselectionLabelString, Label); i++;
    popup = XmCreatePromptDialog(w, "corfDialog", arg, i);
    XtAddCallback(popup, XmNokCallback, okCorf, (XtPointer)which);
    XtAddCallback(popup, XmNcancelCallback, cancelCorf, (XtPointer)which);
    XtAddCallback(popup, XmNhelpCallback, HelpCB, (XtPointer)HELPINCORF);
    XmStringFree(Label);
    XtManageChild(popup);

    return;
}

/***********************************************************************/
/* ARGSUSED */
#ifdef __STDC__
void sidebandCallback(Widget w, XtPointer client_data, XtPointer call_data)
#else
void sidebandCallback(w, client_data, call_data)
Widget w;
XtPointer client_data;
XtPointer call_data;    /* Unused */
#endif /*__STDC__*/
{
    Boolean state;
    int button;
    XmToggleButtonCallbackStruct *scb;

    scb = (XmToggleButtonCallbackStruct *)call_data;
    button = (int)client_data;       /* Get the button number pressed. */

    if (scb->set != True)
      return;

    state = (button == 0) ? True : False;

    if (state == Global->usb)
      return;

    Global->usb = state;

    if (Global->debug > 0)
      (void)printf("Sideband set to [%s]\n",
        ((Global->usb == True) ? "usb" : "lsb"));

    updateLO1();

    return;
}

/***********************************************************************/
#ifdef __STDC__
void modeCallback(Widget w, XtPointer client_data, XtPointer call_data)
#else
void modeCallback(w, client_data, call_data)
Widget w;
XtPointer client_data;
XtPointer call_data;
#endif /*__STDC__*/
{
    int mode;
    XmToggleButtonCallbackStruct *scb;

    scb = (XmToggleButtonCallbackStruct *)call_data;
    mode = (int)client_data;                      /* Get the new mode. */
    mode++;                       /* Go from 0 based to 1 based index. */

    if ((scb->set == True) && (mode != Global->mode))
      setMode(XtParent(XtParent(w)), mode);

    return;
}

/***********************************************************************/
/* ARGSUSED */
#ifdef __STDC__
void optionCallback(Widget w, XtPointer client_data, XtPointer call_data)
#else
void optionCallback(w, client_data, call_data)
Widget w;               /* Unused */
XtPointer client_data;
XtPointer call_data;    /* Unused */
#endif /*__STDC__*/
{
    Boolean state;

    state = (Boolean)client_data;

    if (XmToggleButtonGetState(w) == False)
      return;

    if (state == Global->option)
      return;

    Global->option = state;

    if (Global->debug > 0)
      (void)printf("Cross/Auto Option set to [%s].\n",
        ((Global->option == True) ? "cross" : "auto"));

    Global->numchans = NUMCHANS;
    if (Global->option != True)
      Global->numchans *= 2;

    updateRestFQ();
    updateChannels();

    return;
}

/***********************************************************************/
#ifdef __STDC__
void corfCallback(Widget w, XtPointer client_data, XtPointer call_data)
#else
void corfCallback(w, client_data, call_data)
Widget w;
XtPointer client_data;
XtPointer call_data;
#endif /*__STDC__*/
{
    char errmsg[256];
    int whichCorf;
    double corfValue;
    XmScaleCallbackStruct *scb;

    whichCorf = (int)client_data;
    scb = (XmScaleCallbackStruct *)call_data;

    switch (scb->reason) {
      case XmCR_DRAG:
      case XmCR_VALUE_CHANGED:
        corfValue = scb->value / 1000.0;                /* khz -> Mhz. */
        /*
         *  The following section is unfortunately necessary because
         *  the Scale widget does not allow me to control the value
         *  associated with the item XmNincrement.  If the difference
         *  between the current corf value and the requested value
         *  is less than SYNTHSTEP, then the requested value is
         *  increased to be SYNTHSTEP.
         */
        {
            int sign;
            double diff;

            if (corfValue != Global->corfs[whichCorf-1]) {
              if (corfValue > Global->corfs[whichCorf-1]) {
                sign = 1;
                diff = corfValue - Global->corfs[whichCorf-1];
              } else {
                sign = -1;
                diff = Global->corfs[whichCorf-1] - corfValue;
              }

              if (diff < SYNTHSTEP)
                corfValue = Global->corfs[whichCorf-1] + (sign * SYNTHSTEP);
            }
        }
        if (corfValue < CORFMIN)
          corfValue = CORFMIN;
        break;
      default:
        (void)sprintf(errmsg, "Widget [%s] should not be calling corfCallback",
          XtName(w));
        Warning(errmsg);
        return;
    }

    setCorf(XtParent(w), whichCorf, corfValue);

    return;
}

/***********************************************************************/
#ifdef __STDC__
void bwCallback(Widget w, XtPointer client_data, XtPointer call_data)
#else
void bwCallback(w, client_data, call_data)
Widget w;
XtPointer client_data;
XtPointer call_data;
#endif /*__STDC__*/
{
    char errmsg[256];
    int whichBW, intValue;
    double bw, toggleValue;
    Widget tog;
    XmRowColumnCallbackStruct *rccb;

    whichBW = (int)client_data;
    rccb = (XmRowColumnCallbackStruct *)call_data;

    tog = rccb->widget;

    if (XmToggleButtonGetState(tog) == False)
      return;

    if (sscanf(XtName(tog), "button_%d", &intValue) != 1) {
      (void)sprintf(errmsg,
        "Trouble getting bandwidth requested from Widget name [%s].",
        XtName(tog));
      Warning(errmsg);
      return;
    }

    toggleValue = BWMIN * (1 << intValue);
    if ((toggleValue < BWMIN) || (toggleValue > BWMAX)) {
      (void)sprintf(errmsg,
        "Illegal bandwidth requested by [%s]; [%G] <= [%G] <= [%G] MHz",
        XtName(w), (double)BWMIN, toggleValue, (double)BWMAX);
      Warning(errmsg);
      return;
    }

    switch (whichBW) {
      case 1: case 2: case 3: case 4:
        bw = toggleValue;
        break;
      default:
        (void)sprintf(errmsg, "Widget [%s] should not be calling bwCallback",
          XtName(w));
        Warning(errmsg);
        return;
    }

    setBW(XtParent(w), whichBW, bw);

    return;
}

/***********************************************************************/
#ifdef __STDC__
void smallRulerCallback(Widget w, XtPointer client_data, XtPointer call_data)
#else
void smallRulerCallback(w, client_data, call_data)
Widget w;
XtPointer client_data;
XtPointer call_data;
#endif /*__STDC__*/
{
    char errmsg[256];
    Boolean isusb;
    XmDrawingAreaCallbackStruct *dacb;
    XSetWindowAttributes xswa;

    static Boolean firstTimeUSB = True;
    static Boolean firstTimeLSB = True;

    isusb = (Boolean)client_data;
    dacb = (XmDrawingAreaCallbackStruct *)call_data;

    switch (dacb->reason) {
      case XmCR_INPUT:
        /* NULL */ ;
        break;
      case XmCR_EXPOSE:
        /*
         *  Change (only once) the bit gravity of the Drawing Area;
         *  the default is "north-west" and we want "forget" so that
         *  resize always generates exposure events.
         */
        if ((isusb == True) && (firstTimeUSB == True)) {
          firstTimeUSB = False;
          xswa.bit_gravity = ForgetGravity;
          XChangeWindowAttributes(XtDisplay(w), XtWindow(w),
            CWBitGravity, &xswa);
        }
        if ((isusb == False) && (firstTimeLSB == True)) {
          firstTimeLSB = False;
          xswa.bit_gravity = ForgetGravity;
          XChangeWindowAttributes(XtDisplay(w), XtWindow(w),
            CWBitGravity, &xswa);
        }
        redrawSmallRuler(isusb);
        break;
      case XmCR_RESIZE:
        resizeSmallRuler(w, False, isusb);
        break;
      default:
        (void)sprintf(errmsg,
          "Widget [%s] should not be calling smallRulerCallback", XtName(w));
        Warning(errmsg);
        return;
    }

    return;
}

/***********************************************************************/
#ifdef __STDC__
void drawingCallback(Widget w, XtPointer client_data, XtPointer call_data)
#else
void drawingCallback(w, client_data, call_data)
Widget w;
XtPointer client_data;
XtPointer call_data;
#endif /*__STDC__*/
{
    char errmsg[256];
    Boolean isusb;
    XmDrawingAreaCallbackStruct *dacb;
    XSetWindowAttributes xswa;

    static Boolean firstTimeUSB = True;
    static Boolean firstTimeLSB = True;

    isusb = (Boolean)client_data;
    dacb = (XmDrawingAreaCallbackStruct *)call_data;

    switch (dacb->reason) {
      case XmCR_EXPOSE:
        /*
         *  Change (only once) the bit gravity of the Drawing Area;
         *  the default is "north-west" and we want "forget" so that
         *  resize always generates exposure events.
         */
        if ((isusb == True) && (firstTimeUSB == True)) {
          firstTimeUSB = False;
          xswa.bit_gravity = ForgetGravity;
          XChangeWindowAttributes(XtDisplay(w), XtWindow(w),
            CWBitGravity, &xswa);
        }
        if ((isusb == False) && (firstTimeLSB == True)) {
          firstTimeLSB = False;
          xswa.bit_gravity = ForgetGravity;
          XChangeWindowAttributes(XtDisplay(w), XtWindow(w),
            CWBitGravity, &xswa);
        }
        redisplayDrawing(isusb);
        break;
      case XmCR_RESIZE:
        resizeDrawing(w, isusb, False);
        break;
      default:
        (void)sprintf(errmsg,
          "Widget [%s] should not be calling drawingCallback", XtName(w));
        Warning(errmsg);
        return;
    }

    return;
}

/***********************************************************************/
#ifdef __STDC__
void corfdrawCallback(Widget w, XtPointer client_data, XtPointer call_data)
#else
void corfdrawCallback(w, client_data, call_data)
Widget w;
XtPointer client_data;
XtPointer call_data;
#endif /*__STDC__*/
{
    char errmsg[256];
    Boolean isusb;
    XmDrawingAreaCallbackStruct *dacb;
    XSetWindowAttributes xswa;

    static Boolean firstTimeUSB = True;
    static Boolean firstTimeLSB = True;

    isusb = (Boolean)client_data;
    dacb = (XmDrawingAreaCallbackStruct *)call_data;

    switch (dacb->reason) {
      case XmCR_EXPOSE:
        /*
         *  Change (only once) the bit gravity of the Drawing Area;
         *  the default is "north-west" and we want "forget" so that
         *  resize always generates exposure events.
         */
        if ((isusb == True) && (firstTimeUSB == True)) {
          firstTimeUSB = False;
          xswa.bit_gravity = ForgetGravity;
          XChangeWindowAttributes(XtDisplay(w), XtWindow(w),
            CWBitGravity, &xswa);
        }
        if ((isusb == False) && (firstTimeLSB == True)) {
          firstTimeLSB = False;
          xswa.bit_gravity = ForgetGravity;
          XChangeWindowAttributes(XtDisplay(w), XtWindow(w),
            CWBitGravity, &xswa);
        }
        redisplayCorfs(isusb);
        break;
      case XmCR_RESIZE:
        resizeCorfs(w, isusb);
        break;
      default:
        (void)sprintf(errmsg,
          "Widget [%s] should not be calling drawingCallback", XtName(w));
        Warning(errmsg);
        return;
    }

    return;
}

/***********************************************************************/
/* ARGSUSED */
#ifdef __STDC__
void rulerCallback(Widget w, XtPointer client_data, XtPointer call_data)
#else
void rulerCallback(w, client_data, call_data)
Widget w;
XtPointer client_data;  /* Unused */
XtPointer call_data;
#endif /*__STDC__*/
{
    char errmsg[256];
    XmDrawingAreaCallbackStruct *dacb;
    XSetWindowAttributes xswa;

    static unsigned int button;
    static Boolean firstTime = True;

    dacb = (XmDrawingAreaCallbackStruct *)call_data;

    switch (dacb->reason) {
      case XmCR_INPUT:
        if (dacb->event->type == ButtonPress) {
          sliderStart(w, dacb->event->xbutton.x);
          button = dacb->event->xbutton.button;
        } else if (dacb->event->type == ButtonRelease) {
          if (button == dacb->event->xbutton.button)
            sliderStop(w, dacb->event->xbutton.x);
        } else if (dacb->event->type == MotionNotify) {
          sliderMove(w, dacb->event->xmotion.x);
        } /* Simply ignore any other events. */
        break;
      case XmCR_EXPOSE:
        /*
         *  Change (only once) the bit gravity of the Drawing Area;
         *  the default is "north-west" and we want "forget" so that
         *  resize always generates exposure events.
         */
        if (firstTime == True) {
          firstTime = False;
          xswa.bit_gravity = ForgetGravity;
          XChangeWindowAttributes(XtDisplay(w), XtWindow(w),
            CWBitGravity, &xswa);
        }
        redisplaySlider(w);
        break;
      case XmCR_RESIZE:
        resizeSlider(w);
        break;
      default:
        (void)sprintf(errmsg,
          "Widget [%s] should not be calling rulerCallback", XtName(w));
        Warning(errmsg);
        return;
    }

    return;
}

/***********************************************************************/
/* ARGSUSED */
#ifdef __STDC__
void arrowCallback(Widget w, XtPointer client_data, XtPointer call_data)
#else
void arrowCallback(w, client_data, call_data)
Widget w;              /* Unused */
XtPointer client_data;
XtPointer call_data;
#endif /*__STDC__*/
{
    Boolean isUpArrow;
    XmArrowButtonCallbackStruct *abcb;

    isUpArrow = (Boolean)client_data;
    abcb = (XmArrowButtonCallbackStruct *)call_data;

    if (abcb->click_count == 1)   /* Only process single click events. */
      adjustSliderRange(isUpArrow);

    return;
}

/***********************************************************************/
#ifdef __STDC__
void channelRulerCB(Widget w, XtPointer client_data, XtPointer call_data)
#else
void channelRulerCB(w, client_data, call_data)
Widget w;
XtPointer client_data;
XtPointer call_data;
#endif /*__STDC__*/
{
    char errmsg[256];
    Boolean isusb;
    XmDrawingAreaCallbackStruct *dacb;
    XSetWindowAttributes xswa;

    static Boolean firstTimeUSB = True;
    static Boolean firstTimeLSB = True;

    isusb = (Boolean)client_data;
    dacb = (XmDrawingAreaCallbackStruct *)call_data;

    switch (dacb->reason) {
      case XmCR_INPUT:
        /* NULL */ ;
        break;
      case XmCR_EXPOSE:
        /*
         *  Change (only once) the bit gravity of the Drawing Area;
         *  the default is "north-west" and we want "forget" so that
         *  resize always generates exposure events.
         */
        if ((isusb == True) && (firstTimeUSB == True)) {
          firstTimeUSB = False;
          xswa.bit_gravity = ForgetGravity;
          XChangeWindowAttributes(XtDisplay(w), XtWindow(w),
            CWBitGravity, &xswa);
        }
        if ((isusb == False) && (firstTimeLSB == True)) {
          firstTimeLSB = False;
          xswa.bit_gravity = ForgetGravity;
          XChangeWindowAttributes(XtDisplay(w), XtWindow(w),
            CWBitGravity, &xswa);
        }
        redrawChannelRuler(isusb);
        break;
      case XmCR_RESIZE:
        resizeSmallRuler(w, True, isusb);
        break;
      default:
        (void)sprintf(errmsg,
          "Widget [%s] should not be calling channelRulerCB", XtName(w));
        Warning(errmsg);
        return;
    }

    return;
}

/***********************************************************************/
#ifdef __STDC__
void channelDrawCB(Widget w, XtPointer client_data, XtPointer call_data)
#else
void channelDrawCB(w, client_data, call_data)
Widget w;
XtPointer client_data;
XtPointer call_data;
#endif /*__STDC__*/
{
    char errmsg[256];
    Boolean isusb, reset;
    XmDrawingAreaCallbackStruct *dacb;
    XSetWindowAttributes xswa;

    static unsigned int button = AnyButton;
    static Boolean firstTimeUSB = True;
    static Boolean firstTimeLSB = True;

    isusb = (Boolean)client_data;
    dacb = (XmDrawingAreaCallbackStruct *)call_data;

    switch (dacb->reason) {
      case XmCR_INPUT:
        if ((dacb->event->type == ButtonPress) && (button == AnyButton)) {
          button = dacb->event->xbutton.button;
        } else if (dacb->event->type == ButtonRelease) {
          if (button == dacb->event->xbutton.button) {
            reset = (button == Button3) ? True : False;
            channelPress(isusb, reset, dacb->event->xbutton.y);
            button = AnyButton;
          }
        } /* Simply ignore any other events. */

        if (Global->debug > 1) {
          if ((dacb->event->type == ButtonPress) ||
              (dacb->event->type == ButtonRelease)) {
                (void)printf("Channel Input: usb/x/y: %c %d %d\n",
                  ((isusb == True) ? 'T' : 'F'),
                  dacb->event->xbutton.x, dacb->event->xbutton.y);
          }
        }

        break;
      case XmCR_EXPOSE:
        /*
         *  Change (only once) the bit gravity of the Drawing Area;
         *  the default is "north-west" and we want "forget" so that
         *  resize always generates exposure events.
         */
        if ((isusb == True) && (firstTimeUSB == True)) {
          firstTimeUSB = False;
          xswa.bit_gravity = ForgetGravity;
          XChangeWindowAttributes(XtDisplay(w), XtWindow(w),
            CWBitGravity, &xswa);
        }
        if ((isusb == False) && (firstTimeLSB == True)) {
          firstTimeLSB = False;
          xswa.bit_gravity = ForgetGravity;
          XChangeWindowAttributes(XtDisplay(w), XtWindow(w),
            CWBitGravity, &xswa);
        }
        redisplayChannels(isusb);
        break;
      case XmCR_RESIZE:
        resizeDrawing(w, isusb, True);
        break;
      default:
        (void)sprintf(errmsg,
          "Widget [%s] should not be calling channelDrawCB", XtName(w));
        Warning(errmsg);
        return;
    }

    return;
}
