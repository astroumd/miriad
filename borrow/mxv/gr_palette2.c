/* gr_palette2.c
Routines to create a palette window.

TODO:
	gr_color/gr_color.split may someday not be global either.

	We need to destroy these widgets/data sometime!!!

NOTE:
	Routines calling gr_make_palette also need to call gr_ImageSetCMap
	with the upper level window as the argument. Trying to change the
	colormap of a child window doesn't seem to work.
*/
#include "gr_com.h"
extern void CBInitRotate(), CRotate(), CBReset(), CBUndo(), CBPalSave();
extern void PaletteBox(), gr_AddDestroy();
extern XFontStruct *gr_FindFont();
#ifndef __convex__
extern char *malloc();
#endif

static Boolean		inited=FALSE;
static unsigned char	*palData;		/* Palette data */
static	XImage	*palImage;			/* the palette display XImage*/

typedef struct {
	GC	gc, gc1;
	XFontStruct	*font;
	float	min;		/* Data min/max */
	float	max;
	int	width;		/* Width of palette bar.		*/
	int	x0,y0;		/* Where to start printing ticks.	*/
	int	cheight;	/* Height of characters in font.	*/
	int	buttonx, buttony;
	int	mx0, my0;	/* Where to draw moving label.		*/
	struct	btndata {
		int	mask;
		void	(*proc)();
		XtPointer	data;
		} btns[5];
	struct	pixelMapping	mapping;	/* Used when drawing labels.*/
	} label_struct, *Label_struct;


/* Height of palette display. The 30 is historical. */
#define	DEFROWS	30

#define	TICKLENGTH	10

#define	HSPACE	10	/* Amount of horizontal space over palette width. */
#define	VSPACE	40	/* Amount of vertical space over palette height.
			   Will be used for tick marks & labels.
			*/

/* Cleanup afterwards. */
static void destroy(w, data, call_data)
Widget	w;
XtPointer	data, call_data;
{
A_Palette_t *PalData = (A_Palette_t *) data;

	if(data != NULL)
		free(data);
}

/* Initialize data that gets reused everytime.
	w can be any widget that has been realized. (Its used for Display,
	etc).
*/
static Boolean init(w, rows, cols)
Widget		w;
unsigned int	rows, cols;	/* Size of palette display. */
{
unsigned int	x,y, i;

	if(inited)
		return TRUE;
	inited = 1;

	/* Allocate an array that's rows high be  cols wide.	*/ 
	if( (palData = (unsigned char *) malloc(rows*cols)) == NULL)
		return FALSE;

	/* Insert linear ramp. */
	for (i=0,y=0; y< rows; y++)
		for (x=0; x< cols; x++)
		{	palData[i] = (unsigned char)x;
			i++;
		}

	/* Create the XImage struct to hold data.
	   We might consider calling XCreateImage ourselves instead of using
	   gr_ImageCreate.
	*/
	if((palImage = gr_ImageCreate(w, cols, rows, palData))== NULL)
		return FALSE;

	return TRUE;
}

static void *error()
{
	gr_TextMsgOut("Could not generate palette bar window.");
	return NULL;
}


/* Convert a button press into a data value and display it. Initially,
this was going to move around under the palette, but that didn't work
out so well.
*/

static void moving_label(w, client_data, call_data)
Widget		w;
XtPointer	client_data, call_data;
{
Label_struct	ls = (Label_struct) client_data;
Display		*display = XtDisplay(w);
Window		window = XtWindow(w);
float		val;
char		label[20];

#if 0
	val = (float)(ls->buttonx-ls->x0)/(float)(ls->width-1);
	val = ls->min + val*(ls->max-ls->min);
	if((val < ls->min) || (val > ls->max))	/* Out of bounds.	*/
		sprintf(label,"%8s", " ");
	else
		sprintf(label,"%8.2f", val);
#else
	if( xi_unmapPixel(ls->buttonx-ls->x0, &val, &(ls->mapping),
		ls->min, ls->max))
		sprintf(label,"%8.4g", val);
	else
		sprintf(label, "No  data");	/* Same length as the 8.2g */
#endif
	Notate(display, window, ls->gc, ls->font, ls->mx0, ls->my0,
					label, CENTER_JUSTIFY, 0);
}

