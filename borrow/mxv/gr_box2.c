/*
 *	File:		gr_box2.c
 *	Contents:	Box routines for graphics module
 */

#include <math.h>
#include "gr_com.h"
extern A_BoxVert_t	*gr_CreateVNode();
extern A_BoxEdge_t	*gr_CreateENode();

#define	DIST	900.0

double C[5][5];
double mat[5][5];


/*
 *	Pre-multiply B with A
 *	C=B*A
 */
void
gr_MatMult(A,B)
double	A[5][5],B[5][5];
{
	short  i,j;

	for (i=1;i<5;i++)
		for(j=1;j<5;j++)
			C[i][j] = A[i][1]*B[1][j]+A[i][2]*B[2][j]+
					  A[i][3]*B[3][j]+A[i][4]*B[4][j];
}


/*
 * Get inverse matrix
 */
void
gr_MatInverse(A,B)
double A[5][5],B[5][5];
{
	double T[5][5];
	short i,j;

	for (i=0;i<5;i++)
		for (j=0;j<5;j++)
		{
			B[i][j] = (double)0.0;
			T[i][j] = A[i][j];
		}
	B[1][1] = B[2][2] = B[3][3] = B[4][4] = (double)1.0;
	B[1][1] = B[1][1]/T[1][1];
	T[1][3] = T[1][3]/T[1][1];
	T[1][2] = T[1][2]/T[1][1];
	T[1][1] = (double)1.0;
	B[2][1] = -(T[2][1]*B[1][1]);
	T[2][3] = T[2][3]-(T[2][1]*T[1][3]);
	T[2][2] = T[2][2]-(T[2][1]*T[1][2]);
	T[2][1] = (double)0.0;
	B[3][1] = -(T[3][1]*B[1][1]);
	T[3][3] = T[3][3]-(T[3][1]*T[1][3]);
	T[3][2] = T[3][2]-(T[3][1]*T[1][2]);
	T[3][1] = (double)0.0;
	B[2][1] = B[2][1]/T[2][2];
	B[2][2] = B[2][2]/T[2][2];
	T[2][3] = T[2][3]/T[2][2];
	T[2][2] = (double)1.0;
	B[3][1] = B[3][1]-(T[3][2]*B[2][1]);
	B[3][2] = B[3][2]-(T[3][2]*B[2][2]);
	T[3][3] = T[3][3]-(T[3][2]*T[2][3]);
	T[3][2] = (double)0.0;
	B[3][1] = B[3][1]/T[3][3];
	B[3][2] = B[3][2]/T[3][3];
	B[3][3] = B[3][3]/T[3][3];
	T[3][3] = (double)1.0;
	B[2][1] = B[2][1]-(T[2][3]*B[3][1]);
	B[2][2] = B[2][2]-(T[2][3]*B[3][2]);
	B[2][3] = -(T[2][3]*B[3][3]);
	T[2][3] = (double)0.0;
	B[1][1] = B[1][1]-(T[1][2]*B[2][1]);
	B[1][2] = -(T[1][2]*B[2][2]);
	B[1][3] = -(T[1][2]*B[2][3]);
	T[1][2] = (double)0.0;
	B[1][1] = B[1][1]-(T[1][3]*B[3][1]);
	B[1][2] = B[1][2]-(T[1][3]*B[3][2]);
	B[1][3] = B[1][3]-(T[1][3]*B[3][3]);
	T[1][3] = (double)0.0;
}


/*
 * Return distance between 2 cartesian points
 */
double
gr_Distance(x1,y1,x2,y2)
double x1,y1,x2,y2;
{
	return(sqrt((x1-x2)*(x1-x2)+(y1-y2)*(y1-y2)));
}


/*
 * Rotate matrix in X-Y direction
 */
