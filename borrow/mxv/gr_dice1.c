/*
 *	File:		gr_dice1.c
 *	Contents:	Dicer level routines for graphics module
 */

#include <math.h>
#include "gr_com.h"

extern	void	gr_DiceDraw();
extern	void	gr_DiceDrawSlice();
extern	void	gr_PaletteShade();

/*
 *	Round off a double number to nearest integer.  Some systems do
 *	not have this function.
 */
double
gr_rint(x)
double x;
{
	int ix=x;
	double r=x-ix;

	if (r < 0.5)
		return((double)ix);
	else
		return((double)(ix+1));
}

# ifndef NO_DICER

/*
 *	Calculate slice for X cutting edge
 */
void
gr_DiceXCalc(diceWin,xsplane,xfplane)
A_DiceWind_t *diceWin;
int	xsplane,xfplane;
{
	int tmp,xwidth,ywidth,zwidth;
	int	ysplane,yfplane,zsplane,zfplane;

	diceWin->planeType = 1;
	diceWin->sliced = FALSE;

	if (xsplane < 0) xsplane = 0; else
	if (xsplane > diceWin->xdim-1) xsplane = diceWin->xdim-1;
	if (xfplane < 0) xfplane = 0; else
	if (xfplane > diceWin->xdim-1) xfplane = diceWin->xdim-1;
	diceWin->xsplane = xsplane;
	diceWin->xfplane = xfplane;

	sprintf(msg,"%d",xsplane);
	gr_DialogSetValue(diceWin->splaneDialog,msg);
	sprintf(msg,"%d",xfplane);
	gr_DialogSetValue(diceWin->fplaneDialog,msg);

	if (diceWin->dicer == FALSE)
	{
		diceWin->ysplane = ysplane = 0; 
		diceWin->yfplane = yfplane = diceWin->ydim-1;
		diceWin->zsplane = zsplane = 0; 
		diceWin->zfplane = zfplane = diceWin->zdim-1;
	}
	else
	{
		ysplane = diceWin->ysplane; yfplane = diceWin->yfplane;
		zsplane = diceWin->zsplane; zfplane = diceWin->zfplane;
	}

	if (xsplane > xfplane)
	{ tmp = xsplane; xsplane = xfplane; xfplane= tmp; }
	if (ysplane > yfplane)
	{ tmp = ysplane; ysplane = yfplane; yfplane= tmp; }
	if (zsplane > zfplane)
	{ tmp = zsplane; zsplane = zfplane; zfplane= tmp; }

	xwidth = (xfplane-xsplane+1)*diceWin->scale;
	ywidth = (yfplane-ysplane+1)*diceWin->scale;
	zwidth = (zfplane-zsplane+1)*diceWin->scale;
	xsplane = xsplane*diceWin->scale;
	ysplane = ysplane*diceWin->scale; 
	zsplane = zsplane*diceWin->scale; 

	diceWin->slice[0].x = diceWin->org+xsplane+zsplane;
	diceWin->slice[0].y = diceWin->ysize-(diceWin->org+ysplane+zsplane);
	diceWin->slice[1].x = diceWin->slice[0].x+zwidth;
	diceWin->slice[1].y = diceWin->slice[0].y-zwidth;
	diceWin->slice[2].x = diceWin->slice[1].x;
	diceWin->slice[2].y = diceWin->slice[1].y-ywidth;
	diceWin->slice[3].x = diceWin->slice[0].x;
	diceWin->slice[3].y = diceWin->slice[0].y-ywidth;

	diceWin->slice[4].x = diceWin->slice[0].x+xwidth;
	diceWin->slice[4].y = diceWin->slice[0].y;
	diceWin->slice[5].x = diceWin->slice[1].x+xwidth;
	diceWin->slice[5].y = diceWin->slice[1].y;
	diceWin->slice[6].x = diceWin->slice[2].x+xwidth;
	diceWin->slice[6].y = diceWin->slice[2].y;
	diceWin->slice[7].x = diceWin->slice[3].x+xwidth;
	diceWin->slice[7].y = diceWin->slice[3].y;
}


/*
 *	Calculate slice for Y cutting edge
 */
