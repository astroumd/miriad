/*
 * DEMOS.C:
 * is a collection of short demonstrations of how to use the SDS, SDL, and
 * VCTRL classes of DTM messages.
 *
 * DEMOS output: In order to see the output created by these demos, you will
 * need to have either the utility "readit" connected to the output port to 
 * view the actual data, or you will have to have other modules attached to 
 * visualize/manipulate the data.  Suggestions for these additional models 
 * accompany each example.  
 *
 * DEMOS input: The functions that read data from the input port must have
 * an external module sending data via that port in order to work properly.
 * A couple of small programs have been written and included in this set of
 * demo programs that give data to these ports.  The source code for these
 * additional programs is not as heavily commented as this program is, but
 * they can serve as extra examples.  The programs are:
 *
 *		gravity:	Sends a gravity field as data as a 
 *				scientific data set.
 *		circle:		An n-point circle described using the
 *				Surface Description Language.
 *		transforms:	Sends a view control message for a
 *				ModelView matrix that has had a
 *				translation and a rotation applied.
 */

#include <stdio.h>
#include <math.h>
#include <dtm.h>
#include <sdl.h>
#include <sds.h>

#include "messages.h"
#include "matrices.h"

#define DTM_IN		"-DTMIN"
#define DTM_OUT		"-DTMOUT"
#define SPHERE		"-sphere"
#define CUBE		"-cube"
#define TRANSFORMS	"-transform"
#define SDSDEMO		1
#define SDLDEMO		2
#define VCTRLDEMO	4

#define DSIZE		4096
#define NXMAX		20
#define NYMAX		20
#define NZMAX		20

#ifndef DTMgetPortName
#define DTMgetPortName(h, s, size)      dtm_get_char((h), "PORT", (s), size)
#endif

#ifndef DTMsetPortName
#define DTMsetPortName(h, s)    dtm_set_char((h), "PORT", (s))
#endif

typedef struct DTM_TRIPLET TRIPLET;	/* Defined for ease of reading	*/


/************************************************************************
 *									*
 *		FUNCTIONS DEALING WITH WRITING TO PORTS.		*
 *									*
 ************************************************************************/
/*
 * SPHERE_REGION:
 * Sends a scientific data set of values that increase evenly in all 
 * directions, radiating from the center of the volume.  This ouput would
 * be useful to send to an isosurface generator with a gradient value 
 * between 0 and the radius 10.
 */
sphere_region(outport)
int		outport;		/* The output data port		*/
{
   int		x, y, z,		/* Loop control variables	*/
		xcenter = NXMAX/2,
		ycenter = NYMAX/2,
		zcenter = NZMAX/2,	/* The sphere's center		*/
		dims[4];		/* The data dimensions		*/
   char		header[DTM_MAX_HEADER];	/* The sds header		*/
   float	grid[NXMAX][NYMAX][NZMAX];	/* The grid of data	*/


   /*
    * Create a "sphere grid" by simply recording in each cell of the grid
    * the distance to the center of the square volume.  Thus, each cell
    * that has the same value lies on a sphere of that distance value.
    */
   for (z = 0; z < NZMAX; z++)
      for (y = 0; y < NYMAX; y++)
         for (x = 0; x < NXMAX; x++)
            grid[x][y][z] = sqrt((x-xcenter)*(x-xcenter) +
				 (y-ycenter)*(y-ycenter) + 
				 (z-zcenter)*(z-zcenter));

   /*
    * CORE SDS WRITING CODE:
    * Set up the header for the transmission of the scientific data set.
    * This includes defining the dimensions of the data set, and setting
    * the rank as well as title.
    */
   dims[0] = NXMAX;
   dims[1] = NYMAX;
   dims[2] = NZMAX;
   SDSsetClass(header);
   SDSsetDimensions(header, 3, dims);
   SDSsetTitle(header, "Sphere");

   /*
    * Wait until the port is available then write the set to the output port.
    */
   while(!DTMavailWrite(outport));
   DTMbeginWrite(outport, header, DTMHL(header));
   DTMwriteDataset(outport, grid, NXMAX*NYMAX*NZMAX, DTM_FLOAT);
   DTMendWrite(outport);
} /* sphere_region */



