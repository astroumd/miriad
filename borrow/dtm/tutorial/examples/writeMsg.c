/*
 * Program:	writeMsg.c
 *
 * Example:	6
 *
 * Usage:	writeMsg -DTMOUT <port>
 *
 * Sample:	writeMsg -DTMOUT goofus:9876
 *
 * This example demonstrates how data can be written to an output port
 * using the call DTMwriteMsg.  It is otherwise identical to the code
 * presented in example #.
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
	 * Initialize the data.
	 */
	for (i = 0; i < BUFSIZE; i++)
		dataset[i] = (float)i / 2.0;


	/*
	 * Write the data using calls.  Don't check for errors and
	 * block until a reader is ready to accept the message.
	 */
	DTMwriteMsg(outport, header, DTMHL(header), dataset, BUFSIZE, DTM_FLOAT);

	return(0);
}
