/*
 *	File:		td_miriad.c
 *	Contents:	Miriad file calls
 *
 */

#ifdef sun
#define bcopy(a,b,c) memcpy((b),(a),(c))
#endif

#include <math.h>
#include	<sys/types.h>
#include	<sys/stat.h>
#include	<stdio.h>
#include	<fcntl.h>

/* #include "td_com.h" */
#include "gr_com.h"
#include "td_inc.h"

#define	rtod  (180.0 / PI)
#define	rtoh  (12.0  / PI)

/* ------------------------------------------------------- */
/*
 *	Load specified MIRIAD file into memory jng  nov/13/90
 */
int
td_MiriadLoad(db) /* MY */
A_Data_t	*db;
{
Boolean first=TRUE;
int i,j,k,ret=0;
long 	imagesize, rowsize, tempsiz;
int nitems;
unsigned char* hbuf;
unsigned char* mirheadopen();
int		fmir; /* miriad image file handle */
int		nbytes;
char 		mirname[1024], keyword[9];
float32		dummy; /* = first float in image file (not used) */
float		*rowdata;
Cvalues		cv;

/*
 printf("\n:td_mirload:src [%s] [%s]\n", db->dataName, db->pathName);
*/
/* initializeto dummy values  */

   db->dims[0] = db->dims[1] = db->dims[2] = 1; /* ie a dot */ 
   db->rank = 3; db->min = 1000.0; db->max = -1000.0;

	hbuf = (unsigned char*) mirheadopen(db->pathName,&nitems);
   if (hbuf==NULL) {
		 gr_TextMsgOut("cannot read Miriad header\n");
       return(-1);
     }
   mirgetitem (hbuf,nitems,"naxis", &(db->rank));

	if (hbuf == NULL) return(-1);

	else {
   mirgetitem (hbuf,nitems,"naxis1",&db->dims[0]);
   mirgetitem (hbuf,nitems,"naxis2",&db->dims[1]);
   mirgetitem (hbuf,nitems,"naxis3",&db->dims[2]);
/*
   printf("td_mirload: rank=%d dims= %d %d %d\n",
			db->rank,db->dims[0],db->dims[1],db->dims[2]);
*/
	imagesize  = db->dims[0] * db->dims[1] * db->dims[2] * sizeof(float32);
   tempsiz  = mirimagesize(db->pathName);

	if ( tempsiz != imagesize )
	{ char buf[132];

		beep();
		sprintf(buf,
	" File error: image file siz=%d mismatch with header (=%d)!!\n",
					 tempsiz,imagesize);
		gr_TextMsgOut(buf);
		return (-1);
	}

   /* otherwise, ok, proceed to malloc image buffer, read in headers */

		db->data   = (float32 ***)
			td_Malloc3Dfloat32(db->dims[0],db->dims[1],db->dims[2]);
		
	   if (db->data==NULL) gr_TextMsgOut("cannot malloc db->data\n");
/*
      mirgetitem (hbuf,nitems,"ctype1",db->label[0]);
      mirgetitem (hbuf,nitems,"ctype2",db->label[1]);
      mirgetitem (hbuf,nitems,"ctype3",db->label[2]);
*/
	cv = &(db->cvals[0]);
	cv->ctype = StringToQuark(db->label[0]);
	for(cv=&db->cvals[0], i=0; i< 3; cv++, i++)
	{	sprintf(keyword, "ctype%d", i+1);
		mirgetitem(hbuf, nitems, keyword, db->label[i]);
		cv->ctype = StringToQuark(db->label[i]);
		sprintf(keyword, "crval%d", i+1);
		mirgetitem(hbuf, nitems, keyword, &(cv->crval));
		sprintf(keyword, "crpix%d", i+1);
		mirgetitem(hbuf, nitems, keyword, &(cv->crpix));
		sprintf(keyword, "cdelt%d", i+1);
		mirgetitem(hbuf, nitems, keyword, &(cv->cdelt));
	}

/* **jng  OPEN MIRIAD image file **/

	sprintf(mirname,"%s/image",db->pathName);
	if (-1 == (fmir = open(mirname,O_RDONLY)))
	   {printf("Unable to open %s -exiting.\n",mirname);
	    return (NULL);
	   }

	read(fmir,&dummy,sizeof(float32));

	rowdata  = (float32 *)td_Malloc1D(1,db->dims[0],
			(unsigned int)sizeof(float32), "temp float32");
	if(rowdata==NULL) printf("cannot malloc rowdata!\n");

	rowsize = db->dims[0] * sizeof(float32); /* size of one row of data */

/* ******************************** */
		if (db->data != NULL) 
		{
			for (i=0;i<db->dims[2];i++) {
				for (j=0;j<db->dims[1];j++) {

					/* get a row of miriad data, then flip and store in db->data */
					if (rowsize  != (nbytes = read(fmir,rowdata,rowsize )))
	   				{ printf("\t%s\n Try to read %i bytes, but only %i read\n",
		   								mirname, rowsize, nbytes);
						    return (-1);
	 					  }

					for (k=0;k<db->dims[0];k++) {
						db->data[k][j][i] = rowdata[k];
						if (first){ first = FALSE;
										db->min = db->max = db->data[0][0][0];
							}
						else if (db->min > db->data[k][j][i])
										db->min = db->data[k][j][i];
						else if (db->max < db->data[k][j][i])
										db->max = db->data[k][j][i];
						}
					}
				}   
            db->range = db->max - db->min;
/*		printf("td_mir: max=%f min=%f\n",db->max,db->min);*/

			close(fmir); /*** close miriad file */
			td_Free(rowdata);

			if (ret == -1)
			{
				sprintf(msg,
				"***ERROR: Cannot read 3D image from %s.\n",
					db->pathName);
				gr_TextMsgOut(msg);
				gr_TextMsgOut
				("Are you sure this is a 3D 32-bit floating point dataset?\n");
				td_Free3d(db->data);
			}
			else
				db->format = MIRIAD;
		}
		else
		{
			td_Free3d(db->data);
			ret = -1;
			sprintf(msg,
			"***ERROR: Not enough memory to load MIRIAD image %s.\n",
					db->pathName);
			gr_TextMsgOut(msg);
			gr_TextMsgOut
			("I suggest you quit and retry the loading.\n");
		}

		return(ret);
	}
}


