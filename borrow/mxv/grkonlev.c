
#include "gr_com.h"
extern void		gr_ContourSave(), gr_ContourSavePS();
extern void		gr_ContourPlotWIP(), gr_ContourSaveWIP();/* hr 6/92 */
extern void		gr_ContourPlotGNU(), gr_ContourSaveGNU();/* hr 6/92 */

#define MAXPTS 8000
#define MAXLEVS 300

static struct {
	int npt;
	int xa[MAXPTS];
	int ya[MAXPTS];
	int xb[MAXPTS];
	int yb[MAXPTS];
	int nlev, levnpts[MAXLEVS];
	float levels[MAXLEVS];
	
	int xlo, xhi, ylo, yhi; /*bounding box */
} g;

/* ------------------------------------------------------------------  */

/* DISPLAY WIN contour toggle button hit, pop up contour dialog */

extern void gr_DsplClosecontourdialog();
extern void gr_Dsplbegincontour();

void gr_Dsplcontourdialog ( w, client_data, call_data)
Widget   w;
caddr_t  client_data;
caddr_t  call_data;
{
A_DsplWind_t   *dsplWin = ( A_DsplWind_t*) client_data;
A_HistWind_t *tmp; 	/* this will be the actual contour dialog window */
Widget	btnW, menuW;

	if (dsplWin->contourWin != NULL) {
		gr_TextMsgOut ("Contour Dialog window already opened!");
		beep();
		return;
		}

	if ((tmp = (A_HistWind_t *)td_Malloc(sizeof(A_HistWind_t),
        		"A_HistWind_t")) == NULL) return;
	dsplWin->contourWin = tmp;

	tmp->shell = gr_MakeWindow2("MXV Contour Levels",
		gr_topLevel, &(tmp->win),
                (XtCallbackProc)gr_DsplClosecontourdialog, (XtPointer)tmp,
		"Contour Levels", "Close", FALSE);

#if 0
	btnW = gr_MakeButton3(NULL, tmp->win ,"apply", NONE,
		(XtCallbackProc)gr_Dsplbegincontour, (caddr_t) tmp,
		NULL, NULL);
#endif
	menuW = gr_MakeMenu( "Contour", tmp->win, "Save Options");
	gr_AddMenuEntry( NULL, menuW, "Save ps format",
			gr_ContourSavePS ,(caddr_t)tmp);
	gr_AddMenuEntry( NULL, menuW, "Save in WIP format",
			gr_ContourSaveWIP ,(caddr_t)tmp);
	gr_AddMenuEntry( NULL, menuW, "Save GNU format",
			gr_ContourSaveGNU ,(caddr_t)tmp);
	gr_AddMenuEntry( NULL, menuW, "Preview with WIP",
			gr_ContourPlotWIP ,(caddr_t)tmp);
	gr_AddMenuEntry( NULL, menuW, "Preview with GNU",
			gr_ContourPlotGNU ,(caddr_t)tmp);

	btnW = gr_MakeMenuButton(NULL, tmp->win, "Apply", menuW,
			gr_ContourSave, (caddr_t)tmp, NULL, NULL);

	/* # of rows (10) should probably be a resource. */
 	tmp->conDialog = gr_MakeDialog(NULL, tmp->win,
				"Enter contour levels", "0.0", 20, 10,
				btnW, NULL);
	gr_ManageChild(tmp->shell);

	 tmp->parent = dsplWin;
 
  	 tmp->prev   = NULL;
  	 tmp->next   = NULL;

   /* init for trace - jng dec 90 */
      tmp->ntraced = 0; /* set to zero, because this is not a trace window */
      tmp->traceX = tmp->traceY = NULL;

   /* null out dialogs and gdata - not in gaussian mode */
   tmp->xDialog = tmp->yDialog = tmp->tDialog = tmp->fDialog =  NULL;
   tmp->gdata = NULL;
	gr_TextMsgOut ("Enter contour levels, then click the apply button\n");

}
/* ------------------------------------------------------------------  */

/* ANI WIN contour toggle button hit, pop up contour dialog */
extern void gr_AniClosecontourdialog();
extern void gr_Anibegincontour();

