/*
 *	File:		gr_anilev.c
 *	Contents:	Animate level window functions for graphics module
 * NOTE!!
	These routines use the form widget to allow easy placement. However,
in order to get different boxes to line up, there has still be a lot of
fudging of sizes.

 */

#include "gr_com.h"

#include <signal.h>

extern long	td_CurrentTime();
extern int	gr_AniTimeOut();
extern void	gr_RasterImagePrint ();
extern void	gr_Anibegincontour();
extern void	gr_ImageInitCMapHDF();
extern void	gr_AniDrawGrid();
extern void	gr_AniDrawImage();
extern void	gr_AniDrawLoad();
extern void	gr_Anicontourdialog();
extern void	gr_AniSetAutoOff();
extern void	gr_AniSetAutoRev();
extern void	gr_AniSetAutoRep();
extern void	gr_AniPlayStop();
extern void	gr_AniPlayForward();
extern void	gr_AniPlayBackward();
extern void	gr_AniStepForward();
extern void	gr_AniStepBackward();
extern void	gr_AniSpeedFast();
extern void	gr_AniSpeedSlow();
extern void	gr_AniSpeedSliderSel();
extern void	gr_AniSpeedSliderMov();
extern void	gr_CloseAniLevel();
extern void	gr_AniExpose();
extern void	gr_SaveAni();
extern void	gr_AniFrameSliderSel();
extern void	gr_AniFrameSliderMov();

extern XtActionProc gr_FrameSetReturn();
extern Widget gr_MakeRepeater();

#define	OFFSET			50
#define GR_ANIDELAYMAX  2000000
#define GR_ANIDELAYGRD  10000
#define	MINWINXSIZE	285
#define MINWINYSIZE	100
#define	MAXWINXSIZE	900
#define MAXWINYSIZE	900
#define LEEWAY		2

/* Translation template for Frame/Skip dialogs. */
static  char gr_SetAniTrans[]   = "<Key>Return:    gr_FrameSetReturn(%#x %s)";

/* set up translations for animation window.
Generates a translation string for Frame or Skip dialog then adds it to
the dialog.

w	dialog widget
ani	pointer to aniwin struct
which	either "Frame" or "Skip"
*/
static void SetAniTrans(w, ani, which)
Widget	w;
A_AniWind_t *ani;
char	*which;
{
char	buf[sizeof(gr_SetAniTrans)+20];

	sprintf(buf, gr_SetAniTrans, ani, which);
	gr_DialogAddTrans(w, buf);
}

/* Make the Off, Repeat and Reverse controls. */
static Widget make_off_reverse( parent, tmp, topW, leftW)
Widget	parent, topW, leftW;
A_AniWind_t	*tmp;
{
Widget	box, tmpW1, tmpW, formW;

	/* Goes around all these buttons. */
	box = gr_MakeBoxForm( NULL, parent, &formW, topW, leftW);
		tmpW = gr_MakeToggle2(NULL, formW,
				"Off ", DIAMOND, TRUE,
				(XtCallbackProc)gr_AniSetAutoOff, (caddr_t)tmp,
				NULL, NULL);
		gr_MakeRadio(tmpW, tmpW, TRUE);
		tmpW1 = gr_MakeToggle2(NULL, formW,
				"Repeat", DIAMOND, FALSE,
				(XtCallbackProc)gr_AniSetAutoRep, (caddr_t)tmp,
				NULL, tmpW);
		gr_MakeRadio(tmpW1, tmpW, TRUE);
		tmpW = gr_MakeToggle2(NULL,  formW,
				"Reverse",DIAMOND, FALSE,
				(XtCallbackProc)gr_AniSetAutoRev,(caddr_t)tmp,
				NULL, tmpW1);
		gr_MakeRadio(tmpW, tmpW1, TRUE);
	return box;
}

/* Make the direction controls. */
static Widget make_direction_buttons( parent, tmp, topW, leftW)
Widget	parent, topW, leftW;
A_AniWind_t	*tmp;
{
Widget	box, tmpW, formW;

	box = gr_MakeBoxForm( NULL, parent, &formW, topW, leftW);

		tmpW = gr_MakeButton3(NULL, formW, "<<", NONE,
			 (XtCallbackProc)gr_AniPlayBackward, (caddr_t)tmp,
			 NULL, NULL);
/*		tmpW = gr_MakeButton3(NULL, formW, "< ", NONE, */
		tmpW = gr_MakeButton3(NULL, formW, NULL, LEFT, 
			 (XtCallbackProc)gr_AniStepBackward, (caddr_t)tmp,
			 NULL, tmpW);
		/* This was "<>" it is now whatever it is to increase
		   the box size.
		*/
		tmpW = gr_MakeButton3(NULL, formW," <-> ", NONE,
			 (XtCallbackProc)gr_AniPlayStop,(caddr_t)tmp,
			 NULL, tmpW);
/*		tmpW = gr_MakeButton3(NULL, formW,"> ", NONE,*/
		tmpW = gr_MakeButton3(NULL, formW, NULL, RIGHT,
			 (XtCallbackProc)gr_AniStepForward,(caddr_t)tmp,
			 NULL, tmpW);
		tmpW = gr_MakeButton3(NULL, formW,">>", NONE,
			 (XtCallbackProc)gr_AniPlayForward,(caddr_t)tmp,
			 NULL, tmpW);
	return box;
}