/* return Miriad header attributes as text */
char
*td_MiriadgetStats(db,nColors,nSplitColors)
A_Data_t    *db;
int         nColors,nSplitColors;
{
int  i,j,ret;
char *strng=NULL;
Cvalues	cv;
char s1[20],s2[20],s3[20]; /* temp strings */

	if (db->format != MIRIAD) return (NULL);
	strng = td_Malloc1D(1500,1,sizeof(char),"td_Malloc1D:string");
	sprintf(strng,"Miriad File: %s\n", db->pathName);

	for (i=0;i<3;i++)
	{	sprintf(strng,"%s%s: dim=%ld,\tlabel=%s\n",strng,
		axesLabels[i],db->dims[i],db->label[i]);
	}
	sprintf(strng,"%sMax= %8.5f, Min=%8.5f\n", strng,db->max,db->min);
	sprintf(strng,
 	  "%sHeader Data:\nNo.  crval        crpix        cdelt\n", strng);

		/* ---  Print Miriad header data, with formatting  -- */

	for(cv = &db->cvals[0], i=1; i<= 3; cv++, i++)
	{	td_convertcv(cv, s1, s2, s3);
		sprintf(strng,"%s %d  %s  %s  %s\n", strng, i, s1, s2, s3);
	}
	db->range = db->max - db->min;
	db->rangeFrac = (float32)((float32)nColors/db->range);
	db->rangeFracSplit = (float32)((float32)nSplitColors/db->range);
    return(strng);
}

/* ------------------------------------------------------------------ */

/* returns a ptr to mem with header, and nitems */
unsigned char* mirheadopen(mirname,nitems)  /* newmiriad */
char *mirname;
int * nitems;

{
	struct	stat	mystat;
	char		fname[1024];
	unsigned char *hbuf;
	int		n, nbytes, fd;
	long val;
	char itemstr[90];
   char msg[280];

	strcpy(fname,mirname);
	strcat(fname,"/header");

	if (0 != stat(fname,&mystat))
	   {printf("Stat failed on %s.\n",fname);
		 gr_TextMsgOut("Not a miriad file!!\n"); beep();
		
	    return (NULL);
	   }

	if (0 == (n = mystat.st_size))
	   {printf("%s has zero-sized header - exiting.\n",fname);
	    return (NULL);
	   }

	if (0 == (hbuf = (unsigned char*) malloc(n)))
	   {printf("Unable to malloc %i bytes -exiting.\n",n);
	    return (NULL);
	   }
	
	if (-1 == (fd = open(fname,O_RDONLY)))
	   {printf("Unable to open %s -exiting.\n",fname);
	    return (NULL);
	   }

	if (n != (nbytes = read(fd,hbuf,n)))
	   {printf("File\t%s\nStat says %i bytes, %i read - exiting.\n",
		   fname, n, nbytes);
	    return (NULL);
	   }

	if (0 != close(fd))
	   {printf("Problem closing %s - continuing anyway.\n",fname);
	   }
	*nitems = 1+nbytes/32;

	return (hbuf);
}

