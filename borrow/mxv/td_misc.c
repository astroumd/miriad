/* td_misc.c
Miscellaneous non graphics support routines
*/
#include <math.h>
#include "X11/Xlib.h"
#include "X11/Intrinsic.h"	/* Picks up definition of Boolean. */
#include "mxv.h"
#include "gr_def.h"

#define	rtod  (180.0 / PI)
#define	rtoh  (12.0  / PI)
#define	ABS(x)	((x) < 0 ? -(x) : (x))

/* ------------------------------------------------------------------ */
/* converts angle into HH:MIN:SEC string
From jng's degtoang

input:
angle	float	Input angle
degrees	Boolean	If true angle is in degrees. Otherwise it is in radians.
str	String	Output array to hold result.

Return:
	Pointer to str.
*/
#define	RADTODEG(x)	((x)*(180.0/PI))

char *angleToString(angle,degrees, str)
float	angle;
Boolean	degrees;
char str[];
{
char sign;
int deg, min;
float sec;
float v;

	if(! degrees)		/* Convert from radians if necessary. */
		angle = RADTODEG(angle);
	if(angle >= 0.0)
		sign = '+';
	else
	{	sign='-';
		angle = - angle;
	}

	v = angle;

	deg = (int) v;
	min = (v-(float)deg)*60;

	sec = (v - (float)deg - (float)min/60.0) *3600.0;
	sprintf(str,"%c%d:%d:%05.2f",sign,deg,min,sec);
	return str;
}

/* Whenever we deal with RA___SIN, we need to make sure that there is a
DEC__SIN available to provide a conversion factor. This routine takes a
3 element array of cvalues and returns the indices of the RA___SIN and
the DEC__SIN entries. If there isn't an entry -1 is returned instead of
an index.
*/
void getRaDec(cv, raindex, decindex)
Cvalues	cv;
int	*raindex, *decindex;
{
int	ra, dec, i;

	ra = dec = -1;
	for(i=0; i< 3; i++, cv++)
		if(cv->ctype == RA___SIN)
			ra = i;
		else
		if(cv->ctype == DEC__SIN)
			dec = i;
	if(raindex != NULL)
		*raindex = ra;
	if(decindex != NULL)
		*decindex = dec;
	return;
}

/****************************************************************************/
/* Convert an axis index (0..max -1) into a value.
ds	Data struct for dataset.
index	How far from '0' pixel are we. (0..max - 1).
axis	Which axis we are looking at (1:x, 2:y, 3:z).
	(Values from A_Axes_t struct). If axis is < 0, the index is assumed
	to be relative to the high side (0 means max-1).
adjust	Normally certain axis types (ie RA--SIN) need a special adjustment.
	If adjust is true AND the axis is this type, the adjustment is made.
	adjust should be FALSE if td_GetAxisValue is being called by I/O
	routines and TRUE if being called by label generating routines.

Returns a floating point value.
*/
float td_GetAxisValue(ds, index, axis, adjust)
A_Data_t	*ds;
int		index;
int		axis;
Boolean		adjust;
{
float	value0, delta, offset, value, mult;
Cvalues	cv;
int	i, ra, dec;

	/* If axis < 0 then compute relative to other end.
	   Then convert to 0..n-1 rather than 1..n.
	*/
	if(axis < 0)
	{	axis = -axis -1;
		index = ds->dims[axis] - index - 1;
	}
	else
		axis -= 1;

	/* HDF format is easy. */
	if(ds->format == HDF)
		value =  ds->scaleStr[axis][index];
	else
	{	cv = &ds->cvals[axis];
		value0 = cv->crval;
		delta = cv->cdelt;
		mult = 1.0;
		/* Adjustment for RA--SIN */
		if( adjust && (cv->ctype == RA___SIN))
		{	/* Have to find the DEC--SIN ordinate. */
			getRaDec(ds->cvals, &ra, &dec);
			if( dec >= 0)
			{	delta /= cos(ds->cvals[dec].crval);
				mult = 1.0/15.0;
			}
		}

		offset = (double)index - cv->crpix;
		value = (value0 + offset*delta)*mult;
	}
	return value;
}


