/* td_fits.c
Interface routines between mxv and the fits reader routines.

TODO:
*/

#ifdef sun
#define bcopy(a,b,c) memcpy((b),(a),(c))
#endif

#include "td_inc.h"
#include "fits.h"

#ifndef __convex__
#include <string.h>
/*
#include <strings.h>
*/
extern char * malloc();
#endif

extern A_FITS_t *fitopen(/* name, status, naxis, nsize */);

/* Crval & cdelt are expected to be in radians & km/s but are stored in
degrees & m/s in FITS files. Scale supplies the appropriate fudge factors.
*/
/*
static float	Scale[] = {
		PI/180.0, PI/180.0, .001
		};
#define SCALELEN (sizeof(Scale)/sizeof(*Scale))
*/
#define	RASINSCALE	(PI/180.0)
#define	DECSINSCALE	(PI/180.0)
#define	VELOSCALE	.001

/* Return scaled version of a FITS 'c' value.
value	value to be scaled.
ctype	Quark giving the 'ctype' of the value.
output	TRUE scale for output. FALSE, scale for input.
*/
static float fitsScale(value, ctype, output)
float	value;
Quark	ctype;
Boolean	output;
{
float	scale;

	if(ctype == RA___SIN)
		scale = RASINSCALE;
	else
	if(ctype == DEC__SIN)
		scale = DECSINSCALE;
	else
	if(ctype == VELO_LSR)
		scale = VELOSCALE;
	else
		scale = 1.0;

	if(output)
		value /= scale;
	else
		value *= scale;

	return value;
}

/* Read in a FITS file and set some of the parameters in the A_Data_t
struct.
The struct needs to have the fits file name setup.

Returns -1 for error, else 0.
*/
int td_FITSLoad( data)
A_Data_t	*data;
{
A_FITS_t *fits;
float	*rowdata, datum;
Boolean first=TRUE;
int	i,j,k, err=0;
long 	imagesize, rowsize, tempsiz;
char	keyword[9], msg[80];
Cvalues	cv;

	if(data == NULL)
		return -1;

	/* set to something innocuous. */
	data->numSDs = 0;	/* May get reset to 1 later. */

	/* Open fits file. */
	if( (fits = fitopen(data->pathName, "old", 3, data->dims))== NULL)
		return -1;
	data->rank = fits->naxis;

	/* Get labels and scale values for axis. */
	/* Keywords must be upper case for FITS.
	*/
	for(	cv = &data->cvals[0], i=0;
		i < sizeof(data->cvals)/sizeof(*data->cvals);
		cv++, i++)
	{	sprintf(keyword, "CTYPE%d", i+1);
		fitrdhda(fits, keyword, data->label[i], NULL);
		cv->ctype = StringToQuark(data->label[i]);
		/* Floating point keywords. */
		sprintf(keyword, "CRVAL%d", i+1);
		fitrdhdr(fits, keyword, &(cv->crval), 0.0);
		sprintf(keyword, "CRPIX%d", i+1);
		fitrdhdr(fits, keyword, &(cv->crpix), 0.0);
		sprintf(keyword, "CDELT%d", i+1);
		fitrdhdr(fits, keyword, &(cv->cdelt), 1.0);
		cv->crval = fitsScale(cv->crval, cv->ctype, FALSE);
		cv->cdelt = fitsScale(cv->cdelt, cv->ctype, FALSE);
	}

	fitrdhda(fits, "OBJECT", data->dataName, NULL);
	/* BZERO/BSCALE is handled in fitsread routines. */


	/* Read in image data. */
	/* This code is lifted from td_miriad.c */
	rowdata  = (float32 *)td_Malloc1D(1,data->dims[0],
			(unsigned int)sizeof(float32), "td_FITSLoad");
	if(rowdata==NULL)
		err = -1;

	rowsize = data->dims[0]* sizeof(float32); /* size of one row of data */

/* ******************************** */
	data->data   = (float32 ***) td_Malloc3Dfloat32(data->dims[0],
					data->dims[1], data->dims[2]);

	if((data->data != NULL) && (err >= 0))
	{	for (i=0;i<data->dims[2];i++)	/* Read each plane. */
		{	/* Request which plane to read. */
			if( (err = fitsetpl(fits, 1, &i)) != 0)
			{	printf("%s\n", fits_error(err));
				break;
			}
			/* get a row of FITS data, then flip and store in
			   data->data
			  */
			for (j=0;j<data->dims[1];j++)
			{	err = fitread(fits, j, rowdata);
						
				if(err != 0)
   				{	sprintf(msg, "%s\n", fits_error(err));
					gr_TextMsgOut(msg);
					free(data->data);
					data->data = NULL;
					return (-1);
				}

				/* Copy data, do min/max check. */
				for (k=0;k<data->dims[0];k++)
				{	datum=data->data[k][j][i] = rowdata[k];
					if (first)
					{	first = FALSE;
						data->min = data->max =
							data->data[0][0][0];
					}
					else
					if (data->min > datum)
						data->min = datum;
					else
					if (data->max < datum)
						data->max = datum;
				}
			}
		}
		fitclose(fits);
		data->range = data->max - data->min;
/*		printf("td_fits: max=%f min=%f\n",data->max,data->min);*/
		td_Free(rowdata);

		if (err == -1)
		{	sprintf(msg,
				"***ERROR: Cannot read 3D image from %s.\n",
					data->pathName);
			gr_TextMsgOut(msg);
			gr_TextMsgOut
			("Are you sure this is a legal FITS dataset?\n");
				td_Free3d(data->data);
		}
		else	/* Sucessful read. */
		{	data->format = FITS;
			data->numSDs = 1;
		}
	}
	else
	{	td_Free3d(data->data);
		err = -1;
		sprintf(msg,
		  "***ERROR: Not enough memory to load FITS image %s.\n",
					data->pathName);
		gr_TextMsgOut(msg);
		gr_TextMsgOut("I suggest you quit and retry the loading.\n");
	}

	return err;
}