/* ---------------------------------------------------------- */
/* returns value of itemstr in val. returns -1 if error. */
int mirgetitem (hbuf,nitems,itemstr,val) /* newmiriad */
unsigned char  hbuf[][32], *val;
int nitems;
char * itemstr;

 {
   int i,j, code, m;
   double *dptr;
   float  izap;
   unsigned char *czap;
   char	*cptr, cptr1;

	for(i=0;i<nitems ;i++) 
	{  cptr = (char *) hbuf[i];
	   bcopy(hbuf[i], &cptr1, sizeof(cptr1));
	   if (!strcmp(itemstr,(char *)hbuf[i]))  {
		code = (int) hbuf[i][19];
/* printf("item=[%s] code=%d\n", itemstr, code);*/
		switch(code) {		
		case 1: /* string */
 			j=0;
			m = (int) ( hbuf[i][15] - 6);
			while (m-- >= -1) { val[j] = hbuf[i][20+j]; j++; }
			val[j] = '\0';
		break;

		case 2: /* int4 */	
			for(j=0;j<4;j++)
				val[j] = (unsigned char) hbuf[i][20+j];
		break;

		case 3: /* int2 */
			for(j=0;j<2;j++)
				val[j] = (unsigned char) hbuf[i][20+j];
		break;

		case 4: /* float */
			for(j=0;j<sizeof(float);j++)
				val[j] = hbuf[i][20+j];
		break;

		case 5: /* double */
			dptr = (double *)(&(hbuf[i][24]));
			izap = (float)(*dptr);
			czap = (unsigned char *)(&izap);
			for (j=0; j<4; j++)
			    val[j] = *(czap + j);
/*
			for(j=0;j<sizeof(double);j++)
				val[j] = hbuf[i][24+j];
*/
		break;

		default: printf("rubbish\n");
  					return(-1); 
		break;
		} /* switch */
		return(0);
	}
	}
	printf("no such item [%s]\n",itemstr);
   return(-1); 
}
/* ------------------------------------------------------- */
/* returns the miriad image file's byte size as found using stat() */
int mirimagesize(mirname) /* newmiriad */
char* mirname; {
	struct	stat	mystat;
	char		fname[1024];
	int		n, nbytes, fd;

	strcpy(fname,mirname);
	strcat(fname,"/image");

	if (0 != stat(fname,&mystat))
	   {printf("Stat failed on %s - exiting.\n",fname);
	    return (-1);
	   }

	if (0 == (n = mystat.st_size))
	   {printf("%s has zero-sized image - exiting.\n",fname);
	    return (-1);
	   }

	return(n-4); /* first 4 bytes in "/image" are not data at all */

}/* mirimagesize */
/* ------------------------------------------------------------------ */
/* converts degrees into string */
/* input: angle in degrees (float) */

degtoang (ang,ss) float ang; char ss[];  {
  char sign;
  int deg, min;
  float sec;
  float v;

  if(ang > 0.0) sign = '+'; else { sign='-';  ang = - ang; }

  v = ang;

  deg = (int) v;
  min = (v-(float)deg)*60;
  
  sec = (v - (float)deg - (float)min/60.0) *3600.0;
  sprintf(ss,"%c%d:%d:%05.2f",sign,deg,min,sec);
}

/* ------------------------------------------------------------------ */

