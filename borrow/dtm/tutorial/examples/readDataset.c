/*
 * Program:	readDataset.c
 *
 * Example:	12
 *
 * Usage:	readDataset -DTMIN <port>
 *
 * Sample:	readDataset -DTMIN :9876
 *
 * This example demonstrates how data can be read from an input port
 * using the calls DTMbeingRead, DTMreadDataset and DTMendRead.  The
 * data is received in a single buffer.  Data will be discarded if
 * the buffer is not big enough to hold all of it at once.  For
 * demonstrating this, the buffer size was chosen to be unusually
 * small.  Normally the buffers are larger to make data transfer
 * more efficient.
 *
 * A sample writer must be sending to the port specified in the command
 * line if this program is to execute properly.
 *
 * No error checking is performed save a check for proper port creation.
 *
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dtm.h>


#define MAXBUFSIZE 5


main(int argc, char *argv[])
{
	int			i = 0,								/* Argument counter				*/
					nelem = 0,							/* Number of elements read		*/
					inport = DTMERROR;				/* DTM input port					*/
	char			header[DTM_MAX_HEADER];			/* DTM header						*/
	float			dataset[MAXBUFSIZE];				/* Data buffer						*/


	/*
	 * Create the input port by parsing the command line
	 * looking for the argument "-DTMIN".  Abort the program
	 * if no input port was created.
	 */
	for (i = 1; i < argc; i++)
		if (!strcmp(argv[i], "-DTMIN"))
			inport = DTMmakeInPort(argv[++i], DTM_DEFAULT);

	if (inport == DTMERROR) {
		fprintf(stderr, "\nUsage: %s -DTMIN <port>\n\n", argv[0]);
		exit(0);
	}


	/*
	 * Read the data using a single call to DTMreadDataset.
	 * Don't check for errors and block until a writer is ready
	 * to send the message.
	 */
	DTMbeginRead(inport, header, sizeof header);
	nelem = DTMreadDataset(inport, dataset, MAXBUFSIZE, DTM_FLOAT);
	DTMendRead(inport);


	/*
	 * Print the number of floating point values read.  Note that
	 * it is possible to have lost some data if the number waiting
	 * to be received was greater than MAXBUFSIZE.
	 */
	printf("\nThe header read was: '%s'\n", header);
	for (i = 0; i < nelem; i++)
		printf("Floating point value %d = %f\n", i, dataset[i]);

	return(0);
}