#if 0
/* Write a FITS file using parameters in the A_Data_t struct.
The struct needs to have the fits file name setup.
Basically, the inverse of td_FITSLoad.

The argument scale is a floating point array of length data->rank. It
contains values used to scale crval and crdelt keywords. If it is
NULL, the Scale array above is used. NOTE: scale values are divided
into the crval/crdelt values.

Returns -1 for error, else 0.
*/
int td_FITSWrite( data, scale)
A_Data_t	*data;
float		*scale;
{
A_FITS_t *fits;
float	*rowdata, datum;
int	i,j,k, err=0, naxis;
long 	imagesize, rowsize, tempsiz;
char	keyword[9];
Cvalues	cv;

	if( (data == NULL) || (data->data == NULL))
		return -1;

	if(scale == NULL)	/* Use default. */
		scale = Scale;

	naxis = data->rank;
	/* Open fits file. */
	if( (fits = fitopen(data->pathName, "new", naxis, data->dims))== NULL)
		return -1;

	/* Don't know what to do if not FITS or MIRIAD format.!!!! */
	if(data->format == HDF) goto WRITEDATA;

	/* Write labels for axes. */
	/* Keywords must be upper case for FITS.
	   Use keyword for default so can figure out what was missing.
	*/
	for(cv=&data->cvals[0], i=0; i<naxis; cv++, i++)
	{	sprintf(keyword, "CTYPE%d", i+1);
		fitwrhda(fits, keyword, data->label[i], NULL);
		/* Floating point keywords. */
		sprintf(keyword, "CRVAL%d", i+1);
		datum = cv->crval/cv->scale;
		fitwrhdr(fits, keyword, datum, NULL);
		sprintf(keyword, "CRPIX%d", i+1);
		fitwrhdr(fits, keyword, cv->crpix, NULL);
		sprintf(keyword, "CDELT%d", i+1);
		datum = cv->cdelt/cv->scale;
		fitwrhdr(fits, keyword, datum, NULL);
	}

	if(strlen(data->dataName) > 0)
		fitwrhda(fits, "OBJECT", data->dataName, NULL);
	else
	{ char *r;
		if( (r = rindex(data->pathName, "/")) == NULL)
			r = data->pathName;
		else
			r += 1;
		fitwrhda(fits, "OBJECT", r, NULL);
	}

WRITEDATA:
	/* Write image data. */
	rowdata  = (float32 *)td_Malloc1D(1,data->dims[0],
			(unsigned int)sizeof(float32), "temp float32");
	if(rowdata==NULL)
	{	gr_TextMsgOut("Count Not allocate memory for write.\n");
		fitclose(fits);
		return -1;
	}
	rowsize = data->dims[0]* sizeof(float32); /* size of one row of data */

	if((data->data != NULL) && (err >= 0))
	{	for (i=0;i<data->dims[2];i++)	/* Write each plane. */
		{	/* Request which plane to write. */
			if( (err = fitsetpl(fits, 1, &i)) != 0)
			{	printf("%s\n", fits_error(err));
				break;
			}
			/* Flip data then write a row of FITS data;
			  */
			for (j=0;j<data->dims[1];j++)
			{
				/* Copy data, do min/max check. */
				for (k=0;k<data->dims[0];k++)
				{	rowdata[k] = data->data[k][j][i];
				}
if(j < 3)
{ int d;
for(d=0; d< data->dims[0]; d++)
	printf("%5.2f ", rowdata[d]);
printf("\n");
}
				err = fitwrite(fits, j, rowdata);
				if(err != 0)
   				{	printf("%s\n", fits_error(err));
					td_Free(rowdata);
					return (-1);
				}

			}
		}
		fitclose(fits);
		if (err == -1)
		{	sprintf(msg,
				"***ERROR: Cannot write 3D image to %s.\n",
					data->pathName);
			gr_TextMsgOut(msg);
		}
	}

	td_Free(rowdata);
	return err;
}
#endif

