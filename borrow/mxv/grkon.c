

/* ------------------------------------------------------------------ */
float FMAX2 (a,b) float a,b; { if (a>b ) return (a); else return(b); }
float FMIN2 (a,b) float a,b; { if (a<b ) return (a); else return(b); }

float FMAX4 (a,b,c,d) float a,b,c,d; 
{ return (  (float) FMAX2( (float) FMAX2(a,b), (float) FMAX2(c,d))  ); }

float FMIN4 (a,b,c,d) float a,b,c,d; 
{ return (  (float) FMIN2( (float) FMIN2(a,b), (float) FMIN2(c,d))  ); }
/* ------------------------------------------------------------------ */

/* PURE CONTOURING CODE FOLLOWS */

/* macro for inverse interpolation */
#define INVERSE(xm,zm,xp,zp,zz) ( (xp*(zz-zm) + xm*(zp-zz)) / (zp-zm) )

/* returns 1 if ok, else 0 */
/* if ok, returns x and y  vals  */

int cpoint (f0, x0, y0, f1, x1, y1, clvl, x, y, flag)
float f0, f1, x0, x1, y0, y1; 	/* f1 is value at (x1,y1) etc */
float clvl; 							/* contour val */
float  *x, *y;
{
	if (clvl > FMAX2 (f0,f1) || clvl < FMIN2 (f0,f1)) {
		return (0);
	}
	if (f0 == f1)  
		return (0);
	else {
		*x = INVERSE (x0, f0, x1, f1, clvl);
		*y = INVERSE (y0, f0, y1, f1, clvl);
		return (1);
	}
}
/* ------------------------------------------------------------------ */
/* THIS IS THE ACTUAL ROUTINE THAT CALCULATES THE CONTOURS */
int mxv_make_contour (a, xg, yg, nx, ny, clvl, ncint)
int ncint;				/* no of contour levels */
float clvl[]; 			/* contour levels to use */	
int nx, ny;
float  xg[], yg[]; 	/* grid x and y vals */
float a[]; 				/* 2D float data (nx x xy) */
{

#define AVALUE(x,y) ((float)  a[(y)*nx + (x)])
#define GOOD_AVALUE(x,y) ((float)  a[(x)*ny + (y)])

	float xp[4], yp[4];
	int c, cross;
	float y1, y2, x1, x2, f0, f1, f2, f3, f4;
	int i, j, n;
	float zmax, zmin, x, y, level;
	long degen = 0; /* count of degenerates */
	long good = 0; /* count of segments created */

	/* -------  CINT Loop --------- */
	for (n=0; n<ncint; n++) {
		level = clvl[n];

			if ( level  == 0.0) continue;

	  /* ----- loop for array cells ---- */
		for (j=0; j<ny-1; j++) {
			y1 = yg[j];
			y2 = yg[j+1];
			for (i=0; i<nx-1; i++) {
				x1 = xg[i];
				x2 = xg[i+1];

				f1 = AVALUE (i, j+1); 			/* a[i][j+1]; */
				f2 = AVALUE (i+1, j+1); 		/* a[i+1][j+1]; */
				f3 = AVALUE (i, j);				/* a[i][j]; */
				f4 = AVALUE (i+1, j); 			/* a[i+1][j]; */

				/* check to see if contour crosses cell */
				zmax = FMAX4 (f1, f2, f3, f4);
				zmin = FMIN4 (f1, f2, f3, f4);
				if ( level <= zmax && level > zmin) {

					/* compute crossings */
					cross = 0;
					c = cpoint (f1, x1, y2, f3, x1, y1, level, &x, &y);
					if (c) { xp[cross] = x; yp[cross] = y; cross++; }
					c = cpoint (f1, x1, y2, f2, x2, y2, level, &x, &y);
					if (c) { xp[cross] = x; yp[cross] = y; cross++; }
					c = cpoint (f4, x2, y1, f2, x2, y2, level, &x, &y);
					if (c) { xp[cross] = x; yp[cross] = y; cross++; }
					c = cpoint (f4, x2, y1, f3, x1, y1, level, &x, &y);
					if (c) { xp[cross] = x; yp[cross] = y; cross++; }

					switch (cross) {
					case 1 : /* ignore */
						return;
						break;
					case 2 : /* then draw line */
						putline (xp[0], yp[0], xp[1], yp[1]);
						good++;
						break;
					case 3:  /* degenerate case - ignore */
						degen ++;
						break;
					case 4: /* saddle point. use 5th pt to draw */
						f0 = 0.25 * (f1+f2+f3+f4);
						if ( (level > f0 && level < f1)  ||
						    (level > f1 && level < f0)     ) {
							putline (xp[0], yp[0], xp[1], yp[1]);
							good++;
							putline (xp[2], yp[2], xp[3], yp[3]);
							good++;
						}
						else {
							putline (xp[0], yp[0], xp[2], yp[2]);
							good++;
							putline (xp[1], yp[1], xp[3], yp[3]);
							good++;
						}
						break;
					} /* switch */
				} /* if */
			}
		}
	}
} /* end makecontour */

/* ------------------------------------------------------------------ */