/* jng 13-MAR-91. Used by contour hardcopy routine only */
/* if Miriad file, returns the x and y axes titles */
void gr_getMiriadAxesTitles (dsplWin, xtitle, ytitle) 
A_DsplWind_t	*dsplWin;
char				* xtitle, *ytitle;
{
	A_Axes_t	 orient;
	A_Data_t	 *db=dsplWin->parent->parent->data;

	if((db->format != MIRIAD) && (db->format != FITS))
		return;

	orient=dsplWin->axesOrient;

	if (     ( orient.row  == 2 || orient.row  == -2 ) 
     		&& ( orient.col  == 1 || orient.col  == -1 ) 
     		&& ( orient.axis == 3 || orient.axis == -3 )) { /* XY  plane */
			strcpy(xtitle, db->label[0]);
			strcpy(ytitle, db->label[1]);
		}
	else 
	if (     ( orient.row  == 3 || orient.row  == -3 ) 
     		&& ( orient.col  == 1 || orient.col  == -1 ) 
     		&& ( orient.axis == 2 || orient.axis == -2 )) { /* XZ  plane */
			strcpy(xtitle, db->label[0]);
			strcpy(ytitle, db->label[2]);
		}
	else 
	if (     ( orient.row  == 3 || orient.row  == -3 ) 
     		&& ( orient.col  == 2 || orient.col  == -2 ) 
     		&& ( orient.axis == 1 || orient.axis == -1 )) { /* ZY  plane */
			strcpy(xtitle, db->label[1]);
			strcpy(ytitle, db->label[2]);
		}
}

/* ------------------------------------------------------------------ */
/* jng 13-MAR-91. Used by contour hardcopy routine only */
/* if Miriad file, returns the tick labels along the x and y axes */
/* FOR NOW, only 1 value (center) per axis returned */

void gr_getMiriadAxesTickValues (dsplWin, xtick, ytick)
A_DsplWind_t	*dsplWin;
char 				*xtick, *ytick;
{
	A_Axes_t	 orient;
	A_Data_t	 *db=dsplWin->parent->parent->data;
	char		dummy[50];
	int selX, selY;

	if((db->format != MIRIAD) && (db->format != FITS))
		return;

	orient=dsplWin->axesOrient;

	if (     ( orient.row  == 2 || orient.row  == -2 ) 
     		&& ( orient.col  == 1 || orient.col  == -1 ) 
     		&& ( orient.axis == 3 || orient.axis == -3 )) { /* XY  plane */

			selX =  db->dims[0]/2-1; selY =  db->dims[1]/2-1;
			computeMiriadValues (selX, selY, db, orient,
							xtick, ytick, dummy);
		}
	else 
	if (     ( orient.row  == 3 || orient.row  == -3 ) 
     		&& ( orient.col  == 1 || orient.col  == -1 ) 
     		&& ( orient.axis == 2 || orient.axis == -2 )) { /* XZ  plane */

			selX =  db->dims[0]/2-1; selY =  db->dims[2]/2-1;
			computeMiriadValues (selX, selY, db, orient,
						xtick, ytick, dummy);
		}
	else 
	if (     ( orient.row  == 3 || orient.row  == -3 ) 
     		&& ( orient.col  == 2 || orient.col  == -2 ) 
     		&& ( orient.axis == 1 || orient.axis == -1 )) { /* ZY  plane */

			selX =  db->dims[1]/2-1; selY =  db->dims[2]/2-1;
			computeMiriadValues (selX, selY, db, orient,
						xtick, ytick, dummy);
		}
}

/* ------------------------------------------------------------------ */

/* jng 24-MAY-91. Used by contour hardcopy routine only */
/* if Miriad file, returns the axes hi and low end tick labels */

void gr_getMiriadEndAxesTickValues (dsplWin, xtick0, ytick0, xtick1, ytick1)
A_DsplWind_t	*dsplWin;
char		*xtick0, *ytick0;  /* low-end axes  value */
char		*xtick1, *ytick1;  /* high-end axes value */
{
A_Axes_t	 *orient;
A_Data_t	 *db=dsplWin->parent->parent->data;
char		dummy[50];
int		selX, selY;

	if( (db->format != MIRIAD) &&  (db->format != FITS)) return;

	orient= &dsplWin->axesOrient;

	selX =  selY = 0;
	computeMiriadValues (selX, selY, db, orient, xtick0, ytick0, dummy);

	if (     ( orient->row  == 2 || orient->row  == -2 ) 
     		&& ( orient->col  == 1 || orient->col  == -1 ) 
     		&& ( orient->axis == 3 || orient->axis == -3 )  ) { /* XY  plane */

			selX =  db->dims[0]; selY =  db->dims[1];
			computeMiriadValues (selX, selY, db, orient, xtick1, ytick1, dummy);
		}
	else 
	if (     ( orient->row  == 3 || orient->row  == -3 ) 
     		&& ( orient->col  == 1 || orient->col  == -1 ) 
     		&& ( orient->axis == 2 || orient->axis == -2 )  ) { /* XZ  plane */

			selX =  db->dims[0]; selY =  db->dims[2];
			computeMiriadValues (selX, selY, db, orient, xtick1, ytick1, dummy);
		}
	else 
	if (     ( orient->row  == 3 || orient->row  == -3 ) 
     		&& ( orient->col  == 2 || orient->col  == -2 ) 
     		&& ( orient->axis == 1 || orient->axis == -1 )  ) { /* ZY  plane */

			selX =  db->dims[1]; selY =  db->dims[2];
			computeMiriadValues (selX, selY, db, orient, xtick1, ytick1, dummy);
		}
}

