/*
This file was originally part of XIMAGE. It has been hacked to be part of MXV.

Conversion notes:
	The MXV read palette routine(s) should call SaveForUndo.
	(see CBLoadPal).
 */

#ifdef sun
#define bcopy(a,b,c) memcpy((b),(a),(c))
#endif

#include <math.h>
#include <X11/Intrinsic.h>
#include "gr_xwi.h"
#include "gr_com.h"
#include "ximage.h"

#define PALCOMPHEIGHT	100
/*#define PAL_WIDTH	28*/

#ifndef TRUE
#define TRUE 1
#endif
#ifndef FALSE
#define FALSE 0
#endif

extern Widget gr_make_palette();

/* copy a color cell */
#define cpccell(a,b)	{\
			a.red = b.red; \
			a.green = b.green; \
			a.blue = b.blue;\
			a.flags = b.flags; \
			a.pad = b.pad;\
			}

#define MAX3(a,b,c) ((a>b)&&(a>c)) ? a : ((b > c)? b : c)
#define MIN3(a,b,c) ((a<b)&&(a<c)) ? a : ((b < c)? b : c)
#define SIGN(a) ((a)?(a/abs(a)):1) /* return 1 if zero */


extern	Widget	toplevelform;			/* The top dude (composite)*/
extern	void	CBEditPalEntry();
extern Widget MakeRasterImage();

unsigned long white;
unsigned long black;

static	Display	*myDpy;				/* Display for this program*/
static	Visual	*myVis;
static	Widget	top_pal_ctrl_widget;		/* pal ctrl window ap shell*/
static	Widget	pal_ctrl_widget;		/* composite widget ctrl win*/
static	XWindowAttributes pcw_attrib;		/* window attributes */
static	char palette_ctrl_window_showing = FALSE;	/* self explanitory */
static	XColor	bccells[256];			/* Back up copy */
static	Boolean	restrictFiddleCursor;		/* If TRUE, fiddle cursor is
						   restricted to its own win.*/
/* mxv supports (at least) 2 color maps. Ximage only supported one. This
structure holds the information that needs to be kept separate between
different functions that modify color maps.
*/
static struct ColorInfo {
	Colormap	cmap;	/* Colormap used. */
	XColor	original[256],	/* original copy. Set on entry to the window.
				   Used by reset button.
				*/
		current[256],	/* Current state of colormap.	*/
		undo[256];	/* Used to undo last function.	*/
	} colorInfo[2];		/* 0->normal, 1->split.		*/
#define	NColorInfoEntries	(sizeof(colorInfo)/sizeof(*colorInfo))

/* A couple of macros for frequently accessed components.	*/
#if 0
#define	INDEXtoCMAP(i)		(colorInfo[i].cmap)
#define	INDEXtoCURRENT(i)	(&(colorInfo[i].current[0]))
#define	INDEXtoORIGINAL(i)	(&(colorInfo[i].original[0]))
#define	INDEXtoUNDO(i)	(&(colorInfo[i].undo[0]))
#else
/* For debugging. */
#define	VALID_INDEX(i)	( ((i)>=0) && ((i)< NColorInfoEntries))
Colormap INDEXtoCMAP(i)
A_Colormap_t	i;
{
	if(!VALID_INDEX(i))
	{	fprintf(stderr,
		  "MXV internal error: Bad index to INDEXtoCMAP (%d)\n", i);
		i = 0;
	}
	return colorInfo[i].cmap;
}

XColor *INDEXtoCURRENT(i)
A_Colormap_t	i;
{
	if(!VALID_INDEX(i))
	{	fprintf(stderr,
	  "MXV internal error: Bad index to INDEXtoCURRENT (%d, %#x)\n", i, i);
		i = 0;
	}
	return &(colorInfo[i].current[0]);
}

XColor *INDEXtoORIGINAL(i)
A_Colormap_t	i;
{
	if(!VALID_INDEX(i))
	{	fprintf(stderr,
		"MXV internal error: Bad index to INDEXtoORIGINAL (%d)\n", i);
		i = 0;
	}
	return &(colorInfo[i].original[0]);
}

XColor *INDEXtoUNDO(i)
A_Colormap_t	i;
{
	if(!VALID_INDEX(i))
	{	fprintf(stderr,
		  "MXV internal error: Bad index to INDEXtoUNDO (%d)\n", i);
		i = 0;
	}
	return &(colorInfo[i].undo[0]);
}
#endif


/* Ideally, all routines accessing colorInfo would have the right index.
However, for some it would get a bit messy since they already use the
client_data arg. Those routines will have to use this until (unless) they
get changed.

This will get set whenever palette control window is created.
*/
static	A_Colormap_t	currentColorindex = NORMALCMAP;

/* Mxv will not use any color cells already allocated in the default
colormap. Sysccells holds a copy of the default colormap as of the start
of mxv. The pad entry in the XColor struct is used to hold a mask that
indicates whether the cell was in use and whether it is the black or white
cell. (Need to be careful not to assume the pad is safe between X calls).

Mxv can be told to use all but the B/W cells or the entire map. If it is
desired to go back to using fewer colors, the red,green,blue parts of the
XColor struct will then be needed.

This not perfect. If the user sets a resource color, it is likely to be
allocated AFTER the palette initialization. Whenever the palette is in use,
that color will be squashed.
*/
static	XColor	sysccells[256];
#define	ALLOC_MASK	0x1	/* Whether entry is allocated.*/
#define	BW_MASK		0x2	/* Mask for the black and white pixels. */
#define	UNALLOC_MASK	0x0	/* Not allocated. */

/* Storecolors looks at this to determine whether to write a color entry
to the server.
*/
static	int	reserved_mask = ALLOC_MASK;

static	int	numColors;		/* max num colors on this screen*/

static	crlastx = 0;
static	Widget pal_comp;
static	GC 	pal_comp_gc;
static	int	comp_pen=0;		/* color to draw new component */
static	unsigned long comp_pen_dcolor;	/* color to draw comp pen */
static	int	comp_last_x=0;
static	int	comp_last_y=0;
static	XPoint	rpoints[256];		/*drawn red points(CBDrawComponent)*/
static	XPoint	gpoints[256];		/*drawn green points*/
static	XPoint	bpoints[256];		/*drawn blue points*/
static	XPoint	cpoints[256];		/*drawn cyan  */
static	XPoint	mpoints[256];		/*drawn magenta  */
static	XPoint	ypoints[256];		/*drawn yellow */
static	XPoint	hpoints[256];		/*drawn hue */
static	XPoint	spoints[256];		/*drawn saturation*/
static	XPoint	vpoints[256];		/*drawn value */
static	unsigned int	rgbcmyhsv=0;	/* What's plotted (r=(1<<9),v=(1<<1))*/
static	palRedraw = FALSE;

void	CBInitRotate();
void	CBReset();
void	CBEvalExpr();
void	CBNewLoadPal();
void	CBSetPen();
void	CBUnSetPen();
void	CBPrepChangeComp();
void	CBChangeComponent();
void	CBEndChangeComp();
void	RedrawComponent();
void	CBTranspose();
void	TransposeCMap();
void	CBFiddle();
void	CRotate();
int	ChooseColor();
void	CBRedrawComponents();
void	CBCompKey();
void	CBPalSave();
void	CBUndo();
void	SaveForUndo();
void	CBSmooth();
void	CBDrawComponentToggle();
void	CBSetPenToggle();
void	CBUnDrawComponent();

/* Copy colormap cells from one XColor array to another.
in,out	XColor pointers to XColor arrays to be copied.
num		Number of XColor elements to copy.
copypixel	Copies the pixel value if true.
NOTE:
	Assumes there is space in the output array!!
*/
static void copy_colors(in, out, num, copypixel)
register XColor	*in,*out;
register int	num, copypixel;
{
	if(copypixel)
		bcopy(in, out, sizeof(XColor)*num);
	else
	while(--num > 0)
	{	out->red = in->red;
		out->green = in->green;
		out->blue = in->blue;
		out->flags = in->flags;
		out->pad = in->pad;
		out++; in++;
	}
}

/* Return a pixelMapping struct filled in with current values.
If mapping is NULL, a new struct will be allocated.
*/
pixelMapping *xi_getPixelMapping(mapping)
pixelMapping *mapping;
{
int	i,j;
unsigned char *m;
short	*um;

	if(mapping == NULL)
		mapping = (pixelMapping *)malloc(sizeof(*mapping));
	if(mapping == NULL)
		return NULL;
	um = mapping->unmap;
	m=mapping->map;
	for(j=0, i=0; i< 256; i++)
	{	if((sysccells[i].pad & reserved_mask) == 0)
		{	m[j] = i;	/* Map.		*/
			um[i]= j++;	/* Unmap.	*/
		}
		else
			um[i] = -1;	/* Set to invalid. */
	}
	mapping->npixels = j;

	return mapping;
}

/* Map an array of floating point numbers to pixels. If pixels is NULL
allocate the array.
data	Input floating data array
width,
height	Size of data.
scale	scale vactor
pixels	Output pixel array of size [width*scale,height*scale].
min,	Min/max data points.
max
mapping	Pixel conversion info. pointer.

*/
unsigned char *xi_mapPixels( data, width, height, scale,
				pixels, min, max, mapping)
