#ifndef NO_ISO
#include "gr_com.h"
#include "gr_iso.h"

extern void	gr_IsoScanFill();
extern void	gr_IsoEvent();

static float32	***data;
#define D(x,y,z)	(data[x][y][z])
#define even(a)		(1 & (~a))
typedef	int Coordinate[3];

static Coordinate	cubeVertices[8]	= {
	{0, 0, 0},
	{0, 1, 0},
	{1, 1, 0},
	{1, 0, 0},
	{0, 0, 1},
	{0, 1, 1},
	{1, 1, 1},
	{1, 0, 1}};
	
#define D0	D(x,y,z)
#define D1	D(x,y+1,z)
#define D2	D(x+1,y+1,z)
#define D3	D(x+1,y,z)
#define D4	D(x,y,z+1)
#define D5	D(x,y+1,z+1)
#define D6	D(x+1,y+1,z+1)
#define D7	D(x+1,y,z+1)

typedef		int Edge[2];

static Edge *cubeEdges;	/* pointer to either cubeEdgesEven or cubeEdgesOdd */

static int	cubeEdgesEven[18][2] 	= {
	{0, 1},
	{1, 2},
	{3, 2},
	{0, 3},
	{4, 5},
	{5, 6},
	{7, 6},
	{4, 7},
	{0, 4},
	{1, 5},
	{2, 6},
	{3, 7},
	{0, 2},	/* 12 */
	{5, 7},
	{0, 5},
	{7, 2},
	{5, 2},
	{0, 7}
	};

static int	cubeEdgesOdd[18][2] 	= {
	{0, 1},
	{1, 2},
	{3, 2},
	{0, 3},
	{4, 5},
	{5, 6},
	{7, 6},
	{4, 7},
	{0, 4},
	{1, 5},
	{2, 6},
	{3, 7},
	{1, 3},	/* 12 */
	{4, 6},
	{4, 1},
	{3, 6},
	{1, 6},
	{4, 3}
	};
	
static int	tetraVertices[6][2]	= {
	{0, 1},	/* edge 0 */
	{1, 2},
	{2, 3},
	{0, 3},
	{0, 2},
	{1, 3}};

/* Table of 5 tetrahedrons in a cube; each row is the list of cube vertices. */

typedef TetraVertices[4];

static TetraVertices	*cubeTetraVertices;

static int cubeTetraVerticesEven[5][4] = {
	{0, 1, 2, 5},
	{2, 5, 6, 7},
	{0, 2, 3, 7},
	{0, 7, 4, 5},
	{0, 5, 2, 7}};

static int cubeTetraVerticesOdd[5][4] = {
	{0, 1, 3, 4},
	{1, 2, 3, 6},
	{3, 4, 6, 7},
	{1, 4, 5, 6},
	{1, 3, 4, 6}};
	
typedef	TetraEdges[6];

static TetraEdges	*cubeTetraEdges;

static int	cubeTetraEdgesEven[5][6]	= {
	{0, 1, 16, 14, 12, 9},
	{16, 5, 6, 15, 10, 13},
	{12, 2, 11, 17, 3, 15},
	{17, 7, 4, 14, 8, 13},
	{14, 16, 15, 17, 12, 13}};

static int	cubeTetraEdgesOdd[5][6]	= {
	{0, 12, 17, 8, 3, 14},
	{1, 2, 15, 16, 12, 10},
	{17, 13, 6, 11, 15, 7},
	{14, 4, 5, 16, 9, 13},
	{12, 17, 13, 16, 14, 15}};

static int	triTetra[16][7]	= {
							/* 0123 - vertices of tetrahedron */
	{0, 0, 0, 0, 0, 0, 0},	/* 0000 - all vertices are lower than value */
	{1, 2, 5, 3, 0, 0, 0},	/* 0001 - only vertex 3 is higher */
	{1, 1, 2, 4, 0, 0, 0},	/* 0010 */
	{2, 3, 4, 5, 5, 4, 1},	/* 0011 */
	{1, 0, 5, 1, 0, 0, 0},	/* 0100 */
	{2, 1, 0, 2, 2, 0, 3},
	{2, 0, 5, 4, 4, 5, 2},
	{1, 0, 3, 4, 0, 0, 0},
	{1, 0, 4, 3, 0, 0, 0},
	{2, 0, 4, 5, 5, 4, 2},
	{2, 1, 2, 0, 0, 2, 3},
	{1, 0, 1, 5, 0, 0, 0},
	{2, 3, 5, 4, 4, 5, 1},
	{1, 1, 4, 2, 0, 0, 0},
	{1, 2, 3, 5, 0, 0, 0},
	{0, 0, 0, 0, 0, 0, 0}};