void
gr_DiceYCalc(diceWin,ysplane,yfplane)
A_DiceWind_t *diceWin;
int	ysplane,yfplane;
{
	int tmp,xwidth,ywidth,zwidth;
	int	xsplane,xfplane,zsplane,zfplane;

	diceWin->planeType = 2;
	diceWin->sliced = FALSE;
	
	if (ysplane < 0) ysplane = 0; else
	if (ysplane > diceWin->ydim-1) ysplane = diceWin->ydim-1;
	if (yfplane < 0) yfplane = 0; else
	if (yfplane > diceWin->ydim-1) yfplane = diceWin->ydim-1;
	diceWin->ysplane = ysplane;
	diceWin->yfplane = yfplane;

	sprintf(msg,"%d",ysplane);
	gr_DialogSetValue(diceWin->splaneDialog,msg);
	sprintf(msg,"%d",yfplane);
	gr_DialogSetValue(diceWin->fplaneDialog,msg);

	if (diceWin->dicer == FALSE)
	{
		diceWin->xsplane = xsplane = 0;
		diceWin->xfplane = xfplane = diceWin->xdim-1;
		diceWin->zsplane = zsplane = 0;
		diceWin->zfplane = zfplane = diceWin->zdim-1;
	}
	else
	{
		xsplane = diceWin->xsplane; xfplane = diceWin->xfplane;
		zsplane = diceWin->zsplane; zfplane = diceWin->zfplane;
	}

	if (xsplane > xfplane)
	{ tmp = xsplane; xsplane = xfplane; xfplane= tmp; }
	if (ysplane > yfplane)
	{ tmp = ysplane; ysplane = yfplane; yfplane= tmp; }
	if (zsplane > zfplane)
	{ tmp = zsplane; zsplane = zfplane; zfplane= tmp; }

	xwidth = (xfplane-xsplane+1)*diceWin->scale;
	ywidth = (yfplane-ysplane+1)*diceWin->scale;
	zwidth = (zfplane-zsplane+1)*diceWin->scale;
	xsplane = xsplane*diceWin->scale;
	ysplane = ysplane*diceWin->scale; 
	zsplane = zsplane*diceWin->scale; 

	diceWin->slice[0].x = diceWin->org+xsplane+zsplane;
	diceWin->slice[0].y = diceWin->ysize-(diceWin->org+ysplane+zsplane);
	diceWin->slice[1].x = diceWin->slice[0].x+zwidth;
	diceWin->slice[1].y = diceWin->slice[0].y-zwidth;
	diceWin->slice[2].x = diceWin->slice[1].x+xwidth;
	diceWin->slice[2].y = diceWin->slice[1].y;
	diceWin->slice[3].x = diceWin->slice[0].x+xwidth;
	diceWin->slice[3].y = diceWin->slice[0].y;

	diceWin->slice[4].x = diceWin->slice[0].x;
	diceWin->slice[4].y = diceWin->slice[0].y-ywidth;
	diceWin->slice[5].x = diceWin->slice[1].x;
	diceWin->slice[5].y = diceWin->slice[1].y-ywidth;
	diceWin->slice[6].x = diceWin->slice[2].x;
	diceWin->slice[6].y = diceWin->slice[2].y-ywidth;
	diceWin->slice[7].x = diceWin->slice[3].x;
	diceWin->slice[7].y = diceWin->slice[3].y-ywidth;
}


/*
 *	Calculate slice for Z cutting edge
 */
