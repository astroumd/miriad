/*
 *	File:		gr_xwi.h
 *	Contents:	Header file containing all the includes and externs
 *				by the X-Windows Athena widget set.
 */


#include <X11/Xos.h>
#include <X11/Intrinsic.h>
#include <X11/StringDefs.h>
#include <X11/Shell.h>

#ifdef XtSpecificationRelease
#include <X11/Xaw/AsciiText.h>
#include <X11/Xaw/Box.h>
#include <X11/Xaw/Command.h>
#include <X11/Xaw/Dialog.h>
#include <X11/Xaw/Label.h>
#include <X11/Xaw/List.h>
#include <X11/Xaw/Viewport.h>
#else
#include <X11/AsciiText.h>
#include <X11/Box.h>
#include <X11/Command.h>
#include <X11/Dialog.h>
#include <X11/Label.h>
#include <X11/List.h>
#include <X11/Viewport.h>
#endif

/* This should not be a global. */
Arg	argList[15];
