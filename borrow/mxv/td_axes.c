/*
 *	File:		td_axes.c
 *	Contents:	Axes Planes Data calls
 *
 */

#include "td_com.h"
#include "gr_def.h"

extern	Widget          gr_topLevel;
extern	void	td_HdfsetPixel();
extern	void	td_HdfInterpPixel();
extern	char	*gr_GetStringResource();

/*
 *	Return dimension of SDS along axis
 */
int
td_HdfgetDim(hdf,axis)
A_Data_t	*hdf;
int axis;
{
	if (axis < 0)
		axis = -axis;

	return(hdf->dims[axis-1]);
}


/*
 *	Check if plane exists along axis
 */
int32
td_HdfCheckPlane(hdf,axis,planeID)
A_Data_t	*hdf;
int	axis;
int	planeID;
{
	int32 max,plane=0;

	if (planeID < 0)
		plane = 0;
	else
	{
		max = (int32)td_HdfgetDim(hdf,axis);
		if ((int32)planeID >= max)
			plane = max-1;
		else
			plane = planeID;
	}

	return(plane);
}

/*
	Return 1 plane of data from data cube.

planeID	which plane to get.
axis	which of the three axis is perpendicular to the plane.
xs	defines which of the remaining 2 axes is parallel to the rows of data.
xs,ys	If > 0, the data is retrieved from 0..dim-1
	If < 0, the data is retrieved from dim-1..0.
	(Image is reversed).
NOTE:
	For pixmaps, the (0,0) point is upper left rather than lower left
	for the data cube so ys should probably set - of what was selected.
cull	If true, every scale point/line is returned.

data	Pointer to an array large enough to hold the plane. If NULL,
	space will be allocated.

width,	If not NULL, the width and height of the plane is returned.
height
It appears that MXV data cubes are stored [x][y][z].
*/
float *td_getPlaneData(hdf, data, width, height, xs, ys,  axis, planeID, cull)
A_Data_t	*hdf;
Boolean		cull;
int ys,xs,axis,planeID, *width, *height;
float	*data;
{
int	xpos,ypos;	/* Xpositive, Ypositive. */
int32	xincr,yincr;
int32	xstart,ystart, xsize, ysize;
int32	xend,yend, xdim,ydim;
int32	x,y, plane;
float32	***hdfdata=hdf->data, *d;
int32	scale=hdf->scale;

	/* Force plane ID to be valid. */
	plane = td_HdfCheckPlane(hdf,axis,planeID);

	/* Size of plane. */
	xdim = td_HdfgetDim(hdf,xs);
	ydim = td_HdfgetDim(hdf,ys);

	/* How many elements to be returned? */
	if (cull == FALSE)
	{	xsize = xdim;		/* Return the whole plane. */
		ysize = ydim;
	}
	else	/* If culling, adjust allocation size. */
	{	xsize = xdim/scale;
		if (xsize*scale < xdim) xsize++;
		ysize = ydim/scale;
		if (ysize*scale < ydim) ysize++;
	}

	if(data == NULL)
		data = (float *) malloc(xsize*ysize*sizeof(*data));
	if(data == NULL)
	{	gr_TextMsgOut("td_getPlaneData: Could not allocate memory.");
		return NULL;
	}
	if(width != NULL)
		*width = xsize;
	if(height != NULL)
		*height = ysize;

	if (xs > 0)
	{	xpos=1; 
		if (cull == FALSE)
			xincr = 1;
		else
			xincr = hdf->scale;
		xstart = 0;
		xend = xdim;
	}
	else
	{	xpos=0;
		xstart = xdim-1;
		xend = -1;
		xs = -xs;			/* abs(xs) hr 6/30/92 */
		if (cull == FALSE)
			xincr = -1;
		else
			xincr = -hdf->scale;
	}

	/* MXV traditional has the check for ys > 0 so images are rightside
	   up. Hence the need to negate ys if it wants data for an image.
	*/
	if (ys < 0)
	{	ypos=0;
		ystart = ydim-1;
		yend = -1;
		if (cull == FALSE)
			yincr = -1;
		else
			yincr = -hdf->scale;
	}
	else
	{	ypos=1;
		ystart = 0;
		yend = ydim;
		ys = -ys;			/* abs(ys) hr 6/30/92 */
		if (cull == FALSE)
			yincr = 1;
		else
			yincr = hdf->scale;
	}

	d = data;
	switch(axis)
	{
		case 1: /* axis=X */
			y = ystart;
			while ( (ypos && (y < yend)) ||
					((!ypos) && (y > yend)) )
			{
				x = xstart;
				while ( (xpos && (x < xend)) ||
						((!xpos) && (x > xend)) )
				{
					if (xs == 2)	/* Y */
						*d++ = hdfdata[plane][x][y];
					else		/* Z */
						*d++ = hdfdata[plane][y][x];
					x = x + xincr;
				}	
				y = y + yincr;
			}
			break;
		case 2: /* axis=Y */
			y = ystart;
			while ( (ypos && (y < yend)) ||
					((!ypos) && (y > yend)) )
			{
				x = xstart;
				while ( (xpos && (x < xend)) ||
						((!xpos) && (x > xend)) )
				{
					if (xs == 1)	/* X */
						*d++ = hdfdata[x][plane][y];
					else		/* Z */
						*d++ = hdfdata[y][plane][x];
					x = x + xincr;
				}	
				y = y + yincr;
			}
			break;
		case 3: /* Axis=Z */
			y = ystart;
			while ( (ypos && (y < yend)) ||
					((!ypos) && (y > yend)) )
			{
				x = xstart;
				while ( (xpos && (x < xend)) ||
						((!xpos) && (x > xend)) )
				{
					if (xs == 1)	/* X */
						*d++ = hdfdata[x][y][plane];
					else		/* Y */
						*d++ = hdfdata[y][x][plane];
					x = x + xincr;
				}
				y = y + yincr;
			}
			break;
	}

	return data;
}

