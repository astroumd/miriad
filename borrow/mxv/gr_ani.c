/*
 *	File:		gr_ani.c
 *	Contents:	Animation level routines for graphics module
 */

#include "gr_com.h"
#include <string.h>
#include <math.h>

extern long strtol();
extern A_AniWind_t  *gr_InitAniLevel2();

#define	GR_ANIDELAYMAX	2000000
#define	GR_ANIDELAYGRD	10000

XEvent	report;

#if defined(SYSV) || defined(__convex__) || defined(mips)
#include <sys/types.h>
#include <sys/time.h>

struct timeval   st_delay;
#define usleep(x)   { \
	st_delay.tv_usec = (x % 1000000); \
	st_delay.tv_sec = (x / 1000000); \
	select(32, NULL, NULL, NULL, &st_delay); }
#else
#ifdef UNICOS
struct timeval   st_delay;
#define usleep(x)   { \
	st_delay.tv_usec = (x % 1000000); \
	st_delay.tv_sec = (x / 1000000); \
	select(32, NULL, NULL, NULL, &st_delay); }
#endif
#endif

/*
 *	Delay and polling
 */
void
gr_AniEvent(delay)
long delay;
{
	if (delay > 0)
		usleep(delay);

	while (XtAppPending(app_context) != 0)
	{
		XtAppNextEvent(app_context, &report);
		XtDispatchEvent(&report);
	}
}

/****************************************************************************/


/*
 *	Draw grid
If MIRIAD format, labels are in hours, minutes, degrees no matter what.

Notes:
	When grid is on:
	This version differs from 'standard' MXV in that horizontal labels
	end on the tick marks rather than being roughly centered on them.
	This was done to make sure label doesn't run off right edge.
ToDo
	Rewrite to allow pixmaps to be displayed with grid.
 */

