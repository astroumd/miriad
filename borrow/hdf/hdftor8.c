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
Revision 1.1.1.1  1990/09/28 21:50:12  teuben
UIUC 15-feb-2001 w/out wip and some manuals

 * Revision 3.1  90/07/02  10:11:37  clow
 * some cosmetic modifications
 * 
*/

/*
 * hdftor8.c
 * Extract images from HDF file to raster files
 */

#include "df.h"

#define TRUE		1
#define FALSE		0
#define FILENAME_MAX	256	/* maximum file name length, too long? */
#define PALETTE_SIZE	768	/* size of palette array */
#define COLOR_SIZE	256	/* size of palette color array */
                                /* COLOR_SIZE == PALETTE_SIZE / 3 */

#define INTERACTIVE	'i'	/* interactive option */
#define RASTER_FILE	'r'	/* raster filename template */
#define PALETTE_FILE	'p'	/* palette filename template */
#define VERBOSE		'v'	/* verbose option */

#define TEMPLATE_NUMBER	'#'	/* image or palette number positions */
#define TEMPLATE_XDIM	'@'	/* image x dim positions */
#define TEMPLATE_YDIM	'%'	/* image y dim positions */

#define D_RASTER_TEM	"img#.@.%" /* default raster file name template */
#define D_PALETTE_TEM	"pal#"	/*  default palette file name template */

extern int DFerror;		/* HDF error return variable */

char *newSpace(), *getTemplate();

int interactive;		/* interactive option */
int verbose;			/* verbose option */

main(argc, argv)
    int argc;
    char *argv[];
{
    int i, imageNumber, ispal;
    int32 xdim, ydim;
    char *hdfFile, *image, palette[PALETTE_SIZE];
    char *rasterTemplate = NULL, *paletteTemplate = NULL;

    if (argc < 2) {
        printf("%s,  version: 1.0   date: December 1, 1988\n",argv[0]);
    printf("\tThis utility extracts the raster-8 images and or palettes\n");
    printf("\tfrom an HDF file and stores them in two sets of files that\n");
    printf("\tcontain only images and palettes, respectively.\n\n");
        puts("Usage:");
        puts("hdftor8 hdf_file [-i] [-v] [-r image_file] [-p palette_file]");
        puts("\t-i: interactive (specify filenames interactively)");
        puts("\t-v: verbose (provide descriptive messages)");
        puts("\tImages and palettes are placed in the specified files");
        puts("\tThe names of these files may contain special characters which");
        puts("\t\twill be replaced by numbers:");
        puts("\t #\treplace with image or palette number");
        puts("\t @\treplace with x dim of image");
        puts("\t %\treplace with y dim of image");
        puts("\tIf not specified, image filename defaults to img.#.@.%");
        puts("\tIf not specified, palette filename defaults to pal.#");
        exit(1);
    }

    hdfFile = argv[1];

    for (i = 2; i < argc; i++) {
        if (*argv[i] == '-') {
            switch (argv[i][1]) {
            case INTERACTIVE :
                interactive = TRUE;
                break;
            case RASTER_FILE :
                rasterTemplate = argv[++i];
                break;
            case PALETTE_FILE :
                paletteTemplate = argv[++i];
                break;
            case VERBOSE :
                verbose = TRUE;
                break;
            default :
                printf("Illegal option: %s, skipping...\n", argv[i]);
                break;
            }
        }
        else
            printf("Illegal option: %s, skipping...\n", argv[i]);
    }

    if (!rasterTemplate && !interactive)
        rasterTemplate = D_RASTER_TEM;
    if (!paletteTemplate && !interactive)
        paletteTemplate = D_PALETTE_TEM;

    for(imageNumber = 1;!DFR8getdims(hdfFile, &xdim, &ydim, &ispal);) {
        image = newSpace(xdim * ydim);
        if (verbose) {
            if (ispal)
                printf("Getting image and palette %d.\n", imageNumber);
            else
                printf("Getting image %d.\n", imageNumber);
            printf("Image dimensions : %d * %d\n", xdim, ydim);
        }
        if (!DFR8getimage(hdfFile, image, xdim, ydim, palette)) {
            putRaster(rasterTemplate, xdim, ydim, imageNumber, image);
            if(ispal) putPalette(paletteTemplate, imageNumber, palette);
            imageNumber++;
        }
        else break;
    }

    if ((DFerror != DFE_NOMATCH) && (DFerror != DFE_NOERROR)) {
        printf("Error # %d\n", DFerror);
        exit(1);
    }
}

/*
 * putRaster
 *
 * Write the image to a raster image file.
 *
 * INPUT:
 *        template : pointer to template string
 *        xdim : x dimension of image
 *        ydim : y dimension of image
 *        imageNumber : (need I say more?)
 *        image : pointer to image array
 */
putRaster(template, xdim, ydim, imageNumber, image)
    char *template, *image;
    int32 xdim, ydim;
    int imageNumber;
{
    FILE *fd;
    char fileName[FILENAME_MAX];
    int size;

    if (!template)                /* can assume interactive (see main) */
        template = getTemplate("image", imageNumber);

    convert(template, imageNumber, xdim, ydim, fileName);

    if (verbose)
        printf("Writing into image file : %s\n",fileName);

    if ((fd = fopen(fileName, "w")) == NULL) {
        puts("Unable to open file. Exiting...");
        exit(1);
    }
    size = xdim * ydim;
    if (fwrite(image, 1, size, fd) != size) {
        puts("Unable to write to file. Exiting...");
        exit(1);
    }
    if (fclose(fd)) {
        puts("Unable to close file. Exiting...");
        exit(1);
    }
}

