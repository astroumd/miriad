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
Revision 1.1.1.1  1990/09/28 21:50:10  teuben
UIUC 15-feb-2001 w/out wip and some manuals

 * Revision 3.1  90/07/02  10:11:49  clow
 * some cosmetic modifications
 * 
*/

/*
*  hdfcomp.c
*  Re-compress Raster-8 HDF file
*/

#include "df.h"

char *space;
char palette[768];
int32 xdim,ydim, ispal;

main(argc,argv) 
    int argc;
    char *argv[];
    {
    int i, ret;
    char *outfile;
    int image=1,compress=0;
    uint16 prevref, writeref=200;

    if (argc < 3) { 
        printf("%s,  version: 1.0   date: December 1, 1988\n",argv[0]);
        printf("  This utility will read in raster-8 images from an\n");
        printf("  HDF file and create a new HDF containing the\n");
        printf("  images in a compressed format.  Images will be\n");
        printf("  appended to outfile, if it exists.\n\n");
        puts("Usage:");
        puts(" hdfcomp outfile {[-c],[-r],[-i]} imagefile ...\n");
                puts("                 {[-c],[-r],[-i]} imagefile\n");
        puts("         -r: Store without compression (default)");
        puts("         -c: Store using RLE compression");
                puts("         -i: Store using IMCOMP compression");
        exit(1);
    }

    outfile = argv[1];

    for (i=2; i<argc; i++) {
        if (*argv[i]=='-') {
            switch (argv[i][1]) {
                case 'r':               /* raster */
                    image=1;
                    compress=0;
                    break;
                case 'c':               /* RLE */
                    image = 1;
                    compress = DFTAG_RLE;
                    break;
                case 'i':               /* IMCOMP */
                    image=1;
                    compress=DFTAG_IMC;
                    break;
                default:
                    printf("Illegal option: %s, skipping....\n",argv[i]);   
                    break;
            }
        }
        else { /* file name */
            while (DFR8getdims(argv[i], &xdim, &ydim, &ispal)>=0) {
                prevref = DFR8lastref();
                if (NULL == (space = malloc(xdim*ydim))) {
                    puts("Not enough memory to convert image");
                    exit(1);
                }
                if (DFR8getimage(argv[i], space, xdim, ydim, palette)<0) {
                    printf("Error reading image from file %s\n",argv[i]);
                    exit(1);
                }
                if (ispal) DFR8setpalette(palette);
                ret = DFR8writeref(outfile, writeref++);
                if (DFR8addimage(outfile, space, xdim, ydim, compress)<0) {
                    printf("Error writing image to file %s\n",outfile);
                    exit(1);
                }
                ret = DFR8readref(argv[i], prevref);
                        /* sequence past this image */
                ret = DFR8getdims(argv[i], &xdim, &ydim, &ispal);
            }
        }
    }

    return(0);
}
