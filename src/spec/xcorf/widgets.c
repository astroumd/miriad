#include "xcorf.h"

#include <Xm/ArrowB.h>
#include <Xm/CascadeB.h>
#include <Xm/Command.h>
#include <Xm/DrawingA.h>
#include <Xm/FileSB.h>
#include <Xm/Form.h>
#include <Xm/Frame.h>
#include <Xm/Label.h>
#include <Xm/LabelG.h>
#include <Xm/MainW.h>
#include <Xm/MessageB.h>
#include <Xm/PushB.h>
#include <Xm/RowColumn.h>
#include <Xm/Scale.h>
#include <Xm/SelectioB.h>
#include <Xm/SeparatoG.h>
#include <Xm/TextF.h>
#include <Xm/ToggleB.h>

static char *SetupName = (char *)NULL;
static char *FileName = (char *)NULL;

typedef void (*dialogCBProc)(              /* This is used by dialogCB */
#if NeedFunctionPrototypes
    Widget              /* widget */,
    double              /* argument */
#endif
);

/***********************************************************************/
/* ARGSUSED */
#ifdef __STDC__
static Boolean exitWorkProc(XtPointer client_data)
#else
static Boolean exitWorkProc(client_data)
XtPointer client_data; /* Unused */
#endif /*__STDC__*/
{
    (void)exit(0);
    /* NOTREACHED */
}

/***********************************************************************/
/* ARGSUSED */
#ifdef __STDC__
static void quitCB(Widget w, XtPointer client_data, XtPointer call_data)
#else
static void quitCB(w, client_data, call_data)
Widget w;
XtPointer client_data; /* Unused */
XtPointer call_data;   /* Unused */
#endif /*__STDC__*/
{
    Widget top;

    for (top = w; XtParent(top); top = XtParent(top))
      /* NULL */ ;
    XtUnmapWidget(top);                  /* Make it disappear quickly. */
    XtDestroyWidget(top);
    XtAppAddWorkProc(XtWidgetToApplicationContext(w),
      exitWorkProc, (XtPointer)NULL);

    return;
}

/***********************************************************************/
/* ARGSUSED */
#ifdef __STDC__
static void cancelCB(Widget w, XtPointer client_data, XtPointer call_data)
#else
static void cancelCB(w, client_data, call_data)
Widget w;
XtPointer client_data;
XtPointer call_data;   /* Unused. */
#endif /*__STDC__*/
{
    XtUnmanageChild(w);

    if (((int)client_data > 1) && (FileName != (char *)NULL)) {
      XtFree(FileName);
      FileName = (char *)NULL;
    }

    return;
}

/***********************************************************************/
#ifdef __STDC__
static void setupCB(Widget w, XtPointer client_data, XtPointer call_data)
#else
static void setupCB(w, client_data, call_data)
Widget w;
XtPointer client_data;
XtPointer call_data;
#endif /*__STDC__*/
{
    char *setup;
    Boolean doWrite;
    XmSelectionBoxCallbackStruct *scb;
    
    doWrite = (Boolean)client_data;
    scb = (XmSelectionBoxCallbackStruct *)call_data;

    /* Get the setup string from the file selection box. */
    if (XmStringGetLtoR(scb->value, XmFONTLIST_DEFAULT_TAG, &setup)) {

      /*  Make a private copy of the setup name for use by future popups. */
      if (SetupName != (char *)NULL) XtFree(SetupName);
      SetupName = XtNewString(setup);

      if (doWrite == True) {
        if (Global->debug > 0)
          (void)printf("Write to file [%s] and setup [%s]\n", FileName, setup);
        writeSetup(FileName, setup);
      } else {
        if (Global->debug > 0)
          (void)printf("Read from file [%s] and setup [%s]\n", FileName, setup);
        readSetup(FileName, setup);
      }

      XtFree(setup);
    }

    XtUnmanageChild(w);

    if (FileName != (char *)NULL) {
      XtFree(FileName);
      FileName = (char *)NULL;
    }

    return;
}

/***********************************************************************/
#ifdef __STDC__
static void acceptCB(Widget w, XtPointer client_data, XtPointer call_data)
#else
static void acceptCB(w, client_data, call_data)
Widget w;
XtPointer client_data;
XtPointer call_data;
#endif /*__STDC__*/
{
    char *filename;
    char errmsg[1000];
    int which;
    Cardinal i;
    Arg arg[5];
    static Widget rpw = (Widget)NULL;
    static Widget wpw = (Widget)NULL;
    XmFileSelectionBoxCallbackStruct *fcb;
    XmString Label;

    /*  Popdown the file selection box. */
    XtUnmanageChild(w);

    which = (int)client_data;
    if ((which < 0) || (which > 3))
      return;

    fcb = (XmFileSelectionBoxCallbackStruct *)call_data;

    /*  Get the filename from the file selection box. */
    if (XmStringGetLtoR(fcb->value, XmFONTLIST_DEFAULT_TAG, &filename)) {
      if (filename[strlen(filename) - 1] == '/') {
        (void)sprintf(errmsg, "No file name specified...?\n[%s]\n", filename);
        XtFree(filename);
        Warning(errmsg);
        return;
      }

      switch (which) {
        case 0:
          setInputFile(filename, False);
          refreshAllDrawings();
          break;
        case 1:
          setInputFile(filename, True);
          refreshAllDrawings();
          break;
        case 2:
          if (rpw == (Widget)NULL) {
            i = 0;
            Label = XmStringCreateLocalized("Setup Name:");
            XtSetArg(arg[i], XmNselectionLabelString, Label); i++;
            rpw = XmCreatePromptDialog(w, "setupNameDialog", arg, i);
            XtAddCallback(rpw, XmNokCallback, setupCB, (XtPointer)False);
            XtAddCallback(rpw, XmNcancelCallback, cancelCB, (XtPointer)which);
            XtAddCallback(rpw, XmNhelpCallback, HelpCB, (XtPointer)HELPSETUP);
            XmStringFree(Label);
          }

          /*  Make a private copy of the file name for use by setupCB. */
          if (FileName != (char *)NULL) XtFree(FileName);
          FileName = XtNewString(filename);

          /*  Initialize the prompt with the current setup name. */
          i = 0;
          Label = XmStringCreateLocalized(SetupName);
          XtSetArg(arg[i], XmNtextString, Label); i++;
          XtSetValues(rpw, arg, i);
          XmStringFree(Label);
          XtManageChild(rpw);
          break;
        case 3:
          if (wpw == (Widget)NULL) {
            i = 0;
            Label = XmStringCreateLocalized("Setup Name:");
            XtSetArg(arg[i], XmNselectionLabelString, Label); i++;
            wpw = XmCreatePromptDialog(w, "setupNameDialog", arg, i);
            XtAddCallback(wpw, XmNokCallback, setupCB, (XtPointer)True);
            XtAddCallback(wpw, XmNcancelCallback, cancelCB, (XtPointer)which);
            XtAddCallback(wpw, XmNhelpCallback, HelpCB, (XtPointer)HELPSETUP);
            XmStringFree(Label);
          }

          /*  Make a private copy of the file name for use by setupCB. */
          if (FileName != (char *)NULL) XtFree(FileName);
          FileName = XtNewString(filename);

          /*  Initialize the prompt with the current setup name. */
          i = 0;
          Label = XmStringCreateLocalized(SetupName);
          XtSetArg(arg[i], XmNtextString, Label); i++;
          XtSetValues(wpw, arg, i);
          XmStringFree(Label);
          XtManageChild(wpw);
          break;
      }
      XtFree(filename);
    }

    return;
}

/***********************************************************************/
/* ARGSUSED */
#ifdef __STDC__
static void openCB(Widget w, XtPointer client_data, XtPointer call_data)
#else
static void openCB(w, client_data, call_data)
Widget w;
XtPointer client_data;
XtPointer call_data;   /* Unused */
#endif /*__STDC__*/
{
    int which, hcd;
    Cardinal i;
    Arg arg[5];
    static Widget file[4];

    which = (int)client_data;
    if ((which < 0) || (which > 3))
      return;

    if (file[which] == (Widget)NULL) {
      hcd = (which < 3) ? HELPINFILES : HELPOUTFILES ;
      i = 0;
      file[which] = XmCreateFileSelectionDialog(Global->mainWindow,
        "file selection dialog", arg, i);

      XtAddCallback(file[which], XmNokCallback, acceptCB, (XtPointer)which);
      XtAddCallback(file[which], XmNcancelCallback, cancelCB, (XtPointer)which);
      XtAddCallback(file[which], XmNhelpCallback, HelpCB, (XtPointer)hcd);
    }

    XtManageChild(file[which]);

    return;
}

/***********************************************************************/
/* ARGSUSED */
#ifdef __STDC__
static void dialogCB(Widget w, XtPointer client_data, XtPointer call_data)
#else
static void dialogCB(w, client_data, call_data)
Widget w;
XtPointer client_data;
XtPointer call_data;     /* Unused */
#endif /*__STDC__*/
{
    char *string;
    double argument;
    dialogCBProc fnc;

    string = XmTextFieldGetString(w);
    argument = atof(string);
    XtFree(string);

    fnc = (dialogCBProc)client_data;
    (*fnc)(XtParent(w), argument);

    return;
}

/***********************************************************************/
#ifdef __STDC__
static Widget buildDialog(Widget parent, Arg inargs[], Cardinal nargs,
  String label, String title, int pos, XtCallbackProc cbProc, XtPointer cbData)
