#include <stdio.h>
#include <time.h>

/* ================================================================== */

#define XDISP 90
#define YDISP 90
#define emits(ss)  fprintf(pf,"%s\n",ss)

static    FILE *pf = NULL;

/* strings used for labelling ticks along axes */
static	char *   x0Tick = NULL; /* min x tick */
static 	char *   y0Tick = NULL; /* min y tick */
static	char *   x1Tick = NULL; /* max x tick */
static 	char *   y1Tick = NULL; /* max y tick */
static	char *   xmidTick = NULL;
static 	char *   ymidTick = NULL;
static	char *   xaxisTitle = NULL;
static 	char *   yaxisTitle = NULL;
static 	char *   topTitle   = NULL;

static struct ps_work_area {
	int xmax, xmin, ymax, ymin;
} ps;

static char * conpsfile = "contour.ps";
/* ------------------------------------------------------------------ */
dumppscontourBegin ( xlo, ylo, xhi, yhi)
int xlo, ylo, xhi, yhi;
{
	char timenow[60];

	ps.xmin = xlo;  ps.ymin = ylo; ps.xmax = xhi; ps.ymax = yhi;

	getCurrentTime (timenow);

   if (NULL==(pf=fopen(conpsfile,"w"))) {
				 printf("open %s err\n",conpsfile); return; }
   emits ("%!PS-Adobe-?.0");
	emits ("%%By: Jason Ng");
   fprintf(pf,"%%CreationDate: %s\n", timenow);

   emits ("%%EndComments");
	emits (".05 setlinewidth 0 setgray");
	emits("/jl { moveto lineto } def"); 
}

/* ------------------------------------------------------------------ */
dumppscontourLevel (pxa, pya, pxb, pyb, npt,level)
int pxa[], pya[], pxb[], pyb[];
int npt, level;
{
	int	i;
	int xa,ya,xb,yb;
	int ydiff;


		fprintf(pf,"%% lev=%d npt=%d\n", level, npt);
	emits("stroke");
	if (level <0) 
		 emits("[2 2] 1 setdash"); /* dash-line */
	else 
		 emits("[] 0 setdash"); /* full-line */

	ydiff = ps.ymax - ps.ymin;
	for (i=0;i<npt;i++) {
		xa = pxa[i]; xb = pxb[i];
		ya = pya[i]; yb = pyb[i];

		/* must be rotated in x-axis to map to postscript coordinate axes */
		ya  = ydiff - ya;
		yb  = ydiff - yb;

		xa += XDISP; ya += YDISP;
		xb += XDISP; yb += YDISP;


		fprintf(pf,"%4d %4d %4d %4d jl ", xa, ya , xb, yb);
		if (i%3==0) fprintf(pf,"\n");
	}
	emits("stroke"); 

}
/* ------------------------------------------------------------------ */
static savestring (src,dst) char *src, ** dst; {
   int n;
   if (*dst != NULL) free (*dst);
   n = strlen(src);
   *dst = (char*) malloc (sizeof(char) * n + 1 ); /* space for '\0' */
   if (*dst==NULL) return;
   strcpy (*dst, src);
}
/* ================================================================== */
PSsetVert0Tick(ss) char * ss; {
	savestring (ss, &y0Tick);
	printf("y0Tick saved [%s]\n",y0Tick);
}
/* ------------------------------------------------------------------ */
PSsetVert1Tick(ss) char * ss; {
	savestring (ss, &y1Tick);
	printf("y1Tick saved [%s]\n",y1Tick);
}
/* ================================================================== */
PSsetHoriz0Tick(ss) char * ss; {
	savestring (ss, &x0Tick);
	printf("x0Tick saved [%s]\n",x0Tick);
}
/* ------------------------------------------------------------------ */
PSsetHoriz1Tick(ss) char * ss; {
	savestring (ss, &x1Tick);
	printf("x1Tick saved [%s]\n",x1Tick);
}
/* ================================================================== */
PSsetVertTick(ss) char * ss; {
	savestring (ss, &ymidTick);
	printf("ymidTick saved [%s]\n",ymidTick);
}
/* ------------------------------------------------------------------ */
PSsetHorizTick(ss) char * ss; {
	savestring (ss, &xmidTick);
	printf("xmidTick saved [%s]\n",xmidTick);
}
/* ================================================================== */
PSsetTopTitle( ss) char * ss; {
	savestring (ss, &topTitle);
	printf("topTitle saved [%s]\n", topTitle);
}
/* ------------------------------------------------------------------ */
PSsetHorizTitle( ss) char * ss; {
	savestring (ss, &xaxisTitle);
	printf("xaxisTitle saved [%s]\n",xaxisTitle);
}
/* ------------------------------------------------------------------ */
PSsetVertTitle( ss) char * ss; {
	savestring (ss, &yaxisTitle);
	printf("yaxisTitle saved [%s]\n",yaxisTitle);
}
/* ------------------------------------------------------------------ */
#define TKLEN 3				/* tick length */