/* Make the speed controls. */
static Widget make_speed_controls( parent, tmp, topW, leftW)
Widget	parent, topW, leftW;
A_AniWind_t	*tmp;
{
Widget	boxW, tmpW, formW;

	boxW = gr_MakeBoxForm( NULL, parent, &formW, topW, leftW);
		tmpW = gr_MakeRepeater(NULL, formW, "Fast <-", NONE,
			(XtCallbackProc)gr_AniSpeedFast, (caddr_t)tmp,
			NULL, NULL);
		tmp->speedSlider =
			gr_MakeSlider2(NULL, formW,
				0,GR_ANIDELAYMAX+1, 0, 0,
				(XtCallbackProc)gr_AniSpeedSliderSel,
				(XtCallbackProc)gr_AniSpeedSliderMov,
				(caddr_t)tmp, HORIZONLY, 180, 26, NULL , tmpW);
		gr_MakeRepeater(NULL, formW,"-> Slow", NONE, 
			(XtCallbackProc)gr_AniSpeedSlow,(caddr_t)tmp,
			NULL, tmp->speedSlider);
	return boxW;
}

static Widget gr_MakeAniControls( shellname, parent, data,
			label, tmp, xsize, ysize, numplanes, init2)
char		*shellname;
Widget		parent;
A_Data_t	*data;
char		*label;
A_AniWind_t	*tmp;
int		xsize, ysize, numplanes;
Boolean		init2;		/* Hack for level2 stuff. */
{
Widget	tmpW, saveW, dirW, offW;	/* Temp widgets. */
Widget	palW, boxWind, boxformW, speedW;
XImage	*palimage;

	tmp->shell = gr_MakeWindow2(shellname, parent, &(tmp->win),
				(XtCallbackProc)gr_CloseAniLevel, (caddr_t)tmp,
				label, "Close", FALSE);

	/* Where animation is done. */
	if (tmp->gridOn == FALSE)
		tmp->imageWin = gr_MakeWorkSpace2(NULL, tmp->win,
			(XtCallbackProc)gr_AniExpose, NULL, NULL, (caddr_t)tmp,
			xsize,ysize, NULL, NULL);
	else
		tmp->imageWin = gr_MakeWorkSpace2(NULL, tmp->win,
			(XtCallbackProc)gr_AniExpose, NULL, NULL, (caddr_t)tmp,
			xsize+2*OFFSET,ysize+2*OFFSET, NULL, NULL);


/*	imageVport seems to not be needed.
	tmp->imageVPort = gr_MakeVPort2("MXVvport", tmp->win,
				VERTHORIZ, NULL, (XtPointer) tmp,
				Winxsize, Winysize, boxWind, NULL);
*/
	tmp->imageVPort = NULL;

	/* Image of palette. */
	palW = gr_make_palette(tmp->win, tmp->shell, TRUE, FALSE,
			data, tmp->imageWin, NULL);


	/* All those buttons and things below the palette. */
	boxWind = gr_MakeBoxForm( NULL, tmp->win, &boxformW, palW, NULL);

		saveW = gr_MakeButton3(NULL, boxformW, "Save   ", NONE,
			(XtCallbackProc)gr_SaveAni, (caddr_t)tmp,
			NULL, NULL);
		/* Direction buttons go to right of 'Save' button. */
		dirW = make_direction_buttons( boxformW, tmp, NULL , saveW);

	/* Off Repeat Reverse buttons. */
	offW = make_off_reverse( boxformW, tmp, dirW, NULL);
	/* To right of palette button. */
	tmp->frameSlider =
		gr_MakeSlider2(NULL, boxformW, 0, numplanes, 0,0,
			(XtCallbackProc)gr_AniFrameSliderSel,
			(XtCallbackProc)gr_AniFrameSliderMov,
			(caddr_t)tmp, HORIZONLY, 300, 23, offW, NULL);


	tmp->frameDialog= gr_MakeDialog(NULL, boxformW,"Frame","0",5,1,
				NULL, offW);
	SetAniTrans(tmp->frameDialog, tmp, "Frame");
	tmp->skipDialog= gr_MakeDialog(NULL, boxformW,"Skip ","0",5,1,
				NULL, tmp->frameDialog);
	SetAniTrans(tmp->skipDialog, tmp, "Skip");
	/* Fast Slow controls. */
	tmpW = make_speed_controls(boxformW, tmp, tmp->frameSlider, NULL);
	if( init2) 
	{	speedW = gr_MakeButton3(NULL,boxWind, "Print", NONE,
			(XtCallbackProc)gr_RasterImagePrint ,(caddr_t)tmp,
			NULL, NULL);
		gr_MakeButton3( NULL,boxWind, "Contour", NONE,
				(XtCallbackProc) gr_Anicontourdialog,
				(caddr_t)tmp,
				speedW, tmpW);
	}
	/* By now, most of the widgets have been made. Now try to realize
	   them;
	*/
	gr_ManageChild(tmp->shell);
	return boxWind;
}

