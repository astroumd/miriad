/*****************************************************************************
* 
*			  NCSA HDF version 3.10r2
*				Sept 20, 1990
*
* NCSA HDF Version 3.10r2 source code and documentation are in the public
* domain.  Specifically, we give to the public domain all rights for future
* licensing of the source code, all resale rights, and all publishing rights.
* 
* We ask, but do not require, that the following message be included in all
* derived works:
* 
* Portions developed at the National Center for Supercomputing Applications at
* the University of Illinois at Urbana-Champaign.
* 
* THE UNIVERSITY OF ILLINOIS GIVES NO WARRANTY, EXPRESSED OR IMPLIED, FOR THE
* SOFTWARE AND/OR DOCUMENTATION PROVIDED, INCLUDING, WITHOUT LIMITATION,
* WARRANTY OF MERCHANTABILITY AND WARRANTY OF FITNESS FOR A PARTICULAR PURPOSE
* 
*****************************************************************************/

#ifdef RCSID
static char RcsId[] = "@(#)$Revision$";
#endif
/*
$Header$

$Log$
Revision 1.1.1.1  1990/09/28 21:50:15  teuben
UIUC 15-feb-2001 w/out wip and some manuals

 * Revision 1.1  90/07/17  11:51:23  mfolk
 * Initial revision
 * 
*/
/* 
 *
 * This program will read in a R8 raster image from an HDF file
 * and display in on the console.  The following options are
 * supported:
 *   -help       - display help
 *   -all        - display all the raster images
 *   -pos x y    - put the window location at x,y
 *   -pause      - pause between images
 *
 * The syntax is:
 *   showr8 [-options] hdf.r8 [hdf.r8 ... ]
 *
 * NOTE: This routine is currently implemented only for SGI machines.
 *
 * Written by Mike Krogh, NCSA, May 8, 1990
 *
 */


#include <stdio.h>
#include "df.h"


/* SGI specific includes */
#include <gl.h>
#include <device.h>


/* global variables */
char MYNAME[100];  /* the name of this program */
int PAUSE=0;       /* if 1, pause between images */
int ALL=0;         /* if 1, display all of the images in a given file */
int XPOS= -1;       /* location of window on screen, user control if -1 */
int YPOS= -1;       /* location of window on screen, user control if -1 */
int WINDOW_OPEN=0; /* window is open if 1 */


main(argc,argv)
int argc;
char *argv[];
{

  int i;
  int file_no;
  int at_least_1_img_ok;
  void parse_options();
  int process_file();
  void loop_forever();

  /* put this program's name in a global variable */
  strcpy(MYNAME,argv[0]);

  if (argc < 2) {
     fprintf(stderr,"%s: error, no filename specified\n",argv[0]);
     exit(1);
  }

  parse_options(argc,argv,&file_no);

  at_least_1_img_ok = 0;
  for (i=file_no;i<argc;i++)
    if (process_file(argv[i]) == 0)
       at_least_1_img_ok = 1;

  /* loop forever */
  if (at_least_1_img_ok)
     loop_forever();

}



/***************************** help *****************************/
/***************************** help *****************************/
/***************************** help *****************************/
/***************************** help *****************************/

void help()
{

  fprintf(stderr,"This program will display a raster image(s) in a\n");
  fprintf(stderr,"window.  The images must be in HDF R8 format.\n\n");

  fprintf(stderr,"Usage: %s [-options] hdf.r8 [hdf.r8 ... ]\n",MYNAME);
  fprintf(stderr,"options:\n");
  fprintf(stderr,"       -all     - display all of the r8 images in the file\n");
  fprintf(stderr,"       -help    - display help\n");
  fprintf(stderr,"       -pause   - pause after each image\n");
  fprintf(stderr,"       -pos x y - position the window at location x,y\n");

}




/***************************** parse_options *****************************/
/***************************** parse_options *****************************/
/***************************** parse_options *****************************/
/***************************** parse_options *****************************/

void parse_options(argc,argv,file_no)
int argc;
char *argv[];
int *file_no;
{

  int i,found;
  void help();

  i=1;
  while (i<argc) {

    found = 0;

    if (!strcmp("-help",argv[i])) {
       help();   /* display help screen and exit */
       exit(0);
    }

    if (!strcmp("-pause",argv[i])) {
       PAUSE=1;  /* turn on global pause flag */
       i++;
       found = 1;  /* found an option */
    }

    if (!strcmp("-pos",argv[i])) {
       if ((i+2)>argc) {
          fprintf(stderr,"%s: error, not enough arguments\n",MYNAME);
          exit(1);
       }
       XPOS = atoi(argv[i+1]);
       YPOS = atoi(argv[i+2]);
       i+=3;
       found = 1;  /* found an option */
    }

    if (!strcmp("-all",argv[i])) {
       ALL=1;   /* display all images flag */
       i++;
       found = 1;  /* found an option */
    }

    if (!found) {   /* no more arguments */
       if (i >= argc) {
          fprintf(stderr,"%s: error, no files specified\n",MYNAME);
          exit(1);
       }
       *file_no = i;
       return;
    }

  }

  fprintf(stderr,"%s: error, no files specified\n",MYNAME);
  exit(1);

}




