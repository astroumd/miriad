/* grtask.c	- Jason's routines for doing gaussian.
*/
#include	"gr_com.h"

#include        <math.h>
#include	"gr_plot.h"

#if defined (SYSV) && defined (sun)
#define rindex(a,b)  strrchr((a),(b))
#define  index(a,b)  strchr ((a),(b))
#endif

extern void	gr_CloseHistLevel();
void gr_GaussSave();
void gr_GaussSaveWIP();
void gr_GaussPlotWIP();
void gr_GaussSaveGNU();
void gr_GaussPlotGNU();

#define MINGAUSSXSIZE	250
#define MINGAUSSYSIZE	200
#define	MAXGAUSSXSIZE	900
#define	MAXGAUSSYSIZE	900
#define	LEEWAY			2

#define XOFFSET			10
#define YOFFSET			10

#define YFUDGE 60  /* jng nov 26 jjj */


/* ------------------------------------------------------------------ */
/*
*  jng 25-may-91
*  read from gaussian dialog boxes
* then generate a convoluted image
 */

void collectgaussparms(w, client_data, call_data)
Widget   w;
caddr_t  client_data;
caddr_t  call_data;
{
A_HistWind_t*  histWin = (A_HistWind_t*) client_data;
A_DsplWind_t*   dsplWin = (A_DsplWind_t*) (histWin->parent);

char *strx, *stry, *strt, *strf;
float * pdat; /* input float data plane */
float * qdat; /* output float data plane */

int px, py; /* no of cols and rows in pdat */
int qx, qy; /* no of cols and rows in qdat */
int xoff, yoff; /* displacement coords of qdat plane wrt pdat plane */
float cx,cy, theta, frac; /* gauss convolution-specific parameters */
char ss[80];
char msg[80];
int            s; /* status */
int            scale ,xdim, ydim, plane;

/* ================================= */

strx = gr_DialogGetValue(histWin->xDialog); sscanf(strx,"%f", &cx);
stry = gr_DialogGetValue(histWin->yDialog); sscanf(stry,"%f", &cy);
strf = gr_DialogGetValue(histWin->fDialog); sscanf(strf,"%f", &frac);
strt = gr_DialogGetValue(histWin->tDialog); sscanf(strt,"%f", &theta);

if (cx <= 0.0) {
   gr_TextMsgOut("Gaussian: x out of range (> 0.0) \n"); beep(); return;
	}
if (cy <= 0.0) {
   gr_TextMsgOut("Gaussian: y out of range (> 0.0) \n"); beep(); return;
	}
if (theta <0.0 || theta > 360.0) {
   gr_TextMsgOut("Gaussian: ang out of range (0 - 360 deg)\n"); beep(); return;
	}
if (frac <0.0 || frac> 100.0) {
   gr_TextMsgOut("Gaussian: frac out of range (0 - 100 %)\n"); beep(); return;
	}

/* ================================= */

xdim = dsplWin->xdim;
ydim = dsplWin->ydim;

	  /* - - - for now  - - - */
      xoff = 0; yoff = 0;
      qx = xdim; qy = ydim;

	pdat = dsplWin->fdata;
   qdat = (float32*)  td_Malloc(qx*qy*sizeof(float), "collectgaussparms"); 
   if ( qdat==NULL) {
      gr_TextMsgOut("Err: cannot alloc Gaussian output plane\n");
      return;
      }

	gr_WidgetCursor (histWin->shell, XC_watch);

   gr_TextMsgOut("Wait..performing Gasussian convolution\n");
   sprintf(ss,"Parameters cx=%f cy=%f theta=%f frac=%f\n", cx, cy, theta, frac);
   gr_TextMsgOut(ss);

   s = mmxv_gauss_cnvl(pdat , xdim,ydim, qdat, xoff, yoff, qx, qy,
                  cx,cy,theta,frac, msg);
   if (s !=0) {
      beep();
      printf("mmxv_gauss_cnvl returns error=%d. msg is [%s]\n", s, msg);
      gr_TextMsgOut("Cannot do Gaussian convolution!\n");
		gr_WidgetCursor (histWin->shell, XC_draped_box);
      return;
      }

   gr_TextMsgOut("Gaussian convolution done\n");

   histWin->gdata = qdat;

	/* now display on gaussian window  */
	my_GaussExpose( (Widget) NULL, histWin, (caddr_t) NULL);

	gr_WidgetCursor (histWin->shell, XC_draped_box);
}