/* Called when a problem occurred allocating animation memory.
Attempts to free anything already allocated, print out an error message
then return.
*/
static void anioops(ani)
A_AniWind_t *ani;
{
	if(ani != NULL)
	{	if(ani->imagexsize != NULL)
			free(ani->imagexsize);
		if(ani->imageysize != NULL)
			free(ani->imageysize);
		if(ani->data != NULL)
			td_Free((char *)ani->data);
		if(ani->image != NULL)
			td_Free(ani->image);
		if(ani->ximage != NULL)
			td_Free(ani->ximage);
		if(ani->pathname != NULL)
			free(ani->pathname);
		free(ani);
	}
	gr_TextMsgOut("Could not allocate animation memory.\n");
}

/* Initialization that is common to InitAniLevel & InitAniLevel3. */
static A_AniWind_t *aniInit0(usePixmap, useDisk, gridOn, pathname, numplanes, nFrames)
Boolean		usePixmap, useDisk, gridOn;
char		*pathname;
int		numplanes, *nFrames;
{
A_AniWind_t	*tmp;
int		numFrames;

/*
	tmp = (A_AniWind_t *)td_Malloc(sizeof(A_AniWind_t),"A_AniWind_t");
*/
	tmp = (A_AniWind_t *) calloc(1, sizeof(A_AniWind_t));
	if(tmp == NULL)
	{	anioops(tmp);
		return NULL;
	}
	tmp->usePixmap = usePixmap;
	tmp->useDisk = useDisk;
	tmp->contourWin = NULL;
	tmp->playStop = 1;
	tmp->autoMode = AUTOOFF;
	tmp->curplane = 0;
	tmp->speed = 0;
	tmp->skip = 0;
	tmp->gridOn = gridOn;
	tmp->numplanes = numplanes;

	if (tmp->gridOn == FALSE)
	{
		tmp->xorg = tmp->yorg = 0;
	}
	else
	{
		tmp->xorg = OFFSET*7/4;
		tmp->yorg = tmp->offset = OFFSET;
	}
	/* Should we be using strdup here?? */
	if(pathname == NULL)
		tmp->pathname = NULL;
	else
	{	tmp->pathname = (char *)td_Malloc1D(1,strlen(pathname)+1,
				(unsigned int)sizeof(char), "td_Malloc1D");
		strcpy(tmp->pathname,pathname);
	}

	numFrames = (tmp->useDisk == TRUE) ? 1 : numplanes;
	*nFrames = numFrames;

	tmp->imagexsize = (int *)calloc(numFrames,sizeof(int));
	if (tmp->imagexsize == NULL)
	{	anioops(tmp);
		return NULL;
	}
	tmp->imageysize = (int *)calloc(numFrames,sizeof(int));
	if (tmp->imageysize == NULL)
	{	anioops(tmp);
		return NULL;
	}
	tmp->data = td_Malloc2D(1,numplanes,
			(long)sizeof(char *),"td_Malloc2D");
	if(tmp->data == NULL)
	{	anioops(tmp);
		return NULL;
	}
	if (tmp->usePixmap == TRUE)
	{	tmp->image = (Pixmap *)td_Malloc1D(1, numFrames,
				(long)sizeof(Pixmap), "td_Malloc1D");
		if(tmp->image == NULL)
		{	anioops(tmp);
			return NULL;
		}
	}
	else
	{	tmp->ximage = (XImage **)td_Malloc1D(1,numFrames,
				(long)sizeof(XImage *), "td_Malloc1D");
		if(tmp->ximage == NULL)
		{	anioops(tmp);
			return NULL;
		}
	}
	return tmp;
}

/*
 * Animate along cartesian axes
 */
A_AniWind_t
*gr_InitAniLevel(header,shellName,parent,numplanes,incr,scale,orient,tparent,
	pathname)
