/*
 *	File:		gr_xwi.c
 *	Contents:	Manipulation functions for X widgets
 *	The functions defined are specific to X-windows or the Athena widget
 *	set.
 */

#include "gr_com.h"
#include "gr_xwi.h"

/*
 *	Attempt to get a PseudoColor 8-plane visual if possible
 */
Visual
*gr_GetVisual(dpy,scr)
Display	*dpy;
int		scr;
{
	XVisualInfo	vinfo;

	if (XMatchVisualInfo(dpy,scr,(int)8,PseudoColor,&vinfo))
		return(vinfo.visual);
	else
		return(DefaultVisual(dpy,scr));
}

#if 0
/*
 * Turn a widget On or Off
 */
void
gr_WidgetSensitive(wid,sen)
Widget wid;
Boolean sen;
{
	XtSetArg(argList[0],XtNsensitive,sen);
	XtSetValues(wid,argList,1);
}
#endif

/*
 * Turn a Button On or Off
 */
void
gr_ButtonSet(wid,isOn)
Widget wid;
Boolean isOn;
{
	gr_set_button_state(wid, isOn);
}


/*
 * Change a cursor font for a shell window
 */
void gr_WidgetCursor(wid, cursorfont)
Widget wid;
int cursorfont;
{
	Cursor cursor;
	Window win = XtWindow(wid);
	Display *dpy = XtDisplay(wid);

	if (win)
	{
		cursor = XCreateFontCursor(dpy,cursorfont);
		XDefineCursor(dpy,win,cursor);
		XFlush(dpy);
	}
	return;
}

/* Change cursor for a widget. The widget must be a subclass of Simple. */
void gr_WidgetCursor2(wid, cursorName)
Widget wid;
char *cursorName;
{
Arg	argList[1];

	XtSetArg(argList[0], XtNcursorName, cursorName);
	XtSetValues(wid, argList, 1);

	return;
}


/*
 * Change the contents of an Athena list widget
 */
void
gr_ListChange(wid,list,nitems,longest,resize)
Widget wid;
String *list;
int nitems,longest;
Boolean resize;
{
#ifdef XtSpecificationRelease
	XawListHighlight(wid,0);
	XawListChange(wid,list,nitems,longest,resize);
	XawListHighlight(wid,0);
#else
	XtListHighlight(wid,0);
	XtListChange(wid,list,nitems,longest,resize);
	XtListHighlight(wid,0);
#endif
}


/*
 * Highlight an entry in an Athena list widget
 */
void
gr_ListHighlight(wid,item)
Widget wid;
int item;
{
	if(wid == NULL)
		return;
#ifdef XtSpecificationRelease
	XawListHighlight(wid,item);
#else
	XtListHighlight(wid,item);
#endif
}


/*
 * Get the string and index of the selected list item in Athena list
 */
char
*gr_ListgetStruct(wid,ind)
Widget wid;
int	   *ind;
{
#ifdef XtSpecificationRelease
	XawListReturnStruct	*strngStruct;

	strngStruct = XawListShowCurrent(wid);
	*ind = strngStruct->list_index;
	return(strngStruct->string);
#else
	XtListReturnStruct	*strngStruct;

	strngStruct = XtListShowCurrent(wid);
	*ind = strngStruct->index;
	return(strngStruct->string);
#endif
}


#ifdef XtSpecificationRelease
/*
 *  Save message buffer out to text file
 */
void
gr_TextMsgSave()
{
    Widget  asciiSrc;

    XtSetArg(argList[0],XtNtextSource,&asciiSrc);
    XtGetValues(gr_topWin.msgWin,argList,1);
    if (XawAsciiSave(asciiSrc) == FALSE)
        fprintf(stderr,"Warning\t: Cannot write logbook.\n");
}
#endif


/*
 * Set insertion pointer in Athena text widget
 */
void
gr_TextSetInsertionPoint(wid,atPos)
Widget wid;
long   atPos;
{
int	p1, p2;
#ifdef XtSpecificationRelease
/*	p1 = XawTextGetInsertionPoint(wid);*/
	XawTextSetInsertionPoint(wid,atPos);
/*	p2 = XawTextGetInsertionPoint(wid);
	printf("Insertion point changed from %d to %d\n", p1, p2);
*/
#else
	XtTextSetInsertionPoint(wid,atPos);
#endif
}


/*
 * Replace text in an Athena text widget
 */