/***************************** process_file *****************************/
/***************************** process_file *****************************/
/***************************** process_file *****************************/
/***************************** process_file *****************************/

int process_file(filename)
char *filename;
{

  int xdim,ydim;
  int ispal;
  char *image;
  char palette[768];
  void display_r8();

  /* check if the file is an HDF file and if it contains a R8 image */

  if (DFR8getdims(filename, &xdim, &ydim, &ispal) < 0) {
     fprintf(stderr,"%s: error, %s is not an HDF file or \n",MYNAME,filename);
     fprintf(stderr,"it does not contain a R8 image\n");
     return -1;
  }

  if ((image=(char *)malloc(xdim*ydim)) == NULL) {
     fprintf(stderr,"%s: error, not enough memory\n",MYNAME);
     exit(1);
  }

  do {

     if (DFR8getimage(filename, image, xdim, ydim, palette) < 0)
        break;

     display_r8(image,xdim,ydim,ispal,palette);

  } while (ALL);

  free(image);

  return 0;

}




/* global variables for SGI screen refresh */
int XDIM,YDIM;
short *IMG;




/***************************** display_r8 *****************************/
/***************************** display_r8 *****************************/
/***************************** display_r8 *****************************/
/***************************** display_r8 *****************************/

void display_r8(image,xdim,ydim,ispal,palette)
char *image;
int xdim,ydim;
int ispal;
char *palette;
{

  short *img;
  register int j,j1,j2,k;
  register char *pp;
  register int r,g,b;
  int idev;
  short qvalue;


  if (WINDOW_OPEN == 0) {
     init_graphics(xdim,ydim);
     WINDOW_OPEN=1;
  }

  if ((img=(short *)malloc(xdim*ydim*sizeof(short))) == NULL) {
     fprintf(stderr,"%s: error, not enough memory\n",MYNAME);
     exit(1);
  }

  pp = palette;
  for (j=0; j<256; j++) {
      r = (int)(*pp++);
      g = (int)(*pp++);
      b = (int)(*pp++);
      mapcolor(j,r,g,b);  /* change the system palette */
  }

  for (j=0; j<ydim; j++) {
      j1 = (ydim-j-1)*xdim;
      j2 = j*xdim;
      for (k=0; k<xdim; k++)
          *(img+j1+k) = (short)(*(image+j2+k));
  }

  rectwrite(0,0,(xdim-1),(ydim-1),img);

  /* set up global variables for loop_forever() */
  XDIM=xdim;
  YDIM=ydim;
  IMG=img;

  if (PAUSE) {
     while(1) {
       idev=qread(&qvalue);
       if (idev==REDRAW) {
          reshapeviewport();
          rectwrite(0,0,(xdim-1),(ydim-1),img);
       }

       if (idev==KEYBD)
          break;
     }
  }

}




/***************************** loop_forever *****************************/
/***************************** loop_forever *****************************/
/***************************** loop_forever *****************************/
/***************************** loop_forever *****************************/

void loop_forever()
{

  int idev;
  short qvalue;

  qdevice(KEYBD);
  while(1) {
    /* SGI stuff to refresh the window when necessary */
    idev=qread(&qvalue);
    if (idev==REDRAW) {
       reshapeviewport();
       rectwrite(0,0,(XDIM-1),(YDIM-1),IMG);
    }

    if (idev==KEYBD)
       break;
  }

}




/***************************** init_graphics *****************************/
/***************************** init_graphics *****************************/
/***************************** init_graphics *****************************/
/***************************** init_graphics *****************************/

init_graphics(xdim,ydim)
int xdim,ydim;
{
    int gid;
    float aspect;


    if (XPOS != -1)
       prefposition(XPOS,XPOS+xdim-1,YPOS,YPOS+ydim-1);
    else
       prefsize(xdim,ydim);

    gid = winopen (MYNAME);

    shademodel(FLAT);
    multimap();
    gconfig();
    setmap(4);
    color(BLACK);
    clear();
    qdevice(REDRAW);
    if (PAUSE)
       qdevice(KEYBD);

}