A_AniWind_t 	*header;
char   	 	*shellName;
Widget	 	parent;
int		numplanes,incr,scale;
A_Axes_t	orient;
A_CubeWind_t	*tparent;
char		*pathname;
{
A_BossWind_t	*bossWin=tparent->parent;
A_AniWind_t	*tmp;
Widget		controlW;
int		usePlane,winxsize,winysize,xsize,ysize;
int		ncols,nrows,numFrames,ret,fileexist;
short		i,j;
long		startTime,remTime;
char		label[STRNG160],strng[STRNG160];
Display		*dpy;
Window		win;
XImage		*palimage;
XGCValues	gcvals;
pixelMapping	*mapping = &tparent->mapping;

	gr_WidgetCursor(tparent->shell,XC_watch);
	tmp = aniInit0(tparent->usePixmap, tparent->useDisk, tparent->gridOn,
		pathname, numplanes, &numFrames);
	if(tmp == NULL)
		return NULL;
	bossWin->data->scale = scale;
	tmp->scale = scale;
	tmp->aniType = 1;
	tmp->axesOrient = orient;

	ncols = td_HdfgetDim(bossWin->data,orient.col);
	nrows = td_HdfgetDim(bossWin->data,orient.row);

	if ((tparent->interp == TRUE) && (tparent->cull == FALSE))
	{
		ncols--; nrows--;
	}

	if (tparent->cull == FALSE)
	{
		xsize = ncols*scale;
		ysize = nrows*scale;
	}
	else
	{
		xsize = ncols/scale;
		if (xsize*scale < ncols) xsize++;
		ysize = nrows/scale;
		if (ysize*scale < nrows) ysize++;
	}

	if (xsize > MINWINXSIZE)
		if (xsize > MAXWINXSIZE)
			winxsize = MAXWINXSIZE;
		else
			winxsize = xsize+LEEWAY;
	else
		winxsize = MINWINXSIZE+LEEWAY;

	if (ysize > MINWINYSIZE)
		if (ysize > MAXWINYSIZE)
			winysize = MAXWINYSIZE;
		else
			winysize = ysize+LEEWAY;
	else
		winysize = MINWINYSIZE+LEEWAY;

	if (tmp->gridOn == TRUE)
	{
		winxsize += 2*OFFSET; winysize += 2*OFFSET;
	}

	sprintf(label,"%s: Animate %d planes",tparent->parent->filename,
			numplanes);

	controlW = gr_MakeAniControls( shellName, parent,  bossWin->data,
		label, tmp, xsize, ysize, numplanes, FALSE);



	dpy = XtDisplay(tmp->imageWin);
	win = XtWindow(tmp->imageWin);
	gcvals.foreground = BlackPixel(dpy,DefaultScreen(dpy));
	tmp->imageWinGC = XtGetGC(tmp->imageWin, GCForeground, &gcvals);
	XSetTSOrigin(dpy,tmp->imageWinGC,0,0);
	XSetFillStyle(dpy,tmp->imageWinGC,FillTiled);

	startTime = td_CurrentTime();

	i=0;
	for (j=0;j<numplanes;j++)
	{
		usePlane = orient.plane+(j*incr);
		if (tmp->useDisk == FALSE)
			i = j;

		tmp->imagexsize[i] = xsize;
		tmp->imageysize[i] = ysize;
		if ((tmp->useDisk == TRUE) && (j > 0))
		{
			if (tmp->usePixmap == TRUE)
				XFreePixmap(dpy,tmp->image[0]);
			else
				XDestroyImage(tmp->ximage[0]);
			td_Free((char *)tmp->data[0]);
		}
		tmp->data[i] = td_HdfgetPixData(bossWin->data,
				orient.row,orient.col,orient.axis,
				usePlane,tparent->interp,tparent->cull,
				mapping);

		if (tmp->usePixmap == TRUE)
		{
		tmp->image[i] = gr_PixmapCreate(tmp->imageWin,tmp->imageWinGC,
				tmp->xorg,tmp->yorg,
				tmp->imagexsize[i],tmp->imageysize[i],tmp->data[i]);
		}
		else
		{
		tmp->ximage[i] = gr_ImageCreate(tmp->imageWin,
				tmp->imagexsize[i],tmp->imageysize[i],tmp->data[i]);
		}
		gr_AniDrawImage(dpy,win,tmp,i);

		if (tmp->useDisk == TRUE)
		{
			fileexist = td_FileExist(pathname);

			if (fileexist == 0)
				ret = td_HdfPutImage(pathname,tmp->data[i],gr_color.palette,
				tmp->imagexsize[i],tmp->imageysize[i]);
			else
				ret = td_HdfAddImage(pathname,tmp->data[i],gr_color.palette,
				tmp->imagexsize[i],tmp->imageysize[i]);
			if (ret == -1)
				gr_TextMsgOut("Error in saving Animation image!\n");
			else
				gr_TextMsgOut("Saved ");
		}
		remTime = (long)((td_CurrentTime()-startTime)/(j+1.0)*
						 (numplanes-j-1.0));
		sprintf(strng,"Generated frame %d, %5lds to completion...\n",
							j,remTime);
		gr_TextMsgOut(strng);
	}

	if (tmp->useDisk == TRUE)
		gr_AniDrawLoad(dpy,win,tmp,0);
	else
		gr_AniDrawImage(dpy,win,tmp,0);

	tmp->parent	= tparent;
	tmp->arbparent = NULL;
	tmp->prev	= NULL;
	tmp->next	= header;
	if (header != NULL)
		header->prev = tmp;

	if (tmp->gridOn == TRUE)
		gr_AniDrawGrid(tmp);

	gr_WidgetCursor(tmp->shell,XC_draped_box);
	gr_WidgetCursor(tparent->shell,XC_draped_box);

	return(tmp);
}