dumppscontourEnd () {

	char timenow[60];
	
	getCurrentTime( timenow);

   emits("stroke");
	emits("[] 0 setdash"); /* full-line */

	/* - - This BLOCK: throw in some tick marks - - - - - - - */
	{
	int i, x, y, len, dlen;
	int  nticks = 15; /* should be ODD */
	int midtick = (nticks-1)/2;

	emits ("0.6 setlinewidth");

	len = ps.xmax - ps.xmin; dlen = len/(nticks-1);	
	y = YDISP;
	for( x=0, i=0;i<nticks;i++, x+=dlen )  
		if (i==midtick)
  		fprintf(pf,"%4d %4d %4d %4d jl\n",x+XDISP,y+TKLEN,x+XDISP,y-TKLEN);
		else
		fprintf(pf,"%4d %4d %4d %4d jl\n",x+XDISP,YDISP,x+XDISP,YDISP-TKLEN);

	y = ps.ymax +YDISP;
	for( x=0, i=0;i<nticks;i++, x+=dlen )  
		if (i==midtick)
		fprintf(pf,"%4d %4d %4d %4d jl\n",x+XDISP,y-TKLEN ,x+XDISP,y+TKLEN);
		else
		fprintf(pf,"%4d %4d %4d %4d jl\n",x+XDISP,y ,x+XDISP,y+TKLEN);

	/* put tick values along x axis, if any */
	if (xmidTick != NULL) {
		emits ("/Helvetica findfont 7 scalefont setfont");
   	fprintf(pf,"%d %d moveto ", XDISP+dlen*midtick, YDISP-9);
   	fprintf(pf,"(%s) show \n",xmidTick);
	}
	if (x0Tick != NULL) {
		emits ("/Helvetica findfont 7 scalefont setfont");
   	fprintf(pf,"%d %d moveto ", XDISP, YDISP-9);
   	fprintf(pf,"(%s) show \n",x0Tick);
	}
	if (x1Tick != NULL) {
		emits ("/Helvetica findfont 7 scalefont setfont");
   	fprintf(pf,"%d %d moveto ", XDISP+ps.xmax, YDISP-9);
   	fprintf(pf,"(%s) show \n",x1Tick);
	}

	len = ps.ymax - ps.ymin; dlen = len/(nticks-1);	
	x = XDISP;
	for( y=0, i=0;i<nticks;i++, y+=dlen )  
		if (i==midtick)
		fprintf(pf,"%4d %4d %4d %4d jl\n",x+TKLEN,y+YDISP,x-TKLEN,y+YDISP);
		else
		fprintf(pf,"%4d %4d %4d %4d jl\n",x ,y+YDISP,x-TKLEN,y+YDISP);
	

	x = ps.xmax +XDISP;
	for( y=0, i=0;i<nticks;i++, y+=dlen )  
		if (i==midtick)
		fprintf(pf,"%4d %4d %4d %4d jl\n",x-TKLEN ,y+YDISP,x+TKLEN,y+YDISP);
		else
		fprintf(pf,"%4d %4d %4d %4d jl\n",x ,y+YDISP,x+TKLEN,y+YDISP);

	/* put  tick values along y axis, if any */
	if (y0Tick != NULL) {
		emits ("/Helvetica findfont 7 scalefont setfont");
   	fprintf(pf,"%d %d moveto ", XDISP-50, YDISP);
   	fprintf(pf,"(%s) show \n",y0Tick);
	}
	if (y1Tick != NULL) {
		emits ("/Helvetica findfont 7 scalefont setfont");
   	fprintf(pf,"%d %d moveto ", XDISP-50, YDISP+ps.ymax);
   	fprintf(pf,"(%s) show \n",y1Tick);
	}
	if (ymidTick != NULL) {
		emits ("/Helvetica findfont 7 scalefont setfont");
   	fprintf(pf,"%d %d moveto ", XDISP-50, YDISP + dlen*midtick);
   	fprintf(pf,"(%s) show \n",ymidTick);
	}

	emits ("stroke");
	}
	/* - - - - - - - - - - - - - - - - - - - - - - - - - - - */

	/* put a framing box around it */
	emits ("2 setlinewidth");
   fprintf(pf,"%d %d moveto\n", ps.xmin+XDISP, ps.ymin+YDISP);
   fprintf(pf,"%d %d lineto\n", ps.xmax+XDISP, ps.ymin+YDISP);
   fprintf(pf,"%d %d lineto\n", ps.xmax+XDISP, ps.ymax+YDISP);
   fprintf(pf,"%d %d lineto\n", ps.xmin+XDISP, ps.ymax+YDISP);
   emits ("closepath");
   emits ("stroke");

	/* put title along x and y axis, if any */
	emits ("/Helvetica findfont 9 scalefont setfont");


	if (yaxisTitle != NULL) {
   	fprintf(pf,"%d %d moveto ", XDISP-55, YDISP + 40);
   	fprintf(pf,"(%s) show \n",yaxisTitle);
	}
	if (xaxisTitle != NULL) {
   	fprintf(pf,"%d %d moveto ", XDISP+75, YDISP - 22);
   	fprintf(pf,"(%s) show \n",xaxisTitle);
	}


	/* put title on top, if any */
	emits ("0.3 setlinewidth");
	emits ("/Helvetica-BoldOblique findfont 14 scalefont setfont");
   fprintf(pf,"%d %d moveto ", XDISP, ps.ymax+YDISP+10);
	emits ("(MXV) true charpath stroke");

	if (topTitle != NULL) {
		emits ("/Helvetica findfont 10 scalefont setfont");
  	 	fprintf(pf,"%d %d moveto ", XDISP+100, ps.ymax+YDISP+10);
  		fprintf(pf,"(%s) show \n",topTitle);
	}

	/* put time stamp */
	emits ("/Helvetica findfont 6 scalefont setfont");
   fprintf(pf,"%d %d moveto ", XDISP, YDISP-32);
   fprintf(pf,"(MXV %s) show\n", timenow);

   emits ("showpage");

	fclose(pf); pf=NULL;

	printf("\nCONTOUR PostScript file %s created. Print it!\n\n", conpsfile); 
	beep();
}
/* ------------------------------------------------------------------ */

