/*
 * Program:	MSGexample.c
 *
 * Example:	21
 *
 * Usage:	MSGexample -DTMIN <port>
 *							-or-
 *				MSGexample -DTMOUT <port>
 *
 * Sample:	MSGexample -DTMIN :7788
 *						-or-
 *				MSGexample -DTMOUT gallant:7788
 *
 * This example serves a dual purpose: both the reading and writing programs
 * are contained within one source file.  To execute the reading program,
 * specify an input port only on the command line.  To execute the writing
 * program, specify an output port on the command line.
 *
 * This program demonstrates how to create a simple message of a particular
 * class - MSG - using that message class' creation macros.  It also
 * demonstrates how to determine if a message received is a message of class
 * MSG and how to parse the header to get the needed information, all
 * using the predefined MSGclass macros.
 *
 * All error checking is performed, and an error value is returned whenever
 * an error is encountered with the exception of when creating the ports.
 * In that case the program exits.
 *
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dtm.h>



/***************************************************************************
 *																									*
 * READING MSG CLASS MESSAGES:															*
 * This section of code contains examples of how one can read MSG class		*
 * messages and parse the headers.														*
 *																									*
 ***************************************************************************/

/*
 * readMSG:
 * Attempt to read a header from the supplied port.  Ignore any data that
 * may be associated with that header since MSGclass messages don't have
 * data.  If the header is a MSGclass message, print the associated string.
 * If the message is of some other class, print an error message.
 */
static int readMSG(int inport)
{
	char			header[DTM_MAX_HEADER],
					string[DTM_MAX_HEADER];

	if (DTMbeginRead(inport, header, sizeof header) == DTMERROR) {
		printf("An error was encountered in DTMbeginRead()\n");
		printf("\t%s\n", DTMerrmsg(1));
		return(DTMERROR);
	}

	if (DTMendRead(inport) == DTMERROR) {
		printf("An error was encountered in DTMendRead()\n");
		printf("\t%s\n", DTMerrmsg(1));
		return(DTMERROR);
	}

	printf("The header read was: '%s'\n", header);

	if (MSGcompareClass(header)) {
		MSGgetString(header, string, sizeof string);

		printf("The message is a MSGclass message and the string is:\n");
		printf("'%s'\n", string);
	}

	else printf("The message is not a MSGclass message: ignoring the header\n");

	return(DTM_OK);

}





/***************************************************************************
 *																									*
 * WRITING MSG CLASS MESSAGES:															*
 * This section of code contains examples of how one can write MSG class	*
 * messages and create the headers.														*
 *																									*
 ***************************************************************************/

/*
 * writeMSG:
 * Create a MSGclass message using the MSGset* macros and attempt to write
 * that message across the given port.  If an error is encountered during
 * the write, report it and return the value DTMERROR.  Otherwise, print a
 * message of success and return a value of DTM_OK.
 */
static int writeMSG(int outport)
{
	char			header[DTM_MAX_HEADER];

	MSGsetClass(header);
	MSGsetString(header, "This is a MSGclass message");

	if (DTMwriteMsg(outport, header, MSGHL(header), NULL, 0, 0)  == DTMERROR) {
		printf("An error was encountered in writeMSG() function DTMwriteMsg()\n");
		printf("\t%s\n", DTMerrmsg(1));
		return(DTMERROR);
	}
	printf("The message '%s' was successfully written\n", header);

	return(DTM_OK);

} /* writeMSG */




main(int argc, char *argv[])
{
	int			inport = DTMERROR,				/* DTM input port					*/
					outport = DTMERROR,				/* DTM output port				*/
					i = 0;								/* Argument counter				*/

	/*
	 * Create the requested port and do the ususal error
	 * checking.  If no ports are requested, report an
	 * error and exit.
	 */
	for (i = 1; i < argc; i++) {

		if (!strcmp(argv[i], "-DTMOUT")) {
			if ((outport = DTMmakeOutPort(argv[++i], DTM_DEFAULT)) == DTMERROR) {
				printf("Error in DTMmakeOutPort().  Port %s in use?\n", argv[i-1]);
				printf("\t%s\n", DTMerrmsg(1));
				exit(0);
			}
		}

		else if (!strcmp(argv[i], "-DTMIN")) {
			if ((inport = DTMmakeInPort(argv[++i], DTM_DEFAULT)) == DTMERROR) {
				printf("Error in DTMmakeInPort().  Port %s in use?\n", argv[i-1]);
				printf("\t%s\n", DTMerrmsg(1));
				exit(0);
			}
		}
	}

	if ((outport == DTMERROR) && (inport == DTMERROR)) {
		printf("\nUsage:\t%s -DTMOUT <port>\n", argv[0]);
		printf("Or:\t%s -DTMIN <port>\n\n", argv[0]);
		exit(0);
	}


	/*
	 * If an input port is requested, read a message from
	 * that port, otherwise attempt to write a message from
	 * the port.
	 */
	if (inport != DTMERROR)	
		readMSG(inport);

	else writeMSG(outport);

	return(0);
}
