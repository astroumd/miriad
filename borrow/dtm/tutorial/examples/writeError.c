/*
 * Program:	writeError.c
 *
 * Example:	18
 *
 * Usage:	writeError -DTMOUT <port>
 *
 * Sample:	writeError -DTMOUT gallant:9876
 *
 * This example is identical to Example # except that now, every
 * DTM function call is error checked and warning messages are printed
 * if an error is found.
 *
 * A sample reader must be listening on the port specified in the command
 * line if this program is to execute properly.
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dtm.h>


#define BUFSIZE 5


main(int argc, char *argv[])
{
	int			i = 0,									/* Argument counter			*/
					outport = DTMERROR;					/* DTM output port			*/
	char			*header = "This is the header";	/* DTM header					*/
	float			dataset[BUFSIZE];						/* The data buffer			*/

	/*
	 * Create the output port by parsing the command line
	 * looking for the argument "-DTMOUT".  Abort the program
	 * if no output port was created.  If an error was returned
	 * by DTMmakeOutPort, print a warning and the DTM error
	 * message and abort the program immediately.
	 */
	for (i = 1; i < argc; i++) {

		if (!strcmp(argv[i], "-DTMOUT")) {

			if ((outport = DTMmakeOutPort(argv[++i], DTM_DEFAULT)) == DTMERROR) {
				printf("There was an error in DTMmakeOutPort() for port ");
				printf("'%s'.  Port possibly in use?\n", argv[i-1]);
				printf("\t%s\n\n", DTMerrmsg(1));
				exit(0);
			}
		}
	}

	if (outport == DTMERROR) {
		fprintf(stderr, "\nUsage: %s -DTMOUT <port>\n\n", argv[0]);
		exit(0);
	}


	/*
	 * Initialize the data for sending.
	 */
	for (i = 0; i < BUFSIZE; i++)
		dataset[i] = (float)i / 2.0;


	/*
	 * Write the data checking for errors along the way.  If an
	 * error occurs, exit the program.  Usually, upon receipt of
	 * an error message, the program keeps on executing and the
	 * function assigned to make the DTM calls returns quietly.
	 */
	if (DTMbeginWrite(outport, header, DTMHL(header)) == DTMERROR) {
		printf("An error was encountered by DTMbeginWrite()\n");
		printf("\t%s\n", DTMerrmsg(1));
		exit(0);
	}

	
	if (DTMwriteDataset(outport, dataset, BUFSIZE, DTM_FLOAT) == DTMERROR) {
		printf("An error was encountered by DTMwriteDataset()\n");
		printf("\t%s\n", DTMerrmsg(1));
		exit(0);
	}

	if (DTMendWrite(outport) == DTMERROR) {
		printf("An error was encountered by DTMendWrite()\n");
		printf("\t%s\n", DTMerrmsg(1));
		exit(0);
	}

	return(0);
}