void
gr_TextReplace(wid,startPos,endPos,strng)
Widget wid;
char *strng;
long startPos,endPos;
{
#ifdef XtSpecificationRelease
	XawTextBlock	text;
#else
	XtTextBlock	text;
#endif

	text.firstPos = 0;
	text.length = strlen(strng);
	text.ptr = strng;
	text.format = FMT8BIT;

#ifdef XtSpecificationRelease
	XawTextReplace(wid,startPos,endPos,&text);
#else
	XtTextReplace(wid,startPos,endPos,&text);
#endif
}


/*
 * Get internal Athena text widget from Athena dialog widget
 */
Widget
gr_DialogGetTextWind(w)
Widget w;
{
/*
	return (((DialogWidget)w)->dialog.valueW);
*/
	return (XtNameToWidget(w,"value"));
}


/*
 * Get string from Athena dialog widget
 */
char
*gr_DialogGetValue(wid)
Widget wid;
{
#ifdef XtSpecificationRelease
	return(XawDialogGetValueString(wid));
#else
	return(XtDialogGetValueString(wid));
#endif
}

/* Return a vector of floating point values from a dialog widget.
Allocates space for the values and returns a pointer to it and the number
of values decoded.

w	Dialog widget
vals	Address of where to return pointer.
nvals	Pointer to where to return number of values.

Function return is the length of the array (which should be > nvals).
The caller will need to free the allocated space.
*/
extern double strtod();
int gr_DialogGetFloatValues(w, vals, nvals)
Widget	w;
double	**vals;
int	*nvals;
{
char	*ss, *p;
int	n;
float	*f, *fp;
double	val;
	ss = gr_DialogGetValue(w);
	/* Allocate an array long enough to handle strlen/2 values since
	   we need at least one char between fields. ("1 2" is 2 values).
	*/
	n = strlen(ss)/2 + 1;
	f = fp = (float *) calloc(n, sizeof(*f));
	/* Keep decoding until p = ss, which means we either finished or
	   there was an illegal char.
	*/
	p = NULL;
	while(1)
	{	val = strtod(ss, &p);	/* Will be zero when done. */
		if(p == ss)
			break;
		else
			*f++ = (float) val;
		ss = p;
	}
	if(vals != NULL)
		*vals = (double *)fp;
	if(nvals != NULL)
		*nvals = f - fp;
	return n;	/* Length of array. */
}

/*
 * Set string in Athena dialog widget
 */
void gr_DialogSetValue(wid,strng)
Widget wid;
char *strng;
{
	Widget textWid;
	String oldStrng;

	if((wid == NULL) || (strng == NULL))
		return;
	textWid = gr_DialogGetTextWind(wid);
	oldStrng = gr_DialogGetValue(wid);
	gr_TextReplace(textWid,0,strlen(oldStrng),strng);
	gr_TextSetInsertionPoint(textWid,strlen(strng));
}


/*
 * Set label string in Athena Label/Command widget
 */
void
gr_LabelSetValue(wid,strng)
Widget wid;
char *strng;
{
	XFontStruct *myfont;

	XtSetArg(argList[0],XtNlabel,strng); 
	XtSetValues(wid,argList,1);
}

/*
 * Set slider position in slider widget
 */
void
gr_SliderSetValue(wid,pos)
Widget wid;
int	   pos;
{
	if(wid != NULL)
		SliderSetThumb(wid, pos, -1.0);
}

/*
 * Get slider position
 */
int
gr_SliderGetValue(wid)
Widget wid;
{
	int pos;

	pos = SliderReadThumb(wid);
	return(pos);
}

/*
 *	Override existing key translations for text Widget in Dialog Widget.
 */
void
gr_DialogAddTrans(wid,trans)
Widget wid;
char   *trans;
{
	XtTranslations	trans_table;
	Widget			textWid=gr_DialogGetTextWind(wid);

	trans_table = XtParseTranslationTable(trans);

	XtOverrideTranslations(textWid,trans_table);
}

	/*****************************************************************/
/*
 *	File:		gr_xwi2.c
 *	Contents:	Creation functions for X widgets
 *	This file is an extension of the file gr_xwi1.c
 */

void
gr_DialogEventEnter(w,client_data,call_data)
Widget  w;
caddr_t client_data;
caddr_t call_data;
{
		XSetInputFocus(XtDisplay(w), XtWindow(w),RevertToParent,CurrentTime);
}

/* ----- choose a nice bold font ---------------------- */
/* some suggested nice fonts jng 19-feb-91 */

#define MYMEDIUMFONT "*helvetica*medium-r-normal--12*"
#define MYMEDIUMFONT1 "*helvetica*medium*normal--12*"
#define MYMEDIUMFONT2 "6x13"