/* return FITS header attributes as text
	From td_miriad.c
*/
char
*td_FITSgetStats(db,nColors,nSplitColors)
A_Data_t    *db;
int         nColors,nSplitColors;
{
int  i,j,ret;
char *strng=NULL;
Cvalues	cv;

	float rtod = 180.0 / PI;
	float rtoh = 12.0  / PI;

   char s1[40],s2[40],s3[40]; /* temp strings */

    if (db->format != FITS) return (NULL);
/*	 printf("in TDFITSSTATS\n");*/
    strng = td_Malloc1D(1500,1,sizeof(char),"td_Malloc1D:string");
    sprintf(strng,"FITS File: %s\n", db->pathName);

		for (i=0;i<3;i++) {
            sprintf(strng,"%s%s: dim=%ld,\tlabel=%s\n",strng,
                axesLabels[i],db->dims[i], db->label[i]);
        }
    	sprintf(strng,"%sMax= %8.5f, Min=%8.5f\n", strng,db->max,db->min);
	sprintf(s1, "Object: %s", db->dataName);
/*Can't read header any more.
	fitrdhda(fits, "TELESCOP", s3, "");
	sprintf(s2, "Telescope: %s", s3);
    	sprintf(strng,
	  "%sHeader Data:\n%s\t%s\nNo.  crval        crpix        cdelt\n",
		strng, s1, s2);
*/
    	sprintf(strng,
	  "%sHeader Data:\n%s\nNo.  crval        crpix        cdelt\n",
		strng, s1);

		/* ---  Print FITS header data, with formatting  -- */

	for(cv = &db->cvals[0], i=1; i<= 3; cv++, i++)
	{	td_convertcv(cv, s1, s2, s3);
		sprintf(strng,"%s %d  %s  %s  %s\n", strng, i, s1, s2, s3);
	}

    db->range = db->max - db->min;
    db->rangeFrac = (float32)((float32)nColors/db->range);
    db->rangeFracSplit = (float32)((float32)nSplitColors/db->range);

    return(strng);
}


/*
Write a plane of data to a FITS file.
Need:
Pointer to data
width, height of data
cvals,
plane id
object name
file name
transpose?
Access direction

Need to convert plane number into proper cvalue. (May not be a cube plane).
Support writing subplane?? (No since MXV doesn't need it.)

data, width, height, *cvalues, transpose, plane #, name, fn
data	Pointer to a array [height][width].
	if width or height are negative, ouput is from high to low.
cvalues	Pointer to a 3 element array of cvalues.
	[0] is width, [1] height, [2] z
transpose
	If true output is transposed.
name	Object name
fn	where to write.
*/


/* Return a row or column from a 2D array.
data	Pointer to an array [height][width].
lineno	Which row or column to return.
getrow	If true, return a row  [lineno](0..width).
	If false, return a col [0..height][lineno].
flip	if true return [max..0] rather than [0..max].
rowbuf	Pointer to an array big enough to hold either a row or a column.
	If rowbuf is NULL, space will be allocated.
Returns a pointer to rowbuf unless one of the arguments is invalid in which
	case returns null.
*/
float	*getline2D(data, height, width, lineno, getrow, flip, rowbuf)
float	*data, *rowbuf;
int	height, width, lineno;
Boolean	getrow, flip;
{
float	*p0, *rp;
int	num, pincr;

	/* Sanity check. */
	if((data == NULL) || (height <= 0) || (width <= 0) || (lineno < 0))
		return NULL;

	/* Set up pointer and pointer increment. */
	if(getrow)	/* Return a row. */
	{	if(lineno >= height)
			return NULL;
		num = width;
		p0 = data + (lineno *width);	/* Start of row lineno. */
		if(flip)
		{	p0 += width -1;		/* Last element in row.	*/
			pincr = -1;
		}
		else
			pincr = 1;
	}
	else		/* Return a column. */
	{	if(lineno >= width)
			return NULL;
		num = height;
		p0 = data + lineno;		/* Start of col lineno. */
		if(flip)
		{	p0 += (width*(height-1));	/* Point to last row */
			pincr = -width;
		}
		else
			pincr = width;
	}

	/* Allocate space if necessary. */
	if( (rowbuf == NULL) &&
		( (rowbuf = (float *) malloc(num*sizeof(float))) == NULL) )
		return NULL;
	rp = rowbuf;

	/* Get data. */
	if( !flip && getrow)
		bcopy( p0, rp, num*sizeof(float));
	else
		while( --num >= 0)
		{	*rp++ = *p0;
			p0 += pincr;
		}

	return rowbuf;
}