/* ================================================================== */

#if 0
static void printv(d, nx, ny)
float	*d;
int	nx, ny;
{
int	x,y;

	for(y=0; y< ny; y++)
	{	for(x=0; x< nx; x++)
			printf("%4.2f ", *d++);
		printf("\n");
	}
	printf("\n");
}
#endif

#define ABS(x) ((x) >= 0 ? (x) : -(x))
/*
Display Dataset numerical values on spreadsheet window.

The name of this routine is a bit of a misnomer since it now handles
HDF datasets.
*/
int gr_DsplMiriadValues(dsplWin) 			/* jng 13-MAR-91 */
A_DsplWind_t	*dsplWin;
{
A_Data_t	*db=dsplWin->parent->parent->data;
char		Xmsg[80], Ymsg[80], Zmsg[80], data[80];
float		datum, *f;
int		x,y, width, height;
A_Axes_t	orient, *o;

	/* When this routine is called, the axis values are already in
	   data space. In order to keep confusion down, a copy of the
	   orient struct is made with absolute values. That is passed to
	   computeMiriadValues.
	*/
	o = &dsplWin->axesOrient;
	orient.row = ABS(o->row);
	orient.col = ABS(o->col);
	orient.axis = ABS(o->axis);
	orient.plane = o->plane;
	x = dsplWin->selX;
	y = dsplWin->selY;
	width = dsplWin->xdim;
	height = dsplWin->ydim;
	computeMiriadValues( x, y, db, &orient, Xmsg, Ymsg, Zmsg);
	/* Make sure point is within data set then generate its value.
	   fdata points to the upper left point for normal images, the
	   lower left data point if flipped vertically.
	*/
	td_convertXY(o, width, height, x, y, &x, &y);
	if((x >= 0) && (x <= width) && (y >= 0) && (y <= height))
	{	f = dsplWin->fdata;
/*
printf("Xin,Yin (%d,%d) x,y (%d,%d)\n", dsplWin->selX,dsplWin->selY, x, y);
printf("Col %d Row %d\n", o->col, o->row);
printv(f, width, height);
*/
		datum = *(f+y*width+x);
		sprintf(data, "%7.4g", datum);
	}
	else
		sprintf(data, "  ?  ");


	gr_DialogSetValue(dsplWin->xDialog,Xmsg); 
	gr_DialogSetValue(dsplWin->yDialog,Ymsg); 
	gr_DialogSetValue(dsplWin->zDialog,Zmsg); 
	gr_DialogSetValue(dsplWin->dDialog, data); 
}

/* ------------------------------------------------------------------ */
/*
	jng 8-apr-91
  Given a point (selX,selY)  on the display window,
  compute its corresponding data values, return them as 3 strings.
  From the orient structure, it knows what the selX and selY corresponds to.

selX, selY	Position on display window (0..dim-1) in window coordinates.

The name of this routine is a bit of a misnomer since td_GetAxisValueString
will deal with HDF data sets.
*/

#define	FMT	"%7.5f"
static computeMiriadValues (selX, selY, db, orient, Xmsg, Ymsg, Zmsg) 
int		selX, selY; 	/* selected pt on display window */
A_Axes_t	*orient; 	/* orientation of that display window */
A_Data_t 	*db;		/* Any dataset */
char 		*Xmsg, *Zmsg, *Ymsg;  /* strings returned here */
{

	td_GetAxisValueString(db, selX, orient->col , FMT, Xmsg);
	td_GetAxisValueString(db, selY, orient->row , FMT, Ymsg);
	td_GetAxisValueString(db, orient->plane, orient->axis,
							FMT, Zmsg);
}

/* ================================================================== */