/* ================================================================== */
/* 
This older version just dumps out line segments of a contour
in a postcript file. Replaced by the series "dumppscontourBegin,
dumppscontourLevel, dumppscontourEnd" which gives more control
By itself this version is entirely stand-alone and fully functional.
Thus, either use this routine ALONE, or use the series, but don't mix.
*/ 

dumppscontour (pxa, pya, pxb, pyb, npt, bound)
int pxa[], pya[], pxb[], pyb[];
int bound[4]; /* bounding box */
int npt;
{
   int i;
   int xa,ya,xb,yb;
	int xmax, ymax,xmin, ymin;
	char timenow[60];

	xmin = bound[0]; ymin = bound[1];
	xmax = bound[2]; ymax = bound[3];

	getCurrentTime(timenow);

   if (NULL==(pf=fopen(conpsfile,"w"))) 
			{ printf("open %s err\n",conpsfile); return; }
   emits ("%!PS-Adobe-?.0");
	emits ("%%By: Jason Ng");
   fprintf(pf,"%%CreationDate: %s\n", timenow);

   emits ("%%EndComments");
	emits (".05 setlinewidth 0 setgray");

	emits("/jl { moveto lineto } def"); 
	
	for(i=0;i<npt;i++) {
		xa = pxa[i]; xb = pxb[i];
		ya = pya[i]; yb = pyb[i];

		/* must be rotated in x-axis to map to postscript coordinate axes */
		ya  = ymax + ymin - ya;
		yb  = ymax + ymin - yb;

		xa += XDISP; ya += YDISP;
		xb += XDISP; yb += YDISP;

		if(i%100==0) { emits("stroke"); }

		fprintf(pf,"%4d %4d %4d %4d jl ", xa, ya , xb, yb);
		if (i%3==0) fprintf(pf,"\n");
	}
   emits("stroke");

	/* draw a framing box around it */
	emits ("2 setlinewidth");
   fprintf(pf,"%d %d moveto\n", xmin+XDISP, ymin+YDISP);
   fprintf(pf,"%d %d lineto\n", xmax+XDISP, ymin+YDISP);
   fprintf(pf,"%d %d lineto\n", xmax+XDISP, ymax+YDISP);
   fprintf(pf,"%d %d lineto\n", xmin+XDISP, ymax+YDISP);
   emits ("closepath");
   emits ("stroke");

	/* put a title on top */
	emits ("0.3 setlinewidth");
	emits ("/Helvetica-BoldOblique findfont 14 scalefont setfont");
   fprintf(pf,"%d %d moveto ", XDISP, ymax+YDISP+10);
	emits ("(MXV) true charpath stroke");

	emits ("/Helvetica findfont 7 scalefont setfont");
   fprintf(pf,"%d %d moveto ", XDISP, YDISP-10);
   fprintf(pf,"(MXV %s) show\n", timenow);

   emits ("showpage");

	fclose(pf); pf=NULL;

	printf("\nCONTOUR PostScript file %s created. Print it!\n\n", conpsfile); 
	beep();
}

