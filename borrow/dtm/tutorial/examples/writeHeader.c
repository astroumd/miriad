/*
 * Program:	writeHeader.c
 *
 * Example	3
 *
 * Usage:	writeHeader
 *
 * This example demonstrates how to write a DTM message header to a
 * given port.  A reading program must be listening on port 7788 if
 * this program is to cease executing.
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
	char		*header = "This is a header";		/* DTM header.						*/
	int		outport = DTMERROR;					/* Output port						*/

	/*
	 * Create an output port using the hardcoded value
	 * ":7788".  This practice is not recommended, but
	 * was done to keep this program simple.
	 */
	outport = DTMmakeOutPort(":7788", DTM_DEFAULT);

	/*
	 * The following two lines write the header to the output
	 * port created above.  If no reader is listening, the 
	 * program will block at the DTMbeginWrite call.  A sample
	 * reader is provided with Example #.
	 */
	DTMbeginWrite(outport, header, DTMHL(header));
	DTMendWrite(outport);

	return(0);
}