float	*data;			/* Input data. */
int	width, height, scale;	/* Size of data and scale factor.. */
unsigned char	*pixels;	/* Where to store, if non NULL. */
float	min,max;		/* Range of data's elements.	*/
pixelMapping *mapping;		/* Mapping struct.		*/
{
float	scl, x;
int	pmax, p, rowWidth, r, c, s;
unsigned char *pxls, *map, *rowptr, *nextline;
int linesToDo, linesScaled, nPixelsCopied, nlines;

	if((width <= 0) || (height <= 0) || (scale <= 0))
		return NULL;
	if(pixels == NULL)
		pixels = (unsigned char *)malloc(width*height*scale);
	if(pixels == NULL)
		return NULL;

	pmax = mapping->npixels-1;
	map = mapping->map;
	scl = ((float)pmax)/(max-min);
	pxls = pixels;
	rowWidth = width*scale;		/* Width of pixel array. */
	/* For each row of the data array... */
	for(rowptr = pixels, r=0; r< height; r++)
	{
		/* For each element in a row... */
		for(pxls = rowptr, c=0; c< width; c++)
		{	/* Scale data point to 0..npixels-1,		*/
			p = (int )((*data++ - min)*scl /*+ 0.5*/ );
			/* then lookup in mapping array.		*/
			p = (p <= 0) ? 0 : (p>=pmax) ? pmax : map[p];
			/* then copy to output scale times.		 */
			for(s=0; s< scale; s++)
				*pxls++ = p;
		}
		/* Replicate the row scale-1 times. */
		linesScaled = 1;	/* # of lines that have been scaled. */
		linesToDo = scale -1;	/* # of lines left to do.	*/
		nextline = rowptr + rowWidth;	/* Where to copy to.	*/
		while( linesToDo > 0)
		{	/* nlines is min of what we've done & what's left. */
			nlines = (linesScaled <= linesToDo) ? linesScaled
							     : linesToDo;
			nPixelsCopied = nlines*rowWidth;
			bcopy(rowptr, nextline, nPixelsCopied);
			linesScaled += nlines;
			linesToDo -= nlines;
			nextline += nPixelsCopied;
		}
		rowptr += rowWidth*scale;
	}
	return pixels;
}


/* Map a floating point number to a pixel. This is just a stripped down
version of xi_mapPixels and should only be used until the calling routines
are rewritten to use that. It is currently called by those routines that
used to use the MXV_CNV2PIX macro.

data	Input floating data point.
min,	Min/max data values.
max
mapping	Pixel conversion info. pointer.

returns the scaled pixel.
*/
unsigned char xi_mapPixel( data, min, max, mapping)
float	data;			/* Input data. */
float	min,max;		/* Range of data's elements.	*/
pixelMapping *mapping;		/* Mapping struct.		*/
{
float	scl;
int	pmax, p;
unsigned char *map;

	if(mapping == NULL)
		return 0;
	map = mapping->map;
	pmax = mapping->npixels-1;
	scl = ((float)pmax)/(max-min);
	/* Scale data point to 0..npixels-1,		*/
	p = (int )((data - min)*scl /*+ 0.5*/ );
	/* then lookup in mapping array.		*/
	p = (p <= 0) ? 0 : (p>=pmax) ? pmax : map[p];
	return (unsigned char) p;
}

/* Convert an integer CM index back into a floating point data element
the best we can. 

pixel	pixel value to be converted.
data	address of where to store result. If NULL, nothing is returned.
min,max	Scale factors.
mapping	Pointer to pixel mapping info.

Function returns TRUE if pixel maps into valid data, FALSE otherwise.
*/
Boolean	xi_unmapPixel(pixel, data, mapping, min, max)
int	pixel;
float32	*data;
pixelMapping *mapping;		/* Mapping struct.		*/
float32	min,max;
{
	if(mapping == NULL)
		return FALSE;
	if((pixel<0) || (pixel >= 256))
		return FALSE;		/* Not valid. */
	pixel = mapping->unmap[pixel];	/* Map pixel.	*/
	if(pixel < 0)
		return FALSE;		/* Not valid.	*/
	if(data != NULL)
		*data = (float) (pixel*((max-min)/(float)(mapping->npixels-1))
				+ min);

	return TRUE;
}

/* Write any non-reserved colors to the server.

If the matchindex variable is TRUE, ccells[0] will either go into color[0]
or else not be copied. If FALSE, ccells[0] will go into the first available
slot and the last several values won't get copied. If there is a definite
win one way or the other, the variable will go away. If not, it will probably
become a resource.
*/
/* Merge a color table with the reserved table.
Returns the number of colors copied.
*/
static int MergeColors(ccells, colors)
XColor	ccells[], colors[];	/* colors to be merged and where to put them */
{
int	i, num=0, np;
Boolean	matchindex=FALSE;

	/* Copy all non-reserved colors to temp array then write that.
	   Assumes that sysccells[i].pixel = i;
	*/
	for(np=0, i = 0; i< numColors; i++)
	{	
		if( (sysccells[i].pad & reserved_mask) == 0)
		{	bcopy( (char *) &ccells[np], (char *) &colors[i],
					sizeof( XColor));
			num += 1;
			if(matchindex)
				np = i+1;
			else
			{	colors[i].pixel = i;
				np += 1;
			}
		}
		else
		{	bcopy( (char *) &sysccells[i], (char *) &colors[i],
				sizeof( XColor));
		}
	}
	return num;
} /* MergeColors() */

static void StoreColors(ccells, redraw, index)
XColor	ccells[];	/* colors to be stored. */
int	redraw;		/* Should I redraw components? */
A_Colormap_t index;
{
int	num;
XColor	colors[256];
Colormap cmap;		/* colormap to store colors in. */

	if (myVis->class != PseudoColor) {
	  gr_TextMsgOut("Can't set colors for this non-PseudoColor display\n");
	    return;
	    }

	num = MergeColors( ccells, colors);

	if(num > 0)
	{	cmap = INDEXtoCMAP(index);
		XStoreColors(myDpy,cmap, colors, numColors);

		if (redraw)
			RedrawComponent(index);
	}

	return;
} /* StoreColors() */

/* External version of StoreColors. First, rccells is saved for undo. Then,
ccells is copied to rccells to set it as the current copy. Finally,
StoreColors is called.
*/
void xi_storeColors(ccells, redraw, index)
XColor	ccells[];	/* colors to be stored. */
int	redraw;		/* Should I redraw components? */
int	index;
{
Colormap cmap;		/* colormap to store colors in. */

	SaveForUndo(index);
	copy_colors(ccells, INDEXtoCURRENT(index), 256, FALSE);
	StoreColors(ccells, redraw, index);
}

/* PROTECT_NONE needs to be first. */
typedef enum { PROTECT_NONE=0, PROTECT_BW, PROTECT_ALLOCATED } ColorProtection;

/* Convert a string to DisplayTimes.
Returns DisplayAlways if type is unknown.
*/
static char allocstr[80];
/* The order of the first three entries is important. */
static struct {
        char    	*name, *printVal;
	ColorProtection	protection;
	int		mask;
        } colorProtections[] =
	{ { "NONE",		"Using Entire Palette",
						PROTECT_NONE, UNALLOC_MASK},
	  { "BLACK-WHITE",	"  Using all but B&W ",
						PROTECT_BW, BW_MASK},
	  { "ALLOCATED",	allocstr,
						PROTECT_ALLOCATED, ALLOC_MASK},
	};
#define NPROTECTIONS (sizeof(colorProtections)/sizeof(*colorProtections))

/* Convert a string to a ColorProtection. Used to convert resource strings.*/
static ColorProtection gr_StrToColorProtection(str)
char    *str;
{
int     i;

	if(str == NULL)
		return PROTECT_ALLOCATED;
	for(i=0; i< NPROTECTIONS; i++)
		if(strcmp(str, colorProtections[i].name) == 0)
			return colorProtections[i].protection;

	return PROTECT_ALLOCATED;
}

/* Convert an ColorProtections value to a character string. Returned,
string is either the 'resource' value or a 'printvalue' all of which
have the same length.

If val is not valid, returns NULL.
*/
static char *gr_ColorProtectionToStr(val, printval)
ColorProtection	val;
Boolean		printval;
{
int     i;

	for(i=0; i< NPROTECTIONS; i++)
		if( val == colorProtections[i].protection)
			return ((printval) ? colorProtections[i].printVal
					  : colorProtections[i].name);

	return NULL;
}

/* Called when Palette use entire palette button is pressed. Toggles to next
setting.
*/
/* This should probably be elsewhere, but since its only used here and
int the initialization routine...
*/
static ColorProtection colorprotection_status;

static void setColorProtection(val)
ColorProtection	val;
{
char	*str;

	colorprotection_status = val;
	reserved_mask = colorProtections[val].mask;
}

/* Called when the 'using so many colors button' is pressed to change
to the next setting.
*/
static XtCallbackProc toggle_colorProtections(w, client_data, call_data)
Widget	w;
XtPointer	client_data, call_data;
{
A_Colormap_t	index = (A_Colormap_t) client_data;
ColorProtection	val;
char	*str;

	val = colorprotection_status + 1;
	if(val > PROTECT_ALLOCATED)
		val = PROTECT_NONE;

	setColorProtection(val);
	StoreColors(INDEXtoCURRENT(index), TRUE, index);
	str = gr_ColorProtectionToStr(val, TRUE);
	gr_LabelSetValue(w, str);
}

/* Close/destroy palettebox window.
*/
void ClosePaletteBox(w,client_data,call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
A_Palette_t	*PalData = (A_Palette_t *) client_data;
A_Colormap_t	index = PalData->index;

	if (palette_ctrl_window_showing) {
		if( (PalData != NULL) && (PalData->cs != NULL))
		{	copy_colors(INDEXtoCURRENT(index),
				PalData->cs->cmapCells,
				256, FALSE);
		}
		XtDestroyWidget(top_pal_ctrl_widget);
		}


	palette_ctrl_window_showing = FALSE;
}

