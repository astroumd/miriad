/*
 *	File:		gr_subs.c
 *	Contents:	Substance level routines for graphics module
 */

#include <math.h>
#include "gr_com.h"

extern	double	gr_VbuffgetIntensity();
extern	double	gr_VbuffgetOpacity();
extern	double	gr_VbuffgetAtten();
extern	void	gr_VbuffIntegrate();

int	   mesh1[50][50];
XEvent report;


/*
 *	Toggle Processing cursor so that it is animated
 */
void
gr_SubsToggleCursor(subsWin)
A_SubsWind_t	*subsWin;
{
	if (subsWin->curCursor == FALSE)
	{
		subsWin->curCursor = TRUE;
   		gr_WidgetCursor(subsWin->shell,XC_leftbutton);
	}
	else
	{
		subsWin->curCursor = FALSE;
   		gr_WidgetCursor(subsWin->shell,XC_rightbutton);
	}
}


/*
 *	Process event
 */
Boolean
gr_SubsEvent(subsWin)
A_SubsWind_t	*subsWin;
{
	while (XtPending() == TRUE)
	{
		XtNextEvent(&report);
		XtDispatchEvent(&report);
	}

	gr_SubsToggleCursor(subsWin);

	return(subsWin->runMode == 1);
}


/*
 */
void
gr_SubsUpdateDialogs(subsWin)
A_SubsWind_t	*subsWin;
{
	int id = subsWin->curSubsID;

	sprintf(msg,"Substance %2d",id+1);
	gr_LabelSetValue(subsWin->IDLabel,msg);
	sprintf(msg,"%4.2f",subsWin->subs[id].lower);
	gr_DialogSetValue(subsWin->lowerDialog,msg);
	sprintf(msg,"%4.2f",subsWin->subs[id].upper);
	gr_DialogSetValue(subsWin->upperDialog,msg);
	sprintf(msg,"%4.2f",subsWin->subs[id].opacity);
	gr_DialogSetValue(subsWin->opacityDialog,msg);
	sprintf(msg,"%4d",subsWin->subs[id].red);
	gr_DialogSetValue(subsWin->redDialog,msg);
	sprintf(msg,"%4d",subsWin->subs[id].green);
	gr_DialogSetValue(subsWin->greenDialog,msg);
	sprintf(msg,"%4d",subsWin->subs[id].blue);
	gr_DialogSetValue(subsWin->blueDialog,msg);
}

void
gr_SubsIDSliderSel(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_SubsWind_t *subsWin=(A_SubsWind_t *)client_data;

	subsWin->curSubsID = (int)call_data;
	gr_SliderSetValue(w,subsWin->curSubsID);

	gr_SubsUpdateDialogs(subsWin);
}

void
gr_SubsIDSliderMov(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
int	id;

	A_SubsWind_t *subsWin=(A_SubsWind_t *)client_data;

#if 0
	subsWin->curSubsID = (int)call_data;

	gr_SubsUpdateDialogs(subsWin);
#else
	id = (int)call_data;
	if(id < subsWin->numSubs)
	{	subsWin->curSubsID = id;
		gr_SubsUpdateDialogs(subsWin);
	}
#endif

}


void
gr_SubsSetID(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_SubsWind_t *subsWin=(A_SubsWind_t *)client_data;
	char		 *strng;
	int			 id = subsWin->curSubsID;
	float		 value;

	strng = gr_DialogGetValue(subsWin->lowerDialog);
	sscanf(strng,"%f", &value);
	subsWin->subs[id].lower = (double)value;

	strng = gr_DialogGetValue(subsWin->upperDialog);
	sscanf(strng,"%f", &value);
	subsWin->subs[id].upper = (double)value;

	strng = gr_DialogGetValue(subsWin->opacityDialog);
	sscanf(strng,"%f", &value);
	subsWin->subs[id].opacity = (double)value;

	subsWin->subs[id].red = atoi(gr_DialogGetValue(subsWin->redDialog));
	subsWin->subs[id].green = atoi(gr_DialogGetValue(subsWin->greenDialog));
	subsWin->subs[id].blue = atoi(gr_DialogGetValue(subsWin->blueDialog));
}