void gr_Anicontourdialog ( w, client_data, call_data)
Widget   w;
caddr_t  client_data;
caddr_t  call_data;
{
A_AniWind_t   *aniWin = ( A_AniWind_t*) client_data;
A_HistWind_t *tmp; 	/* this will be the actual contour dialog window */

	if (aniWin->contourWin != NULL) {
		gr_TextMsgOut ("Contour Dialog window already opened!");
		beep();
		return;
		}

   if ((tmp = (A_HistWind_t *)td_Malloc(sizeof(A_HistWind_t),
        		    "A_HistWind_t")) == NULL) return;

	aniWin->contourWin = tmp;

	tmp->shell = gr_MakeWindow2("MXV Contour Levels 2",
			gr_topLevel, &(tmp->win),
		(XtCallbackProc)gr_AniClosecontourdialog, (XtPointer)tmp,
		"Contour Levels", "Close", FALSE);


	gr_MakeButton3(NULL, tmp->win ,"okay", NONE,
		(XtCallbackProc)gr_Anibegincontour, (caddr_t) tmp,
		NULL, NULL);

	/* # of rows (10) should probably be a resource. */
 	tmp->conDialog = gr_MakeDialog(NULL, tmp->win,
				"Enter contour levels", "0.0", 20, 10,
				NULL, NULL);
	/* Make widget have more than one row. */
	gr_SetRowsCols(tmp->conDialog, NULL, 10, 0, TRUE, 0, 0);
	gr_ManageChild(tmp->shell);

	 tmp->parent = (A_DsplWind_t*) aniWin;  /* this is ok */
 
  	 tmp->prev   = NULL;
  	 tmp->next   = NULL;

   /* init for trace - jng dec 90 */
      tmp->ntraced = 0; /* set to zero, because this is not a trace window */
      tmp->traceX = tmp->traceY = NULL;

   /* null out dialogs and gdata - not in gaussian mode */
   tmp->xDialog = tmp->yDialog = tmp->tDialog = tmp->fDialog =  NULL;
   tmp->gdata = NULL;

}
/* ------------------------------------------------------------------ */
/* closes the contour dialog window for a DISPLAY WINDOW*/

void
gr_DsplClosecontourdialog (w, client_data, call_data)
Widget   w;
caddr_t  client_data;
caddr_t  call_data;
{
   A_HistWind_t   *histWin=(A_HistWind_t *)client_data;
   A_DsplWind_t   *dsplWin=(A_DsplWind_t *)histWin->parent;

		dsplWin->contourWin = NULL;
      XtDestroyWidget(histWin->conDialog);
      XtDestroyWidget(histWin->shell);
      td_Free((char *)histWin);
}

/* ------------------------------------------------------------------ */
/* closes the contour dialog window for a ANI WINDOW*/

void
gr_AniClosecontourdialog (w, client_data, call_data)
Widget   w;
caddr_t  client_data;
caddr_t  call_data;
{
   A_HistWind_t  *histWin = (A_HistWind_t *)client_data;
   A_AniWind_t   *aniWin  = (A_AniWind_t *) histWin->parent;

	aniWin->contourWin = NULL;
	XtDestroyWidget(histWin->conDialog);
	XtDestroyWidget(histWin->shell);
	td_Free((char *)histWin);
}

/* ------------------------------------------------------------------ */
#define MAXCONLEVELS 50