#else
static Widget buildDialog(parent, inargs, nargs, label, title, pos, cbProc, cbData)
Widget parent;
Arg inargs[];
Cardinal nargs;
String label;
String title;
int pos;
XtCallbackProc cbProc;
XtPointer cbData;
#endif /*__STDC__*/
{
    Arg arg[10];
    Cardinal i;
    Widget frame, form, w;
    XmString Label;

    /*-----------------------------------------------------------------*/
    /*  Dialog Composites (label : text). */
    /*-----------------------------------------------------------------*/

    frame = XmCreateFrame(parent, "dialogFrame", inargs, nargs);
    XtManageChild(frame);

    i = 0;
    form = XmCreateForm(frame, "dialogForm", arg, i);
    XtManageChild(form);

    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,               XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNbottomAttachment,            XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNleftAttachment,          XmATTACH_POSITION);  i++;
    XtSetArg(arg[i], XmNleftPosition,                (XtArgVal)pos);  i++;
    XtSetArg(arg[i], XmNrightAttachment,             XmATTACH_FORM);  i++;
    w = XmCreateTextField(form, label, arg, i);
    XtManageChild(w);
    XtAddCallback(w, XmNactivateCallback, cbProc, (XtPointer)cbData);

    Label = XmStringCreateLocalized(title);

    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,               XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNbottomAttachment,            XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNleftAttachment,              XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNrightAttachment,           XmATTACH_WIDGET);  i++;
    XtSetArg(arg[i], XmNrightWidget,                   (XtArgVal)w);  i++;
    XtSetArg(arg[i], XmNlabelString,               (XtArgVal)Label);  i++;
    w = XmCreateLabel(form, "dialogLabel", arg, i);
    XtManageChild(w);
    XmStringFree(Label);

    return(frame);
}

/***********************************************************************/
/* ARGSUSED */
#ifdef __STDC__
static void okayFQCB(Widget w, XtPointer client_data, XtPointer call_data)
#else
static void okayFQCB(w, client_data, call_data)
Widget w;
XtPointer client_data; /* Unused. */
XtPointer call_data;   /* Unused. */
#endif /*__STDC__*/
{
    XtUnmanageChild(w);

    return;
}

/***********************************************************************/
/* ARGSUSED */
#ifdef __STDC__
static void resetFQCB(Widget w, XtPointer client_data, XtPointer call_data)
#else
static void resetFQCB(w, client_data, call_data)
Widget w;
XtPointer client_data; /* Unused. */
XtPointer call_data;   /* Unused. */
#endif /*__STDC__*/
{
    resetAllRestFQ();
    updateRestFQ();
    updateChannels();

    return;
}

/***********************************************************************/
/* ARGSUSED */
#ifdef __STDC__
static void restFQCB(Widget w, XtPointer client_data, XtPointer call_data)
#else
static void restFQCB(w, client_data, call_data)
Widget w;
XtPointer client_data;
XtPointer call_data;   /* Unused. */
#endif /*__STDC__*/
{
    char *string;
    char value[80];
    int k, which;
    double freq;
    Boolean isusb, state;

    which = (int)client_data;
    if ((which < 1) || (which > 16))
      return;

    string = XmTextFieldGetString(w);
    freq = atof(string);                          /* Frequency in GHz. */
    XtFree(string);

    if (which > 8) {
      which -= 8;
      isusb = True;
    } else {
      isusb = False;
    }
    which--;

    for (k = 0; k < 2; k++) {
      state = (k == 0) ? False : True ;
      if ((Global->option == True) && (state != isusb))
        continue;

      setRestFQ(which, state, freq);
    }

    if (Global->option == True) {
      if (getRestFQ(which, isusb, &freq)) {
        (void)sprintf(value, "%.6f", freq);
        string = value + strlen(value) - 1;
        while ((string >= value) && (*string == '0'))
          *string-- = '\0';
        XmTextFieldSetString(w, value);
        setLastPos(w);
        redisplayChannels(isusb);
      }
    } else {
      updateRestFQ();
      updateChannels();
    }

    return;
}

/***********************************************************************/
/* ARGSUSED */
#ifdef __STDC__
static void restFQPopup(Widget w, XtPointer client_data, XtPointer call_data)
#else
static void restFQPopup(w, client_data, call_data)
Widget w;
XtPointer client_data; /* Unused */
XtPointer call_data;   /* Unused */
#endif /*__STDC__*/
{
    char name[50], text[50];
    register int j;
    Cardinal i;
    Arg args[10];
    Widget rowc, dialog;
    static Widget popup = (Widget)NULL;
    XmString mtext, title, close, reset, help;

    if (popup == (Widget)NULL) {
      /* Create a Template style MessageBox dialog. */

      mtext = XmStringCreateLtoR("\
This input window permits the selection of individual\n\
rest frequencies for each correlator window.  Select\n\
the desired window item with the first mouse button\n\
and then enter the frequency value (in GHz).\n\n\
Select the Help button for more details.",
              XmSTRING_DEFAULT_CHARSET);
      title = XmStringCreateLtoR("Rest Frequency Dialog",
              XmSTRING_DEFAULT_CHARSET);
      close = XmStringCreateLtoR("Close", XmSTRING_DEFAULT_CHARSET);
      reset = XmStringCreateLtoR("Reset All", XmSTRING_DEFAULT_CHARSET);
      help  = XmStringCreateLtoR("Help",  XmSTRING_DEFAULT_CHARSET);

      i = 0;
      XtSetArg(args[i], XmNdefaultButtonType,     XmDIALOG_NONE);  i++;
      XtSetArg(args[i], XmNautoUnmanage,        (XtArgVal)False);  i++;
      XtSetArg(args[i], XmNdialogTitle,         (XtArgVal)title);  i++;
      XtSetArg(args[i], XmNmessageString,       (XtArgVal)mtext);  i++;
      XtSetArg(args[i], XmNokLabelString,       (XtArgVal)close);  i++;
      XtSetArg(args[i], XmNcancelLabelString,   (XtArgVal)reset);  i++;
      XtSetArg(args[i], XmNhelpLabelString,      (XtArgVal)help);  i++;
      popup = XmCreateTemplateDialog(Global->mainWindow, "restFQbox", args, i);
      XmStringFree(help);
      XmStringFree(reset);
      XmStringFree(close);
      XmStringFree(title);
      XmStringFree(mtext);

      XtAddCallback(popup, XmNokCallback, okayFQCB, (XtPointer)NULL);
      XtAddCallback(popup, XmNcancelCallback, resetFQCB, (XtPointer)NULL);
      XtAddCallback(popup, XmNhelpCallback, HelpCB, (XtPointer)HELPRESTFQS);

      i = 0;
      XtSetArg(args[i], XmNnumColumns,              (XtArgVal)2);  i++;
      XtSetArg(args[i], XmNorientation,              XmVERTICAL);  i++;
      XtSetArg(args[i], XmNpacking,               XmPACK_COLUMN);  i++;
      XtSetArg(args[i], XmNrowColumnType,           XmWORK_AREA);  i++;
      rowc = XmCreateRowColumn(popup, "restFQRowColumn", args, i);
      XtManageChild(rowc);

      for (j = 1; j <= 16; j++) {
        i = 0;
        (void)sprintf(name, "restfqs_%d", j);
        (void)sprintf(text, "Window %d:",  j);
        dialog = buildDialog(rowc, args, i, name, text, 50,
          (XtCallbackProc)restFQCB, (XtPointer)j);
        XtManageChild(dialog);
      }
    }

    XtManageChild(popup);
    updateRestFQ();

    return;
}

/***********************************************************************/
/* ARGSUSED */
#ifdef __STDC__
static void debugCB(Widget w, XtPointer client_data, XtPointer call_data)
#else
static void debugCB(w, client_data, call_data)
Widget w;
XtPointer client_data;
XtPointer call_data;
#endif /*__STDC__*/
{
    int debugLevel;

    debugLevel = (int)client_data;
    if (debugLevel < 0) debugLevel = 0;
    if (debugLevel > 2) debugLevel = 2;

    if (debugLevel != Global->debug) {
      Global->debug = debugLevel;
      switch (Global->debug) {
        case 0:
          (void)printf("Turning off debug information...\n");
          break;
        case 1:
          (void)printf("Turning on general debug information...\n");
          break;
        case 2:
          (void)printf("Turning on detailed debug information...\n");
          break;
      }
    }

    return;
}