/* Initialize the sysccells array.
Assumes that InitPalette has been called to setup some variables.

Create the normalColormap for use later.
Initialize origccels;

Load the value of the default colormap into sysccells.
Allocate everything we can from default colormap. Flag the ones we CAN'T
allocate as being inuse. Then free the ones we just got. This could mess
up some program that happens to be trying to allocate some colors at just
the wrong time, so lets hope its over quickly.
*/
static void init_colormaps(dpy)
Display *dpy;
{
int x;
int screen, white, black;
unsigned long pixels[256], i, j, pxl, npixels, *pxlptr;
Colormap	map;
Window		win;
Visual		*visual;

	screen = DefaultScreen(dpy);
	visual = gr_GetVisual(dpy, screen);
	map = DefaultColormap(dpy, screen);
	win = DefaultRootWindow(dpy);

	white = WhitePixel(dpy,screen);		/* special pixel indices. */
	black = BlackPixel(dpy,screen);

	/* Get a copy of the system's colormap. */
	for(x=0;x < numColors; x++)
		sysccells[x].pixel = x;
	XQueryColors(dpy, map, sysccells, numColors);
	/* Copy it to other places. */
	bcopy( (char *) &sysccells, (char *) &(colorInfo[0].original),
		sizeof(colorInfo[0].original));
	bcopy( (char *) sysccells, (char *) colorInfo[0].current,
		sizeof(colorInfo[0].current));
	bcopy( (char *) sysccells, (char *) colorInfo[0].undo,
		sizeof(colorInfo[0].undo));
	bcopy( (char *) &colorInfo[0], &colorInfo[1], sizeof(colorInfo[0]));

	colorInfo[NORMALCMAP].cmap =
			XCreateColormap(dpy, win, visual, AllocAll);
	colorInfo[SPLITCMAP].cmap =
			XCreateColormap(dpy, win, visual, AllocAll);

	/* Determine which colors are 'reserved' by first allocating all
	   we can. The ones we couldn't are already reserved. Don't forget
	   to give back the ones we grabbed. Note that we don't assume that
	   the pad value was preserved across the XQueryColors call.
	*/

	for(i=0; i< numColors; i++)
		sysccells[i].pad = ALLOC_MASK;		/* Flag as in use. */

	/* This can theoretically get all but one of the colormap entries.
	   Since we won't use more than n-2 anyway, no problem.
	*/
	npixels = numColors/2;
	pxlptr = pixels;
	while( npixels > 0)
	{	if(XAllocColorCells(dpy, map, FALSE, NULL, 0, pxlptr, npixels))
			pxlptr += npixels;
		npixels /= 2;
	}
	npixels = pxlptr - pixels;
	XFreeColors(dpy, map, pixels, npixels, 0);
	XFlush(dpy);				/* Force the xfree to server.*/
	if(npixels > numColors - 2)		/* Reserve B/W just in case. */
		npixels = numColors - 2;
	for(i=0; i< npixels; i++)
	{	pxl = pixels[i];
		sysccells[pxl].pad = 0;		/* Flag as r/w. */
	}
	/* Generate a label string. */
	sprintf(allocstr, "  Using %3d colors  ", npixels);

	{ char msg[80];
		sprintf(msg, "%d of %d colors available.\n", npixels,
								numColors);
		gr_TextMsgOut(msg);
	}
	/* Mark the two special pixels. */
	sysccells[black].pad |= BW_MASK;
	sysccells[white].pad |= BW_MASK;
}

static int palette_initialized = 0;

int InitPalette(wid)
Widget	wid;
{
Display *dpy;
int x;
int screen;
char	*str, *res;
ColorProtection val;

	if(palette_initialized)
	{	printf("InitPalette called again.\n");
		return(1);
	}
	dpy    = XtDisplay(wid);
	myDpy = dpy;
	screen = DefaultScreen(dpy);
	myVis = gr_GetVisual(dpy, screen);

	white = WhitePixel(dpy,screen);
	black = BlackPixel(dpy,screen);

	numColors = XDisplayCells(dpy,screen);
	if (numColors > 256) {
		numColors = 256;   /* only use max 256 color entries */
		}

	/* Pick up default string for protected colors. */
	res = gr_ColorProtectionToStr(PROTECT_ALLOCATED, FALSE);
	str = gr_GetStringResource(wid,
			"colorProtection", "ColorProtection", res);
	val = gr_StrToColorProtection(str);
	setColorProtection(val);
	/* Is fiddle cursor restricted to its own window or can it roam? */
	restrictFiddleCursor = gr_GetBooleanResource(wid,
		"restrictFiddleCursor", "RestrictCursor", TRUE);

	init_colormaps(dpy);	/* Initialize sysccells & color arrays. */

	palette_initialized = 1;
	return(1); /* initialize ok */
}


void CBInitPal(w,client_data,call_data)
/* This procedure called on exposure of palette control window*/
/* Sets the colormap for the window */
Widget w;
caddr_t client_data;
caddr_t call_data;
{
Display *dpy;
Widget w2;
Colormap c;

#if 0	/* Still doesn't know about A_Colormap_t stuff. */
/*	printf("CBInitPal() I've been called\n");
	fflush(stdout);*/
	dpy = XtDisplay(w);
/*	XSync(dpy,False);*/

	if (!defStaticVisual)
		XSetWindowColormap(dpy,XtWindow(w),normalCmap);

	XtRemoveEventHandler(w,ExposureMask,0,
		(XtEventHandler)CBInitPal,NULL);

#if 0
	/* I don't think this command should be here, but it seems *
	 * to make it work.....oh well... 			   *
	 * Shake up the ICCCM window manager maybe? 		   */
	if (!defStaticVisual) {
		XSetWindowColormap(dpy,XtWindow(w),normalCmap);
		XSync(dpy,False);
		}
#endif
	XtVaSetValues(w, XtNcolormap, normalCmap, NULL);
/*
	XtVaGetValues(w, XtNcolormap, &c, NULL);
	printf("Normal %#x, set %#x\n", normalCmap, c);
	w2 = (Widget) client_data;
	while(XtParent(w2) != NULL)
		w2 = XtParent(w2);
	XtSetWMColormapWindows(w2, &w, 1);
*/
#endif
}

/*
Set the colormap of a widget to cmap refered to by index.
*/
void xi_setColormap(wid, index)
Widget		wid;
A_Colormap_t	index;
{
Display	*dpy;
Window	w;
Visual	*v;
int	x;
Colormap cmap;

	v = DefaultVisual( XtDisplay(wid), DefaultScreen(XtDisplay(wid)));

	if (v->class != PseudoColor)
        {	/* Don't do error message if myVis is NULL, since its likely
		   that the message window isn't around yet.
		*/
		if(myVis != NULL)
			gr_TextMsgOut(
			"Can't set colors for this non-PseudoColor display\n");
		return;
	}

	cmap = INDEXtoCMAP(index);

/*	if (!defStaticVisual) {
		XSetWindowColormap(dpy,w,cmap);
		attrib.colormap = cmap;
		XChangeWindowAttributes(dpy,w,CWColormap,&attrib);
		}
*/
	XtVaSetValues(wid, XtNcolormap, cmap, NULL);

}

/* Make a box widget and put color display and edit buttons in it. */
static Widget make_color_buttons(parent, display, edit, label,
			dsp_cbp, edt_cbp, data)
Widget		parent, *display, *edit;
char		*label;
XtCallbackProc	dsp_cbp, edt_cbp;
XtPointer	data;
{
Widget	boxW;

	boxW = gr_MakeBox2(NULL, parent, NULL, NULL, FALSE);
	*display = gr_MakeToggle2(NULL, boxW, NULL, SQUARE, FALSE,
			dsp_cbp, data, NULL, NULL);
	*edit = gr_MakeToggle2(NULL, boxW, label, DIAMOND, FALSE,
			edt_cbp, data, NULL, *display);
	return boxW;
}

