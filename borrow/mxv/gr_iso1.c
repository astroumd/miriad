#ifndef NO_ISO
/*
 *	File:		gr_iso1.c
 *	Contents:	Iso-surface level routines for graphics module
 */

#include "gr_com.h"
#include "gr_iso.h"
#include <math.h>
extern double gr_rint();
/*extern double sin();
extern double cos();
*/
extern void   mcube();

static float32	lightLen;
static InterpCoor	lightVec = { 0, 0.0, 0.0, 1.0 };
XEvent report;


/*
 *  Process event
 */
void gr_IsoEvent(isoWin)
A_IsoWind_t    *isoWin;
{
XtInputMask	mask;

    while( (mask = XtAppPending(app_context)) == TRUE)
    {
        XtAppNextEvent(app_context, &report);
        XtDispatchEvent(&report);
    }
}


void
gr_IsoCalMatrix(isoWin)
A_IsoWind_t *isoWin;
{
	double	X,Y,Z,cx,sx,cy,sy,cz,sz;

	X = (double)((double)isoWin->xangle*PI/(double)180.0);
	Y = (double)((double)isoWin->yangle*PI/(double)180.0);
	Z = (double)((double)isoWin->zangle*PI/(double)180.0);

	cx = cos((double)X); sx = sin((double)X);
	cy = cos((double)Y); sy = sin((double)Y);
	cz = cos((double)Z); sz = sin((double)Z);

	isoWin->matrix[1][1] = cy*cz;
	isoWin->matrix[1][2] = -cy*sz;
	isoWin->matrix[1][3] = sy;
	isoWin->matrix[1][4] = 0.0;
	isoWin->matrix[2][1] = sx*sy*cz+cx*sz;
	isoWin->matrix[2][2] = -sx*sy*sz+cx*cz;
	isoWin->matrix[2][3] = -sx*cy;
	isoWin->matrix[2][4] = 0.0;
	isoWin->matrix[3][1] = -cx*sy*cz+sx*sz;
	isoWin->matrix[3][2] = sx*cz+cx*sy*sz;
	isoWin->matrix[3][3] = cx*cy;
	isoWin->matrix[3][4] = 0.0;
	isoWin->matrix[4][1] = 0.0;
	isoWin->matrix[4][2] = 0.0;
	isoWin->matrix[4][3] = 0.0;
	isoWin->matrix[4][4] = 1.0;
}


gr_IsoInit(isoWin)
A_IsoWind_t *isoWin;
{
	int i,j,k=0;
	int	numPixs=isoWin->xsize*isoWin->ysize,tmp;

    for (i=0;i<isoWin->xsize;i++)
	  for (j=0;j<isoWin->ysize;j++)
      	isoWin->fb[j][i] = isoWin->xsize;

    for (j=0;j<numPixs;j++)
    {
      isoWin->data[j] = (unsigned char)gr_color.white;
	  isoWin->data24[k++] = (unsigned char)gr_color.white;
	  isoWin->data24[k++] = (unsigned char)gr_color.white;
	  isoWin->data24[k++] = (unsigned char)gr_color.white;
    }

	if (isoWin->doUpdate == TRUE)
	{
		for (i=0;i<gr_color.maxColors;i++)
		{
			tmp = i*3;
			isoWin->palData[tmp++] = i;
			isoWin->palData[tmp++] = i;
			isoWin->palData[tmp] = i;
		}
		gr_ImageInitCMapHDF(isoWin->palData);
		gr_ImageSetCMap(isoWin->shell);
	}

	gr_IsoCalMatrix(isoWin);
}


void
gr_IsoCreateImage(isoWin)
A_IsoWind_t	*isoWin;
{
	Widget		wid=isoWin->imageWin;
	Display	    *dpy=XtDisplay(wid);
	Window		win=XtWindow(wid);

	XClearWindow(dpy,win);
	if (isoWin->doWireFrame == TRUE)
		return;

	if (isoWin->doTrueColor == TRUE)
	{
		r24r8(isoWin->xsize,isoWin->ysize,isoWin->data24,
		isoWin->data,gr_color.maxColors,isoWin->palData);
		gr_TextMsgOut("Quantized 24-bit image to 8 bits.\n");
		gr_ImageInitCMapPLA(isoWin->palData);
		gr_ImageSetCMap(isoWin->shell);
	}
    isoWin->image =
		gr_ImageCreate(isoWin->imageVPort,isoWin->xsize,isoWin->ysize,
			isoWin->data);

	XPutImage(dpy,win,isoWin->gc,isoWin->image,0,0,0,0,isoWin->xsize,isoWin->ysize);

	gr_ImageSetCMap(isoWin->shell);
}