/*
 * CUBE:
 * Given the eight corners of a cube, this uses the SDLquad primitive type
 * to create a solid, multi-colored cube.  Use the viewer to visualize it
 * and rotate it around.
 */
void cube(outport)
int		outport;		/* The output data port		*/
{
   float	points[8][3];		/* The eight cube corners	*/
   TRIPLET	*SDLdata, *ptr;		/* The cube when generated	*/
   char		header[DTM_MAX_HEADER];	/* The sdl header		*/

   /*
    * Allocate space for the cube vertices and colors: 6 faces X (4
    * vertices + 1 color) = 30 elements needed.  Assign values for each
    * of the six faces.  This is a bogus way of defining a cube, no?
    * So I'm lazy...
    */
   SDLdata = (TRIPLET *)malloc(30 * sizeof(TRIPLET));
   ptr = SDLdata;
   ptr->tag = SDLcolor;    ptr->x =  1.0; ptr->y =  0.0; ptr->z =  0.0; ptr++;
   ptr->tag = SDLposition; ptr->x = -1.0; ptr->y = -1.0; ptr->z = -1.0; ptr++;
   ptr->tag = SDLposition; ptr->x =  1.0; ptr->y = -1.0; ptr->z = -1.0; ptr++;
   ptr->tag = SDLposition; ptr->x =  1.0; ptr->y = -1.0; ptr->z =  1.0; ptr++;
   ptr->tag = SDLposition; ptr->x = -1.0; ptr->y = -1.0; ptr->z =  1.0; ptr++;

   ptr->tag = SDLcolor;    ptr->x =  0.0; ptr->y =  1.0; ptr->z =  0.0; ptr++;
   ptr->tag = SDLposition; ptr->x = -1.0; ptr->y = -1.0; ptr->z = -1.0; ptr++;
   ptr->tag = SDLposition; ptr->x =  1.0; ptr->y = -1.0; ptr->z = -1.0; ptr++;
   ptr->tag = SDLposition; ptr->x =  1.0; ptr->y =  1.0; ptr->z = -1.0; ptr++;
   ptr->tag = SDLposition; ptr->x = -1.0; ptr->y =  1.0; ptr->z = -1.0; ptr++;

   ptr->tag = SDLcolor;    ptr->x =  0.0; ptr->y =  0.0; ptr->z =  1.0; ptr++;
   ptr->tag = SDLposition; ptr->x =  1.0; ptr->y = -1.0; ptr->z = -1.0; ptr++;
   ptr->tag = SDLposition; ptr->x =  1.0; ptr->y = -1.0; ptr->z =  1.0; ptr++;
   ptr->tag = SDLposition; ptr->x =  1.0; ptr->y =  1.0; ptr->z =  1.0; ptr++;
   ptr->tag = SDLposition; ptr->x =  1.0; ptr->y =  1.0; ptr->z = -1.0; ptr++;

   ptr->tag = SDLcolor;    ptr->x =  1.0; ptr->y =  1.0; ptr->z =  0.0; ptr++;
   ptr->tag = SDLposition; ptr->x =  1.0; ptr->y = -1.0; ptr->z =  1.0; ptr++;
   ptr->tag = SDLposition; ptr->x = -1.0; ptr->y = -1.0; ptr->z =  1.0; ptr++;
   ptr->tag = SDLposition; ptr->x = -1.0; ptr->y =  1.0; ptr->z =  1.0; ptr++;
   ptr->tag = SDLposition; ptr->x =  1.0; ptr->y =  1.0; ptr->z =  1.0; ptr++;

   ptr->tag = SDLcolor;    ptr->x =  1.0; ptr->y =  0.0; ptr->z =  1.0; ptr++;
   ptr->tag = SDLposition; ptr->x = -1.0; ptr->y = -1.0; ptr->z =  1.0; ptr++;
   ptr->tag = SDLposition; ptr->x = -1.0; ptr->y = -1.0; ptr->z = -1.0; ptr++;
   ptr->tag = SDLposition; ptr->x = -1.0; ptr->y =  1.0; ptr->z = -1.0; ptr++;
   ptr->tag = SDLposition; ptr->x = -1.0; ptr->y =  1.0; ptr->z =  1.0; ptr++;

   ptr->tag = SDLcolor;    ptr->x =  0.0; ptr->y =  1.0; ptr->z =  1.0; ptr++;
   ptr->tag = SDLposition; ptr->x = -1.0; ptr->y =  1.0; ptr->z = -1.0; ptr++;
   ptr->tag = SDLposition; ptr->x =  1.0; ptr->y =  1.0; ptr->z = -1.0; ptr++;
   ptr->tag = SDLposition; ptr->x =  1.0; ptr->y =  1.0; ptr->z =  1.0; ptr++;
   ptr->tag = SDLposition; ptr->x = -1.0; ptr->y =  1.0; ptr->z =  1.0; ptr++;

   /*
    * CORE SDS WRITING CODE:
    * Set the class, title, and primitive type.  Then write the data
    * via the output port once it is available.
    */
   SDLsetClass(header);
   SDLsetPrimitive(header, SDLquad);
   SDLsetTitle(header, "Cube");

   while(!DTMavailWrite(outport));
   DTMbeginWrite(outport, header, DTMHL(header));
   DTMwriteDataset(outport, SDLdata, 30, DTM_TRIPLET);
   DTMendWrite(outport);
} /* cube */