/* Called whenever palette button is pushed. */
void PaletteBox(w,client_data,call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
Widget	buttonbox1;
Widget	buttonbox2;
Widget	buttonbox3;
Widget	boxwind;
Widget	tmpboxW, rgbW, cmyW, hsvW, colorW, tmpW;

Display *dpy;
Visual	*vis;
int x;
int	xpos,ypos;
A_Palette_t	*PalData = (A_Palette_t *) client_data;
char	*str;
Widget	pal_image;			/* The palette display window*/
A_Colormap_t	index;
Boolean	split;				/* TRUE if this is for dicer window.*/

	if (palette_ctrl_window_showing) {
		gr_TextMsgOut("Palette window already open\n");
		return;
		}

	/* Make sure client_data is OK. */
	{	if( (PalData->Load_Palette == NULL) ||
		    (PalData->Save_Palette == NULL))
		{	printf("PaletteBox called with bad client_data\n");
			return;
		}
	}
		
	currentColorindex = index = PalData->index;
	if(!VALID_INDEX(index))
	{	fprintf(stderr,
		  "MXV internal error: Bad index to PaletteBox (%d)\n", index);
		fprintf(stderr, "PalData is %#x\n", PalData);
		index = currentColorindex = 0;
	}
	split = (index==SPLITCMAP);

	dpy = XtDisplay(w);
	vis = gr_GetVisual(dpy, DefaultScreen(dpy));

	if (vis->class != PseudoColor) {
		gr_TextMsgOut("MXV can't change palette on this display.\n");
		gr_TextMsgOut("Not a Pseudo Color device\n");
		return;
		}

	if ( DisplayPlanes(dpy,XDefaultScreen(dpy)) != 8 ) {
		gr_TextMsgOut("Can't use X Image Palette on this display.\n");
		gr_TextMsgOut("Not an 8 bit display\n");
		return;
		}
		
	rgbcmyhsv = 0;
	comp_pen = 0;
	comp_last_x = comp_last_y = 0;
	crlastx = 0;

	top_pal_ctrl_widget = 
		gr_MakeWindow2("MXV Palette", 
			gr_topLevel,
			&boxwind, ClosePaletteBox, client_data,
			"MXV Palette", "Close", FALSE);
	pal_ctrl_widget = boxwind;

#if 0
	/* These arrays have already been setup. */
	/* Copy current colors used by calling window. */
	copy_colors(PalData->cs->cmapCells, rccells, 256, TRUE);
	copy_colors(rccells, origccells, 256, TRUE);
	copy_colors(PalData->cs->cmapCells, uccells, 256, TRUE);
#else
	/* Whenever this window is opened, the 'reset' colors are set to
	   the current (as of now) colors.
	*/
	copy_colors(INDEXtoCURRENT(index), INDEXtoORIGINAL(index), 256, TRUE);
#endif
	pal_image = gr_make_palette(pal_ctrl_widget, top_pal_ctrl_widget,
			FALSE, split, NULL, NULL, NULL);

	pal_comp = gr_MakeWorkSpace2(NULL, pal_ctrl_widget,
			CBRedrawComponents, NULL, NULL, (XtPointer) index,
			255,PALCOMPHEIGHT+2, pal_image, NULL);

	buttonbox1 = gr_MakeBox2(NULL, pal_ctrl_widget, pal_comp, NULL, FALSE);

	b[PAL_LOAD] = gr_MakeButton3(NULL, buttonbox1, "Load", NONE,
		CBNewLoadPal, client_data, NULL, NULL);

/* Save button turned off 9/92 for split maps (dicer windows) since
while we can save the palette, when it is read in again it will be
resplit. So there is no point.
*/
	if(!split)
		b[PAL_SAVE] = gr_MakeButton3(NULL, buttonbox1, "Save", NONE,
			PalData->Save_Palette, PalData, NULL, NULL);

/*
		Done in gr_make_palette.
	b[PAL_RESET] = gr_MakeButton3(NULL, buttonbox1,"Reset", NONE,
		CBReset, index,  NULL, NULL);

	(void) gr_MakeButton3(NULL, buttonbox1, "Undo", NONE,
		CBUndo, index, NULL, NULL);
*/
	b[PAL_SMOOTH] = gr_MakeButton3(NULL, buttonbox1, "Smooth", NONE,
				CBSmooth,&comp_pen, NULL, NULL);

	str = gr_ColorProtectionToStr(colorprotection_status , TRUE);
	gr_MakeButton3(NULL, buttonbox1, str, NONE,
		toggle_colorProtections, (XtPointer)index, NULL, NULL);

	buttonbox2 = gr_MakeBox2(NULL, pal_ctrl_widget,
				buttonbox1, NULL, TRUE);

	gr_MakeLabel2(NULL, buttonbox2, "Wholistic", NONE, 0, NULL, NULL);
	b[PAL_FIDDLE] = gr_MakeButton3(NULL, buttonbox2, "Fiddle   ", NONE,
			CBFiddle, (XtPointer)index, NULL, NULL);
	b[PAL_INVERT] = gr_MakeButton3(NULL, buttonbox2,"Flip     ", NONE,
			CBTranspose, (XtPointer)index, NULL, NULL);
/*b[PAL_T_ROTATE] =gr_MakeButton3(NULL, buttonbox2,"Track Rotate", NONE,
			CBRotate,NULL,NULL, NULL);
*/
/*	b[PAL_ROTATE] = gr_MakeButton3(NULL, buttonbox2, "Rotate", NONE,
			NULL,NULL,NULL, NULL);
*/

	gr_WidgetCursor(buttonbox2,XC_hand2);

	buttonbox3 = gr_MakeBoxForm(NULL, pal_ctrl_widget, &colorW, buttonbox1,
			buttonbox2, TRUE);

	tmpW = gr_MakeLabel2(NULL, colorW,
		"      Palette Component Manipulation     ",
		NONE, 0, NULL, NULL);

	rgbW = gr_MakeBox2(NULL, colorW, tmpW, NULL, TRUE);
		make_color_buttons(rgbW, &b[PAL_PRED], &b[PAL_RED], "Red  ",
			CBDrawComponentToggle, CBSetPenToggle, CRED);
		make_color_buttons(rgbW, &b[PAL_PGREEN], &b[PAL_GREEN],"Green",
			CBDrawComponentToggle, CBSetPenToggle, CGREEN);
		make_color_buttons(rgbW, &b[PAL_PBLUE], &b[PAL_BLUE], "Blue ",
			CBDrawComponentToggle, CBSetPenToggle, CBLUE);
		gr_MakeRadio(b[PAL_RED], b[PAL_RED],   FALSE);
		gr_MakeRadio(b[PAL_GREEN], b[PAL_RED], FALSE);
		gr_MakeRadio(b[PAL_BLUE], b[PAL_RED],  FALSE);

	cmyW = gr_MakeBox2(NULL, colorW, tmpW, rgbW, TRUE);
		make_color_buttons(cmyW, &b[PAL_PCYAN], &b[PAL_CYAN],
			"Cyan   ",
			CBDrawComponentToggle, CBSetPenToggle, CCYAN);
		make_color_buttons(cmyW, &b[PAL_PMAGENTA], &b[PAL_MAGENTA],
			"Magenta",
			CBDrawComponentToggle, CBSetPenToggle, CMAGENTA);
		make_color_buttons(cmyW, &b[PAL_PYELLOW], &b[PAL_YELLOW],
			"Yellow ",
			CBDrawComponentToggle, CBSetPenToggle, CYELLOW);
		gr_MakeRadio(b[PAL_CYAN], b[PAL_RED],	FALSE);
		gr_MakeRadio(b[PAL_MAGENTA], b[PAL_RED],FALSE);
		gr_MakeRadio(b[PAL_YELLOW], b[PAL_RED],	FALSE);

	hsvW = gr_MakeBox2(NULL, colorW, tmpW, cmyW, TRUE);
		make_color_buttons(hsvW, &b[PAL_PHUE], &b[PAL_HUE],
			"Hue       ",
			CBDrawComponentToggle, CBSetPenToggle, CHUE);
		make_color_buttons(hsvW,
			&b[PAL_PSATURATION], &b[PAL_SATURATION],"Saturation",
			CBDrawComponentToggle, CBSetPenToggle, CSATURATION);
		make_color_buttons(hsvW,
			&b[PAL_PVALUE], &b[PAL_VALUE], "Value     ",
			CBDrawComponentToggle, CBSetPenToggle, CVALUE);
		gr_MakeRadio(b[PAL_HUE], b[PAL_RED],		FALSE);
		gr_MakeRadio(b[PAL_SATURATION], b[PAL_RED],	FALSE);
		gr_MakeRadio(b[PAL_VALUE], b[PAL_RED],		FALSE);

	gr_WidgetCursor(buttonbox3,XC_hand2);

	xi_setColormap(top_pal_ctrl_widget, index);
	gr_ManageChild(top_pal_ctrl_widget);

	{
	static XGCValues gcvalues;
	gcvalues.foreground = black;
	gcvalues.background = white;
	pal_comp_gc = XtGetGC(pal_comp,(GCForeground|GCBackground),&gcvalues);
	}

	
	/* Component palette display window drawing */
	XtAddEventHandler(pal_comp,ButtonPressMask,0,
			CBPrepChangeComp, (XtPointer) index );
        XtAddEventHandler(pal_comp,Button1MotionMask,0,
			CBChangeComponent, (XtPointer) index );
	XtAddEventHandler(pal_comp,ButtonReleaseMask|LeaveWindowMask,0,
			CBEndChangeComp, (XtPointer) index );
	gr_WidgetCursor(pal_comp,XC_pencil);


#if 0
	in make_palette.
        XtAddEventHandler(pal_image,ButtonPressMask,0,CBInitRotate,NULL );
        XtAddEventHandler(pal_image,Button1MotionMask,0,CRotate,NULL );
        gr_WidgetCursor(pal_image,XC_sb_h_double_arrow);
#endif
	palette_ctrl_window_showing = TRUE;

	return;

} /* PaletteBox() */



static void CBRedrawComponents(w,client_data,call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
	RedrawComponent((A_Colormap_t)client_data);
}

#if 0
static void CBCompKey(w,client_data,call_data)
/* this routine is suppose to set which component to draw with 
 * but the HP workspace widget doesn't seem to be returning anything
 * meaningful when a key pressed.... either that or I don't know how
 * to use it. 
 */
Widget w;
caddr_t client_data;
caddr_t call_data;
{
/*	printf("Just pressed %d key(call_data)\n",(int) call_data);
	printf("Just pressed %c key(call_data)\n",(char *) call_data);
	printf("Just pressed %d key(client_data)\n",(int) client_data);
*/
	/* will use CBSetPen() */
	/* then set the toggle */
}
#endif

static void CBTranspose(w,client_data,call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
	TransposeCMap((A_Colormap_t) client_data);
	return;
}

void CBInitRotate(w,client_data,call_data)
Widget w;
XtPointer client_data;
XtPointer call_data;
{
A_Colormap_t	index = (A_Colormap_t) client_data;
Window root, child;
int	root_x,root_y;
int	win_x,win_y;
unsigned int	keys_buttons;

	SaveForUndo(index);
	if (XQueryPointer(XtDisplay(w),XtWindow(w),&root,&child,
		&root_x,&root_y,&win_x,&win_y,&keys_buttons)) {
/*		crlastx = win_x;*/
		crlastx = root_x;
		}
}

/* Load new palette by calling mxv routine then copying data from where
it was put.
*/
static void CBNewLoadPal(w,client_data,call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
A_Palette_t     *PalData = (A_Palette_t *) client_data;

	/* Make sure we have something to call. */
	if( (PalData == NULL) || (PalData->Load_Palette == NULL))
		return;
	/* Call appropriate MXV routine to read file. */
	(PalData->Load_Palette)(w, PalData->client_data, call_data);
	/* Now, copy data to rccells so we can fiddle, etc. */
	/* CAN'T copy, since window isn't even painted yet! */
}


void ConvertHSVtoRGB(h,s,v,pr,pg,pb)
double h; /* 0.0 to 360.0 */
double s; /* 0.0 to 1.0 */
double v; /* 0.0 to 1.0 */
unsigned short *pr,*pg,*pb; /* 0 to 65535 */
{
double r,g,b;
int i;
double f;
double p1,p2,p3;

	r = ((double) *pr) / (double) 65535.0;
	g = ((double) *pg) / (double) 65535.0;
	b = ((double) *pb) / (double) 65535.0;

	if (h == 360.0)
		h = 0.0;

	h = h / 60.0;

	i = (int) h;
	f = h - ((double) i);

	p1 = v * (1.0 - s);
	p2 = v * (1.0 - (s * f));
	p3 = v * (1.0 - (s * (1.0 - f)));

	switch (i) {
		case 0:
			r = v; g = p3; b = p1;
			break;
		case 1:
			r = p2; g = v; b = p1;
			break;
		case 2:
			r = p1; g = v; b = p3;
			break;
		case 3:
			r = p1; g = p2; b = v;
			break;
		case 4:
			r = p3; g = p1; b = v;
			break;
		case 5:
			r = v; g = p1; b = p2;
			break;
		}

	*pr = (unsigned short) (r * 65535.0);
	*pg = (unsigned short) (g * 65535.0);
	*pb = (unsigned short) (b * 65535.0);

} /* ConvertHSVtoRGB */

