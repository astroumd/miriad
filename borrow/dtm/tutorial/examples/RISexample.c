/*
 * Program:	RISexample.c
 *
 * Example:	24, 25
 *
 * Usage:	RISexample -DTMIN <port>
 *							-or-
 *				RISexample -DTMOUT <port>
 *
 * Sample:	RISexample -DTMIN :7788
 *						-or-
 *				RISexample -DTMOUT gallant:7788
 *
 * This program is by far the most complex of all of the examples.
 * RISexample attempts to both read and write a palatte and an image.
 * The image sent is always an 8-bit image, though the reading portion
 * is set up to read 24-bit images as well.
 *
 * This program demonstrates how to use the raster image set (RIS) and
 * palette (PAL) classes.  It also demonstrates how to determine if a
 * message received is an RIS class or PAL class message, and how to parse
 * the header to get the needed information, also using the predefined
 * RIS and PAL class macros.
 *
 * All error checking is performed, and an error value is returned whenever
 * an error is encountered with the exception of when creating the ports.
 * In that case the program exits.
 *
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dtm.h>
#include <ris.h>




/***************************************************************************
 *																									*
 * Reading Palettes and Raster Images													*
 * In this section, a palette is read from the given input port as well		*
 * an 8-bit image or a 24-bit image.  The image is determined by parsing	*
 * the header.																					*
 *																									*
 ***************************************************************************/

/*
 * printImage:
 * Print the image as a list of integers that are offsets into the
 * colormap.
 */
static void printImage(char *header, char *title, char *image,
								int xdim, int ydim, RISTYPE imagetype)
{
	int			i = 0;

	printf("\nThe header read was from an RIS message: '%s'\n", header);
	printf("The title of this image is '%s'\n", title);
	printf("Dimensions: %d x %d\n", xdim, ydim);

	if (imagetype == RIS8BIT) {
		printf("The 8-bit image:\n");
		for (i = 0; i < xdim*ydim; i++)
			printf("%c%4d", ((i%15 == 0) ? '\n' : ' '), image[i]);
	}
	else {
		printf("The 24-bit image:");
		for (i = 0; i < 3*xdim*ydim; i+=3)
			printf("%c0x%02x%02x%02x", ((i%9 == 0) ? '\n' : ' '),
												image[i], image[i+1], image[i+2]);
	}
	printf("\n");

}



/*
 * readRIS:
 * read the Raster Image from the given port based on the information
 * contained in the header.
 */
static int readRIS(int inport, char *header)
{
	int		size = 0,						/* Size of the array in floats		*/
				count = 0,						/* Number of chars read					*/
				xdim = 0,						/* X dimension of the image			*/
				ydim = 0;						/* Y dimension of the image			*/
	char		title[80],						/* Title of this message				*/
				*image = NULL;					/* Image received							*/
	RISTYPE	type = RIS8BIT;				/* Default type is RIS8BIT				*/


	/*
	 * Get the image information from the header.  Allocate space for
	 * the image based on the image type.  Read the data from the port,
	 * reporting errors, and print out the image values.
	 */
	RISgetDimensions(header, &xdim, &ydim);
	RISgetTitle(header, title, sizeof title);
	RISgetType(header, &type);
	size = xdim * ydim * ((type == RIS24BIT) ? 3 : 1);
	image = (char *)malloc(size * sizeof(char));

	/*
	 * Read the image and print out only the number of items read.
	 */
	if ((count = DTMreadDataset(inport, image, size, DTM_CHAR)) == DTMERROR) {
		printf("Error in readRIS() function DTMreadDataset()\n");
		printf("\t%s\n", DTMerrmsg(1));
		return(DTMERROR);
	}

	if (count != size) {
		printf("The number of image bytes read (%d) ", count);
		printf("does not equal the number expected (%d)\n", size);
	}
	else
		printImage(header, title, image, xdim, ydim, type);

	return(DTM_OK);

}



/*
 * printPalette:
 * Print out the palette in hexidecimal format.
 */
