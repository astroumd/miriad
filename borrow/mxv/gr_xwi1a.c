/*
 *	File:		gr_xwi1.c
 *	Contents:	Creation functions for X widgets
 *	These functions are used to create windows having the same look
 *	and feel required by Miriad X Visualizer. There should not be any other
 *	explicit Xt calls outside of the gr_xwi*.c files.  This is an
 *	effort to contain porting problems within a smaller scope.
 */

#include "gr_com.h"
#include "gr_xwi.h"

#include <X11/Xaw/Form.h>
#include <X11/Xaw/Toggle.h>
#include <X11/Xaw/Command.h>
#include <X11/Xaw/Repeater.h>
#include <X11/Xaw/Viewport.h>
#include <X11/Xaw/Porthole.h>
#include <X11/Xaw/SimpleMenu.h>
#include <X11/Xaw/MenuButton.h>
#include <X11/Xaw/SmeBSB.h>
#include <X11/Xaw/SmeLine.h>
/* MXV widgets. */
#include "WorkSpace.h"
#include "SRaster.h"
#include "Slider.h"


void gr_DialogEventEnter();


#include "bitmaps.h"
#include "X11/bitmaps/gray"

/* Create pixmaps for toggle/button.
	NO CHECKING IS DONE FOR FAILURE!!
*/

static Boolean bm_inited = FALSE;
Pixmap	diamond, square, up, down, left, right;
Pixmap	gray;

/* Initialize bitmaps. If wid has no window, use root as prototype window.. */
static void init_bm(wid)
Widget	wid;
{
Display	*dpy;
Window	win;

	if( bm_inited) return;
	dpy = XtDisplay(wid);
	win = XtWindow(wid);
	if( win == 0)
		win = DefaultRootWindow(dpy);

	square = XCreateBitmapFromData(dpy, win,
		square_bits, square_width, square_height);
	diamond = XCreateBitmapFromData(dpy, win,
		(char *) diamond_bits, diamond_width, diamond_height);
	up = XCreateBitmapFromData(dpy, win,
		(char *)up_bits, up_width, up_height);
	down = XCreateBitmapFromData(dpy, win,
		(char *)down_bits, down_width, down_height);
	left = XCreateBitmapFromData(dpy, win,
		(char *)left_bits, left_width, left_height);
	right = XCreateBitmapFromData(dpy, win,
		(char *) right_bits, right_width, right_height);
#ifdef PIXMAPBACKGROUND
	gray = XCreatePixmapFromBitmapData(dpy, win,
		gray_bits, gray_width, gray_height, 0, 1, 8);
#endif
	bm_inited = TRUE;
}

/* Put bitmap for shape in arg.
Returns the new value of i.
*/
static int set_bitmap( parent, argList, resource, shape, i)
Arg	*argList;
char	*resource;
A_ToggleShape_t	shape;
int	i;
{
	init_bm(parent);

	switch (shape) {
	case SQUARE:
		XtSetArg(argList[0], resource, square);
		break;
	case DIAMOND:
		XtSetArg(argList[0], resource, diamond);
		break;
	case UP:
		XtSetArg(argList[0], resource, up);
		break;
	case DOWN:
		XtSetArg(argList[0], resource, down);
		break;
	case LEFT:
		XtSetArg(argList[0], resource, left);
		break;

	case RIGHT:
		XtSetArg(argList[0], resource, right);
		break;
	case NONE:
	default:
		i -= 1;		/* Don't want to increment. */
		break;
	}
	return i+1;
}

/*
 * Return an Athena Label widget.
label	Contents of label
shape	Shape to use. To left of or instead of label.
leftW	Widget to left
topW	Widget above
justify	How to justify string in window.
*/
Widget gr_MakeLabel2(name, parent, label, shape, justify, topW, leftW)
char 	*name;
Widget 	parent;
char	*label;
A_ToggleShape_t shape;
int	justify;	/* UNUSED */
Widget		topW, leftW;
{
Widget		labelWind;
Arg			argList[20];
Cardinal	i=0;
char		*bmtype;

	if(name == NULL)
		name = "MXVlabel";

	if(label != NULL)
	{	XtSetArg(argList[i],XtNlabel,label);	i++;
		bmtype = XtNleftBitmap;
	}
	else
		bmtype = XtNbitmap;

	if( topW != NULL)
	{	XtSetArg(argList[i], XtNfromVert, topW); i++;
	}
	if( leftW != NULL)
	{	XtSetArg(argList[i], XtNfromHoriz, leftW); i++;
	}
	/* Don't let label change size. */
	XtSetArg(argList[i], XtNtop, XawChainTop); i++;
	XtSetArg(argList[i], XtNbottom, XawChainTop); i++;
	XtSetArg(argList[i], XtNright, XawChainLeft); i++;
	XtSetArg(argList[i], XtNleft, XawChainLeft); i++;

	XtSetArg(argList[i],XtNresizable, FALSE);  i++;
	/* This should be the same for all 'text' widgets. */
	XtSetArg(argList[i],XtNvertDistance, 0);  i++;
	XtSetArg(argList[i],XtNhorizDistance, 0); i++;
	XtSetArg(argList[i],XtNinternalHeight, 6); i++;

	init_bm(parent);

	labelWind = XtCreateManagedWidget(name, labelWidgetClass,
				parent,argList,i);

	return(labelWind);
}

/*
 * Return an Xaw Form widget.
*/
Widget
gr_MakeForm(shellName,parent, topW, leftW)
char		*shellName;
Widget		parent;
Widget		topW, leftW;
{
Widget		boxW;
Cardinal	i=0;
Arg	argList[20];

	if(shellName == NULL)
		shellName = "MXVform";

	/* Box */
	i = 0;
	if(leftW != NULL)
	{       XtSetArg(argList[i], XtNfromHoriz, leftW); i++;	}
	if(topW != NULL)
	{       XtSetArg(argList[i], XtNfromVert, topW); i++;}
/*	XtSetArg(argList[i], XtNtop, XawChainBottom); i++;*/
/*	XtSetArg(argList[i], XtNbottom, XawChainBottom); i++;*/
	XtSetArg(argList[i],XtNvertDistance, 0);  i++;
	XtSetArg(argList[i],XtNhorizDistance, 0); i++;
/*	XtSetArg(argList[i],XtNresizable, TRUE);  i++;*/
/*
	XtSetArg(argList[i],XtNwidth,  1);	i++;
	XtSetArg(argList[i],XtNheight, 1);	i++;
*/
	boxW = XtCreateManagedWidget(shellName, formWidgetClass, parent,
		argList, i);

	return(boxW);
}

/* Lock the size of a form widget's child by chaining top to bottom
and left to right.
The arguments indicate whether to chainTop/Left or Bottom/Right.
*/
gr_set_noresizable(w, lockTop, lockLeft)
Widget	w;
Boolean lockTop, lockLeft;
{
Arg	argList[20];
Cardinal i;
int	vertchain, horizchain;

	vertchain = (lockTop) ? XawChainTop : XawChainBottom;
	horizchain = (lockLeft) ? XawChainLeft : XawChainRight;
	i = 0;
/*	XtSetArg(argList[0], XtNresizable, resize); i++;*/
	XtSetArg(argList[i], XtNtop, vertchain); i++;
	XtSetArg(argList[i], XtNbottom, vertchain); i++;
	XtSetArg(argList[i], XtNright, horizchain); i++;
	XtSetArg(argList[i], XtNleft, horizchain); i++;
	XtSetValues(w, argList, i);
}

/* Set chaining for children of form widget. Used to 'chain' an edge
of a child widget to one of the parent's edges.
*/
gr_ChainEdge(w, edge, chainto)
Widget	w;
A_Direction_t	edge, chainto;
{
Arg	argList[20];
Cardinal i;
int	parent_edge;
char	*Edge;

	switch (edge){
	case DIR_TOP:
			Edge = XtNtop;
			break;
	case DIR_BOTTOM:
			Edge = XtNbottom;
			break;
	case DIR_LEFT:
			Edge = XtNleft;
			break;
	case DIR_RIGHT:
			Edge = XtNright;
			break;
	default:
			Edge = NULL;
	};
	if(Edge == NULL)
		return;
	switch (chainto){
	case DIR_TOP:
			parent_edge = XawChainTop;
			break;
	case DIR_BOTTOM:
			parent_edge = XawChainBottom;
			break;
	case DIR_LEFT:
			parent_edge = XawChainLeft;
			break;
	case DIR_RIGHT:
			parent_edge = XawChainRight;
			break;
	default:
			parent_edge = -1;
	};
	if(parent_edge == -1)
		return;

	XtSetArg(argList[0], Edge, parent_edge);
	XtSetValues(w, argList, 1);
}