void
gr_BoxRotX(box,newang)
A_Box_t	*box;
int		newang;
{
	int	   i,j;
	double A,B;
	double diff;

	diff=(double)(box->xangle - (double)newang);

	box->xangle = (double)newang;
	diff = (double)(diff*(double)3.141592654/(double)180.0);
	A = sin(diff);
	B = cos(diff);

	mat[1][1] = 1.0;
	mat[1][2] = 0.0;
	mat[1][3] = 0.0;
	mat[1][4] = 0.0;
	mat[2][1] = 0.0;
	mat[2][2] = B;
	mat[2][3] = A;
	mat[2][4] = 0.0;
	mat[3][1] = 0.0;
	mat[3][2] = -A;
	mat[3][3] = B;
	mat[3][4] = 0.0;
	mat[4][1] = 0.0;
	mat[4][2] = 0.0;
	mat[4][3] = 0.0;
	mat[4][4] = 1.0;

	gr_MatMult(mat,box->matrix);
	for (i=1;i<5;i++)
		for (j=1;j<5;j++)
			box->matrix[i][j] = C[i][j];
}


/*
 * Rotate matrix in Y-Z direction
 */
void
gr_BoxRotY(box,newang)
A_Box_t	*box;
int		newang;
{
	int	   i,j;
	double A,B;
	double diff;

	diff=(double)(box->yangle - (double)newang);

	box->yangle = (double)newang;
	diff = (double)(diff*(double)3.141592654/(double)180.0);
	A = sin(diff);
	B = cos(diff);

	mat[1][1] = B;
	mat[1][2] = 0.0;
	mat[1][3] = -A;
	mat[1][4] = 0.0;
	mat[2][1] = 0.0;
	mat[2][2] = 1.0;
	mat[2][3] = 0.0;
	mat[2][4] = 0.0;
	mat[3][1] = A;
	mat[3][2] = 0.0;
	mat[3][3] = B;
	mat[3][4] = 0.0;
	mat[4][1] = 0.0;
	mat[4][2] = 0.0;
	mat[4][3] = 0.0;
	mat[4][4] = 1.0;

	gr_MatMult(mat,box->matrix);
	for (i=1;i<5;i++)
		for (j=1;j<5;j++)
			box->matrix[i][j] = C[i][j];
}


/*
 * Obtain a slice
 */
void
gr_BoxSlice(box,indepth)
A_Box_t	*box;
int		indepth;
{
	A_BoxEdge_t	*boxedges=box->edgeList;
	A_BoxVert_t	*cutVert,*nextVert,*mark,*prev,*tmp;
	int			i,tmpID;
	double 		u,x,y;
	Boolean		found=FALSE,first=TRUE;

	box->indepth = indepth;
	box->depth = (double)((double)indepth*
					 ((box->zmax-box->zmin)/100.0)+box->zmin);

	/* remove previous intersect vertices */
	td_Free((char *)box->cutVList);
	box->cutVList = NULL;

	/* remove previous intersect edges */
	td_Free((char *)box->cutEList);
	box->cutEList = NULL;

	box->numCuts = 0;

	while (boxedges != NULL)
	{
		if (boxedges->v2->z != boxedges->v1->z)
			u = (box->depth - boxedges->v1->z) /
				(boxedges->v2->z - boxedges->v1->z);
		else
			u = 1.1;
		if ((u >= 0.0) && (u <= 1.0))
		{
			box->numCuts++;
			x = boxedges->v1->x + (boxedges->v2->x - boxedges->v1->x)*u;
			y = boxedges->v1->y + (boxedges->v2->y - boxedges->v1->y)*u;
			box->cutVList = gr_CreateVNode(box->cutVList,box->numCuts,
							x,y,box->depth,boxedges);
			if (first == TRUE)
			{
				box->boundxmin = box->boundxmax = x;
				box->boundymin = box->boundymax = y;
				first = FALSE;
			}
			else
			{
				if (x < box->boundxmin)
					box->boundxmin = x;
				else
				if (x > box->boundxmax)
					box->boundxmax = x;
				if (y < box->boundymin)
					box->boundymin = y;
				else
				if (y > box->boundymax)
					box->boundymax = y;
			}
		}
		boxedges = boxedges->next;
	}

	/* sort intersection points */
	cutVert = box->cutVList;
	while (cutVert->next != NULL)
	{
		prev = cutVert;
		mark = nextVert = cutVert->next;
		found = FALSE;
		while (found == FALSE)
		{
			i=0;
			while ((i<7) && (nextVert->enode->id != cutVert->enode->adj[i]))
				i++;
			if (i==7)
			{
				prev = nextVert;
				nextVert = nextVert->next;
			}
			else
				found = TRUE;
		}
		if (nextVert != mark)
		{
			/* swap vertices nextVert with mark */
			tmpID = mark->id;
			mark->id = nextVert->id;
			nextVert->id = tmpID;
			cutVert->next = nextVert;
			if (mark != prev)
			{
				tmp = mark->next;
				mark->next = nextVert->next;
				nextVert->next = tmp;
				prev->next = mark;
			}
			else
			{
				mark->next = nextVert->next;
				nextVert->next = mark;
			}
		}
		cutVert = cutVert->next;
	}

	for (i=1;i<box->numCuts;i++)
		box->cutEList = gr_CreateENode(box->cutEList,box->cutVList,i,i,i+1,
						0,0,0,0,0,0,0);
	box->cutEList = gr_CreateENode(box->cutEList,box->cutVList,
				box->numCuts,box->numCuts,1,0,0,0,0,0,0,0);

}


