/*
 * Program:	SDSexample.c
 *
 * Example:	22, 23
 *
 * Usage:	SDSexample -DTMIN <port>
 *							-or-
 *				SDSexample -DTMOUT <port>
 *
 * Sample:	SDSexample -DTMIN :7788
 *						-or-
 *				SDSexample -DTMOUT gallant:7788
 *
 * This example serves a dual purpose: both the reading and writing programs
 * are contained within one source file.  To execute the reading program,
 * specify only an input port on the command line.  To execute the writing
 * program, specify an output port on the command line.
 *
 * This program demonstrates how to use the scientific data set (SDS)
 * class using the SDS class' creation macros.  It also demonstrates
 * how to determine if a message received is an SDS class message
 * how to parse the header to get the needed information, also
 * using the predefined SDSclass macros.
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
#include <sds.h>



/***************************************************************************
 *																									*
 * Reading an SDS message:																	*
 * The following code reads SDS messages from the given port and prints		*
 * out the data.  It is assumed that only floating point data is being		*
 * used, though the code can be generalized to other types of data as		*
 * well.																							*
 *																									*
 ***************************************************************************/

/*
 * printData:
 * Print out the floating point data.
 */
static void printData(	char *title, float minimum, float maximum,
								int *dims, int rank, float *array, int count)
{
	int			i = 0;

	printf("\nTitle: '%s'\n", title);

	printf("Rank = %d\n", rank);
	printf("Dimensions:");
	for (i = 0; i < rank; i++)
		printf(" %d", dims[i]);

	printf("\nMin = %f, Max = %f\n", minimum, maximum);
	printf("\nData:");
	for (i = 0; i < count; i++)
		printf("Data value %d = %f\n", i, array[i]);

	printf("\n");
}



/*
 * readSDS:
 * Attempt to read a header from the supplied port.  If the header is an
 * SDSclass message, print the associated data.  If the message is of 
 * some other class, print an error message.
 */
static int readSDS(int inport)
{
	int		rank = 0,						/* Rank of the dataset (# of dims)	*/
				size = 0,						/* Size of the array in floats		*/
				count = 0,						/* Number of floats read				*/
				dims[10];						/* Max # of dims for this example	*/
	float		minimum = 0.0,					/* Minimum value							*/
				maximum = 0.0,					/* Maximum value							*/
				*array = NULL;					/* The array of data						*/
	char		header[SDSsize],				/* SDS header								*/
				title[80];						/* Title of this message				*/
	DTMTYPE	type = DTM_FLOAT;				/* Default type is DTM_FLOAT			*/

	/*
	 * Begin reading.  Ensure that the message read was an SDS class
	 * message before continuing.
	 */
	if (DTMbeginRead(inport, header, sizeof header) == DTMERROR) {
		printf("Error in DTMbeginRead()\n");
		printf("\t%s\n", DTMerrmsg(1));
		return(DTMERROR);
	}


	/*
	 * If the message is an SDS class message, get the various possible
	 * datatypes (but don't do anything with them).  Ignore non-SDS
	 * messages completely.
	 */
	if (SDScompareClass(header)) {

		SDSgetMinMax(header, &minimum, &maximum);
		SDSgetType(header, &type);
		SDSgetTitle(header, title, sizeof title);
		SDSgetDimensions(header, &rank, dims, 10);
		size = SDSnumElements(rank, dims);
		array = (float *)malloc(size * sizeof(float));

		/*
		 * Read the dataset and print out only the number of items read.
		 */
		if ((count = DTMreadDataset(inport, array, size, DTM_FLOAT))==DTMERROR) {
			printf("Error in DTMreadDataset()\n");
			printf("\t%s\n", DTMerrmsg(1));
			return(DTMERROR);
		}
		printData(title, minimum, maximum, dims, rank, array, count);

	}

	if (DTMendRead(inport) == DTMERROR) {
		printf("Error in DTMendRead()\n");
		printf("\t%s\n", DTMerrmsg(1));
		return(DTMERROR);
	}

	return(DTM_OK);

}



/***************************************************************************
 *																									*
 * Writing an SDS message:																	*
 * The following code writes SDS messages to the given port.  Only			*
 * floating point data is being sent, though the code can be generalized	*
 * to other types of data as well.														*
 *																									*
 ***************************************************************************/

/*
 * writeSDS:
 * Create an SDSclass message using the SDSset* macros and attempt to write
 * that message across the given port.  If an error is encountered during
 * the write, report it and return the value DTMERROR.  Otherwise, print a
 * message of success and return a value of DTM_OK.
 */
static int writeSDS(int outport)
{
	int		i = 0,							/* Loop variable							*/
				rank = 3,						/* Rank of the dataset (# of dims)	*/
				size = 0,						/* Size of the array						*/
				dims[3];							/* Dimensions for this example		*/
	char		header[SDSsize];				/* SDS header								*/
	float		*array = NULL;					/* Data array								*/


	/*
	 * Initialize the example data.  The elements of the
	 * array are centered about 0.  Normally this data would
	 * come from a simulation or an experiment.
	 */
	dims[0] = 2; dims[1] = 3; dims[2] = 4;
	size = dims[0] * dims[1] * dims[2];
	array = (float *)malloc(size * sizeof(float));
	for (i = 0; i < size; i++)
		array[i] = (float)i - (float)size/2.0;


	/*
	 * Set up the SDS message header using the SDSclass macros.
	 */
	SDSsetClass(header);
	SDSsetDimensions(header, rank, dims);
	SDSsetTitle(header, "This is an SDS array");
	SDSsetType(header, DTM_FLOAT);
	SDSsetMinMax(header, -(float)size/2.0, (float)size/2.0-1.0);


	/*
	 * Attempt to send the header and data at the same time.  This
	 * practice is recommended whenever the data is contained
	 * within a single buffer.
	 */
	if (DTMwriteMsg(outport, header, SDSHL(header), array, size, DTM_FLOAT) 
				== DTMERROR) {
		printf("Error in DTMwriteMsg()\n");
		printf("\t%s\n", DTMerrmsg(1));
		return(DTMERROR);
	}

	printf("Write of SDS was successful.\n");
	return(DTM_OK);
}



/*
 * main:
 * Create an input or output port based on the type specified.  Read or
 * write the data depending on the type of port created.
 */
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
		readSDS(inport);

	else writeSDS(outport);

	return(0);
}