/***********************************************************************/
#ifdef __STDC__
static Widget buildCommandLevel(Widget parent)
#else
static Widget buildCommandLevel(parent)
Widget parent;
#endif /*__STDC__*/
{
    Arg arg[10];
    Cardinal i;
    Widget menuBar, menuPane, button, cascade;
    Widget subMenu;
    XmString label;

    i = 0;
    menuBar = XmCreateMenuBar(parent, "menuBar", arg, i);
    XtManageChild(menuBar);

    /*-----------------------------------------------------------------*/
    /*  Create the "File" PulldownMenu. */
    /*-----------------------------------------------------------------*/

    i = 0;
    menuPane = XmCreatePulldownMenu(menuBar, "menuPane", arg, i);

    label = XmStringCreateLocalized("Open Line File...");
    i = 0;
    XtSetArg(arg[i], XmNmnemonic, (XtArgVal)'O');  i++;
    XtSetArg(arg[i], XmNlabelString, (XtArgVal)label);  i++;
    button = XmCreatePushButton(menuPane, "openLineFile", arg, i);
    XtManageChild(button);
    XtAddCallback(button, XmNactivateCallback, openCB, (XtPointer)0);
    XmStringFree(label);

    label = XmStringCreateLocalized("Merge Line File...");
    i = 0;
    XtSetArg(arg[i], XmNmnemonic, (XtArgVal)'M');  i++;
    XtSetArg(arg[i], XmNlabelString, (XtArgVal)label);  i++;
    button = XmCreatePushButton(menuPane, "addLineFile", arg, i);
    XtManageChild(button);
    XtAddCallback(button, XmNactivateCallback, openCB, (XtPointer)1);
    XmStringFree(label);

    i = 0;
    button = XmCreateSeparatorGadget(menuPane, "separator", arg, i);
    XtManageChild(button);

    label = XmStringCreateLocalized("Read Setup File...");
    i = 0;
    XtSetArg(arg[i], XmNmnemonic, (XtArgVal)'R');  i++;
    XtSetArg(arg[i], XmNlabelString, (XtArgVal)label);  i++;
    button = XmCreatePushButton(menuPane, "openSetupFile", arg, i);
    XtManageChild(button);
    XtAddCallback(button, XmNactivateCallback, openCB, (XtPointer)2);
    XmStringFree(label);

    label = XmStringCreateLocalized("Write Setup File...");
    i = 0;
    XtSetArg(arg[i], XmNmnemonic, (XtArgVal)'W');  i++;
    XtSetArg(arg[i], XmNlabelString, (XtArgVal)label);  i++;
    button = XmCreatePushButton(menuPane, "saveSetupFile", arg, i);
    XtManageChild(button);
    XtAddCallback(button, XmNactivateCallback, openCB, (XtPointer)3);
    XmStringFree(label);

    i = 0;
    button = XmCreateSeparatorGadget(menuPane, "separator", arg, i);
    XtManageChild(button);

    i = 0;
    XtSetArg(arg[i], XmNmnemonic, (XtArgVal)'Q');  i++;
    button = XmCreatePushButton(menuPane, "Quit", arg, i);
    XtManageChild(button);
    XtAddCallback(button, XmNactivateCallback, quitCB, (XtPointer)NULL);

    /*-----------------------------------------------------------------*/
    /*  Bind the "File" PulldownMenu to the Menu Bar. */
    /*-----------------------------------------------------------------*/

    i = 0;
    XtSetArg(arg[i], XmNmnemonic, (XtArgVal)'F');  i++;
    XtSetArg(arg[i], XmNsubMenuId,     menuPane);  i++;
    cascade = XmCreateCascadeButton(menuBar, "File", arg, i);
    XtManageChild(cascade);

    /*-----------------------------------------------------------------*/
    /*  Create the "Options" PulldownMenu. */
    /*-----------------------------------------------------------------*/

    i = 0;
    menuPane = XmCreatePulldownMenu(menuBar, "menuPane", arg, i);

    label = XmStringCreateLocalized("Rest Frequencies...");
    i = 0;
    XtSetArg(arg[i], XmNmnemonic, (XtArgVal)'R');  i++;
    XtSetArg(arg[i], XmNlabelString, (XtArgVal)label);  i++;
    button = XmCreatePushButton(menuPane, "setRestFQ", arg, i);
    XtManageChild(button);
    XtAddCallback(button, XmNactivateCallback, restFQPopup, (XtPointer)NULL);
    XmStringFree(label);

    i = 0;
    subMenu = XmCreatePulldownMenu(menuPane, "subMenu", arg, i);

    i = 0;
    XtSetArg(arg[i], XmNmnemonic, (XtArgVal)'D');  i++;
    XtSetArg(arg[i], XmNsubMenuId,      subMenu);  i++;
    cascade = XmCreateCascadeButton(menuPane, "Debug...", arg, i);
    XtManageChild(cascade);

    label = XmStringCreateLocalized("No Information");
    i = 0;
    XtSetArg(arg[i], XmNmnemonic, (XtArgVal)'N');  i++;
    XtSetArg(arg[i], XmNlabelString, (XtArgVal)label);  i++;
    button = XmCreatePushButton(subMenu, "noneDebug", arg, i);
    XtManageChild(button);
    XtAddCallback(button, XmNactivateCallback, debugCB, (XtPointer)0);
    XmStringFree(label);

    label = XmStringCreateLocalized("Some Information");
    i = 0;
    XtSetArg(arg[i], XmNmnemonic, (XtArgVal)'S');  i++;
    XtSetArg(arg[i], XmNlabelString, (XtArgVal)label);  i++;
    button = XmCreatePushButton(subMenu, "someDebug", arg, i);
    XtManageChild(button);
    XtAddCallback(button, XmNactivateCallback, debugCB, (XtPointer)1);
    XmStringFree(label);

    label = XmStringCreateLocalized("A lot of Information");
    i = 0;
    XtSetArg(arg[i], XmNmnemonic, (XtArgVal)'A');  i++;
    XtSetArg(arg[i], XmNlabelString, (XtArgVal)label);  i++;
    button = XmCreatePushButton(subMenu, "tonsDebug", arg, i);
    XtManageChild(button);
    XtAddCallback(button, XmNactivateCallback, debugCB, (XtPointer)2);
    XmStringFree(label);

    i = 0;
    XtSetArg(arg[i], XmNmnemonic, (XtArgVal)'O');  i++;
    XtSetArg(arg[i], XmNsubMenuId,     menuPane);  i++;
    cascade = XmCreateCascadeButton(menuBar, "Options", arg, i);
    XtManageChild(cascade);

    /*-----------------------------------------------------------------*/
    /*  Create a "Help" PulldownMenu and bind it to the Menu Bar. */
    /*-----------------------------------------------------------------*/

    i = 0;
    menuPane = XmCreatePulldownMenu(menuBar, "menuPane", arg, i);

    label = XmStringCreateLocalized("General Help");
    i = 0;
    XtSetArg(arg[i], XmNlabelString, (XtArgVal)label);  i++;
    XtSetArg(arg[i], XmNmnemonic,      (XtArgVal)'G');  i++;
    button = XmCreatePushButton(menuPane, "generalHelp", arg, i);
    XtManageChild(button);
    XtAddCallback(button, XmNactivateCallback, HelpCB, (XtPointer)HELPGENERAL);
    XmStringFree(label);

    label = XmStringCreateLocalized("Examples");
    i = 0;
    XtSetArg(arg[i], XmNlabelString, (XtArgVal)label);  i++;
    XtSetArg(arg[i], XmNmnemonic,      (XtArgVal)'E');  i++;
    button = XmCreatePushButton(menuPane, "examples", arg, i);
    XtManageChild(button);
    XtAddCallback(button, XmNactivateCallback, HelpCB, (XtPointer)HELPEXAMPLE);
    XmStringFree(label);

    i = 0;
    label = XmStringCreateLocalized("Mode Settings");
    XtSetArg(arg[i], XmNlabelString, (XtArgVal)label);  i++;
    XtSetArg(arg[i], XmNmnemonic,      (XtArgVal)'M');  i++;
    button = XmCreatePushButton(menuPane, "modeHelp", arg, i);
    XtManageChild(button);
    XtAddCallback(button, XmNactivateCallback, HelpCB, (XtPointer)HELPMODE);
    XmStringFree(label);

    i = 0;
    label = XmStringCreateLocalized("Diagram of Modes");
    XtSetArg(arg[i], XmNlabelString, (XtArgVal)label);  i++;
    XtSetArg(arg[i], XmNmnemonic,      (XtArgVal)'D');  i++;
    button = XmCreatePushButton(menuPane, "drawingHelp", arg, i);
    XtManageChild(button);
    XtAddCallback(button, XmNactivateCallback, HelpCB, (XtPointer)HELPDRAWING);
    XmStringFree(label);

    label = XmStringCreateLocalized("Application Resources");
    i = 0;
    XtSetArg(arg[i], XmNlabelString, (XtArgVal)label);  i++;
    XtSetArg(arg[i], XmNmnemonic,      (XtArgVal)'A');  i++;
    button = XmCreatePushButton(menuPane, "resourceHelp", arg, i);
    XtManageChild(button);
    XtAddCallback(button, XmNactivateCallback, HelpCB, (XtPointer)HELPAPPDEFS);
    XmStringFree(label);

    label = XmStringCreateLocalized("Command Line Inputs");
    i = 0;
    XtSetArg(arg[i], XmNlabelString, (XtArgVal)label);  i++;
    XtSetArg(arg[i], XmNmnemonic,      (XtArgVal)'I');  i++;
    button = XmCreatePushButton(menuPane, "cmdLineHelp", arg, i);
    XtManageChild(button);
    XtAddCallback(button, XmNactivateCallback, HelpCB, (XtPointer)HELPCMDLINE);
    XmStringFree(label);

    i = 0;
    label = XmStringCreateLocalized("Slider Window");
    XtSetArg(arg[i], XmNlabelString, (XtArgVal)label);  i++;
    XtSetArg(arg[i], XmNmnemonic,      (XtArgVal)'S');  i++;
    button = XmCreatePushButton(menuPane, "sliderHelp", arg, i);
    XtManageChild(button);
    XtAddCallback(button, XmNactivateCallback, HelpCB, (XtPointer)HELPSLIDER);
    XmStringFree(label);

    i = 0;
    label = XmStringCreateLocalized("Corf Windows");
    XtSetArg(arg[i], XmNlabelString, (XtArgVal)label);  i++;
    XtSetArg(arg[i], XmNmnemonic,      (XtArgVal)'o');  i++;
    button = XmCreatePushButton(menuPane, "corfWinHelp", arg, i);
    XtManageChild(button);
    XtAddCallback(button, XmNactivateCallback, HelpCB, (XtPointer)HELPCORF);
    XmStringFree(label);

    i = 0;
    label = XmStringCreateLocalized("Channel Windows");
    XtSetArg(arg[i], XmNlabelString, (XtArgVal)label);  i++;
    XtSetArg(arg[i], XmNmnemonic,      (XtArgVal)'C');  i++;
    button = XmCreatePushButton(menuPane, "chanWinHelp", arg, i);
    XtManageChild(button);
    XtAddCallback(button, XmNactivateCallback, HelpCB, (XtPointer)HELPCHANS);
    XmStringFree(label);

    i = 0;
    label = XmStringCreateLocalized("Additional Help");
    XtSetArg(arg[i], XmNlabelString, (XtArgVal)label);  i++;
    XtSetArg(arg[i], XmNmnemonic,      (XtArgVal)'H');  i++;
    button = XmCreatePushButton(menuPane, "moreHelp", arg, i);
    XtManageChild(button);
    XtAddCallback(button, XmNactivateCallback, HelpCB, (XtPointer)HELPMISC);
    XmStringFree(label);

    i = 0;
    XtSetArg(arg[i], XmNmnemonic, (XtArgVal)'H');  i++;
    XtSetArg(arg[i], XmNsubMenuId, menuPane);  i++;
    cascade = XmCreateCascadeButton(menuBar, "Help", arg, i);
    XtManageChild(cascade);

    i = 0;
    XtSetArg(arg[i], XmNmenuHelpWidget, cascade);  i++;
    XtSetValues(menuBar, arg, i);

    return(menuBar);
}

