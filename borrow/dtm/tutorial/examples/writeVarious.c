/*
 * Program:	writeVarious.c
 *
 * Example:	8
 *
 * Usage:	writeVarious -DTMOUT <port>
 *
 * Sample:	writeVarious -DTMOUT goofus:9876
 *
 * This example demonstrates how multiple data sets of varying types
 * can be written to an output port using DTMwriteDataset.  The data
 * sent are two arrays, one integer and one floating point.  Normally,
 * data sets are larger, but for simplicity's sake, this example sends
 * small ones.
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

#define FDIM 5
#define IDIM 4

static float	floatdata[FDIM] = {-1.0, -0.5, 0.0, 0.5, 1.0};
static int		intdata[IDIM] = {4049, 5349, 4125, 4137};


main(int argc, char *argv[])
{
	int			i = 0,									/* Argument counter	*/
					outport = DTMERROR;					/* DTM output port	*/
	char			header[DTM_MAX_HEADER];				/* DTM header			*/

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
	 * Write the two datasets using two DTMwriteDataset calls.
	 * Don't check for errors and block until a reader is ready
	 * to accept the message.  Remember that there is nothing to
	 * distinguish individual write data set calls of differing
	 * types.  Thus, some for of dimension or size information
	 * must be passed along so the receiving program can get the
	 * data in the correct amounts and types.
	 */
	sprintf(header, "This is the header.  Fdim: %d Idim: %d", FDIM, IDIM);
	DTMbeginWrite(outport, header, DTMHL(header));
	DTMwriteDataset(outport, floatdata, FDIM, DTM_FLOAT);
	DTMwriteDataset(outport, intdata, IDIM, DTM_INT);
	DTMendWrite(outport);

	return(0);
}
