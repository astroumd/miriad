/*
 * Program:	readVarious.c
 *
 * Example:	14
 *
 * Usage:	readVarious -DTMIN <port>
 *
 * Sample:	readVarious -DTMIN :9876
 *
 * This example demonstrates how multiple data sets of varying types
 * can be read from an input port using DTMreadDataset.  The data
 * sent are two arrays, one integer and one floating point.  Each array
 * is read into a fixed size buffer until all data is read to ensure
 * maximum flexibility.
 *
 * This code is more complex than one would expect.  Since there are no
 * delimiters between differing data blocks, the *exact* number of
 * elements of each time must be read.  If the exact number is not read,
 * integer values will be stored in a floating point buffer and vice versa.
 * To get around that problme, the individual dimensions are parsed from
 * the header.  Normally, a message class function would be used to create
 * this header and then parse it, but here "sprintf/sscanf" will work.
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


#define MAXBUFSIZE 32768


main(int argc, char *argv[])
{
	int			i = 0,								/* Argument counter				*/
					dataval = 1,						/* The current data value		*/
					fdim = 0,							/* Floating point buffer dim	*/
					idim = 0,							/* Integer buffer dim			*/
					inport = DTMERROR;				/* DTM input port					*/
	char			header[DTM_MAX_HEADER];			/* DTM header						*/
	float			floatdata[MAXBUFSIZE];			/* Floating point data buffer	*/
	int			intdata[MAXBUFSIZE];				/* Integer data buffer			*/

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
	 * Read the two datasets using two DTMreadDataset calls.
	 * Don't check for errors and block until a writer is ready
	 * to send the message.  Loop for each DTMreadDataset until
	 * all of the necessary data has been read, and print out
	 * each buffer full of data as it is read.
	 *
	 * Remember that since each call to DTMreadDataset has no
	 * way of knowing the type of data ahead of time, it is
	 * important to parse the dimensions of the data from the
	 * header, and read EXACTLY that many of each type.
	 */
	DTMbeginRead(inport, header, sizeof header);

	sscanf(header, "This is the header.  Fdim: %d Idim: %d", &fdim, &idim);
	printf("Header read: '%s'\n", header);
	printf("The data dimensions are: %d and %d\n", fdim, idim);

	dataval = 1;
	DTMreadDataset(inport, floatdata, fdim, DTM_FLOAT);
	for (i = 0; i < fdim; i++, dataval++)
		printf("Floating point value %d = %f\n", dataval, floatdata[i]);

	dataval = 1;
	DTMreadDataset(inport, intdata, idim, DTM_INT);
	for (i = 0; i < idim; i++, dataval++)
		printf("Integer value %d = %d\n", dataval, intdata[i]);

	DTMendRead(inport);

	return(0);
}