/* Return an Xaw command widget (push button).

name	Button name
parent	parent of button
label	button label
shape	Shape of pixmap (NONE for none).
callback
	procedure to call when button pressed.
data	data to be passed to callback
leftW,	If non NULL, widgets to left/top of button.
topW	If NULL, parent is assumed.

If there is a label and shape is not NONE, the pixmap will be a 'leftbitmap'.
If label is NULL and shape is not NONE, the pixmap will be a 'bitmap'.


The button is kept from resizing by chaining to an edge of its parent.
It therefore needs to be inside a box or form that can get moved. Otherwise,
it will be stepped on when resizes occur.
*/
Widget
gr_MakeButton3(name,parent,label, shape, callback,data, topW, leftW)
char		*name;
Widget		parent;
char		*label;
A_ToggleShape_t	shape;
XtCallbackProc	callback;
caddr_t		data;
Widget		topW, leftW;
{
Widget		buttonWind;
Arg		argList[20];
Cardinal	i=0;
char		*bmtype;

	if(name == NULL)
		name = "MXVbutton";

	if(label != NULL)
	{	XtSetArg(argList[i],XtNlabel,label);	i++;
		bmtype = XtNleftBitmap;
	}
	else
		bmtype = XtNbitmap;

/*	XtSetArg(argList[i],XtNshapeStyle, XmuShapeOval);	i++;*/
	if( topW != NULL)
	{	XtSetArg(argList[i], XtNfromVert, topW); i++;
	}
	if( leftW != NULL)
	{	XtSetArg(argList[i], XtNfromHoriz, leftW); i++;
	}
	/* Don't let button change size. */
	XtSetArg(argList[i], XtNtop, XawChainTop); i++;
	XtSetArg(argList[i], XtNbottom, XawChainTop); i++;
	XtSetArg(argList[i], XtNright, XawChainLeft); i++;
	XtSetArg(argList[i], XtNleft, XawChainLeft); i++;

	XtSetArg(argList[i],XtNresizable, FALSE);  i++;
	XtSetArg(argList[i],XtNvertDistance, 0);  i++;
	XtSetArg(argList[i],XtNhorizDistance, 0); i++;
	XtSetArg(argList[i],XtNinternalHeight, 6); i++;

	i = set_bitmap( parent, &argList[i], bmtype, shape, i);

	buttonWind = XtCreateManagedWidget(name,commandWidgetClass,
					  parent, argList,i);

	if (callback != NULL)
		XtAddCallback(buttonWind,XtNcallback,callback, data);

	return(buttonWind);
}
Widget
gr_MakeRepeater(name,parent,label, shape, callback,data, topW, leftW)
char		*name;
Widget		parent;
char		*label;
A_ToggleShape_t	shape;
XtCallbackProc	callback;
caddr_t		data;
Widget		topW, leftW;
{
Widget		buttonWind;
Arg		argList[20];
Cardinal	i=0;
char		*bmtype;

	if(name == NULL)
		name = "MXVrepeater";

	if(label != NULL)
	{	XtSetArg(argList[i],XtNlabel,label);	i++;
		bmtype = XtNleftBitmap;
	}
	else
		bmtype = XtNbitmap;

/*	XtSetArg(argList[i],XtNshapeStyle, XmuShapeOval);	i++;*/
	if( topW != NULL)
	{	XtSetArg(argList[i], XtNfromVert, topW); i++;
	}
	if( leftW != NULL)
	{	XtSetArg(argList[i], XtNfromHoriz, leftW); i++;
	}
	/* Don't let button change size. */
	XtSetArg(argList[i], XtNtop, XawChainTop); i++;
	XtSetArg(argList[i], XtNbottom, XawChainTop); i++;
	XtSetArg(argList[i], XtNright, XawChainLeft); i++;
	XtSetArg(argList[i], XtNleft, XawChainLeft); i++;

	XtSetArg(argList[i],XtNresizable, FALSE);  i++;
	XtSetArg(argList[i],XtNvertDistance, 0);  i++;
	XtSetArg(argList[i],XtNhorizDistance, 0); i++;
	XtSetArg(argList[i],XtNinternalHeight, 6); i++;

	i = set_bitmap( parent, &argList[i], bmtype, shape, i);

	buttonWind = XtCreateManagedWidget(name, repeaterWidgetClass,
					  parent, argList,i);

	if (callback != NULL)
		XtAddCallback(buttonWind,XtNcallback,callback, data);

	return(buttonWind);
}

/*
 * Return an Xaw Box Widget.

	If orient_vertical is true, the box is set to orientVertical,
otherwise its set to orientHorizontal.
 */
Widget
gr_MakeBox2(shellName,parent, topW, leftW, orient_vertical)
char		*shellName;
Widget		parent;
Widget		topW, leftW;
Boolean		orient_vertical;
{
Widget		boxW;
Cardinal	i=0;
Arg	argList[20];

	if(shellName == NULL)
		shellName = "MXVbox";
	/* Box */
	i = 0;
	if(! orient_vertical)
	{     XtSetArg(argList[i], XtNorientation, XtorientHorizontal); i++; }
	if( topW != NULL)
	{	XtSetArg(argList[i], XtNfromVert, topW); i++; }
	if( leftW != NULL)
	{	XtSetArg(argList[i], XtNfromHoriz, leftW); i++; }

/*	XtSetArg(argList[i], XtNtop, XawChainBottom); i++;
	XtSetArg(argList[i], XtNbottom, XawChainBottom); i++;
*/
	XtSetArg(argList[i],XtNvertDistance, 0);  i++;
	XtSetArg(argList[i],XtNhorizDistance, 0); i++;
	XtSetArg(argList[i],XtNhSpace, 0);  i++;
	XtSetArg(argList[i],XtNvSpace, 0); i++;
	XtSetArg(argList[i],XtNresize, TRUE);  i++;

	boxW = XtCreateManagedWidget(shellName, boxWidgetClass, parent,
		argList, i);

	return(boxW);
}

Widget gr_MakeBoxForm(shellName,parent, formW, topW, leftW)
char		*shellName;
Widget		parent;
Widget		topW, leftW, *formW;
/*Boolean		orient_vertical;*/
{
Widget		boxW;
Cardinal	i=0;
Arg	argList[20];

	boxW = gr_MakeBox2(shellName,parent, topW, leftW, TRUE);
	if(boxW == NULL)
		return NULL;
/*	XtSetArg(argList[i], XtNtop, XawChainBottom); i++;*/
/*	XtSetArg(argList[i], XtNbottom, XawChainBottom); i++;*/
	XtSetArg(argList[i],XtNdefaultDistance, 0);  i++;
	XtSetArg(argList[i],XtNvertDistance, 0);  i++;
	XtSetArg(argList[i],XtNhorizDistance, 0); i++;
	XtSetArg(argList[i],XtNborderWidth, 0); i++;
/*        XtSetArg(argList[i],XtNresizable, TRUE);  i++;*/
	*formW = XtCreateManagedWidget("BoxForm", formWidgetClass, boxW,
		argList, i);
	return boxW;
}

/* Returns true if size of wid is not zero. */
static Boolean not_zero(wid)
Widget wid;
{
Cardinal	i = 0;
Arg     argList[20];
Dimension width, height;

	XtSetArg(argList[i], XtNheight, &height); i++;
	XtSetArg(argList[i], XtNwidth, &width); i++;
	XtGetValues(wid, argList, i);
	return ((width > 0) && (height > 0));
}