/* ------------------------------------------------------------------ */
/*
 *
 * jng may-25-91	
 *	Just creates a Gaussian window with dialogs, but no image yet.
 *
 */
extern 			my_GaussExpose();

A_HistWind_t
*my_InitGaussLevel (header,shellName,parent,tparent) 
A_HistWind_t *header; /* usually NULL (not safe) , use tparent instead ! */
char   	 *shellName;
Widget	 parent;
A_DsplWind_t	*tparent;
{
A_HistWind_t	*histWin=(A_HistWind_t *) tparent->histWin;
A_DsplWind_t	*dsplWin=tparent;
int		xsize, ysize, winxsize, winysize;
int		scale ,xdim, ydim;
A_HistWind_t	*tmp;
Widget		bwin; /* bulletin box widget */
Widget		controlW, menuW;

	gr_WidgetCursor(tparent->shell,XC_watch);

	scale= dsplWin->scale;
	xdim = dsplWin->xdim;
	ydim = dsplWin->ydim;

	if ((tmp = (A_HistWind_t *)td_Malloc(sizeof(A_HistWind_t),
			   "A_HistWind_t")) == NULL)
		return(NULL);

	xsize = xdim*scale + 2*XOFFSET;
	ysize = ydim*scale + 2*YOFFSET;

    if (xsize > MINGAUSSXSIZE)
        if (xsize > MAXGAUSSXSIZE)
            winxsize = MAXGAUSSXSIZE;
        else
            winxsize = xsize+LEEWAY;
    else
        winxsize = MINGAUSSXSIZE+LEEWAY;

    if (ysize > MINGAUSSYSIZE)
        if (ysize > MAXGAUSSYSIZE)
            winysize = MAXGAUSSYSIZE;
        else
            winysize = ysize+LEEWAY;
    else
        winysize = MINGAUSSYSIZE+LEEWAY;

	tmp->shell = gr_MakeWindow2("MXV Hist", parent, &(tmp->win),
			(XtCallbackProc)gr_CloseHistLevel, (caddr_t)tmp,
			"Result of Gaussian", "Close", FALSE);

	tmp->imageVPort = gr_MakeVPort2(NULL, tmp->win, NOSCROLL,
			NULL, (caddr_t)tmp,
			winxsize,winysize, NULL, NULL);

	tmp->imageWin	= gr_MakeWorkSpace2(NULL, tmp->imageVPort,
				(XtCallbackProc)my_GaussExpose,
				NULL, NULL,(caddr_t)tmp,
				xsize,ysize, NULL, NULL);
	bwin  = gr_MakeBox2(NULL, tmp->win, tmp->imageVPort, NULL, FALSE);
	tmp->xDialog= gr_MakeDialog1(NULL, bwin, "X pixels", "1", 5,
					NULL, NULL);
	tmp->yDialog= gr_MakeDialog1(NULL, bwin, "Y pixels", "1", 5,
					NULL, NULL);
	tmp->tDialog= gr_MakeDialog1(NULL, bwin, "ANG deg", "0.0", 5,
					NULL, NULL);
	tmp->fDialog= gr_MakeDialog1(NULL, bwin, "FRAC %", "1", 5,
					NULL, NULL);

	controlW = gr_MakeBox2(NULL, tmp->win, tmp->imageVPort, bwin, TRUE);
	gr_MakeButton3(NULL, controlW, "apply", NONE,
		(XtCallbackProc) collectgaussparms, (caddr_t)tmp,
		NULL, NULL);

/*	gr_MakeButton3(NULL, controlW, "save ", NONE,
		(XtCallbackProc) NULL, (caddr_t)tmp,
		NULL, NULL);
*/
	menuW = gr_MakeMenu( "Gauss", controlW, "Save Options");
/*	gr_AddMenuEntry( NULL, menuW, "Save ps format",
			gr_GaussSavePS ,(caddr_t)tmp);
*/
	gr_AddMenuEntry( NULL, menuW, "Save in WIP format",
			gr_GaussSaveWIP ,(caddr_t)tmp);
	gr_AddMenuEntry( NULL, menuW, "Save GNU format",
			gr_GaussSaveGNU ,(caddr_t)tmp);
	gr_AddMenuEntry( NULL, menuW, "Preview with WIP",
			gr_GaussPlotWIP ,(caddr_t)tmp);
	gr_AddMenuEntry( NULL, menuW, "Preview with GNU",
			gr_GaussPlotGNU ,(caddr_t)tmp);

	gr_MakeMenuButton(NULL, controlW, "Save", menuW,
			gr_GaussSave, (caddr_t)tmp, NULL, NULL);

	/* zero out other fields in this HistWin */
	tmp->ntraced = 0;
	tmp->gdata = NULL;

	/* link this window structure to all others */ 
	tmp->parent	= tparent;
	tmp->prev	= NULL;
	tmp->next	= header;
	if (header != NULL)
		header->prev = tmp;

	gr_ManageChild(tmp->shell);
	gr_ImageSetCMap(tmp->shell);
	gr_WidgetCursor(tmp->shell,XC_draped_box);
	gr_WidgetCursor(tparent->shell,XC_draped_box);
   gr_TextMsgOut("Enter Gaussian parameters, then click the apply button\n");

	return(tmp);
}