void
gr_DiceZCalc(diceWin,zsplane,zfplane)
A_DiceWind_t *diceWin;
int	zsplane,zfplane;
{
	int tmp,xwidth,ywidth,zwidth;
	int	xsplane,xfplane,ysplane,yfplane;

	diceWin->planeType = 3;
	diceWin->sliced = FALSE;

	if (zsplane < 0) zsplane = 0; else
	if (zsplane > diceWin->zdim-1) zsplane = diceWin->zdim-1;
	if (zfplane < 0) zfplane = 0; else
	if (zfplane > diceWin->zdim-1) zfplane = diceWin->zdim-1;
	diceWin->zsplane = zsplane;
	diceWin->zfplane = zfplane;

	sprintf(msg,"%d",zsplane);
	gr_DialogSetValue(diceWin->splaneDialog,msg);
	sprintf(msg,"%d",zfplane);
	gr_DialogSetValue(diceWin->fplaneDialog,msg);

	if (diceWin->dicer == FALSE)
	{
		diceWin->xsplane = xsplane = 0;
		diceWin->xfplane = xfplane = diceWin->xdim-1;
		diceWin->ysplane = ysplane = 0;
		diceWin->yfplane = yfplane = diceWin->ydim-1;
	}
	else
	{
		xsplane = diceWin->xsplane; xfplane = diceWin->xfplane;
		ysplane = diceWin->ysplane; yfplane = diceWin->yfplane;
	}

	if (xsplane > xfplane)
	{ tmp = xsplane; xsplane = xfplane; xfplane= tmp; }
	if (ysplane > yfplane)
	{ tmp = ysplane; ysplane = yfplane; yfplane= tmp; }
	if (zsplane > zfplane)
	{ tmp = zsplane; zsplane = zfplane; zfplane= tmp; }

	xwidth = (xfplane-xsplane+1)*diceWin->scale;
	ywidth = (yfplane-ysplane+1)*diceWin->scale;
	zwidth = (zfplane-zsplane+1)*diceWin->scale;
	xsplane = xsplane*diceWin->scale;
	ysplane = ysplane*diceWin->scale; 
	zsplane = zsplane*diceWin->scale; 

	diceWin->slice[0].x = diceWin->org+zsplane+xsplane;
	diceWin->slice[0].y = diceWin->ysize-(diceWin->org+zsplane+ysplane);
	diceWin->slice[1].x = diceWin->slice[0].x+xwidth;
	diceWin->slice[1].y = diceWin->slice[0].y;
	diceWin->slice[2].x = diceWin->slice[1].x;
	diceWin->slice[2].y = diceWin->slice[1].y-ywidth;
	diceWin->slice[3].x = diceWin->slice[0].x;
	diceWin->slice[3].y = diceWin->slice[2].y;

	diceWin->slice[4].x = diceWin->slice[0].x+zwidth;
	diceWin->slice[4].y = diceWin->slice[0].y-zwidth;
	diceWin->slice[5].x = diceWin->slice[1].x+zwidth;
	diceWin->slice[5].y = diceWin->slice[1].y-zwidth;
	diceWin->slice[6].x = diceWin->slice[2].x+zwidth;
	diceWin->slice[6].y = diceWin->slice[2].y-zwidth;
	diceWin->slice[7].x = diceWin->slice[3].x+zwidth;
	diceWin->slice[7].y = diceWin->slice[3].y-zwidth;
}


/*
 *	Get start cutting plane when X-slider is selected
 */
void
gr_DiceXSliderSel(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_DiceWind_t *diceWin=(A_DiceWind_t *)client_data;
	int			 plane=(int)call_data;

	gr_SliderSetValue(w,plane);

	if (diceWin->sliced == FALSE)
		gr_DiceDrawSlice(diceWin);

	if (diceWin->dicer == FALSE)
		gr_DiceXCalc(diceWin,plane,plane);
	else
	{
		if (diceWin->xsplane > diceWin->xfplane)
		gr_DiceXCalc(diceWin,plane,plane-(diceWin->xsplane-diceWin->xfplane));
		else
		gr_DiceXCalc(diceWin,plane,plane+(diceWin->xfplane-diceWin->xsplane));
	}
	gr_DiceDraw(diceWin);
}


/*
 *	Move end cutting plane when X-slider is moved
 */
void
gr_DiceXSliderMov(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_DiceWind_t *diceWin=(A_DiceWind_t *)client_data;
	int			 fplane=(int)call_data,splane;

	if (diceWin->sliced == FALSE)
		gr_DiceDrawSlice(diceWin);

	splane = diceWin->xsplane;
	gr_DiceXCalc(diceWin,splane,fplane);

	gr_DiceDraw(diceWin);
}


/*
 *	Get start cutting plane when Y-slider is selected
 */