static void printPalette(char *header, char *title, char *palette, int elements)
{
	int			i;

	printf("The header read was from a PAL message: '%s'\n", header);
	printf("The title of this palette is '%s'\n", title);
	printf("The number of elements in the palette is %d\n", elements);

	printf("The palette entries are:\n");
	for (i = 0; i < elements*3; i+=3)
		printf("%c%4d:(%3d %3d %3d)", ((i%12) ? ' ' : '\n'),
							(i/3+1), palette[i], palette[i+1], palette[i+2]);
	printf("\n");

}



/*
 * readPAL:
 * Read the palette from the given port based on information contained
 * in the header.  Print out the palette entries.
 */
static int readPAL(int inport, char *header)
{
	int		elements = 0,					/* Number of colormap entries			*/
				count = 0,						/* The number of elements read		*/
				size = 0;						/* 3 * elements (RGB)					*/
	char		title[80],						/* Title of this message				*/
				*palette = NULL;				/* The palette to be read				*/

	/*
	 * Get the information from the header.  Allocate space for the
	 * palette and read it from the input port.  If the call to
	 * DTMreadDataset returns an error, abort the read.
	 */
	PALgetTitle(header, title, sizeof title);
	PALgetSize(header, &elements);
	size = 3*elements;
	palette = (char *)malloc(size * sizeof(char));

	if ((count=DTMreadDataset(inport,palette,size,DTM_CHAR)) == DTMERROR) {
		printf("There was an error in readPAL() function DTMreadDataset()\n");
		printf("\t%s\n", DTMerrmsg(1));
		return(DTMERROR);
	}

	if (count != size) {
		printf("The number of palette bytes read (%d) ", count);
		printf("does not equal the number expected (%d)\n", size);
	}
	else
		printPalette(header, title, palette, elements);

	return(DTM_OK);

} /* readPAL */



/*
 * readMessage:
 * Read a message from the given port.  Determine which port the message
 * came from and call the appropriate function for reading that message.
 * This function returns DTM_OK if no errors occurred.
 */
static int readMessage(int inport)
{
	char		header[DTM_MAX_HEADER];		/* DTM header to be received			*/

	/*
	 * Begin reading.  Check for errors and return immediately if one
	 * has occurred.
	 */
	if (DTMbeginRead(inport, header, sizeof header) == DTMERROR) {
		printf("Error in DTMbeginRead()\n");
		printf("\t%s\n", DTMerrmsg(1));
		return(DTMERROR);
	}


	/*
	 * Read the message based upon the class of the message.
	 */
	if (RIScompareClass(header))
		readRIS(inport, header);

	else if (PALcompareClass(header))
		readPAL(inport, header);


	/*
	 * End reading.  Report any errors.
	 */
	if (DTMendRead(inport) == DTMERROR) {
		printf("Error in DTMendRead()\n");
		printf("\t%s\n", DTMerrmsg(1));
		return(DTMERROR);
	}

	return(DTM_OK);

} /* readMessage */





/***************************************************************************
 *																									*
 * Writing Palettes and Raster Images													*
 * In this section, a 256 entry palette is written to the given ouput		*
 * port as well as either a 8-bit image or a 24-bit image.  The image		*
 * type was parsed from the command line.												*
 *																									*
 ***************************************************************************/

/*
 * writeRIS:
 * Create an RISclass message using the RISset* macros and attempt to write
 * that message across the given port.  If an error is encountered during
 * the write, report it and return the value DTMERROR.  Otherwise, print a
 * message of success and return a value of DTM_OK.  The raster image is
 * a simple 8-bit grayscale image.
 */