void
gr_IsoGetValues(isoWin)
A_IsoWind_t *isoWin;
{
	float		val;
	char		*strng;

	strng = gr_DialogGetValue(isoWin->pFactorDialog);
	sscanf(strng,"%f",&val);
	isoWin->pFactor = (double)val*isoWin->xsize;

	strng = gr_DialogGetValue(isoWin->attenDialog);
	sscanf(strng,"%f",&val);
	isoWin->atten = (double)val+isoWin->xsize;

	strng = gr_DialogGetValue(isoWin->rotXDialog);
	sscanf(strng,"%f",&val);
	isoWin->xangle = (double)val;

	strng = gr_DialogGetValue(isoWin->rotYDialog);
	sscanf(strng,"%f",&val);
	isoWin->yangle = (double)val;

	strng = gr_DialogGetValue(isoWin->rotZDialog);
	sscanf(strng,"%f",&val);
	isoWin->zangle = (double)val;

	strng = gr_DialogGetValue(isoWin->incXDialog);
	sscanf(strng,"%f",&val);
	isoWin->incX = (double)val;

	strng = gr_DialogGetValue(isoWin->incYDialog);
	sscanf(strng,"%f",&val);
	isoWin->incY = (double)val;

	strng = gr_DialogGetValue(isoWin->incZDialog);
	sscanf(strng,"%f",&val);
	isoWin->incZ = (double)val;

    isoWin->numFrames = atoi(gr_DialogGetValue(isoWin->numFramesDialog));
    isoWin->numSubs = atoi(gr_DialogGetValue(isoWin->numSubsDialog));

	lightLen = sqrt( (lightVec.x*lightVec.x) +
					 (lightVec.y*lightVec.y) +
					 (lightVec.z*lightVec.z) );

}


/*
 *	View iso-surfaces
 */
void
gr_IsoView(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_IsoWind_t *isoWin=(A_IsoWind_t *)client_data;
	A_Data_t	*hdf=isoWin->parent->data;
	float32		***hdfdata=hdf->data;
	int			i;

    gr_WidgetCursor(isoWin->shell,XC_watch);

	gr_IsoGetValues(isoWin);

	gr_IsoCalMatrix(isoWin);

	for (i=0;i<isoWin->numSubs;i++)
	{
		if ((isoWin->subsVal[i] < hdf->min) ||
			(isoWin->subsVal[i] > hdf->max))
		{
			sprintf(msg,"Value %f is out of range.  Please re-specify.\n",isoWin->subsVal[i]);
			gr_TextMsgOut(msg);
    		gr_WidgetCursor(isoWin->shell,XC_draped_box);
			return;
		}
	}

	isoWin->stopIso = FALSE;

   	mcube(isoWin, hdfdata, isoWin->xdim, isoWin->ydim, isoWin->zdim,
		isoWin->startX, isoWin->endX,
		isoWin->startY, isoWin->endY,
		isoWin->startZ, isoWin->endZ,
		isoWin->subsVal, isoWin->numSubs);


	if (isoWin->doWireFrame == FALSE)
		gr_IsoCreateImage(isoWin);

	if (isoWin->stopIso == TRUE)
		gr_TextMsgOut("Iso-surface rendering interrupted!\n");

	isoWin->stopIso = TRUE;
    gr_WidgetCursor(isoWin->shell,XC_draped_box);

	return;
}

static InterpCoor	pt[3];
static float32 A,B,C,K,intensity,redI,greenI,blueI;
static float32 minX,minY,maxX,maxY,maxZ,startX,endX;
static float32 mb[3],xb[3];
static int	   i,j,k,nb[3],tb[3];

