/*
 * TRANSFORMS.C
 * is a simple demo program that takes a ModelView matrix, applies a
 * translation of (3,4,5) and applies a rotation of 45 degrees about the
 * x axis.  The new ModelView matrix, calculated by premultiplying the
 * rotation and translation matrices, is then sent out as a view control
 * message via the output port.
 */

#include <stdio.h>
#include <math.h>
#include <dtm.h>
#include <sdl.h>
#include "matrices.h"

#define	DTM_OUT		"-DTMOUT"

#ifndef DTMsetPortName
#define DTMsetPortName(h, s)    dtm_set_char((h), "PORT", (s))
#endif

#ifndef DTMgetPortName
#define DTMgetPortName(h, s, size)      dtm_get_char((h), "PORT", (s), size)
#endif

extern Matrix	matrix;


/*
 * USAGE:
 * prints the correct usage for this program.
 */
void usage(program_name)
char		*program_name;		/* The program name (DUH!)	*/
{
   fprintf(stderr, "\nUsage: %s %s <output port>\n\n", program_name, DTM_OUT);
   exit(-1);
} /* usage */


main(argc, argv)
int		argc;
char		*argv[];
{
   char		header[DTM_MAX_HEADER],	/* The header of the message	*/
		outaddr[32];		/* The output address		*/
   int		outport = -1,		/* The output port		*/
		i;			/* Loop control variable	*/

   /*
    * Parse the command line for at least one output port.  Abort the
    * program if incorrect.
    */
   for (i = 1; i < argc; i++)
      if (!strcmp(argv[i], DTM_OUT)) {
	 outport = DTMmakeOutPort(argv[++i], DTM_SYNC);
	 DTMgetPortAddr(outport, outaddr, sizeof(outaddr));
      }
   if (outport == -1) usage(argv[0]);

   /*
    * Clear the matrix, translate (3,4,5) from the origin and rotate 45
    * degrees around the x axis.
    */
   identity();
   translate(3.0, 4.0, 5.0);
   rotate_x(45.0);

   /*
    * Set the view control message header.  The addition of the port
    * name is necessary for programs like the "viewer" that require
    * passing these messages around.  By adding the port name from which
    * the message originated it is possible to screen out messages that
    * are original to that run of the program.
    */
   VCTRLsetClass(header);
   VCTRLsetGTM(header);
   DTMsetPortName(header, outaddr);

   /*
    * Wait until the port becomes available for writing output and then
    * send the view control message.
    */
   while(!DTMavailWrite(outport));
   DTMbeginWrite(outport, header, DTMHL(header));
   DTMwriteDataset(outport, matrix, 16, DTM_FLOAT);
   DTMendWrite(outport);

} /* transforms.c */