void gr_Dsplbegincontour( w, client_data, call_data)
Widget   w;
caddr_t  client_data;
caddr_t  call_data;
{
   A_HistWind_t 	*histWin = ( A_HistWind_t *) client_data;
  	A_DsplWind_t   *dsplWin= histWin->parent;
	A_CubeWind_t	*cubeWin = dsplWin->parent;
  	A_BossWind_t 	*curboss = gr_topWin.bossWin;
   A_CubeWind_t 	*curcube;
   A_DsplWind_t 	*curdspl;

   A_Data_t    	*hdf = cubeWin->parent->data;
   float32        min = hdf->min, max = hdf->max,frac = hdf->rangeFrac;
   float32        ***hdfdata = hdf->data;
	float32* fdata; /* points to a plane of 2d float data */
	A_Axes_t			*orient = &( dsplWin->axesOrient);
	int dx,dy;
/*	float clevels[MAXCONLEVELS];*/
float	*clevels;
	int nlev;
	int i;
	int xdim, ydim;
	char title[80];
	char  word[80];
	char *floatstostring();
	char * ss;
	char buf[200];

#if 0
	ss = gr_DialogGetValue(histWin->conDialog);
	i=0;
	str_setstring(ss);
	while(str_getnextword(word)) {
		if (sscanf(word,"%f",&clevels[i])) { i++; }		
		if (i>=MAXCONLEVELS) break;
		}
	nlev = i;
#else
	gr_DialogGetFloatValues(histWin->conDialog, &clevels, &nlev);
#endif

	dx = dy =  dsplWin->scale;
	fdata = (float32*) dsplWin->fdata;

  xdim = td_HdfgetDim(hdf,orient->col);
  ydim = td_HdfgetDim(hdf,orient->row);

	gr_TextMsgOut ("Wait - CONTOURING..."); beep();

	gr_WidgetCursor(dsplWin->shell,XC_watch);
	gr_MakeContourLines (fdata, xdim, ydim, dx, dy, clevels, nlev);
	free(clevels);
	gr_WidgetCursor(dsplWin->shell,XC_draped_box);
	gr_TextMsgOut ("done.\n "); beep();

	/*- - - - - - - - - - - - - - - - - - - - */
  if (dsplWin->synchronize == FALSE)
	gr_DrawContourLines (dsplWin->imageWin ); /* draw contour over image */
   else
   while (curboss != NULL) {
      curcube = curboss->cubeWin;
      while (curcube != NULL) {
         curdspl = curcube->dsplWin;
         while (curdspl != NULL) {
            if ((curdspl == dsplWin) || (curdspl->synchronize == TRUE))
				gr_DrawContourLines (curdspl->imageWin ); 
            if ((curdspl != dsplWin) && (curdspl->synchronize == TRUE))
					drawmark (curdspl->imageWin ); 
            curdspl = curdspl->next;
         }
         curcube = curcube->next;
      }
      curboss = curboss->next;
   }
	/*- - - - - - - - - - - - - - - - - - - - */

#define psf "show.ps"
	/* - - - - - - - - - - -- - - - - - - - - - - - - - - - - - - - - - -  */
	/* This CODE generates a contour postscript file--- */
	{ 
		int i,t,n, level;
		dumppscontourBegin (g.xlo, g.ylo, g.xhi, g.yhi);
		t = 0;
		for(i=0;i<g.nlev;i++) {
			level = (int) (g.levels[i] * 10); /* prevent truncation to 0 */
			n = g.levnpts[i];
			dumppscontourLevel(&g.xa[t], &g.ya[t], &g.xb[t], &g.yb[t], n, level);
			t +=n;	
		}
	/* - - - - - - - - - - -- - - - - - - - - - - - - - - - - - - - - - -  */

	sprintf(title,"%s ",hdf->pathName);
	PSsetTopTitle(title);

	/* generate x and y axes titles if Miriad file, don't bother if HDF */
	if ((hdf->format == MIRIAD) || (hdf->format == FITS)) {
		char xTitle[200], yTitle[200];
		xTitle[0] =  yTitle[0] = '\0';
		gr_getMiriadAxesTitles (dsplWin, xTitle, yTitle);
		PSsetHorizTitle (xTitle);	
		PSsetVertTitle (yTitle);	
	}
	/* generate x and y axes tick values if Miriad file,
		don't bother if HDF
	*/
	if ((hdf->format == MIRIAD) || (hdf->format == FITS)) {
		char xtick0[40], ytick0[40];
		char xtick1[40], ytick1[40];

		xtick0[0] =  ytick0[0] = '\0';
		xtick1[0] =  ytick1[0] = '\0';

		gr_getMiriadEndAxesTickValues(dsplWin,
			xtick0, ytick0, xtick1, ytick1);
		trimdecimals (xtick0,2); trimdecimals (ytick0,2);
		trimdecimals (xtick1,2); trimdecimals (ytick1,2);

	 	PSsetHoriz0Tick (xtick0);
		PSsetVert0Tick (ytick0); 

	 	PSsetHoriz1Tick (xtick1);
		PSsetVert1Tick (ytick1);

	}
	
	dumppscontourEnd ();

	/* clear out the titles */
	PSsetTopTitle(" "); PSsetVertTitle(" "); PSsetHorizTitle(" ");

	}

}

