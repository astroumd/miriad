/*
 * Program:	availWrite.c
 *
 * Example:	9
 *
 * Usage:	availWrite -DTMIN <port>
 *
 * Sample:	availWrite -DTMIN :9876
 *
 * availWrite demonstrates how a program can poll a port for output.  If no
 * port is free to send data, then the program can continue processing
 * other information.  If a port is ready to transmit, write the header.
 *
 * availWrite only checks the output port creation for errors.  All other
 * errors are ignored completely.
 * 
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dtm.h>


main(int argc, char *argv[])
{
	int			i = 0,									/* Argument counter			*/
					iteration = 1,							/* Main loop counter			*/
					outport = DTMERROR;					/* The output port			*/
	char			*header = "This is the header";	/* The message header		*/

	/*
	 * Parse the command line for the option "-DTMOUT".  If the
	 * option is not present, print an error and exit.  If an error
	 * occurrs opening the port, print the error message and exit.
	 */
	for (i = 1; i < argc; i++) {
		if (!strcmp(argv[i], "-DTMOUT")) {
			if ((outport = DTMmakeOutPort(argv[++i], DTM_DEFAULT)) == DTMERROR) {
				fprintf(stderr, "Error in opening port '%s'.  ", argv[i-1]);
				fprintf(stderr, "Port in use?\n\t%s\n", DTMerrmsg(1));
				exit(0);
			}
		}
	}

	if (outport == -1) {
		fprintf(stderr, "\nUsage: %s -DTMOUT <port>\n\n", argv[0]);
		exit(0);
	}


	/*
	 * This is the main program loop.  It will loop infinitely or
	 * until the message has been successfully written.  A message
	 * is printed to stdout so that the user is aware that other
	 * processing can take place while waiting for the port to
	 * become free.
	 *
	 * No error checking is performed on either the DTMavailWrite
	 * or the DTMwriteMsg.  Note that DTMwriteMsg can write NULL
	 * datasets if desired.
	 */
	while (!DTMavailWrite(outport))
		printf("Do something useful for iteration #%d.\n", iteration++);

	DTMwriteMsg(outport, header, DTMHL(header), NULL, 0, DTM_CHAR);

	return(0);
}