/*
 * Animate along arbitrary axes
BUGS:
	If the user presses the 'Animate' button, closes the animation window
and then opens it again, the box struct will be different. This results in
fewer planes being generated. (Only one plane the second time in).
 */
A_AniWind_t
*gr_InitAniLevel3(header,shellName,parent,numplanes,zincr,scale,tparent,pathname)
A_AniWind_t *header;
char   	 *shellName;
Widget	 parent;
int		 numplanes,scale;
double	 zincr;
A_ArbWind_t	*tparent;
char	 *pathname;
{
	A_BossWind_t	*bossWin=tparent->parent;
	A_AniWind_t		*tmp;
	A_Box_t			*box=tparent->xybox;
	Widget			boxWind;
	int			winxsize, winysize, xsize,ysize,numFrames,
				fileexist,ret;
	short			i,j;
	long			startTime,remTime;
	char			label[MAXNAMELEN],strng[MAXNAMELEN];
	double			useDepth,startInDepth;
	Boolean			quit = FALSE;
	XGCValues		gcvals;
	Display			*dpy;
	Window			win;
	pixelMapping	*mapping = &(tparent->mapping);

	gr_WidgetCursor(tparent->shell,XC_watch);

	tmp = aniInit0(tparent->usePixmap, tparent->useDisk, FALSE,
		pathname, numplanes, &numFrames);
	if(tmp == NULL)
		return NULL;

	tmp->aniType = 3;

	bossWin->data->scale = scale;

	xsize = (int)(((int)box->xmax-(int)box->xmin)*scale);
	ysize = (int)(((int)box->ymax-(int)box->ymin)*scale);
	if (xsize > MINWINXSIZE)
		if (xsize > MAXWINXSIZE)
			winxsize = MAXWINXSIZE;
		else
			winxsize = xsize+LEEWAY;
	else
		winxsize = MINWINXSIZE+LEEWAY;

	if (ysize > MINWINYSIZE)
		if (ysize > MAXWINYSIZE)
			winysize = MAXWINYSIZE;
		else
			winysize = ysize+LEEWAY;
	else
		winysize = MINWINYSIZE+LEEWAY;

	startInDepth = (double)box->indepth;

	i = 0; quit = FALSE;
	while ((i< numplanes) && (quit == FALSE))
	{
		useDepth = (double)i*zincr+startInDepth;
		if (useDepth < 100.0)
			i++;
		else
			quit = TRUE;
	}

	if (numplanes > i)
	{
	sprintf(strng,"Warning: Only %d frames can be generated.\n", i);
	gr_TextMsgOut(strng);
		tmp->numplanes = i;	/* Update for Close. */
	}

	numplanes = i;

	sprintf(label,"%s: Animate %d planes",tparent->parent->filename,
			numplanes);

	boxWind = gr_MakeAniControls( shellName, parent,  bossWin->data,
		label, tmp, 275,134, numplanes, FALSE);

	dpy = XtDisplay(tmp->imageWin);
	win = XtWindow(tmp->imageWin);
	gcvals.foreground = BlackPixel(dpy,DefaultScreen(dpy));
	tmp->imageWinGC = XtGetGC(tmp->imageWin, GCForeground, &gcvals);
	XSetTSOrigin(dpy,tmp->imageWinGC,0,0);
	XSetFillStyle(dpy,tmp->imageWinGC,FillTiled);


	startTime = td_CurrentTime();

	i = 0;
	for (j=0;j<numplanes;j++)
	{
		if (tmp->useDisk == FALSE)
			i=j;

		useDepth = (double)j*zincr+startInDepth;
		gr_ArbZSliderSel(tparent->zSlider,(caddr_t)tparent,
			(caddr_t)100-(int)useDepth);
		tmp->imagexsize[i] = xsize;
		tmp->imageysize[i] = ysize;
		if ((tmp->useDisk == TRUE) && (j > 0))
		{
			td_Free((char *)tmp->data[0]);
			if (tmp->usePixmap == TRUE)
				XFreePixmap(dpy,tmp->image[0]);
			else
			XDestroyImage(tmp->ximage[0]);
		}
		tmp->data[i] = gr_ViewgetData(box,scale,2,bossWin, mapping);
		if (tmp->usePixmap == TRUE)
		{
		tmp->image[i] = gr_PixmapCreate(tmp->imageWin,tmp->imageWinGC,
					tmp->xorg,tmp->yorg,
					tmp->imagexsize[i],
					tmp->imageysize[i],tmp->data[i]);
		}
		else
		{
		tmp->ximage[i] = gr_ImageCreate(tmp->imageWin,
					tmp->imagexsize[i],
					tmp->imageysize[i],tmp->data[i]);
		}
		gr_AniDrawImage(dpy,win,tmp,i);

		if (tmp->useDisk == TRUE)
		{
			fileexist = td_FileExist(pathname);

			if (fileexist == 0)
				ret = td_HdfPutImage(pathname,tmp->data[i],gr_color.palette,
				tmp->imagexsize[i],tmp->imageysize[i]);
			else
				ret = td_HdfAddImage(pathname,tmp->data[i],gr_color.palette,
				tmp->imagexsize[i],tmp->imageysize[i]);
			if (ret == -1)
				gr_TextMsgOut("Error in saving Animation image!\n");
			else
				gr_TextMsgOut("Saved ");
		}
		remTime = (long)((td_CurrentTime()-startTime)/(j+1.0)*
						 (numplanes-j-1.0));
		sprintf(strng,"Generated frame %d, %5lds to completion...\n",j,remTime);
		gr_TextMsgOut(strng);
	}

	if (tmp->useDisk == TRUE)
		gr_AniDrawLoad(dpy,win,tmp,0);
	else
		gr_AniDrawImage(dpy,win,tmp,0);

	tmp->arbparent	= tparent;
	tmp->parent		= NULL;
	tmp->prev	= NULL;
	tmp->next	= header;
	if (header != NULL)
		header->prev = tmp;

	gr_WidgetCursor(tmp->shell,XC_draped_box);
	gr_WidgetCursor(tparent->shell,XC_draped_box);

	return(tmp);
}

