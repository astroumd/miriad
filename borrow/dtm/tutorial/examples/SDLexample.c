/*
 * Program:	SDLexample.c
 * 
 * Example:	28
 *
 * Usage:	SDLexample -DTMIN <port>
 *							-or-
 *				SDLexample -DTMOUT <port>
 *
 * Sample:	SDLexample -DTMIN :7788
 *						-or-
 *				SDLexample -DTMOUT goofus:7788
 *
 * This example serves a dual purpose: both the reading and writing programs
 * are contained within one source file.  To execute the reading program,
 * specify only an input port on the command line.  To execute the writing
 * program, specify an output port on the command line.
 *
 * This program demonstrates how to create an surface description language 
 * (SDL) class message using the predefined creation macros.  It also
 * demonstrates how to determine if a message received is of the SDL message
 * class and how to parse the header to get the needed information, also
 * using the predefined SDLclass macros.
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
#include <sdl.h>


#define TBUF	100


/***************************************************************************
 *																									*
 * Functions for reading SDL messages:													*
 * The following section contains code for reading an SDL message, parsing	*
 * the header, and printing out the received triplet values.					*
 *																									*
 ***************************************************************************/

/*
 * printTriplets:
 * Print nelem triplet values displaying their SDLtag values and floating
 * point triplet values.
 */
static void printTriplets(struct DTM_TRIPLET *triplets, int nelem)
{
	int			i = 0;

	for (i = 0; i < nelem; i++) {
		switch(triplets[i].tag) {
			case SDLposition:	printf("SDLposition: ");
									break;
			case SDLcolor:	printf("SDLcolor: ");
								break;
			case SDLnormal:	printf("SDLnormal: ");
									break;
			case SDLtranslate:	printf("SDLtranslate: ");
										break;
			case SDLrotate:	printf("SDLrotate: ");
									break;
			case SDLscale:	printf("SDLscale: ");
								break;
		}
		printf("(%f, %f, %f)\n", triplets[i].x, triplets[i].y, triplets[i].z);
	}
	printf("\n");

} /* printTriplets */



/*
 * readSDL:
 * Attempt to read a header from the supplied port.  If the header is
 * a SDLclass message, print the associated data in a format that is
 * understandable.  If the message is of some other class, print an
 * error message.
 */
static int readSDL(int inport)
{
	char			header[SDLsize],				/* The header character string	*/
					title[SDLsize];				/* The title read						*/
	int			nelem = 0;						/* Number of elements read			*/
	struct DTM_TRIPLET	triplets[TBUF];	/* Triplet data buffer				*/
	SDLprim_t	primitive;						/* The primitive type				*/

	if (DTMbeginRead(inport, header, sizeof header) == DTMERROR) {
		printf("An error was encountered in DTMbeginRead()\n");
		printf("\t%s\n", DTMerrmsg(1));
		return(DTMERROR);
	}

	printf("\nThe header read was: '%s'\n", header);

	/*
	 * If the message is of class SDL, get the title and
	 * primitive type.  Then print out the title and type.
	 */
	if (SDLcompareClass(header)) {
		SDLgetTitle(header, title, sizeof title);
		SDLgetPrimitive(header, &primitive);

		printf("The message is a SDLclass message.\n");
		printf("The title is: '%s'\n", title);
		printf("Primitive type: ");
		switch(primitive) {
			case SDLpoint:	printf("SDLpoint\n");
								break;
			case SDLlineseg:	printf("SDLlineseg\n");
									break;
			case SDLtriangle:	printf("SDLtriangle\n");
									break;
			case SDLquad:	printf("SDLquad\n");
								break;
			case SDLsphere:	printf("SDLsphere\n");
									break;
		}

		/*
		 * Read the data in chunks of TBUF triplets at a time.
		 * Print the resulting data type for each triplet.
		 */
		while ((nelem = DTMreadDataset(inport, triplets, TBUF, DTM_TRIPLET)) > 0)
			printTriplets(triplets, nelem);

		if (nelem == DTMERROR) {
			printf("An error was encountered in DTMreadDataset()\n");
			printf("\t%s\n", DTMerrmsg(1));
			return(DTMERROR);
		}
	}

	else
		printf("The message is not a SDLclass message: ignoring the data.\n");

	if (DTMendRead(inport) == DTMERROR) {
		printf("An error was encountered in DTMendRead()\n");
		printf("\t%s\n", DTMerrmsg(1));
		return(DTMERROR);
	}

	return(DTM_OK);

}





/***************************************************************************
 *																									*
 * Functions for writing SDL messages:													*
 * The following section contains code for writing an SDL message				*
 * and creating the header.																*
 *																									*
 ***************************************************************************/

#define NTRIS	9
static struct DTM_TRIPLET triangle[NTRIS] = {{SDLcolor, 1.0, 0.0, 0.0},
															{SDLnormal, 0.0, 0.0, 1.0},
															{SDLposition, 0.0, 0.0, 1.0},
															{SDLcolor, 0.0, 1.0, 0.0},
															{SDLnormal, 1.0, 0.0, 0.0},
															{SDLposition, 1.0, 0.0, 0.0},
															{SDLcolor, 0.0, 0.0, 1.0},
															{SDLnormal, 0.0, 1.0, 0.0},
															{SDLposition, 0.0, 1.0, 0.0} };



/*
 * writeSDL:
 * Create an SDLclass message using the SDLset* macros and attempt to write
 * that message across the given port.  If an error is encountered during
 * the write, report it and return the value DTMERROR.  Otherwise, print a
 * message of success and return a value of DTM_OK.  The data written is
 * a triangle with three colors (red, green, and blue) and with three
 * normals, one of each at each vertex.
 */
static int writeSDL(int outport)
{
	char			header[SDLsize];

	SDLsetClass(header);
	SDLsetTitle(header, "Example X.Y: A Triangle");
	SDLsetPrimitive(header, SDLtriangle);

	if (DTMwriteMsg(outport, header, SDLHL(header), triangle, NTRIS, DTM_TRIPLET)
				== DTMERROR) {
		printf("Error in DTMwriteMsg()\n");
		printf("\t%s\n", DTMerrmsg(1));
		return(DTMERROR);
	}

	printf("SDL message written successfully.\n");
	return(DTM_OK);

} /* writeSDL */





/*
 * main:
 * create either an input or an output port (but not both) and attempts
 * to either read or write based on the type of port specified.
 */
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
	 * If an input port is requested, read a message from
	 * that port, otherwise attempt to write a message from
	 * the port.
	 */
	if (inport != DTMERROR)	
		readSDL(inport);

	else writeSDL(outport);

	return(0);
}