void
gr_DiceYSliderSel(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_DiceWind_t *diceWin=(A_DiceWind_t *)client_data;
	int			 plane=diceWin->ydim-(int)call_data-1;

	gr_SliderSetValue(w,(int)call_data);

	if (diceWin->sliced == FALSE)
		gr_DiceDrawSlice(diceWin);

	if (diceWin->dicer == FALSE)
		gr_DiceYCalc(diceWin,plane,plane);
	else
	{
		if (diceWin->ysplane > diceWin->yfplane)
		gr_DiceYCalc(diceWin,plane,plane-(diceWin->ysplane-diceWin->yfplane));
		else
		gr_DiceYCalc(diceWin,plane,plane+(diceWin->yfplane-diceWin->ysplane));
	}

	gr_DiceDraw(diceWin);
}


/*
 *	Move end cutting plane when Y-slider is moved
 */
void
gr_DiceYSliderMov(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_DiceWind_t *diceWin=(A_DiceWind_t *)client_data;
	int			 fplane=diceWin->ydim-(int)call_data-1,splane;

	if (diceWin->sliced == FALSE)
		gr_DiceDrawSlice(diceWin);

	splane = diceWin->ysplane;
	gr_DiceYCalc(diceWin,splane,fplane);
	gr_DiceDraw(diceWin);
}


/*
 *	Get start cutting plane when Z-slider is selected
 */
void
gr_DiceZSliderSel(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_DiceWind_t *diceWin=(A_DiceWind_t *)client_data;
	int			 plane=(int)call_data;

	gr_SliderSetValue(w,plane);

	if (diceWin->sliced == FALSE)
		gr_DiceDrawSlice(diceWin);

	if (diceWin->dicer == FALSE)
		gr_DiceZCalc(diceWin,plane,plane);
	else
	{
		if (diceWin->zsplane > diceWin->zfplane)
		gr_DiceZCalc(diceWin,plane,plane-(diceWin->zsplane-diceWin->zfplane));
		else
		gr_DiceZCalc(diceWin,plane,plane+(diceWin->zfplane-diceWin->zsplane));
	}

	gr_DiceDraw(diceWin);
}


/*
 *	Move end cutting plane when Z-slider is moved
 */
void
gr_DiceZSliderMov(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_DiceWind_t *diceWin=(A_DiceWind_t *)client_data;
	int			 fplane=(int)call_data,splane;

	if (diceWin->sliced == FALSE)
		gr_DiceDrawSlice(diceWin);

	splane = diceWin->zsplane;

	gr_DiceZCalc(diceWin,splane,fplane);
	gr_DiceDraw(diceWin);
}

/*
 *	Decrement contrast shading
 */
void
gr_DiceShadeLight(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_DiceWind_t *diceWin=(A_DiceWind_t *)client_data;
	int			 shade;

	shade=gr_SliderGetValue(diceWin->shadeSlider);
	/* 'granularity' here might be a resource. */
	if (shade>100)
		shade-=100;
	else
		shade=0;

	gr_SliderSetValue(diceWin->shadeSlider,shade);
	gr_PaletteShade(shade);
	gr_ImageSetCMapSplit(diceWin->shell);

	return;
}


/*
 *	Increment contrast shading
 */
void
gr_DiceShadeDark(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_DiceWind_t *diceWin=(A_DiceWind_t *)client_data;
	int			 shade;

	shade=gr_SliderGetValue(diceWin->shadeSlider);

	if (shade<9900)
		shade+=100;
	else
		shade=10000;

	gr_SliderSetValue(diceWin->shadeSlider,shade);
	gr_PaletteShade(shade);
	gr_ImageSetCMapSplit(diceWin->shell);

	return;
}


/*
 *	Set contrast shading when shade slider is selected
 */
void
gr_DiceShadeSel(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_DiceWind_t *diceWin=(A_DiceWind_t *)client_data;
	int			 shade=(int)call_data;

	gr_SliderSetValue(w,shade);
	gr_PaletteShade(shade);
	gr_ImageSetCMapSplit(diceWin->shell);
}


/*
 *	Change contrast shading when shade slider is moved
 */