/*
 * putPalette
 *
 * Write palette array out to palette file.
 *
 * INPUT:
 *        template : palette filename template
 *        imageNumber : Yes, the number of the image
 *        palette : pointer to the palette array
 */
putPalette(template, imageNumber, palette)
    char *template, *palette;
    int imageNumber;
{
    int i;
    FILE *fd;
    char fileName[FILENAME_MAX], reds[COLOR_SIZE];
    char greens[COLOR_SIZE], blues[COLOR_SIZE];

    if (!template)		/* can assume interactive (see main) */
        template = getTemplate("palette", imageNumber);

    convert(template, imageNumber, (int32) 1, (int32) 768, fileName);

    if (verbose)
        printf("Writing into palette file : %s\n", fileName);

    if ((fd = fopen(fileName, "w")) == NULL) {
        puts("Unable to open file. Exiting...");
        exit(1);
    }

    for(i = 0; i < COLOR_SIZE; i++) {
        reds[i] = *palette++;
        greens[i] = *palette++;
        blues[i] = *palette++;
    }
    if (fwrite(reds, 1, COLOR_SIZE, fd) != COLOR_SIZE) {
        puts("Unable to write to file. Exiting...");
        exit(1);
    }
    if (fwrite(greens, 1, COLOR_SIZE, fd) != COLOR_SIZE) {
        puts("Unable to write to file. Exiting...");
        exit(1);
    }
    if (fwrite(blues, 1, COLOR_SIZE, fd) != COLOR_SIZE) {
        puts("Unable to write to file. Exiting...");
        exit(1);
    }
    if (fclose(fd)) {
        puts("Unable to close file. Exiting...");
        exit(1);
    }
}

/*
 * convert
 *
 * Determine the file name given the template, imageNumber, x dimension
 * and y dimension. Replaces template special characters with the
 * corresponding numbers.
 *
 * INPUT:
 *        template : file name template
 *        imageNumber :
 *        xdim : x dimension of image
 *        ydim : y dimension of image
 * OUTPUT:
 *        stringOut : the concocted file name
 */
convert(template, imageNumber, xdim, ydim, stringOut)
    char *template, *stringOut;
    int imageNumber;
    int32 xdim, ydim;
{
    char numStr[20], xStr[20], yStr[20];

    sprintf(numStr, "%1d", imageNumber);
    sprintf(xStr, "%1d", xdim);
    sprintf(yStr, "%1d", ydim);

    for(;(*template);) {
        switch (*template) {
        case TEMPLATE_NUMBER :
            fillStr(&template, &stringOut, numStr, TEMPLATE_NUMBER);
            break;
        case TEMPLATE_XDIM :
            fillStr(&template, &stringOut, xStr, TEMPLATE_XDIM);
            break;
        case TEMPLATE_YDIM :
            fillStr(&template, &stringOut, yStr, TEMPLATE_YDIM);
            break;
        default :
            *stringOut++ = *template++;
        }
    }
    *stringOut = '\0';
}

/*
 * fillStr
 *
 * Fill a string of special characters with a number string.
 * If the number string is shorter than the number of special characters
 * then the string is padded with '0' on the left. Else the number of the
 * special characters is ignored.
 *
 * INPUT:
 *        template : pointer to pointer of string template
 *        string : pointer to the number string
 *        specialChar : the special character we are replacing
 * OUTPUT:
 *        stringOut : pointer to pointer of converted string (not really)
 * BUG: Both the pointer to the template string and the pointer to the
 *        comverted string are moved to after the position of the conversion.
 */
fillStr(template, stringOut, string, specialChar)
    char **template, **stringOut, *string, specialChar;
{
    int templateLen, stringLen, i;

    for(templateLen = 1; *(++(*template)) == specialChar; templateLen++);
    stringLen = strlen(string);

    for(i = templateLen - stringLen; i > 0; i--)
        *(*stringOut)++ = '0';

    for(;(*string);) *(*stringOut)++ = *string++;
}

/*
 * newSpace
 *
 * Allocate a space with little wastage
 *
 * INPUT:
 *        size : size of space request
 * RETURN:
 *        pointer to the space allocated
 *
 * BUG: This routine can only handle one request at any time,
 *        a second call cannot be made while the space is still
 *        in use (somewhere else).
 */
char*
newSpace(size)
    int32 size;
{
    static int32 oldSize = 0;        /* must be static */
    static char *oldSpace = NULL; /* must be static */

    if (size >= oldSize) {
        if (oldSpace != NULL) free(oldSpace);
        if ((oldSpace = malloc((unsigned) size)) == NULL) {
            puts("Out of memory. Abort.");
            exit(1);
        }
        oldSize = size;
    }

    return oldSpace;
}

/*
 * getTemplate
 *
 * Ask the user for a file name template string.
 *
 * INPUT:
 *        type : a description string of the type of file,
 *                i.e. image or palette.
 *        imageNumber :
 * RETURN:
 *        pointer to template string
 * BUG: This routine can only handle one request at any time,
 *        a second call cannot be made while the template is still
 *        in use (somewhere else).
 */
char*
getTemplate(type, imageNumber)
    int imageNumber;
    char *type;
{
    static char template[FILENAME_MAX];

    printf("This is %s %d.\nWhat template would you like?\n",
           type, imageNumber);
    scanf("%s", template);
    return template;
}