/*
 * WIGGLE:
 * View control messages are generated by this function that would cause
 * an object to rotate about the line defined by the vector (1,1,1) and
 * to be translated forward and backward along this line in increments
 * of +/- 1.0 unit.
 */
void wiggle(outport)
int		outport;		/* The output data port		*/
{
   int		i;			/* Loop control variable	*/
   float	step = 0.0,		/* Translation step size	*/
		axis[3];		/* Axis of rotation		*/
   char		header[DTM_MAX_HEADER],	/* The header of the message	*/
		outaddr[32];		/* The output address		*/

   /*
    * CORE VCTRL WRITING CODE part I:
    * Set the class, global transformation type, and the name of this
    * output port.  This is placed up here because there is no need to
    * re-assign the header each time through the loop as it will always
    * be the same.
    */
   VCTRLsetClass(header);
   VCTRLsetGTM(header);
   DTMgetPortAddr(outport, outaddr, sizeof(outaddr));
   DTMsetPortName(header, outaddr);

   /*
    * Create the normalized axis pointing to (1,1,1).
    */
   axis[0] = axis[1] = axis[2] = 1.0 / sqrt(3.0);
  
   /*
    * Rotate about that axis and translate the approriate amount.
    */ 
   for (i = 0; i < 100; i++) {
      identity();
      step += ((i < 50) ? 0.1 : -0.1);
      scale(10.0, 10.0, 10.0);
      rotate_about_axis(step*100, axis);
      translate(step, step, step);

      /*
       * CORE VCTRL WRITING CODE part II:
       * Wait until the port is available for writing and send the matrix.
       */
      while(!DTMavailWrite(outport));
      DTMbeginWrite(outport, header, DTMHL(header));
      DTMwriteDataset(outport, matrix, 16, DTM_FLOAT);
      DTMendWrite(outport);
   }
} /* wiggle */



/*
 * WRITE_DEMOS:
 * demonstrate how to write the three different message classes. WRITE_DEMOS 
 * also demonstrates how to open a port for writing and close it.
 */
void write_demos(outport, demos)
int		outport,		/* The output port		*/
		demos;			/* The demos to run mask	*/
{
   if (demos & SDSDEMO)
      sphere_region(outport);

   if (demos & SDLDEMO)
      cube(outport);

   if (demos & VCTRLDEMO)
      wiggle(outport);
} /* write_demos */



/************************************************************************
 *									*
 *		FUNCTIONS DEALING WITH READING FROM PORTS.		*
 *									*
 ************************************************************************/
/*
 * READ_VCTRL:
 * reads a view control message from the specified port.
 */
void readVCTRL(inport, header)
int		inport;			/* The input port		*/
char		*header;		/* The data header		*/
{
   float	matrix[16];		/* The viewcontrol matrix	*/
   int		len,			/* The actual # of elements	*/
		i;			/* Loop control variable	*/
   char		portname[32];		/* The portname			*/

   fprintf(stderr, "Identified an incoming view control message...\n");

   /*
    * CORE VCTRL READING CODE:
    * View control messages are at the present very simple: they consist
    * of a single 4x4 matrix that contains the composite modelling and
    * viewing transforms.  Further transforms made to this matrix should
    * be PRE-MULTIPLIED in order to achieve the correct transformation.
    */
   DTMgetPortName(header, portname, sizeof(portname));
   len = DTMreadDataset(inport, matrix, 16, DTM_FLOAT);

   /*
    * Print the matrix.
    */
   fprintf(stderr, "Here is the matrix sent from port '%s':\n", portname);
   for (i = 0; i < len; i+=4)
      fprintf(stderr, "| %7.4f %7.4f %7.4f %7.4f |\n",
		      matrix[i], matrix[i+1], matrix[i+2], matrix[i+3]);
   
}  /* readVCTRL */