static int writeRIS(int outport)
{
	int		i = 0,							/* Loop variable							*/
				xdim = 256,						/* X dimension of the image			*/
				ydim = 256,						/* Y dimension of the image			*/
				size = xdim * ydim;			/* Size of the array						*/
	char		header[RISsize],				/* SDS header								*/
				*image = NULL,					/* Raster image							*/
				*iptr = NULL;					/* Used for copying the image			*/

	/*
	 * Initialize the example image.  The image in this case is an
	 * image with the lowest colormap entries on the left, the highest
	 * on the right.
	 */
	size = xdim * ydim;
	image = (char *)malloc(size * sizeof(char));
	for (iptr = image, i = 0; i < xdim; iptr++, i++)
		*iptr = i;
	for ( ; iptr < image + size; iptr+=xdim)
		memcpy(iptr, image, xdim*sizeof(char));


	/*
	 * Set up the RIS message header using the RISclass macros.  The
	 * type will depend upon the value specified on the command line.
	 */
	RISsetClass(header);
	RISsetDimensions(header, xdim, ydim);
	RISsetTitle(header, "This is an RIS image");
	RISsetType(header, RIS8BIT);


	/*
	 * Attempt to send the header and image at the same time.  This
	 * practice is recommended whenever the data is contained
	 * within a single buffer.
	 */
	if (DTMwriteMsg(outport, header, RISHL(header), image, size, DTM_CHAR) 
				== DTMERROR) {
		printf("Error in writeRIS() function DTMwriteMsg()\n");
		printf("\t%s\n", DTMerrmsg(1));
		return(DTMERROR);
	}
	printf("Write of RIS was successful.\n");

	return(DTM_OK);

}




/*
 * writePAL:
 * Write a palette to the given output port.  The palette is a 256
 * element grayscale palette.
 */
static int writePAL(int outport)
{
	int		i = 0,							/* Loop variable							*/
				elements = 768;				/* Number of elements in palette		*/
	char		header[PALsize],				/* PAL header								*/
				*palette = NULL;				/* The palette								*/

	/*
	 * Create a sample grayscale palette.
	 */
	palette = (char *)malloc(elements * sizeof(char));
	for (i = 0; i < elements; i+=3)
		palette[i] = palette[i+1] = palette[i+2] = i/3;


	/*
	 * Set up the necessary information about how to interpret the
	 * palette data.  Even though 256 elements is the default, it's
	 * still good to set it explicitly in the header.
	 */
	PALsetClass(header);
	PALsetSize(header, elements/3);
	PALsetTitle(header, "This is a grayscale palette");


	/*
	 * Attempt to send the header and data at the same time.  This
	 * practice is recommended whenever the data is contained
	 * within a single buffer.
	 */
	if (DTMwriteMsg(outport, header, PALHL(header), palette, elements, DTM_CHAR) 
				== DTMERROR) {
		printf("Error in DTMwriteMsg()\n");
		printf("\t%s\n", DTMerrmsg(1));
		return(DTMERROR);
	}
	printf("Write of PAL was successful.\n");

	return(DTM_OK);

}



main(int argc, char *argv[])
{
	int			inport = DTMERROR,				/* DTM input port					*/
					outport = DTMERROR,				/* DTM output port				*/
					i = 0;								/* Argument counter				*/

	/*
	 * Create the requested port and do the ususal error
	 * checking.  If no ports are requested, report an
	 * error and exit.
	 */
	for (i = 1; i < argc; i++) {

		if (!strcmp(argv[i], "-DTMOUT")) {
			if ((outport = DTMmakeOutPort(argv[++i], DTM_DEFAULT)) == DTMERROR) {
				printf("Error in DTMmakeOutPort().  Port %s in use?\n", argv[i-1]);
				printf("\t%s\n", DTMerrmsg(1));
				exit(0);
			}
		}

		else if (!strcmp(argv[i], "-DTMIN")) {
			if ((inport = DTMmakeInPort(argv[++i], DTM_DEFAULT)) == DTMERROR) {
				printf("Error in DTMmakeInPort().  Port %s in use?\n", argv[i-1]);
				printf("\t%s\n", DTMerrmsg(1));
				exit(0);
			}
		}
	}

	if ((outport == DTMERROR) && (inport == DTMERROR)) {
		printf("\nUsage:\t%s -DTMOUT <port>\n", argv[0]);
		printf("Or:\t%s -DTMIN <port>\n\n", argv[0]);
		exit(0);
	}


	/*
	 * If an input port is requested, attempt to read two
	 * messages from that port, otherwise attempt to write
	 * both a palette and an 8-bit image from the port.
	 */
	if (inport != DTMERROR) {
		readMessage(inport);
		readMessage(inport);
	}

	else {
		writePAL(outport);
		writeRIS(outport);
	}

	return(0);
}