int ConvertRGBtoHSV(pr,pg,pb,h,s,v)
/* will return 0 if hue is undefined else return 1*/
unsigned short pr,pg,pb; /* 0 to 65535 */
double	*h; /* between 0.0 and 360.0 */
double	*s; /* between 0.0 and 1.0 */
double	*v; /* between 0.0 and 1.0 */
{
double	r,g,b;
double	range;
double	min;
double  rl,gl,bl;

	r = ((double)pr) / (double)65535.0;
	g = ((double)pg) / (double)65535.0;
	b = ((double)pb) / (double)65535.0;

	*v  = MAX3(r,g,b);
	min = MIN3(r,g,b);

	range = *v - min;

	if (*v)
		*s = range / *v;
	else
		*s = 0;

        if (*s) {
		rl = (*v - r) / range;
		gl = (*v - g) / range;
		bl = (*v - b) / range;

	        if ( *v == r ) {
			if ( min == g)
				*h = 5.0 + bl;
			else
				*h = 1.0 - gl;
	                }
		else {
			if ( *v == g) {
				if ( min == b)
					*h = 1.0 + rl;
				else
					*h = 3.0 - bl;
				}
			else {
				if (min == r)
					*h = 3.0 + gl;
				else
					*h = 5.0 - rl;
				}
			}
		*h = *h * 60.0;
		} /* if (*s)
	else
		return(0); /* h is undefined */

	return(1);
	
} /* ConvertRGBtoHSV() */



static void DrawComponent(component, index)
/* Draw the color components in the component window */
int	component;	/* which component to draw */
A_Colormap_t	index;	/* Index of color info struct.	*/
{
int x;
int y;
XGCValues	gcval;
XColor		*rccells= INDEXtoCURRENT(index);

	if( (pal_comp==NULL) || ! XtIsRealized(pal_comp))
		return;
        gcval.foreground = ChooseColor(rccells,component);
        XChangeGC(XtDisplay(pal_comp), pal_comp_gc, GCForeground, &gcval);
	switch (component){
		case CRED :
			for (x = 0 ; x < 256 ; x++ ) {
				y = (int) ((float) ((int)rccells[x].red >> 8)* 
						(float) (100.0 / 255.0));
				rpoints[x].x = x;
				rpoints[x].y = 100 - y;
				}
			XDrawPoints(XtDisplay(pal_comp),XtWindow(pal_comp),
				pal_comp_gc,rpoints,256,CoordModeOrigin);
			break;
		case CGREEN:
			for (x = 0 ; x < 256 ; x++ ) {
				y = (int) ((float) ((int)rccells[x].green >> 8)* 
						(float) (100.0 / 255.0));
				gpoints[x].x = x;
				gpoints[x].y = 100 - y;
				}
			XDrawPoints(XtDisplay(pal_comp),XtWindow(pal_comp),
				pal_comp_gc,gpoints,256,CoordModeOrigin);
			break;
		case CBLUE:
			for (x = 0 ; x < 256 ; x++ ) {
				y = (int) ((float) ((int)rccells[x].blue >> 8)* 
						(float) (100.0 / 255.0));
				bpoints[x].x = x;
				bpoints[x].y = 100 -y;
				}
			XDrawPoints(XtDisplay(pal_comp),XtWindow(pal_comp),
				pal_comp_gc,bpoints,256,CoordModeOrigin);
			break;
		case CCYAN:
			for (x = 0 ; x < 256 ; x++ ) {
				y = (int) ((float) ((int)rccells[x].red >> 8)* 
						(float) (100.0 / 255.0));
				cpoints[x].x = x;
				cpoints[x].y = y;
				}
			XDrawPoints(XtDisplay(pal_comp),XtWindow(pal_comp),
				pal_comp_gc,cpoints,256,CoordModeOrigin);
			break;
		case CMAGENTA:
			for (x = 0 ; x < 256 ; x++ ) {
				y = (int) ((float) ((int)rccells[x].green >> 8)* 
						(float) (100.0 / 255.0));
				mpoints[x].x = x;
				mpoints[x].y = y;
				}
			XDrawPoints(XtDisplay(pal_comp),XtWindow(pal_comp),
				pal_comp_gc,mpoints,256,CoordModeOrigin);
			break;
		case CYELLOW:
			for (x = 0 ; x < 256 ; x++ ) {
				y = (int) ((float) ((int)rccells[x].blue >> 8)* 
						(float) (100.0 / 255.0));
				ypoints[x].x = x;
				ypoints[x].y = y;
				}
			XDrawPoints(XtDisplay(pal_comp),XtWindow(pal_comp),
				pal_comp_gc,ypoints,256,CoordModeOrigin);
			break;
		case CHUE: {
			double h,s,v;
			for (x= 0; x < 256; x++ ) {
				if (!ConvertRGBtoHSV((int)rccells[x].red,
					rccells[x].green,rccells[x].blue,
					&h,&s,&v)) {
					h = 0; /* undefined */
					}
		
				y = (int) ((double)(h * (100.0 / 360.0)));
				hpoints[x].x = x;
				hpoints[x].y = 100 - y;
				} 
			XDrawPoints(XtDisplay(pal_comp),XtWindow(pal_comp),
				pal_comp_gc,hpoints,256,CoordModeOrigin);
			}
			break; /*CHUE*/
		case CSATURATION: {
			int r,g,b;
			int s;
			int max,min;

			for (x = 0 ; x < 256 ; x++ ) {
				r = (int) (((float) ((int)rccells[x].red >> 8))* 
						(float) (100.0 / 255.0));
				g = (int) (((float) ((int)rccells[x].green >> 8))* 
						(float) (100.0 / 255.0));
				b = (int) (((float) ((int)rccells[x].blue >> 8))* 
						(float) (100.0 / 255.0));

				max = MAX3(r,g,b);
				min = MIN3(r,g,b);

				if (max != 0)
		    		    s=(int)(100.0 *(((float) (max - min)) / 
						((float) max)));
				else
				     s = 0;
		
				spoints[x].x = x;
				spoints[x].y = 100 - s;
				}
			XDrawPoints(XtDisplay(pal_comp),XtWindow(pal_comp),
				pal_comp_gc,spoints,256,CoordModeOrigin);
			}
			break;
		case CVALUE: {
			int r,g,b;
			int value;
			for (x = 0 ; x < 256 ; x++ ) {
				r = (int) ((float) ((int)rccells[x].red >> 8)* 
						(float) (100.0 / 255.0));
				g = (int) ((float) ((int)rccells[x].green >> 8)* 
						(float) (100.0 / 255.0));
				b = (int) ((float) ((int)rccells[x].blue >> 8)* 
						(float) (100.0 / 255.0));

				value = (int) MAX3(r,g,b);

				vpoints[x].x = x;
				vpoints[x].y = 100 - value;
				}
			XDrawPoints(XtDisplay(pal_comp),XtWindow(pal_comp),
				pal_comp_gc,vpoints,256,CoordModeOrigin);
			}
			break;
		} /* switch */

			
	
	rgbcmyhsv = rgbcmyhsv | component;
	return;
	
} /* DrawComponent() */

/* Erase a color compent in the workspace. */
static void UnDrawComponent(component, index)
int component;
A_Colormap_t index;
{
XGCValues	gcval;
gcval.foreground = white;

	if( (pal_comp==NULL) || ! XtIsRealized(pal_comp))
		return;
	XChangeGC(XtDisplay(pal_comp), pal_comp_gc, GCForeground, &gcval);
	switch (component) {
		case CRED:
			XDrawPoints(XtDisplay(pal_comp),XtWindow(pal_comp),
				pal_comp_gc,rpoints,256,CoordModeOrigin);
			break;
		case CGREEN:
			XDrawPoints(XtDisplay(pal_comp),XtWindow(pal_comp),
				pal_comp_gc,gpoints,256,CoordModeOrigin);
			break;
		case CBLUE:
			XDrawPoints(XtDisplay(pal_comp),XtWindow(pal_comp),
				pal_comp_gc,bpoints,256,CoordModeOrigin);
			break;
		case CCYAN:
			XDrawPoints(XtDisplay(pal_comp),XtWindow(pal_comp),
				pal_comp_gc,cpoints,256,CoordModeOrigin);
			break;
		case CMAGENTA:
			XDrawPoints(XtDisplay(pal_comp),XtWindow(pal_comp),
				pal_comp_gc,mpoints,256,CoordModeOrigin);
			break;
		case CYELLOW:
			XDrawPoints(XtDisplay(pal_comp),XtWindow(pal_comp),
				pal_comp_gc,ypoints,256,CoordModeOrigin);
			break;
		case CHUE:
			XDrawPoints(XtDisplay(pal_comp),XtWindow(pal_comp),
				pal_comp_gc,hpoints,256,CoordModeOrigin);
			break;
		case CSATURATION:
			XDrawPoints(XtDisplay(pal_comp),XtWindow(pal_comp),
				pal_comp_gc,spoints,256,CoordModeOrigin);
			break;
		case CVALUE:
			XDrawPoints(XtDisplay(pal_comp),XtWindow(pal_comp),
				pal_comp_gc,vpoints,256,CoordModeOrigin);
			break;
	} /* switch */

	rgbcmyhsv = rgbcmyhsv ^ (rgbcmyhsv & component) ;
	if (! palRedraw)
		RedrawComponent(index);

} /* UnDrawComponent() */