/* ================================================================== */

/* jng 26-may-91
*  Redraws the Gaussian image on exposue event
*/

my_GaussExpose(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
   A_HistWind_t   *histWin=(A_HistWind_t *)client_data;
   A_DsplWind_t   *dsplWin=histWin->parent;

   A_Data_t       *hdf=dsplWin->parent->parent->data;
   float32        min=hdf->min,max=hdf->max;
   Widget         wid=histWin->imageWin;
   Display        *dpy=XtDisplay(wid);
   Window         win=XtWindow(wid);
   int            scr = DefaultScreen(dpy);
   GC             gc;
   XGCValues      gcvals;

   XFontStruct    *font_info;
   char           *fontname = "6x10",strng[40];
   int             scale ,xpos,ypos, x,y, xdim, ydim;
   long           black, color;
   pixelMapping	  *map= &(dsplWin->parent->mapping);
   float32        *sp;  /* pts to a plane of float values */

	if (histWin->gdata == NULL) return;

  	gcvals.foreground = black = BlackPixel(dpy,scr);
	gc = XtGetGC(wid, GCForeground, &gcvals);

	XClearWindow(dpy,win);
	XSetForeground(dpy,gc,black);

	scale= dsplWin->scale;

	xdim = dsplWin->xdim;
	ydim = dsplWin->ydim;

  	ypos = YOFFSET;
	sp = histWin->gdata;

	for (y=0; y<ydim; y++,ypos+=scale) {
	   	xpos = XOFFSET;
		for (x=0; x<xdim; x++,xpos+=scale) {
			 color = (int) xi_mapPixel(*sp++, min, max, map);
	        	XSetForeground(dpy,gc,color);
			XFillRectangle(dpy,win,gc,xpos,ypos ,scale,scale);
		}
	}

}

/* ------------------------------------------------------------------ */
/** jng 27-feb-91 */
/* called when "gauss" button on spreadsheet window pressed */

void
gr_DsplGauss (w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_DsplWind_t	*dsplWin=(A_DsplWind_t *)client_data;
	A_HistWind_t	*tmp; /* new histwin created here */
	extern A_HistWind_t    *my_InitSliceLevel();


    if (dsplWin->numHistWins < MAX_HISTLEV_WINDS)
    {
		/* create a HISTWIN here  as tmp, and all its links */
     	tmp = my_InitGaussLevel(dsplWin->histWin,"XTDwindow",gr_topLevel,dsplWin);
	
		if (tmp != NULL)
        {
            dsplWin->histWin = tmp;
            dsplWin->numHistWins++;
        }
    }
    else
    {
        sprintf(msg,"Only %d histogram windows are allowed!\n",
            MAX_HISTLEV_WINDS);
        gr_TextMsgOut(msg);
    }
    return;
}

/* ------------------------------------------------------------------ */