/*
  Return an Miriad X Visualizer "window" with the given termination callBack
  procedure.  It has a Close button on the top left hand corner and
  a title bar to the right of the button. If the window gets resized, the
  quit button doesn't change, the title button will expand horizontally, but
  not vertically.
  Below the button and title is an Xaw form window that the caller uses to
  install its buttons, etc. It is returned in form.

form	Pointer to an Xaw form widget to be used for buttons, etc.
	This is used as parent for all children.
cbp	Call back procedure called when close button is pressed.
client_data
	Data to be passed to call_back procedure.
title	Title label
quit_label
	Label for quit button. (Usually "close", but is "quit" for top window.)
app_shell
	If true, this is part of the top application shell. Otherwise, a
	top level shell is created.

	Since the form widgets are created w/o any size parameters set,
	an error would occur if gr_MakeWindow were called after the toplevel
	widget were realized. To get around this, CreateWidget rather than
	CreateManagedWidget is used. The calling routine will have to call
	ManageChild itself.

Return:
	widget wrapper used for placing other widgets relative to this one.
*/

Widget
gr_MakeWindow2(shellName,parent,form,cbp,client_data,title,quit_label,
				app_shell)
char		*shellName;
Widget		parent,*form;
XtCallbackProc	cbp;
char		*title,*quit_label;
caddr_t		client_data;
Boolean		app_shell;
{
Widget		shellW, quitW, titleW, formW, formP;
Cardinal	i;
Arg		argList[20];

			/* Outer shell for window. */

	i = 0;
	/* Create top level shell if not already in one. */
	if(!app_shell)
	{	formP = shellW  = XtCreateWidget(shellName,
				topLevelShellWidgetClass,
				parent, argList, i);
		shellName = "FORM";
	}
	else
		formP = parent;

	formW = XtCreateManagedWidget( shellName,
		formWidgetClass, formP, argList, i);
	XawFormDoLayout(formW, FALSE);
			/* "Quit" button. */
	quitW =  gr_MakeButton3("Quit" ,formW, quit_label, NONE,
			cbp, client_data, NULL, NULL);

			/* Title string. */
	/* Title comes after quit, ends at right edge & is centered. */
	i = 0;
	if(title != NULL)
	{	XtSetArg(argList[i], XtNlabel, title); i++;}
/*	XtSetArg(argList[i], XtNresizable, TRUE); i++;*/
	XtSetArg(argList[i], XtNfromHoriz, quitW); i++;
	XtSetArg(argList[i], XtNtop, XawChainTop); i++;
	XtSetArg(argList[i], XtNbottom, XawChainTop); i++;
	XtSetArg(argList[i], XtNleft, XawChainLeft); i++;
	XtSetArg(argList[i], XtNright, XawChainRight); i++;

	XtSetArg(argList[i],XtNvertDistance, 0);  i++;
	XtSetArg(argList[i],XtNhorizDistance, 0); i++;
	XtSetArg(argList[i],XtNinternalHeight, 6); i++;

	/* The "MXVlabel" is looked for in gr_FileShowLevel! */
	titleW = XtCreateManagedWidget("MXVlabel", labelWidgetClass, formW,
			argList, i);

		/* Form widget for user stuff. */
	if(form != NULL)
	{	i = 0;
		XtSetArg(argList[i], XtNfromVert, quitW); i++;
		XtSetArg(argList[i], XtNtop, XawChainTop); i++;
		XtSetArg(argList[i], XtNbottom, XawChainBottom); i++;
		XtSetArg(argList[i],XtNvertDistance, 0);  i++;
		XtSetArg(argList[i],XtNhorizDistance, 0); i++;
		*form = XtCreateManagedWidget("MXVsubform", formWidgetClass,
				formW, argList, i);
	}

	if(app_shell)
		shellW = formW;

	return(shellW);
}

/* Simple wrapper to turn on those windows just made above. */
void gr_ManageChild(w)
Widget	w;
{
	XtManageChild(w);
}