/***********************************************************************/
#ifdef __STDC__
static Widget buildInputs(Widget parent, Arg inargs[], Cardinal nargs,
  double restfreq, double iffreq, double vlsr, Boolean usb)
#else
static Widget buildInputs(parent, inargs, nargs, restfreq, iffreq, vlsr, usb)
Widget parent;
Arg inargs[];
Cardinal nargs;
double restfreq, iffreq, vlsr;
Boolean usb;
#endif /*__STDC__*/
{
    int buttonSet;
    Arg arg[20];
    Cardinal i, nlist;
    Widget form, w, sideFrame;
    XmString Label;
    XmString list[2];

    /*-----------------------------------------------------------------*/
    /*  Create a Form to enclose the input widget collection. */
    /*-----------------------------------------------------------------*/

    form = XmCreateForm(parent, "inputsForm", inargs, nargs);
    XtManageChild(form);
    XtAddCallback(form, XmNhelpCallback, HelpCB, (XtPointer)HELPSLIDER);

    /*-----------------------------------------------------------------*/
    /*  Rest frequency dialog. */
    /*-----------------------------------------------------------------*/

    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,               XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNbottomAttachment,            XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNleftAttachment,              XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNrightAttachment,         XmATTACH_POSITION);  i++;
    XtSetArg(arg[i], XmNrightPosition,                (XtArgVal)25);  i++;
    w = buildDialog(form, arg, i, "restfreq", "Line Freq. (GHz):", 66,
      (XtCallbackProc)dialogCB, (XtPointer)setRestFreq);
    setRestFreq(w, restfreq);

    /*-----------------------------------------------------------------*/
    /*  Sideband toggle. */
    /*-----------------------------------------------------------------*/

    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,               XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNbottomAttachment,            XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNleftAttachment,          XmATTACH_POSITION);  i++;
    XtSetArg(arg[i], XmNleftPosition,                 (XtArgVal)25);  i++;
    XtSetArg(arg[i], XmNrightAttachment,         XmATTACH_POSITION);  i++;
    XtSetArg(arg[i], XmNrightPosition,                (XtArgVal)50);  i++;
    sideFrame = XmCreateFrame(form, "sbFrame", arg, i);
    XtManageChild(sideFrame);

    i = 0;
    sideFrame = XmCreateForm(sideFrame, "sbForm", arg, i);
    XtManageChild(sideFrame);

    Label = XmStringCreateLocalized("Sideband:");

    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,               XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNbottomAttachment,            XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNleftAttachment,              XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNrightAttachment,         XmATTACH_POSITION);  i++;
    XtSetArg(arg[i], XmNrightPosition,                (XtArgVal)50);  i++;
    XtSetArg(arg[i], XmNlabelString,               (XtArgVal)Label);  i++;
    w = XmCreateLabel(sideFrame, "sbLabel", arg, i);
    XtManageChild(w);
    XmStringFree(Label);

    list[0] = XmStringCreateLocalized("USB");
    list[1] = XmStringCreateLocalized("LSB");
    nlist = 2;
    buttonSet = 0;   /* This gets set correctly by setSB() call later. */

    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,               XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNbottomAttachment,            XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNleftAttachment,          XmATTACH_POSITION);  i++;
    XtSetArg(arg[i], XmNleftPosition,                 (XtArgVal)50);  i++;
    XtSetArg(arg[i], XmNrightAttachment,             XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNorientation,                  XmHORIZONTAL);  i++;
    XtSetArg(arg[i], XmNbuttons,                    (XtArgVal)list);  i++;
    XtSetArg(arg[i], XmNbuttonCount,               (XtArgVal)nlist);  i++;
    XtSetArg(arg[i], XmNbuttonSet,             (XtArgVal)buttonSet);  i++;
    XtSetArg(arg[i], XmNsimpleCallback, (XtArgVal)sidebandCallback);  i++;
    w = XmCreateSimpleRadioBox(sideFrame, "sideband", arg, i);
    XtManageChild(w);
    XmStringFree(list[0]);
    XmStringFree(list[1]);
    setSB(parent, usb);

    /*-----------------------------------------------------------------*/
    /*  IF frequency dialog. */
    /*-----------------------------------------------------------------*/

    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,               XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNbottomAttachment,            XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNleftAttachment,          XmATTACH_POSITION);  i++;
    XtSetArg(arg[i], XmNleftPosition,                 (XtArgVal)50);  i++;
    XtSetArg(arg[i], XmNrightAttachment,         XmATTACH_POSITION);  i++;
    XtSetArg(arg[i], XmNrightPosition,                (XtArgVal)75);  i++;
    w = buildDialog(form, arg, i, "iffreq", "IF Freq (MHz):", 66,
      (XtCallbackProc)dialogCB, (XtPointer)setIFFreq);
    setIFFreq(w, iffreq);

    /*-----------------------------------------------------------------*/
    /*  Velocity dialog. */
    /*-----------------------------------------------------------------*/

    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,               XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNbottomAttachment,            XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNleftAttachment,          XmATTACH_POSITION);  i++;
    XtSetArg(arg[i], XmNleftPosition,                 (XtArgVal)75);  i++;
    XtSetArg(arg[i], XmNrightAttachment,             XmATTACH_FORM);  i++;
    w = buildDialog(form, arg, i, "vlsr", "Vlsr (km/s):", 66,
      (XtCallbackProc)dialogCB, (XtPointer)setVlsr);
    setVlsr(w, vlsr);

    return(form);
}

/***********************************************************************/
#ifdef __STDC__
static void buildMainRuler(Widget parent, Arg inargs[], Cardinal nargs,
  double freq, double rulerWidth, XFontStruct *font)
#else
static void buildMainRuler(parent, inargs, nargs, freq, rulerWidth, font)
Widget parent;
Arg inargs[];
Cardinal nargs;
double freq, rulerWidth;
XFontStruct *font;
#endif /*__STDC__*/
{
    double rulerMin, rulerMax;
    Arg arg[20];
    Cardinal i;
    Widget arrow, form, frame, ruler;

    static String translations = "#override \n\
      <BtnMotion>:DrawingAreaInput() ManagerGadgetButtonMotion()\n\
      <BtnDown>:DrawingAreaInput()\n\
      <BtnUp>:DrawingAreaInput()\n\
    ";

    /*
     *  The main slider ruler window has two vertical arrows to the
     *  left of the ruler window.  These arrows control the width
     *  of the ruler in user units (GHz).
     */
    form = XmCreateForm(parent, "mainRulerForm", inargs, nargs);
    XtManageChild(form);
    XtAddCallback(form, XmNhelpCallback, HelpCB, (XtPointer)HELPSLIDER);

    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,        XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNbottomAttachment, XmATTACH_POSITION);  i++;
    XtSetArg(arg[i], XmNbottomPosition,        (XtArgVal)50);  i++;
    XtSetArg(arg[i], XmNleftAttachment,       XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNrightAttachment,      XmATTACH_NONE);  i++;
    XtSetArg(arg[i], XmNnavigationType,              XmNONE);  i++;
    frame = XmCreateFrame(form, "arrowFrame", arg, i);
    XtManageChild(frame);

    i = 0;
    XtSetArg(arg[i], XmNarrowDirection,          XmARROW_UP);  i++;
    XtSetArg(arg[i], XmNmultiClick,    XmMULTICLICK_DISCARD);  i++;
    arrow = XmCreateArrowButton(frame, "upArrow", arg, i);
    XtManageChild(arrow);
    XtAddCallback(arrow,  XmNactivateCallback, arrowCallback, (XtPointer)True);

    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,    XmATTACH_POSITION);  i++;
    XtSetArg(arg[i], XmNtopPosition,           (XtArgVal)50);  i++;
    XtSetArg(arg[i], XmNbottomAttachment,     XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNleftAttachment,       XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNrightAttachment,      XmATTACH_NONE);  i++;
    XtSetArg(arg[i], XmNnavigationType,              XmNONE);  i++;
    frame = XmCreateFrame(form, "arrowFrame", arg, i);
    XtManageChild(frame);

    i = 0;
    XtSetArg(arg[i], XmNarrowDirection,        XmARROW_DOWN);  i++;
    XtSetArg(arg[i], XmNmultiClick,    XmMULTICLICK_DISCARD);  i++;
    arrow = XmCreateArrowButton(frame, "downArrow", arg, i);
    XtManageChild(arrow);
    XtAddCallback(arrow,  XmNactivateCallback, arrowCallback, (XtPointer)False);

    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,        XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNbottomAttachment,     XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNleftAttachment,     XmATTACH_WIDGET);  i++;
    XtSetArg(arg[i], XmNleftWidget,         (XtArgVal)frame);  i++;
    XtSetArg(arg[i], XmNrightAttachment,      XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNnavigationType,              XmNONE);  i++;
    frame = XmCreateFrame(form, "mainRulerFrame", arg, i);
    XtManageChild(frame);

    i = 0;
    XtSetArg(arg[i], XmNuserData,            (XtArgVal)font);  i++;
    XtSetArg(arg[i], XmNnavigationType,              XmNONE);  i++;
    ruler = XmCreateDrawingArea(frame, "mainRuler", arg, i);
    XtManageChild(ruler);
    XtAddCallback(ruler,  XmNinputCallback, rulerCallback, (XtPointer)NULL);
    XtAddCallback(ruler, XmNexposeCallback, rulerCallback, (XtPointer)NULL);
    XtAddCallback(ruler, XmNresizeCallback, rulerCallback, (XtPointer)NULL);
    XtOverrideTranslations(ruler, XtParseTranslationTable(translations));

    rulerMin = freq - (rulerWidth / 2);
    rulerMax = rulerMin + rulerWidth;
    setSliderRange(ruler, rulerMin, rulerMax);

    return;
}