void
gr_AniDrawGrid(aniWin)
A_AniWind_t	*aniWin;
{
	A_Data_t	*ds=aniWin->parent->parent->data;
	Display		*display = XtDisplay(aniWin->imageWin);
	Window		window = XtWindow(aniWin->imageWin);
	int			scr = DefaultScreen(display);
	XGCValues	gcvals;
	GC			gc;
    XFontStruct *font_info;
    char        *fontname = "6x10", strbuf[20], *strng = strbuf;
	int		scale=aniWin->scale;
	int		offset=aniWin->offset;
	int		xmin=aniWin->xorg+scale/2;
	int		ymin=aniWin->yorg+scale/2;
	int		xdim=aniWin->imagexsize[0]/scale;
	int		ydim=aniWin->imageysize[0]/scale;
	int		vticks=aniWin->xorg-scale;
	int		vticke=vticks-10;
	int		hticks=aniWin->yorg+aniWin->imageysize[0]+scale;
	int		hticke=hticks+10;
	int		row=aniWin->axesOrient.row;
	int		col=aniWin->axesOrient.col;
	int		i,pos, oldpos;
	double		lpos;
	float32		val;
	A_Axes_t	*O= &aniWin->axesOrient;

	/* Row gives index of plane displayed along x axis, col along y???*/
	/*?? Should reverse label printing if negative?? */
	if (row < 0) row = -row;
	if (col < 0) col = -col;
	row--; col--;

	gcvals.foreground = BlackPixel(display,scr);
	gcvals.background = WhitePixel(display,scr);
	gcvals.line_width = 1;
	gc = XtGetGC(aniWin->imageWin, GCBackground|GCForeground|GCLineWidth,
					&gcvals);
	/* Do we really need to load a special font for this?? */

    if ((font_info = XLoadQueryFont(display,fontname)) != NULL)
        XSetFont(display,gc,font_info->fid);


	Notate( display, window, gc, font_info, 
		aniWin->xorg+aniWin->imagexsize[0]/2, 20,
		ds->dataName, CENTER_JUSTIFY, 0);

	XDrawRectangle(display,window,gc,
		aniWin->xorg, aniWin->yorg,
		aniWin->imagexsize[0], aniWin->imageysize[0]);

	/* Draw first 4 tick marks and labels for vertical axis (top down).*/
	for (i=0;i<4;i++)
	{
		lpos = (double)((double)ydim/4.0*(double)i);
		pos = (int)lpos*scale+ymin;
		XDrawLine(display,window,gc,vticks,pos,vticke,pos);
#if 0
		if (aniWin->axesOrient.row < 0)
			td_GetAxisValueString(ds, (int)lpos, row+1,
							NULL, strng);
		else
			td_GetAxisValueString(ds, ydim - (int)lpos -1,
							row+1, NULL, strng);
#else
		td_GetAxisValueString(ds, ydim - (int)lpos -1,
							O->row, NULL, strng);
#endif
		Notate(display, window, gc, font_info,
			vticke, pos, strng, RIGHT_JUSTIFY, 0);
	}

	/* Draw bottom tick mark on vertical scale. */
	pos = (ydim-1)*scale+ymin;
	XDrawLine(display,window,gc,vticks,pos,vticke,pos);
#if 0
	if (aniWin->axesOrient.row < 0)
		td_GetAxisValueString(ds, ydim-1, row+1, NULL, strng);
	else
		td_GetAxisValueString(ds, 0, row+1, NULL, strng);
#else
		td_GetAxisValueString(ds, 0, O->row, NULL, strng);
#endif
	/* Bottom label on vertical axis. */
	Notate(display, window, gc, font_info,
                        vticke, pos, strng, RIGHT_JUSTIFY, 0);
	/* Title for vertical axis. */
	Notate(display, window, gc, font_info,
		vticke, (int)ymin-10, ds->label[row], RIGHT_JUSTIFY, -1);


	/* Horizontal axis ticks and labels. */
	for (i=0;i<4;i++)
	{
		lpos = (double)((double)xdim/4.0*(double)i);
		pos = (int)lpos*scale+xmin;
		XDrawLine(display,window,gc,pos,hticks,pos,hticke);

#if 0
		if (aniWin->axesOrient.col < 0)
			td_GetAxisValueString(ds, xdim-(int)lpos-1,
							col+1, NULL, strng);
		else
			td_GetAxisValueString(ds, (int)lpos,
							col+1, NULL, strng);
#else
		td_GetAxisValueString(ds, (int)lpos, O->col, NULL, strng);
#endif

		/**** Draw axis label, maybe. */
		/* If width of image is too small to allow horizontal labels
		   to fit comfortably, only display even labels.
		   Note that oldpos can't be used until after the first loop.
		*/
		if( (i & 1) != 0)	/* Check odd labels. */
		{ int label_width, tick_width, len;

			tick_width = pos - oldpos;
			len = strlen(strng);
			label_width = XTextWidth(font_info, strng, len);
			/* tick_width should be > than label_width + ,say,
			   2 char widths.
			*/
			label_width += (label_width*2)/len;
			if(tick_width < label_width)
			{	oldpos = pos;
				continue;	/* Skip drawing label. */
			}
		}
		/* The 2 char offset puts the decimal point under the tick. */
		Notate(display, window, gc, font_info,
			pos, hticke+8, strng, RIGHT_JUSTIFY, 2);
		oldpos = pos;
	} /* End for loop */

	/* Draw last tick/label */
	pos = (xdim-1)*scale+xmin;
	XDrawLine(display,window,gc,pos,hticks,pos,hticke);
#if 0
	if (aniWin->axesOrient.col < 0)
			td_GetAxisValueString(ds, 0, col+1, NULL, strng);

	else
			td_GetAxisValueString(ds, xdim-1,
							col+1, NULL, strng);
#else
		td_GetAxisValueString(ds, xdim-1, O->col, NULL, strng);
#endif
	Notate(display, window, gc, font_info,
		pos, hticke+8, strng, RIGHT_JUSTIFY, 2);
	/* Horizontal title */
	Notate(display, window, gc, font_info,
		aniWin->xorg+aniWin->imagexsize[0]/2, hticke+20,
		ds->label[col], CENTER_JUSTIFY, 0);
	XFreeFont(display, font_info);
}


