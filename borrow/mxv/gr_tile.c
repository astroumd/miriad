/*
 *	File:		gr_tile.c
 *	Contents:	routines for tile window
 */

#include "gr_com.h"
/* ----------------------- mine from here --- */
#include "gr_xwi.h" 
#include <X11/IntrinsicP.h>

#ifdef XtSpecificationRelease
#include <X11/Xaw/BoxP.h>
/*
#include <X11/Xaw/DialogP.h>
*/
#else
#include <X11/BoxP.h>
/*
#include <X11/DialogP.h>
*/
#endif

/* ----------------------- mine till here --- */

extern	void	gr_ImageSetPixel();

void
gr_TileSelect(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_TileWind_t		*tileWin=(A_TileWind_t *)client_data;
	A_Axes_t			orient;
	A_BossWind_t		*bossWin=tileWin->parent->parent;
	Display				*dpy;
	XButtonPressedEvent *buttonEvent;
	int					i,x,y,nx,ny,newx,newy;
	int				  	xdim,ydim,scale,numtiles,index;
	int j, dumt[100][2];

	orient=tileWin->axesOrient;
	buttonEvent = (XButtonPressedEvent *)call_data;
	x = buttonEvent->x;
	y = buttonEvent->y;

	numtiles = tileWin->numTiles;
	scale = tileWin->scale;
	xdim = td_HdfgetDim(bossWin->data,orient.col);
	ydim = td_HdfgetDim(bossWin->data,orient.row);

	nx = x/scale;
	ny = y/scale;
	x = nx*scale;
	y = ny*scale;
	index = ny*xdim+nx;

	if (tileWin->oldInd != -1) {
		for (i=0;i<numtiles;i++)
			gr_ImageSetPixel(tileWin->imageWin[i],tileWin->oldX,
				 tileWin->oldY,scale,tileWin->oldPix[i]);
	}

	if (tileWin->oldInd == index)
	{
		for (i=0;i<numtiles;i++)
			gr_ImageSetPixel(tileWin->imageWin[i],tileWin->oldX,
				 tileWin->oldY,scale,tileWin->oldPix[i]);
		tileWin->oldInd = -1;
	}
	else
	{

		tileWin->oldInd = index;
		tileWin->oldX = x;
		tileWin->oldY = y;

	
      patchthem(tileWin,numtiles);

		for (i=0;i<numtiles;i++) {
			newx = x; newy = y;
		{ float xpos= (float)nx/(float)xdim,
			ypos = (float)ny/(float)ydim;

		/* Currently, moving the child erases the 'setpixel'. Maybe
		   because setpixel gets called before its repainted???
		*/
			gr_VPortMoveChild2(tileWin->imageVPort[i],
				 tileWin->imageWin[i],
				&xpos, &ypos);
			newx *= xpos;
			newy *= ypos;
		}
			dumt[i][0]=newx; dumt[i][1] = newy;
		}

		for (i=0;i<numtiles;i++) {
			dpy = XtDisplay(tileWin->imageWin[i]);
			tileWin->oldPix[i] = XGetPixel(tileWin->image[i],x,y);
			gr_ImageSetPixel(tileWin->imageWin[i],x,y,scale,
					 WhitePixel(dpy,DefaultScreen(dpy)));
		}

	}
}
/* &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& */
patchthem(tilew , n) 
A_TileWind_t *tilew;	
int n;
{
  int i;
#if 0
/* If this is really needed, it will need to be converted to reference
Athena widgets.
*/
 XwSWindowWidget sw0, sw;
   sw0 = (XwSWindowWidget) ( tilew->imageVPort[0] );

 for (i=0;i<n;i++) {
   sw = (XwSWindowWidget) ( tilew->imageVPort[i] );
 	sw->swindow.hOrigin = sw0->swindow.hOrigin;
 	sw->swindow.vOrigin = sw0->swindow.vOrigin;
  }
#endif
}
/* &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& */