/* ================================================================== */

static char ims[200];
dumptonebox (x,y, tone) 
int x,y;
float tone;
{
sprintf(ims,"%5.2f %4d %4d box ", tone , x+XDISP, y+YDISP);
}
/* ------------------------------------------------------------------ */

#define jmf "picture.ps"

int dumppsimage (im, nx, ny, dx,dy, minval, maxval, title) 
int nx, ny;
int dx, dy;
float im[]; 				/* 2D float data (nx x xy) */
float minval, maxval;
char * title;
{

#define ATONEVALUE(x,y) ( ((float)  im[(y)*nx + (x)] - minval )/range )


	unsigned char c;
	int i,j;
   float  tone;
	int xpos, ypos;
	float range;
	long count;
	int xmin, xmax, ymin, ymax;
   char timenow[60];

	getCurrentTime (timenow);

	/* bounding box */
	xmin = 0; xmax = nx*dx;
	ymin = 0; ymax = ny*dy;

range = maxval - minval;

if (NULL==(pf=fopen(jmf,"w"))) { printf("error open %s\n",jmf); return;}

   emits ("%!PS-Adobe-?.0");
	emits ("%%!MXV. Condensed image file");
   emits ("%%By: Jason Ng");
   fprintf(pf,"%%CreationDate: %s\n", timenow);

	fprintf(pf, "%%CreationDate: %s\n", timenow);
	fprintf(pf,"/dx %d def 		\n/dy %d def \n", dx, dy);
	fprintf(pf,"/xdisp %d def 	\n/ydisp %d def \n", XDISP, YDISP);
	fprintf(pf,"/nx %d 1 sub def \n/ny %d 1 sub def \n\n", nx, ny);
	fprintf(pf,"/myfac %f def\n", 1.0/range);

	emits ("/box {  dx 0 rlineto 0 dy rlineto ");
	emits ("     dx neg 0 rlineto closepath fill newpath } def ");

	emits ("/jasit { newpath ");
	emits ("		/yloc yloc ydisp add def");
	emits ("		0 1 nx {  dup");
	emits ("			tones exch get myfac mul setgray"); 
	emits ("			dx mul xdisp add yloc moveto box");		
	emits ("  } for } def\n");

	  /* ----- loop for array cells ---- */

		count = 0;
		for (ypos = 0,j=0; j<ny; j++) {
			ypos +=dy;
			fprintf(pf,"\n /yloc %d  def\n",ymax + ymin -ypos);
			emits ("/tones [");
			for (xpos = 0, i=0; i<nx; i++) {
				 tone = (ATONEVALUE (i, j) );
				fprintf(pf,"%3d ", (int) ( (1.0-tone) * range) );
					if (count%20==0) fprintf(pf,"\n");
					xpos +=dx;
					count++;
			}
			emits ("\n] def jasit");
		}

	/* fancy titles etc */

	emits("0 setgray");
	emits ("0.3 setlinewidth");

   fprintf(pf,"%d %d moveto\n", xmin+XDISP, ymin+YDISP);
   fprintf(pf,"%d %d lineto\n", xmax+XDISP, ymin+YDISP);
   fprintf(pf,"%d %d lineto\n", xmax+XDISP, ymax+YDISP);
   fprintf(pf,"%d %d lineto\n", xmin+XDISP, ymax+YDISP);
   emits ("closepath stroke");

   emits ("0.3 setlinewidth");
   emits ("/Helvetica-BoldOblique findfont 14 scalefont setfont");
   fprintf(pf,"%d %d moveto ", XDISP, ymax+YDISP+10);
   emits ("(MXV) true charpath stroke");

	/* brief title */
   emits ("/Helvetica-Oblique findfont 7 scalefont setfont");
   fprintf(pf,"%d %d moveto ", XDISP+90, ymax+YDISP+10);
   fprintf(pf,"(%s) show \n",title);


   emits ("/Helvetica findfont 7 scalefont setfont");
   fprintf(pf,"%d %d moveto ", XDISP, YDISP-10);
   fprintf(pf,"(MXV %s) show\n", timenow);

fprintf (pf,"showpage\n");
fclose(pf); pf=NULL; 
printf("\nIMAGE Postscript file %s created. Print it!\n\n",jmf); beep();
}