void
gr_IsoScanFill(isoWin,p)
A_IsoWind_t *isoWin;
InterpCoor	p[3];
{
	XGCValues gcvals;
	GC		 gc;
	Widget  wid=isoWin->imageWin;
	Display *dpy=XtDisplay(wid);
	Window	win=XtWindow(wid);
	float32 scale=(float32)isoWin->scale,pfact;
	char	*data=isoWin->data;
	char	*data24=isoWin->data24;
	int		**fb=isoWin->fb;
	int		lineX,pos,posY;
	int		xsize=isoWin->xsize,ysize=isoWin->ysize;
	int	    ix,iy;
	int		subsID=isoWin->curSubs;
	Bool	first=TRUE;

    for (i=0;i<3;i++) {
		pt[i].x = p[i].x = (p[i].x * scale) - isoWin->xmid;
		pt[i].y = p[i].y = (p[i].y * scale) - isoWin->ymid;
		pt[i].z = p[i].z = (p[i].z * scale) - isoWin->zmid;
	}

	/* Rotate all points */
	if (isoWin->doRotate == TRUE)
   	for (i=0;i<3;i++) {
		p[i].x = pt[i].x*isoWin->matrix[1][1]+pt[i].y*isoWin->matrix[2][1]+
				 pt[i].z*isoWin->matrix[3][1]+isoWin->matrix[4][1];
		p[i].y = pt[i].x*isoWin->matrix[1][2]+pt[i].y*isoWin->matrix[2][2]+
				 pt[i].z*isoWin->matrix[3][2]+isoWin->matrix[4][2];
		p[i].z = pt[i].x*isoWin->matrix[1][3]+pt[i].y*isoWin->matrix[2][3]+
				 pt[i].z*isoWin->matrix[3][3]+isoWin->matrix[4][3];
		}

	/* Perform perspective transformation */
	if (isoWin->doPerspective == TRUE)
   	for (i=0;i<3;i++) {
   		pfact = 1.0/((p[i].z/isoWin->pFactor)+1.0);
		p[i].x = p[i].x * pfact;
		p[i].y = p[i].y * pfact;
	}

	/* Translate points to center image */
    for (i=0;i<3;i++) {
		p[i].x = p[i].x + isoWin->xoff;
		p[i].y = p[i].y + isoWin->yoff;
		p[i].z = p[i].z + isoWin->zoff;

		if ((p[i].x < 0) || (p[i].x > xsize)) return;
		if ((p[i].y < 0) || (p[i].y > ysize)) return;
	}

	/* Calculate max depth */
	maxZ        = p[0].z;
    for (i=1;i<3;i++)
		if (p[i].z > maxZ) maxZ = p[i].z;

	/* Calculate normal */
    A = p[0].y*(p[1].z-p[2].z)+p[1].y*(p[2].z-p[0].z)+p[2].y*(p[0].z-p[1].z);
    B = p[0].z*(p[1].x-p[2].x)+p[1].z*(p[2].x-p[0].x)+p[2].z*(p[0].x-p[1].x);
    C = p[0].x*(p[1].y-p[2].y)+p[1].x*(p[2].y-p[0].y)+p[2].x*(p[0].y-p[1].y);
    K = sqrt((A*A)+(B*B)+(C*C));
 
    if ( K != 0.0 )
    {
        intensity =(((A*lightVec.x)+(B*lightVec.y)+(C*lightVec.z))/
					 (K*lightLen))*gr_color.nColors;
        if (intensity < 0.0) intensity = -intensity;

		if ((maxZ > 0.0) && (isoWin->doAttenuate == TRUE))
			intensity *= (isoWin->atten-maxZ)/isoWin->atten;

		if (isoWin->doTrueColor == TRUE)
		{
			redI = (isoWin->redCoeff[subsID]*intensity)+RESERVED_COLORS;
			greenI = (isoWin->greenCoeff[subsID]*intensity)+RESERVED_COLORS;
			blueI = (isoWin->blueCoeff[subsID]*intensity)+RESERVED_COLORS;
		}

        intensity += RESERVED_COLORS;


        if (intensity <= gr_color.nColors)
        {

			if (isoWin->doWireFrame == TRUE)
			{
				gcvals.foreground = (int)intensity;
				gc = XtGetGC(wid,GCForeground,&gcvals);
				XDrawLine(dpy,win,gc,(int)p[0].x,(int)(ysize-p[0].y),
					(int)p[1].x,(int)(ysize-p[1].y));
				XDrawLine(dpy,win,gc,(int)p[1].x,(int)(ysize-p[1].y),
					(int)p[2].x,(int)(ysize-p[2].y));
				XDrawLine(dpy,win,gc,(int)p[2].x,(int)(ysize-p[2].y),
					(int)p[0].x,(int)(ysize-p[0].y));
				return;
			}

			/* Calculate bounding box */
			minX = maxX = p[0].x;
			minY = maxY = p[0].y;
    		for (i=1;i<3;i++) {
				if (p[i].x < minX) minX = p[i].x; else
				if (p[i].x > maxX) maxX = p[i].x;
				if (p[i].y < minY) minY = p[i].y; else
				if (p[i].y > maxY) maxY = p[i].y;
			}

			if (p[1].y == p[0].y)
				nb[0] = 0;
			else
			{
				nb[0] = 1;
				mb[0] = (p[1].x-p[0].x)/(p[1].y-p[0].y);
			}

			if (p[2].y == p[1].y)
				nb[1] = 0;
			else
			{
				nb[1] = 1;
				mb[1] = (p[2].x-p[1].x)/(p[2].y-p[1].y);
			}

			if (p[0].y == p[2].y)
				nb[2] = 0;
			else
			{
				nb[2] = 1;
				mb[2] = (p[0].x-p[2].x)/(p[0].y-p[2].y);
			}
			for (iy=(int)minY;iy<=(int)maxY;iy++)
			{
				if (nb[0]) xb[0] = mb[0]*((float32)iy-p[0].y)+p[0].x;
				if (nb[1]) xb[1] = mb[1]*((float32)iy-p[1].y)+p[1].x;
				if (nb[2]) xb[2] = mb[2]*((float32)iy-p[2].y)+p[2].x;
				tb[0] = ( (((float32)iy>=p[0].y) && ((float32)iy<=p[1].y)) ||
						  (((float32)iy>=p[1].y) && ((float32)iy<=p[0].y)) );
				tb[1] = ( (((float32)iy>=p[1].y) && ((float32)iy<=p[2].y)) ||
						  (((float32)iy>=p[2].y) && ((float32)iy<=p[1].y)) );
				tb[2] = ( (((float32)iy>=p[2].y) && ((float32)iy<=p[0].y)) ||
						  (((float32)iy>=p[0].y) && ((float32)iy<=p[2].y)) );
				k=0;
				for (j=0;j<3;j++)
					if ((nb[j]) && (tb[j]) &&
						(xb[j] >= minX) && (xb[j] <= maxX))
					{
						if (k==0)
						   startX=endX=xb[j];
						else
						if (xb[j] < startX)
							startX = xb[j];
						else
						if (xb[j] > endX)
							endX = xb[j];
						k++;
					}

				if (k > 1)
				{
					first=TRUE;
					posY=(ysize-iy)*xsize;
					for (ix=(int)startX;ix<=(int)endX;ix++)
						if (fb[iy][ix] > (int)maxZ)
				   		{
					  		fb[iy][ix] = (int)maxZ;
							if (isoWin->doTrueColor == FALSE)
								data[posY+ix] = (int)intensity;
							else
							{
								pos = (posY+ix)*3;
								data24[pos] = (unsigned char)redI;
								data24[pos+1] = (unsigned char)greenI;
								data24[pos+2] = (unsigned char)blueI;
							}
							if (first == TRUE)
							{
								lineX = ix;
								first = FALSE;
							}
						}
						else
						if (first == FALSE)
						{
							gcvals.foreground = (int)intensity;
							if (isoWin->doUpdate == TRUE)
							{
							gc = XtGetGC(wid,GCForeground,&gcvals);
							XDrawLine(dpy,win,gc,
						lineX,(int)(ysize-iy),(int)(ix-1),(int)(ysize-iy));
							}
							first = TRUE;
						}

					if (first == FALSE)
					{
						gcvals.foreground = (int)intensity;
						if (isoWin->doUpdate == TRUE)
						{
						gc = XtGetGC(wid,GCForeground,&gcvals);
						XDrawLine(dpy,win,gc,
						lineX,(int)(ysize-iy),(int)endX,(int)(ysize-iy));
						}
						first = TRUE;
					}

				}

			}
        }
    }
}


