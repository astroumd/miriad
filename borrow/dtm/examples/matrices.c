/*
 * MATRICES.C:					Septemeber 6, 1991
 * contains the matrix routines used by the demo programs.  These are simple
 * modifications of the ones that are used by the xviewer, and only those
 * necessary are included here.  (The xviewer transform file was not copied
 * directly because they are much more complicated dealing with a stack
 * which is not necessary here.)  Most of the code has been lifted directly
 * from _Graphics_Gems_ though the matrices have been transposed to allow
 * for pre-multiplication to take place.
 */

#include	<stdio.h>
#include	<math.h>
#include	"matrices.h"

/* Global variables */
double	degtorad = M_PI / 180.0;
Matrix	matrix = { { 1.0, 0.0, 0.0, 0.0 },
		   { 0.0, 1.0, 0.0, 0.0 },
		   { 0.0, 0.0, 1.0, 0.0 },
		   { 0.0, 0.0, 0.0, 1.0 }
		 };


/************************************************************************
 *									*
 * Various useful matrix routines					*
 *									*
 ************************************************************************/

/*
 * PRINT_MAT:
 * prints out the specified matrix.
 */
void print_mat(m)
Matrix		m;			/* The matrix to print		*/
{

   fprintf(stderr, "\nmatrix:\n");
   fprintf(stderr, "\t%f, %f, %f, %f\n", m[0][0], m[0][1], m[0][2], m[0][3]);
   fprintf(stderr, "\t%f, %f, %f, %f\n", m[1][0], m[1][1], m[1][2], m[1][3]);
   fprintf(stderr, "\t%f, %f, %f, %f\n", m[2][0], m[2][1], m[2][2], m[2][3]);
   fprintf(stderr, "\t%f, %f, %f, %f\n\n", m[3][0], m[3][1], m[3][2], m[3][3]);
} /* print_mat */


/*
 * IDENTITY:
 * clears the matrix to be the identity matrix.
 */
void identity()
{
  bzero(matrix, sizeof(Matrix));

  matrix[0][0] = 1.0;
  matrix[1][1] = 1.0;
  matrix[2][2] = 1.0;
  matrix[3][3] = 1.0;
} /* identity */


/*
 * TRANSLATE:
 * translates by the supplied values.
 */
void translate(tx, ty, tz)
double		tx, ty, tz;		/* The translation vector	*/
{
   matrix[3][0] += tx*matrix[0][0] + ty*matrix[1][0] + tz*matrix[2][0];
   matrix[3][1] += tx*matrix[0][1] + ty*matrix[1][1] + tz*matrix[2][1];
   matrix[3][2] += tx*matrix[0][2] + ty*matrix[1][2] + tz*matrix[2][2];
   matrix[3][3] += tx*matrix[0][3] + ty*matrix[1][3] + tz*matrix[2][3];
} /* translate */



/*
 * SCALE:
 * applies a scaling factor of (sx, sy, sz) to the matrix.
 */
void scale(sx, sy, sz)
double		sx, sy, sz;		/* The scaling factors		*/
{
   matrix[0][0] *= sx;
   matrix[1][0] *= sy;
   matrix[2][0] *= sz;
 
   matrix[0][1] *= sx;
   matrix[1][1] *= sy;
   matrix[2][1] *= sz;

   matrix[0][2] *= sx;
   matrix[1][2] *= sy;
   matrix[2][2] *= sz;

   matrix[0][3] *= sx;
   matrix[1][3] *= sy;
   matrix[2][3] *= sz;
} /* scale */


/*
 * ROTATE_X:
 * applies a rotation of "degrees" degrees about the x axis.
 */
void rotate_x(degrees)
float		degrees;		/* Angle of rotation in degrees */
{
   float	cosine,			/* cos(angle)                   */
		sine;			/* sin(angle)                   */
   double	angle;			/* Angle in radians             */
   Matrix	m;			/* Temporary matrix		*/

   angle = degtorad * degrees;
   cosine = (float)cos(angle);
   sine = (float)sin(angle);

   bcopy(matrix, m, sizeof(Matrix));

   m[1][0] = matrix[1][0] * cosine + matrix[2][0] * sine;
   m[1][1] = matrix[1][1] * cosine + matrix[2][1] * sine;
   m[1][2] = matrix[1][2] * cosine + matrix[2][2] * sine;
   m[1][3] = matrix[1][3] * cosine + matrix[2][3] * sine;
   m[2][0] = matrix[2][0] * cosine - matrix[1][0] * sine;
   m[2][1] = matrix[2][1] * cosine - matrix[1][1] * sine;
   m[2][2] = matrix[2][2] * cosine - matrix[1][2] * sine;
   m[2][3] = matrix[2][3] * cosine - matrix[1][3] * sine;

   loadmatrix(m);
} /* rotate_x */


/*
 * ROTATE_ABOUT_AXIS:
 * generates a rotation matrix for a rotation about an arbitrary axis 
 * defined by a vector at the origin.  The angle of rotation is given in
 * degrees.  This method of rotation was taken from the book _Graphics_Gems_
 * page 466 and transposed to allow for pre-multiplication of matrices.
 */
void rotate_about_axis(degrees, axis)
float		degrees,		/* The angle of rotation	*/
		axis[3];		/* The normalized axis vector	*/
{
   float	t,			/* 1 - Cosine of angle		*/
		c,			/* Cosine of angle		*/
		s;			/* Sine of angle		*/
   double	angle;			/* The angle of rotation	*/
   Matrix	rotation;		/* The rotation matrix		*/

   /*
    * Convert the angle to radians and then calculate t, c, and s.
    */
   angle = degtorad * degrees;
   c = (float)cos(angle);
   s = (float)sin(angle);
   t = 1.0 - c;

   /*
    * Use the normalized axis and the angle of rotation to determine the
    * rotation matrix.  Matrix taken from _Graphics_Gems_ pg. 466.
    */

   rotation[0][0] = t*axis[0]*axis[0] + c;
   rotation[0][1] = t*axis[0]*axis[1] - s*axis[2];
   rotation[0][2] = t*axis[0]*axis[2] + s*axis[1];
   rotation[0][3] = 0.0;
   rotation[1][0] = t*axis[0]*axis[1] + s*axis[2];;
   rotation[1][1] = t*axis[1]*axis[1] + c;
   rotation[1][2] = t*axis[1]*axis[2] - s*axis[0];;
   rotation[1][3] = 0.0;
   rotation[2][0] = t*axis[0]*axis[2] - s*axis[1];;
   rotation[2][1] = t*axis[1]*axis[2] + s*axis[0];;
   rotation[2][2] = t*axis[2]*axis[2] + c;
   rotation[2][3] = 0.0;
   rotation[3][0] = rotation[3][1] = rotation[3][2] = 0.0;
   rotation[3][3] = 1.0;

   multmatrix(rotation);
} /* axis_rot */



/*
 * MULTMATRIX:
 * premultiplies the matrix by the argument matrix.
 */
void multmatrix(m)
Matrix		m;			/* The matrix to multiply by	*/
{
   int		r, c;			/* Row and column loop control	*/
   Matrix	n;			/* New matrix calculated	*/

   for (r = 0; r < 4; r++)
      for (c = 0; c < 4; c++)
	 n[r][c] = m[r][0]*matrix[0][c] + m[r][1]*matrix[1][c] +
		   m[r][2]*matrix[2][c] + m[r][3]*matrix[3][c];
   loadmatrix(n);
} /* multmatrix */
