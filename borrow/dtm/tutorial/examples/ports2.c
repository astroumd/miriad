/*
 * Program:		ports2.c
 *
 * Examples:	2, 10
 *
 * Usage:		ports2 -DTMIN <inport> -DTMOUT  <outport>
 *
 * Sample:		ports2 -DTMIN goofus:7788 -DTMOUT gallant:9876
 *
 * This examples demonstates how ports can be created from the command line.
 * The command line arguments "-DTMIN" and "-DTMOUT" are the arguments
 * recommended by the NCSA DTM staff to identify input and output ports.
 * However, if multiple input or output ports are desired, this convention
 * is relaxed.
 *
 * This example also demonstrates a crude level of error checking.  Should
 * the creation of a port fail, or should an argument be forgotten, an
 * error message displaying the usage of the program is printed and the
 * program is immediately aborted.  For more thorough error checking
 * see the examples that deal with errors.
 *
 * Upon successful creation of both ports, the port descriptor values are
 * printed and the program exits.
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dtm.h>


main(int argc, char *argv[])
{
	int			inport = DTMERROR,		/* Input port id							*/
					outport = DTMERROR,		/* Output port id							*/
					i = 0;						/* Argument counter						*/

	/*
	 * Check the command line for options.  These options
	 * are "-DTMIN" for input ports and "-DTMOUT" for output.
	 */
	for (i = 1; i < argc; i++) {

		if (!strcmp(argv[i], "-DTMIN"))
			inport = DTMmakeInPort(argv[++i], DTM_DEFAULT);

		else if (!strcmp(argv[i], "-DTMOUT"))
			outport = DTMmakeOutPort(argv[++i], DTM_DEFAULT);
	}


	/*
	 * Check the results for errors.  If either of the
	 * ports was given a negative value, exit the program.
	 */
	if ((inport == DTMERROR) || (outport == DTMERROR)) {
		printf("\nAn input or output port was assigned an error value.  ");
		printf("(in = %d, out = %d)\n\n", inport, outport);
		printf("Usage: %s -DTMIN <port> -DTMOUT <port>\n\n", argv[0]);
		exit(0);
	}


	/*
	 * Print the port values to show that the port
	 * descriptors are not created in sequence.
	 */
	printf("\nThe port numbers assigned were: input = %d, output = %d.\n",
				inport, outport);
	printf("Note that they are not in sequence.\n\n");

	return(0);
}
