/*
 * Program:	readHeader.c
 *
 * Example:	11
 *
 * Usage:	readHeader
 *
 * This example demonstrates how to read a DTM message header from a
 * given port.  A writing program must be sending to port 7788 if
 * this program is to execute properly.
 *
 * No error checking is performed by this code.  For code that checks
 * for errors, see the examples in the error detection section.
 *
 */
#include <stdio.h>
#include <stdlib.h>
#include <dtm.h>


main(int argc, char *argv[])
{
	char		header[DTM_MAX_HEADER]; /* DTM header of unknown size			*/
	int		inport = DTMERROR;		/* Input port								*/


	/*
	 * Create an input port using the hardcoded value
	 * ":7788".  This practice is not recommended but
	 * was done to keep this program simple.
	 */
	inport = DTMmakeInPort(":7788", DTM_DEFAULT);


	/*
	 * Begin reading from the input port.  If no writer
	 * is sending data then the program will block at the
	 * DTMbeginRead call.  A sample writer is provided in
	 * example #.
	 */
	DTMbeginRead(inport, header, sizeof header);
	DTMendRead(inport);

	printf("The header received was: '%s'\n", header);

	return(0);
}