/* Interpolation data is stored to avoid recomputation. */
static InterpData
		** zFace,	/* Previous z plane of faces */
		* yFace,	/* Previous y line of faces */
		xFace;		/* Previous x face */


/* Booleans that indicates if currently indexing on the edge of the data */
static int	onXedge, onYedge, onZedge;	

static float32	aSave, baSave;	/* for use by interp macro */
static float32	dataValue;	/* the value to interpolate at */
#define interp(a, b)	(aSave=a, baSave=b-aSave, \
							(baSave ? (((float32)dataValue-aSave) / baSave) : -1 ))

#define dinterp(a, b)	(((float32)dataValue-a) / (b-a))


void 
mcube(isoWin,d, xn, yn, zn, xi, xj, yi, yj, zi, zj, values, numvalues)
	A_IsoWind_t *isoWin;
	float32 ***d;			/* 3D array of data */
	int	xn, yn, zn;	/* size of each dimension of d */
	int	*xi, *xj, 	/* range of data to plot, for each dimension & value */
		*yi, *yj, 
		*zi, *zj;
	float32	*values;	/* list of values plot surface of */
	int numvalues;	/* length of values */
{
	int i;
	
	data = d;
	
	/* allocate interpolation data arrays */
	yFace = (InterpData *) malloc(xn * sizeof(InterpData));
	if (!yFace) return;
	zFace = (InterpData **) td_Alloc2D(xn,yn,sizeof(InterpData),"2d");
	if (!zFace) return;
	
	isoWin->curSubs=0;
	for (i = 0; ((i<numvalues) && (isoWin->stopIso == FALSE)); i++)
	{
	  mcubeOneValue(isoWin,values[i], xi[i], xj[i], yi[i], yj[i], zi[i], zj[i]);
	  isoWin->curSubs++;
	}
	isoWin->curSubs=0;
}

/* Global vars for index into data */
static	int	x, y, z;

/* Global var to store whether each corner of the cube is higher than the value */
static	int	cubecase[8];

void mcubeOneValue(isoWin,value, xFirst, xLast, yFirst, yLast, zFirst, zLast)
	A_IsoWind_t	*isoWin;
	float32 value;
	int	xFirst, xLast, 	/* range of data to plot, for each dimension */
		yFirst, yLast, 
		zFirst, zLast;
{	
	dataValue = value;
	
 	z = 0;
	for (x = xFirst; x <= xLast; x++) {
	for (y = yFirst; y <= yLast; y++) {
		zFace[x][y].h.good = 0;
		zFace[x][y].v.good = 0;
		zFace[x][y].d.good = 0;
		}};

	/* loop through each z plane.*/
	for (z = zFirst; z < zLast; z++) {

/* Stop on interrupt */
gr_IsoEvent(isoWin);
if (isoWin->stopIso == TRUE)
	return;

		onZedge = (z == zFirst || z == (zLast-1));
		
		y = 0;
		for (x = xFirst; x <= xLast; x++) {
			yFace[x].h.good = 0;
			yFace[x].v.good = 0;
			yFace[x].d.good = 0;
			};
		
		/* loop through each y line */
		for (y = yFirst; y < yLast; y++) {
			onYedge = (y == yFirst || y == (yLast-1));

			x = 0;
			xFace.h.good = 0;
			xFace.v.good = 0;
			xFace.d.good = 0;
			
			/* loop through each x value */
			for (x = xFirst; x < xLast; x++) {
				int	i;
				int	found;
				/* test whether there is any intersection in this cube */
				found = 0;
				cubecase[0] = D(x+cubeVertices[0][0], 
								y+cubeVertices[0][1], 
								z+cubeVertices[0][2]) <= dataValue;
				for (i=1; i<8; i++) {
					cubecase[i] = D(x+cubeVertices[i][0], 
									y+cubeVertices[i][1], 
									z+cubeVertices[i][2]) <= dataValue;
					found = found || (cubecase[i] != cubecase[i-1]);
					};
				if (found) {
					onXedge = (x == xFirst || x == (xLast-1));
					triangCube(isoWin);
					}
				else { /* skipping a cube, so most values we would save are lost */
					xFace.h.good = 0;
					xFace.v.good = 0;
					xFace.d.good = 0;
					yFace[x].h.good = 0;
					yFace[x].v = xFace.h;
					yFace[x].d.good = 0;
					zFace[x][y].h = yFace[x].h;
					zFace[x][y].v = xFace.v;
					zFace[x][y].d.good = 0;
					}					
				}
			
			/* reinit some more values after x interation is done */
			yFace[x].v.good = 0;
			zFace[x][y].v.good = 0;
			}

		/* last row of zFace needs to be reinitialized */
		y = yLast;
		for (x = xFirst; x < xLast; x++)
			zFace[x][y].h.good = 0;
		}
}

