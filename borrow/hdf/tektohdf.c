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

 * Revision 3.1  90/07/02  10:11:04  clow
 * some cosmetic modifications
 * 
*/

/* This code will take Tek images from stdin and create a  HDF file.    */
/* Written by Mike Krogh, NCSA, Nov 4, 1988                             */
/* Last modified by Mike Krogh, NCSA, Mar 22, 1989                      */
/*      bug fix for the crays, change 'char c,c2' to 'int c,c2' and     */
/*      modified 'add' accordingly.                                     */

#include <stdio.h>
#include "df.h"

#define MAXBUF 4096
#define TAG 603

DF *DFP;
int CURCHR;
char BUFFER[MAXBUF];

main(argc,argv)
int argc;
char *argv[];
{

  int refno;
  int c,c2;

  if (argc < 2) {
     printf("%s,  version: 1.0   date: December 1, 1988\n",argv[0]);
     printf("Tektronix to HDF\n");
     printf("This utility will take Tek images from stdin and create ");
     printf("a HDF file.\n");
     printf("\n");
     printf("Usage: %s <hdffile>\n",argv[0]);
     printf("\n");
     exit(1);
  }

  DFP = DFopen(argv[1], DFACC_CREATE,128);
  if (!DFP) {
     fprintf(stderr,"Error opening %s (%d)\n",argv[1],DFerror);
     exit(1);
  }

  refno = 1;
  CURCHR = 0;

  if ((DFaccess(DFP, TAG, refno, "w")) == -1) {
     fprintf(stderr,"can't start HDF file, ref no. %d\n",refno);
     exit(1);
  }

  while ((c = getchar()) != EOF) {
    if (c == '\033') {
       if ((c2 = getchar()) == '\014') {
          tflush();
          refno += 1;
          if ((DFaccess(DFP, TAG, refno, "w")) == -1) {
             fprintf(stderr,"can't start HDF file, ref no. %d\n",refno);
             exit(1);
          }
        } else {
          add(c);
          if (c2 != EOF) 
             add(c2);
        }
     }
     else add(c);
  }

  tflush();
  if ((DFclose(DFP)) == -1)
     fprintf(stderr,"can't close the HDF file\n");
 
} 


add(c)
int c;
{
  if (CURCHR >= MAXBUF) 
     tflush();
  BUFFER[CURCHR] = (char)c;
  CURCHR++;
}


tflush()
{
  if ((DFwrite(DFP,BUFFER,CURCHR)) != CURCHR) {
      fprintf(stderr,"error writing to HDF file\n");
      exit(1);
  }
  CURCHR = 0;
}