/*
        ---------------------------------------------------------------
        mmxv_gauss_cnvl

	Prep the data, do conversions, and call the routine to do the
	Gaussian convolution.

        Returns zero on success; else non-zero.

                in    = ptr to input data plane
                xin   = no. of x-points in input data plane
                yin   = no. of y-points in input data plane

                xoff  = x-offset to subregion within input plane
                yoff  = y-offset to subregion within input plane

                out   = ptr to output data plane
                xout  = no. of x-points in output data plane
                yout  = no. of y-points in output data plane

		xaxis = x-major axis, FWHM
                yaxis = y-major axis, FWHM
                theta = rotation angle of kernel (degrees)
                frac  = cutoff % (between 0 and 100) of max 

                m     = ptr to 80byte char string to return message.
        ---------------------------------------------------------------
*/
int     mmxv_gauss_cnvl(in,xin,yin,out,xoff,yoff,
			xout,yout,xaxis,yaxis,theta,frac,m)

        float           *in,*out,xaxis,yaxis,theta,frac;
        unsigned int    xin,yin,xoff,yoff,xout,yout;
        char            *m;
{
	float		xparm,yparm;
	int		gk_convolve(),code;

	theta *= (3.14159265358979323846 / 180.);
	frac  /= 100.;
	xparm  = xaxis * sqrt(log(4.));
	yparm  = xparm * yaxis / xaxis;

	code = gk_convolve(in,xin,yin,out,xoff,yoff,
			   xout,yout,xparm,yparm,theta,frac,m);

	return (code);

}
/*
        ---------------------------------------------------------------
        gk_convolve

        Perform kernel convolution of subregion of input plane and
        write output to a new plane; kernel is normalized.

        Returns zero on success; else non-zero.

                in    = ptr to input data plane
                xin   = no. of x-points in input data plane
                yin   = no. of y-points in input data plane

                xoff  = x-offset to subregion within input plane
                yoff  = y-offset to subregion within input plane

                out   = ptr to output data plane
                xout  = no. of x-points in output data plane
                yout  = no. of y-points in output data plane

		xaxis = x-semiaxis of kernel
                yaxis = y-semiaxis of kernel
                theta = rotation angle of kernel (radians)
                frac  = cutoff % (expressed as frac) of max of Gaus. Dist.

                m     = ptr to 80byte char string to return message.
        ---------------------------------------------------------------
*/
int     gk_convolve(in,xin,yin,out,xoff,yoff,
		    xout,yout,xaxis,yaxis,theta,frac,m)

        float           *in,*out,xaxis,yaxis,theta,frac;
        unsigned int    xin,yin,xoff,yoff,xout,yout;
        char            *m;
{
	int		top,bot,left,right,d,kx,ky,tkx,tky,ztemp;
	float		*tk,*k;
	void		gk_wksp(),gk_tk2k(),gk_copyborder(),gk_2d();
/*
        ***************************************************************
        Get the max possible kernel size.  d = max(xaxis*r,yaxis*r)
        ***************************************************************
*/
        if (xaxis > yaxis)
	   d = (int)(.5 + xaxis * sqrt(log(1./(frac * frac))));
        else
	   d = (int)(.5 + yaxis * sqrt(log(1./(frac * frac))));

	tkx = d + d - 1;
	tky = d + d - 1;
/*
        ***************************************************************
        Allocate wksp kernel, calculate values, find actual kernel
        dimensions, and then ensure that there's enough data in the
        subregion to get at least one valid output point.
        ***************************************************************
*/
        tk = (float *)(malloc (tkx * tky * sizeof(float)));
        if (NULL == tk)
           {strcpy(m,"Cannot allocate kernel-sized workspace ... exiting.\n");
            return (-1);
           }
        else;

        gk_wksp(tk,tkx,tky,&kx,&ky,xaxis,yaxis,theta,frac);

        if (kx > xout || ky > yout)
           {strcpy(m,"Output plane too small for kernel ... exiting.\n");
	    free (tk);
            return (-2);
           }
        else;
/*
        ***************************************************************
        Allocate k[kx][ky], copy values from tk,and normalize; free tk.
        ***************************************************************
*/
        k = (float *)(malloc (kx * ky * sizeof(float)));
        if (NULL == k)
           {strcpy(m,"Cannot allocate kernel ... exiting.\n");
            free (tk);
            return (-3);
           }
        else;

        gk_tk2k(tk,tkx,tky,k,kx,ky);

        free (tk);
/*
        ***************************************************************
        Calculate the region where there isn't enough data to apply the
        kernel (finite plane, subregion specification).  top,bot,left,
	right are the dimensions on the top, bottom, left, right (resp).
        ***************************************************************
*/
        top = (ky - 1) / 2 - yoff;
        if (top < 0)    top = 0;
        else;

        bot = (ky - 1) / 2 - yin + yout + yoff;
        if (bot < 0)    bot = 0;
        else;

        left = (kx - 1) / 2 - xoff;
        if (left < 0)   left = 0;
        else;

        right = (kx - 1) / 2 - xin + xout + xoff;
        if (right < 0)  right = 0;
        else;
/*
        ***************************************************************
        Convolve in the region where there is enough data to apply the
        kernel; free (k);

	(float *) pointers refer to (in order):

		1st point in input plane to use with kernel
	
		1st valid point in 1st valid row of output plane

		last valid point in 1st valid row of output plane

		last valid point in output plane
        ***************************************************************
*/
	if (left < xoff)	ztemp  = xoff - left;
	else			ztemp  = 0;
	if (top  < yoff)	ztemp += xin * (yoff - top);
	else;

	gk_2d((float *)(in + ztemp),
	      xin,
	      (float *)(out + left + xout * top),
	      (float *)(out + xout * top + xout - 1 - right),
	      (float *)(out + xout * yout - 1 - xout * bot - right),
	      xout,
	      k,
	      kx,
	      ky);

	free (k);
/*
        ***************************************************************
        Copy the border values in the output plane.
        ***************************************************************
*/
        gk_copyborder(out,xout,yout,left,right,top,bot);

	strcpy (m,"Gaussian kernel operation completed.\n");
	return (0);
}

