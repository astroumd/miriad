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
Revision 1.1.1.1  1990/09/28 21:50:14  teuben
UIUC 15-feb-2001 w/out wip and some manuals

 * Revision 3.5  90/07/02  10:11:30  clow
 * some cosmetic modifications
 * 
*/

/*
*  r8tohdf.c
*  Encoding of raster images in HDF files
*/

/* The intrepretation of arguments has changed a little.  A -p introduces a
   palette which will be used for subsequent images, till another -p. -i and -c
   introduce a series of images/compressed images */

#include "df.h"

char *space;
char newfn[256];
char palspace[1024],
        reds[256],
        greens[256],
        blues[256];

int32 xdim,ydim;

main(argc,argv) 
    int argc;
    char *argv[];
    {
    int i, is_pal=0;
    char *outfile;
    int image=1,compress=0;

    if (argc < 5) { 
        printf("%s,  version: 1.0   date: December 1, 1988\n",argv[0]);
    printf("   This utility converts one or more raw raster-8 images to\n");
    printf("   HDF RIS8 format and writes them to an HDF file.\n\n");
        puts("Usage:");
        printf("   %s xdim ydim outfile [-p palfile] {[-r],[-c],[-i]} imagefile\n", argv[0]);
        puts("\t\t\t\t ... [ -p palfile ]{[-r],[-c],[-i]} imagefile ..");
        puts("   -r: Store without compression (default)");
        puts("   -c: Store using RLE compression");
        puts("   -i: Store using IMCOMP compression");
        puts("       can take any number of images and palettes");
        puts("       compression, palette, apply to all subsequent images\n");
        puts("       all images are considered to be the same dimensions");
        exit(1);
    }

    xdim = atoi(argv[1]);
    ydim = atoi(argv[2]);

    if (xdim < 1 || ydim < 1) {
        puts("Must specify xdim and ydim");
        exit(1);
    }

    if (NULL == (space = malloc(xdim*ydim))) {
        puts("Not enough memory to convert image");
        exit(1);
    }

    outfile = argv[3];

    for (i=4; i<argc; i++) {
        if (*argv[i]=='-') {
            switch (argv[i][1]) {
                case 'p':               /* palette */
					is_pal=1;
                    image=0;
                    break;
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
            if (image) {
                if (compress==DFTAG_IMC && is_pal==0) {
                    printf("Illegal options.  If imcomp comression (-i) ");
                    printf("chosen, you must supply a palette.\n");
                    printf("Program aborted.\n");
                    exit(1);
                }
                imconv( outfile, argv[i], compress);
            } else {
                palconv( argv[i]);
                image = 1;
            }
        }
    }
    return(0);
}

/*
 *  palconv(file) sets the palette
 */

palconv( palfile)
char *palfile;
{
    char *p;
    FILE *fp;
    int j,ret;

    fp = fopen(palfile,"r");
    if (fp==NULL) {
        printf(" Error opening palette file %s\n", palfile);
        exit(1);
    }
    fread(reds,1,256,fp);
    fread(greens,1,256,fp);
    fread(blues,1,256,fp);
    fclose(fp);

    p = palspace;
    for (j=0; j<256; j++) {
        *p++ = reds[j];
        *p++ = greens[j];
        *p++ = blues[j];
    }

    ret = DFR8setpalette(palspace);
    if (ret < 0) {
        printf(" Error: %d, in writing palette %s\n",ret, palfile);
        exit(1);
    }
    return(0);
}


imconv( outfile, imfile, compress )
char *outfile;
char *imfile;
int compress;
{
    static int first=1;                 /* is this first image? */
    int ret;
    FILE *fp;

    if (NULL == (fp = fopen(imfile,"r"))) {
        puts("Error opening image file");
        exit(1);
    }

    if (0 >= fread(space, (int) xdim, (int) ydim, fp)) {
        puts("Cannot read image file");
        fclose(fp);
        exit(1);
    }

    if (first) {
        ret = DFR8putimage(outfile, space, xdim, ydim, compress);
        first = 0;
    }
    else
        ret = DFR8addimage(outfile, space, xdim, ydim, compress);
    if (ret < 0) {
        printf(" Error: %d, in writing image %s\n",DFerror,imfile);
        exit(1);
    }
    fclose(fp);
    return(0);
}