void
gr_DiceShadeMov(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_DiceWind_t *diceWin=(A_DiceWind_t *)client_data;
	int			 shade=(int)call_data;

	gr_PaletteShade(shade);
	gr_ImageSetCMapSplit(diceWin->shell);
}


/*
 *	Set to X cutting edge when X-toggle is selected
 */
void
gr_DiceSetX(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_DiceWind_t *diceWin=(A_DiceWind_t *)client_data;
	int			 splane,fplane;

	if(!gr_is_toggle_set(w))
		return;
	splane = diceWin->xsplane;
	fplane = diceWin->xfplane;

	if (diceWin->sliced == FALSE)
		gr_DiceDrawSlice(diceWin);
	gr_DiceXCalc(diceWin,splane,fplane);
	gr_DiceDraw(diceWin);

	return;
}


/*
 *	Set to Y cutting edge when Y-toggle is selected
 */
void
gr_DiceSetY(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_DiceWind_t *diceWin=(A_DiceWind_t *)client_data;
	int			 splane,fplane;

	if(!gr_is_toggle_set(w))
		return;
	splane = diceWin->ysplane;
	fplane = diceWin->yfplane;

	if (diceWin->sliced == FALSE)
		gr_DiceDrawSlice(diceWin);
	gr_DiceYCalc(diceWin,splane,fplane);
	gr_DiceDraw(diceWin);

	return;
}


/*
 *	Set to Z cutting edge when Z-toggle is selected
 */
void
gr_DiceSetZ(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_DiceWind_t *diceWin=(A_DiceWind_t *)client_data;
	int			 splane,fplane;

	if(!gr_is_toggle_set(w))
		return;
	splane = diceWin->zsplane;
	fplane = diceWin->zfplane;

	if (diceWin->sliced == FALSE)
		gr_DiceDrawSlice(diceWin);
	gr_DiceZCalc(diceWin,splane,fplane);
	gr_DiceDraw(diceWin);

	return;
}


/*
 *	Set cutting planes to dialogs
 */
void
gr_DiceSetPlanes(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_DiceWind_t *diceWin=(A_DiceWind_t *)client_data;
	int			 splane,fplane;

	splane = atoi(gr_DialogGetValue(diceWin->splaneDialog));
	fplane = atoi(gr_DialogGetValue(diceWin->fplaneDialog));

	if (diceWin->sliced == FALSE)
		gr_DiceDrawSlice(diceWin);

	if (diceWin->planeType == 1)
	{
		if (splane < 0) splane = 0; else
		if (splane > diceWin->xdim-1) splane = diceWin->xdim-1;
		if (fplane < 0) fplane = 0; else
		if (fplane > diceWin->xdim-1) fplane = diceWin->xdim-1;

		gr_SliderSetValue(diceWin->xSlider,fplane);
		gr_DiceXCalc(diceWin,splane,fplane);
	}
	else
	if (diceWin->planeType == 2)
	{
		if (splane < 0) splane = 0; else
		if (splane > diceWin->ydim-1) splane = diceWin->ydim-1;
		if (fplane < 0) fplane = 0; else
		if (fplane > diceWin->ydim-1) fplane = diceWin->ydim-1;

		gr_SliderSetValue(diceWin->ySlider,(diceWin->ydim-fplane-1));
		gr_DiceYCalc(diceWin,splane,fplane);
	}
	else
	{
		if (splane < 0) splane = 0; else
		if (splane > diceWin->zdim-1) splane = diceWin->zdim-1;
		if (fplane < 0) fplane = 0; else
		if (fplane > diceWin->zdim-1) fplane = diceWin->zdim-1;

		gr_SliderSetValue(diceWin->zSlider,fplane);
		gr_DiceZCalc(diceWin,splane,fplane);
	}

	gr_DiceDraw(diceWin);

	return;
}

/*
 *	Turn on Dicing device
 */
void
gr_DiceSetDicerOnToggle(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_DiceWind_t *diceWin=(A_DiceWind_t *)client_data;

	diceWin->dicer = gr_is_toggle_set(w);
}

#endif /* NO_DICER */