/* ------------------------------------------------------------------ */
#define MAXCONLEVELS 50

/* begin to generate the contours for a RASTER */

void gr_Anibegincontour ( w, client_data, call_data)
Widget	w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_HistWind_t   *histWin  = (A_HistWind_t *)client_data;
	A_AniWind_t    * aWin = (A_AniWind_t*) histWin->parent;
	long i;
	float *im;
	int nx,ny;
   int curplane;
	unsigned char * rasterdata;
	float clevels[MAXCONLEVELS];
   int nlev;
	char word[80], *ss;

	curplane = aWin->curplane;
   nx = aWin->imagexsize[curplane];
   ny = aWin->imageysize[curplane];
	rasterdata = (unsigned char*) aWin->data[curplane];

	if(NULL== (im = (float*) malloc(sizeof(float)*nx*ny))) 
	{ printf("Aniocontour malloc error for image to print\n"); return; }
	
	/* convert raster image to a float array so that dumppscontour can use */
/*
	for(i=0;i<nx*ny;i++) im[i] = (float) (rasterdata[i] * 1.0); 
*/
	for(i=0;i<nx*ny;i++) im[i] = ((float)rasterdata[i] * 1.0); 

	/* ---------------------- */	
      nlev =  20;
      for(i=0;i<nlev;i++) clevels[i] = i*13.5; /* must not be exact integer */
	  ss = gr_DialogGetValue(histWin->conDialog);
  	 i=0;
  	 str_setstring(ss);
  	 while(str_getnextword(word)) {
      if (sscanf(word,"%f",&clevels[i])) { i++; }
      if (i>=MAXCONLEVELS) break;
      }
   nlev = i;
	/* ---------------------- */	

	gr_WidgetCursor(aWin->shell,XC_watch);

  	gr_TextMsgOut ("Wait - CONTOURING Raster..."); beep();

  	gr_MakeContourLines (im, nx, ny, 1, 1, clevels, nlev);
  	gr_DrawContourLines (aWin->imageWin ); /* draw contour over image */
  	gr_TextMsgOut ("done.\n "); beep();

	gr_WidgetCursor(aWin->shell,XC_draped_box);

	free (im);
  printcontour();

}

/* ------------------------------------------------------------------ */
/* jng 23-feb-91 */

void gr_RasterImagePrint( w, client_data, call_data)
Widget	w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_AniWind_t	*aWin=(A_AniWind_t *)client_data;
	long i;
	float *im;
	int nx,ny;
   int curplane;
	unsigned char * rasterdata;
	char title[100];

	curplane = aWin->curplane;
   nx = aWin->imagexsize[curplane];
   ny = aWin->imageysize[curplane];
	rasterdata = (unsigned char*) aWin->data[curplane];

	gr_WidgetCursor(aWin->shell,XC_watch);

	if(NULL== (im = (float*) malloc(sizeof(float)*nx*ny))) 
	{ printf("Raster Print malloc error for image to print\n"); return; }
	
	/* convert raster image to a float array so that dumppsimage can use */
/*
	for(i=0;i<nx*ny;i++) im[i] = (float) (rasterdata[i] * 1.0); 
*/
	for(i=0;i<nx*ny;i++) im[i] =  ((float)rasterdata[i] * 1.0); 

	sprintf(title,"RASTER: %s",aWin->pathname);

   /* dumppsimage (im, nx, ny,  1, 1,  0.0,  255.0, title); */
   dumppsCOLORimage (im, nx, ny, 1,1, 0.0, 255.0, title, gr_color.palette);
   free (im);

	gr_WidgetCursor(aWin->shell,XC_draped_box);
	beep();
}