/* Called be CBDrawComponentToggle and CBPenToggle?.
When turning OFF a component, make sure the 'pen' button is turned OFF.
When turning ON  a pen, make sure the 'component' button is turned ON.

If on, make sure component is drawn otherwise make sure pen is off.
*/
static void component_pen(component, on, index)
int		component;
Boolean		on;
A_Colormap_t	index;
{
Widget	penW, componentW;

	switch (component) {
		case CRED:
			componentW = b[PAL_PRED];
			penW = b[PAL_RED];
			break;
		case CGREEN:
			componentW = b[PAL_PGREEN];
			penW = b[PAL_GREEN];
			break;
		case CBLUE:
			componentW = b[PAL_PBLUE];
			penW = b[PAL_BLUE];
			break;
		case CCYAN:
			componentW = b[PAL_PCYAN];
			penW = b[PAL_CYAN];
			break;
		case CMAGENTA:
			componentW = b[PAL_PMAGENTA];
			penW = b[PAL_MAGENTA];
			break;
		case CYELLOW:
			componentW = b[PAL_PYELLOW];
			penW = b[PAL_YELLOW];
			break;
		case CHUE:
			componentW = b[PAL_PHUE];
			penW = b[PAL_HUE];
			break;
		case CSATURATION:
			componentW = b[PAL_PSATURATION];
			penW = b[PAL_SATURATION];
			break;
		case CVALUE:
			componentW = b[PAL_PVALUE];
			penW = b[PAL_VALUE];
			break;
	default:
		printf("Unknown component %d\n", component);
		return;
	} /* switch */

	if(on)
	{	if(!gr_is_toggle_set(componentW))
			/* Turn on component display button. */
			gr_set_button_state(componentW, TRUE);
			/* Draw component since setting button does not
			   trigger event.
			*/
			DrawComponent(component, index);
	}
	else
		if(gr_is_toggle_set(penW))	/* Turn off edit button. */
		{	gr_set_button_state(penW, FALSE);
			comp_pen = 0;
		}
} 

/* Display or undisplay a component.
The client_data for this needs to be changed to include the index.
*/
static void CBDrawComponentToggle(w,client_data,call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
int	component = (int) client_data;
A_Colormap_t	index = currentColorindex;

	if(gr_is_toggle_set(w))
		DrawComponent(component, index);
	else
	{	component_pen(component, FALSE, index);
		UnDrawComponent(component, index);
	}
}


void CBReset(w,client_data,call_data)
/* Set colormap back to last loaded colors */
Widget w;
caddr_t client_data;
caddr_t call_data;
{
int x;
A_Colormap_t	index = (A_Colormap_t) client_data;
XColor	*rccells = INDEXtoCURRENT(index), *origccells = INDEXtoORIGINAL(index);

	SaveForUndo(index);
	for(x=0; x < 256 ; x++) {
		rccells[x].pixel = x;
		cpccell(rccells[x],origccells[x]);
		}
	RedrawComponent(index);
	StoreColors(rccells,TRUE, index);
} /* CBReset() */

/*
static void CBEvalExpr(w,client_data,call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
	* Not working yet, but we'll blame it on the user for
	   not knowing how to use this feature *

	gr_TextMsgOut("Bad expression in cut/paste buffer\n");
}
*/


/* Flip the colormap:  (0<-> 255, 1<->254, etc.)*/
static void TransposeCMap(index)
A_Colormap_t	index;
{
int	x;
XColor	tmp, *rccells = INDEXtoCURRENT(index);

	SaveForUndo(index);
	for (x=0; x < 128 ;x++) {
		cpccell(tmp,rccells[255-x]);
		cpccell(rccells[255-x],rccells[x]);
		cpccell(rccells[x],tmp);
		}
	StoreColors(rccells,TRUE, index);

	return;

} /* TransposeCMap() */


static void FiddlePalette(w,xdim,ydim,xpos,ypos, index)
Widget		w;
int		xdim,ydim;
int		xpos,ypos;
A_Colormap_t	index;
{
double a,b;
double unit_Theta = (double) 3.14159 / (double) (ydim*2);
double up,down;
register int prej,i,j,k;
int	NUMCOLORS = 256;
XColor	*rccells = INDEXtoCURRENT(index);

	xpos = (((xpos < 0)?0:xpos)>xdim)?xdim:xpos;
	ypos = (((ypos < 0)?0:ypos)>ydim)?ydim:ypos;

	a = (double) tan((double) (unit_Theta * (double) (ydim - ypos)));

	up = 1 + (short) (127.0 * a);
	down = 256 - (short) (128.0 * a);
	if (up > down)
		b = (((double)xpos / (double)xdim) * (double)(up - down))
				 + (double) down;
	else
		b = (((double)xpos / (double)xdim) * (double)(down - up))
			 + (double) up;
	
	prej = 1;

	for ( i = 1 ; i <= NUMCOLORS - 2 ; i++) {
	    j = (short) (a * (double) (i - (NUMCOLORS/2)) + b);
	    if ((j > 0) && (j <= NUMCOLORS-2)) {
		for ( k = prej; k <= j - 1 ; k++)
		   /*if((rccells[k].pixel!=white)&&(rccells[k].pixel!=black))*/
				cpccell(rccells[k],bccells[i]);
		/*if ((rccells[j].pixel!=white)&&(rccells[j].pixel!=black))*/
			cpccell(rccells[j],bccells[i]);
		}
	    else
		if (j >= NUMCOLORS-1) {
			for ( k = prej; k <= NUMCOLORS-2; k++)
				/*if ((rccells[k].pixel!=white)
				    &&(rccells[k].pixel!=black))*/
					cpccell(rccells[k],bccells[i]);
			break;
			}
		else
			continue;

	    prej = j + 1;
 	    }

	for(;j < NUMCOLORS;j++) 
		/*ccells[j].pixel = bccells[255].pixel;*/
		cpccell(rccells[j],bccells[255]);

	StoreColors(rccells,TRUE, index);
}

static void Cfiddle(w,client_data,call_data)
/* Do linear expansion and compression on palette */
Widget w;
caddr_t client_data;
caddr_t call_data;
{
Window root, child;
int	root_x,root_y;
int	win_x,win_y;
unsigned int	keys_buttons;
A_Colormap_t	index = (A_Colormap_t) client_data;

	if (XQueryPointer(XtDisplay(w),XtWindow(w),&root,&child,
	    &root_x,&root_y,&win_x,&win_y,&keys_buttons)) {
		FiddlePalette(w,pcw_attrib.width,pcw_attrib.height,
			win_x,win_y, index);
		}

} /* Cfiddle() */


static void CBPrepFiddle(w,client_data,call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
int	x;
A_Colormap_t	index = (A_Colormap_t) client_data;

	SaveForUndo(index);
#if 1
	/* Save current colors to backup. */
	copy_colors((char *)INDEXtoCURRENT(index), (char *)bccells,
								256, TRUE);
#else
	for (x=0; x< 256 ; x++) {
		cpccell(bccells[x],rccells[x]);
		bccells[x].pixel = rccells[x].pixel;
		}
#endif
}

static void CBEndFiddle(w,client_data,call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
Window root, child;
int     root_x,root_y;	/* X & Y coordinates with respect to root */
int     win_x,win_y;	/* X & Y coordinates with respect to window */
unsigned int    keys_buttons;
int	win;

	win = XtWindow(w);

        if (XQueryPointer(XtDisplay(w),win,&root,&child,
                &root_x,&root_y,&win_x,&win_y,&keys_buttons)) {
		XWarpPointer(XtDisplay(w),win,win,win_x,win_y,
		pcw_attrib.width,pcw_attrib.height,30,200);
		}
	XUngrabPointer(XtDisplay(w),CurrentTime);
        XtRemoveEventHandler(pal_ctrl_widget,Button1MotionMask,0,
		(XtEventHandler)Cfiddle,NULL);
	XtRemoveEventHandler(pal_ctrl_widget,ButtonReleaseMask,0,
		(XtEventHandler)CBEndFiddle,NULL);
} /* CBEndFiddle() */


/* client_data = index. */
static void CBFiddle(w,client_data,call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
	if(XGrabPointer(XtDisplay(w),XtWindow(pal_ctrl_widget),False,
		PointerMotionMask|ButtonReleaseMask,
		GrabModeAsync,GrabModeSync,
		(restrictFiddleCursor) ? XtWindow(pal_ctrl_widget): None,
		XCreateFontCursor(XtDisplay(w),XC_fleur),
		CurrentTime)) {
			gr_TextMsgOut("Can't grab pointer for fiddle\n");
			return;
			}

        XtAddEventHandler(pal_ctrl_widget,Button1MotionMask,0,
		(XtEventHandler)Cfiddle, client_data );
	XtAddEventHandler(pal_ctrl_widget,ButtonReleaseMask,0,
		(XtEventHandler)CBEndFiddle,NULL);

	CBPrepFiddle(pal_ctrl_widget,client_data, NULL);


	XGetWindowAttributes(XtDisplay(w),XtWindow(pal_ctrl_widget),
			&pcw_attrib);
} /* CBFiddle() */

static RotatePalette(w,xdim,ydim,xpos,ypos, index)
Widget w;
int xdim,ydim;
int xpos,ypos;
A_Colormap_t	index;
{
int offset;
int x;
int new;
XColor	*rccells = INDEXtoCURRENT(index);

	if ((crlastx)&& (crlastx != xpos)) {
		for(x = 0;x < 256; x++)
			cpccell(bccells[x],rccells[x]);

		offset = xpos - crlastx;

		for(x=0; x < 256; x++) {
			new = x + offset;
			new = (new > 255) ? (new - 256) : 
					(new < 0) ? (new + 256): new;
			cpccell(rccells[new],bccells[x]);
			}

		StoreColors(rccells,TRUE, index);
		}
	crlastx = xpos;
	return;

} /* RotatePalette() */