/*
 * READ_SDL:
 * reads a surface description language data stream from the specified port.
 */
void readSDL(inport, header)
int		inport;			/* The input port		*/
char		*header;		/* The data header		*/
{
   SDLprim_t	primitive;		/* The primitive type		*/
   TRIPLET	SDLdata[DSIZE];		/* The data to be read		*/
   int		size,			/* Unused size information	*/
		len,			/* The actual # of TRIPLETs	*/
		i;			/* The loop control variable	*/
   char		title[80];		/* Arbitrary len. title string	*/

   fprintf(stderr, "Identified an incoming SDL message...\n");

   /*
    * CORE SDL READING CODE:
    * Determine the title, the primitive type, and read the data.
    * Since it is impossible to determine in advance how much data is
    * to be read, we must read it in chunks, either reallocating the
    * amount of memory as new data is read, or disposing of the data
    * as soon as it is not needed.  Here the data is printed as soon
    * as it is read and the array of TRIPLETs is reused.
    */
   SDLgetPrimitive(header, &primitive);
   SDLgetTitle(header, title, sizeof(title));
   while ((len = DTMreadDataset(inport, SDLdata, DSIZE, DTM_TRIPLET)) > 0) {

      /*
       * Since were splitting this up in chunks, the data handling
       * code would go here.  In this case all we'll do is print the
       * information read from the port.
       */
      fprintf(stderr, "Primitive Type: ");
      switch(primitive) {
	 case SDLpoint:		fprintf(stderr, "SDLpoint\n"); break;
	 case SDLlineseg:	fprintf(stderr, "SDLlineseg\n"); break;
	 case SDLtriangle:	fprintf(stderr, "SDLtriangle\n"); break;
	 case SDLtristrip:	fprintf(stderr, "SDLtristrip\n"); break;
	 case SDLquad:		fprintf(stderr, "SDLquad\n"); break;
	 case SDLsphere:	fprintf(stderr, "SDLsphere\n"); break;
      }
      fprintf(stderr, "Title: '%s'\nData: \n", title);
      for (i = 0; i < len; i++) {
	 switch(SDLdata[i].tag) {
	    case SDLposition:	fprintf(stderr, "SDLposition "); break;
	    case SDLcolor:	fprintf(stderr, "SDLcolor "); break;
	    case SDLnormal:	fprintf(stderr, "SDLnormal "); break;
	    case SDLtranslate:	fprintf(stderr, "SDLtranslate "); break;
	    case SDLrotate:	fprintf(stderr, "SDLrotate "); break;
	    case SDLscale:	fprintf(stderr, "SDLscale "); break;
	 }
	 fprintf(stderr, "(%6.4f %7.4f %7.4f)\n",
			 SDLdata[i].x, SDLdata[i].y, SDLdata[i].z);
      }
   }
}  /* readSDL */


/*
 * READ_SDS:
 * reads a scientific data set from the specified port.
 */