/*
        ---------------------------------------------------------------
        gk_copyborder

        Copy the border of the output plane from the nearest valid
        interior values after completing a kernel convolution.

                plane = ptr to data plane
                nx    = no. of x-points in plane
                ny    = no. of y-points in plane
                left  = no. of columns to be copied on the left
                right = no. of columns to be copied on the right
                top   = no. of rows to be copied on the top
                bot   = no. of rows to be copied on the bottom
        ---------------------------------------------------------------
*/
void    gk_copyborder(plane,nx,ny,left,right,top,bot)
        float           *plane;
        unsigned int    nx,ny,left,right,top,bot;
{
        float           *b,*bz,*a;

        if (left > 0)
           {b = plane + top * nx;
            bz = plane + (ny - bot - 1) * nx;
            a = b + left;
            while (b < bz)
                  {while (b < a) *b++ = *a;
                   a += nx;
                   b = a - left;
                  }
            while (b < a) *b++ = *a;
           }
        else;
        if (right > 0)
           {b = plane + top * nx + nx - 1;
            a = b - right;
            bz = plane + (ny - bot - 1) * nx + nx - 1;
            while (b < bz)
                  {while (b > a) *b-- = *a;
                   a += nx;
                   b = a + right;
                  }
            while (b > a) *b-- = *a;
           }
        else;
        if (top > 0)
           {b  = plane;
            a  = plane + nx * top;
            bz = a + nx - 1;
            while (b < a)
                  {while (a < bz) *b++ = *a++;
                   *b++ = *a;
                   a -= (nx - 1);
                  }
            while (a < bz) *b++ = *a++;
            *b = *a;
           }
        else;
        if (bot > 0)
           {b  = plane + nx * (ny - 1);
            a  = b - nx * bot;
            bz = a + (nx - 1);
            while (b > a)
                  {while (a < bz) *b++ = *a++;
                   *b = *a;
                   a -= (nx - 1);
                   b -= ((nx - 1) + nx);
                  }
            while (a < bz) *b++ = *a++;
            *b = *a;
           }
        else;

        return;
}
/*
        ---------------------------------------------------------------
        gk_wksp

	Get the temporary kernel workspace ... calculate its values
	and find the actual kernel dimensions.

		tk  = pointer to tk[tkx][tky]
		tkx = x-points in tk
		tky = y-points in tk
		*kx = x-points in final kernel k
		*ky = y-points in final kernel k
		cx  = x semi-axis
		cy  = y semi-axis
		th  = rotation angle
		f   = frac of max defining ellipse boundary
        ---------------------------------------------------------------
*/
void	gk_wksp(tk,tkx,tky,kx,ky,cx,cy,th,f)
	int	*kx,*ky,tkx,tky;
	float	*tk,cx,cy,th,f;
{
	register int	i,j;
	int		xmin = tkx - 1,
			ymin = tky - 1,
			xmax = 0,
			ymax = 0,
			dx   = -1 + (tkx + 1) / 2,
			dy   = -1 + (tky + 1) / 2,
			ztemp = tkx * tky;
	float		cth  = cos (th),
			sth  = sin (th);
	float		x,y;

	for (j = 0; j < tky; j++)
	    for (i = 0; i < tkx; i++)
		{x = ( cth * (i - dx) - sth * (j - dy)) / cx;
		 y = (-sth * (i - dx) + cth * (j - dy)) / cy;
		 *tk = exp (- (x * x + y * y) / 2.);
		 if (*tk < f) *tk = 0.;
		 else
		     {if (i < xmin) xmin = i; else;
		      if (i > xmax) xmax = i; else;
		      if (j < ymin) ymin = j; else;
		      if (j > ymax) ymax = j; else;
		     }
		 if (ztemp-- > 1) tk++;
		 else;
		}
	
	*ky = ymax - ymin + 1;
	*kx = xmax - xmin + 1;

	return;
}
/*
        ---------------------------------------------------------------
        gk_tk2k

	Get the actual kernel from the temporary workspace kernel and
	normalize it.

		tk  = pointer to workspace kernel
		tkx = x-points in tk
		tky = y-points in tk
		k   = pointer to actual kernel
		kx  = x-points in k
		ky  = y-points in k
        ---------------------------------------------------------------
*/
void	gk_tk2k(tk,tkx,tky,k,kx,ky)
	int	tkx,tky,kx,ky;
	float	*tk,*k;
{
	register float	*p,*q,*row,*end,a;
	float		*start;

	start = tk + (tkx * (tky - ky) + (tkx -kx)) / 2;
	p = k;
	a = 0.;
	q = k + kx * ky - 1;

	while (ky > 1)
	      {row = start;
	       end = row + kx - 1;
	       while (row < end)
		     {a += *row;
		      *p++ = *row++;
		     }
	       a += *row;
	       *p++ = *row;
	       start += tkx;
	       ky--;
	      }
	row = start;
	end = row + kx - 1;
	while (row < end)
	      {a += *row;
	       *p++ = *row++;
	      }
	a += *row;
	*p = *row;

	p = k;
	while (p < q)	*p++ /= a;
	*p /= a;

	return;
}
/*
        ---------------------------------------------------------
        gk_2d   Given a kernel and an input plane, perform
                the kernel convolution

		p  = ptr, input plane's 1st pt to use with kernel
		px = x-points in input plane

		t  = ptr, 1st valid pt in output plane
		tu = ptr, last valid pt, 1st valid row in output
		tz = ptr, last valid pt in output plane

		tx = x-points in output plane

                k  = ptr to kernel
                kx = x-points in kernel
                ky = y-points in kernel
        ---------------------------------------------------------
*/
void    gk_2d(p,px,t,tu,tz,tx,k,kx,ky)
	float	*p,*t,*tu,*tz,*k;
	int	px,tx,kx,ky;
{
	
	float		gk_2dcalc();
	register float	*pp,*tt;

	while (tu < tz)
	      {pp = p;
	       tt = t;
	       while (tt < tu) *tt++ = gk_2dcalc(pp++,px,k,kx,ky);
	       *tt = gk_2dcalc(pp,px,k,kx,ky);
	       tu += tx;
	       p  += px;
	       t  += tx;
	      }
	pp = p;
	tt = t;
	while (tt < tu) *tt++ = gk_2dcalc(pp++,px,k,kx,ky);
	*tt = gk_2dcalc(pp,px,k,kx,ky);

        return;
}
/*
        ---------------------------------------------------------
        gk_2dcalc       Return the result of a single kernel
                        calculation (ie, the output point).

                pp = ptr to location in the input plane
                     corresponding to the upper left corner of
                     the kernel
                px = number of x-points in input plane
                k  = pointer to upper left corner of kernel
                kx = number of x-points in kernel
                ky = number of y-points in kernel
        ---------------------------------------------------------
*/
float   gk_2dcalc(pp,px,k,kx,ky)
        float           *pp;
        register float  *k;
        unsigned int    px,kx,ky;
{
        register float *p,*u,a;

        a = 0.;
        kx--;
        u = pp + kx;
        while (ky > 1)
              {p = pp;
               while (p < u) a += *p++ * *k++;
               a += *p * *k++;
               u  += px;
               pp += px;
               ky--;
              }

        p = pp;
        while (p < u) a += *p++ * *k++;
        a += *p * *k;

        return (a);
}
/* ------------------------------------------------------------------	*/
/*			Plot the gaussian.				*/
/* ------------------------------------------------------------------	*/