/* ================================================================== */
getCurrentTime (ss) 
char *ss;
{
	time_t tp =  time(NULL);
	sprintf(ss,"%s",(char*) ctime(&tp) );
}

/* ================================================================== */
getmaxmin(xx,n,xmax,xmin) 
float xx[],*xmax,*xmin;
int n;
{
  float tmax = -1.0e9, tmin = 1.0e9;
  int i;
  for(i=0;i<n;i++) {
   if(tmax < xx[i]) tmax = xx[i];
   if(tmin > xx[i]) tmin = xx[i];
   }

  *xmax = tmax;
  *xmin = tmin;
}
/* ================================================================== */



dumppsBarGraph (nvals, pvals, width, title)

int nvals, pvals[];
char * title;
{
	int i;
	int x, y;
   char timenow[60];
	FILE * pf;
	char * profpsfile = "profile.ps";

   getCurrentTime (timenow);

	if ( NULL==(pf=fopen(profpsfile,"w")) ) 
		{ printf("gr_HistPrint: open file %s error\n", profpsfile); return (-1); }

	emits ("%!PS-Adobe-?.0");
   emits ("%%By: Jason Ng");
   fprintf(pf,"%%CreationDate: %s\n", timenow);
   emits ("%%Profile plot ");
   emits ("%%EndComments");
   emits("/jl { moveto lineto } def");

	fprintf (pf, "%f setlinewidth 0.4 setgray\n", ((float)width) - 1.2);

	x =  XDISP;
	for(i=0;i<nvals;i++) {
      y =  pvals[i];
      x += width;
      fprintf(pf,"%4d %4d %4d %4d jl\n ", x, YDISP,  x,  y + YDISP);
	}
   emits("stroke ");

   emits ("0 setgray");

   /* put MXV logo on top */
   emits ("0.3 setlinewidth");
   emits ("/Helvetica-BoldOblique findfont 14 scalefont setfont");
   fprintf(pf,"%d %d moveto ", XDISP, 256 +YDISP+10);
   emits ("(MXV) true charpath stroke");

   /* brief title */
   emits ("/Helvetica-Oblique findfont 7 scalefont setfont");
   fprintf(pf,"%d %d moveto ", XDISP+90, 256 +YDISP+10);
   fprintf(pf,"(%s) show \n",title);

   /* put bounding box */
   emits ("newpath");
   fprintf(pf,"%d %d moveto\n", XDISP, YDISP);
   fprintf(pf,"%d %d lineto\n", XDISP, YDISP+256);
   fprintf(pf,"%d %d lineto\n", XDISP+(width*nvals), YDISP+256);
   fprintf(pf,"%d %d lineto\n", XDISP+(width*nvals), YDISP);
   emits ("closepath");
   emits ("stroke");

   /* put time stamp */
   emits ("/Helvetica findfont 6 scalefont setfont");
   fprintf(pf,"%d %d moveto ", XDISP, YDISP - 20);
   fprintf(pf,"(MXV %s) show\n", timenow);

   emits("showpage\n");

	fclose(pf);
#if 0
	beep();
	 printf("Profile Postscript file %s created. Print it!\n", profpsfile);
#else
	{ char buf[256];
		sprintf(buf, "Profile Postscript file %s created.\n",
			profpsfile);
	beep();
	gr_TextMsgOut(buf);
	}
#endif

	/* &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& */
	return 0; /* hr 3/19/92 */
}

/* ------------------------------------------------------------------ */
