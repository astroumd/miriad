/*
 * Program:	writeMultiple.c
 *
 * Example:	7
 *
 * Usage:	writeMultiple -DTMOUT <port>
 *
 * Sample:	writeMultiple -DTMOUT gallant:9876
 *
 * This example demonstrates how data can be written in chunks to an
 * output port using multiple calls to DTMwriteDataset.  The data sent
 * is a floating point array, with each chunk containing ten values.
 * Normally, data sets are sent in larger pieces, but for simplicity's
 * sake, this example sends a small ones.
 *
 * A sample reader must be listening on the port specified in the command
 * line if this program is to execute properly.
 *
 * No error checking is performed save a check for proper port creation.
 *
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dtm.h>


#define BUFSIZE 30


main(int argc, char *argv[])
{
	int		i = 0,									/* Argument counter				*/
				incr = 10,								/* Data block size				*/
				chunk = 1,								/* Block # sent					*/
				outport = DTMERROR;					/* DTM output port				*/
	char		*header = "This is the header";	/* DTM header						*/
	float		dataset[BUFSIZE],						/* Data buffer						*/
				*dptr = dataset;						/* Data pointer					*/


	/*
	 * Create the output port by parsing the command line
	 * looking for the argument "-DTMOUT".  Abort the program
	 * if no output port was created.
	 */
	for (i = 1; i < argc; i++)
		if (!strcmp(argv[i], "-DTMOUT"))
			outport = DTMmakeOutPort(argv[++i], DTM_DEFAULT);

	if (outport == DTMERROR) {
		fprintf(stderr, "\nUsage: %s -DTMOUT <port>\n\n", argv[0]);
		exit(0);
	}


	/*
	 * Initialize the data to some arbitrary values.
	 */
	for (i = 0; i < BUFSIZE; i++)
		dataset[i] = (float)i / 2.0;


	/*
	 * Write the data using multiple DTMwriteDataset calls.  Don't
	 * check for errors and block until a reader is ready to accept
	 * the message.  The loop that writes the data is designed to
	 * always write the correct number of items (BUFSIZE is a multiple
	 * of incr).  Normally, a final call to writeDatset would be
	 * needed to flush the rest of the buffer.  It is not present
	 * here for simplicity.
	 */
	DTMbeginWrite(outport, header, DTMHL(header));
	for (dptr = dataset; dptr < dataset+BUFSIZE; dptr += incr) {
		printf("Writing block #%d of size %d\n", chunk++, incr);
		DTMwriteDataset(outport, dptr, incr, DTM_FLOAT);
	}
	DTMendWrite(outport);

	return(0);
}