/*
 *	Expose event for iso-surface window
 */
void
gr_IsoExpose(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_IsoWind_t *isoWin=(A_IsoWind_t *)client_data;
	Display		*dpy = XtDisplay(isoWin->imageWin);
	Window	win = XtWindow(isoWin->imageWin);

	gr_ImageSetCMap(isoWin->shell);
	XPutImage(dpy,win,isoWin->gc,isoWin->image,0,0,
	0,0,(int)isoWin->xsize,(int)isoWin->ysize);

	return;
}

/*
 *	Clear window
 */
void
gr_IsoClear(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_IsoWind_t *isoWin=(A_IsoWind_t *)client_data;
	Widget		wid=isoWin->imageWin;
	Display	    *dpy=XtDisplay(wid);
	Window		win=XtWindow(wid);

	gr_IsoInit(isoWin);
    isoWin->image =
		gr_ImageCreate(isoWin->imageVPort,isoWin->xsize,isoWin->ysize,
			isoWin->data);

	XClearWindow(dpy,win);

	return;
}


/*
 *	Do True Color
 */
void
gr_IsoSetTrueColorToggle(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_IsoWind_t *isoWin=(A_IsoWind_t *)client_data;

	isoWin->doTrueColor = gr_is_toggle_set(w);

	return;
}

