/*
 *	File:		gr_vbuff.c
 *	Contents:	routines for V-buffer
 */

#include "gr_com.h"
#include <math.h>

#define	MAXCOLOR	254

double
gr_VbuffgetIntensity(subsWin,val)
A_SubsWind_t *subsWin;
float32	val;
{
	return(pow((double)((val-subsWin->hdf->min)/subsWin->hdf->range),
			subsWin->gamma));
}

double
gr_VbuffgetOpacity(subsWin,val,r,g,b)
A_SubsWind_t *subsWin;
double	  val;
int	 *r,*g,*b;
{
	A_SubsType_t	*subs=subsWin->subs;
	double			range;
	int i;

	for (i=0;i<subsWin->numSubs;i++)
		if ((val > subs[i].lower) &&
			(val < subs[i].upper))
		{
			range = 0.2*(val-subs[i].lower)/(subs[i].upper-subs[i].lower);
			*r = 0.8*subs[i].red+subs[i].red*range;
			*g = 0.8*subs[i].green+subs[i].green*range;
			*b = 0.8*subs[i].blue+subs[i].blue*range;
			return(subs[i].opacity);
		}
	return((double)-1.0);
}

double
gr_VbuffgetAtten(subsWin,val)
A_SubsWind_t *subsWin;
double val;
{
	return(subsWin->depthcueSquared/pow((val+subsWin->depthcue),2.0));
}

void
gr_VbuffIntegrate(subsWin,red,green,blue,opacity,atten,x,y)
A_SubsWind_t *subsWin;
int		red,green,blue;
double	opacity,atten;
int	x,y;
{
	int	r,g,b;
	double	factor;

	if (subsWin->vbuff[x][y].opacity < (double)1.0)
	{
		factor = atten*opacity*((double)1.0 - subsWin->vbuff[x][y].opacity);
		if (subsWin->vbuff[x][y].red < MAXCOLOR)
		{
			subsWin->vbuff[x][y].red +=
				red*factor+subsWin->amb;
			if (subsWin->vbuff[x][y].red > MAXCOLOR)
				subsWin->vbuff[x][y].red = MAXCOLOR;
		}
		if (subsWin->vbuff[x][y].green < MAXCOLOR)
		{
			subsWin->vbuff[x][y].green +=
				green*factor+subsWin->amb;
			if (subsWin->vbuff[x][y].green > MAXCOLOR)
				subsWin->vbuff[x][y].green = MAXCOLOR;
		}
		if (subsWin->vbuff[x][y].blue < MAXCOLOR)
		{
			subsWin->vbuff[x][y].blue +=
				blue*factor+subsWin->amb;
			if (subsWin->vbuff[x][y].blue > MAXCOLOR)
				subsWin->vbuff[x][y].blue = MAXCOLOR;
		}

		subsWin->vbuff[x][y].opacity +=
		(opacity - (subsWin->vbuff[x][y].opacity * opacity));

	}
}
