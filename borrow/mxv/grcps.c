#include <stdio.h>
/* ================================================================== */

#define emits(ss)  fprintf(pf,"%s\n",ss)
#define XDISP 90
#define YDISP 90
#define jmf "cpicture.ps"

static    FILE *pf = NULL;

/* ================================================================== */

/*
*
* Jason Ng 4-APR-91
* This version takes an SDS and creates a COLOR-PostScript file
* NOTE: takes an extra parameter pal.
*
*/

int dumppsCOLORimage (im, nx, ny, dx,dy, minval, maxval, title, pal ) 
int nx, ny;
int dx, dy;
float im[]; 				/* 2D float data (nx * xy) */
float minval, maxval;
unsigned char pal[768];
char * title;

{

#define ACOLORINDEX(x,y) ( ((float)  im[(y)*nx + (x)] - minval )/range )

	unsigned char c;
	int i,j, itone;
   float  tone;
	int xpos, ypos;
	float range;
	long count;
	int xmin, xmax, ymin, ymax;
   char timenow[60];
	float rmap[256], gmap[256], bmap[256];

	getCurrentTime (timenow);

	/* bounding box */
	xmin = 0; xmax = nx*dx;
	ymin = 0; ymax = ny*dy;
	range = maxval - minval;


if (NULL==(pf=fopen(jmf,"w"))) { printf("error open %s\n",jmf); return;}

	/* extract palette components into r g b maps */
	for(j=0, i=0;i<256;i++, j+=3) {
      rmap[i] = ((float)pal[j])/256.0; 
      gmap[i] = ((float)pal[j+1])/256.0; 
      bmap[i] = ((float)pal[j+2])/256.0; 
      }

   emits ("%!");
   emits ("%%PS-Adobe-?.0");
	emits ("%%!MXV. Condensed COLOR image file");
   emits ("%%By: Jason Ng");

	fprintf(pf, "%%CreationDate: %s\n", timenow);
	fprintf(pf,"/dx %d def 		\n/dy %d def \n", dx, dy);
	fprintf(pf,"/xdisp %d def 	\n/ydisp %d def \n", XDISP, YDISP);
	fprintf(pf,"/nx %d 1 sub def \n/ny %d 1 sub def \n\n", nx, ny);

	emits ("/box {  dx 0 rlineto 0 dy rlineto ");
	emits ("     dx neg 0 rlineto closepath fill newpath } def ");

	emits ("/jasit { newpath ");
	emits ("		/yloc yloc ydisp add def");
	emits ("		0 1 nx {  dup");
	emits ("			tones exch get ");
	emits ("			/cpt exch def ");
	emits (" 		rmap cpt get ");
	emits (" 		gmap cpt get ");
	emits (" 		bmap cpt get ");
	emits (" 		setrgbcolor ");
	emits ("			dx mul xdisp add yloc moveto box");		
	emits ("  } for } def\n");
	emits ("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  ");
	emits ("/rmap [ ");
   for(i=0;i<256;i++) {
      if(i%8==0) fprintf(pf,"\n");
      fprintf(pf, " %5.3f", rmap[i]);
      }
    fprintf(pf,"\n ] def %% red map \n");

	emits ("/gmap [ ");
   for(i=0;i<256;i++) {
      if(i%8==0) fprintf(pf,"\n");
      fprintf(pf, " %5.3f", gmap[i]);
      }
    fprintf(pf,"\n ] def %% green map \n");

	emits ("/bmap [ ");
   for(i=0;i<256;i++) {
      if(i%8==0) fprintf(pf,"\n");
      fprintf(pf, " %5.3f", bmap[i]);
      }
    fprintf(pf,"\n ] def %% blue map \n");

	emits ("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  ");

	  /* ----- loop for array cells ---- */

		count = 0;
		for (ypos = 0,j=0; j<ny; j++) {
			ypos +=dy;
			fprintf(pf,"\n /yloc %d  def\n",ymax + ymin -ypos);
			emits ("/tones [");
			for (xpos = 0, i=0; i<nx; i++) {
				 tone = (ACOLORINDEX (i, j) );
					itone = (int) (tone * 256);
					if (itone <0) itone = 0; 
					if (itone > 255) itone = 255;
				   fprintf(pf,"%3d ", itone);
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
printf("\nColor IMAGE Postscript file %s  created. Print it!\n\n", jmf); beep();
}


