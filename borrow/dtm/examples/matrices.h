/***********************************************************************
**
** header file for 'matrices.c' - set of matrix routines for the demos.
**
************************************************************************/

typedef float Matrix[4][4];

extern Matrix matrix;			/* The currently saved matrix	*/

extern void print_mat();
extern void identity();
extern void rotate_x();
extern void rotate_about_axis();
extern void translate();
extern void scale();
extern void multmatrix();

/* global macros */
#define	loadmatrix(m) bcopy(m, matrix, sizeof(Matrix))
#define getmatrix(m) bcopy(matrix, m, sizeof(Matrix)))