/*
 *	Convert numeric data to pixel data
 */
unsigned char
*td_HdfgetPixData(hdf,ys,xs,axis,planeID,interp,cull, mapping)
A_Data_t *hdf;
int 	ys,xs,axis,planeID;
Boolean	interp,cull;
pixelMapping *mapping;
{
unsigned char	*data;
int32	c=0,k=0,baseline=0,linesize,singleline;
int32	xsize,ysize;
int32	x,y,xdim,ydim, width, height, val;
int32	scale=hdf->scale;
float32	min=hdf->min,max=hdf->max,frac=hdf->rangeFrac;
float32	*pd, *plndata;

	xdim = td_HdfgetDim(hdf,xs);
	ydim = td_HdfgetDim(hdf,ys);
	if ((cull == FALSE) && (interp == TRUE))
	{
		xdim--; ydim--;
	}
	if (cull == FALSE)
	{
		xsize = xdim*scale; ysize = ydim*scale;
	}
	else
	{
		xsize = xdim/scale;
		if (xsize*scale < xdim) xsize++;
		ysize = ydim/scale;
		if (ysize*scale < ydim) ysize++;
	}

	data = (unsigned char *)td_Malloc1D(xsize,ysize,
			(long)(sizeof(unsigned char)),"td_HdfgetPixData");
	if (data == NULL)
	{	return((unsigned char *)NULL);
	}
	plndata = td_getPlaneData(hdf, NULL, &width, &height,
				xs, -ys,  axis, planeID, cull);
	if(plndata == NULL)
	{	free(data);
		return NULL;
	}

	singleline = xdim*scale;	/* # of pixels in 1 line. */
	linesize = singleline*scale;	/* Above with vert scaling. */
	c = 0;
	if(interp)
	{	printf("Interpolating\n");
		for(pd=plndata, y=0; y<height; y++)
		{	k = 0;
			for(x=0; x< width; pd++, x++)
			{	td_HdfInterpPixel(scale,min,max, mapping, data,
				  *pd, *(pd+1), *(pd+width), *(pd+width+1),
				  k, baseline, singleline);
				k += scale;
			}
			baseline += linesize;	/* Next row of pixels. */
		}
	}
	else
		xi_mapPixels(plndata, width, height, scale, data, min, max,
								mapping);
	free(plndata);
	return(data);
}

/*
 *	Get numeric data for spreadsheet display
 */
/* Format used to generate strings.*/
#define	FORMAT	"%10.2E"
/* max length of that string plus the NULL; */
#define	STRLEN	11

char **td_HdfgetPlaneData(hdf,cull,ys,xs,axis,planeID)
A_Data_t	*hdf;
Boolean		cull;
int ys,xs,axis,planeID;
{
char	**strngs, *strs, *strsp, **strngsp;
char	value[80];
int	i=0,xpos,ypos;
int32	xincr,yincr;
int32	xstart,ystart;
int32	xend,yend;
int32	x,y, width, height;
int32	xdim,ydim;
float32	*plndata, *pd;

	plndata = td_getPlaneData(hdf, NULL, &width, &height,
				xs, -ys,  axis, planeID, cull);
	if(plndata == NULL)
		return NULL;

	/* 2D array of character string pointers. */
	strngs = td_Malloc2D(width, height,
			(long)sizeof(char *),"td_HdfgetPlaneData");

	if(strngs == NULL)
	{	free(plndata);
		return(NULL);
	}
	/* Allocate enough memory for the strings + some more. Since we
	   can't be sure that the sprintf will only generate STRLEN-1 chars,
	   we give some fudge at the end. Its OK for earlier ones to be
	   long since we will NULL terminate as we go.
	*/
	strs = malloc((width*height+1)*STRLEN);
	if(strs == NULL)
	{	gr_TextMsgOut(
			"td_HdfgetPlaneData: Could not allocate memory.");
		free(strngs);
		free(plndata);
		return(NULL);
	}

	strngsp = strngs;
	strsp = strs;
	pd = plndata;
	for(y = 0; y < height; y++)
	{	for(x=0; x < width; pd++, x++)
		{	sprintf(strsp,FORMAT, *pd);/* New string.	  */
			*strngsp++ = strsp;	/* Pointer to new string. */
			*(strsp+STRLEN-1) = '\0'; /* Make sure it ends.	  */
			strsp += STRLEN;	/* Next string space.	  */
		}
	}

	*strngsp = NULL;	/* NULL terminate pointer list.		  */
	return (strngs);
}