/***********************************************************************/
#ifdef __STDC__
static Widget buildCorfBW(Widget parent, Arg inargs[], Cardinal nargs, Cardinal which)
#else
static Widget buildCorfBW(parent, inargs, nargs, which)
Widget parent;
Arg inargs[];
Cardinal nargs;
Cardinal which;
#endif /*__STDC__*/
{
    char name[20], label[10];
    int buttonSet;
    Arg arg[20];
    Cardinal i, j;
    Cardinal nlist;
    Widget frame, form, lab1, scale, lab2, radio;
    XmString Label;
    XmString list[5];

    /*-----------------------------------------------------------------*/
    /* Make the Corf slider/BW toggle selectors. */
    /*-----------------------------------------------------------------*/

    buttonSet = 0;
    nlist = 0;
    list[nlist++] = XmStringCreateLocalized("6.25");
    list[nlist++] = XmStringCreateLocalized("12.5");
    list[nlist++] = XmStringCreateLocalized("25.0");
    list[nlist++] = XmStringCreateLocalized("50.0");
    list[nlist++] = XmStringCreateLocalized("100.0");

    (void)sprintf(name, "corfBWFrame_%d", which);
    frame = XmCreateFrame(parent, name, inargs, nargs);
    XtManageChild(frame);

    i = 0;
    form = XmCreateForm(frame, "corfBWForm", arg, i);
    XtManageChild(form);

    /*-----------------------------------------------------------------*/
    /* label(name) : scale(slider) */
    /*-----------------------------------------------------------------*/

    (void)sprintf(label, "Corf%d:", which);
    Label = XmStringCreateLocalized(label);

    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,               XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNbottomAttachment,        XmATTACH_POSITION);  i++;
    XtSetArg(arg[i], XmNbottomPosition,               (XtArgVal)40);  i++;
    XtSetArg(arg[i], XmNleftAttachment,              XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNrightAttachment,             XmATTACH_NONE);  i++;
    XtSetArg(arg[i], XmNalignment,                 XmALIGNMENT_END);  i++;
    XtSetArg(arg[i], XmNlabelString,               (XtArgVal)Label);  i++;
    lab1 = XmCreatePushButton(form, "corfLabel", arg, i);
    XtAddCallback(lab1, XmNactivateCallback, setCorfCB, (XtPointer)which);
    XtManageChild(lab1);
    XmStringFree(Label);

    (void)sprintf(name, "corf%d", which);

    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,               XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNbottomAttachment,        XmATTACH_POSITION);  i++;
    XtSetArg(arg[i], XmNbottomPosition,               (XtArgVal)40);  i++;
    XtSetArg(arg[i], XmNleftAttachment,            XmATTACH_WIDGET);  i++;
    XtSetArg(arg[i], XmNleftWidget,                 (XtArgVal)lab1);  i++;
    XtSetArg(arg[i], XmNrightAttachment,             XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNscaleMultiple,              (XtArgVal)6250);  i++;
    XtSetArg(arg[i], XmNminimum,                   (XtArgVal)90000);  i++;
    XtSetArg(arg[i], XmNmaximum,                  (XtArgVal)900000);  i++;
    XtSetArg(arg[i], XmNdecimalPoints,                 (XtArgVal)3);  i++;
    XtSetArg(arg[i], XmNorientation,                  XmHORIZONTAL);  i++;
    XtSetArg(arg[i], XmNshowValue,                  (XtArgVal)True);  i++;
    scale = XmCreateScale(form, name, arg, i);
    XtManageChild(scale);
    XtAddCallback(scale, XmNdragCallback, corfCallback, (XtPointer)which);
    XtAddCallback(scale, XmNvalueChangedCallback,
      corfCallback, (XtPointer)which);

    /*-----------------------------------------------------------------*/
    /* label(name) : radiobox(toggles) */
    /*-----------------------------------------------------------------*/

    (void)sprintf(label, "BW%d:", which);
    Label = XmStringCreateLocalized(label);

    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,           XmATTACH_POSITION);  i++;
    XtSetArg(arg[i], XmNtopPosition,                  (XtArgVal)50);  i++;
    XtSetArg(arg[i], XmNtopAttachment,             XmATTACH_WIDGET);  i++;
    XtSetArg(arg[i], XmNtopWidget,                 (XtArgVal)scale);  i++;
    XtSetArg(arg[i], XmNbottomAttachment,        XmATTACH_POSITION);  i++;
    XtSetArg(arg[i], XmNbottomPosition,               (XtArgVal)80);  i++;
    XtSetArg(arg[i], XmNleftAttachment,              XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNrightAttachment,  XmATTACH_OPPOSITE_WIDGET);  i++;
    XtSetArg(arg[i], XmNrightWidget,                (XtArgVal)lab1);  i++;
    XtSetArg(arg[i], XmNalignment,                 XmALIGNMENT_END);  i++;
    XtSetArg(arg[i], XmNlabelString,               (XtArgVal)Label);  i++;
    lab2 = XmCreateLabel(form, "bwLabel", arg, i);
    XtManageChild(lab2);
    XmStringFree(Label);

    (void)sprintf(name, "bwRadio_%d", which);

    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,    XmATTACH_OPPOSITE_WIDGET);  i++;
    XtSetArg(arg[i], XmNtopWidget,                  (XtArgVal)lab2);  i++;
    XtSetArg(arg[i], XmNbottomAttachment, XmATTACH_OPPOSITE_WIDGET);  i++;
    XtSetArg(arg[i], XmNbottomWidget,               (XtArgVal)lab2);  i++;
    XtSetArg(arg[i], XmNleftAttachment,            XmATTACH_WIDGET);  i++;
    XtSetArg(arg[i], XmNleftWidget,                 (XtArgVal)lab2);  i++;
    XtSetArg(arg[i], XmNrightAttachment,             XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNorientation,                  XmHORIZONTAL);  i++;
    XtSetArg(arg[i], XmNbuttons,                    (XtArgVal)list);  i++;
    XtSetArg(arg[i], XmNbuttonCount,               (XtArgVal)nlist);  i++;
    XtSetArg(arg[i], XmNbuttonSet,             (XtArgVal)buttonSet);  i++;
    radio = XmCreateSimpleRadioBox(form, name, arg, i);
    XtManageChild(radio);
    XtAddCallback(radio, XmNentryCallback, bwCallback, (XtPointer)which);
    for (j = 0; j < nlist; j++) {
      XmStringFree(list[j]);
    }

    Label = XmStringCreateLocalized("Vel:");

    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,           XmATTACH_POSITION);  i++;
    XtSetArg(arg[i], XmNtopPosition,                  (XtArgVal)80);  i++;
    XtSetArg(arg[i], XmNbottomAttachment,            XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNleftAttachment,              XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNrightAttachment,  XmATTACH_OPPOSITE_WIDGET);  i++;
    XtSetArg(arg[i], XmNrightWidget,                (XtArgVal)lab1);  i++;
    XtSetArg(arg[i], XmNalignment,                 XmALIGNMENT_END);  i++;
    XtSetArg(arg[i], XmNlabelString,               (XtArgVal)Label);  i++;
    lab2 = XmCreateLabel(form, "velLabel", arg, i);
    XtManageChild(lab2);
    XmStringFree(Label);

    Label = XmStringCreateLocalized("Range:");

    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,    XmATTACH_OPPOSITE_WIDGET);  i++;
    XtSetArg(arg[i], XmNtopWidget,                  (XtArgVal)lab2);  i++;
    XtSetArg(arg[i], XmNbottomAttachment, XmATTACH_OPPOSITE_WIDGET);  i++;
    XtSetArg(arg[i], XmNbottomWidget,               (XtArgVal)lab2);  i++;
    XtSetArg(arg[i], XmNleftAttachment,            XmATTACH_WIDGET);  i++;
    XtSetArg(arg[i], XmNleftWidget,                 (XtArgVal)lab2);  i++;
    XtSetArg(arg[i], XmNrightAttachment,             XmATTACH_NONE);  i++;
    XtSetArg(arg[i], XmNlabelString,               (XtArgVal)Label);  i++;
    lab2 = XmCreateLabel(form, "rangeLabel", arg, i);
    XtManageChild(lab2);
    XmStringFree(Label);

    (void)sprintf(name, "velRange_%d", which);

    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,    XmATTACH_OPPOSITE_WIDGET);  i++;
    XtSetArg(arg[i], XmNtopWidget,                  (XtArgVal)lab2);  i++;
    XtSetArg(arg[i], XmNbottomAttachment, XmATTACH_OPPOSITE_WIDGET);  i++;
    XtSetArg(arg[i], XmNbottomWidget,               (XtArgVal)lab2);  i++;
    XtSetArg(arg[i], XmNleftAttachment,            XmATTACH_WIDGET);  i++;
    XtSetArg(arg[i], XmNleftWidget,                 (XtArgVal)lab2);  i++;
    XtSetArg(arg[i], XmNrightAttachment,         XmATTACH_POSITION);  i++;
    XtSetArg(arg[i], XmNrightPosition,                (XtArgVal)50);  i++;
    lab2 = XmCreateLabel(form, name, arg, i);
    XtManageChild(lab2);

    Label = XmStringCreateLocalized("Resolution:");

    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,    XmATTACH_OPPOSITE_WIDGET);  i++;
    XtSetArg(arg[i], XmNtopWidget,                  (XtArgVal)lab2);  i++;
    XtSetArg(arg[i], XmNbottomAttachment, XmATTACH_OPPOSITE_WIDGET);  i++;
    XtSetArg(arg[i], XmNbottomWidget,               (XtArgVal)lab2);  i++;
    XtSetArg(arg[i], XmNleftAttachment,            XmATTACH_WIDGET);  i++;
    XtSetArg(arg[i], XmNleftWidget,                 (XtArgVal)lab2);  i++;
    XtSetArg(arg[i], XmNrightAttachment,             XmATTACH_NONE);  i++;
    XtSetArg(arg[i], XmNlabelString,               (XtArgVal)Label);  i++;
    lab2 = XmCreateLabel(form, "resolLabel", arg, i);
    XtManageChild(lab2);
    XmStringFree(Label);

    (void)sprintf(name, "velResol_%d", which);

    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,    XmATTACH_OPPOSITE_WIDGET);  i++;
    XtSetArg(arg[i], XmNtopWidget,                  (XtArgVal)lab2);  i++;
    XtSetArg(arg[i], XmNbottomAttachment, XmATTACH_OPPOSITE_WIDGET);  i++;
    XtSetArg(arg[i], XmNbottomWidget,               (XtArgVal)lab2);  i++;
    XtSetArg(arg[i], XmNleftAttachment,            XmATTACH_WIDGET);  i++;
    XtSetArg(arg[i], XmNleftWidget,                 (XtArgVal)lab2);  i++;
    XtSetArg(arg[i], XmNrightAttachment,             XmATTACH_FORM);  i++;
    lab2 = XmCreateLabel(form, name, arg, i);
    XtManageChild(lab2);

    return(frame);
}