/* Draw tick marks & labels.
width	How wide palette is.
x0, y0	Where to start.

We draw this stuff at an expose event since the window doesn't even exist
when make_palette is called.
*/
static void draw_labels(w, client_data, call_data)
Widget		w;
XtPointer	client_data, call_data;
{
Label_struct	ls = (Label_struct) client_data;
int		width, x0, ystart, yend, x1, x, i, tickspace, npixels;
float	min, max;
Display		*display = XtDisplay(w);
Window		window = XtWindow(w);
GC		gc, gc1;
char		label[80];
unsigned char	*map;
XGCValues	gcvals;

	if( ! XtIsRealized(w))
	{	printf("OOps\n");
		return;
	}
	gc = ls->gc;
	gc1 = ls->gc1;
	map = ls->mapping.map;
	npixels = ls->mapping.npixels;
	ystart = ls->y0;
	yend = ystart+TICKLENGTH;
	width = npixels;
	/* Draw a 3 sided box around the bar. */
	x0 = ls->x0;
	x1 = ls->x0 + ls->width -1;
	XDrawLine(display,window, gc, x0-1, 0, x0-1, ystart);
	XDrawLine(display,window, gc, x1+1, 0, x1+1, ystart);
	XDrawLine(display,window, gc, x0-1, ystart, x1+1, ystart);
	/* Draw some tick marks. */
#define NUMTICKS 8
	tickspace = npixels/NUMTICKS;/* Assuming it evenly divides. */
/*printf("Ticks at: ");*/
	for(i=0, x = 0; i <= NUMTICKS; x += tickspace,i++)
	{	
		/* Force last tickmark to be at end. */
		if(i == NUMTICKS)
			x = npixels -1;
		x1 = x0 + map[x];
		/* Lengthen first and last tickmark. */
		if((i == 0) || (i== NUMTICKS))
			XDrawLine(display,window,gc, x1, ystart, x1, yend+5);
		else
			XDrawLine(display,window,gc, x1, ystart, x1, yend);
		/* Draw contrasting tick into palette bar. */
		XSetForeground(display, ls->gc1, width - i);
		XDrawLine(display,window,ls->gc1, x1, ystart, x1, ystart-10);

	}
/*
	XDrawLine(display,window,gc, x1, ystart, x1, yend);
*/
	if(ls->font == NULL)
	{	printf("Can't make labels.\n");
		return;
	}
	yend +=  ls->cheight+5;
	sprintf(label,"%.2g", ls->min);
	Notate(display, window, gc, ls->font, x0, yend,
					label, LEFT_JUSTIFY, 0);
	sprintf(label,"%.2g", ls->max);
	Notate(display, window, gc, ls->font, x0+map[npixels-1], yend,
					label, RIGHT_JUSTIFY, 0);
}

/* Decide which procedure to call depending on which button is pressed. */
static void dispatcher( w, client_data, call_data)
Widget	w;
XtPointer	client_data, call_data;
{
Window		root, child, win;
int		root_x, root_y, win_x, win_y;
unsigned int	buttons;
Label_struct	ls = (Label_struct) client_data;
int		i;

	win = XtWindow(w);
        if (XQueryPointer(XtDisplay(w),win,&root,&child,
                &root_x,&root_y,&win_x,&win_y,&buttons))

	ls->buttonx = win_x;
	ls->buttony = win_y;
	for(i =0; i < sizeof(ls->btns)/sizeof( *ls->btns); i++)
		if( (buttons & ls->btns[i].mask) && (ls->btns[i].proc != NULL))
			(ls->btns[i].proc)(w, ls->btns[i].data, call_data);
}


/*		ARGS needed.
Display palette button
Which palette - split or normal.
display min/max

*/
#if 0
extern void CBInitPal();
#endif
/* Create a palette window. Used several places to see what the current
palette looks like.

If only the palette button is drawn, that widget is returned. Otherwise
the return is a pointer to the box widget that surrounds everything.

Need arg to say whether to include palette bar.

Resources are used to determine whether to display palette bar,
labels for the bar.
If there is no data or no bar, no annotation will be displayed.

Probably should concatenate shellname with "Palette" for resource.
*/
Widget gr_make_palette(parent, shell, drawPaletteButton,
		split, data, topW, leftW)