void CRotate(w,client_data,call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
Window root, child;
int     root_x,root_y;	/* X & Y coordinates with respect to root */
int     win_x,win_y;	/* X & Y coordinates with respect to window */
unsigned int    keys_buttons;
A_Colormap_t	index = (A_Colormap_t) client_data;

        if (XQueryPointer(XtDisplay(w),XtWindow(w),&root,&child,
                &root_x,&root_y,&win_x,&win_y,&keys_buttons)) {

		if ((win_x <= 255) && (win_x > 0))
	                RotatePalette(w,255,28,root_x, root_y, index);
/*	                RotatePalette(w,255,28,win_x,win_y, index);*/
                }
}

static void RedrawComponent(index)
A_Colormap_t	index;
{
	palRedraw = TRUE;
	if (rgbcmyhsv & CRED ){
		UnDrawComponent(CRED, index);
		DrawComponent(CRED, index);
		}
	if (rgbcmyhsv & CGREEN) {
		UnDrawComponent(CGREEN, index);
		DrawComponent(CGREEN, index);
		}
	if (rgbcmyhsv & CBLUE) {
		UnDrawComponent(CBLUE, index);
		DrawComponent(CBLUE, index);
		}
	if (rgbcmyhsv & CCYAN) {
		UnDrawComponent(CCYAN, index);
		DrawComponent(CCYAN, index);
		}
	if (rgbcmyhsv & CMAGENTA) {
		UnDrawComponent(CMAGENTA, index);
		DrawComponent(CMAGENTA, index);
		}
	if (rgbcmyhsv & CYELLOW) {
		UnDrawComponent(CYELLOW, index);
		DrawComponent(CYELLOW, index);
		}
	if (rgbcmyhsv & CHUE) {
		UnDrawComponent(CHUE, index);
		DrawComponent(CHUE, index);
		}
	if (rgbcmyhsv & CSATURATION) {
		UnDrawComponent(CSATURATION, index);
		DrawComponent(CSATURATION, index);
		}
	if (rgbcmyhsv & CVALUE) {
		UnDrawComponent(CVALUE, index);
		DrawComponent(CVALUE, index);
		}
	palRedraw = FALSE;
	return;
} /* RedrawComponent() */


static void CBSetPenToggle(w,client_data,call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
A_Colormap_t	index = currentColorindex;

	if( gr_is_toggle_set(w))
	{	comp_pen = (unsigned short) client_data;
		component_pen(comp_pen, TRUE, index);
	}
	else
		comp_pen = 0;
}

static void SetPenColor(dpy,wingc,color)
/*
 * Set pen color for drawing.
 * Using an 8-bit palette, 0 <= color <= 255
 */
Display		*dpy;
GC		wingc;
unsigned short color;
{
XGCValues	gcval;
        gcval.foreground = color;
        XChangeGC(dpy,wingc, GCForeground, &gcval);
}

		
PlotComp(w,x,y,comp, index)
Widget w;
int x,y;
int comp;
A_Colormap_t	index;
{
Display	*dpy; 
Window	win;
XColor	*rccells = INDEXtoCURRENT(index);

	dpy = XtDisplay(w);
	win = XtWindow(w);

	switch(comp) {
		case CRED:	
			rccells[x].red = (int) ((((float) y)/
					((float) PALCOMPHEIGHT)) * 65535.0);
			SetPenColor(dpy,pal_comp_gc,white);
			XDrawPoint(dpy,win,pal_comp_gc,
					x,rpoints[x].y);
			rpoints[x].y = PALCOMPHEIGHT - y;
			SetPenColor(dpy,pal_comp_gc,comp_pen_dcolor);
			XDrawPoint(dpy,win,pal_comp_gc,
					x,rpoints[x].y);
			break;
		case CGREEN:	
			rccells[x].green= (int) ((((float)y)/
					((float) PALCOMPHEIGHT)) * 65535.0);
			SetPenColor(dpy,pal_comp_gc,white);
			XDrawPoint(dpy,win,pal_comp_gc,
					x,gpoints[x].y);
			gpoints[x].y = PALCOMPHEIGHT - y;
			SetPenColor(dpy,pal_comp_gc,comp_pen_dcolor);
			XDrawPoint(dpy,win,pal_comp_gc,
					x,gpoints[x].y);
			break;
		case CBLUE:	
			rccells[x].blue= (int) ((((float) y)/
					((float) PALCOMPHEIGHT)) * 65535.0);
			SetPenColor(dpy,pal_comp_gc,white);
			XDrawPoint(dpy,win,pal_comp_gc,
					x,bpoints[x].y);
			bpoints[x].y = PALCOMPHEIGHT - y;
			SetPenColor(dpy,pal_comp_gc,comp_pen_dcolor);
			XDrawPoint(dpy,win,pal_comp_gc,
					x,bpoints[x].y);
			break;
		case CCYAN:	
			rccells[x].red = (int) (65535.0 - ((((float) y)/
						((float) PALCOMPHEIGHT))
						 * 65535.0));
			SetPenColor(dpy,pal_comp_gc,white);
			XDrawPoint(dpy,win,pal_comp_gc,
					x,cpoints[x].y);
			cpoints[x].y = PALCOMPHEIGHT - y;
			SetPenColor(dpy,pal_comp_gc,comp_pen_dcolor);
			XDrawPoint(dpy,win,pal_comp_gc,
					x,cpoints[x].y);
			break;
		case CMAGENTA:	
			rccells[x].green= (int) (65535.0 - ((((float) y)/
						((float) PALCOMPHEIGHT))
						 * 65535.0));
			SetPenColor(dpy,pal_comp_gc,white);
			XDrawPoint(dpy,win,pal_comp_gc,
					x,mpoints[x].y);
			mpoints[x].y = PALCOMPHEIGHT - y;
			SetPenColor(dpy,pal_comp_gc,comp_pen_dcolor);
			XDrawPoint(dpy,win,pal_comp_gc,
					x,mpoints[x].y);
			break;
		case CYELLOW:	
			rccells[x].blue = (int) (65535.0 - ((((float) y)/
						((float) PALCOMPHEIGHT))
						 * 65535.0));
			SetPenColor(dpy,pal_comp_gc,white);
			XDrawPoint(dpy,win,pal_comp_gc,
					x,ypoints[x].y);
			ypoints[x].y = PALCOMPHEIGHT - y;
			SetPenColor(dpy,pal_comp_gc,comp_pen_dcolor);
			XDrawPoint(dpy,win,pal_comp_gc,
					x,ypoints[x].y);
			break;
		case CHUE:{

			double h,s,v;
			if (!ConvertRGBtoHSV(rccells[x].red,rccells[x].green,
					rccells[x].blue,&h,&s,&v)) {
				h = 0;
				}
			h = ((double)360.0)
				*((double) y) / ((double) PALCOMPHEIGHT);
			ConvertHSVtoRGB(h,s,v,&(rccells[x].red),
				&(rccells[x].green),&(rccells[x].blue));

			SetPenColor(dpy,pal_comp_gc,white);
			XDrawPoint(dpy,win,pal_comp_gc,
					x,hpoints[x].y);
			hpoints[x].y = PALCOMPHEIGHT - y;
			SetPenColor(dpy,pal_comp_gc,comp_pen_dcolor);
			XDrawPoint(dpy,win,pal_comp_gc,
					x,hpoints[x].y);
			
			}
			break;
		case CSATURATION:
			{
			double h,s,v;

			if (!ConvertRGBtoHSV(rccells[x].red,rccells[x].green,
					rccells[x].blue,&h,&s,&v)) {
				h = 0;
				}

			s = ((double)y) / ((double) PALCOMPHEIGHT);

			ConvertHSVtoRGB(h,s,v,&(rccells[x].red),
				&(rccells[x].green),&(rccells[x].blue));

			SetPenColor(dpy,pal_comp_gc,white);
			XDrawPoint(dpy,win,pal_comp_gc,
					x,spoints[x].y);
			spoints[x].y = PALCOMPHEIGHT - y;
			SetPenColor(dpy,pal_comp_gc,comp_pen_dcolor);
			XDrawPoint(dpy,win,pal_comp_gc,
					x,spoints[x].y);
			
			}
			break;
		case CVALUE: {
			int max;
			double ratio;
			double yval;

			yval = ((double) y) * 
					(65535.0 / ((double)PALCOMPHEIGHT));
			max = MAX3(rccells[x].red,rccells[x].green,
				rccells[x].blue);
			if (max != 0) {
				ratio =((double) rccells[x].red)/(double) max;
				rccells[x].red = (int) (ratio *  yval);
				ratio =((double) rccells[x].green)/(double)max;
				rccells[x].green = (int) (ratio *  yval);
				ratio =((double) rccells[x].blue)/(double) max;
				rccells[x].blue = (int) (ratio *  yval);
				}
			else {
				rccells[x].red = rccells[x].blue = 
					rccells[x].green = yval;
				}
			SetPenColor(dpy,pal_comp_gc,white);
			XDrawPoint(dpy,win,pal_comp_gc,
					x,vpoints[x].y);
			vpoints[x].y = PALCOMPHEIGHT - y;
			SetPenColor(dpy,pal_comp_gc,comp_pen_dcolor);
			XDrawPoint(dpy,win,pal_comp_gc,
					x,vpoints[x].y);
			}
			break;

		default:
			break;
		}
		
	return;
} /* PlotComp() */