/***********************************************************************/
#ifdef __STDC__
static Widget buildToggleCommands(Widget parent, Arg inargs[], Cardinal nargs,
  int mode, Boolean cross, double bws[], double corfs[])
#else
static Widget buildToggleCommands(parent, inargs, nargs, mode, cross, bws, corfs)
Widget parent;
Arg inargs[];
Cardinal nargs;
int mode;
Boolean cross;
double bws[];
double corfs[];
#endif /*__STDC__*/
{
    int buttonSet;
    Arg arg[10];
    Cardinal i, j, nlist;
    Widget form, frame, label, toggle, radioBox, item;
    XmString Label;
    XmString list[8];

    form = XmCreateForm(parent, "toggleForm", inargs, nargs);
    XtManageChild(form);
    XtAddCallback(form, XmNhelpCallback, HelpCB, (XtPointer)HELPCORF);

    /*-----------------------------------------------------------------*/
    /* The correlator mode toggle selector. */
    /*-----------------------------------------------------------------*/

    nlist = 0;
    list[nlist++] = XmStringCreateLocalized("1");
    list[nlist++] = XmStringCreateLocalized("2");
    list[nlist++] = XmStringCreateLocalized("3");
    list[nlist++] = XmStringCreateLocalized("4");
    list[nlist++] = XmStringCreateLocalized("5");
    list[nlist++] = XmStringCreateLocalized("6");
    list[nlist++] = XmStringCreateLocalized("7");
    list[nlist++] = XmStringCreateLocalized("8");

    buttonSet = mode - 1;
    if ((mode < 1) || (mode > nlist)) buttonSet = nlist;

    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,            XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNbottomAttachment,         XmATTACH_NONE);  i++;
    XtSetArg(arg[i], XmNleftAttachment,           XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNrightAttachment,      XmATTACH_POSITION);  i++;
    XtSetArg(arg[i], XmNrightPosition,             (XtArgVal)66);  i++;
    frame = XmCreateFrame(form, "modeFrame", arg, i);
    XtManageChild(frame);

    Label = XmStringCreateLocalized("Correlator Mode:");

    i = 0;
    XtSetArg(arg[i], XmNchildType,           XmFRAME_TITLE_CHILD);  i++;
    XtSetArg(arg[i], XmNchildHorizontalSpacing,      (XtArgVal)4);  i++;
    XtSetArg(arg[i], XmNchildVerticalAlignment, XmALIGNMENT_WIDGET_BOTTOM); i++;
    XtSetArg(arg[i], XmNlabelString,             (XtArgVal)Label);  i++;
    label = XmCreateLabel(frame, "modeLabel", arg, i);
    XtManageChild(label);
    XmStringFree(Label);

    i = 0;
    XtSetArg(arg[i], XmNnumColumns,                  (XtArgVal)2);  i++;
    XtSetArg(arg[i], XmNorientation,      (XtArgVal)XmHORIZONTAL);  i++;
    XtSetArg(arg[i], XmNbuttons,                  (XtArgVal)list);  i++;
    XtSetArg(arg[i], XmNbuttonCount,             (XtArgVal)nlist);  i++;
    XtSetArg(arg[i], XmNbuttonSet,           (XtArgVal)buttonSet);  i++;
    XtSetArg(arg[i], XmNsimpleCallback,   (XtArgVal)modeCallback);  i++;
    toggle = XmCreateSimpleRadioBox(frame, "modeBox", arg, i);
    XtManageChild(toggle);
    for (i = 0; i < nlist; i++)
      XmStringFree(list[i]);
    setMode(frame, mode);

    /*-----------------------------------------------------------------*/
    /* Make a correlator option toggle selector. */
    /*-----------------------------------------------------------------*/

    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,             XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNbottomAttachment,          XmATTACH_NONE);  i++;
    XtSetArg(arg[i], XmNleftAttachment,          XmATTACH_WIDGET);  i++;
    XtSetArg(arg[i], XmNleftWidget,              (XtArgVal)frame);  i++;
    XtSetArg(arg[i], XmNrightAttachment,           XmATTACH_FORM);  i++;
    frame = XmCreateFrame(form, "optionFrame", arg, i);
    XtManageChild(frame);

    Label = XmStringCreateLocalized("Option:");

    i = 0;
    XtSetArg(arg[i], XmNchildType,           XmFRAME_TITLE_CHILD);  i++;
    XtSetArg(arg[i], XmNchildHorizontalSpacing,      (XtArgVal)4);  i++;
    XtSetArg(arg[i], XmNchildVerticalAlignment, XmALIGNMENT_WIDGET_BOTTOM); i++;
    XtSetArg(arg[i], XmNlabelString,             (XtArgVal)Label);  i++;
    label = XmCreateLabel(frame, "optionLabel", arg, i);
    XtManageChild(label);
    XmStringFree(Label);

    i = 0;
    radioBox = XmCreateRadioBox(frame, "optionBox", arg, i);
    XtManageChild(radioBox);

    i = 0;
    toggle = XmCreateToggleButton(radioBox, "Cross", arg, i);
    XtManageChild(toggle);
    XtAddCallback(toggle, XmNvalueChangedCallback,
      optionCallback, (XtPointer)True);
    item = toggle;

    toggle = XmCreateToggleButton(radioBox,  "Auto", arg, i);
    XtManageChild(toggle);
    XtAddCallback(toggle, XmNvalueChangedCallback,
      optionCallback, (XtPointer)False);

    XmToggleButtonSetState(((cross == True) ? item : toggle), True, True);

    /*-----------------------------------------------------------------*/
    /* Make the 4 Corf slider/BW toggle selectors. */
    /*-----------------------------------------------------------------*/

    item = frame;
    for (j = 1; j <= 4; j++) {
      i = 0;
      XtSetArg(arg[i], XmNtopAttachment,         XmATTACH_WIDGET);  i++;
      XtSetArg(arg[i], XmNtopWidget,              (XtArgVal)item);  i++;
      XtSetArg(arg[i], XmNbottomAttachment,        XmATTACH_NONE);  i++;
      XtSetArg(arg[i], XmNleftAttachment,          XmATTACH_FORM);  i++;
      XtSetArg(arg[i], XmNrightAttachment,         XmATTACH_FORM);  i++;
      item = buildCorfBW(form, arg, i, j);
      setBW(item, j, bws[j-1]);
      setCorf(item, j, corfs[j-1]);
    }

    return(form);
}

/***********************************************************************/
#ifdef __STDC__
static void buildSB(Widget parent, Arg inargs[], Cardinal nargs,
  Boolean usb, XFontStruct *rulerFont, XFontStruct *drawFont)