void
gr_SubsExpose(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_SubsWind_t	*subsWin=(A_SubsWind_t *)client_data;
	Display			*dpy=XtDisplay(subsWin->imageWin);
	Window			win=XtWindow(subsWin->imageWin);
	int				scr=DefaultScreen(dpy);
	XGCValues		gcvals;
	GC				gc;

	gcvals.foreground = BlackPixel(dpy,scr);
	gcvals.function = GXcopy;
	gc = XtGetGC(subsWin->imageWin, GCForeground|GCFunction, &gcvals);

	gr_ImageSetCMap(subsWin->shell);

	XPutImage(dpy,win,gc,subsWin->image,0,0,0,0,
		(int)subsWin->xsize, (int)subsWin->ysize);

	return;
}

/*
 *	Interpolate values at the corners of a square with uneven x and y
 *	sizes.
 *	val4----------val3
 *   |             |
 *   |             |
 *	val1----------val2
 */
void
td_VBuffInterpPixel(subsWin,val1,val2,val3,val4,ind,baseline,singleline)
A_SubsWind_t    *subsWin;
int		val1,val2,val3,val4;
int     ind,baseline,singleline;
{
    int	y1,y2,x1;
    int	scalexi,scaleyi,yi;
    int	x,y,YY;

    YY = baseline + ind;

    if (((val1 == val2) && (val2 == val3) && (val3 == val4)) ||
		(subsWin->parent->interp == FALSE))
    {
        for (y=0;y<subsWin->ypts;y++)
        {
            for (x=0;x<subsWin->xpts;x++)
                subsWin->data24[x*3+YY] = (unsigned char)val1;
            YY += singleline;
        }
        return;
    }

    scalexi = subsWin->xpts-1;
    scaleyi = subsWin->ypts-1;

    mesh1[0][0] = val1;
    mesh1[scalexi][0] = val2;
    mesh1[scalexi][scaleyi] = val3;
    mesh1[0][scaleyi] = val4;
    y1 = (val4-val1)/subsWin->ypts;
    y2 = (val3-val2)/subsWin->ypts;
    for (y=1;y<scaleyi;y++)
    {
        yi = y - 1;
        mesh1[0][y] = mesh1[0][yi]+y1;
        mesh1[scalexi][y] = mesh1[scalexi][yi]+y2;
    }
    for (y=0;y<subsWin->ypts;y++)
    {
        x1 = (mesh1[scalexi][y]-mesh1[0][y])/subsWin->xpts;
        for (x=1;x<scalexi;x++)
            mesh1[x][y] = mesh1[x-1][y]+x1;
    }

    for (y=scaleyi;y>=0;y--)
    {
        for (x=0;x<subsWin->xpts;x++)
            subsWin->data24[x*3+YY] = (unsigned char)(mesh1[x][y]);
        YY += singleline;
    }
}

