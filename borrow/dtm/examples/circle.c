#include <stdio.h>
#include <math.h>
#include <dtm.h>
#include <sdl.h>


#define DTM_OUT		"-DTMOUT"
#define NUM_SEGS	"-segments"

typedef struct DTM_TRIPLET	TRIPLET;


/*
 * USAGE:
 * prints the correct usage for this program.
 */
void usage(program_name)
char		*program_name;		/* The program name (DUH!)	*/
{
   fprintf(stderr, "\nUsage: %s %s <output port> %s <# of segments (>0)>\n\n",
		   program_name, DTM_OUT, NUM_SEGS);
   exit(-1);
} /* usage */



/*
 * CALCULATE_CIRCLE
 * uses the polar coordinate equations to calculate a circle based on
 * an arbitrary radius (5.0 units in this case) and the angle.  The
 * points are calculated individually then split apart according to
 * how they pair up into line segments.
 */
int calculate_circle(SDLdata, numsegs)
TRIPLET		**SDLdata;		/* The circle points & colors	*/
int		numsegs;		/* The number of circle segs	*/
{
   int		size,			/* The size of the data		*/
		i;			/* Loop control variable	*/
   float	angle,			/* Angle value			*/
		delta_a,		/* Delta angle value		*/
		*x, *y;			/* The circle points		*/
   TRIPLET	*SDLtemp;		/* Data pointer			*/

   delta_a = 2*M_PI/numsegs;

   /*
    * Calculate the points using polar coordinates and store them in
    * arrays for later assignment.
    */
   x = (float *)malloc(numsegs * sizeof(float));
   y = (float *)malloc(numsegs * sizeof(float));
   for (angle = 0.0, i = 0; i < numsegs; i++, angle += delta_a) {
      x[i] = 5.0 * cos(angle);
      y[i] = 5.0 * sin(angle);
   }

   /*
    * Allocate storage for the circle data.  Then copy the data from
    * the point arrays in pairs including some arbitrary colors.
    */
   size = 3*numsegs;
   *SDLdata = (TRIPLET *)malloc(size*sizeof(TRIPLET));
   SDLtemp = *SDLdata;
   for (i = 0; i < numsegs; i++) {
      /*
       * Assign the color first.
       */
      SDLtemp->tag = SDLcolor;
      SDLtemp->x = fabs(x[i])/5.0;
      SDLtemp->y = fabs(y[i])/5.0;
      SDLtemp->z = (float)i/numsegs;
      SDLtemp++;

      /*
       * Assign the two endpoints of the line segment
       */
      SDLtemp->tag = SDLposition;
      SDLtemp->x = x[i]; SDLtemp->y = y[i]; SDLtemp->z = 0.0;
      SDLtemp++;

      SDLtemp->tag = SDLposition;
      if (i+1 == numsegs) {
	 SDLtemp->x = x[0]; SDLtemp->y = y[0]; SDLtemp->z = 0.0;
      }
      else {
	 SDLtemp->x = x[i+1]; SDLtemp->y = y[i+1]; SDLtemp->z = 0.0;
      }
      SDLtemp++;
   }
   return(size);

} /* calculate_circle */


/*
 * WRITE_SDL:
 * will write the scientific data language of the given size to the given
 * port.
 */
int write_SDL(outport, SDLdata, size)
int		outport,		/* The output port		*/
		size;			/* The size of the data		*/
TRIPLET		*SDLdata;		/* The circle points & colors	*/
{
   int		return_val = 1;		/* The return value		*/
   char		header[DTM_MAX_HEADER];	/* The header of the message	*/

   if (size > 0) {

      /*
       * Set the header up for SDL by setting the correct class, the
       * correct primitive type, and an arbitrary title: "Circle".  Then
       * wait until the port is available for writing, and send the entire
       * data set.
       */
      SDLsetClass(header);
      SDLsetPrimitive(header, SDLlineseg);
      SDLsetTitle(header, "Circle");
      while (!DTMavailWrite(outport));
      DTMbeginWrite(outport, header, DTMHL(header));
      DTMwriteDataset(outport, SDLdata, size, DTM_TRIPLET);
      DTMendWrite(outport);
   }
   return(return_val);
} /* write_SDL */



main(argc, argv)
int		argc;
char		*argv[];
{
   int		outport = -1,		/* The output port		*/
		numsegs = 0,		/* The # of circle segments	*/
		size,			/* The number of triplets	*/
		i;			/* Loop control variable	*/
   TRIPLET	*SDLdata;		/* The circle points		*/

   /*
    * Parse the command line for at least one output port.  Abort the
    * program if incorrect.
    */
   for (i = 1; i < argc; i++) {
      if (!strcmp(argv[i], DTM_OUT))
	 outport = DTMmakeOutPort(argv[++i], DTM_SYNC);
      else if (!strcmp(argv[i], NUM_SEGS))
	 numsegs = atoi(argv[++i]);
   }
   if ((outport == -1) || (numsegs <= 0))  usage(argv[0]);

   size = calculate_circle(&SDLdata, numsegs);
   if (!write_SDL(outport, SDLdata, size))
      fprintf(stderr, "Error in writing data.\n");

   return(0);
} /* circle.c */
