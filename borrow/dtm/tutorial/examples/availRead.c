/*
 * Program:	availRead.c
 *
 * Example:	15
 *
 * Usage:	availRead -DTMIN <port>
 *
 * Sample:	availRead -DTMIN :9876
 *
 * availRead demonstrates how a program can poll a port for input.  If no
 * input is ready to be received, then the program can continue processing
 * other information.  If input is ready to be received, read the header
 * and print it out, ignoring any data that might be waiting.
 *
 * availRead only checks the input port creation for errors.  All other
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
					inport = DTMERROR;					/* The input port				*/
	char			header[DTM_MAX_HEADER];				/* The message header		*/

	/*
	 * Parse the command line for the option "-DTMIN".  If the
	 * option is not present, print an error and exit.  If an error
	 * occurrs opening the port, print the error message and exit.
	 */
	for (i = 1; i < argc; i++) {
		if (!strcmp(argv[i], "-DTMIN")) {
			if ((inport = DTMmakeInPort(argv[++i], DTM_DEFAULT)) == DTMERROR) {
				fprintf(stderr, "Error in opening port '%s'.  ", argv[i-1]);
				fprintf(stderr, "Port in use?\n\t%s\n", DTMerrmsg(1));
				exit(0);
			}
		}
	}

	if (inport == DTMERROR) {
		fprintf(stderr, "\nUsage: %s -DTMIN <port>\n\n", argv[0]);
		exit(0);
	}


	/*
	 * This is the main program loop.  It will loop infinitely or
	 * until the message has been successfully written.  A message
	 * is printed to stdout so that the user is aware that other
	 * processing can take place while waiting for the port to
	 * become free.
	 *
	 * No error checking is performed on either the DTMavailRead
	 * or the reading code.
	 */

	while(!DTMavailRead(inport))
		printf("Do something useful for iteration #%d.\n", iteration++);

	DTMbeginRead(inport, header, sizeof header);
	DTMendRead(inport);

	printf("The header received was: '%s'\n", header);

	return(0);
}