Widget		parent;
Widget		shell;	/* Shell widget for parent. */
Boolean		drawPaletteButton, split;
A_Data_t	*data;
{
Widget	palW, boxW, panelW, btnW;
Label_struct	ls;
Widget	resetW, undoW;
A_Palette_t *PalData;
int		height, width, cols, rows, i;
Display		*display = XtDisplay(parent);
int		scr = DefaultScreen(display);
XGCValues	gcvals;
char	        *fontname = "6x10";
XFontStruct 	*font_info;
Dimension	cheight, cwidth;
Boolean		drawBar, drawLabels, needBox;
A_Colormap_t	index = (split) ? SPLITCMAP : NORMALCMAP;
char		*ctlstr;

	drawBar = gr_GetBooleanResource(shell,
			"showPaletteBar", "ShowPaletteBar", FALSE);
	drawLabels = gr_GetBooleanResource(shell,
			"annotatePalette", "AnnotatePalette", FALSE);

	drawLabels = drawLabels & drawBar & (data != NULL);
	needBox = drawBar;
	rows = gr_GetIntResource(shell,
		"paletteBarHeight", "PaletteBarHeight", DEFROWS);

	cols = gr_color.maxColors;

	if(!init(parent, rows, cols))
		return error();

	/* If not drawing labels, make window same size as XImage struct. */
	if(needBox)
	{	boxW = gr_MakeBox2("Palette", parent, topW, leftW, TRUE);
		if(drawLabels)
		{	height = rows + VSPACE;
			width = cols + HSPACE;
			ls = (Label_struct) malloc(sizeof( *ls));
			if(ls == NULL)
			{	fprintf(stderr,
				  "gr_make_palette: ran out of memory.\n");
				drawLabels = FALSE;
			}
			else
			{	ls->min = data->min;
				ls->max = data->max;
				xi_getPixelMapping(&(ls->mapping));
				ls->width = cols;
				ls->y0 = rows;
				ls->x0 = HSPACE/2;
				ls->mx0 = width/2;
				ls->my0 = height - 2;
				for(i=0; i<
					sizeof(ls->btns)/sizeof(*ls->btns);i++)
				{	ls->btns[i].mask = 0;
					ls->btns[i].proc = NULL;
					ls->btns[i].data = NULL;
				}
				ls->btns[0].mask = Button1Mask;
				ls->btns[0].proc = CBInitRotate;
				ls->btns[0].data = (XtPointer)index;
				ls->btns[1].mask = Button3Mask;
				ls->btns[1].proc = moving_label;
				ls->btns[1].data = (XtPointer)ls;
			}
		}
		else
		{	height = rows;
			width = cols;
		}

		if(drawBar)
		{	palW = gr_MakeImageStatic2(NULL, boxW,
				palImage, NULL, NULL,
					width, height, NULL, NULL);
			/* Set to use changeable colormap.
			   Unless shell is the top level shell, this may be
			   in vain.
			*/ 
			xi_setColormap(shell, index);
		        XtAddEventHandler(palW, Button1MotionMask,0,
						CRotate, (XtPointer) index );
#if 0
			/* Doesn't work. */
		        XtAddEventHandler(palW, ExposureMask,0,
					CBInitPal, XtParent(parent) );
#endif
/*		        gr_WidgetCursor2(palW, "sb_h_double_arrow");*/
		        gr_WidgetCursor2(palW, "crosshair");
		}

		/* Stuff that needs palW to set up. */
		if(drawLabels)
		{	gcvals.foreground = BlackPixel(display,scr);
			gcvals.background = WhitePixel(display,scr);
			gcvals.line_width = 1;
			ls->gc = XtGetGC(palW,
				GCBackground | GCForeground|GCLineWidth,
				&gcvals);
			gcvals.function = GXxor;
			ls->gc1 = XtGetGC(palW,
				GCLineWidth|GCFunction, &gcvals);
			/* NEED TO FREE THIS LATER !!! */
			if ((font_info = XLoadQueryFont(display,fontname))
			   != NULL)
				XSetFont(display,ls->gc,font_info->fid);

			ls->font = font_info;
			/* Guesstimate height of labels.	*/
			gr_RowColSize(font_info, TRUE, 1, 1,
							&cwidth, &cheight);
			ls->cheight = cheight;
			gr_AddDestroy(palW, gr_free, (XtPointer)ls);
		        XtAddEventHandler(palW, ButtonPressMask, FALSE,
				(XtEventHandler)dispatcher, (XtPointer) ls);

		        XtAddEventHandler(palW, ExposureMask, FALSE,
				(XtEventHandler)draw_labels, (XtPointer)ls);

		}
		else
		if(palW != NULL)
		{	XtAddEventHandler(palW, ButtonPressMask,
				FALSE, CBInitRotate, (XtPointer)index);
		}

		/* Place for some buttons. */
		panelW = gr_MakeBox2(NULL, boxW, palW, NULL, FALSE);
		gr_MakeButton3(NULL, panelW, "Reset", NONE,
			CBReset, index,  NULL, NULL);
		gr_MakeButton3(NULL, panelW, "Undo", NONE,
			CBUndo,index,  NULL, NULL);
	} /* if needbox */
	else
		panelW = parent;

	if(drawPaletteButton)
	{	PalData = (A_Palette_t *) calloc(1, sizeof(A_Palette_t));
		/* Need to deallocate this when window goes away!!! */
		if(PalData == NULL)
			return error();

		if(split)
		{	PalData->cs = &gr_colorSplit;
			PalData->index = index;
			PalData->Load_Palette = gr_LoadPALSplit;
		}
		else
		{	PalData->cs = &gr_color;
			PalData->Load_Palette = gr_LoadPAL;
		}
		PalData->Save_Palette = CBPalSave;
		PalData->client_data = (caddr_t) shell;
		/* Increase the size of the button if there is more room. */
		if(drawBar)
		{	if(drawLabels)	/* Bar, annotation. */
				ctlstr = "     Palette Control    ";
			else	/* Bar, no annotation. */
				ctlstr = "     Palette Control   ";
		}
		else	/* Only button. */
			ctlstr = "Palette Control";

		btnW = gr_MakeButton3(NULL, panelW,
			ctlstr, NONE,
			(XtCallbackProc)PaletteBox, (XtPointer) PalData,
			topW, leftW);
		gr_AddDestroy(btnW, destroy, (XtPointer)PalData);
	}
	else
		btnW = NULL;


	return needBox ? boxW : btnW;
}