static void gr_PlotGauss(histWind, plotfunction)
A_HistWind_t	*histWind;
A_PlotFunction	plotfunction;
{
A_DsplWind_t   *dsplWin= histWind->parent;
A_Data_t	*hdf=dsplWin->parent->parent->data;
int		r, c, nrows=dsplWin->xdim, ncols=dsplWin->ydim;
char histTitle[100], *ht;
FILE		*file;
float		*f = histWind->gdata;
char		*datafile, *cmdfile;
PlotData	plot;
int		xaxis, yaxis, zaxis, ra, dec;

	if(f == NULL)
	{	gr_TextMsgOut("Please Use Apply First");
		return;
	}
	/* Make a title from just the filename by
	   removing leading path compenents.
	*/
	if( (ht = rindex(hdf->pathName, '/')) != NULL)
		ht += 1;
	else
		ht = hdf->pathName;

	if( (plot = NewPlotData(NULL)) == NULL)
	{	printf("gr_ShowGauss: plot malloc err\n"); return; }
	plot->data = hdf;
	plot->pdata = f;
	plot->vectorplot = FALSE;
	plot->contourplot = FALSE;
	plot->imageplot = TRUE;
	plot->nrows = nrows;
	plot->ncols = ncols;
	plot->flipx = FALSE;
	plot->flipy = TRUE;
	plot->axesOrient = &(dsplWin->axesOrient);
	xaxis = plot->axesOrient->col;
	xaxis = (xaxis > 0) ? xaxis -1: -xaxis -1;
	yaxis = plot->axesOrient->row;
	yaxis = (yaxis > 0) ? yaxis -1: -yaxis -1;
	zaxis = plot->axesOrient->axis -1;
	getRaDec( hdf->cvals, &ra, &dec);
	plot->xhms = ((xaxis == ra) && (dec >= 0)) || (dec == xaxis);
	plot->yhms = ((yaxis == ra) && (dec >= 0)) || (dec == yaxis);
	plot->ncontours = 0;

	sprintf(plot->filename, "%s.%s_Pln%d",
		ht, hdf->label[zaxis], plot->axesOrient->plane);

	sprintf(plot->title, "Gauss of %s plane %d of %s",
		hdf->label[zaxis], plot->axesOrient->plane, ht);
	plot->drawtitle = TRUE;

	sprintf(plot->xtitle, "%s", hdf->label[xaxis]);
	plot->drawxtitle = TRUE;
	sprintf(plot->ytitle, "%s", hdf->label[yaxis]);
	plot->drawytitle = TRUE;

	gr_plot(plot, plotfunction);
	free(plot);
}