void
gr_SubsCreateImage(subsWin,width,height,widthOrient,heightOrient)
A_SubsWind_t	*subsWin;
int	width, height, widthOrient, heightOrient;
{
	Display			*dpy=XtDisplay(subsWin->imageWin);
	Window			win=XtWindow(subsWin->imageWin);
	int				scr=DefaultScreen(dpy);
	XGCValues		gcvals;
	GC				gc;
	int				i,j,m=0;
	int				baseline,linesize,singleline;
	
	gcvals.foreground = BlackPixel(dpy,scr);
	gcvals.function = GXcopy;
	gc = XtGetGC(subsWin->imageWin, GCForeground|GCFunction, &gcvals);

	baseline = 0;
	singleline = subsWin->xsize*3;
	linesize = singleline*subsWin->ypts;

	if ((widthOrient > 0) && (heightOrient > 0))
	for (j=height-1;j>0;j--)
	{
		m=0;
		for (i=0;i<width-1;i++)
		{
            td_VBuffInterpPixel(subsWin,
                subsWin->vbuff[i][j-1].red,
                subsWin->vbuff[i+1][j-1].red,
                subsWin->vbuff[i+1][j].red,
                subsWin->vbuff[i][j].red,
                m,baseline,singleline);
            td_VBuffInterpPixel(subsWin,
                subsWin->vbuff[i][j-1].green,
                subsWin->vbuff[i+1][j-1].green,
                subsWin->vbuff[i+1][j].green,
                subsWin->vbuff[i][j].green,
                m+1,baseline,singleline);
            td_VBuffInterpPixel(subsWin,
                subsWin->vbuff[i][j-1].blue,
                subsWin->vbuff[i+1][j-1].blue,
                subsWin->vbuff[i+1][j].blue,
                subsWin->vbuff[i][j].blue,
                m+2,baseline,singleline);
			m+=subsWin->xpts*3;
		}
		baseline += linesize;
	}
	else
	if ((widthOrient > 0) && (heightOrient < 0))
	for (j=0;j<height-1;j++)
	{
		m=0;
		for (i=0;i<width-1;i++)
		{
            td_VBuffInterpPixel(subsWin,
                subsWin->vbuff[i][j+1].red,
                subsWin->vbuff[i+1][j+1].red,
                subsWin->vbuff[i+1][j].red,
                subsWin->vbuff[i][j].red,
                m,baseline,singleline);
            td_VBuffInterpPixel(subsWin,
                subsWin->vbuff[i][j+1].green,
                subsWin->vbuff[i+1][j+1].green,
                subsWin->vbuff[i+1][j].green,
                subsWin->vbuff[i][j].green,
                m+1,baseline,singleline);
            td_VBuffInterpPixel(subsWin,
                subsWin->vbuff[i][j+1].blue,
                subsWin->vbuff[i+1][j+1].blue,
                subsWin->vbuff[i+1][j].blue,
                subsWin->vbuff[i][j].blue,
                m+2,baseline,singleline);
			m+=subsWin->xpts*3;
		}
		baseline += linesize;
	}
	else
	if ((widthOrient < 0) && (heightOrient > 0))
	for (j=height-1;j>0;j--)
	{
		m=0;
		for (i=width-1;i>0;i--)
		{
            td_VBuffInterpPixel(subsWin,
                subsWin->vbuff[i][j-1].red,
                subsWin->vbuff[i-1][j-1].red,
                subsWin->vbuff[i-1][j].red,
                subsWin->vbuff[i][j].red,
                m,baseline,singleline);
            td_VBuffInterpPixel(subsWin,
                subsWin->vbuff[i][j-1].green,
                subsWin->vbuff[i-1][j-1].green,
                subsWin->vbuff[i-1][j].green,
                subsWin->vbuff[i][j].green,
                m+1,baseline,singleline);
            td_VBuffInterpPixel(subsWin,
                subsWin->vbuff[i][j-1].blue,
                subsWin->vbuff[i-1][j-1].blue,
                subsWin->vbuff[i-1][j].blue,
                subsWin->vbuff[i][j].blue,
                m+2,baseline,singleline);
			m+=subsWin->xpts*3;
		}
		baseline += linesize;
	}
	else
	if ((widthOrient < 0) && (heightOrient < 0))
	for (j=0;j<height-1;j++)
	{
		m=0;
		for (i=width-1;i>0;i--)
		{
            td_VBuffInterpPixel(subsWin,
                subsWin->vbuff[i][j+1].red,
                subsWin->vbuff[i-1][j+1].red,
                subsWin->vbuff[i-1][j].red,
                subsWin->vbuff[i][j].red,
                m,baseline,singleline);
            td_VBuffInterpPixel(subsWin,
                subsWin->vbuff[i][j+1].green,
                subsWin->vbuff[i-1][j+1].green,
                subsWin->vbuff[i-1][j].green,
                subsWin->vbuff[i][j].green,
                m+1,baseline,singleline);
            td_VBuffInterpPixel(subsWin,
                subsWin->vbuff[i][j+1].blue,
                subsWin->vbuff[i-1][j+1].blue,
                subsWin->vbuff[i-1][j].blue,
                subsWin->vbuff[i][j].blue,
                m+2,baseline,singleline);
			m+=subsWin->xpts*3;
		}
		baseline += linesize;
	}

	r24r8(subsWin->xsize,subsWin->ysize,subsWin->data24,subsWin->data,
		gr_color.maxColors,subsWin->palData);

	gr_TextMsgOut("Quantized 24-bit image to 8 bits.\n");
	gr_ImageInitCMapPLA(subsWin->palData);
	gr_ImageSetCMap(subsWin->shell);

	subsWin->image = gr_ImageCreate(subsWin->imageVPort,
		subsWin->xsize,subsWin->ysize,subsWin->data);

	XPutImage(dpy,win,gc,subsWin->image,0,0,0,0,
		(int)subsWin->xsize, (int)subsWin->ysize);
}