/* ------------------------------------------------------------------ */
/* jng 3-apr-91. given decimal string, strips away excess decimals
to precision specified by ndec (assumed positive).
Will modify input string - make sure it is a char array.
Specialized routine, not to be used  outside this file!
*/
 
static trimdecimals (valstr, ndec) 
char *valstr; int ndec;
  {
	int i,ns, decpos;
	ns = strlen(valstr);
	for(i=ns-1;i>=0;i--) if (valstr[i]=='.') break;
	decpos = i;
   if (decpos<=0) return; /* nothing to do, no dec pts found */
	
	if(decpos+ndec+1 >= ns) return; /* string already has enough precision */	
	valstr[decpos+ndec+1] ='\0'; /* effectively trimming off excess chars */
}

/* ------------------------------------------------------------------ */
/* used only to print a RASTER */
printcontour () {
   int bound[4]; /* bounding box */

   bound[0] = g.xlo; bound[1] = g.ylo;
   bound[2] = g.xhi; bound[3] = g.yhi;
   dumppscontour ( g.xa, g.ya, g.xb, g.yb, g.npt, bound);
}

/* ------------------------------------------------------------------ */

static char* my_string = NULL;
static int my_stringpos, my_stringlen  = 0;

static int myblankchar(c) int c; { if(c >' ' && c <='~') return(0); return(1); }
str_setstring(ss) char *ss; 
{
  	my_string = ss;
  	my_stringpos = 0;
	my_stringlen = strlen(my_string);
}

int str_getnextword(aword) char *aword; 
{
	int i, c;
	char * word = aword;

	i= my_stringpos;
   while( i<my_stringlen) {
		if (!myblankchar(my_string[i])) break;
      i++;
   }
   while( i<my_stringlen) {
		if (myblankchar(my_string[i])) break;
		else  *word++  = my_string[i]; 
		i++;
   }
	*word++ = '\0';
	my_stringpos = i;
	if (my_stringpos >= my_stringlen) return (0);
	else return (1); 
}

/* ------------------------------------------------------------------ */
char * floatstostring(clevels, nlev) 
float clevels[]; int nlev; 
{
	int i;
	char * ss, temp[70];

	ss = (char *) malloc(nlev * 9); if (ss == NULL) return(NULL); *ss = '\0';
	for(i=0;i<nlev;i++) {
		sprintf(temp,"%f \n",clevels[i]);
		strcat(ss,temp);
		}
	return (ss);
	
}

/* ------------------------------------------------------------------ */
void gr_SDSHardcopy ( w, client_data, call_data)
Widget   w;
caddr_t  client_data;
caddr_t  call_data;
{
  A_DsplWind_t   *dsplWin=(A_DsplWind_t *)client_data;
	A_CubeWind_t	*cubeWin = dsplWin->parent;
   A_Data_t    	*hdf = cubeWin->parent->data;
   float32        min = hdf->min, max = hdf->max,frac = hdf->rangeFrac;
   float32        *fdata; /* pts to a 2d plane of float data */
   float32        ***hdfdata = hdf->data;
	A_Axes_t			*orient = &( cubeWin->axesOrient);
	int dx,dy;
	int i;
	int xdim, ydim;
	char title[100];

	gr_WidgetCursor(dsplWin->shell,XC_watch);
	gr_TextMsgOut ("Wait - creating Hardcopy..."); beep();

	dx = dy =  dsplWin->scale;
	fdata = (float32*) dsplWin->fdata;

	xdim = td_HdfgetDim(hdf,orient->col);
 	ydim = td_HdfgetDim(hdf,orient->row);

	sprintf(title,"%s", hdf->pathName);
   /* dumppsimage (fdata, xdim, ydim,  dx,dy, min, max, title); */
   dumppsCOLORimage (fdata, xdim, ydim,  dx,dy, min, max,title, gr_color.palette);

	gr_WidgetCursor(dsplWin->shell,XC_draped_box);
	gr_TextMsgOut ("done.\n "); beep();

}
/* ------------------------------------------------------------------ */
gr_DrawContourLines (w)
Widget w;
{
   Display     *dpy=XtDisplay(w);
   Drawable win=XtWindow(w);
   XGCValues   values;
   GC          drawGC;
	int i;
	int xa, ya, xb, yb;

   drawGC = XtGetGC(w,GCForeground,&values);
	XSetForeground(dpy,drawGC, WhitePixel(dpy,DefaultScreen(dpy)) );
	
	for(i=0;i<g.npt;i++) {
		xa = g.xa[i]; ya = g.ya[i];
		xb = g.xb[i]; yb = g.yb[i];
	   XDrawLine(dpy,win,drawGC,xa,ya,xb,yb);
	}
}

