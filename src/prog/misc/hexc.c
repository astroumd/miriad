/*---------------------------------------------------------------------*/
/*= hex - generate hexagonal grid patterns.
/*& mchw
/*: utility
/*+
/*  calculate hexagonal grid patterns for mosaic observations */
/*  See also hex.py in $MIR/examples/mosaic
/*---------------------------------------------------------------------*/
/*  History */
/*   03feb99 mchw - Miriad:  misc */
/*   11mar02 mchw - added declination  */
/*   12mar02 mchw - removed declination  */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

main()
{
	int n, row, k;
	double x, y, grid ;
	float dec;
	char tring[128];

	fprintf(stdout,"Enter grid spacing in arcsec :");
	fgets(tring, 127, stdin);
	grid = atof(tring);
	printf("%s \n",tring);

	fprintf(stdout,"Enter number of rings :");
	fscanf(stdin,"%d", & n);

	printf("hex: %d, grid spacing: %0.2f \n", n, grid) ; 

/*	fprintf(stdout,"Enter declination in degrees :");
	fscanf(stdin,"%f", & dec);

	printf("hex: %d, grid spacing: %0.2f, declination:  %0.2f \n", n, grid, dec) ; 
*/
	for (row = -(n-1); row <= (n-1); row++) 
	  { y = 0.866025403 * grid * row;
	  for (k=-(2*n-abs(row)-2); k<=(2*n-abs(row)-2); k+=2)
	    { x = 0.5 * grid * k ;
/*
	    { x = 0.5 * grid * k / cos((dec+row*grid/3600.)/57.29577951) ;
*/
	    fprintf(stdout,"%0.2f,%0.2f\n", x,y);
	    }
	  }
}