XFontStruct * getmediumfont(wid) 
Widget wid;
{
   XFontStruct * myfont;

  	if ( myfont = XLoadQueryFont(XtDisplay(wid),MYMEDIUMFONT)) return(myfont);
  	if ( myfont = XLoadQueryFont(XtDisplay(wid),MYMEDIUMFONT1)) return(myfont);
  	if ( myfont = XLoadQueryFont(XtDisplay(wid),MYMEDIUMFONT2)) return(myfont);
	return(0); /* no such font */
}

/* ----- choose a nice bold font ---------------------- */
/* some suggested nice fonts jng 19-feb-91 */

#define MYBOLDFONT "*helvetica*bold-r-normal--12*"
#define MYBOLDFONT1 "*helvetica*bold-o-normal--12*"
#define MYBOLDFONT2 "6x13bold"

XFontStruct * getboldfont(wid) 
Widget wid;
{
   XFontStruct * myfont;

  	if ( myfont = XLoadQueryFont(XtDisplay(wid),MYBOLDFONT)) return(myfont);
  	if ( myfont = XLoadQueryFont(XtDisplay(wid),MYBOLDFONT1)) return(myfont);
  	if ( myfont = XLoadQueryFont(XtDisplay(wid),MYBOLDFONT2)) return(myfont);
	return(0); /* no such font */
}
/* ------------------------------------------------------- */

/* Add a destroy callback to a widget. */
void gr_AddDestroy(w, proc, data)
Widget		w;
XtCallbackProc	proc;
XtPointer	data;
{
	if((w != NULL) && (proc != NULL))
		XtAddCallback(w, XtNdestroyCallback, proc, data);
}

/* Alot of times we only need to deallocate (free) a single structure.
For those cases, this routine should suffice.

Neither the widget nor the call_data are referenced.
*/
void	gr_free(w, data, call_data)
Widget	w;
XtPointer	data, call_data;
{
	if(data != NULL)
		free(data);
}
	/*****************************************************************/
/* Return a resource string or default.
Prepends resource with 'mxv' and class with 'MXV' followed by the
hostname. This way different hosts can have different resources.

Usually called with w = shell;

Any blanks in the widget name are replaced by '_'.

If debugging info is requested, the resource and class strings are printed.
The calling routine is expected to finish by printing the returned value.
*/
static String	getStringResource(w, resource, class, def)
Widget	w;
String	resource, class, def;
{
static XrmValue	value;
static char		*sret;
String	ret;
char	res[132], cls[132], xtname[132], *wname, *p;
int	c;

	/* Get widget name, replacing blanks with underscores. */
	p = xtname;
	wname = XtName(w);
	while( (c = *wname++) != '\0')
		*p++ = (c != ' ') ? c : '_';
	*p = '\0';

/*	if( *resource == '.')
*/
	sprintf(res, "%s.%s.%s.%s",
		td_getShortToolName(FALSE), td_Hostname(),
		xtname, resource);
#if 0
	else	/* I don't think this is ever used. */
		sprintf(res, "%s.%s", td_getShortToolName(FALSE),
			td_Hostname(), resource);
#endif
	sprintf(cls, "%s.%s.%s.%s",
/*		td_getShortToolName(TRUE), xtname, class);*/
		td_getShortToolName(TRUE), td_Hostname(), xtname, class);

	if(XrmGetResource(XtDatabase(XtDisplay(w)), res, cls, &sret, &value))
		ret = value.addr;
	else
		ret = def;

	/* Start the debugging output. Finished by caller. */
	if(gr_Data.listresources)
		printf("%s/%s:	", res, cls);

	return ret;
}

String	gr_GetStringResource(w, resource, class, def)
Widget	w;
String	resource, class, def;
{
char	*ret;

	ret = getStringResource(w, resource, class, def);

	if(gr_Data.listresources)
		printf("%s\n", ret);

	return ret;
}

/* Return a resource integer or default. */
int	gr_GetIntResource(w, resource, class, def)
Widget	w;
String	resource, class;
int	def;
{
String	ret, dmy= NULL;
int	value;

	ret = getStringResource(w, resource, class, dmy);
	if(ret == dmy)
		value = def;
	else
		value = strtol(ret, NULL, 0);

	if(gr_Data.listresources)
		printf("%d\n", value);

	return value;
}

