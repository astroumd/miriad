/*
 * Program:	select.c
 *
 * Example:	16
 *
 * Usage:	select -port1 <port> -port2 <port>
 *
 * Sample:	select -port1 :7897 -port2 9494
 *
 * The purpose of this program is to demonstrate how DTMselectRead is able
 * to determine which ports are available for reading.  The main program
 * will loop through three reads before quitting.  Any of the other sample
 * writing programs can send data to this program, though if any messages
 * are sent with data in addition to a header, that data will be ignored.
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
		printf("An error was encountered in readMSG() function DTMbeginRead()\n");
		printf("\t%s\n", DTMerrmsg(1));
		return(DTMERROR);
	}

	if (DTMendRead(inport) == DTMERROR) {
		printf("An error was encountered in readMSG() function DTMendRead()\n");
		printf("\t%s\n", DTMerrmsg(1));
		return(DTMERROR);
	}

	printf("The header read was: '%s'\n", header);

	if (MSGcompareClass(header)) {
		MSGgetString(header, string, sizeof string);

		printf("The message is a MSGclass message and the string is:\n");
		printf("'%s'\n", string);

		if (!strcmp("QUIT", string)) return(1);
	}

	else
		printf("The message is not a MSGclass message: ignoring the header\n");

	return(DTM_OK);

}




main(int argc, char *argv[])
{
	int			i = 0,							/* Argument counter					*/
					error = DTM_OK,				/* DTMselectRead error code		*/
					quit = 0;						/* Program exit flag					*/
	Dtm_set		portset[2];						/* Port connection information	*/


	/*
	 * Initialize the Dtm_set structure for proper error checking.
	 */
	for (i = 0; i < 2; i++) {
		portset[i].port = DTMERROR;
		portset[i].status = DTM_PORT_NOT_READY;
	}


	/*
	 * Create the requested ports and do the ususal error
	 * checking.  If no ports are requested, report an
	 * error and exit.
	 */
	for (i = 1; i < argc; i++) {

		if (!strcmp(argv[i], "-port1")) {
			portset[0].port = DTMmakeInPort(argv[++i], DTM_DEFAULT);
			if (portset[0].port == DTMERROR) {
				printf("Error in DTMmakeInPort().  Port %s in use?\n", argv[i-1]);
				printf("\t%s\n", DTMerrmsg(1));
				exit(0);
			}
		}

		else if (!strcmp(argv[i], "-port2")) {
			portset[1].port = DTMmakeInPort(argv[++i], DTM_DEFAULT);
			if (portset[1].port == DTMERROR) {
				printf("Error in DTMmakeInPort().  Port %s in use?\n", argv[i-1]);
				printf("\t%s\n", DTMerrmsg(1));
				exit(0);
			}
		}

	}

	if ((portset[0].port == DTMERROR) || (portset[1].port == DTMERROR)) {
		printf("\nUsage:\t%s -port1 <port> -port2 <port>\n\n", argv[0]);
		exit(0);
	}


	/*
	 * Loop until three reads have been done.
	 */
	while (quit < 3) {

		/*
		 * Block here waiting for a port to become ready.
		 * The "-1" argument indicates block until a port
		 * is ready.
		 */
		if (error = DTMselectRead(portset, 2, NULL, 0, -1)) {

			/*
			 * If there is an error, report it and loop again.
			 * Otherwise, determine which port is ready for
			 * reading and read the message.  The returned value
			 * indicates if the message string said "QUIT".
			 */
			if (error == DTMERROR) {
				printf("An error was encountered in main() by DTMselectRead()\n");
				printf("\t%s\n", DTMerrmsg(1));
			}

			else {
				if (portset[0].status == DTM_PORT_READY) {
					printf("Message ready on port 1 (#%d)\n", portset[0].port);
					readMSG(portset[0].port);
					quit++;
				}

				if (portset[1].status == DTM_PORT_READY) {
					printf("Message ready on port 2 (#%d)\n", portset[1].port);
					readMSG(portset[1].port);
					quit++;
				}
			}
		}
	}

	return(0);
}
