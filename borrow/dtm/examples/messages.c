/*
 * MESSAGES.C
 * contains the code for all of the message functions used by the DEMOS
 * program.
 */
#include <stdio.h>

#define DTM_IN		"-DTMIN"
#define DTM_OUT		"-DTMOUT"
#define SPHERE		"-sphere"
#define CUBE		"-cube"
#define TRANSFORMS	"-transform"



/*
 * ALERT_DEMOS:
 * prints out an alert message, but performs no other actions.
 */
void alert_demos(message, port)
char		*message;		/* The message to print		*/
int		port;			/* The current port		*/
{
   fprintf(stderr, "Error: '%s' from port %d\n", port);
} /* alert_demos */


/*
 * ABORT_DEMOS:
 * prints out an error message and aborts the program.
 */
void abort_demos(message, port)
char		*message;		/* The message to print		*/
int		port;			/* The current port		*/
{
   fprintf(stderr, "Error: '%s' from port %d\nAborting...\n\n",
		   message, port);
   exit(-1);
} /* abort_demos */


/*
 * USAGE:
 * describes the correct usage of this program.
 */
void usage(program_name)
char		*program_name;
{
   fprintf(stderr, "\nUsage: %s [%s <input port>]\n\t     [%s <output port> [%s %s %s]]\n\n",
		   program_name, DTM_IN, DTM_OUT, SPHERE, CUBE, TRANSFORMS);

   fprintf(stderr, "\t%s:\tSpecifies a port that will accept incoming messages and react\n\t\taccordingly to the type of message received.  Not specifying\n\t\tthis port will cause the program to ignore the routines that\n\t\tuse the input.  WARNING: if there is no data being sent to\n\t\tthis port by any other module, this program will block until\n\t\tit receives data.\n\n",DTM_IN);

   fprintf(stderr, "\t%s: Specifies a port that will be used to send output.  Each\n\t\t option added after the port will specify an output demo to be\n\t\t run.  These include sending a vector field (SDS), sending a\n\t\t multi-colored cube (SDL), and a moving-spinning transform\n\t\t (VCTRL).  Not specifying this port will cause the program to\n\t\t ignore the functions that create data.  WARNING: this program\n\t\t will block until the port is available for writing.\n\n",DTM_OUT);

   fprintf(stderr, "\t\tAt least one of either type of port must be specified.\n\n");

   exit(-1);
} /* usage */
