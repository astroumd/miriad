/*
 *	File:		gr_view.c
 *	Contents:	View level routines for graphics module
 */

#include "gr_com.h"

extern	void	gr_MatInverse();
extern	void	td_VolumeInterp();

void
gr_Box2Data(box,x,y,z,x1,y1,z1)
A_Box_t	*box;
double x,y,z;
double *x1,*y1,*z1;
{
	*x1 = (double)(box->invmatrix[1][1]*x + box->invmatrix[2][1]*y +
                   box->invmatrix[3][1]*z + box->invmatrix[4][1]);
	*y1 = (double)(box->invmatrix[1][2]*x + box->invmatrix[2][2]*y +
                   box->invmatrix[3][2]*z + box->invmatrix[4][2]);
	*z1 = (double)(box->invmatrix[1][3]*x + box->invmatrix[2][3]*y +
                   box->invmatrix[3][3]*z + box->invmatrix[4][3]);

	*x1 = (*x1-box->xorig)/box->dimFactor;
	*y1 = (*y1-box->yorig)/box->dimFactor;
	*z1 = (*z1-box->zorig)/box->dimFactor;
}


char *gr_ViewgetData(box,scale,viewType,bossWin, mapping)
A_Box_t *box;
int		scale;
int		viewType;
A_BossWind_t	*bossWin;
pixelMapping	*mapping;
{
	float32		***sds=bossWin->data->data,val;
	float32		min=(float32)bossWin->data->min;
	float32		max=(float32)bossWin->data->max;
	float32		frac=(float32)bossWin->data->rangeFrac;
	Boolean		interp;
	double		x1,y1,z1,xp,yp,zp,i,j,incr;
	char		*data;
	int			count,x,y,z;
	int			xdim,ydim,zdim;
	int			xstart,xend,ystart,yend;

	if (viewType == 1)
	{
		xstart = (int)box->boundxmin;
		xend   = (int)box->boundxmax;
		ystart = (int)box->boundymin;
		yend   = (int)box->boundymax;
	}
	else
	{
		xstart = (int)box->xmin;
		xend   = (int)box->xmax;
		ystart = (int)box->ymin;
		yend   = (int)box->ymax;
	}

	xdim   = box->xdim-1;
	ydim   = box->ydim-1;
	zdim   = box->zdim-1;
	incr   = (double)1.0/(double)scale;
	box->xpicsize = (int)((xend-xstart)*scale);
	box->ypicsize = (int)((yend-ystart)*scale);
	if ((box->xpicsize == 0) || (box->ypicsize == 0))
	{
		gr_TextMsgOut("Warning:\t Please select a valid slice first!\n");
		return(NULL);
	}
	if ((data  = td_Malloc1D(box->xpicsize,box->ypicsize,
			 (long)sizeof(unsigned char),"td_Malloc1D")) == NULL)
		return(NULL);

	gr_MatInverse(box->matrix,box->invmatrix);

	interp = bossWin->arbWin->interp;
	count = 0;
	for (i=(double)yend;i>(double)ystart;i-=incr)
	{
		for (j=(double)xstart;j<(double)xend;j+=incr)
		{
			gr_Box2Data(box,j,i,box->depth,&x1,&y1,&z1);
			x = (int)x1; y=(int)y1; z=(int)z1;
			if (((x >= 0) && (x < xdim)) &&
				((y >= 0) && (y < ydim)) &&
				((z >= 0) && (z < zdim)))
			{
				if (interp == TRUE)
				{
					xp=x1-(double)x; yp=y1-(double)y; zp=z1-(double)z;
					td_VolumeInterp(&val,sds[x][y][z],sds[x+1][y][z],
						sds[x+1][y+1][z],sds[x][y+1][z],sds[x][y][z+1],
						sds[x+1][y][z+1],sds[x+1][y+1][z+1],
						sds[x][y+1][z+1],xp,yp,zp);
				}
				else
					val = sds[x][y][z];

				data[count]=xi_mapPixel(val,min,max, mapping);
			}
			else
				data[count]=0;
			count++;
		}
	}	
	return(data);
}