/* ------------------------------------------------------------------ */

/***				 Plot data. 			****/
static void gr_GaussPlotGNU(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
A_HistWind_t	*histWind=(A_HistWind_t *)client_data;

	if(!SetPlotMethod(GNUPLOT))
		return;
	gr_PlotGauss(histWind, PREVIEWPLOT);
}

static void gr_GaussSaveGNU(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
A_HistWind_t	*histWind=(A_HistWind_t *)client_data;

	if(!SetPlotMethod(GNUPLOT))
		return;
	gr_SetMenuSelection( NULL, w);
	gr_PlotGauss(histWind, SAVEPLOT);
}

static void gr_GaussPlotWIP(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
A_HistWind_t	*histWind=(A_HistWind_t *)client_data;

	if(!SetPlotMethod(WIPPLOT))
		return;
	gr_PlotGauss(histWind, PREVIEWPLOT);
}

static void gr_GaussSaveWIP(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
A_HistWind_t	*histWind=(A_HistWind_t *)client_data;

	if(!SetPlotMethod(WIPPLOT))
		return;
	gr_SetMenuSelection( NULL, w);
	gr_PlotGauss(histWind, SAVEPLOT);
}

static void gr_GaussSavePS(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
A_HistWind_t	*histWind=(A_HistWind_t *)client_data;

	if(!SetPlotMethod(INTERNALPLOT))
		return;
	gr_SetMenuSelection( NULL, w);
	return;		/* Nothing to call here. */
}

/* Save in whatever format was last used. */
static void gr_GaussSave(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
A_HistWind_t	*histWind=(A_HistWind_t *)client_data;

	if(!SetPlotMethod(INTERNALPLOT))
		return;
	/* Hack since INTERNALPLOT isn't really supported here. */
#if 0
	if(plotctl->method == INTERNALPLOT)
	{
		return;
	}
	else
#endif
		gr_PlotGauss(histWind, SAVEPLOT);
}