/* =================================================================== */
/* routines for storing contour points and bounding box */

clearpts() { g.npt = 0; g.nlev = 0; }

saveboundbox (xlo,ylo,xhi,yhi)
int xlo,ylo,xhi,yhi;
{
	g.xlo = xlo; g.xhi = xhi;
	g.ylo = ylo; g.yhi = yhi;
}

savelevel (level) float level; {
	int i, n, t;

	if (g.nlev >= MAXLEVS-1) {printf("savelevel: too many levels\n"); return; }

	for(t=0, i=0;i<g.nlev;i++)  t += g.levnpts[i]; 

	n =  g.npt - t;

	g.levnpts[g.nlev] = n;
	g.levels[g.nlev] = level;
	g.nlev++;
}

savepts (xa,ya,xb,yb) 
int xa,ya,xb,yb; 
{
   if(g.npt>=MAXPTS-1) return;
   g.xa[g.npt] = xa;
   g.ya[g.npt] = ya;
   g.xb[g.npt] = xb;
   g.yb[g.npt] = yb;
   g.npt++;
}


/* ------------------------------------------------------------------ */
putline (x1, y1, x2, y2)  float x1, y1, x2, y2; 
{ 
	savepts ( (int) x1, (int) y1, (int) x2, (int) y2);
}

/* ------------------------------------------------------------------ */
/* kkk */
int gr_MakeContourLines (a, nx, ny, dx, dy, clvl, nclvl)

float a[]; /* 2d (nx by ny) float array */
int nx,ny; /* dims of 2d array */
int dx, dy; /* step bwteen grid */
float clvl[]; /* user-specified contour levels */
int nclvl; /* no of such levels */

{
	int i;
	float t, dt;
   float * xg, * yg; /* grid */
	
	xg = (float*) malloc(sizeof(float)*nx);
	yg = (float*) malloc(sizeof(float)*ny);
	for (dt = (float) dx, t=0.0, i=0;i<nx;i++,t+=dt) xg[i] = t;
	for (dt = (float) dy, t=0.0, i=0;i<ny;i++,t+=dt) yg[i] = t;

	clearpts();
	saveboundbox(0,0,dx*nx, dy*ny);
	for (i=0;i<nclvl;i++) {
	   mxv_make_contour (a,xg, yg, nx, ny, &clvl[i], 1);
		savelevel (clvl[i]);
		}
	free(xg); free(yg);
	return;
} /* gr_MakeContourLines */

/* ------------------------------------------------------------------ */
/* jng 25-apr-91 */
/* Draw a X mark in lower left corner of image, to show this is an Overlay */
drawmark (w)
Widget w;
{
   Display     *dpy=XtDisplay(w);
   Drawable win=XtWindow(w);
   XGCValues   values;
   GC          drawGC;

   drawGC = XtGetGC(w,GCForeground,&values);
	XSetForeground(dpy,drawGC, WhitePixel(dpy,DefaultScreen(dpy)) );
	
	XDrawLine (dpy,win,drawGC, 2,2,9,9);
	XDrawLine (dpy,win,drawGC, 2,9,9,2);
}