/*
Write each line in the plane to a FITS file.
If width < 0,  'flip' the row by going from width-1  down to 0.
If height < 0, 'flip' the col by going from height-1 down to 0.
If copyrows, a line is a row otherwise it is a column.

Returns -1 for error, else 0.
*/

int td_FITSWritePlane( filename, object_name,
	data, width, height, cvals, copyrows, planeid)
char	*filename, *object_name;
float	*data;
int	width, height, planeid;
Cvalues	cvals;
Boolean	copyrows;
{
A_FITS_t *fits;
Cvalues	cp;
float	*rowdata, datum;
int	i, err=0, naxis = 3, dims[3];
long 	linesize, nlines, lineno, line0, lineincr;
char	keyword[9], *r;
Boolean	flipx, flipy, flip, flipline;

	if( (data == NULL) || (filename == NULL))
		return -1;

	if( width < 0)
	{	flipx = TRUE;
		width = -width;
	}
	else
		flipx = FALSE;

	if( height < 0)
	{	flipy = TRUE;
		height = -height;
	}
	else
		flipy = FALSE;

	if(copyrows)
	{	/* Set up to copy each row. */
		nlines = height;	/* # of lines to copy.	*/
		linesize = width;	/* Length of each line. */
		flip = flipy;		/* Want it upside down? */
		flipline = flipx;
	}
	else
	{	/* Set up to copy each column. */
		nlines = width;
		linesize = height;
		flip = flipx;		/* reverse?		*/
		flipline = flipy;
	}

	/* If flip, start at end, else start at 0. */
	if(flip)
	{	line0 = nlines -1;
		lineincr = -1;
	}
	else
	{	line0 = 0;
		lineincr = 1;
	}

	rowdata  = (float *) malloc(linesize*sizeof(float));
	if(rowdata==NULL)
	{	gr_TextMsgOut("Count Not allocate memory for plane write.\n");
		return -1;
	}

	dims[0] = width;
	dims[1] = height;
	dims[2] = 1;
	if( (fits = fitopen(filename, "new", naxis, dims))== NULL)
		return -1;

	/* Write labels for axes.
	   Keywords must be upper case for FITS.
	*/
	cp = cvals;
	for(i=0; i<naxis; i++, cp++)
	{	sprintf(keyword, "CTYPE%d", i+1);
		fitwrhda(fits, keyword, QuarkToString(cp->ctype), NULL);
		/* Floating point keywords. */
		sprintf(keyword, "CRVAL%d", i+1);
		datum = fitsScale(cp->crval, cp->ctype, TRUE);
		fitwrhdr(fits, keyword, datum, NULL);
		sprintf(keyword, "CRPIX%d", i+1);
		fitwrhdr(fits, keyword, cp->crpix, NULL);
		sprintf(keyword, "CDELT%d", i+1);
		datum = fitsScale(cp->cdelt, cp->ctype, TRUE);
		fitwrhdr(fits, keyword, datum, NULL);
	}

	if((object_name != NULL) && (strlen(object_name) != 0))
		fitwrhda(fits, "OBJECT", object_name, NULL);

	/* Write image data. */
	lineno = line0;
	for(i=0; i< nlines; i++)
	{	getline2D(data,
			height, width, lineno, copyrows, flipline, rowdata);
		err = fitwrite(fits, i, rowdata);
		if(err != 0)
		{	printf("%s\n", fits_error(err));
			break;
		}
		lineno += lineincr;
	}

	fitclose(fits);
	if (err != 0)
	{char msg[120];
		sprintf(msg, "***ERROR: Cannot write 3D image to %s.\n",
			filename);
		gr_TextMsgOut(msg);
	}

	free(rowdata);
	return err;
}
