/*
 *	File:		td_pixel.c
 *	Contents:	td pixel operation calls
 *
 */

#include "td_com.h"
#include "gr_def.h"

float32 mesh[50][50];

void
td_HdfsetPixel(scale,data,cval,ind,baseline,singleline)
int32	scale;
char	*data;
unsigned char	cval;
int32	ind,baseline,singleline;
{
	int32	x,y,YY;

	YY = baseline + ind;

	for (y=0;y<scale;y++)
	{
		for (x=0;x<scale;x++)
			data[x+YY] = cval;
		YY += singleline;
	}
}


/*
 *	Interpolate a square of values
 *	val1--val2
 *	 |       |
 *	 |       |
 *	val4--val3
 */
void td_HdfInterpPixel(scale,min,max, mapping,
	data,val1,val2,val3,val4,ind,baseline,singleline)
int32	scale;
float32	min,max;
pixelMapping *mapping;
unsigned char	*data;
float32 val1,val2,val3,val4;
int32	ind,baseline,singleline;
{
float32 val,y1,y2,x1;
int32	scalei,xi,yi;
int32	x,y,YY;
unsigned char	pix;

	YY = baseline + ind;

	if ((val1 == val2) && (val2 == val3) && (val3 == val4))
	{
		pix = xi_mapPixel(val1,min,max,mapping);
		for (y=0;y<scale;y++)
		{
			for (x=0;x<scale;x++)
				data[x+YY] = pix;
			YY += singleline;
		}
		return;
	}

	scalei = scale-1;

	mesh[0][0] = val1;
	mesh[scalei][0] = val2;
	mesh[scalei][scalei] = val3;
	mesh[0][scalei] = val4;
	y1 = (val4-val1)/(double)scale;
	y2 = (val3-val2)/(double)scale;
	for (y=1;y<scalei;y++)
	{
		yi = y - 1;
		mesh[0][y] = mesh[0][yi]+y1;
		mesh[scalei][y] = mesh[scalei][yi]+y2;
	}
	for (y=0;y<scale;y++)
	{
		x1 = (mesh[scalei][y]-mesh[0][y])/(double)scale;
		for (x=1;x<scalei;x++)
			mesh[x][y] = mesh[x-1][y]+x1;
	}

	for (y=0;y<scale;y++)
	{
		for (x=0;x<scale;x++)
			data[x+YY] = xi_mapPixel(mesh[x][y],min,max,mapping);
		YY += singleline;
	}
}

void
td_VolumeInterp(outval,val1,val2,val3,val4,val5,val6,val7,val8,x,y,z)
float32 *outval,val1,val2,val3,val4,val5,val6,val7,val8;
float32	x,y,z;
{
	float32 y1,y2,y3,y4,x1,x2;
	float32 xb=(float32)1.0-x;
	float32 yb=(float32)1.0-y;
	float32 zb=(float32)1.0-z;

	y1 = y*val4+yb*val1;
	y2 = y*val3+yb*val2;
	y3 = y*val8+yb*val5;
	y4 = y*val7+yb*val6;

	x1 = x*y2+xb*y1;
	x2 = x*y4+xb*y3;

	*outval = z*x2+zb*x1;
}

void
td_ProcInterp(dataout,iscale,dscale,
	i,j,k,val1,val2,val3,val4,val5,val6,val7,val8)
float ***dataout;
int iscale,dscale;
int i,j,k;
double val1,val2,val3,val4,val5,val6,val7,val8;
{
	int x,y,z,xi,yi;
	int px,py,pz;
	double y1,y2,y3,y4,x1,x2,z1;

	px = i*iscale; py = j*iscale; pz = k*iscale;

	if ((val1 == val2) && (val2 == val3) && (val3 == val4) &&
		(val4 == val5) && (val5 == val6) && (val6 == val7) &&
		(val7 == val8))
	{
		for (z=pz;z<=pz+iscale;z++)
			for (y=py;y<=py+iscale;y++)
				for (x=px;x<=px+iscale;x++)
					dataout[x][y][z] = val1;
		return;
	}

	dataout[px][py][pz] = val1;
	dataout[px+iscale][py][pz] = val2;
	dataout[px+iscale][py+iscale][pz] = val3;
	dataout[px][py+iscale][pz] = val4;
	dataout[px][py][pz+iscale] = val5;
	dataout[px+iscale][py][pz+iscale] = val6;
	dataout[px+iscale][py+iscale][pz+iscale] = val7;
	dataout[px][py+iscale][pz+iscale] = val8;

	y1 = (val4-val1)/(double)dscale;
	y2 = (val3-val2)/(double)dscale;
	y3 = (val8-val5)/(double)dscale;
	y4 = (val7-val6)/(double)dscale;
	for (y=py+1;y<py+iscale;y++)
	{
		yi = y - 1;
		dataout[px][y][pz] = dataout[px][yi][pz] + y1;
		dataout[px+iscale][y][pz] = dataout[px+iscale][yi][pz] + y2;
		dataout[px][y][pz+iscale] = dataout[px][yi][pz+iscale] + y3;
		dataout[px+iscale][y][pz+iscale] = 
			dataout[px+iscale][yi][pz+iscale] + y4;
	}
	for (y=py;y<=py+iscale;y++)
	{
		x1 = (dataout[px+iscale][y][pz]-dataout[px][y][pz])/
				(double)dscale;
		x2 = (dataout[px+iscale][y][pz+iscale]-dataout[px][y][pz+iscale])/
				(double)dscale;
		for (x=px+1;x<px+iscale;x++)
		{
			xi = x - 1;
			dataout[x][y][pz] = dataout[xi][y][pz] + x1;
			dataout[x][y][pz+iscale] = dataout[xi][y][pz+iscale] + x2;
		}
	}
	for (y=py;y<=py+iscale;y++)
	{
		for (x=px;x<=px+iscale;x++)
		{
			z1 = (dataout[x][y][pz+iscale]-dataout[x][y][pz])/
					(double)dscale;
			for (z=pz+1;z<pz+iscale;z++)
				dataout[x][y][z] = dataout[x][y][z-1] + z1;
		}
	}
}