/*
 *	Draw a Pixmap
void
gr_AniDraw(display,window,pix,aniWin)
Display *display;
Window  window;
Pixmap  pix;
A_AniWind_t	*aniWin;
{
	XSetWindowBackgroundPixmap(display,window,pix);
	XClearWindow(display,window);
	XSync(display,FALSE);
}
*/


/*
 *	Draw an XImage
 */
void
gr_AniDrawImage(display,window,aniWin,i)
Display *display;
Window  window;
A_AniWind_t	*aniWin;
int	i;
{
	if (aniWin->usePixmap == TRUE)
	{
		XSetTile(display,aniWin->imageWinGC,aniWin->image[i]);
		XFillRectangle(display,window,aniWin->imageWinGC,0,0,
		aniWin->imagexsize[i],aniWin->imageysize[i]);
	}
	else
	{
		XPutImage(display,window,aniWin->imageWinGC,aniWin->ximage[i],0,0,
		aniWin->xorg,aniWin->yorg,
		aniWin->imagexsize[i],aniWin->imageysize[i]);
	}

	XSync(display,FALSE);
}


/*
 *	Draw an XImage
 */
void
gr_AniDrawLoad(display,window,aniWin,i)
Display *display;
Window  window;
A_AniWind_t	*aniWin;
int	i;
{
	int ispal;

    if (td_HdfgetRaster(aniWin->pathname,
		aniWin->data[0],gr_color.palette,
        &(aniWin->imagexsize[0]),&(aniWin->imageysize[0]),&ispal,i) != NULL)
    {
    	if (aniWin->usePixmap == TRUE)
    	{
		XFreePixmap(display,aniWin->image[0]);
     	aniWin->image[0] = gr_PixmapCreate(aniWin->imageWin,aniWin->imageWinGC,
            aniWin->xorg,aniWin->yorg,
			aniWin->imagexsize[0],aniWin->imageysize[0],aniWin->data[0]);
    	}
    	else
    	{
     	aniWin->ximage[0] = gr_ImageCreate(aniWin->imageWin,
            aniWin->imagexsize[0],aniWin->imageysize[0],aniWin->data[0]);
    	}

     	gr_AniDrawImage(display,window,aniWin,0);
	}
}


/*
 *	Load frames from hdf file
 */
void
gr_AniLoad(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
	A_FileWind_t	*fileWin=(A_FileWind_t *)client_data;
	int		ret,xsize,ysize,ispal,start,stop,numFrames;
	char	*filename;
	char	*pathname;

	pathname = td_getPathName(NULL, NULL, NULL);
	if( (filename = strrchr(pathname, '/')) != NULL)
		filename += 1;
	else
		filename = pathname;

	if ((ret = td_HdfgetRasDims(pathname,&xsize,&ysize,&ispal)) == -1)
	{
		sprintf(msg,"***ERROR: Cannot open file %s.\n",filename);
		gr_TextMsgOut(msg);
		gr_TextMsgOut
		("Are you sure it is a RASTER8 HDF file?\n");
	}
	else
	{
	    start = atoi(gr_DialogGetValue(fileWin->rasStartDialog));
	    stop = atoi(gr_DialogGetValue(fileWin->rasEndDialog));
		if (start < 0) start = 0; if (start >= ret) start=ret-1;
		if (stop < 0) stop = 0; if (stop >= ret) stop=ret-1;
		if (stop < start) stop = start;
		sprintf(msg,"%d",start);
		gr_DialogSetValue(fileWin->rasStartDialog,msg);
		sprintf(msg,"%d",stop);
		gr_DialogSetValue(fileWin->rasEndDialog,msg);
		numFrames = stop-start+1;
		sprintf(msg,
		"Loading %d frames from file %s...Please wait.\n",numFrames,
								filename);
		gr_TextMsgOut(msg);
		if (gr_topWin.numAniWins < MAX_ANILEV_WINDS)
		{
			gr_topWin.aniWin =
				gr_InitAniLevel2(gr_topWin.aniWin,filename,
					pathname, gr_topLevel,start,stop,
					numFrames, xsize,ysize,
					ispal,fileWin->usePixmap,
							fileWin->useDisk);
			if(gr_topWin.aniWin != NULL)
				gr_topWin.numAniWins++;
		}
		gr_CloseFileLevel(w,(caddr_t)fileWin,(caddr_t)NULL);
	}

    return;
}


