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
Revision 1.1  1990/09/28 21:50:13  teuben
Initial revision

 * Revision 3.1  90/07/02  10:11:34  clow
 * some cosmetic modifications
 * 
*/


/* This code will read in a HDF file and display any Tek images on the  */
/* screen.  It assumes that the output is being routed to a tek emulator*/
/* Written by Mike Krogh, NCSA, Nov 3, 1988                             */
/* Last modified by Mike Krogh, NCSA, Mar 22, 1989                      */
/* Added a pause option.                                                */

#include <stdio.h>
#include "df.h"

main(argc,argv)
int argc;
char *argv[];
{

  DF *df;
  DFdesc ddstr;

  int list, fstart, fend, fincr, nclear;
  int i,j,startpic,good,pause;
  char junkstr[80];

  if (argc < 2) {
     printf("%s,  version: 1.0   date: December 1, 1988\n",argv[0]);
     printf("HDF to Tektronix\n");
     printf("This utility will send the vector data from the HDF");
     printf(" file to stdout.\n");
     printf("\n");
     printf("Usage: %s [-options] <hdffile>\n",argv[0]);
     printf("        -nc no clear screen between frames\n");
     printf("        -fs frame_start\n");
     printf("        -fe frame_end\n");
     printf("        -fi frame_increment\n");
     printf("        -l  list of vector contents in hdffile\n");
     printf("        -p  pause between frames\n");
     printf("\n");
     exit(1);
  }

  /* scan for options */
  list = 0;  fstart = -1;  fend = -1;  fincr = 1;  nclear = 0;
  startpic = 1;  pause = 0;

  for (i=1; i<argc; i++) {
    if (*argv[i] == '-') {
       good = 0;
       if (!strcmp(argv[i],"-l")) {
          list = 1;
          startpic++;
          good = 1;
       }
       if (!strcmp(argv[i],"-p")) {
          pause = 1;
          startpic++;
          good = 1;
       }
       if (!strcmp(argv[i],"-nc")) {
          nclear = 1;
          startpic++;
          good = 1;
       }
       if (!strcmp(argv[i],"-fs")) {
          fstart = atoi(argv[i+1]);
          i++;
          startpic+=2;
          good = 1;
       }
       if (!strcmp(argv[i],"-fe")) {
          fend = atoi(argv[i+1]);
          i++;
          startpic+=2;
          good = 1;
       }
       if (!strcmp(argv[i],"-fi")) {
          fincr = atoi(argv[i+1]);
          i++;
          startpic+=2;
          good = 1;
       }
       if (good == 0) {
          fprintf(stderr,"Invalid option %s\n",argv[i]);
          exit(1);
       }
    }
  }

  if (startpic >= argc) {
     fprintf(stderr,"Not enough arguments\n");
     exit(1);
  }

  df = DFopen(argv[startpic], DFACC_READ,DF_DEFAULTDDS);
  if (!df) {
     if (DFerror==DFE_NOTDFFILE)
        fprintf(stderr,"Not an HDF file - %s\n",argv[startpic]);
     else
        fprintf(stderr,"Error opening %s (%d)\n",argv[startpic],DFerror);
     exit(1);
  }

  DFsetfind(df, 603, DFREF_WILDCARD);

  if (list == 1) {
     printf("Listing of HDF Vector Tags\n");
     printf("Ref. No.            Length\n");
     while (DFfind(df,&ddstr) >= 0)
       printf(" %4d                %d\n",ddstr.ref,ddstr.length);
  }
  else {
     if ((fstart == -1) && (fend == -1)) {
        while (DFfind(df, &ddstr)>=0) {
          display(df, ddstr, nclear);
          if (pause == 1)
             fgets(junkstr,80,stdin);
        }
     }
     if ((fstart != -1) && (fend != -1)) 
        for (i=fstart;i<=fend;i+=fincr) {
          DFsetfind(df, 603, i);
          if (DFfind(df, &ddstr)>=0) {
             display(df, ddstr, nclear);
             if (pause == 1)
                fgets(junkstr,80,stdin);
          }
        }
     if ((fstart != -1) && (fend == -1)) {
        i = fstart;
        DFsetfind(df, 603, i);
        while (DFfind(df, &ddstr)>=0) {
          display(df, ddstr, nclear);
          if (pause == 1)
             fgets(junkstr,80,stdin);
          i+=fincr;
          DFsetfind(df, 603, i);
        }
     }
     if ((fstart == -1) && (fend != -1)) 
        for (i=1;i<=fend;i+=fincr) {
          DFsetfind(df, 603, i);
          if (DFfind(df, &ddstr)>=0) {
             display(df, ddstr, nclear);
             if (pause == 1)
                fgets(junkstr,80,stdin);
          }
        }
  }

  DFclose(df);
}


display(df,ddstr,nclear)
DF *df;
DFdesc ddstr;
int nclear;
{
  unsigned char *data;

  if ((data = (unsigned char *) malloc(ddstr.length)) == NULL) { 
     fprintf(stderr,"Error, not enough memory\n"); 
     exit(1);
  } 
  if (DFgetelement( df, ddstr.tag, ddstr.ref, data)<0) { 
     fprintf(stderr,"Error reading element. (%d)\n", DFerror); 
     exit(1); 
  } 
  if (nclear == 0)
     printf("\033\014\n");
  fwrite(data,ddstr.length,1,stdout); 
  fflush(stdout); 
  free(data); 
} 