/*
 * Return a Vertex node
 */
A_BoxVert_t
*gr_CreateVNode(vlist,id,x,y,z,enode)
A_BoxVert_t	*vlist;
A_BoxEdge_t *enode;
int			id;
double		x,y,z;
{
	A_BoxVert_t	*tmp;

	tmp = (A_BoxVert_t *)td_Malloc(sizeof(A_BoxVert_t),"A_BoxVert_t");
	tmp->id = id;
	tmp->enode = enode;
	tmp->x	= x;
	tmp->y	= y;
	tmp->z	= z;
	tmp->next	= vlist;
	vlist = tmp;

	return(tmp);
}


/*
 * Return an Edge node
 */
A_BoxEdge_t
*gr_CreateENode(elist,vlist,id,v1,v2,a0,a1,a2,a3,a4,a5,a6)
A_BoxEdge_t	*elist;
A_BoxVert_t	*vlist;
int			id,v1,v2;
int			a0,a1,a2,a3,a4,a5,a6;
{
	Boolean		found1=FALSE, found2=FALSE;
	A_BoxVert_t	*current = vlist;
	A_BoxEdge_t	*tmp;

	tmp = (A_BoxEdge_t *)td_Malloc(sizeof(A_BoxEdge_t),"A_BoxEdge_t");
	tmp->id = id;
	tmp->adj[0] = a0;
	tmp->adj[1] = a1;
	tmp->adj[2] = a2;
	tmp->adj[3] = a3;
	tmp->adj[4] = a4;
	tmp->adj[5] = a5;
	tmp->adj[6] = a6;
	while (((found1 == FALSE) || (found2 == FALSE)) && (current != NULL))
	{
		if (current->id == v1)
		{
			tmp->v1 = current;
			found1  = TRUE;
		}
		else
		if (current->id == v2)
		{
			tmp->v2 = current;
			found2	= TRUE;
		}
		current = current->next;
	}

	tmp->next	= elist;
	elist = tmp;

	return(tmp);
}


/*
 * Return a list of vertices
 */
A_BoxVert_t
*gr_CreateVList(xlen,ylen,zlen,xorig,yorig,zorig)
double xlen,ylen,zlen;
double *xorig,*yorig,*zorig;
{
	A_BoxVert_t	*root=NULL;
	
	*xorig = -(double)(xlen/2.0);
	*yorig = -(double)(ylen/2.0);
	*zorig = -(double)(zlen/2.0);

	root = gr_CreateVNode(root,1,*xorig,*yorig,*zorig,NULL);
	root = gr_CreateVNode(root,2,*xorig+xlen,*yorig,*zorig,NULL);
	root = gr_CreateVNode(root,3,*xorig+xlen,*yorig+ylen,*zorig,NULL);
	root = gr_CreateVNode(root,4,*xorig,*yorig+ylen,*zorig,NULL);
	root = gr_CreateVNode(root,5,*xorig,*yorig+ylen,*zorig+zlen,NULL);
	root = gr_CreateVNode(root,6,*xorig+xlen,*yorig+ylen,*zorig+zlen,NULL);
	root = gr_CreateVNode(root,7,*xorig+xlen,*yorig,*zorig+zlen,NULL);
	root = gr_CreateVNode(root,8,*xorig,*yorig,*zorig+zlen,NULL);

	return(root);
}