/* Return a resource float or default. */
float	gr_GetFloatResource(w, resource, class, def)
Widget	w;
String	resource, class;
float	def;
{
String	ret, dmy= NULL;
float	value;

	ret = getStringResource(w, resource, class, dmy);
	if(ret == dmy)
		value = def;
	else
		value = (float) atof(ret);

	if(gr_Data.listresources)
		printf("%f\n", value);

	return value;
}

/* Return a resource Boolean or default. */
Boolean	gr_GetBooleanResource(w, resource, class, def)
Widget	w;
String	resource, class;
Boolean	def;
{
String	ret, dmy= NULL;
Boolean	value;

	ret = getStringResource(w, resource, class, dmy);
	if(ret == dmy)
		value = def;
	else
		if( (strcmp(ret, "TRUE") == 0) || (strcmp(ret, "true")==0))
			value = TRUE;
		else
			value = FALSE;

	if(gr_Data.listresources)
		printf("%s\n", (value) ? "TRUE" : "FALSE");

	return value;
}

/* Get a filename resource.

If directory is TRUE, the resource is handled has a directory, otherwise
as a filename.
*/
#ifndef FILENAMECLASS
#define	FILENAMECLASS		"Filename"
#define	DIRECTORYNAMECLASS	"Directory"
#endif

String gr_GetFileResource(w, resource, def, directory)
Widget	w;
String	resource, def;
Boolean	directory;
{
char	*ret, *class;
static	char buf[MAXPATHLEN+1];

	class = (directory) ? DIRECTORYNAMECLASS : FILENAMECLASS;

	ret = getStringResource(w, resource, class, def);

	/* parse resource. Use internal buffer since parseFileName may
	   calling us.
	*/
	ret = td_parseFilename(ret, buf);

	if(gr_Data.listresources)
		printf("%s\n", ret);

	return ret;
}

/* Convert a string to file format.
Returns UNKNOWN if type is unknown.
*/
static struct {
	char	*name;
	A_FileFormat_t	format;
	} formats[] = 
	{	{ "HDF", HDF},
		{ "hdf", HDF},
		{ "MIRIAD", MIRIAD},
		{ "miriad", MIRIAD},
		{ "FITS", FITS},
		{ "fits", FITS}
	};
#define	NFILEFORMATS (sizeof(formats)/sizeof(*formats))

A_FileFormat_t gr_str_to_format(str)
char	*str;
{
int	i;

	if(str == NULL)
		return UNKNOWN;
	for(i=0; i< NFILEFORMATS; i++)
		if(strcmp(str, formats[i].name) == 0)
			return formats[i].format;

	return UNKNOWN;
}


	/*****************************************************************/


	/*****************************************************************/

/* Draw a label with left, center, right justification.
dpy	Display
drw	Drawable	Window or Pixmap to draw to.
gc	GC		GC to use.
font	*XFontStruct	font info
x,y	int		point to justify about.
str	char *		String.
justify	int		How to justify
			0	Justify left.
			1	Justify right.
			2	Center about x/y.
chr_offset	int	Number of characters to offset justification.
			Normally 0, but can be used to add extra blank space.
			+ moves text right.
			Assumes font is fixed width.
#define	LEFT_JUSTIFY	0
#define	RIGHT_JUSTIFY	1
#define	CENTER_JUSTIFY	2
*/

void Notate(dpy, drw, gc, font, x, y, str, justify, chr_offset)
Display	*dpy;
Drawable drw;
GC	gc;
XFontStruct *font;
int	x,y;
char	*str;
int	chr_offset;
A_Justify_t	justify;
{
int	len, width, xoffset;

	len = strlen(str);
	width = XTextWidth(font, str, len);
	/* How much does offset move text? */
	if(chr_offset != 0)
	{ float xwidth;
	  int	olen;
	  char	*optr;

		if(len < 1)		/* Need something. */
		{	optr = "Test.12";
			olen = strlen(optr);
			xwidth = (float) XTextWidth(font, optr, olen);
		}
		else
		{	xwidth = (float) width;
			olen = len;
		}

		xwidth /= (float) olen;		/* Width per char. */
		chr_offset = (int) ((xwidth * (float)chr_offset) + 0.5);
	}

	switch( justify) {
	case RIGHT_JUSTIFY:
		xoffset = -width;
		break;
	case CENTER_JUSTIFY:
		xoffset = -width/2;
		break;
	case LEFT_JUSTIFY:
	default:		/* Anything else is left justify. */
		xoffset = 0;
		break;
	}
/*	XDrawString(dpy, drw,gc, x + xoffset + chr_offset, y, str, len);*/
	XDrawImageString(dpy, drw,gc, x + xoffset + chr_offset, y, str, len);
}