/* ------------------------------------------------------------------ */
/*
 *	Animate from stored raster images
*  also have a print button jng 23-feb-91
 */
#define MYEXTRA  26 /* for print button jng 23-feb-91 */

A_AniWind_t
*gr_InitAniLevel2(header,filename,pathname,parent,start,stop,numplanes,
	xsize,ysize,ispal,usePixmap,useDisk)
A_AniWind_t *header;
char   	 *filename,*pathname;
Widget	 parent;
int		 start,stop,numplanes,xsize,ysize,ispal;
Boolean	 usePixmap,useDisk;
{
	A_AniWind_t	*tmp;
	Widget		boxWind;
	short		i,j,winxsize,winysize,numFrames,frameStop;
	char		label[MAXNAMELEN],strng[MAXNAMELEN];
	XGCValues	gcvals;
	Display		*dpy;
	Window		win;
	Boolean     noCMap=TRUE;

	gr_WidgetCursor(gr_topWin.shell,XC_watch);

	tmp = (A_AniWind_t *)td_Malloc(sizeof(A_AniWind_t),"A_AniWind_t");
	if(tmp == NULL)
	{	gr_TextMsgOut("Could not allocate memory for animation.\n");
		return NULL;
	}

	sprintf(label,"Animate %d planes from %s",numplanes,filename);

	tmp->gridOn = FALSE;
	tmp->usePixmap = usePixmap;
	tmp->useDisk = useDisk;
	tmp->xorg = tmp->yorg = 0;

	if(pathname == NULL)
		tmp->pathname = NULL;
	else
	{	tmp->pathname = (char *)td_Malloc1D(1,strlen(pathname)+1,
			sizeof(char), "td_Malloc1D");
		strcpy(tmp->pathname,pathname);
	}
	if (tmp->useDisk == TRUE)
	{
		numFrames = 1;
		frameStop = start;
	}
	else
	{
		numFrames = numplanes;
		frameStop = stop;
	}
	tmp->imagexsize = (int *)td_Malloc1D(1,numFrames,sizeof(int),
		"td_Malloc1D");
	if (tmp->imagexsize == NULL)
	{	anioops(tmp);
		return NULL;
	}
	tmp->imageysize = (int *)td_Malloc1D(1,numFrames,sizeof(int),
		"td_Malloc1D");
	if (tmp->imageysize == NULL)
	{	anioops(tmp);
		return NULL;
	}

	if (xsize > MINWINXSIZE)
		if (xsize > MAXWINXSIZE)
			winxsize = MAXWINXSIZE;
		else
			winxsize = xsize+LEEWAY;
	else
		winxsize = MINWINXSIZE+LEEWAY;

	if (ysize > MINWINYSIZE)
		if (ysize > MAXWINYSIZE)
			winysize = MAXWINYSIZE;
		else
			winysize = ysize+LEEWAY;
	else
		winysize = MINWINYSIZE+LEEWAY;

	boxWind = gr_MakeAniControls("Animate RAster", parent, NULL,label, tmp,
		winxsize, winysize,numplanes, TRUE);

	tmp->data = (char **)td_Malloc2D(1,numFrames,sizeof(char *),"td_Malloc2D");
	if(tmp->data == NULL)
	{	anioops(tmp);
		return NULL;
	}
	if (tmp->usePixmap == TRUE)
	{	tmp->image = (Pixmap *)td_Malloc1D(1,numFrames,sizeof(Pixmap),
			"td_Malloc1D");
		if(tmp->image == NULL)
		{	anioops(tmp);
			return NULL;
		}
	}
	else
	{	tmp->ximage =
			(XImage **)td_Malloc1D(1,numFrames,sizeof(XImage *),
						"td_Malloc1D");
		if(tmp->ximage == NULL)
		{	anioops(tmp);
			return NULL;
		}
	}

	dpy = XtDisplay(tmp->imageWin);
	win = XtWindow(tmp->imageWin);
	gcvals.foreground = BlackPixel(dpy,DefaultScreen(dpy));
	gcvals.background = WhitePixel(dpy,DefaultScreen(dpy));
	tmp->imageWinGC = XtGetGC(tmp->imageWin,
		GCForeground|GCBackground, &gcvals);
	XSetTSOrigin(dpy,tmp->imageWinGC,0,0);
	XSetFillStyle(dpy,tmp->imageWinGC,FillTiled);
	tmp->aniType = 2;
	tmp->playStop = 1;
	tmp->autoMode = AUTOOFF;
	tmp->curplane = 0;
	tmp->skip = 0;
	tmp->speed = 0;
	tmp->numplanes = numplanes;
	tmp->contourWin = NULL;

	for (j=0;j<start;j++) {
	   td_HdfgetRasData(pathname,gr_color.palette,
			&(tmp->imagexsize[0]),&(tmp->imageysize[0]),&ispal,FALSE);
			}

    i = 0;
	for (j=start;j<=frameStop;j++)
	{
		tmp->data[i] = td_HdfgetRasData(pathname,gr_color.palette,
				&(tmp->imagexsize[i]),&(tmp->imageysize[i]),&ispal,TRUE);
		
	    if ((ispal == 1) && (noCMap))
		{
		    gr_ImageInitCMapHDF(gr_color.palette);
			gr_ImageSetCMap(tmp->shell);
			noCMap = FALSE;
		}
		if (tmp->usePixmap == TRUE)
		{
		tmp->image[i] = gr_PixmapCreate(tmp->imageWin,tmp->imageWinGC,
						tmp->xorg,tmp->yorg,
						tmp->imagexsize[i],tmp->imageysize[i],tmp->data[i]);
		}
		else
		{
		tmp->ximage[i] = gr_ImageCreate(tmp->imageWin,
						tmp->imagexsize[i],tmp->imageysize[i],tmp->data[i]);
		}
		gr_AniDrawImage(dpy,win,tmp,i);
		i++;
	}

	if (tmp->useDisk == FALSE)
	{
		gr_AniDrawImage(dpy,win,tmp,0);
	}
	sprintf(strng,"First frame ID= %d, Last frame ID= %d\n",start,stop);
	gr_TextMsgOut(strng);
	sprintf(strng,"Dimensions of first frame= %dx%d.\n",
		tmp->imagexsize[0],tmp->imageysize[0]);
	gr_TextMsgOut(strng);

	tmp->parent = NULL;
	tmp->arbparent = NULL;
	tmp->prev 	= NULL;
	tmp->next	= header;
	if (header != NULL)
		header->prev = tmp;

	gr_WidgetCursor(tmp->shell,XC_draped_box);
	gr_WidgetCursor(gr_topWin.shell,XC_draped_box);

	return(tmp);
}