/*
 * Return a list of edges
 */
A_BoxEdge_t
*gr_CreateEList(vlist)
A_BoxVert_t	*vlist;
{
	A_BoxEdge_t	*root=NULL;

	root = gr_CreateENode(root,vlist, 1, 1, 2, 1, 2, 3, 4,11, 7,10);
	root = gr_CreateENode(root,vlist, 2, 2, 3, 2,11, 6,12, 1, 4, 3);
	root = gr_CreateENode(root,vlist, 3, 3, 4, 3,12, 5, 9, 2, 1, 4);
	root = gr_CreateENode(root,vlist, 4, 4, 1, 4,10, 8, 9, 1, 2, 3);
	root = gr_CreateENode(root,vlist, 5, 5, 6, 5, 6, 7, 8, 9, 3,12);
	root = gr_CreateENode(root,vlist, 6, 6, 7, 6,11, 2,12, 7, 8, 5);
	root = gr_CreateENode(root,vlist, 7, 7, 8, 7, 6, 5, 8,11, 1,10);
	root = gr_CreateENode(root,vlist, 8, 8, 5, 8, 5, 6, 7,10, 4, 9);
	root = gr_CreateENode(root,vlist, 9, 5, 4, 9, 4,10, 8, 3,12, 5);
	root = gr_CreateENode(root,vlist,10, 1, 8,10, 1,11, 7, 4, 9, 8);
	root = gr_CreateENode(root,vlist,11, 7, 2,11, 2,12, 6, 1,10, 7);
	root = gr_CreateENode(root,vlist,12, 3, 6,12, 3, 9, 5, 1,11, 6);

	return(root);
}


/*
 * Return a box
 */
A_Box_t
*gr_CreateBox(xdim,ydim,zdim)
int	xdim,ydim,zdim;
{
	int	max;
	A_Box_t	*box;

	if ((box = (A_Box_t *)td_Malloc(sizeof(A_Box_t),"A_Box_t")) == NULL)
		return(NULL);

	max = MXV_GREATER((MXV_GREATER(xdim,ydim)),zdim);

	box->dimFactor = (double)(100.0/(double)max);
	box->xdim	   = xdim;
	box->ydim	   = ydim;
	box->zdim	   = zdim;
	box->xlen	   = xdim*box->dimFactor;
	box->ylen	   = ydim*box->dimFactor;
	box->zlen	   = zdim*box->dimFactor;
	box->numCuts   = 0;
	box->depth	   = 0.0;
	box->cutVList  = NULL;
	box->cutEList  = NULL;

	box->origVList  = gr_CreateVList(box->xlen,box->ylen,box->zlen,
							&(box->xorig),&(box->yorig),&(box->zorig));
	box->vertList  = gr_CreateVList(box->xlen,box->ylen,box->zlen,
							&(box->xorig),&(box->yorig),&(box->zorig));
	box->edgeList  = gr_CreateEList(box->vertList);
	box->zmin	   = box->zorig;
	box->zmax	   = box->zorig+box->zlen;
	box->xangle	   = box->yangle = (double)0.0;
	box->depth	   = 0.0;
	box->indepth   = 0;
	box->boundxmin = box->boundxmax = 0.0;
	box->boundymin = box->boundymax = 0.0;
	box->xpicsize  = 0;
	box->ypicsize  = 0;
	box->matrix[1][1] = 1.0;
	box->matrix[1][2] = 0.0;
	box->matrix[1][3] = 0.0;
	box->matrix[1][4] = 0.0;
	box->matrix[2][1] = 0.0;
	box->matrix[2][2] = 1.0;
	box->matrix[2][3] = 0.0;
	box->matrix[2][4] = 0.0;
	box->matrix[3][1] = 0.0;
	box->matrix[3][2] = 0.0;
	box->matrix[3][3] = 1.0;
	box->matrix[3][4] = 0.0;
	box->matrix[4][1] = 0.0;
	box->matrix[4][2] = 0.0;
	box->matrix[4][3] = 0.0;
	box->matrix[4][4] = 1.0;

	return(box);
}