/*
 *	Do Attenuation
 */
void
gr_IsoSetAttenuateToggle(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_IsoWind_t *isoWin=(A_IsoWind_t *)client_data;

	isoWin->doAttenuate = gr_is_toggle_set(w);
	return;
}

/*
 *	Do Rotation
 */
void
gr_IsoSetRotateToggle(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_IsoWind_t *isoWin=(A_IsoWind_t *)client_data;

	isoWin->doRotate = gr_is_toggle_set(w);
	return;
}

/*
 *	Do Perspective
 */
void
gr_IsoSetPerspectiveToggle(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_IsoWind_t *isoWin=(A_IsoWind_t *)client_data;

	isoWin->doPerspective = gr_is_toggle_set(w);

	return;
}

/*
 *	Update
 */
void
gr_IsoSetUpdateToggle(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_IsoWind_t *isoWin=(A_IsoWind_t *)client_data;

	isoWin->doUpdate = gr_is_toggle_set(w);

	return;
}

/*
 * Draw with wire frames only
 */
void
gr_IsoSetWireFrameToggle(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_IsoWind_t *isoWin=(A_IsoWind_t *)client_data;

	isoWin->doWireFrame = gr_is_toggle_set(w);

	return;
}


/*
 *	Batch animation
 */
void
gr_IsoSaveAni(isoWin,pathname,numframes)
A_IsoWind_t *isoWin;
char	*pathname;
int		*numframes;
{
	Widget		wid=isoWin->imageWin;
	Display	    *dpy=XtDisplay(wid);
	Window		win=XtWindow(wid);
	A_Data_t	*hdf=isoWin->parent->data;
	float32		***hdfdata=hdf->data;
	int			i,ret,fileexist;

    gr_WidgetCursor(isoWin->shell,XC_watch);

	gr_IsoGetValues(isoWin);

	*numframes = isoWin->numFrames;

	for (i=0;i<isoWin->numSubs;i++)
	{
		if ((isoWin->subsVal[i] < hdf->min) ||
			(isoWin->subsVal[i] > hdf->max))
		{
			sprintf(msg,"Value %f is out of range.  Please re-specify.\n");
			gr_TextMsgOut(msg);
    		gr_WidgetCursor(isoWin->shell,XC_draped_box);
			return;
		}
	}

	isoWin->stopIso = FALSE;

	for (i=0;((i<isoWin->numFrames) && (isoWin->stopIso == FALSE));i++)
	{
		gr_IsoCalMatrix(isoWin);

    	mcube(isoWin, hdfdata, isoWin->xdim, isoWin->ydim, isoWin->zdim,
		isoWin->startX, isoWin->endX,
		isoWin->startY, isoWin->endY,
		isoWin->startZ, isoWin->endZ,
		isoWin->subsVal, isoWin->numSubs);

		if (isoWin->doWireFrame == TRUE)
			return;

		gr_IsoCreateImage(isoWin);

    	fileexist = td_FileExist(pathname);

        if (fileexist == 0)
            ret = td_HdfPutImage(pathname,isoWin->data,
                gr_color.palette,
                isoWin->xsize,isoWin->ysize);
        else
            ret = td_HdfAddImage(pathname,isoWin->data,
                gr_color.palette,
                isoWin->xsize,isoWin->ysize);

        if (ret == -1)
		{
			sprintf(msg,"HDF Error: Cannot save image %d in file %s.\n",
				i,pathname);
            gr_TextMsgOut(msg);
		}
		else
		{
			sprintf(msg,"Saved image %d in %s.\n",
				i,pathname);
			gr_TextMsgOut(msg);
		}

		isoWin->xangle += isoWin->incX;
		isoWin->yangle += isoWin->incY;
		isoWin->zangle += isoWin->incZ;

		if ((i < isoWin->numFrames-1) && (isoWin->stopIso == FALSE))
		{
			gr_IsoInit(isoWin);
    		isoWin->image =
			gr_ImageCreate(isoWin->imageVPort,isoWin->xsize,isoWin->ysize,
				isoWin->data);
			XClearWindow(dpy,win);
		}

		if (isoWin->stopIso == TRUE)
			gr_TextMsgOut("Iso-surface rendering interrupted!\n");
	}

	isoWin->stopIso = TRUE;

    gr_WidgetCursor(isoWin->shell,XC_draped_box);

	return;
}