InterpCoor
	cubeD[18];	/* 12 edges of cube + 6 diagonal edges */

void triangCube(isoWin)
A_IsoWind_t *isoWin;
{
	/* find old faces */
	/* should avoid doing the copy if value hasnt been computed, ie good=0 */
	cubeD[9] = xFace.h;
	cubeD[4] = xFace.v;
	cubeD[14] = xFace.d;
	cubeD[7] = yFace[x].h;
	cubeD[8] = yFace[x].v;
	cubeD[17] = yFace[x].d;
	cubeD[3] = zFace[x][y].h;
	cubeD[0] = zFace[x][y].v;
	cubeD[12] = zFace[x][y].d;
	
	cubeD[1] = zFace[x][y+1].h;
	cubeD[2] = zFace[x+1][y].v;
	cubeD[11] = yFace[x+1].v;

	cubeD[10].good = 0;	/* A */
	cubeD[6].good = 0;	/* B */
	cubeD[5].good = 0;	/* C */
		
	cubeD[13].good = 0;
	cubeD[15].good = 0;	
	cubeD[16].good = 0;
	if (even(x+y+z)) {
		cubeEdges = (Edge *)cubeEdgesEven;
		cubeTetraEdges = (TetraEdges *)cubeTetraEdgesEven;
		cubeTetraVertices = (TetraVertices *)cubeTetraVerticesEven;
		}
	else {
		cubeEdges = (Edge *)cubeEdgesOdd;
		cubeTetraEdges = (TetraEdges *)cubeTetraEdgesOdd;
		cubeTetraVertices = (TetraVertices *)cubeTetraVerticesOdd;
		};
		
	/* triangulate each tetrahedron */
	{
		int i;
		for (i = 0; i < 5; i++)
			triangTetra(isoWin,cubeTetraEdges[i], cubeTetraVertices[i]);
	}
	
	/* save values for future cubes */
	xFace.h	= cubeD[10];
	xFace.v	= cubeD[6];
	xFace.d	= cubeD[15];
	yFace[x].h = cubeD[5];
	yFace[x].v = cubeD[9];
	yFace[x].d = cubeD[16];
	zFace[x][y].h = cubeD[7];
	zFace[x][y].v = cubeD[4];
	zFace[x][y].d = cubeD[13];
}

void triangTetra(isoWin, E, V)
A_IsoWind_t *isoWin;
	int E[6];	/* edges of tetrahedron */
	int V[4];	/* vertices .. */
{
	int i, j, k;
	Coordinate	*c1, *c2;	/* coordinate of a vertex */
	int *tri;			/* row of TriTetra */
	int numTriangles;
	InterpCoor p[3];	/* three points of interpolated triangle */
	int	edge;

	/* first determine which of 16 cases we have */
	{
		register int	sum;
		register int	factor;
		
		sum = 0;
		factor = 8;
		for (i = 0; i < 4; i++) {
			sum += (cubecase[V[i]]) * factor;
			factor = factor >> 1;
			};
		tri = triTetra[sum];
	};
	
	/* for each triangle, find intersection points and draw segments between them */
	numTriangles = *tri;
	tri++;
	for (i = 0; i < numTriangles; i++)
	{
		/* for each intersecting edge */
		for (j = 0; j < 3; j++)
		{
			edge = *(tri++);
			/* get the coordinates of endpoints */
			c1 = (Coordinate *) cubeVertices[cubeEdges[E[edge]][0]];
			c2 = (Coordinate *) cubeVertices[cubeEdges[E[edge]][1]];
			
			/* find intersection point along the edge */
			{
				register InterpCoor	*p;		/* where to store interpolation data */
				float32	dist;
				p = &cubeD[E[edge]];
				
				if (!p->good) {
					p->good = 1;
					dist = interp(D(x+c1[0][0], y+c1[0][1], z+c1[0][2]),
								  D(x+c2[0][0], y+c2[0][1], z+c2[0][2]));
					p->x = x + c1[0][0] + (c2[0][0] - c1[0][0]) * dist;
					p->y = y + c1[0][1] + (c2[0][1] - c1[0][1]) * dist;
					p->z = z + c1[0][2] + (c2[0][2] - c1[0][2]) * dist;
					}
			};

			p[j] = cubeD[E[edge]];
		};
		
		gr_IsoScanFill(isoWin,p);
	}
}
#endif