#else
static void buildSB(parent, inargs, nargs, usb, rulerFont, drawFont)
Widget parent;
Arg inargs[];
Cardinal nargs;
Boolean usb;
XFontStruct *rulerFont, *drawFont;
#endif /*__STDC__*/
{
    char drawName[80], rulerName[80], labstring[5];
    register int count, percent;
    Arg arg[10];
    Cardinal i;
    Widget rframe, dframe, form, ruler;
    Widget innerForm, draw, corf;
    Widget labframe, label;
    XmString labString;

    form = XmCreateForm(parent, "sbForm", inargs, nargs);
    XtManageChild(form);
    XtAddCallback(form, XmNhelpCallback, HelpCB, (XtPointer)HELPCORF);

    (void)sprintf(rulerName, "%sRuler", ((usb == True) ? "usb" : "lsb"));
    (void)sprintf(drawName, "%sDraw", ((usb == True) ? "usb" : "lsb"));

    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,          XmATTACH_POSITION);  i++;
    XtSetArg(arg[i], XmNtopPosition,                  (XtArgVal)5);  i++;
    XtSetArg(arg[i], XmNbottomAttachment,           XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNleftAttachment,             XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNrightAttachment,            XmATTACH_NONE);  i++;
    rframe = XmCreateFrame(form, "rulerFrame", arg, i);
    XtManageChild(rframe);

    i = 0;
    XtSetArg(arg[i], XmNuserData,             (XtArgVal)rulerFont);  i++;
    ruler = XmCreateDrawingArea(rframe, rulerName, arg, i);
    XtManageChild(ruler);
    XtAddCallback(ruler, XmNexposeCallback, smallRulerCallback, (XtPointer)usb);
    XtAddCallback(ruler, XmNresizeCallback, smallRulerCallback, (XtPointer)usb);
    initSmallRuler(ruler, False, usb);

    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,   XmATTACH_OPPOSITE_WIDGET);  i++;
    XtSetArg(arg[i], XmNtopWidget,               (XtArgVal)rframe);  i++;
    XtSetArg(arg[i], XmNbottomAttachment,           XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNleftAttachment,           XmATTACH_WIDGET);  i++;
    XtSetArg(arg[i], XmNleftWidget,              (XtArgVal)rframe);  i++;
    XtSetArg(arg[i], XmNrightAttachment,            XmATTACH_FORM);  i++;
    dframe = XmCreateFrame(form, "drawFrame", arg, i);
    XtManageChild(dframe);

    i = 0;
    innerForm = XmCreateForm(dframe, "drawForm", arg, i);
    XtManageChild(innerForm);

    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,              XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNbottomAttachment,           XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNleftAttachment,             XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNrightAttachment,        XmATTACH_POSITION);  i++;
    XtSetArg(arg[i], XmNrightPosition,               (XtArgVal)80);  i++;
    XtSetArg(arg[i], XmNuserData,              (XtArgVal)drawFont);  i++;
    draw = XmCreateDrawingArea(innerForm, drawName, arg, i);
    XtManageChild(draw);
    XtAddCallback(draw, XmNexposeCallback, drawingCallback, (XtPointer)usb);
    XtAddCallback(draw, XmNresizeCallback, drawingCallback, (XtPointer)usb);
    initDrawingArea(draw, usb, False);

    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,              XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNbottomAttachment,           XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNleftAttachment,           XmATTACH_WIDGET);  i++;
    XtSetArg(arg[i], XmNleftWidget,                (XtArgVal)draw);  i++;
    XtSetArg(arg[i], XmNrightAttachment,            XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNuserData,              (XtArgVal)drawFont);  i++;
    corf = XmCreateDrawingArea(innerForm, "corfDraw", arg, i);
    XtManageChild(corf);
    XtAddCallback(corf, XmNexposeCallback, corfdrawCallback, (XtPointer)usb);
    XtAddCallback(corf, XmNresizeCallback, corfdrawCallback, (XtPointer)usb);
    initCorfs(corf, usb);

    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,              XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNbottomAttachment,         XmATTACH_WIDGET);  i++;
    XtSetArg(arg[i], XmNbottomWidget,            (XtArgVal)rframe);  i++;
    XtSetArg(arg[i], XmNleftAttachment,           XmATTACH_WIDGET);  i++;
    XtSetArg(arg[i], XmNleftWidget,              (XtArgVal)rframe);  i++;
    XtSetArg(arg[i], XmNrightAttachment,            XmATTACH_FORM);  i++;
    labframe = XmCreateFrame(form, "labFrame", arg, i);
    XtManageChild(labframe);

    i = 0;
    labframe = XmCreateForm(labframe, "labForm", arg, i);
    XtManageChild(labframe);

    percent = 100;
    for (count = 4; count > 0; count--) {
      (void)sprintf(labstring, "%d", count);
      labString = XmStringCreateLocalized(labstring);

      i = 0;
      XtSetArg(arg[i], XmNtopAttachment,              XmATTACH_FORM);  i++;
      XtSetArg(arg[i], XmNbottomAttachment,           XmATTACH_FORM);  i++;
      XtSetArg(arg[i], XmNrightAttachment,        XmATTACH_POSITION);  i++;
      XtSetArg(arg[i], XmNrightPosition,          (XtArgVal)percent);  i++;
      percent -= 5;
      XtSetArg(arg[i], XmNleftAttachment,         XmATTACH_POSITION);  i++;
      XtSetArg(arg[i], XmNleftPosition,           (XtArgVal)percent);  i++;
      XtSetArg(arg[i], XmNlabelString,          (XtArgVal)labString);  i++;
      label = XmCreateLabelGadget(labframe, "corfLabel", arg, i);
      XtManageChild(label);
      XmStringFree(labString);
    }

    labString = XmStringCreateLocalized((usb == True) ? 
      "Upper Sideband" : "Lower Sideband");

    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,              XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNbottomAttachment,           XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNleftAttachment,             XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNrightAttachment,          XmATTACH_WIDGET);  i++;
    XtSetArg(arg[i], XmNrightWidget,              (XtArgVal)label);  i++;
    XtSetArg(arg[i], XmNlabelString,          (XtArgVal)labString);  i++;
    label = XmCreateLabelGadget(labframe, "sideLabel", arg, i);
    XtManageChild(label);
    XmStringFree(labString);

    return;
}

/***********************************************************************/
#ifdef __STDC__
static void buildChannelWindow(Widget parent, Arg inargs[], Cardinal nargs,
  Boolean usb, XFontStruct *rulerFont, XFontStruct *drawFont)
#else
static void buildChannelWindow(parent, inargs, nargs, usb, rulerFont, drawFont)
Widget parent;
Arg inargs[];
Cardinal nargs;
Boolean usb;
XFontStruct *rulerFont, *drawFont;
#endif /*__STDC__*/
{
    char drawName[80], rulerName[80];
    Arg arg[10];
    Cardinal i;
    Widget frame, form, ruler, draw;

    form = XmCreateForm(parent, "smallForm", inargs, nargs);
    XtManageChild(form);
    XtAddCallback(form, XmNhelpCallback, HelpCB, (XtPointer)HELPCHANS);

    (void)sprintf(rulerName, "%sSmallRuler", ((usb == True) ? "usb" : "lsb"));
    (void)sprintf(drawName, "%sSmallDraw", ((usb == True) ? "usb" : "lsb"));

    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,              XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNbottomAttachment,           XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNleftAttachment,             XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNrightAttachment,            XmATTACH_NONE);  i++;
    frame = XmCreateFrame(form, "rulerFrame", arg, i);
    XtManageChild(frame);

    i = 0;
    XtSetArg(arg[i], XmNuserData,             (XtArgVal)rulerFont);  i++;
    XtSetArg(arg[i], XmNtraversalOn,              (XtArgVal)False);  i++;
    ruler = XmCreateDrawingArea(frame, rulerName, arg, i);
    XtManageChild(ruler);
    XtAddCallback(ruler, XmNexposeCallback, channelRulerCB, (XtPointer)usb);
    XtAddCallback(ruler, XmNresizeCallback, channelRulerCB, (XtPointer)usb);
    initSmallRuler(ruler, True, usb);

    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,              XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNbottomAttachment,           XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNleftAttachment,           XmATTACH_WIDGET);  i++;
    XtSetArg(arg[i], XmNleftWidget,               (XtArgVal)frame);  i++;
    XtSetArg(arg[i], XmNrightAttachment,            XmATTACH_FORM);  i++;
    frame = XmCreateFrame(form, "drawFrame", arg, i);
    XtManageChild(frame);

    i = 0;
    XtSetArg(arg[i], XmNuserData,              (XtArgVal)drawFont);  i++;
    draw = XmCreateDrawingArea(frame, drawName, arg, i);
    XtManageChild(draw);
    XtAddCallback(draw,  XmNinputCallback, channelDrawCB, (XtPointer)usb);
    XtAddCallback(draw, XmNexposeCallback, channelDrawCB, (XtPointer)usb);
    XtAddCallback(draw, XmNresizeCallback, channelDrawCB, (XtPointer)usb);
    initDrawingArea(draw, usb, True);

    return;
}

/***********************************************************************/
#ifdef __STDC__
Widget buildWindows(Widget parent, Boolean usb, Boolean cross,
  int mode, double restfreq, double iffreq, double vlsr, double rulerWidth,
  double bws[], double corfs[], XFontStruct *rulerFont,
  XFontStruct *usbRulerFont, XFontStruct *usbDrawFont,
  XFontStruct *lsbRulerFont, XFontStruct *lsbDrawFont)
#else
Widget buildWindows(parent, usb, cross, mode, restfreq, iffreq, vlsr,
  rulerWidth, bws, corfs, rulerFont, usbRulerFont, usbDrawFont,
  lsbRulerFont, lsbDrawFont)