static void CBChangeComponent(w,client_data,call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
Window root, child;
int     root_x,root_y;
int     win_x,win_y;
unsigned int    keys_buttons;
int	x;
float	y;
float	yinc,ydiff;
Display	*dpy; 
Window	win;
A_Colormap_t	index = (A_Colormap_t) client_data;

	if (!comp_pen)		/* No component selected */
		return;

	dpy = XtDisplay(w);
	win = XtWindow(w);
        if (!XQueryPointer(dpy,win,&root,&child,
                &root_x,&root_y,&win_x,&win_y,&keys_buttons)) 
		return;

	win_x = (win_x > 255)? 255 : (win_x <0)? 0 : win_x;
	win_y = (win_y > PALCOMPHEIGHT)? PALCOMPHEIGHT: 
					(win_y < 0)? 0 : win_y;

	win_y = PALCOMPHEIGHT - win_y; /* 4th quadrant -> 1st quadrant */

	if (comp_last_x == 0)
		PlotComp(pal_comp,win_x,win_y,comp_pen, index);
	else {
		ydiff = (comp_last_x > win_x)?(comp_last_y - win_y):
				(win_y - comp_last_y);

		if (comp_last_x > win_x) {
			yinc = (float) ydiff /((comp_last_x == win_x)?1.0:
					((float)(comp_last_x - win_x)));
			for (x = win_x,y=win_y; x < comp_last_x; x++,y=y+yinc)
				PlotComp(pal_comp,x,(int) y,comp_pen, index);
			}
		else{
			yinc = (float) ydiff / ((comp_last_x == win_x)?1.0:
					((float)( win_x - comp_last_x)));
			for (x = comp_last_x, y=comp_last_y; x < win_x; x++,y=y+yinc)
				PlotComp(pal_comp,x,(int) y,comp_pen, index);
			}
		}
	comp_last_x = win_x;
	comp_last_y = win_y;
	StoreColors(INDEXtoCURRENT(index),FALSE, index);
} /* CBChangeComponent() */
			

static void CBPrepChangeComp(w,client_data,call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
A_Colormap_t	index = (A_Colormap_t) client_data;

	if(comp_pen == 0)
	{	printf("No pen selected!\n");
		return;
	}
	comp_last_x = 0;
	comp_last_y = 0;
	comp_pen_dcolor = ChooseColor(INDEXtoCURRENT(index),comp_pen);
	SaveForUndo(index);
	CBChangeComponent(w,client_data,call_data);
}

static void CBEndChangeComp(w,client_data,call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
	if (comp_last_x || comp_last_y)
		RedrawComponent((A_Colormap_t) client_data);
	comp_last_x = 0;
	comp_last_y = 0;
}

/* pick the best entry in the palette to match color */
static int ChooseColor(test,whichone)
XColor	test[];		/* the palette */
int	whichone;	/* which color to find in palette */
{
int best;
int best_cmpval;
int cmpval;
int x;
int r,b,g;
XColor	ccells[256];

	/* Look at the palette as it will be on server. */
	MergeColors(test, ccells);
	best = black;
	best_cmpval = -1 - (1 >> 18);
	switch (whichone) {
	case CRED:	/* find purest red */
		for(x=0; x < 256 ; x++) {
			g = ccells[x].green;
			b = ccells[x].blue;
			cmpval = ccells[x].red - g - b - abs(g-b);
			if (cmpval > best_cmpval) {
				best_cmpval = cmpval;
				best = x;
				}
			}
		break;
	case CGREEN:	/* find purest green */
		for(x=0; x < 256 ; x++) {
			r = ccells[x].red;
			b = ccells[x].blue;
			cmpval = ccells[x].green - r - b - abs(r-b);
			if (cmpval > best_cmpval) {
				best_cmpval = cmpval;
				best = x;
				}
			}
		break;
	case CBLUE:	/* find purest blue */
		for(x=0; x < 256 ; x++) {
			r = ccells[x].red;
			g = ccells[x].green;
			cmpval = ccells[x].blue - r - g - abs(r-g);
			if (cmpval > best_cmpval) {
				best_cmpval = cmpval;
				best = x;
				}
			}
		break;
	case CCYAN:	/* find purest cyan */
		for(x=0; x < 256 ; x++) {
			cmpval = ccells[x].green + ccells[x].blue
						- ccells[x].red;
			if (cmpval > best_cmpval) {
				best_cmpval = cmpval;
				best = x;
				}
			}
		break;
	case CMAGENTA:	/* find purest magenta */
		for(x=0; x < 256 ; x++) {
			cmpval = ccells[x].red + ccells[x].blue
						- ccells[x].green;
			if (cmpval > best_cmpval) {
				best_cmpval = cmpval;
				best = x;
				}
			}
		break;
	case CYELLOW:	/* find purest yellow */
		for(x=0; x < 256 ; x++) {
			cmpval = ccells[x].red + ccells[x].green
						- ccells[x].blue;
			if (cmpval > best_cmpval) {
				best_cmpval = cmpval;
				best = x;
				}
			}
		break;
	case CHUE:	/* find purest orange */
		for(x=0; x < 256 ; x++) {
			r = ccells[x].red;
			b = ccells[x].blue;
			cmpval = r-b - abs(((r+b)>>1) - ccells[x].green);
			if (cmpval > best_cmpval) {
				best_cmpval = cmpval;
				best = x;
				}
			}
		break;
	case CSATURATION:	/* find purest purplish color?? */
		for(x=0; x < 256 ; x++) {
			r = ccells[x].red;
			g = ccells[x].green;
			b = ccells[x].blue;	/* hr 3/19/92 */
			cmpval = b-g - abs(((b+g)>>1) - ccells[x].red);
			if (cmpval > best_cmpval) {
				best_cmpval = cmpval;
				best = x;
				}
			}
		break;
	
	case CVALUE:	
	default:
		/* find purest black */
		for(x=0; x < 256 ; x++) {
			b = ccells[x].blue;	/* hr 3/19/92 */
			r = ccells[x].red;	/* hr 3/19/92 */
			cmpval = b-r - abs(((b+r)>>1) - ccells[x].green);
			/*cmpval = 65535 - ((ccells[x].red + ccells[x].green
					+ccells[x].blue)/3);
			*/
			if (cmpval > best_cmpval) {
				best_cmpval = cmpval;
				best = x;
				}
			}
		break;
	} /* switch */

	return(best);
}

void CBPalSave(w,client_data,call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
A_Palette_t     *PalData = (A_Palette_t *) client_data;

	gr_SavePal(w, PalData->client_data, call_data);

}


void CBUndo(w,client_data,call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
int	x;
A_Colormap_t	index = (A_Colormap_t) client_data;
XColor	real_undo[256], *rccells = INDEXtoCURRENT(index);
XColor	*uccells=INDEXtoUNDO(index);

	for(x=0;x < 256; x++) {
		rccells[x].pixel = x;
		cpccell(real_undo[x],uccells[x]);
		}

	SaveForUndo(index);

	for(x=0;x < 256; x++) {
		rccells[x].pixel = x;
		cpccell(rccells[x],real_undo[x]);
		}
	StoreColors(rccells,TRUE, index);
}

static void SaveForUndo(index)
A_Colormap_t	index;
{
int	x;
XColor	*rccells = INDEXtoCURRENT(index), *uccells=INDEXtoUNDO(index);

	for(x=0;x < 256; x++) {
		uccells[x].pixel = x;
		cpccell(uccells[x], rccells[x]);
		}
}

static void CBSmooth(w,client_data,call_data)
Widget w;
caddr_t client_data;	/* contains a pointer to the component*/
caddr_t call_data;
{
int x;
int	comp_pen;	/* Drawing color; smooth this one */
A_Colormap_t index = currentColorindex;
XColor	*rccells = INDEXtoCURRENT(index);

	SaveForUndo(index);

	comp_pen = *( (int *) client_data);
	if (!comp_pen) {
		gr_TextMsgOut(
			"Please select a component to manipulate first\n");
		return;
		}

	switch (comp_pen){
		case CRED:
		case CCYAN:
		    rccells[0].red = (int)(rccells[255].red +rccells[1].red)/2;
		    for(x=1; x< 255; x++)
			rccells[x].red = 
				(int)(rccells[x-1].red + rccells[x+1].red)/2;
		    rccells[255].red = (int)(rccells[254].red +rccells[0].red)/2;
		    break;
		case CGREEN:
		case CMAGENTA:
		    rccells[0].green = 
				(int)(rccells[255].green + rccells[1].green)/2;
		    for(x=1; x< 255; x++)
			rccells[x].green = 
				(int)(rccells[x-1].green + rccells[x+1].green)/2;
		    rccells[255].green = 
				(int)(rccells[254].green + rccells[0].green)/2;
		    break;
		case CBLUE:
		case CYELLOW:
		    rccells[0].blue = 
				(int)(rccells[255].blue + rccells[1].blue)/2;
		    for(x=1; x< 255; x++)
			rccells[x].blue = 
				(int)(rccells[x-1].blue + rccells[x+1].blue)/2;
		    rccells[255].blue = 
				(int)(rccells[254].blue + rccells[0].blue)/2;
		    break;
		case CHUE:
		case CSATURATION:
		case CVALUE:
			/* ick, I'll do this some other time */
		    break;
		} /*switch */
		
	StoreColors(rccells,TRUE, index);
} /* CBSmooth() */

/*
Assigns a changeable colormap to a widget and then loads it with new values.
This should be more or less obsolete. (But it isn't).
*/
void XIMAGE_setcmap(wid, colors, index)
Widget	wid;
XColor	colors[];
A_Colormap_t	index;
{
	xi_setColormap( wid, index);
	xi_storeColors(colors,FALSE, index);
/***??? */
/*	XtSetWMColormapWindows(wid, &wid, 1);*/

}

int WriteSEQPalette(name, index)
char    *name;
int	index;
{
FILE    *fp;
int     x;
char    buff[256];
XColor  *ccells;

	ccells = INDEXtoCURRENT(index);

        if (!(fp = fopen(name,"w"))) {
                sprintf(buff,"Can't open for writing file %s\n",name);
		gr_TextMsgOut(buff);
                return(-1);
                }

	/* Write the current color table. */
	if(ccells == NULL) ccells = INDEXtoCURRENT(index);

        for (x=0; x < 256; x++)
                putc(((char )(ccells[x].red >> 8)),fp);
        for (x=0; x < 256; x++)
                putc(((char )(ccells[x].green >> 8)),fp);
        for (x=0; x < 256; x++)
                putc(((char )(ccells[x].blue >> 8)),fp);

        fclose(fp);
	return 0; /* hr 3/19/92 */
}