/* Test data for figuring out character sizes. */
static char DATA[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ|";

/* How much space does a character font take?
Return_pixels
	If true, returns the width and height in pixels of text ROWS x COLS
	characters.
	If false, returns the width and height in characters of a space
	ROWS x COLS pixels big.

font	XFontStruct to use.
rows,	# of rows & columns.
cols	In chars if Return_pixels is true, in pixels if its false.
width,	*Dimension variables for return.
height	In pixels if Return_Pixels is true, in rows/cols if its false.
*/
void gr_RowColSize(font, Return_Pixels, cols, rows, width, height)
XFontStruct	*font;
Boolean		Return_Pixels;
Dimension	rows, cols;
Dimension	*width, *height;
{
XCharStruct	overall;
int		direction, ascent, descent, len, j;
float	w, h;

	/* Get info on 'typical' string. */
	len = sizeof(DATA) -1;
	XTextExtents(font, DATA, len, &direction, &ascent, &descent, &overall);
	/* How wide is a 'typical' character? */
	j = XTextWidth(font, DATA, len);
	w = (float) XTextWidth(font, DATA, len) /(float)len;
	if(Return_Pixels)
		w = w*(float)cols;		/* Width in pixels */
	else
		w = (float)cols/w;		/* Width in chars. */
	*width = (Dimension) (w + 0.5);

	/* How tall is it? */
	if(Return_Pixels)
		h = (float)( (ascent+descent)*(int)rows);
	else
		h = ( (float)rows/(float)(ascent+descent) + 0.5);
	*height = (Dimension)h;
}

/* Recursively look for a font struct in a widget or its parents. */
XFontStruct *gr_FindFont(wid)
Widget	wid;
{
Arg	argList[1];
XFontStruct	*font = NULL;

	if(wid == NULL)
		return NULL;
	XtSetArg(argList[0], XtNfont, &font);
	XtGetValues(wid, argList, 1);
	if(font == NULL)
		font = gr_FindFont(XtParent(wid));
	return font;
}

/* Resize a widget to be rows high, by cols wide.
If rows or cols is <= 0, ignore it.
font	XFontStruct to use. If NULL it is retrieved from wid.
domargins
	If TRUE, the widget is queried for its margins and they are used
	to compute the new size.
xoff,	Amount to ADD to width and height. (Used if window has no margins).
yoff	Ignored if row/col and widget height/width are 0.

Returns FALSE if had to abort (no font), else TRUE.
*/
Boolean gr_SetRowsCols(wid, font, rows, cols, domargins, xoff, yoff)
Widget	wid;
XFontStruct	*font;
int	rows, cols;
Boolean	domargins;
int	xoff, yoff;
{
Cardinal	i, j;
Arg		argList[20];
XCharStruct	overall;
int		direction, ascent, descent, len;
Dimension	leftMargin, topMargin, bottomMargin, rightMargin;
Dimension	width, height, wwidth, wheight;
Boolean		resizable;
float	w;

	i = 0;
	XtSetArg(argList[i], XtNwidth, &wwidth); i++;
	XtSetArg(argList[i], XtNheight, &wheight); i++;

	if(font == NULL)	  /* Get font struct from widget. */
	{	XtSetArg(argList[i], XtNfont, &font); i++;}

	if(domargins)
	{	XtSetArg(argList[i], XtNtopMargin, &topMargin); i++;
		XtSetArg(argList[i], XtNbottomMargin, &bottomMargin); i++;
		XtSetArg(argList[i], XtNleftMargin, &leftMargin); i++;
		XtSetArg(argList[i], XtNrightMargin, &rightMargin); i++;
	}
	else
	{	leftMargin = topMargin = bottomMargin = rightMargin = 0;
	}

	XtGetValues(wid, argList, i);
	/* If font is still NULL (widget not realized) go looking for one.*/
	if((font == NULL) && ((font = gr_FindFont(XtParent(wid))) == NULL) )
	{	fprintf(stderr, "gr_SetRowsCols: could not get a font.\n");
		return FALSE;
	}

	/* Get size in pixels. */
	gr_RowColSize(font, TRUE, (Dimension)cols, (Dimension)rows,
				&width, &height);

	i = 0;
	/* How wide should window be? */
	if( cols > 0)
		width += rightMargin + leftMargin + xoff;
	else
		if(wwidth > 0)
			width = wwidth + xoff;
		else
			width = 0;

	if(width > 0)
	{	XtSetArg(argList[i], XtNwidth, width); i++; }

	/* How tall should window be? */
	if( rows > 0)
		height += topMargin + bottomMargin + yoff;
	else
		if(wheight > 0)
			height = wheight + xoff;
		else
			height = 0;

	if( height > 0)
	{	XtSetArg(argList[i], XtNheight, height); i++; }

	/* Set new width/height. */
	XtSetValues(wid, argList, i);
	return TRUE;
}


/* Return number of rows & columns in a string. Cols is the max # of chars
on one line. rows will be equal to the number of 'newlines' + 1.

For now, tabs, backspaces are treated as characters since they aren't likely
to be seen in mxv.
*/
static void gr_strlen(str, rows, cols)
char	*str;
int	*rows, *cols;
{
int	r=0, c=0, cmax = -1, chr;
char	*p = str;

	if(str == NULL) return;
	while( (chr = *p++) != '\0')
	{	if(chr == '\n')
		{	if( c > cmax) cmax = c;
			c = 0;
			r += 1;
		}
		else
		c += 1;
	}
	*rows = r+1;
	*cols = c >= cmax ? c : cmax;
}

/*
 * Return an Athena text widget.
leftW	Widget to left.
topW	Widget above.
rows,
cols	Desired size of text window in lines/chars.
	If rows or cols is 0, the value will be gotten from string.
*/
Widget
gr_MakeText2(shellName,parent,vportWind,scrollType,textSelect,textSource,
			string, rows, cols, topW, leftW)
char		*shellName;
Widget		parent;
Widget		*vportWind;
Widget		leftW, topW;
int		cols, rows;
A_Scroll_t		scrollType;
A_TextSelect_t	textSelect;
A_TextSource_t	textSource;
char		*string;
{
Widget		textWind;
Cardinal	i=0;
Arg     argList[20];
XFontStruct	*font;
Widget	text;
Dimension	leftMargin, topMargin, bottomMargin, rightMargin;
Dimension	width, height;
float	w;
int	tmpr, tmpc;

	if(shellName == NULL)
		shellName = "MXVtext";

	/* Estimate # of rows/cols. */
	gr_strlen(string, &tmpr, &tmpc);
	if( rows <= 0) rows = tmpr;
	if( cols <=0) cols = tmpc;
	/* If they are still funny, force a default. */
	if( rows <= 0)
		rows = 1;
	if(cols < 1)
		cols = 1;
	else
	if(cols > 80)
		cols = 80;

	/* Position within parent. */
	if(leftW != NULL)
	{	XtSetArg(argList[i], XtNfromHoriz, leftW); i++;
	}
	if(topW != NULL)
	{	XtSetArg(argList[i], XtNfromVert, topW); i++;
	}
/*	XtSetArg(argList[i], XtNbottom, XawChainBottom); i++;*/
	XtSetArg(argList[i],XtNvertDistance, 0);	i++;
	XtSetArg(argList[i],XtNhorizDistance, 0);	i++;

	*vportWind = parent;
	switch (scrollType)
	{
		case NOSCROLL:
			break;
		case VERTONLY:
			XtSetArg(argList[i],XtNscrollVertical,
/* Would like to only use scrollbars when needed, but it may not work
quite the way we'd like.
*/
					XawtextScrollAlways); i++;
			break;
		case HORIZONLY:
			XtSetArg(argList[i],XtNscrollHorizontal,
						XawtextScrollAlways); i++;
			break;
		case VERTHORIZ:
			XtSetArg(argList[i],XtNscrollVertical,
					XawtextScrollAlways); i++;
			XtSetArg(argList[i],XtNscrollHorizontal,
					XawtextScrollAlways); i++;
			break;
	}

	if (textSource == STRINGSOURCE)
	{
		XtSetArg(argList[i],XtNtype,XawAsciiString);	i++;
		if (textSelect != SELECTABLE)
		{
			XtSetArg(argList[i],XtNsensitive,FALSE);	i++;
			XtSetArg(argList[i],XtNeditType,XawtextRead);	i++;
		}
		else
		{
			XtSetArg(argList[i],XtNsensitive,TRUE);	i++;
			XtSetArg(argList[i],XtNeditType,XawtextEdit);	i++;
		}
		XtSetArg(argList[i],XtNwrap,XawtextWrapWord);	i++;
		XtSetArg(argList[i],XtNlength,1000);	i++;
		XtSetArg(argList[i],XtNstring,string);	i++;
		textWind = XtCreateManagedWidget(shellName,
				asciiTextWidgetClass, *vportWind, argList, i);
	}
	else
	{
		XtSetArg(argList[i],XtNtype,XawAsciiFile);	i++;
		if (textSelect != SELECTABLE)
		{
			XtSetArg(argList[i],XtNsensitive,FALSE);	i++;
			XtSetArg(argList[i],XtNeditType,XawtextRead);	i++;
		}
		else
		{
/*			XtSetArg(argList[i],XtNsensitive,TRUE);	i++;*/
			XtSetArg(argList[i],XtNeditType,XawtextEdit);	i++;
		}
		XtSetArg(argList[i],XtNwrap,XawtextWrapWord);	i++;
		XtSetArg(argList[i],XtNstring,string);	i++;
		textWind = XtCreateManagedWidget(shellName,
				asciiTextWidgetClass, *vportWind, argList, i);
	}

	XawTextEnableRedisplay(textWind);

	/* Use font information to figure out how large window should be.*/
	i = 0;
	XtSetArg(argList[i], XtNfont, &font); i++;  /* Get font struct used. */
	XtSetArg(argList[i], XtNtopMargin, &topMargin); i++;
	XtSetArg(argList[i], XtNbottomMargin, &bottomMargin); i++;
	XtSetArg(argList[i], XtNleftMargin, &leftMargin); i++;
	XtSetArg(argList[i], XtNrightMargin, &rightMargin); i++;
	XtSetArg(argList[i], XtNheight, &height); i++;
	XtGetValues(textWind, argList, i);

	/* How wide should window be? */
	w = (float) XTextWidth(font, DATA, sizeof(DATA)) / (float)sizeof(DATA);
	w = w*cols + 0.5;		/* Width needed. */
	width = (int) w + rightMargin + leftMargin;
	XtSetArg(argList[0], XtNwidth, width);
	/* How tall should window be? */
	/******** ???????? **** Is this really correct??? *******/
	height -= topMargin + bottomMargin;
	height = rows*height + topMargin + bottomMargin;
	XtSetArg(argList[1], XtNheight, height);
	/* Set new width/height. */
	XtSetValues(textWind, argList, 2);
	return(textWind);
}

/*
 * Return an Athena Dialog widget.
 */
Widget
gr_MakeDialog(shellName, parent, label, defString, maxLen, nrows, topW, leftW)
char		*shellName;
Widget		parent;
char		*label;
char		*defString;
int		maxLen, nrows;
Widget		topW, leftW;
{
Widget		dialogWind,textWind, valueW, labelW;
Arg		argList[20];
Cardinal	i=0;
int		len, llen;

	if(shellName == NULL)
		shellName = "MXVdialog";

	if( label != NULL)
	{	XtSetArg(argList[i],XtNlabel,label);	i++;
		llen = strlen(label);
	}
	else
		llen = 0;

/*	XtSetArg(argList[i], XtNdefaultDistance, 6);	i++;*/
	XtSetArg(argList[i], XtNvertDistance, 0);	i++;
	XtSetArg(argList[i], XtNhorizDistance, 0);	i++;

	if(topW != NULL)
		{XtSetArg(argList[i], XtNfromVert, topW); i++;}
	if(leftW != NULL)
		{	XtSetArg(argList[i], XtNfromHoriz, leftW); i++; }

	if (defString != NULL)
	{
		XtSetArg(argList[i],XtNvalue,defString);	i++;
	}

	dialogWind = 
		XtCreateManagedWidget(shellName,dialogWidgetClass,
							  parent,argList,i);
	valueW = XtNameToWidget(dialogWind, "value");
	labelW = XtNameToWidget(dialogWind, "label");
	/* Increase internal spacing so height of dialog is about 2 labels. */
	XtSetArg(argList[0], XtNvertDistance, 8);
	XtSetValues(valueW, argList, 1);
	XtSetValues(labelW, argList, 1);
	/* The dialog's value widget tends to be set to a too large value.
	   set it to the max of either the string length, the maxLen or
	   the length of the label.
	*/
	len = (defString == NULL) ? 0 : strlen(defString);
	if(len < llen) len = llen;
	/* Some calls have maxLen set much too big. */
	if( maxLen > 20)
	{	printf("gr_makeDialog maxLen too big Parent: %s %d\n",
			XtName(parent), maxLen);
		maxLen = 20;
	}
	if( len < maxLen) len = maxLen;
	if(nrows <= 0) nrows = 1;
	gr_SetRowsCols(valueW, NULL, nrows, len, TRUE, 0, 0);
#if 1
	if( defString != NULL)
	{	textWind = gr_DialogGetTextWind(dialogWind);
		gr_TextSetInsertionPoint(textWind,(long)strlen(defString));
	}

/*
#ifdef XtSpecificationRelease
	XtSetArg(argList[0],XtNwidth,width-10);
	XtSetValues(textWind,argList,1);
#endif

    if (gr_Data.inputFocus == TRUE)
	    XtAddEventHandler(dialogWind,EnterWindowMask,FALSE,
			(XtCallbackProc)gr_DialogEventEnter,NULL);
*/
#endif
	return(dialogWind);
}


/* Translation string for 1 line dialogs. */
static  char Set1LineTransStr[]   = "<Key>Return:    no-op()";
static	XtTranslations	Set1LineTable=NULL;

/* Set up translations for 1 line dialogs.
*/
static void Set1LineTranslations(w)
Widget	w;
{
Widget textWid=XtNameToWidget(w,"value");

	if(Set1LineTable == NULL)
		Set1LineTable = XtParseTranslationTable(Set1LineTransStr);

	XtOverrideTranslations(textWid, Set1LineTable);
}

/*
 * Return a 1 line Athena Dialog widget.
 */
Widget
gr_MakeDialog1(shellName, parent, label, defString, maxLen, topW, leftW)
char		*shellName;
Widget		parent;
char		*label;
char		*defString;
int		maxLen;
Widget		topW, leftW;
{
Widget		w;

	/* Make a dialog. */
	w = gr_MakeDialog(shellName, parent, label, defString,
						maxLen, 1, topW, leftW);
	/* Set translations so <return> is a nop. */
	Set1LineTranslations(w);
	return(w);
}

/* Wrapper for XaWDialogAddButton */
void gr_AddDialogButton(w, name, shape, func, client_data)
Widget	w;
String	name;
A_ToggleShape_t	shape;
XtCallbackProc	func;
XtPointer	client_data;
{
Widget btn;
Arg argList[2];
Cardinal i;
int defDistance;

	btn = gr_MakeButton3(NULL, w, name, shape, func,
					client_data, NULL, NULL);
	/* Now, undo some of the settings. */
	defDistance = -1;
	XtSetArg(argList[0],XtNdefaultDistance, &defDistance);
	/* Use parent since defaultDistance isn't part of button. */
	XtGetValues(w, argList,1);
	if( defDistance == -1)
	{
       printf("gr_AddDialogButton: Warning could not get default distance.\n");
		defDistance = 4;
	}
	XtSetArg(argList[0],XtNhorizDistance, defDistance);
	XtSetArg(argList[1],XtNvertDistance, defDistance);
	XtSetValues(btn, argList, 2);
}

/*
 * Return an Athena ViewPort widget.
 */
Widget gr_MakeVPort2(shellName,parent,scrollType,
	cbp, client_data, width, height, topW, leftW)
char		*shellName;
Widget		parent;
A_Scroll_t	scrollType;
XtCallbackProc	cbp;
XtPointer	client_data;
int		width, height;
Widget		topW, leftW;
{
Widget		shellWind;
Cardinal	i;
Arg		argList[20];
WidgetClass	class = viewportWidgetClass;

	if(shellName == NULL)
		shellName = "MXVvport";

	i = 0;
	if(topW != NULL)
		{XtSetArg(argList[i], XtNfromVert, topW); i++;}
	if(leftW != NULL)
		{	XtSetArg(argList[i], XtNfromHoriz, leftW); i++; }
/*	XtSetArg(argList[i],XtNtop,XtChainTop);	i++;*/
	if(width > 0)
	{	XtSetArg(argList[i],XtNwidth,width);	i++;}
	if(height > 0)
	{	XtSetArg(argList[i],XtNheight,height);	i++;}
/*	XtSetArg(argList[i],XtNvertDistance, 0);	i++;
	XtSetArg(argList[i],XtNhorizDistance, 0);	i++;
*/
	switch (scrollType)
	{
		case NOSCROLL:	/* Default is no scroll bars. */
			class = portholeWidgetClass;
			break;
		case VERTONLY:
			XtSetArg(argList[i],XtNallowVert,TRUE); i++;
			XtSetArg(argList[i],XtNuseRight,TRUE); i++;
/*			XtSetArg(argList[i],XtNforceBars,TRUE); i++;*/
			break;
		case HORIZONLY:
			XtSetArg(argList[i],XtNallowHoriz, TRUE); i++;
			XtSetArg(argList[i],XtNuseBottom, TRUE); i++;
/*			XtSetArg(argList[i],XtNforceBars,TRUE); i++;*/
			break;
		case VERTHORIZ:
			XtSetArg(argList[i],XtNallowVert,TRUE); i++;
			XtSetArg(argList[i],XtNallowHoriz,TRUE); i++;
			XtSetArg(argList[i],XtNuseBottom, TRUE); i++;
			XtSetArg(argList[i],XtNuseRight,TRUE); i++;
/*			XtSetArg(argList[i],XtNforceBars,TRUE); i++;*/
			break;
		default:;
	}

	shellWind = XtCreateManagedWidget(shellName,
			class, parent,argList,i);
/*			viewportWidgetClass,parent,argList,i);*/

	if(cbp != NULL)
		XtAddCallback(shellWind, XtNreportCallback, cbp, client_data);

	return(shellWind);
}


/*
 * Move child widget in a scrolled window widget
 * This function is called to translate the position of the child in
 * a scrolledWindowWidget so that the point (xpos,ypos) of the child
 * is centered in the scrolled window of size: xsize by ysize.
 * The resulting coordinates of the translation is returned in
 * (xpos,ypos).  They may then be used to update other children based 
 * on the same horizontal and vertical slider values as needed.
	The return is the fraction of the width or height.
*/
void
gr_VPortMoveChild2(vw, sw, xpos,ypos)
Widget	vw;	/* Viewport window. */
Widget	sw;	/* Scrolled window in viewport window. */
float	*xpos, *ypos;
{
float	vfrac,hfrac, xoff, yoff, xscroll, yscroll;
Cardinal	i=0;
Arg		argList[2];
Dimension	vpw, vph, swh, sww;

	/* Get size of viewport window. */
	XtSetArg(argList[0],XtNwidth, &vpw);
	XtSetArg(argList[1],XtNheight, &vph);
	XtGetValues(vw, argList, 2);
	/* Get size of scrolled window. */
	XtSetArg(argList[0],XtNwidth, &sww);
	XtSetArg(argList[1],XtNheight, &swh);
	XtGetValues(sw, argList, 2);
	/* Center of viewport is what fraction of larger window? */
	xoff = ((float)vpw/(float)sww)*0.5;
	yoff = ((float)vph/(float)swh)*0.5;

	/* Compute scroll values needed to place *xpos, *ypos
	   in center of viewport window.
	*/
	xscroll = *xpos - xoff;
	yscroll = *ypos - yoff;
/*
printf("gr_VPortMoveChild2: x=%.2f/%d y=%.2f/d, xn=%.2f yn=%.2f\n",
	*xpos, xsize, *ypos, ysize, hfrac, vfrac);
	if(hfrac >
*/
	/* If scroll would be < 0, move to 0. */
	if(xscroll < 0.0) xscroll = 0.0;
	if(yscroll < 0.0) yscroll = 0.0;
	XawViewportSetLocation(vw, xscroll, yscroll);
	*xpos = xscroll; *ypos = yscroll;
}


/*
 * This function moves the child of a porthole widget horizontally
 * to effect a horizontal scroll. We'd like to use a Viewport widget
   but it won't scroll if there are no scrollbars.
 */
void
gr_VPortScrollChild(w, xoff, yoff)
Widget w;	/* Child of a viewport widget. */
float	   xoff, yoff;	/* Fraction to scroll. 0..1. */
{
Cardinal        i=0;
Arg             argList[2];
Dimension       width, height;
Position	x,y;

	if(!XtIsRealized(w))
		return;
	/* Get size of scrolled window. */
	XtSetArg(argList[0],XtNwidth, &width);
	XtSetArg(argList[1],XtNheight, &height);
	XtGetValues(w, argList, 2);
	i = 0;
	if(xoff < 0.0)
		xoff = 0.0;
	else
	if(xoff > 1.0)
		xoff = 1.0;
	if(yoff < 0.0)
		yoff = 0.0;
	else
	if(yoff > 1.0)
		yoff = 1.0;
	/* Negative to scroll left/up. */
	xoff = (float)width*xoff + 0.5;
	yoff = (float)height*yoff + 0.5;
	x = -(Position) xoff;
	y = -(Position) yoff;
	i = 0;
	XtSetArg(argList[i], XtNx, x);	i++;
	XtSetArg(argList[i], XtNy, y);	i++;
	XtSetValues(w, argList, i);

}

#if 1
gr_VPortHoriMove2(w,newpos)
Widget w;
float	   newpos;
{
	if(XtIsRealized(w))
		XawViewportSetLocation(w, newpos, -1.0);
}


/*
 * This function moves the child of a porthole widget vertically
 * in the box to effect a vertical scroll on the contents of the
 * box.
 */
void
gr_VPortVertMove2(w,newpos)
Widget w;
float	   newpos;
{
	if(XtIsRealized(w))
		XawViewportSetLocation(w, -1.0, newpos);
}
#endif
/*
 * Return a "simple" Athena list using the given viewport window.
 */
Widget gr_MakeListSimple2(shellName,vportWind,ncols,callBackProc,
			strings,client_data, topW, leftW)
char		*shellName;
Widget		vportWind;
char		*strings[];
int			ncols;
XtCallbackProc	callBackProc;
caddr_t		client_data;
Widget		topW, leftW;
{
Widget		listWind;
Cardinal	i=0;
Arg		argList[20];

	if(topW != NULL)
		{XtSetArg(argList[i], XtNfromVert, topW); i++;}
	if(leftW != NULL)
		{	XtSetArg(argList[i], XtNfromHoriz, leftW); i++; }
	XtSetArg(argList[i],XtNborderWidth,0); i++;
	XtSetArg(argList[i],XtNdefaultColumns,ncols);	i++;
	XtSetArg(argList[i],XtNforceColumns,TRUE);	i++;
	XtSetArg(argList[i],XtNlist,strings);	i++;
	XtSetArg(argList[i],XtNvertDistance, 0);	i++;
	XtSetArg(argList[i],XtNhorizDistance, 0);	i++;

	listWind = XtCreateManagedWidget(shellName,
			listWidgetClass, vportWind, argList, i);
						
	if (callBackProc)
		XtAddCallback(listWind, XtNcallback,callBackProc,client_data);

	return(listWind);
}

/*
 * Return an Athena list widget contained in a scrolledWindow
 * widget which has the specified vertical and horizontal scroll events.
 * Note that the viewport window is returned via the parameter vportWind.

maxrows,	Maximum # of rows/cols (in chars) to display.
maxcols
 */
	
Widget
gr_MakeList2(shellName,parent,vportWind,scrollType, ncols, strings,
			scrlEv, callBackProc, client_data,
			maxrows, maxcols, topW, leftW)
char		*shellName;
Widget		parent;
Widget		*vportWind;
A_Scroll_t	scrollType;
char		*strings[];
int		ncols;
XtCallbackProc	callBackProc, scrlEv;
caddr_t		client_data;
Widget		topW, leftW;
{
Arg		argList[8];
int		i;
Widget		listWind;
XFontStruct	*font;
Dimension	width, height;

	if(shellName == NULL)
		shellName = "MXVlist";

/*	*vportWind = gr_MakeVPort2("XTDvport",parent,scrollType,*/
	*vportWind = gr_MakeVPort2(shellName, parent,scrollType,
				 scrlEv, client_data,
					0,0, topW, leftW);
/*	listWind = gr_MakeListSimple2(shellName,vportWind,*/
	listWind = gr_MakeListSimple2( "SimpleList", *vportWind,
				 ncols,callBackProc,strings,
				 client_data, NULL, NULL);

	/* Set max rows/cols if needed. */
	if( (maxrows > 0) || ( maxcols > 0))
	{	/* Get font struct from listWind. */
		i = 0;
		XtSetArg(argList[i], XtNfont, &font); i++;
		/* Get size of listWind. */
		XtSetArg(argList[i], XtNwidth, &width); i++;
		XtSetArg(argList[i], XtNheight, &height); i++;
		XtGetValues(listWind, argList, i);
		/* How big is it in chars? */
		gr_RowColSize(font, FALSE, width, height, &width, &height);
		/* Don't change if current size is <= max. */
		if(maxcols >= (int)width) maxcols = 0;
		if(maxrows >= (int)height) maxrows = 0;
		/* Set vport window to something new size. */
		gr_SetRowsCols(*vportWind, font, maxrows, maxcols, FALSE, 10, 10);
	}
	return(listWind);
}

Widget
gr_MakeList3(shellName,parent, vportWind,scrollType, ncols, strings,
			scrlEv, callBackProc, client_data,
			minCols, minRows, maxCols, maxRows,
			topW, leftW)
char		*shellName;
Widget		parent;
Widget		*vportWind;
A_Scroll_t	scrollType;
char		*strings[];
int		ncols;
XtCallbackProc	callBackProc, scrlEv;
caddr_t		client_data;
/*int		mincols, maxcols, minrows, maxrows;*/
int		minCols, maxCols, minRows, maxRows;
Widget		topW, leftW;
{
Arg		argList[8];
int		i, nrows, entries;
Widget		listWind;
XFontStruct	*font;
Dimension	width, height/*, minCols, minRows, maxCols, maxRows*/;
Dimension	internalHeight, internalWidth, columnSpacing, rowSpacing;
Boolean		needChange;
char		**sptr;

	if(shellName == NULL)
		shellName = "MXVlist";

	*vportWind = gr_MakeVPort2(shellName, parent,scrollType,
				 scrlEv, client_data,
					0,0, topW, leftW);
	listWind = gr_MakeListSimple2( "SimpleList", *vportWind,
				 ncols,callBackProc,strings,
				 client_data, NULL, NULL);

	/* Make sure the size of the list is within desired range. */

	/* Get font struct from listWind. */
	i = 0;
	XtSetArg(argList[i], XtNfont, &font); i++;
	/* Get size of listWind. */
	XtSetArg(argList[i], XtNwidth, &width); i++;
	XtSetArg(argList[i], XtNheight, &height); i++;
	XtSetArg(argList[i], XtNinternalWidth, &internalWidth); i++;
	XtSetArg(argList[i], XtNinternalHeight, &internalHeight); i++;
	XtSetArg(argList[i], XtNcolumnSpacing, &columnSpacing); i++;
	XtSetArg(argList[i], XtNrowSpacing, &rowSpacing); i++;
	XtGetValues(listWind, argList, i);
	/* How many rows? */
	for(sptr= strings; *sptr != NULL; sptr++);	/* # of strings. */
	entries = sptr-strings;
	nrows = entries / ncols;	/* Full rows.	*/
	i = entries % ncols;		/* Whats left.	*/
	if(i != 0)
		nrows += 1;
	/* Remove margins & spacing. */
	width -= internalWidth + ncols * columnSpacing;
	height -= internalHeight + nrows * rowSpacing;
	/* How big is it in chars? */
	gr_RowColSize(font, FALSE, width, height, &width, &height);
	/* The above call is probably superfluous since nrows,ncols is known.*/

	needChange = FALSE;
	if( width < (Dimension) minCols)
	{	width = minCols;
		needChange = TRUE;
	}
	else
	if( width > (Dimension) maxCols )
	{	width = maxCols;
		needChange = TRUE;
	}		
	else
		width = 0;	/* 0 means don't change. */

	if( height < (Dimension) minRows)
	{	height = minRows;
		needChange = TRUE;
	}
	else
	if( height > (Dimension) maxRows )
	{	height = maxRows;
		needChange = TRUE;
	}
	else
		height = 0;	/* 0 means don't change. */

	if(needChange)
	{	/* Set vport window to new size. */
		gr_SetRowsCols(*vportWind, font, height, width, FALSE,
			internalWidth + ncols * columnSpacing,
			internalHeight+ height* rowSpacing);
	}

	return(listWind);
}

/*
 * Return a toggle widget.
	cbp gets called on select and release.

The toggle is kept from resizing by chaining to an edge of its parent.
It therefore needs to be inside a box or form that can get moved. Otherwise,
it will be stepped on when resizes occur.

*/
Widget
gr_MakeToggle2(shellName,parent,label,toggleShape,setOn,cbp,
				client_data, topW, leftW)
char		*shellName;
Widget		parent;
char		*label;
A_ToggleShape_t	toggleShape;
Boolean		setOn;
XtCallbackProc	cbp;
caddr_t		client_data;
Widget		topW, leftW;
{
Widget		toggleWind;
Arg		argList[20];
Cardinal	i=0;
char		*bmtype;

	if(shellName == NULL)
		shellName = "MXVtoggle";

	if(topW != NULL)
		{XtSetArg(argList[i], XtNfromVert, topW); i++;}
	if(leftW != NULL)
		{	XtSetArg(argList[i], XtNfromHoriz, leftW); i++; }
	if(label != NULL)
	{	XtSetArg(argList[i],XtNlabel,label);	i++;
		bmtype = XtNleftBitmap;
	}
	else
		bmtype = XtNbitmap;

	XtSetArg(argList[i],XtNstate,setOn);	i++;
	/* Don't let button change size. */
	XtSetArg(argList[i], XtNtop, XawChainTop); i++;
	XtSetArg(argList[i], XtNbottom, XawChainTop); i++;
	XtSetArg(argList[i], XtNright, XawChainLeft); i++;
	XtSetArg(argList[i], XtNleft, XawChainLeft); i++;

	XtSetArg(argList[i],XtNresizable, FALSE);  i++;
	XtSetArg(argList[i],XtNvertDistance, 0);  i++;
	XtSetArg(argList[i],XtNhorizDistance, 0); i++;
	XtSetArg(argList[i],XtNinternalHeight, 6); i++;
#ifdef PIXMAPBACKGROUND
	XtSetArg(argList[i],XtNbackgroundPixmap, gray); i++;
#endif
	i = set_bitmap( parent, &argList[i], bmtype, toggleShape, i);
	toggleWind = 
		XtCreateManagedWidget(shellName,toggleWidgetClass,
						  parent,argList,i);

	if (cbp != NULL)
		XtAddCallback(toggleWind,"callback",cbp,client_data);
	return(toggleWind);
}

/* Add widget wid to radio group that widget group is in.
   If 'one_of_many' is true, the widget's translations are changed so
   it becomes a one of many button.
*/
static XtTranslations	trans_table = NULL;
static char table[] = "<Btn1Down>,<Btn1Up>:	set() notify()";


gr_MakeRadio(wid, group, one_of_many)
Widget	wid, group;
Boolean	one_of_many;
{
Arg             argList[2];
Cardinal        i=0;

	if(one_of_many)
	{	if(trans_table == NULL)
			trans_table = XtParseTranslationTable(table);
		/* This could be done in SetValues, but this won't necessarily
		   replace the whole table.
		*/
		XtOverrideTranslations(wid,trans_table);
	}
	if(wid != group)
	{	XtSetArg(argList[0], XtNradioGroup, group);
	        XtSetValues(wid,argList, 1);
	}
}

/* Return status of toggle 'state' resource. */
Boolean gr_is_toggle_set(wid)
Widget	wid;
{
Arg             argList[2];
Cardinal        i=0;
Boolean		state;

	XtSetArg(argList[i], XtNstate, &state); i++;
	XtGetValues(wid,argList,i);
	return state;
}


/* set a toggle (or button) to ON or OFF. */
gr_set_button_state(wid, state)
Widget	wid;
Boolean		state;
{
Arg             argList[2];
Cardinal        i=0;

	XtSetArg(argList[i], XtNstate, &state); i++;
	XtSetValues(wid,argList,i);
}


/*
 * Return an 'HP Workspace widget'. (W/O using HP widgets).
 */
Widget
gr_MakeWorkSpace2(shellName,parent,exposecbp,resizecbp,keydowncbp,
			client_data, width, height, topW, leftW)
char		*shellName;
Widget		parent;
XtCallbackProc	exposecbp,resizecbp,keydowncbp;
caddr_t		client_data;
int			width,height;
{
Arg             argList[20];
Widget		workSWind;
Cardinal	i=0;

	if(shellName == NULL)
		shellName = "MXVworkspace";

	if(topW != NULL)
		{XtSetArg(argList[i], XtNfromVert, topW); i++;}
	if(leftW != NULL)
		{	XtSetArg(argList[i], XtNfromHoriz, leftW); i++; }
	XtSetArg(argList[i],XtNwidth,width);	i++;
	XtSetArg(argList[i],XtNheight,height);	i++;
	workSWind = XtCreateManagedWidget(shellName, workSpaceWidgetClass,
						parent,argList,i);
	if (exposecbp != NULL)
		XtAddCallback(workSWind, XtNexposeCallback,
				exposecbp,client_data);
	if (resizecbp != NULL)
		XtAddCallback(workSWind,"resize",resizecbp,client_data);
	if (keydowncbp != NULL)
		XtAddCallback(workSWind,"keyDown",keydowncbp,client_data);

	return(workSWind);
}

/*
 * Return a staticImage widget
 */
Widget
gr_MakeImageStatic2( shellName, parent, image,
	scbp, client_data, width, height, topW, leftW)
char		*shellName;
Widget		parent, topW, leftW;
XImage		*image;
XtCallbackProc	scbp;
caddr_t		client_data;
int			width,height;
{
Arg             argList[20];
Widget		workSWind;
Cardinal	i=0;
Widget		imageWind;

	if(shellName == NULL)
		shellName = "MXVstaticimage";

	if(width > 0)
	{	XtSetArg(argList[i],XtNwidth,width);	i++; }
	if(height > 0)
	{	XtSetArg(argList[i],XtNheight,height);	i++; }
	XtSetArg(argList[i],XtNsRimage,image);	i++;
	XtSetArg(argList[i],XtNinvertOnSelect,FALSE);	i++;
	XtSetArg(argList[i],XtNgravityName, "North");	i++;
	if(topW != NULL)
		{XtSetArg(argList[i], XtNfromVert, topW); i++;}
	if(leftW != NULL)
		{	XtSetArg(argList[i], XtNfromHoriz, leftW); i++; }

	imageWind = 
		XtCreateManagedWidget(shellName, srasterWidgetClass,
							  parent,argList,i);

	if (scbp != NULL)
		XtAddCallback(imageWind, XtNselect, scbp,client_data);

	return(imageWind);
}

/* Put a floating point value in an arglist. */
static void set_float_arg(arg, resource, val)
Arg     *arg;
char    *resource;
float   val;
{
float   flt = val;
XtArgVal *ptr;

        if( sizeof(float) > sizeof(XtArgVal))
        {       XtSetArg(arg[0], resource, &flt);
        }
        else
        {       ptr = (XtArgVal *)&flt;
                 XtSetArg(arg[0], resource, *ptr);
        }
}


/* Return the width and height of a widget. */
static Dimension get_widget_dimension(wid, what)
Widget	wid;
char	*what;
{
Arg argList[1];
Cardinal i = 0;
Dimension x;

	XtSetArg(argList[i], what, &x); i++;
	XtGetValues(wid, argList, i);
	return x;
}

/* Return a slider widget.
min,max		User defined range. (max may be < min).
extent		Width of slider in user coordinates.
		If extent is <0, it will be set to 1 'step'.
startpos	Where the slider starts. (In user coordinates).
scbp,mcbp	Select and Move callback procedures.
client_data	XtPointer to user data.
width,		Size of slider in pixels. If 0, a warning message will
		be printed and defaults used.
height
*/
Widget gr_MakeSlider2(shellName, parent, min, max, extent, startpos,
			scbp, mcbp, client_data, orient,
			width, height, topW, leftW)
char		*shellName;
Widget		parent;
int		min,max,extent,startpos;
XtCallbackProc	scbp,mcbp;
A_Scroll_t	orient;
caddr_t		client_data;
Widget		topW, leftW;
{
Widget		shellWind;
float		xmin,xmax, shown;
Arg             argList[20];
Widget		workSWind;
Cardinal	i=0;

	if(shellName == NULL)
		shellName = "MXVslider";

	if(topW != NULL)
		{XtSetArg(argList[i], XtNfromVert, topW); i++;}
	if(leftW != NULL)
		{	XtSetArg(argList[i], XtNfromHoriz, leftW); i++; }

	if(width == 0)
	{	printf("Slider width was 0, setting to default.\n");
		width = 100;
	}

	if(height == 0)
	{	printf("Slider height was 0, setting to default.\n");
		height = 20;
	}
	XtSetArg(argList[i],XtNwidth,width); i++;
	XtSetArg(argList[i],XtNheight,height); i++;
	if (orient != VERTONLY)
	{	XtSetArg(argList[i],XtNorientation, XtorientHorizontal);i++;}
	XtSetArg(argList[i],XtNmin,min);	i++;
	XtSetArg(argList[i],XtNmax,max);	i++;
	XtSetArg(argList[i],XtNposition, startpos);	i++;
	if(extent <= 0) extent = 1;
	if( extent > 0)
	{
		xmax = (float) max;
		xmin = (float) min;
		shown = extent/(xmax-xmin);
		set_float_arg( &argList[i], XtNshown, shown); i++;
	}
	shellWind = XtCreateManagedWidget(shellName, sliderWidgetClass,
						parent, argList,i);

	if (mcbp != NULL)
		XtAddCallback(shellWind,XtNmoveProc,mcbp,client_data);
	if (scbp != NULL)
		XtAddCallback(shellWind,XtNselectProc,scbp,client_data);

	return(shellWind);
}

/***************************************************************/
/*****************		MENU ROUTINES	****************/
/***************************************************************/

/*
Modifications to menubuttons to support callback procedures.
 Used in sprintf stmnt. Both args are the menu name. (Can't have blanks).
	Button 1	callback
	Button 2	Nothing
	Button 3	Menu
*/
static char actions[] = "<Btn1Down>:	set() notify() unset()\n\
			 <Btn2Down>:	\n\
			 <Btn3Down>:	reset()\
					XawPositionSimpleMenu(%s)\
					MenuPopup(%s)";


/* 
Replace a menu button's translation table.
btn	A menu button widget.
menu	A simple menu widget.
trans	A pointer to the translation to use. If NULL (the normal case),
	the standard MXV translations will be used.
*/
void gr_SetMenubuttonTranslation(btn, menu, trans)
Widget	btn, menu;
XtTranslations	trans;
{
Arg             args[2];
Cardinal        i=0;
char	buf[256];
char	*name;

	if((btn == NULL) || (menu == NULL))
		return;
	if(trans == NULL)	/* Use default. */
	{	/* Get the menu name, build translations, parse. */
		name = XtName(menu);
		sprintf(buf, actions, name, name);
		trans = XtParseTranslationTable( buf);
	}
	/* This could be done in SetValues, but this won't necessarily
	   replace the whole table.
	*/
	XtOverrideTranslations(btn, trans);
}


/* Create a menu button widget with translations appropriate for our use.
The left mouse button causes the cbp to be called.
The middle mouse button does nothing.
The right mouse button positions & pops up the menu.

name	Name given to button.
label	Text string in button.
menu	menu widget to attach to the button.
cbp/data
	callback procedure attached to left button press.
topW,leftW
	Standard positioning widgets.
*/
Widget gr_MakeMenuButton(name, parent, label, menu, cbp, data, topW, leftW)
char	*name;
Widget	parent, menu;
char	*label;
void	(*cbp)();
XtPointer	data;
Widget		topW, leftW;
{
Arg	argList[20];
Cardinal i;
Widget	btn;

	if(name == NULL)
		name = "MXVmenuButton";
	i = 0;
	if(label != NULL)
	{	XtSetArg(argList[i], XtNlabel, label); i++;}
	if(menu != NULL)
	{	XtSetArg(argList[i], XtNmenuName, XtName(menu)); i++; }
	if( topW != NULL)
	{	XtSetArg(argList[i], XtNfromVert, topW); i++;
	}
	if( leftW != NULL)
	{	XtSetArg(argList[i], XtNfromHoriz, leftW); i++;
	}
/*	XtSetArg(argList[i], XtNcursorName, "rightbutton"); i++;*/
	XtSetArg(argList[i], XtNcursorName, "mouse"); i++;
	/* Don't let button change size. */
	XtSetArg(argList[i], XtNtop, XawChainTop); i++;
	XtSetArg(argList[i], XtNbottom, XawChainTop); i++;
	XtSetArg(argList[i], XtNright, XawChainLeft); i++;
	XtSetArg(argList[i], XtNleft, XawChainLeft); i++;
	/* Same as make_button. */
	XtSetArg(argList[i],XtNresizable, FALSE);  i++;
	XtSetArg(argList[i],XtNvertDistance, 0);  i++;
	XtSetArg(argList[i],XtNhorizDistance, 0); i++;
	XtSetArg(argList[i],XtNinternalHeight, 6); i++;

	btn = XtCreateManagedWidget(name, 
			menuButtonWidgetClass, parent, argList, i);

	gr_SetMenubuttonTranslation(btn, menu, NULL);
	if(cbp != NULL)
		XtAddCallback(btn, XtNcallback, cbp, data);

	return btn;
}

/* Create a simple menu.

'label' is the string at the top of the menu. 'menuName' is the menu's
name. It must not contain any blanks otherwise the translation
routines complain.
*/
Widget gr_MakeMenu(menuName, parent, label)
Widget	parent;
char	*label, *menuName;
{ Arg	argList[2];
Cardinal i; Widget	menu;

	if(menuName == NULL)
		menuName = "MXVmenu";
	i = 0;

	if(label != NULL)
	{	XtSetArg(argList[i], XtNlabel, label); i++;}
	menu = XtCreatePopupShell(
		menuName, simpleMenuWidgetClass, parent, argList, i);
	/* Put a line under the title. */
	XtCreateManagedWidget("Menu_Line", smeLineObjectClass, menu,
			NULL, 0);
	return menu;
}

/* Add entry to menu.
*/
Widget gr_AddMenuEntry(name, menu, text, proc, data)
Widget	menu;
char	*name, *text;
void	(*proc )();
XtPointer data;
{
Arg	argList[4];
Cardinal i;
Widget	btn;

	if(name == NULL)	/* Use text as name of menu. */
		name = text;
	i = 0;
	XtSetArg(argList[i], XtNlabel, text); i++;
	XtSetArg(argList[i],XtNinternalHeight, 6); i++;
	btn = XtCreateManagedWidget(name, smeBSBObjectClass, menu,
			argList, i);
	/* A a line underneath. */
	XtCreateManagedWidget("Menu_Line", smeLineObjectClass, menu,
			NULL, 0);
	if(proc != NULL)
		XtAddCallback(btn, XtNcallback, proc, data);
	return btn;
}

/* Set item to be 'default' menu selection.
'item' becomes the default selection.

If menu is NULL, assume the parent of the item is the menu in question.
*/
void gr_SetMenuSelection( menu, item)
Widget	menu, item;
{
Arg	argList[2];
Cardinal i;

	if(item == NULL)
		return;
	if(menu == NULL)
		menu = XtParent(item);
	XtSetArg(argList[0], XtNpopupOnEntry, item);
	XtSetValues(menu, argList, 1);
}