/*
 */
void
gr_IsoUpdateDialogs(isoWin)
A_IsoWind_t    *isoWin;
{
    int id = isoWin->curSubsID;

    sprintf(msg,"S %1d",id+1);
    gr_LabelSetValue(isoWin->IDLabel,msg);
    sprintf(msg,"%5.2f",isoWin->subsVal[id]);
    gr_DialogSetValue(isoWin->isoDialog,msg);
    sprintf(msg,"%5.2f",isoWin->redCoeff[id]);
    gr_DialogSetValue(isoWin->redDialog,msg);
    sprintf(msg,"%5.2f",isoWin->greenCoeff[id]);
    gr_DialogSetValue(isoWin->greenDialog,msg);
    sprintf(msg,"%5.2f",isoWin->blueCoeff[id]);
    gr_DialogSetValue(isoWin->blueDialog,msg);
    sprintf(msg,"%d",isoWin->startX[id]);
    gr_DialogSetValue(isoWin->startXDialog,msg);
    sprintf(msg,"%d",isoWin->startY[id]);
    gr_DialogSetValue(isoWin->startYDialog,msg);
    sprintf(msg,"%d",isoWin->startZ[id]);
    gr_DialogSetValue(isoWin->startZDialog,msg);
    sprintf(msg,"%d",isoWin->endX[id]);
    gr_DialogSetValue(isoWin->endXDialog,msg);
    sprintf(msg,"%d",isoWin->endY[id]);
    gr_DialogSetValue(isoWin->endYDialog,msg);
    sprintf(msg,"%d",isoWin->endZ[id]);
    gr_DialogSetValue(isoWin->endZDialog,msg);
}


void
gr_IsoGetSubsValues(isoWin,ID)
A_IsoWind_t *isoWin;
int ID;
{
    float       val;
    char        *strng;

    strng = gr_DialogGetValue(isoWin->isoDialog);
    sscanf(strng,"%f",&val);
    isoWin->subsVal[ID] = (float32)val;

    strng = gr_DialogGetValue(isoWin->redDialog);
    sscanf(strng,"%f",&val);
    isoWin->redCoeff[ID] = (double)val;
    strng = gr_DialogGetValue(isoWin->greenDialog);
    sscanf(strng,"%f",&val);
    isoWin->greenCoeff[ID] = (double)val;
    strng = gr_DialogGetValue(isoWin->blueDialog);
    sscanf(strng,"%f",&val);
    isoWin->blueCoeff[ID] = (double)val;

    isoWin->startX[ID] = atoi(gr_DialogGetValue(isoWin->startXDialog));
    isoWin->startY[ID] = atoi(gr_DialogGetValue(isoWin->startYDialog));
    isoWin->startZ[ID] = atoi(gr_DialogGetValue(isoWin->startZDialog));
    isoWin->endX[ID] = atoi(gr_DialogGetValue(isoWin->endXDialog));
    isoWin->endY[ID] = atoi(gr_DialogGetValue(isoWin->endYDialog));
    isoWin->endZ[ID] = atoi(gr_DialogGetValue(isoWin->endZDialog));
}


void
gr_IsoIDSliderSel(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
    A_IsoWind_t *isoWin=(A_IsoWind_t *)client_data;
	int			oldID = isoWin->curSubsID;

	gr_IsoGetSubsValues(isoWin,oldID);

    isoWin->curSubsID = (int)call_data;

    gr_SliderSetValue(w,isoWin->curSubsID);

    gr_IsoUpdateDialogs(isoWin);
}


void
gr_IsoIDSliderMov(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
    A_IsoWind_t *isoWin=(A_IsoWind_t *)client_data;
	int			oldID = isoWin->curSubsID;

	gr_IsoGetSubsValues(isoWin,oldID);

    isoWin->curSubsID = (int)call_data;

    gr_IsoUpdateDialogs(isoWin);
}


void
gr_IsoSetValues(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
    A_IsoWind_t *isoWin=(A_IsoWind_t *)client_data;

	gr_IsoGetSubsValues(isoWin,isoWin->curSubsID);

    return;
}


void
gr_IsoInterrupt(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
    A_IsoWind_t *isoWin=(A_IsoWind_t *)client_data;

	if (isoWin->stopIso == FALSE)
	{
		gr_TextMsgOut("Stopping iso-surface rendering... please wait...\n");
		isoWin->stopIso = TRUE;
	}
}
#endif