/*
 *	Get horizontal scale values for spreadsheet display
 */
char
**td_HdfgetHScale(hdf,xs,cull)
A_Data_t	*hdf;
int xs;
Boolean cull;
{
	char	value[15];
	int	i=0;
	int	x;
	int	xdim,xpos,xsize;
	int	xincr,xstart,xend;
	char	**strngs;

	xdim = xsize = td_HdfgetDim(hdf,xs);
	if (cull == TRUE)
	{
		xsize = xsize/hdf->scale;
		if (xsize*hdf->scale < xdim)
			xsize++;
	}
	strngs = td_Malloc2D((int)xsize,(int)1,(long)sizeof(char *),
				"td_HdfgetHScale");

	if (xs > 0)
	{
		xpos = 1;
		if (cull == FALSE)
			xincr = 1;
		else
			xincr = hdf->scale;
		xstart = 0;
		xend = xdim;
	}
	else
	{
		xpos = 0;
		if (cull == FALSE)
		{
			xincr = -1;
			xstart = xdim-1;
		}
		else
		{
			xincr = -hdf->scale;
			xstart = xdim-1;	/* hr 3/21/92 from kkk above.*/
/*			xstart = xstart - (xstart % hdf->scale);*/
		}
		xend = -1;
	}

	x = xstart;
	while ( (xpos && (x < xend)) ||
			((!xpos) && (x > xend)) )
	{
/*		sprintf(value,"%6d",x);*/
		/* Length of value needs to be same as length of SS entries. */
		sprintf(value,"%6d    ",x);	/* 6 digits + 4 spaces.	*/
		strngs[i] = td_Malloc1D(strlen(value),1,(long)sizeof(char),
					"td_HdfgetHScale");
#ifdef RIOS
		Strcpy(strngs[i],value);
#else
		strcpy(strngs[i],value);
#endif
		x = x + xincr;
		i++;
	}	
	strngs[i] = NULL;

	return(strngs);
}


/*
 *	Get vertical scale values for spreadsheet display
 */
char
**td_HdfgetVScale(hdf,ys,cull)
A_Data_t	*hdf;
int ys;
Boolean	cull;
{
	char	value[10];
	int		i=0;
	int		ypos,y;
	int		ydim,ysize;
	int		yincr,ystart,yend;
	char	**strngs;

	ydim = ysize = td_HdfgetDim(hdf,ys);
	if (cull == TRUE)
	{
		ysize = ysize/hdf->scale;
		if (ysize*hdf->scale < ydim)
			ysize++;
	}
	strngs = td_Malloc2D((int)1,(int)ysize,(long)sizeof(char *),
				"td_HdfgetVScale");

	if (ys < 0)
	{
		ypos = 1;
		if (cull == FALSE)
			yincr = 1;
		else
			yincr = hdf->scale;
		ystart = 0;
		yend = ydim;
	}
	else
	{
		ypos = 0;
		if (cull == FALSE)
		{
			yincr = -1;
			ystart = ydim-1;
		}
		else
		{
			yincr = -hdf->scale;
			ystart = ydim-1;	/* hr 3/21/92 from kkk above.*/
/*			ystart = ystart - (ystart % hdf->scale);*/
		}
		yend = -1;
	}

	y = ystart;
	while ( (ypos && (y < yend)) ||
			((!ypos) && (y > yend)) )
	{
/*		sprintf(value,"%6d",y);*/
		sprintf(value,"%5d",y);
		strngs[i] = td_Malloc1D(strlen(value),1,(long)sizeof(char),
					"td_HdfgetVScale");
#ifdef RIOS
		Strcpy(strngs[i],value);
#else
		strcpy(strngs[i],value);
#endif
		y = y + yincr;
		i++;
	}	
	strngs[i] = NULL;

	return(strngs);
}
