/*
 * Program:	ports.c
 *
 * Examples 1
 *
 * Usage:	ports
 *
 * This program demonstrates how input and output ports can be created
 * and shows the values that are the DTM port descriptors.
 *
 * Using hardcoded port names like the ones shown here ("goofus:7788" and
 * "gallant.ncsa.uiuc.edu:8899") is not a recommended practice.  Port
 * names and numbers should be parsed from the command line or created
 * using logical port names whenever possible.
 *
 * When the "inport" and "outport" variables are created, it is best to
 * initialize them to the value DTMERROR.  The reason for this will become
 * apparent in later examples.
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <dtm.h>

main(int argc, char *argv[])
{
	int		inport = DTMERROR,				/* Input port id						*/
				outport = DTMERROR;				/* Output port id						*/

	outport = DTMmakeOutPort("gallant.ncsa.uiuc.edu:8899", DTM_DEFAULT);
	printf("The output port DTM id = %d\n", outport);

	inport = DTMmakeInPort("goofus:7788", DTM_DEFAULT);
	printf("The input port DTM id = %d\n", inport);

	return(0);
}