void
gr_SubsStart(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_SubsWind_t	*subsWin=(A_SubsWind_t *)client_data;
	int32	i,j,k,xdim,ydim,zdim,incr;
	int	    red,green,blue;
	double	intensity,atten,oldOutMax,opacity;
	char	*strng;
	float32	val;

	xdim = td_HdfgetDim(subsWin->hdf,subsWin->axesOrient.col);
	ydim = td_HdfgetDim(subsWin->hdf,subsWin->axesOrient.row);
	zdim = td_HdfgetDim(subsWin->hdf,subsWin->axesOrient.axis);

	switch (subsWin->runMode)
	{
		case 0:	/* reset */
		subsWin->curCursor = FALSE;
    	gr_WidgetCursor(subsWin->shell,XC_rightbutton);
    	subsWin->nearP = atoi(gr_DialogGetValue(subsWin->nearDialog));
    	subsWin->farP = atoi(gr_DialogGetValue(subsWin->farDialog));
    	incr = subsWin->incrP = atoi(gr_DialogGetValue(subsWin->incrDialog));
    	strng = gr_DialogGetValue(subsWin->attDialog);
    	sscanf(strng,"%f",&val);
    	subsWin->att = (double)val;
    	strng = gr_DialogGetValue(subsWin->gammaDialog);
    	sscanf(strng,"%f",&val);
    	subsWin->gamma = (double)val;
    	subsWin->amb = (double)atoi(gr_DialogGetValue(subsWin->ambDialog));
		oldOutMax = subsWin->outMax = (double)0.0;
		sprintf(msg,"Min=%f,Max=%f,Range=%f\n",
			subsWin->hdf->min,subsWin->hdf->max,
		subsWin->hdf->range);
		gr_TextMsgOut(msg);
		sprintf(msg,"ATTENUATION=%10.7f,GAMMA=%10.7f,AMB=%10.7f\n",
			subsWin->att,subsWin->gamma,subsWin->amb);
		gr_TextMsgOut(msg);

		if (subsWin->nearP < 0) subsWin->nearP = 0;
		else if (subsWin->nearP >= zdim) subsWin->nearP = zdim-1;

		if (subsWin->farP < 0) subsWin->farP = 0;
		else if (subsWin->farP >= zdim) subsWin->farP = zdim-1;

		if ((subsWin->nearP > subsWin->farP) &&
			(subsWin->axesOrient.axis > 0))
		subsWin->axesOrient.axis = -subsWin->axesOrient.axis;

		sprintf(msg,"Rays going from plane %d to plane %d\n",
			subsWin->nearP,subsWin->farP);
		gr_TextMsgOut(msg);
		for (j=0;j<ydim;j++)
			for (i=0;i<xdim;i++)
			{
				subsWin->vbuff[i][j].red = 0;
				subsWin->vbuff[i][j].green = 0;
				subsWin->vbuff[i][j].blue = 0;
				subsWin->vbuff[i][j].intensity = (double)0.0;
				subsWin->vbuff[i][j].opacity = (double)0.0;
			}

		subsWin->curP = subsWin->nearP;
		subsWin->runMode = 1; /* running */
		gr_LabelSetValue(subsWin->runButton,"Pause  ");
		break;

		case 1:
    	gr_WidgetCursor(subsWin->shell,XC_hand2);
		subsWin->runMode = 2; /* paused */
		gr_LabelSetValue(subsWin->runButton,"Cont   ");
		gr_SubsCreateImage(subsWin,xdim,ydim,
			subsWin->axesOrient.col,subsWin->axesOrient.row);
		return;

		case 2:
		if (subsWin->curCursor == FALSE)
    		gr_WidgetCursor(subsWin->shell,XC_rightbutton);
		else
    		gr_WidgetCursor(subsWin->shell,XC_leftbutton);
		if (subsWin->axesOrient.axis < 0) subsWin->curP--;
		else subsWin->curP++;
		subsWin->runMode = 1; /* continue previous run */
		gr_LabelSetValue(subsWin->runButton,"Pause  ");
		break;
	}

	atten = sqrt(subsWin->att);

	switch(subsWin->axesOrient.axis)
	{
		case -3 :
			subsWin->depthcue = (double)((atten*zdim)/(1.0-atten));
			subsWin->depthcueSquared = subsWin->depthcue*subsWin->depthcue;
			if ((subsWin->axesOrient.col == 1) ||
				(subsWin->axesOrient.col == -1) )
			{
				for (k=subsWin->curP;k>=subsWin->farP;k-=incr)
				{
					atten = gr_VbuffgetAtten(subsWin,
						(double)(zdim-k-1));
					for (j=0;j<ydim;j++)
					for (i=0;i<xdim;i++)
					{
						intensity = 
						gr_VbuffgetIntensity(subsWin,
							(float32)subsWin->hdf->data[i][j][k]);
						opacity =
						gr_VbuffgetOpacity(subsWin,intensity,&red,&green,&blue);
						if (opacity != -1.0)
							gr_VbuffIntegrate(subsWin,red,green,blue,
							opacity,atten,i,j);
					}
					sprintf(msg,"%d",k);
					gr_DialogSetValue(subsWin->nearDialog,msg);
					if (subsWin->outMax != oldOutMax) {
					sprintf(msg,"%15.10f",subsWin->outMax);
					gr_DialogSetValue(subsWin->maxDialog,msg);
					oldOutMax = subsWin->outMax;
					}
					if (gr_SubsEvent(subsWin) == FALSE) 
					{ subsWin->curP = k; return;}
				}
			}
			else
			{
				for (k=subsWin->curP;k>=subsWin->farP;k-=incr)
				{
					atten = gr_VbuffgetAtten(subsWin,
						(double)(zdim-k-1));
					for (j=0;j<ydim;j++)
					for (i=0;i<xdim;i++)
					{
						intensity = 
						gr_VbuffgetIntensity(subsWin,
							(float32)subsWin->hdf->data[j][i][k]);
						opacity =
						gr_VbuffgetOpacity(subsWin,intensity,&red,&green,&blue);
						if (opacity != -1.0)
						gr_VbuffIntegrate(subsWin,red,green,blue,
							opacity,atten,i,j);
					}
					sprintf(msg,"%d",k);
					gr_DialogSetValue(subsWin->nearDialog,msg);
					if (subsWin->outMax != oldOutMax) {
					sprintf(msg,"%15.10f",subsWin->outMax);
					gr_DialogSetValue(subsWin->maxDialog,msg);
					oldOutMax = subsWin->outMax;
					}
					if (gr_SubsEvent(subsWin) == FALSE)
					{ subsWin->curP = k; return;}
				}
			}
			subsWin->axesOrient.col = -subsWin->axesOrient.col;
		break;
		case -2 :
			subsWin->depthcue = (double)((atten*ydim)/(1.0-atten));
			subsWin->depthcueSquared = subsWin->depthcue*subsWin->depthcue;
			if ((subsWin->axesOrient.col == 1) ||
				(subsWin->axesOrient.col == -1) )
			{
				for (k=subsWin->curP;k>=subsWin->farP;k-=incr)
				{
					atten = gr_VbuffgetAtten(subsWin,
						(double)(zdim-k-1));
					for (j=0;j<ydim;j++)
					for (i=0;i<xdim;i++)
					{
						intensity = 
						gr_VbuffgetIntensity(subsWin,
							(float32)subsWin->hdf->data[i][k][j]);
						opacity =
						gr_VbuffgetOpacity(subsWin,intensity,&red,&green,&blue);
						if (opacity != -1.0)
						gr_VbuffIntegrate(subsWin,red,green,blue,
							opacity,atten,i,j);
					}
					sprintf(msg,"%d",k);
					gr_DialogSetValue(subsWin->nearDialog,msg);
					if (subsWin->outMax != oldOutMax) {
					sprintf(msg,"%15.10f",subsWin->outMax);
					gr_DialogSetValue(subsWin->maxDialog,msg);
					oldOutMax = subsWin->outMax;
					}
					if (gr_SubsEvent(subsWin) == FALSE)
					{ subsWin->curP = k; return;}
				}
			}
			else
			{
				for (k=subsWin->curP;k>=subsWin->farP;k-=incr)
				{
					atten = gr_VbuffgetAtten(subsWin,
						(double)(zdim-k-1));
					for (j=0;j<ydim;j++)
					for (i=0;i<xdim;i++)
					{
						intensity = 
						gr_VbuffgetIntensity(subsWin,
							(float32)subsWin->hdf->data[j][k][i]);
						opacity =
						gr_VbuffgetOpacity(subsWin,intensity,&red,&green,&blue);
						if (opacity != -1.0)
						gr_VbuffIntegrate(subsWin,red,green,blue,
							opacity,atten,i,j);
					}
					sprintf(msg,"%d",k);
					gr_DialogSetValue(subsWin->nearDialog,msg);
					if (subsWin->outMax != oldOutMax) {
					sprintf(msg,"%15.10f",subsWin->outMax);
					gr_DialogSetValue(subsWin->maxDialog,msg);
					oldOutMax = subsWin->outMax;
					}
					if (gr_SubsEvent(subsWin) == FALSE)
					{ subsWin->curP = k; return;}
				}
			}
			subsWin->axesOrient.col = -subsWin->axesOrient.col;
		break;
		case -1 :
			subsWin->depthcue = (double)((atten*xdim)/(1.0-atten));
			subsWin->depthcueSquared = subsWin->depthcue*subsWin->depthcue;
			if ((subsWin->axesOrient.col == 2) ||
				(subsWin->axesOrient.col == -2) )
			{
				for (k=subsWin->curP;k>=subsWin->farP;k-=incr)
				{
					atten = gr_VbuffgetAtten(subsWin,
						(double)(zdim-k-1));
					for (j=0;j<ydim;j++)
					for (i=0;i<xdim;i++)
					{
						intensity = 
						gr_VbuffgetIntensity(subsWin,
							(float32)subsWin->hdf->data[k][i][j]);
						opacity =
						gr_VbuffgetOpacity(subsWin,intensity,&red,&green,&blue);
						if (opacity != -1.0)
						gr_VbuffIntegrate(subsWin,red,green,blue,
							opacity,atten,i,j);
					}
					sprintf(msg,"%d",k);
					gr_DialogSetValue(subsWin->nearDialog,msg);
					if (subsWin->outMax != oldOutMax) {
					sprintf(msg,"%15.10f",subsWin->outMax);
					gr_DialogSetValue(subsWin->maxDialog,msg);
					oldOutMax = subsWin->outMax;
					}
					if (gr_SubsEvent(subsWin) == FALSE)
					{ subsWin->curP = k; return;}
				}
			}
			else
			{
				for (k=subsWin->curP;k>=subsWin->farP;k-=incr)
				{
					atten = gr_VbuffgetAtten(subsWin,
						(double)(zdim-k-1));
					for (j=0;j<ydim;j++)
					for (i=0;i<xdim;i++)
					{
						intensity = 
						gr_VbuffgetIntensity(subsWin,
							(float32)subsWin->hdf->data[k][j][i]);
						opacity =
						gr_VbuffgetOpacity(subsWin,intensity,&red,&green,&blue);
						if (opacity != -1.0)
						gr_VbuffIntegrate(subsWin,red,green,blue,
							opacity,atten,i,j);
					}
					sprintf(msg,"%d",k);
					gr_DialogSetValue(subsWin->nearDialog,msg);
					if (subsWin->outMax != oldOutMax) {
					sprintf(msg,"%15.10f",subsWin->outMax);
					gr_DialogSetValue(subsWin->maxDialog,msg);
					oldOutMax = subsWin->outMax;
					}
					if (gr_SubsEvent(subsWin) == FALSE)
					{ subsWin->curP = k; return;}
				}
			}
			subsWin->axesOrient.col = -subsWin->axesOrient.col;
		break;
		case 1 :
			subsWin->depthcue = (double)((atten*xdim)/(1.0-atten));
			subsWin->depthcueSquared = subsWin->depthcue*subsWin->depthcue;
			if ((subsWin->axesOrient.col == 2) ||
				(subsWin->axesOrient.col == -2) )
			{
				for (k=subsWin->curP;k<=subsWin->farP;k+=incr)
				{
					atten = gr_VbuffgetAtten(subsWin,(double)k);
					for (j=0;j<ydim;j++)
					for (i=0;i<xdim;i++)
					{
						intensity = 
						gr_VbuffgetIntensity(subsWin,
							(float32)subsWin->hdf->data[k][i][j]);
						opacity =
						gr_VbuffgetOpacity(subsWin,intensity,&red,&green,&blue);
						if (opacity != -1.0)
						gr_VbuffIntegrate(subsWin,red,green,blue,
							opacity,atten,i,j);
					}
					sprintf(msg,"%d",k);
					gr_DialogSetValue(subsWin->nearDialog,msg);
					if (subsWin->outMax != oldOutMax) {
					sprintf(msg,"%15.10f",subsWin->outMax);
					gr_DialogSetValue(subsWin->maxDialog,msg);
					oldOutMax = subsWin->outMax;
					}
					if (gr_SubsEvent(subsWin) == FALSE)
					{ subsWin->curP = k; return;}
				}
			}
			else
			{
				for (k=subsWin->curP;k<=subsWin->farP;k+=incr)
				{
					atten = gr_VbuffgetAtten(subsWin,(double)k);
					for (j=0;j<ydim;j++)
					for (i=0;i<xdim;i++)
					{
						intensity = 
						gr_VbuffgetIntensity(subsWin,
							(float32)subsWin->hdf->data[k][j][i]);
						opacity =
						gr_VbuffgetOpacity(subsWin,intensity,&red,&green,&blue);
						if (opacity != -1.0)
						gr_VbuffIntegrate(subsWin,red,green,blue,
							opacity,atten,i,j);
					}
					sprintf(msg,"%d",k);
					gr_DialogSetValue(subsWin->nearDialog,msg);
					if (subsWin->outMax != oldOutMax) {
					sprintf(msg,"%15.10f",subsWin->outMax);
					gr_DialogSetValue(subsWin->maxDialog,msg);
					oldOutMax = subsWin->outMax;
					}
					if (gr_SubsEvent(subsWin) == FALSE)
					{ subsWin->curP = k; return;}
				}
			}
		break;
		case 2 :
			subsWin->depthcue = (double)((atten*ydim)/(1.0-atten));
			subsWin->depthcueSquared = subsWin->depthcue*subsWin->depthcue;
			if ((subsWin->axesOrient.col == 1) ||
				(subsWin->axesOrient.col == -1) )
			{
				for (k=subsWin->curP;k<=subsWin->farP;k+=incr)
				{
					atten = gr_VbuffgetAtten(subsWin,(double)k);
					for (j=0;j<ydim;j++)
					for (i=0;i<xdim;i++)
					{
						intensity = 
						gr_VbuffgetIntensity(subsWin,
							(float32)subsWin->hdf->data[i][k][j]);
						opacity =
						gr_VbuffgetOpacity(subsWin,intensity,&red,&green,&blue);
						if (opacity != -1.0)
						gr_VbuffIntegrate(subsWin,red,green,blue,
							opacity,atten,i,j);
					}
					sprintf(msg,"%d",k);
					gr_DialogSetValue(subsWin->nearDialog,msg);
					if (subsWin->outMax != oldOutMax) {
					sprintf(msg,"%15.10f",subsWin->outMax);
					gr_DialogSetValue(subsWin->maxDialog,msg);
					oldOutMax = subsWin->outMax;
					}
					if (gr_SubsEvent(subsWin) == FALSE)
					{ subsWin->curP = k; return;}
				}
			}
			else
			{
				for (k=subsWin->curP;k<=subsWin->farP;k+=incr)
				{
					atten = gr_VbuffgetAtten(subsWin,(double)k);
					for (j=0;j<ydim;j++)
					for (i=0;i<xdim;i++)
					{
						intensity = 
						gr_VbuffgetIntensity(subsWin,
							(float32)subsWin->hdf->data[j][k][i]);
						opacity =
						gr_VbuffgetOpacity(subsWin,intensity,&red,&green,&blue);
						if (opacity != -1.0)
						gr_VbuffIntegrate(subsWin,red,green,blue,
							opacity,atten,i,j);
					}
					sprintf(msg,"%d",k);
					gr_DialogSetValue(subsWin->nearDialog,msg);
					if (subsWin->outMax != oldOutMax) {
					sprintf(msg,"%15.10f",subsWin->outMax);
					gr_DialogSetValue(subsWin->maxDialog,msg);
					oldOutMax = subsWin->outMax;
					}
					if (gr_SubsEvent(subsWin) == FALSE)
					{ subsWin->curP = k; return;}
				}
			}
		break;
		case 3 :
			subsWin->depthcue = (double)((atten*zdim)/(1.0-atten));
			subsWin->depthcueSquared = subsWin->depthcue*subsWin->depthcue;
			if ((subsWin->axesOrient.col == 1) ||
				(subsWin->axesOrient.col == -1) )
			{
				for (k=subsWin->curP;k<=subsWin->farP;k+=incr)
				{
					atten = gr_VbuffgetAtten(subsWin,(double)k);
					for (j=0;j<ydim;j++)
					for (i=0;i<xdim;i++)
					{
						intensity = 
						gr_VbuffgetIntensity(subsWin,
							(float32)subsWin->hdf->data[i][j][k]);
						opacity = 
						gr_VbuffgetOpacity(subsWin,intensity,&red,&green,&blue);
						if (opacity != -1.0)
						gr_VbuffIntegrate(subsWin,red,green,blue,
							opacity,atten,i,j);
					}
					sprintf(msg,"%d",k);
					gr_DialogSetValue(subsWin->nearDialog,msg);
					if (subsWin->outMax != oldOutMax) {
					sprintf(msg,"%15.10f",subsWin->outMax);
					gr_DialogSetValue(subsWin->maxDialog,msg);
					oldOutMax = subsWin->outMax;
					}
					if (gr_SubsEvent(subsWin) == FALSE)
					{ subsWin->curP = k; return;}
				}
			}
			else
			{
				for (k=subsWin->curP;k<=subsWin->farP;k+=incr)
				{
					atten = gr_VbuffgetAtten(subsWin,(double)k);
					for (j=0;j<ydim;j++)
					for (i=0;i<xdim;i++)
					{
						intensity = 
						gr_VbuffgetIntensity(subsWin,
							(float32)subsWin->hdf->data[j][i][k]);
						opacity = 
						gr_VbuffgetOpacity(subsWin,intensity,&red,&green,&blue);
						if (opacity != -1.0)
						gr_VbuffIntegrate(subsWin,red,green,blue,
							opacity,atten,i,j);
					}
					sprintf(msg,"%d",k);
					gr_DialogSetValue(subsWin->nearDialog,msg);
					if (subsWin->outMax != oldOutMax) {
					sprintf(msg,"%15.10f",subsWin->outMax);
					gr_DialogSetValue(subsWin->maxDialog,msg);
					oldOutMax = subsWin->outMax;
					}
					if (gr_SubsEvent(subsWin) == FALSE)
					{ subsWin->curP = k; return;}
				}
			}
		break;
	}

	gr_SubsCreateImage(subsWin,xdim,ydim,
		subsWin->axesOrient.col,subsWin->axesOrient.row);
	gr_TextMsgOut("Finished all planes.\n");
	subsWin->runMode = 0; /* reset */
	gr_LabelSetValue(subsWin->runButton,"Start  ");
    gr_WidgetCursor(subsWin->shell,XC_draped_box);
	return;
}

void
gr_SubsReset(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_SubsWind_t	*subsWin=(A_SubsWind_t *)client_data;

	subsWin->runMode = 0; /* reset */
	subsWin->curCursor = FALSE;
	gr_LabelSetValue(subsWin->runButton,"Start  ");
    gr_WidgetCursor(subsWin->shell,XC_draped_box);

	return;
}
