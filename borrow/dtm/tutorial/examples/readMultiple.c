/*
 * Program:	readMultiple.c
 *
 * Example:	13
 *
 * Usage:	readMultiple -DTMIN <port>
 *
 * Sample:	readMultiple -DTMIN :9876
 *
 * This example demonstrates how data can be read in chunks from an
 * input port using multiple calls to DTMreadDataset.  The data read
 * is a floating point array, with each chunk containing five values.
 * Normally, data sets are read in larger pieces, but for simplicity's
 * sake this example reads small ones.
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


#define MAXBUFSIZE 5									/* Maximum buffer size			*/


main(int argc, char *argv[])
{
	int		i = 0,									/* Argument counter				*/
				nelem = 0,								/* Number of elements read		*/
				datanum = 0,							/* Data block size				*/
				chunk = 1,								/* Block # of data read			*/
				inport = DTMERROR;					/* DTM output port				*/
	char		header[DTM_MAX_HEADER];				/* DTM header						*/
	float		dataset[MAXBUFSIZE];					/* Data set buffer				*/


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
	 * Read the data using multiple DTMreadDataset calls.  Don't
	 * check for errors and block until the writer is ready to send 
	 * the message.  The loop that read the data is designed to
	 * read the data in MAXBUFSIZE sized chunks, *independent of the
	 * block size used to write the data*, and will print out the
	 * values received to demonstrate that the data was properly received.
	 */
	DTMbeginRead(inport, header, sizeof header);
	while ((nelem = DTMreadDataset(inport,dataset,MAXBUFSIZE,DTM_FLOAT)) > 0) {
		printf("\nRead chunk #%d of size %d\n", chunk++, MAXBUFSIZE);
		for (i = 0; i < nelem; i++, datanum++)
			printf("Data value %d = %f\n", datanum, dataset[i]);
	}
	DTMendRead(inport);

	return(0);
}