Widget parent;
Boolean usb, cross;
int mode;
double restfreq, iffreq, vlsr, rulerWidth;
double bws[], corfs[];
XFontStruct *rulerFont;
XFontStruct *usbRulerFont, *usbDrawFont;
XFontStruct *lsbRulerFont, *lsbDrawFont;
#endif /*__STDC__*/
{
    Arg arg[10];
    Cardinal i;
    Widget mainW, menuBar, commandW, frame, workArea, toggle;

    /*-----------------------------------------------------------------*/
    /*  Create the main window; all else will be enclosed in it. */
    /*-----------------------------------------------------------------*/
    i = 0;
    mainW = XmCreateMainWindow(parent, "mainWindow", arg, i);
    XtManageChild(mainW);

    /*-----------------------------------------------------------------*/
    /*  Create the main Command Title Bar. */ 
    /*-----------------------------------------------------------------*/
    menuBar = buildCommandLevel(mainW);

    /*-----------------------------------------------------------------*/
    /*  Create a Command Window in the Main Window. */ 
    /*-----------------------------------------------------------------*/

    i = 0;
    commandW = XmCreateForm(mainW, "commands", arg, i);
    XtManageChild(commandW);

    i = 0;
    XtSetArg(arg[i], XmNcommandWindow,   (XtArgVal)commandW);  i++;
    XtSetValues(mainW, arg, i);

    /* Inputs for frequency, iffreq, sideband, and vlsr. */
    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,        XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNbottomAttachment,     XmATTACH_NONE);  i++;
    XtSetArg(arg[i], XmNleftAttachment,       XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNrightAttachment,      XmATTACH_FORM);  i++;
    frame = buildInputs(commandW, arg, i, restfreq, iffreq, vlsr, usb);

    /* The main slider ruler. */
    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,      XmATTACH_WIDGET);  i++;
    XtSetArg(arg[i], XmNtopWidget,          (XtArgVal)frame);  i++;
    XtSetArg(arg[i], XmNbottomAttachment,     XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNleftAttachment,       XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNrightAttachment,      XmATTACH_FORM);  i++;
    buildMainRuler(commandW, arg, i, restfreq, rulerWidth, rulerFont);

    /*-----------------------------------------------------------------*/
    /*  Create a Work Window in the Main Window. */ 
    /*-----------------------------------------------------------------*/

    i = 0;
    workArea = XmCreateForm(mainW, "work", arg, i);
    XtManageChild(workArea);

    i = 0;
    XtSetArg(arg[i], XmNworkWindow,            (XtArgVal)workArea);  i++;
    XtSetValues(mainW, arg, i);

    /* Build the toggle-command region. */
    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,               XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNbottomAttachment,            XmATTACH_NONE);  i++;
    XtSetArg(arg[i], XmNleftAttachment,          XmATTACH_POSITION);  i++;
    XtSetArg(arg[i], XmNleftPosition,                 (XtArgVal)33);  i++;
    XtSetArg(arg[i], XmNrightAttachment,         XmATTACH_POSITION);  i++;
    XtSetArg(arg[i], XmNrightPosition,                (XtArgVal)66);  i++;
    toggle = buildToggleCommands(workArea, arg, i, mode, cross, bws, corfs);

    /* Make the first of the sideband drawing widgets... */
    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,               XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNbottomAttachment, XmATTACH_OPPOSITE_WIDGET);  i++;
    XtSetArg(arg[i], XmNbottomWidget,             (XtArgVal)toggle);  i++;
    XtSetArg(arg[i], XmNleftAttachment,              XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNrightAttachment,         XmATTACH_POSITION);  i++;
    XtSetArg(arg[i], XmNrightPosition,                (XtArgVal)33);  i++;
    XtSetArg(arg[i], XmNtraversalOn,               (XtArgVal)False);  i++;
    buildSB(workArea, arg, i, False, lsbRulerFont, lsbDrawFont); /* LSB */

    /* Make the other sideband drawing widget... */
    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,               XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNbottomAttachment, XmATTACH_OPPOSITE_WIDGET);  i++;
    XtSetArg(arg[i], XmNbottomWidget,             (XtArgVal)toggle);  i++;
    XtSetArg(arg[i], XmNleftAttachment,          XmATTACH_POSITION);  i++;
    XtSetArg(arg[i], XmNleftPosition,                 (XtArgVal)66);  i++;
    XtSetArg(arg[i], XmNrightAttachment,             XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNtraversalOn,               (XtArgVal)False);  i++;
    buildSB(workArea, arg, i, True, usbRulerFont, usbDrawFont); /* USB */

    /* Make the two channel drawing windows... */

    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,             XmATTACH_WIDGET);  i++;
    XtSetArg(arg[i], XmNtopWidget,                (XtArgVal)toggle);  i++;
    XtSetArg(arg[i], XmNbottomAttachment,            XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNleftAttachment,              XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNrightAttachment,         XmATTACH_POSITION);  i++;
    XtSetArg(arg[i], XmNrightPosition,                (XtArgVal)50);  i++;
    buildChannelWindow(workArea, arg, i, False, lsbRulerFont, lsbDrawFont);

    i = 0;
    XtSetArg(arg[i], XmNtopAttachment,             XmATTACH_WIDGET);  i++;
    XtSetArg(arg[i], XmNtopWidget,                (XtArgVal)toggle);  i++;
    XtSetArg(arg[i], XmNbottomAttachment,            XmATTACH_FORM);  i++;
    XtSetArg(arg[i], XmNleftAttachment,          XmATTACH_POSITION);  i++;
    XtSetArg(arg[i], XmNleftPosition,                 (XtArgVal)50);  i++;
    XtSetArg(arg[i], XmNrightAttachment,             XmATTACH_FORM);  i++;
    buildChannelWindow(workArea, arg, i, True, usbRulerFont, usbDrawFont);

    XmMainWindowSetAreas(mainW, menuBar, commandW, NULL, NULL, workArea);

    return(mainW);
}

/***********************************************************************/
#ifdef __STDC__
void setOption(Widget parent, Boolean cross)
#else
void setOption(parent, cross)
Widget parent;
Boolean cross;
#endif /*__STDC__*/
{
    Widget w;

    if (cross == True)
      w = XtNameToWidget(parent, "*optionBox.Cross");
    else
      w = XtNameToWidget(parent, "*optionBox.Auto");

    if (w != (Widget)NULL)
      XmToggleButtonSetState(w, True, True);

    return;
}

/***********************************************************************/
#ifdef __STDC__
void setSB(Widget parent, Boolean usb)
#else
void setSB(parent, usb)
Widget parent;
Boolean usb;
#endif /*__STDC__*/
{
    char name[50];
    Widget w;

    (void)sprintf(name, "*sbForm.sideband.button_%d", ((usb == True) ? 0 : 1));

    if ((w = XtNameToWidget(parent, name)) != (Widget)NULL)
      XmToggleButtonSetState(w, True, True);

    return;
}

/***********************************************************************/
#ifdef __STDC__
void setVelocityRange(Widget parent, int which, int nvals, double range[])
#else
void setVelocityRange(parent, which, nvals, range)
Widget parent;
int which;
int nvals;
double range[];
#endif /*__STDC__*/
{
    char value[50];
    Arg arg[1];
    Cardinal i;
    Widget w;
    XmString string;

    if ((parent == (Widget)NULL) || (!XtIsRealized(parent)))
      return;

    if ((which < 1) || (which > 4))
      return;

    (void)sprintf(value, "*velRange_%d", which);

    if ((w = XtNameToWidget(parent, value)) != (Widget)NULL) {
      switch (nvals) {
        case 1:
          (void)sprintf(value, "%G", range[0]);
          break;
        case 2:
          (void)sprintf(value, "%G, %G", range[0], range[1]);
          break;
        default:
          (void)strcpy(value, "[ERROR]");
          break;
      }
      string = XmStringCreateLocalized(value);
      i = 0;
      XtSetArg(arg[i], XmNlabelString, (XtArgVal)string);  i++;
      XtSetValues(w, arg, i);
      XmStringFree(string);
    }

    return;
}

/***********************************************************************/
#ifdef __STDC__
void setVelocityResol(Widget parent, int which, int nvals, double resol[])
#else
void setVelocityResol(parent, which, nvals, resol)
Widget parent;
int which;
int nvals;
double resol[];
#endif /*__STDC__*/
{
    char value[50];
    Arg arg[1];
    Cardinal i;
    Widget w;
    XmString string;

    if ((parent == (Widget)NULL) || (!XtIsRealized(parent)))
      return;

    if ((which < 1) || (which > 4))
      return;

    (void)sprintf(value, "*velResol_%d", which);

    if ((w = XtNameToWidget(parent, value)) != (Widget)NULL) {
      switch (nvals) {
        case 1:
          (void)sprintf(value, "%G", resol[0]);
          break;
        case 2:
          (void)sprintf(value, "%G, %G", resol[0], resol[1]);
          break;
        default:
          (void)strcpy(value, "[ERROR]");
          break;
      }
      string = XmStringCreateLocalized(value);
      i = 0;
      XtSetArg(arg[i], XmNlabelString, (XtArgVal)string);  i++;
      XtSetValues(w, arg, i);
      XmStringFree(string);
    }

    return;
}

/***********************************************************************/
#ifdef __STDC__
void updateRestFQ(void)
#else
void updateRestFQ()
#endif /*__STDC__*/
{
    char *string;
    char value[50];
    register int j, which;
    double freq;
    Boolean isusb;
    Widget parent, w;

    if (Global->mainWindow != (Widget)NULL) {
      parent = XtNameToWidget(Global->mainWindow, "*restFQbox");
      if (parent != (Widget)NULL) {
        isusb = False;
        for (j = 1; j <= 16; j++) {
          if (j > 8) isusb = True;
          which = (j - 1) % 8;
          (void)sprintf(value, "*restfqs_%d", j);
          if ((w = XtNameToWidget(parent, value)) != (Widget)NULL) {
            if (getRestFQ(which, isusb, &freq)) {
              (void)sprintf(value, "%.6f", freq);
              string = value + strlen(value) - 1;
              while ((string >= value) && (*string == '0'))
                *string-- = '\0';
            } else {
              (void)strcpy(value, "");
            }
            XmTextFieldSetString(w, value);
            setLastPos(w);
          }
        }
      }
    }

    return;
}