/*
 *	Turn off Auto play
 */
void
gr_AniSetAutoOff(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
	A_AniWind_t	*aniWin=(A_AniWind_t *)client_data;

	aniWin->autoMode = AUTOOFF;

    return;
}


/*
 *	Set Auto play to Auto-repeat
 */
void
gr_AniSetAutoRep(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
	A_AniWind_t	*aniWin=(A_AniWind_t *)client_data;

	aniWin->autoMode = AUTOREPEAT;

    return;
}


/*
 *	Set Auto play to Auto-reverse
 */
void
gr_AniSetAutoRev(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
	A_AniWind_t	*aniWin=(A_AniWind_t *)client_data;

	aniWin->autoMode = AUTOREVERSE;

    return;
}


/*
 *	Jump to frame specified by the Frame dialog
 */
void
gr_AniFrameSet(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{

A_AniWind_t	*aniWin=(A_AniWind_t *)client_data;
int		frame;
Widget		slider;

	frame = atoi(gr_DialogGetValue(aniWin->frameDialog));
	slider = aniWin->frameSlider;

	if ((frame >= 0) && (frame < aniWin->numplanes))
	{
		aniWin->curplane = frame;

/*		gr_SliderSetValue(w,aniWin->curplane);*/
		gr_SliderSetValue(slider, aniWin->curplane);
		if (aniWin->useDisk == TRUE)
			gr_AniDrawLoad(XtDisplay(aniWin->imageWin),
			XtWindow(aniWin->imageWin),aniWin,aniWin->curplane);
		else
			gr_AniDrawImage(XtDisplay(aniWin->imageWin),
			XtWindow(aniWin->imageWin),aniWin,aniWin->curplane);
	}
	else
		gr_TextMsgOut("Error: Requested frame is out of limits!\n");

    return;
}


/*
 *	Set the frame skip increment specified by the Skip dialog
 */
void
gr_AniSkipSet(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
	A_AniWind_t	*aniWin=(A_AniWind_t *)client_data;
	int			skip;

	skip = atoi(gr_DialogGetValue(aniWin->skipDialog));

	if ((skip >= 0) && (skip < aniWin->numplanes))
		aniWin->skip = skip;
	else
		gr_TextMsgOut("Error: Frame skip amount is out of limits!\n");

    return;
}


/* Called when user presses <RETURN> after setting Frame or Skip dialogs.
Param:	desc
  1	Pointer to A_AniWind_t struct;
  2	"Frame" or "Skip"

*/
XtActionProc gr_FrameSetReturn(w, event, params, numparams)
Widget	w;
XEvent	*event;
String	*params;
Cardinal *numparams;
{
A_AniWind_t *ani;

	if(*numparams != 2)
	{	fprintf(stderr,
	 "gr_FrameSetReturn: called with wrong # of args (%d)\n", *numparams);
		return;
	}
	/* Convert from string to pointer. The conversion is probably
	   illegal, but ...
	*/
	ani = (A_AniWind_t *) strtol(*params, NULL, 0);
	if( ani == NULL)
	{	fprintf(stderr,
			"gr_FrameSetReturn: called with NULL pointer.\n");
		return;
	}

	switch ( *params[1]) {
	case 'F':
		gr_AniFrameSet(NULL, ani, NULL);
		break;
	case 'S':
		gr_AniSkipSet(NULL, ani, NULL);
		break;
	default:
		fprintf(stderr,
		"gr_FrameSetReturn: called with bad param %s\n", *params);
		break;
	}	
	return;
}

/*
 *	Increment the amount of delay
 */
void
gr_AniSpeedSlow(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
	A_AniWind_t	*aniWin=(A_AniWind_t *)client_data;

	if (aniWin->speed < (long)(GR_ANIDELAYMAX-GR_ANIDELAYGRD))
		aniWin->speed+=(long)GR_ANIDELAYGRD;
	else
		aniWin->speed=(long)GR_ANIDELAYMAX;

	gr_SliderSetValue(aniWin->speedSlider,(int)aniWin->speed);

    return;
}


/*
 *	Decrement the amount of delay
 */
void
gr_AniSpeedFast(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
	A_AniWind_t	*aniWin=(A_AniWind_t *)client_data;

	if (aniWin->speed > (long)GR_ANIDELAYGRD)
		aniWin->speed-=(long)GR_ANIDELAYGRD;
	else
		aniWin->speed=(long)0;

	gr_SliderSetValue(aniWin->speedSlider,(int)aniWin->speed);

    return;
}


/*
 *	Change the amount of delay when speed slider is selected
 */
void
gr_AniSpeedSliderSel(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
	A_AniWind_t	*aniWin=(A_AniWind_t *)client_data;

	aniWin->speed = (long)call_data;
	gr_SliderSetValue(w,(int)aniWin->speed);

	return;
}


/*
 *	Change the amount of delay when speed slider is moved
 */
void
gr_AniSpeedSliderMov(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
	A_AniWind_t	*aniWin=(A_AniWind_t *)client_data;

	aniWin->speed = (long)call_data;
	return;
}


/*
 *	Change the amount of delay when speed slider is released
 */
void
gr_AniSpeedSliderRel(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
	return;
}


/*
 *	Change the frame when manual frame slider is selected
 */
void
gr_AniFrameSliderSel(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
	A_AniWind_t	*aniWin=(A_AniWind_t *)client_data;

	aniWin->curplane = (int)call_data;
	gr_SliderSetValue(w,aniWin->curplane);
	sprintf(msg,"%d",aniWin->curplane);
	gr_DialogSetValue(aniWin->frameDialog,msg);

	if (aniWin->useDisk == TRUE)
	gr_AniDrawLoad(XtDisplay(aniWin->imageWin),
		XtWindow(aniWin->imageWin),aniWin,aniWin->curplane);
	else
		gr_AniDrawImage(XtDisplay(aniWin->imageWin),
		XtWindow(aniWin->imageWin),aniWin,aniWin->curplane);

    return;
}


/*
 *	Change the frame when manual frame slider is moved
 */
void
gr_AniFrameSliderMov(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
A_AniWind_t	*aniWin=(A_AniWind_t *)client_data;
int	curplane;

	if( (curplane = (int)call_data) >= aniWin->numplanes)
		return;

	aniWin->curplane = curplane;
	sprintf(msg,"%d",aniWin->curplane);
	gr_DialogSetValue(aniWin->frameDialog,msg);

	/* Show frames only if animating from memory, else it will be too slow */
	if (aniWin->useDisk == FALSE)
	{
		gr_AniDrawImage(XtDisplay(aniWin->imageWin),
			XtWindow(aniWin->imageWin),aniWin,aniWin->curplane);
	}

    return;
}


/*
 *	Change the frame when manual frame slider is released
 */
void
gr_AniFrameSliderRel(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
	A_AniWind_t	*aniWin=(A_AniWind_t *)client_data;

	aniWin->curplane = (int)call_data;
	sprintf(msg,"%d",aniWin->curplane);
	gr_DialogSetValue(aniWin->frameDialog,msg);

	/* Show last frame selected only if animating from disk */
	if (aniWin->useDisk == TRUE)
		gr_AniDrawLoad(XtDisplay(aniWin->imageWin),
			XtWindow(aniWin->imageWin),aniWin,aniWin->curplane);
    return;
}


/*
 *	Update display on expose event
 */
void
gr_AniExpose(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
	A_AniWind_t	*aniWin=(A_AniWind_t *)client_data;

    gr_ImageSetCMap(aniWin->shell);
	if (aniWin->useDisk == TRUE)
	gr_AniDrawLoad(XtDisplay(aniWin->imageWin),
		XtWindow(aniWin->imageWin),aniWin,aniWin->curplane);
	else
	gr_AniDrawImage(XtDisplay(aniWin->imageWin),
		XtWindow(aniWin->imageWin),aniWin,aniWin->curplane);

	if (aniWin->gridOn == TRUE)
		gr_AniDrawGrid(aniWin);
    return;
}


/*
 *	Turn on the stop flag
 */
void
gr_AniPlayStop(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
	A_AniWind_t	*aniWin=(A_AniWind_t *)client_data;

	aniWin->playStop = 1;
}


/*
 *	Play sequence forward
 */
void
gr_AniForward(display,window,aniWin)
Display	*display;
Window	window;
A_AniWind_t	*aniWin;
{
	int skip;

	aniWin->playStop = 0;

	aniWin->curplane+=aniWin->skip+1;
	skip = aniWin->skip+1;

	while ((aniWin->curplane<aniWin->numplanes) && (aniWin->playStop == 0))
	{
		sprintf(msg,"%d",aniWin->curplane);
		gr_DialogSetValue(aniWin->frameDialog,msg);

		gr_SliderSetValue(aniWin->frameSlider,aniWin->curplane);

		if (aniWin->useDisk == TRUE)
		gr_AniDrawLoad(XtDisplay(aniWin->imageWin),
			XtWindow(aniWin->imageWin),aniWin,aniWin->curplane);
		else
		gr_AniDrawImage(display,window,aniWin,aniWin->curplane);

		gr_AniEvent((long)aniWin->speed);

		aniWin->curplane+=skip;
	}

	aniWin->curplane--;
	aniWin->curplane-=aniWin->skip;
}


/*
 *	Play sequence backward
 */
void
gr_AniBackward(display,window,aniWin)
Display	*display;
Window	window;
A_AniWind_t	*aniWin;
{
	int skip;

	aniWin->playStop = 0;

	aniWin->curplane-=(aniWin->skip+1);
	skip = -aniWin->skip-1;

	while ((aniWin->curplane>=0) && (aniWin->playStop == 0))
	{
		sprintf(msg,"%d",aniWin->curplane);
		gr_DialogSetValue(aniWin->frameDialog,msg);

		gr_SliderSetValue(aniWin->frameSlider,aniWin->curplane);

		if (aniWin->useDisk == TRUE)
		gr_AniDrawLoad(XtDisplay(aniWin->imageWin),
			XtWindow(aniWin->imageWin),aniWin,aniWin->curplane);
		else
		gr_AniDrawImage(display,window,aniWin,aniWin->curplane);

		gr_AniEvent((long)aniWin->speed);

		aniWin->curplane+=skip;
	}
	aniWin->curplane++;
	aniWin->curplane+=aniWin->skip;
}


/*
 *	Play sequence forward (and backward if autoreverse) until stopped
 */
void
gr_AniPlayForward(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
	A_AniWind_t	*aniWin=(A_AniWind_t *)client_data;
	Display	*dpy=XtDisplay(aniWin->imageWin);
	Window	win=XtWindow(aniWin->imageWin);
	int		rev=1;

	if (aniWin->numplanes == 1)
	{
		gr_TextMsgOut(
		"There is only 1 frame in the sequence.\nI cannot animate this sequence.\n");
		return;
	}

	gr_AniForward(dpy,win,aniWin);

	while (aniWin->playStop == 0)
	switch(aniWin->autoMode)
	{
		case AUTOOFF:
			aniWin->playStop = 1;
			break;
		case AUTOREPEAT:
			aniWin->curplane = -1;
			gr_AniForward(dpy,win,aniWin);
			break;
		case AUTOREVERSE:
			if (rev == 1)
			{
				aniWin->curplane = aniWin->numplanes;
				gr_AniBackward(dpy,win,aniWin);
				rev=0;
			}
			else
			{
				aniWin->curplane = -1;
				gr_AniForward(dpy,win,aniWin);
				rev=1;
			}
			break;
	}

    return;
}


/*
 *	Play sequence backward (and forward if autoreverse) until stopped
 */
void
gr_AniPlayBackward(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
	A_AniWind_t	*aniWin=(A_AniWind_t *)client_data;
	Display	*dpy=XtDisplay(aniWin->imageWin);
	Window	win=XtWindow(aniWin->imageWin);
	int			rev=1;

	if (aniWin->numplanes == 1)
	{
		gr_TextMsgOut(
		"There is only 1 frame in the sequence.\nI cannot animate this sequence.\n");
		return;
	}

	gr_AniBackward(dpy,win,aniWin);

	while (aniWin->playStop == 0)
	switch(aniWin->autoMode)
	{
		case AUTOOFF:
			aniWin->playStop = 1;
			break;
		case AUTOREPEAT:
			aniWin->curplane = aniWin->numplanes;
			gr_AniBackward(dpy,win,aniWin);
			break;
		case AUTOREVERSE:
			if (rev==1)
			{
				aniWin->curplane = 0;
				gr_AniForward(dpy,win,aniWin);
				rev=0;
			}
			else
			{
				aniWin->curplane = aniWin->numplanes;
				gr_AniBackward(dpy,win,aniWin);
				rev=1;
			}
			break;
	}

    return;
}


/*
 *	Step forward to next frame
 */
void
gr_AniStepForward(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
	A_AniWind_t	*aniWin=(A_AniWind_t *)client_data;
	Display	*dpy=XtDisplay(aniWin->imageWin);
	Window	win=XtWindow(aniWin->imageWin);

	if (aniWin->curplane < (aniWin->numplanes-1) )
	{
		aniWin->playStop = 1;
		aniWin->curplane++;

		if (aniWin->useDisk == TRUE)
		gr_AniDrawLoad(XtDisplay(aniWin->imageWin),
			XtWindow(aniWin->imageWin),aniWin,aniWin->curplane);
		else
		gr_AniDrawImage(dpy,win,aniWin,aniWin->curplane);

		sprintf(msg,"%d",aniWin->curplane);
		gr_DialogSetValue(aniWin->frameDialog,msg);
		gr_SliderSetValue(aniWin->frameSlider,aniWin->curplane);
	}
    return;
}


/*
 *	Step backward to next frame
 */
void
gr_AniStepBackward(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
	A_AniWind_t	*aniWin=(A_AniWind_t *)client_data;
	Display	*dpy=XtDisplay(aniWin->imageWin);
	Window	win=XtWindow(aniWin->imageWin);

	if (aniWin->curplane > 0)
	{
		aniWin->playStop = 1;
		aniWin->curplane--;

		if (aniWin->useDisk == TRUE)
		gr_AniDrawLoad(XtDisplay(aniWin->imageWin),
			XtWindow(aniWin->imageWin),aniWin,aniWin->curplane);
		else
		gr_AniDrawImage(dpy,win,aniWin,aniWin->curplane);

		sprintf(msg,"%d",aniWin->curplane);
		gr_DialogSetValue(aniWin->frameDialog,msg);
		gr_SliderSetValue(aniWin->frameSlider,aniWin->curplane);
	}
    return;
}