/****************************************************************************/
/* Convert an axis index to a string value. Used for labeling axis tick
marks on plots.

index	how far from '0' pixel are we.
axis	Which cube axis we're looking at. (+/-1..3).
fmt	Format specifier to use if not converting to H:M:S. If NULL,
	a default is used. ("%5.2f").
str	output string. If NULL. An internal static string will be used.

Returns a pointer to the string.
*/
char *td_GetAxisValueString(ds, index, axis, fmt, strng)
A_Data_t	*ds;
int		index;
int		axis;
char		*fmt;
char		*strng;
{
float	value0, delta, offset, value, mult;
static	char str[80];
char	*s;
Cvalues	cv;
Boolean	havedecsin;
int	ra, dec;

	if(fmt == NULL)
		fmt = "%5.2f";
	value = td_GetAxisValue(ds, index, axis, TRUE);

	if(strng == NULL)
		strng = str;
	s = strng;

	/* HDF format does not have the values needed. */
	if(ds->format == HDF)
	{	sprintf(strng, fmt, value);
		return strng;
	}

	/* Assume anything else is MIRIAD or FITS.
	   The cvals struct must be setup.
	*/

	/* Convert to a string. RA---DEC & DEC--SIN are
	   converted to H:MM:SECS. The third axis is a plain floating pt
	   number. RA---DEC needs a DEC--SIN axis for the conversion.
	*/
	getRaDec(&ds->cvals[0], &ra, &dec);
	havedecsin = (dec >= 0);

	cv = &ds->cvals[ABS(axis)-1];
	if( ((cv->ctype == RA___SIN) && havedecsin) || (cv->ctype == DEC__SIN))
	{	angleToString(value, FALSE, strng);
		if(*s == '+') s += 1;	/* Ignore any leading + sign. */
	}
	else
		sprintf(strng, fmt, value);
	return s;
}

/* ------------------------------------------------------- */
/* Convert the three 'cval' elements to strings for printing.
*/
void td_convertcv(cv, s1, s2, s3)
Cvalues	cv;
char	*s1, *s2, *s3;
{
	if(cv->ctype == RA___SIN)	/* --- First type of values (RA) */
	{	degtoang ((float) (cv->crval*rtoh),s1);
		sprintf(s2, "%8.3f", cv->crpix);
		degtoang ((float) (cv->cdelt*rtod),s3);
	}
	else	/* --- second type of values (dec) */
	if(cv->ctype == DEC__SIN)
	{	degtoang((float) (cv->crval*rtod),s1);
		sprintf(s2,"%8.3f",(float) (cv->crpix));
 		degtoang ((float) (cv->cdelt*rtod),s3);
	}
	else	/* --- third set of values (vel) */
	{	/* (Just plain folks). */
		sprintf(s1, "%8.3f", cv->crval);
		sprintf(s2, "%11.3f", cv->crpix);
		sprintf(s3, "%8.3f", cv->cdelt);
	}
}

/* Convert between X11 and Data coordinates.
If the axis value of the A_Axes_t struct is negative, the value is
reversed. Except it is assumed that X11's Y values are at the top and
Data values are at the bottom.

orient	A_Axes_t struct for data
xdim,	size of data plane
ydim

inx,	Values to be converted
iny

outx,	Output pointers.
outy
If outx or outy is NULL, it isn't returned.
*/
void td_convertXY(orient, xdim, ydim, xin, yin, outx, outy)
A_Axes_t	*orient;
int		xdim, ydim, xin, yin, *outx, *outy;
{

	if(outx != NULL)
	{	if (orient->col < 0)
			*outx = xdim-xin-1;
		else
			*outx = xin;
	}
	if( outy != NULL)
	{	if (orient->row > 0)	/* Note the different sense. */
			*outy = ydim-yin-1;
		else
			*outy = yin;
	}
}