void readSDS(inport, header)
int		inport;			/* The input port		*/
char		*header;		/* The data header		*/
{
   int		rank,			/* The rank of the field	*/
		size = 1,		/* The size of the data		*/
		dims[10],		/* The dimensions of the data	*/
		len = 0,		/* The bytes of data read	*/
		i;			/* Loop control variable	*/
   float	*data;			/* Data values stored here	*/
   char		title[80];		/* The title of the data	*/

   fprintf(stderr, "Identified an incoming SDS message...\n");

   /*
    * CORE SDS READING CODE:
    * Get the title and the dimensions of the data from the header.  Then
    * attempt to allocate enough space for the entire data set.  If not
    * possible, in this case, abort the program, even though in most cases
    * the data should be read in chunks.  If allocation succeeds, read
    * the entire data set.  LEN indicates how many floating point values
    * were actually read and should be the exact same size as was calculated.
    */
   SDSgetTitle(header, title, sizeof(title));
   SDSgetDimensions(header, &rank, dims, 10);
   size = SDSnumElements(rank, dims);
   data = (float *)malloc(size * sizeof(float));
   if (data == NULL)
      abort_demos("insufficient memory to store field", inport);
   len = DTMreadDataset(inport, data, size, DTM_FLOAT);

   /*
    * Display the data read from the port.
    */
   fprintf(stderr, "The data set title: '%s'\nThe rank: %d\n", title, rank);
   fprintf(stderr, "The dimensions: ");
   for (i = 0; i < rank; i++) {
     fprintf(stderr, "%d ", dims[i]);
   }
   fprintf(stderr, "\nCalculated data size: %d floating point values.\n", size);
   fprintf(stderr, "The actual size of data: %d\n",len);
   fprintf(stderr, "The data values actually read are:\n");
   for (i = 0; i < len; i++)
      fprintf(stderr, "%c%10.3E", ((i % 7 == 0) ? '\n' : ' '), data[i]);
   fprintf(stderr, "\n");

} /* readSDS */


/*
 * READ_DEMOS:
 * demonstrate how to read the three different message classes.  READ_DEMOS
 * also demonstrates how to open a port for reading and close it.  The
 * basic structure is as follows:
 *
 *		Wait for port to become available.
 *		Begin reading by reading the header:
 *			If unsuccessful, abort or return.
 *		Read the data according to the message class.
 *		End reading from the port.
 */
void read_demos(inport, outport)
int		inport,			/* The input port		*/
		outport;		/* The output port		*/
{
   char		header[DTM_MAX_HEADER];	/* The message header/ident.	*/

   fprintf(stderr, "\nCommencing reading from a port demos...\n");

   /*
    * If port not available for reading wait.
    */
   while (!DTMavailRead(inport));

   /*
    * Now that it's available, begin the reading.  If an error occurs,
    * handle it appropriately.
    */
   if (DTMbeginRead(inport, header, sizeof(header)) == DTMERROR) {
      if (DTMerrno != DTMEOF)
	 abort_demos("reading from port", inport);
      else return;
   }

   /*
    * Display the header, just for demo purposes.
    */
   fprintf(stderr, "The header retrieved is: '%s'\n", header);

   /*
    * Compare the header with the classes and call the correct function
    * for dealing with the correct message type.
    */
   if (SDScompareClass(header))
      readSDS(inport, header);
   else if (SDLcompareClass(header))
      readSDL(inport, header);
   else if (VCTRLcompareClass(header))
      readVCTRL(inport, header);
   else alert_demos("unknown message class retrieved", inport);

   /*
    * End the reading from the port.  Note that every "DTMbeginRead" should
    * be paired with a "DTMendRead" at some point.
    */
   DTMendRead(inport);

} /* read_demos */



main(argc, argv)
int		argc;
char		*argv[];
{
   int		inport = -1,		/* The input port		*/
		outport = -1,		/* The output port		*/
		i = 1,			/* Loop control variable	*/
		demos = 0;		/* Output demos to run		*/

   /*
    * Parse the command line and assign the input & output ports.
    */
   for (i = 1; i < argc; i++) {
      if (!strcmp(argv[i], DTM_IN)) 
	 inport = DTMmakeInPort(argv[++i], DTM_SYNC);
      else if (!strcmp(argv[i], DTM_OUT))
	 outport = DTMmakeOutPort(argv[++i], DTM_SYNC);
      else if (!strcmp(argv[i], SPHERE))
	 demos |= SDSDEMO;
      else if (!strcmp(argv[i], CUBE))
	 demos |= SDLDEMO;
      else if (!strcmp(argv[i], TRANSFORMS))
	 demos |= VCTRLDEMO;
   }

   /*
    * If neither a input port, nor an output port are declared, quit
    */
   if (((inport == -1) && ((outport == -1) || !demos))) usage(argv[0]);

   /*
    * Input available?  Try reading the three message classes.
    */
   if (inport != -1) read_demos(inport, outport);

   /*
    * Output available?  Try writing the three types of message classes
    */
   if ((outport != -1) && demos) write_demos(outport, demos);

   exit(0);
} /* demos.c */
