/*
 * GRAVITY.C:
 * creates a gravitational field in a square volume of three space about a
 * point mass centered in the middle of that three-space.  The field is
 * then written as a SDS to the supplied output port.
 */
#include <stdio.h>
#include <math.h>
#include <dtm.h>
#include <sds.h>

#define	XMAX	10
#define	YMAX	10
#define	ZMAX	10
#define M	10.0
#define G	6.67e-8

#define DTM_OUT		"-DTMOUT"

typedef struct {
   float	x, y, z;
} Vector;

Vector		field[XMAX][YMAX][ZMAX];


void gravity()
{
   int		x, y, z,		/* Loop control for each dim	*/
		vx, vy, vz,		/* The location vector		*/
		cx, cy, cz;		/* Center of the system		*/
   float	denom,			/* Denominator of the equation	*/
		numer,			/* Numerator of the equation	*/
		ratio,			/* The numer / denom ratio	*/
		cubed;			/* The cube of the dot prod.	*/

   /*
    * Determine the center of the region at which point the mass M is located.
    */
   cx = XMAX/2;
   cy = YMAX/2;
   cz = ZMAX/2;

   /*
    * For each point calculate the gravitational force due to the mass M
    * at that point.
    */
   numer = -G * M;
   for (x = 0; x < XMAX; x++)
      for (y = 0; y < YMAX; y++)
	 for (z = 0; z < ZMAX; z++) {

	    /*
	     * Determine the vector from the center to the current point
	     * and then calculate the force in that direction.
	     */
	    vx = x - cx; vy = y - cy; vz = z - cz;
	    cubed = (vx*vx + vy*vy + vz*vz);
	    denom = sqrt(cubed * cubed * cubed);
	    ratio = ((denom == 0.0) ? 0.0 : numer/denom);
	    field[x][y][z].x = ratio * vx;
	    field[x][y][z].y = ratio * vy;
	    field[x][y][z].z = ratio * vz;
	 }
} /* gravity */



void writeSDS(outport)
int		outport;		/* The output port		*/
{
   char		header[DTM_MAX_HEADER];	/* The maximum header		*/
   int		dims[4],		/* The dimensions		*/
		rank = 4,		/* The rank of the data		*/
		size;			/* The size of the data		*/

   dims[0] = 3;
   dims[1] = XMAX; dims[2] = YMAX; dims[3] = ZMAX;

   SDSsetClass(header);
   SDSsetDimensions(header, rank, dims);
   SDSsetTitle(header, "Gravity");
   size = SDSnumElements(rank, dims);

   /*
    * Wait until the port is available for writing and send the data.
    */
   while(!DTMavailWrite(outport));
   DTMbeginWrite(outport, header, DTMHL(header));
   DTMwriteDataset(outport, field, size, DTM_FLOAT);
   DTMendWrite(outport);
} /* writeSDS */


/*
 * USAGE:
 * displays the usage of the program.
 */
void usage(prog_name)
char		*prog_name;		/* The name of the program	*/
{
   fprintf(stderr, "\nUsage: %s %s <data output port>\n\n", prog_name, DTM_OUT);
   exit(-1);
} /* usage */



main(argc, argv)
int		argc;
char		*argv[];
{
   int		outport = -1,		/* The output port		*/
		i = 1;			/* Loop control variable	*/

   /*
    * Parse the command line and assign the input & output ports
    */
   for (i = 1; i < argc; i++)
      if (!strcmp(argv[i], DTM_OUT))
         outport = DTMmakeOutPort(argv[++i], DTM_SYNC);
   if (outport == -1) usage(argv[0]);

   /*
    * Caluclate the gravity field to send.
    */
   gravity();

   /*
    * Write the gravitational field out to the output port.
    */
   writeSDS(outport);
}