/*
 *	Close animation windows
 */
void
gr_CloseAniLevel(w, client_data, call_data)
Widget	w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_AniWind_t	*aniWin=(A_AniWind_t *)client_data;
	Display		*dpy=XtDisplay(aniWin->imageWin);
	short i,numFrames;

	if (aniWin != NULL)
	{
		if (aniWin->playStop == 0)
		{
			/* stop the playing first */
			aniWin->playStop = 1;
			return;
		}

		/* update previous neighbour's pointer */
        if (aniWin->prev != NULL)
            aniWin->prev->next = aniWin->next;
        else
		{
			/* update parent of aniWin */
			switch (aniWin->aniType)
			{
				case 1:
            		aniWin->parent->aniWin = aniWin->next;
        			aniWin->parent->numAniWins--;
					break;
				case 2:
					gr_topWin.aniWin = aniWin->next;
					gr_topWin.numAniWins--;
					break;
				case 3:
            		aniWin->arbparent->aniWin = aniWin->next;
        			aniWin->arbparent->numAniWins--;
					break;
			}
		}

		/* update next neighbour's pointer */
        if (aniWin->next != NULL)
            aniWin->next->prev = aniWin->prev;

		if (aniWin->useDisk == TRUE)
			numFrames = 1;
		else
			numFrames = aniWin->numplanes;

		if (aniWin->usePixmap == TRUE)
			gr_TextMsgOut("Freeing Pixmaps... ");
		else
			gr_TextMsgOut("Freeing XImages... ");

		for (i=0;i<numFrames;i++)
		{
			if (aniWin->usePixmap == TRUE)
			{	/* Was trying to free non existent pixmaps.
				   May have been fixed when tmp->numplanes was
				   to 'i' in initlevel3 above.
				*/
				if(aniWin->image[i] != 0)
					XFreePixmap(dpy,aniWin->image[i]);
			}
			else
			{
				XDestroyImage(aniWin->ximage[i]);
				td_Free((char *)aniWin->ximage[i]);
			}
			td_Free((char *)aniWin->data[i]);
		}
		if (aniWin->usePixmap == TRUE)
			td_Free((char *)aniWin->image);
		else
			td_Free((char *)aniWin->ximage);
		td_Free((char *)aniWin->data);
		td_Free((char *)aniWin->imagexsize);
		td_Free((char *)aniWin->imageysize);
		XtReleaseGC(aniWin->imageWin,aniWin->imageWinGC);
		XtDestroyWidget(aniWin->shell);
     	/* free contour window if necc */
         if (aniWin->contourWin != NULL) {
          	gr_AniClosecontourdialog (NULL, aniWin->contourWin, NULL);
           	aniWin->contourWin = NULL;
           	}

		td_Free((char *)aniWin);
		gr_TextMsgOut("Done.\n");
	}
}
