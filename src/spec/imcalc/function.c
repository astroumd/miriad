#include <stdio.h>
#include <ctype.h>
#include <math.h>
#include "header.h"

VARIABLE *varmake(),*varcopy(),*evaluate();
char *Malloc();
void vardelete();
private VARIABLE *loadx_x();
/**********************************************************************/
VARIABLE *cmplx_x(a,b)
VARIABLE *a,*b;
/*
  This takes two reals and forms a complex number from them.

  Input:
    a,b		VARIABLE structures containing the real and imaginary part
		respectively.
  Output:
    cmplx_x	The resultant complex value. A NULL is returned if some
		problem is detected.
----------------------------------------------------------------------*/
{
  int ndim1,ndim2,i;
  FLOAT *f1,*f2,*c;
  VARIABLE *v;

  if(a->type != TYPE_REAL || b->type != TYPE_REAL)
    ERR_RETURN("### Arguments to \'cmplx\' must be reals\n",NULL);
  ndim1 = a->xdim * a->ydim;
  ndim2 = b->xdim * b->ydim;
  if( ndim1 != 0 && ndim2 != 0 && ndim1 != ndim2)
    ERR_RETURN("### Image args to \'cmplx\' must be of the same size\n",NULL);

/* Make the output variable. */

  v = varmake(TYPE_CMPLX,max(a->xdim,b->xdim),max(a->ydim,b->ydim));

/* Process depending on which (if any) of the args were images. */

  f1 = (FLOAT *)(a->value);
  f2 = (FLOAT *)(b->value);
  c = (FLOAT *)(v->value);
  if(ndim1 == 0 && ndim2 == 0){
    v->val[0] = a->val[0];
    v->val[1] = b->val[0];
  } else if(ndim1 == ndim2){
    for(i=0; i < ndim1; i++){
      *c++ = *f1++;
      *c++ = *f2++;
    }
  } else if(ndim1 != 0){
    for(i=0; i < ndim1; i++){
      *c++ = *f1++;
      *c++ = b->val[0];
    }
  } else {
    for(i=0; i < ndim2; i++){
      *c++ = a->val[0];
      *c++ = *f2++;
    }
  }
  return(v);
}
/**********************************************************************/
VARIABLE *add_x(a,b)
VARIABLE *a,*b;
/*
  This adds together two variables. The variables may be real, complex
  or integer pairs.

  Input:
    a,b		VARIABLE structures of the variables to add.
  Output:
    add_x	A VARIABLE structure of the result.
----------------------------------------------------------------------*/
{
  int i,ndim1,ndim2;
  VARIABLE *v;
  FLOAT *fa,*fb,*fv;

  ndim1 = a->xdim * a->ydim; ndim2 = b->xdim * b->ydim;
  if( ndim1 > 0 && ndim2 > 0 && ndim1 != ndim2)
    ERR_RETURN("### Attempt to \'add\' images of different sizes\n",NULL);

/* Case of both integer pairs. */

  if(a->type == TYPE_COORD && b->type == TYPE_COORD){
    v = varmake(TYPE_COORD,0,0);
    v->val[0] = a->val[0] + b->val[0];
    v->val[1] = a->val[1] + b->val[1];

/* Case of both real args. */

  } else if(a->type == TYPE_REAL && b->type == TYPE_REAL){
    v = varmake(TYPE_REAL,max(a->xdim,b->xdim),max(a->ydim,b->ydim));
    fv = (FLOAT *)(v->value); fa = (FLOAT *)(a->value); fb = (FLOAT *)(b->value);
    if(ndim1 == 0 && ndim2 == 0)
      v->val[0] = a->val[0] + b->val[0];
    else if(ndim1 != 0 && ndim2 != 0)
      for(i=0; i < ndim1; i++) *fv++ = *fa++ + *fb++;
    else if(ndim1 == 0)
      for(i=0; i < ndim2; i++) *fv++ = a->val[0] + *fb++;
    else
      for(i=0; i < ndim1; i++) *fv++ = *fa++ + b->val[0];

/* Case of both complex args. */

  } else if(a->type == TYPE_CMPLX && b->type == TYPE_CMPLX){
    v = varmake(TYPE_CMPLX,max(a->xdim,b->xdim),max(a->ydim,b->ydim));
    fv = (FLOAT *)(v->value); fa = (FLOAT *)(a->value); fb = (FLOAT *)(b->value);
    if(ndim1 == 0 && ndim2 == 0){
      v->val[0] = a->val[0] + b->val[0];
      v->val[1] = a->val[1] + b->val[1];
    } else if(ndim1 != 0 && ndim2 != 0){
      for(i=0; i < 2*ndim1; i++) *fv++ = *fa++ + *fb++;
    } else if(ndim1 == 0){
      for(i=0; i < ndim2; i++){
	*fv++ = a->val[0] + *fb++;
	*fv++ = a->val[1] + *fb++;
      }
    } else {
      for(i=0; i < ndim1; i++){
	*fv++ = *fa++ + b->val[0];
	*fv++ = *fa++ + b->val[1];
      }
    }

/* Case of a real and a complex arg. */

  } else if(a->type == TYPE_REAL && b->type == TYPE_CMPLX){
    v = varmake(TYPE_CMPLX,max(a->xdim,b->xdim),max(a->ydim,b->ydim));
    fv = (FLOAT *)(v->value); fa = (FLOAT *)(a->value); fb = (FLOAT *)(b->value);
    if(ndim1 == 0 && ndim2 == 0){
      v->val[0] = a->val[0] + b->val[0];
      v->val[1] = b->val[1];
    } else if(ndim1 != 0 && ndim2 != 0){
      for(i=0; i < ndim1; i++){
	*fv++ = *fa++ + *fb++;
	*fv++ = *fb++;
      }
    } else if(ndim1 == 0) {
      for(i=0; i < ndim2; i++){
	*fv++ = a->val[0] + *fb++;
	*fv++ = *fb++;
      }
    } else {
      for(i=0; i < ndim1; i++){
	*fv++ = *fa++ + b->val[0];
	*fv++ = b->val[1];
      }
    }

/* Case of a complex and real argument. */

  } else if(a->type == TYPE_CMPLX && b->type == TYPE_REAL){
    v = varmake(TYPE_CMPLX,max(a->xdim,b->xdim),max(a->ydim,b->ydim));
    fv = (FLOAT *)(v->value); fa = (FLOAT *)(a->value); fb = (FLOAT *)(b->value);
    if(ndim1 == 0 && ndim2 == 0){
      v->val[0] = a->val[0] + b->val[0];
      v->val[1] = a->val[1];
    } else if(ndim1 != 0 && ndim2 != 0){
      for(i=0; i < ndim1; i++){
	*fv++ = *fa++ + *fb++;
	*fv++ = *fa++;
      }
    } else if(ndim1 == 0) {
      for(i=0; i < ndim2; i++){
	*fv++ = a->val[0] + *fb++;
	*fv++ = a->val[1];
      }
    } else {
      for(i=0; i < ndim1; i++){
	*fv++ = *fa++ + b->val[0];
	*fv++ = *fa++;
      }
    }

/* Anything else is illegal. */

  } else {
    v = NULL;
    fprintf(stderr,"### Incorrect data types when adding two values\n");
  }
  return(v);
}
/**********************************************************************/
VARIABLE *sub_x(a,b)
VARIABLE *a,*b;
/*
  This subtractsb two variables. The variables may be real, complex
  or integer pairs.

  Input:
    a,b		VARIABLE structures of the variables to subtract.
  Output:
    sub_x	A VARIABLE structure of the result.
----------------------------------------------------------------------*/
{
  int i,ndim1,ndim2;
  VARIABLE *v;
  FLOAT *fa,*fb,*fv;

  ndim1 = a->xdim * a->ydim; ndim2 = b->xdim * b->ydim;
  if( ndim1 > 0 && ndim2 > 0 && ndim1 != ndim2)
    ERR_RETURN("### Attempt to \'subtract\' images of different sizes\n",NULL);

/* Case of both integer pairs. */

  if(a->type == TYPE_COORD && b->type == TYPE_COORD){
    v = varmake(TYPE_COORD,0,0);
    v->val[0] = a->val[0] - b->val[0];
    v->val[1] = a->val[1] - b->val[1];

/* Case of both real args. */

  } else if(a->type == TYPE_REAL && b->type == TYPE_REAL){
    v = varmake(TYPE_REAL,max(a->xdim,b->xdim),max(a->ydim,b->ydim));
    fv = (FLOAT *)(v->value); fa = (FLOAT *)(a->value); fb = (FLOAT *)(b->value);
    if(ndim1 == 0 && ndim2 == 0)
      v->val[0] = a->val[0] - b->val[0];
    else if(ndim1 != 0 && ndim2 != 0)
      for(i=0; i < ndim1; i++) *fv++ = *fa++ - *fb++;
    else if(ndim1 == 0)
      for(i=0; i < ndim2; i++) *fv++ = a->val[0] - *fb++;
    else
      for(i=0; i < ndim1; i++) *fv++ = *fa++ - b->val[0];

/* Case of both complex args. */

  } else if(a->type == TYPE_CMPLX && b->type == TYPE_CMPLX){
    v = varmake(TYPE_CMPLX,max(a->xdim,b->xdim),max(a->ydim,b->ydim));
    fv = (FLOAT *)(v->value); fa = (FLOAT *)(a->value); fb = (FLOAT *)(b->value);
    if(ndim1 == 0 && ndim2 == 0){
      v->val[0] = a->val[0] - b->val[0];
      v->val[1] = a->val[1] - b->val[1];
    } else if(ndim1 != 0 && ndim2 != 0){
      for(i=0; i < 2*ndim1; i++) *fv++ = *fa++ - *fb++;
    } else if(ndim1 == 0){
      for(i=0; i < ndim2; i++){
	*fv++ = a->val[0] - *fb++;
	*fv++ = a->val[1] - *fb++;
      }
    } else {
      for(i=0; i < ndim1; i++){
	*fv++ = *fa++ - b->val[0];
	*fv++ = *fa++ - b->val[1];
      }
    }

/* Case of a real and a complex arg. */

  } else if(a->type == TYPE_REAL && b->type == TYPE_CMPLX){
    v = varmake(TYPE_CMPLX,max(a->xdim,b->xdim),max(a->ydim,b->ydim));
    fv = (FLOAT *)(v->value); fa = (FLOAT *)(a->value); fb = (FLOAT *)(b->value);
    if(ndim1 == 0 && ndim2 == 0){
      v->val[0] = a->val[0] - b->val[0];
      v->val[1] = - b->val[1];
    } else if(ndim1 != 0 && ndim2 != 0){
      for(i=0; i < ndim1; i++){
	*fv++ = *fa++ - *fb++;
	*fv++ = - *fb++;
      }
    } else if(ndim1 == 0) {
      for(i=0; i < ndim2; i++){
	*fv++ = a->val[0] - *fb++;
	*fv++ = - *fb++;
      }
    } else {
      for(i=0; i < ndim1; i++){
	*fv++ = *fa++ - b->val[0];
	*fv++ = - b->val[1];
      }
    }

/* Case of a complex and real argument. */

  } else if(a->type == TYPE_CMPLX && b->type == TYPE_REAL){
    v = varmake(TYPE_CMPLX,max(a->xdim,b->xdim),max(a->ydim,b->ydim));
    fv = (FLOAT *)(v->value); fa = (FLOAT *)(a->value); fb = (FLOAT *)(b->value);
    if(ndim1 == 0 && ndim2 == 0){
      v->val[0] = a->val[0] - b->val[0];
      v->val[1] = a->val[1];
    } else if(ndim1 != 0 && ndim2 != 0){
      for(i=0; i < ndim1; i++){
	*fv++ = *fa++ - *fb++;
	*fv++ = *fa++;
      }
    } else if(ndim1 == 0) {
      for(i=0; i < ndim2; i++){
	*fv++ = a->val[0] - *fb++;
	*fv++ = a->val[1];
      }
    } else {
      for(i=0; i < ndim1; i++){
	*fv++ = *fa++ - b->val[0];
	*fv++ = *fa++;
      }
    }

/* Anything else is illegal. */

  } else {
    v = NULL;
    fprintf(stderr,"### Incorrect data types when subtracting two values\n");
  }
  return(v);
}
/**********************************************************************/
VARIABLE *mult_x(a,b)
VARIABLE *a,*b;
/*
  This multiplies together two variables. The variables may be real, complex
  or integer pairs.

  Input:
    a,b		VARIABLE structures of the variables to multiplied.
  Output:
    mult_x	A VARIABLE structure of the result.
----------------------------------------------------------------------*/
{
  int i,ndim1,ndim2;
  VARIABLE *v;
  FLOAT *fa,*fb,*fv;

  ndim1 = a->xdim * a->ydim; ndim2 = b->xdim * b->ydim;
  if( ndim1 > 0 && ndim2 > 0 && ndim1 != ndim2)
    ERR_RETURN("### Attempt to \'multiply\' images of different sizes\n",NULL);

/* Case of both integer pairs. */

  if(a->type == TYPE_COORD && b->type == TYPE_COORD){
    v = varmake(TYPE_COORD,0,0);
    v->val[0] = a->val[0] * b->val[0];
    v->val[1] = a->val[1] * b->val[1];

/* Case of both real args. */

  } else if(a->type == TYPE_REAL && b->type == TYPE_REAL){
    v = varmake(TYPE_REAL,max(a->xdim,b->xdim),max(a->ydim,b->ydim));
    fv = (FLOAT *)(v->value); fa = (FLOAT *)(a->value); fb = (FLOAT *)(b->value);
    if(ndim1 == 0 && ndim2 == 0)
      v->val[0] = a->val[0] * b->val[0];
    else if(ndim1 != 0 && ndim2 != 0)
      for(i=0; i < ndim1; i++) *fv++ = *fa++ * *fb++;
    else if(ndim1 == 0)
      for(i=0; i < ndim2; i++) *fv++ = a->val[0] * *fb++;
    else
      for(i=0; i < ndim1; i++) *fv++ = *fa++ * b->val[0];

/* Case of both complex args. */

  } else if(a->type == TYPE_CMPLX && b->type == TYPE_CMPLX){
    v = varmake(TYPE_CMPLX,max(a->xdim,b->xdim),max(a->ydim,b->ydim));
    fv = (FLOAT *)(v->value); fa = (FLOAT *)(a->value); fb = (FLOAT *)(b->value);
    if(ndim1 == 0 && ndim2 == 0){
      v->val[0] = a->val[0]*b->val[0] - a->val[1]*b->val[1];
      v->val[1] = a->val[1]*b->val[0] + a->val[0]*b->val[1];
    } else if(ndim1 != 0 && ndim2 != 0){
      for(i=0; i < ndim1; i++){
	*fv++ = *fa * *fb - *(fa+1) * *(fb+1);
	*fv++ = *(fa+1) * *fb + *fa * *(fb+1);
	fa += 2; fb += 2;
      }
    } else if(ndim1 == 0){
      for(i=0; i < ndim2; i++){
	*fv++ = a->val[0] * *fb - a->val[1] * *(fb+1);
	*fv++ = a->val[1] * *fb + a->val[0] * *(fb+1);
	fb += 2;
      }
    } else {
      for(i=0; i < ndim1; i++){
	*fv++ = *fa * b->val[0] - *(fa+1) * b->val[1];
	*fv++ = *(fa+1) * b->val[0] + *fa * b->val[1];
	fa += 2;
      }
    }

/* Case of a real and a complex arg. */

  } else if(a->type == TYPE_REAL && b->type == TYPE_CMPLX){
    v = varmake(TYPE_CMPLX,max(a->xdim,b->xdim),max(a->ydim,b->ydim));
    fv = (FLOAT *)(v->value); fa = (FLOAT *)(a->value); fb = (FLOAT *)(b->value);
    if(ndim1 == 0 && ndim2 == 0){
      v->val[0] = a->val[0] * b->val[0];
      v->val[1] = a->val[0] * b->val[1];
    } else if(ndim1 != 0 && ndim2 != 0){
      for(i=0; i < ndim1; i++){
	*fv++ = *fa   * *fb++;
	*fv++ = *fa++ * *fb++;
      }
    } else if(ndim1 == 0) {
      for(i=0; i < ndim2; i++){
	*fv++ = a->val[0] * *fb++;
	*fv++ = a->val[0] * *fb++;
      }
    } else {
      for(i=0; i < ndim1; i++){
	*fv++ = *fa   * b->val[0];
	*fv++ = *fa++ * b->val[1];
      }
    }

/* Case of a complex and real argument. */

  } else if(a->type == TYPE_CMPLX && b->type == TYPE_REAL){
    v = varmake(TYPE_CMPLX,max(a->xdim,b->xdim),max(a->ydim,b->ydim));
    fv = (FLOAT *)(v->value); fa = (FLOAT *)(a->value); fb = (FLOAT *)(b->value);
    if(ndim1 == 0 && ndim2 == 0){
      v->val[0] = a->val[0] * b->val[0];
      v->val[1] = a->val[1] * b->val[0];
    } else if(ndim1 != 0 && ndim2 != 0){
      for(i=0; i < ndim1; i++){
	*fv++ = *fa++ * *fb;
	*fv++ = *fa++ * *fb++;
      }
    } else if(ndim1 == 0) {
      for(i=0; i < ndim2; i++){
	*fv++ = a->val[0] * *fb;
	*fv++ = a->val[1] * *fb++;
      }
    } else {
      for(i=0; i < ndim1; i++){
	*fv++ = *fa++ * b->val[0];
	*fv++ = *fa++ * b->val[0];
      }
    }

/* Anything else is illegal. */

  } else {
    v = NULL;
    fprintf(stderr,"### Incorrect data types when multiplying two values\n");
  }
  return(v);
}
/**********************************************************************/
VARIABLE *div_x(a,b)
VARIABLE *a,*b;
/*
  This divides two variables. The variables may be real, complex
  or integer pairs.

  Input:
    a,b		VARIABLE structures of the variables to divide.
  Output:
    div_x	A VARIABLE structure of the result.
----------------------------------------------------------------------*/
{
  int i,ndim1,ndim2;
  VARIABLE *v;
  FLOAT *fa,*fb,*fv;
  FLOAT t,t1,t2;

  ndim1 = a->xdim * a->ydim; ndim2 = b->xdim * b->ydim;
  if( ndim1 > 0 && ndim2 > 0 && ndim1 != ndim2)
    ERR_RETURN("### Attempt to \'divide\' images of different sizes\n",NULL);

/* Case of both integer pairs. */

  if(a->type == TYPE_COORD && b->type == TYPE_COORD){
    v = varmake(TYPE_COORD,0,0);
    v->val[0] = a->val[0] / b->val[0];
    v->val[1] = a->val[1] / b->val[1];

/* Case of both real args. */

  } else if(a->type == TYPE_REAL && b->type == TYPE_REAL){
    v = varmake(TYPE_REAL,max(a->xdim,b->xdim),max(a->ydim,b->ydim));
    fv = (FLOAT *)(v->value); fa = (FLOAT *)(a->value); fb = (FLOAT *)(b->value);
    if(ndim1 == 0 && ndim2 == 0)
      v->val[0] = a->val[0] / b->val[0];
    else if(ndim1 != 0 && ndim2 != 0)
      for(i=0; i < ndim1; i++) *fv++ = *fa++ / *fb++;
    else if(ndim1 == 0)
      for(i=0; i < ndim2; i++) *fv++ = a->val[0] / *fb++;
    else
      for(i=0; i < ndim1; i++) *fv++ = *fa++ / b->val[0];

/* Case of both complex args. */

  } else if(a->type == TYPE_CMPLX && b->type == TYPE_CMPLX){
    v = varmake(TYPE_CMPLX,max(a->xdim,b->xdim),max(a->ydim,b->ydim));
    fv = (FLOAT *)(v->value); fa = (FLOAT *)(a->value); fb = (FLOAT *)(b->value);
    if(ndim1 == 0 && ndim2 == 0){
      t = 1/(b->val[0]*b->val[0] + b->val[1]*b->val[1]);
      v->val[0] = t*(a->val[0]*b->val[0] + a->val[1]*b->val[1]);
      v->val[1] = t*(a->val[1]*b->val[0] - a->val[0]*b->val[1]);
    } else if(ndim1 != 0 && ndim2 != 0){
      for(i=0; i < ndim1; i++){
	t = 1/(*fb * *fb + *(fb+1) * *(fb+1));
	*fv++ = t*(*fa * *fb + *(fa+1) * *(fb+1));
	*fv++ = t*(*(fa+1) * *fb - *fa * *(fb+1));
	fa += 2; fb += 2;
      }
    } else if(ndim1 == 0){
      for(i=0; i < ndim2; i++){
	t = 1/(*fb * *fb + *(fb+1) * *(fb+1));
	*fv++ = t*(a->val[0] * *fb + a->val[1] * *(fb+1));
	*fv++ = t*(a->val[1] * *fb - a->val[0] * *(fb+1));
	fb += 2;
      }
    } else {
      t = 1/(b->val[0]*b->val[0] + b->val[1]*b->val[1]);
      t1 = t * b->val[0];
      t2 = t * b->val[1];
      for(i=0; i < ndim1; i++){
	*fv++ = *fa * t1 + *(fa+1) * t2;
	*fv++ = *(fa+1) * t1 - *fa * t2;
	fa += 2;
      }
    }

/* Case of a real and a complex arg. */

  } else if(a->type == TYPE_REAL && b->type == TYPE_CMPLX){
    v = varmake(TYPE_CMPLX,max(a->xdim,b->xdim),max(a->ydim,b->ydim));
    fv = (FLOAT *)(v->value); fa = (FLOAT *)(a->value); fb = (FLOAT *)(b->value);
    if(ndim1 == 0 && ndim2 == 0){
      t = a->val[0] / (b->val[0]*b->val[0] + b->val[1]*b->val[1]);
      v->val[0] =  t * b->val[0];
      v->val[1] = -t * b->val[1];
    } else if(ndim1 != 0 && ndim2 != 0){
      for(i=0; i < ndim1; i++){
	t = *fa++ / (*fb * *fb + *(fb+1) * *(fb+1));
	*fv++ =  t * *fb++;
	*fv++ = -t * *fb++;
      }
    } else if(ndim1 == 0) {
      for(i=0; i < ndim2; i++){
	t = a->val[0] / (*fb * *fb + *(fb+1) * *(fb+1));
	*fv++ =  t * *fb++;
	*fv++ = -t * *fb++;
      }
    } else {
      t = 1/(b->val[0]*b->val[0] + b->val[1]*b->val[1]);
      t1 =  t * b->val[0];
      t2 = -t * b->val[1];
      for(i=0; i < ndim1; i++){
	*fv++ = *fa * t1;
	*fv++ = *fa++ * t2;
      }
    }

/* Case of a complex and real argument. */

  } else if(a->type == TYPE_CMPLX && b->type == TYPE_REAL){
    v = varmake(TYPE_CMPLX,max(a->xdim,b->xdim),max(a->ydim,b->ydim));
    fv = (FLOAT *)(v->value); fa = (FLOAT *)(a->value); fb = (FLOAT *)(b->value);
    if(ndim1 == 0 && ndim2 == 0){
      v->val[0] = a->val[0] / b->val[0];
      v->val[1] = a->val[1] / b->val[0];
    } else if(ndim1 != 0 && ndim2 != 0){
      for(i=0; i < ndim1; i++){
	*fv++ = *fa++ / *fb;
	*fv++ = *fa++ / *fb++;
      }
    } else if(ndim1 == 0) {
      for(i=0; i < ndim2; i++){
	*fv++ = a->val[0] / *fb;
	*fv++ = a->val[1] / *fb++;
      }
    } else {
      for(i=0; i < ndim1; i++){
	*fv++ = *fa++ / b->val[0];
	*fv++ = *fa++ / b->val[0];
      }
    }

/* Anything else is illegal. */

  } else {
    v = NULL;
    fprintf(stderr,"### Incorrect data types when dividing two values\n");
  }
  return(v);
}
/**********************************************************************/
VARIABLE *shift_x(a,b)
VARIABLE *a,*b;
/*
  This performs a cyclic shift, to the right, on an image. If, for example, you
  perform a shift of [1,1] on an image, the pixel [i,j] in the input
  becomes pixel [i+1,j+1] in the output.

  Input:
    a		A VARIABLE structure which must be an image.
    b		A VARIABLE structure which must be a coordinate pair.
  Output:
    shift_x	The VARIABLE structure of the shifted image.
----------------------------------------------------------------------*/
{
  int i,j,xshift,yshift,xdim,ydim;
  FLOAT *in1,*in2,*out;
  VARIABLE *v;

  if( ( a->type != TYPE_REAL && a->type != TYPE_CMPLX ) ||
      (a->xdim * a->ydim == 0) )
    ERR_RETURN("### The first arg of a shift operation must be an image\n",NULL);
  if(b->type != TYPE_COORD)
    ERR_RETURN("### The second arg of a shift operation must be an integer pair\n",NULL);

/* Determine the shift to apply. */

  xshift = b->val[0];
  xshift %= a->xdim;
  if(xshift < 0) xshift += a->xdim;
  yshift = b->val[1];
  yshift %= a->ydim;
  if(yshift < 0) yshift += a->ydim;

/* If there is no shift to be performed, take some short cuts. */

  if(xshift == 0 && yshift == 0){
    if(a->temporary){
      v = varmake(a->type,0,0);
      v->value = a->value;
      a->value = NULL;
      v->xdim = a->xdim;
      v->ydim = a->ydim;
    } else v = a;

/* The case where we cannot use a short cut. */

  } else {
    v = varmake(a->type,a->xdim,a->ydim);
    out = (FLOAT *)(v->value);
    if(v->type == TYPE_REAL){
      xdim = v->xdim; ydim = v->ydim;
    } else {
      xdim = 2*v->xdim; ydim = v->ydim;
      xshift += xshift;
    }
    in1 = (FLOAT *)(a->value) + (ydim - yshift) * xdim;
    for(j=0; j < yshift; j++){
      in2 = in1 + xdim - xshift;
      for(i=0; i < xshift; i++) *out++ = *in2 ++;
      in2 = in1;
      for(i=xshift; i < xdim; i++) *out++ = *in2++;
      in1 += v->xdim;
    }
    in1 = (FLOAT *)(a->value);
    for(j=yshift; j < ydim; j++){
      in2 = in1 + xdim - xshift;
      for(i=0; i < xshift; i++) *out++ = *in2 ++;
      in2 = in1;
      for(i=xshift; i < v->xdim; i++) *out++ = *in2++;
      in1 += xdim;
    }
  }
  return(v);
}
/**********************************************************************/
VARIABLE *coord_x(a,b)
VARIABLE *a,*b;
/*
  This takes two real numbers, and forms a coordinate out of them.
  Most of its job is error checking.
----------------------------------------------------------------------*/
{
  VARIABLE *v;
  if(a->type != TYPE_REAL || a->xdim * a->ydim != 0 ||
     b->type != TYPE_REAL || b->xdim * b->ydim != 0 )
    ERR_RETURN("### Coordinate pairs must be made of integers\n",NULL);
  v = varmake(TYPE_COORD,0,0);
  v->val[0] = a->val[0];
  v->val[1] = b->val[0];
  return(v);
}
/**********************************************************************/
VARIABLE *concat_x(a,b)
VARIABLE *a,*b;
/*
----------------------------------------------------------------------*/
{
  VARIABLE *v;
  int length;
  if(a->type != TYPE_STRING || b->type != TYPE_STRING)
    ERR_RETURN("### Only strings can be concatenated\n",NULL);
  v = varmake(TYPE_STRING,0,0);
  length = strlen(a->value) + strlen(b->value) + 1;
  v->value = Malloc(length*sizeof(char));
  strcpy(v->value,a->value);
  strcat(v->value,b->value);
  return(v);
}
/**********************************************************************/
VARIABLE *convolve_x(a,b)
VARIABLE *a,*b;
/*
----------------------------------------------------------------------*/
{
  int ndim1,ndim2;
  VARIABLE *v;

  ndim1 = a->xdim * a->ydim;
  ndim2 = b->xdim * b->ydim;
  if(ndim1 == 0 || ndim2 == 0 ||
     a->type != TYPE_REAL || b->type != TYPE_REAL)
    ERR_RETURN("### Function \'convolve\' works on real images only\n",NULL);
  v = varmake(TYPE_REAL,a->xdim+b->xdim-1,a->ydim+b->ydim-1);
  if(ndim1 > ndim2)
    convl((FLOAT *)(a->value),a->xdim,a->ydim,(FLOAT *)(b->value),b->xdim,b->ydim,(FLOAT *)(v->value));
  else
    convl((FLOAT *)(b->value),b->xdim,b->ydim,(FLOAT *)(a->value),a->xdim,a->ydim,(FLOAT *)(v->value));
  return(v);
}
/**********************************************************************/
VARIABLE *dims_x(a)
VARIABLE *a;
/*
  This returns an integer-pair, which gives the dimensions of an image.
----------------------------------------------------------------------*/
{
  VARIABLE *v;

  if(a->type != TYPE_REAL && a->type != TYPE_CMPLX)
    ERR_RETURN("### Arg to \'dims\' must be an image\n",NULL);
  if( a->xdim * a->ydim == 0)
    ERR_RETURN("### Arg to \'dims\' must be an image\n",NULL);
  v = varmake(TYPE_COORD,0,0);
  v->val[0] = a->xdim;
  v->val[1] = a->ydim;
  return(v);
}
/**********************************************************************/
VARIABLE *extract_x(a,b)
VARIABLE *a,*b;
/*
----------------------------------------------------------------------*/
{
  int offset;
  VARIABLE *v;

  if((a->type != TYPE_REAL && a->type != TYPE_CMPLX) ||
     a->xdim * a->ydim == 0 || b->type != TYPE_COORD)
    ERR_RETURN("### Args to extract function must be an image and coord pair\n",NULL);
  if(b->val[0] < 1 || b->val[0] > a->xdim ||
     b->val[1] < 1 || b->val[1] > a->ydim )
    ERR_RETURN("### Extraction operation violates array bounds\n",NULL);

  v = varmake(a->type,0,0);
  offset = b->val[0] - 1 + ((b->val[1]-1) * a->xdim);
  if(a->type == TYPE_REAL){
    v->val[0] = *((FLOAT *)(a->value) + offset);
  } else {
    v->val[0] = *((FLOAT *)(a->value) + 2*offset);
    v->val[1] = *((FLOAT *)(a->value) + 2*offset + 1);
  }
  return(v);
}
/**********************************************************************/
VARIABLE *fft_x(a,b)
VARIABLE *a,*b;
/*
  This performs the overall FFT operation.

  Inputs:
    a             The image to be transformed. This must be a power of
                  2 along each dimension, and the phase centre is taken
                  as N/2+1. The output also has the phase centre at
                  N/2+1. The image may be real or complex valued.
    b             The sign of the transform, either -1 or +1. If it is
                  +1, 1/N scaling is performed.
----------------------------------------------------------------------*/
{
  int ndim1,ndim2,k,sign,i;
  FLOAT temp,*f;
  VARIABLE *v;

/* Do a number of checks to see that everything is OK. */

  ndim1 = a->xdim * a->ydim;
  ndim2 = b->xdim * b->ydim;
  if(ndim1 <= 0 || (a->type != TYPE_REAL && a->type != TYPE_CMPLX))
    ERR_RETURN("### The first arg of \'fft\' must be an image\n",NULL);
  if(ndim2 != 0 || b->type != TYPE_REAL)
    ERR_RETURN("### The second arg of \'fft\' must be the sign of the transform\n",NULL);
  sign = b->val[0];
  if(sign != 1 && sign != -1)
    ERR_RETURN("### The second arg of \'fft\' must be 1 or -1\n",NULL);
  k = 2;
  while(k < ndim1)k += k;
  if(k != ndim1)
    ERR_RETURN("### \'fft\' can only handle images which are a power of 2\n",NULL);

/* If its a real image, the transform is never in place (the output is always
   the full complex array. If it is a complex image, the transform is in
   place if the input is a temporary variable. */

  if(a->type == TYPE_REAL){
    v = varmake(TYPE_CMPLX,a->xdim,a->ydim);
    memcpy(v->value,a->value,sizeof(FLOAT)*ndim1);
  } else if(!a->temporary)
    v = varcopy(NULL,a);
  else{
    v = varmake(TYPE_CMPLX,0,0);
    v->value = a->value;
    a->value = NULL;
    v->xdim = a->xdim; v->ydim = a->ydim;
  }

/* Now call the appropriate routine. */

  if(a->type == TYPE_REAL)
    imfft_r((FLOAT *)(v->value),v->xdim,v->ydim,sign);
  else
    imfft_c((FLOAT *)(v->value),v->xdim,v->ydim,sign);

/* Do 1/N scaling if appropriate. */

  if(sign == 1){
    temp = 1.0/ndim1;
    ndim1 += ndim1;
    f = (FLOAT *)(v->value);
    for(i=0; i < ndim1; i++) *f++ *= temp;
  }

/* All done. Return with the goodies. */

  return(v);
}
/**********************************************************************/
VARIABLE *ismax_x(a)
VARIABLE *a;
/*
----------------------------------------------------------------------*/
{
  VARIABLE *v;
  int i,imax,ndim;
  FLOAT maxi,*f;

  ndim = a->xdim * a->ydim;
  if(a->type != TYPE_REAL || ndim == 0)
    ERR_RETURN("### Argument to ismax must be a real image\n",NULL);
  f = (FLOAT *)(a->value);
  imax = 0; maxi = *f;
  for(i=0; i < ndim; i++){
    if( *f > maxi){
      imax = i;
      maxi = *f;
    }
    f++;
  }
  v = varmake(TYPE_COORD,0,0);
  v->val[0] = imax % a->xdim + 1;
  v->val[1] = imax / a->xdim + 1;
  return(v);  
}
/**********************************************************************/
VARIABLE *ismin_x(a)
VARIABLE *a;
/*
----------------------------------------------------------------------*/
{
  VARIABLE *v;
  int i,imin,ndim;
  FLOAT mini,*f;

  ndim = a->xdim * a->ydim;
  if(a->type != TYPE_REAL || ndim == 0)
    ERR_RETURN("### Argument to ismin must be a real image\n",NULL);
  f = (FLOAT *)(a->value);
  imin = 0; mini = *f;
  for(i=0; i < ndim; i++){
    if( *f < mini){
      imin = i;
      mini = *f;
    }
    f++;
  }
  v = varmake(TYPE_COORD,0,0);
  v->val[0] = imin % a->xdim + 1;
  v->val[1] = imin / a->xdim + 1;
  return(v);  
}
/**********************************************************************/
VARIABLE *loadr_x(a,b) VARIABLE *a,*b; {return(loadx_x(a,b,TYPE_REAL));}
VARIABLE *loadc_x(a,b) VARIABLE *a,*b; {return(loadx_x(a,b,TYPE_CMPLX));}
/**********************************************************************/
private VARIABLE *loadx_x(a,b,type)
VARIABLE *a,*b;
int type;
/*
  This loads in an image from an ascii file. Either real or complex
  files can be handled.

  Inputs:
    a		A string VARIABLE giving the name of the file.
    b		A coordinate VARIABLE giving the size of the image.
    type	Either TYPE_REAL or TYPE_CMPLX.
  Output:
    loadx_x	A VARIABLE containing the image.
----------------------------------------------------------------------*/
{
  VARIABLE *v;
  int xdim,ydim,ndim,n;
  FILE *fd;
  FLOAT *f;
  double d;
  char line[MAXLINE],*s,*t;

  if(a->type != TYPE_STRING || b->type != TYPE_COORD)
    ERR_RETURN("### Arguments to \'loada\' should be a string and integer pair\n",NULL);
  xdim = b->val[0];
  ydim = b->val[1];
  if( xdim <= 0 || ydim <= 0)
    ERR_RETURN("### Bad image size for a \'load\' function\n",NULL);
  
/* Open the input file. */

  fd = fopen(a->value,"r");
  if(fd == NULL)
    ERR_RETURN("### Failed to open the ascii file, in \'loada\'\n",NULL);

/* Create the output variable. */

  v = varmake(type,xdim,ydim);

/* Now read through the file, decoding the numbers it contains. */

  f = (FLOAT *)(v->value);
  ndim = xdim * ydim * ( type == TYPE_REAL ? 1 : 2);
  n = 0;
  while(n < ndim){

/* Get a line. */
    if(fgets(line,MAXLINE,fd) == NULL){
      fclose(fd);
      vardelete(v);
      fprintf(stderr,"### \'loada\' read %d values before an i/o error occurred\n",n);
      return(NULL);
    }
/* Decode the line. */
    s = line;
    SKIP_WHITE(s);
    while(*s != 0 && *s != '#'){
      t = s;
      while(*s != '\n' && *s != ' ' && *s != '\t' && *s != '#' && *s != 0)s++;
      if(*s != 0 && *s != '#'){
	*s++ = 0;
	SKIP_WHITE(s);
      } else *s = 0;
      if(sscanf(t,"%lg",&d) != 1){
	fclose(fd);
	vardelete(v);
	fprintf(stderr,"### Error decoding value %s in \'loada\'\n",t);
	return(NULL);
      } else *f++ = d;
      n++;
    }
  }
  fclose(fd);
  return(v);
}
/**********************************************************************/
VARIABLE *load_x(a)
VARIABLE *a;
/*
  This reads in a FITS file. Currently only a real file can be
  handled.

  Inputs:
    a		A string VARIABLE structure, giving the name of the
		file to be read.
  Output:
    load_x	A VARIABLE structure of a real image (or NULL if an
		error occurred).
----------------------------------------------------------------------*/
{
  char *f;
  FLOAT *dat;
  VARIABLE *v;
  int nsize[3],j,k,type;
  char *fitopen();

  if(a->type != TYPE_STRING)
    ERR_RETURN("### Argument to \'load\' must be a string giving a FITS filename\n",NULL);
  f = fitopen(a->value,"old",3,nsize);  
  if(f == NULL) return(NULL);
  if(nsize[0] == 2) v = varmake(TYPE_CMPLX,nsize[1],nsize[2]);
  else if(nsize[2] != 1){
    fitclose(f);
    ERR_RETURN("### Cannot handle three dimensional images\n",NULL);
  } else	    v = varmake(TYPE_REAL,nsize[0],nsize[1]);

  dat = (FLOAT*)(v->value);
  for(k = 0; k < nsize[2]; k++){
    fitsetpl(f,1,&k);
    for(j = 0; j < nsize[1]; j++){
      fitread(f,j,dat);
      dat += nsize[0];
    }
  }
  fitclose(f);
  return(v);
}
/**********************************************************************/
VARIABLE *read_x(a)
VARIABLE *a;
/*
----------------------------------------------------------------------*/
{
  char line[MAXLINE];
  VARIABLE *evaluate();
  if(a->type != TYPE_STRING)
    ERR_RETURN("### Argument to read must be a prompt string\n",NULL);
  printf("%s ",a->value);
  if(gets(line) == NULL) ERR_RETURN("### Error reading value\n",NULL);
  return(evaluate(line));
}
/**********************************************************************/
VARIABLE *sum_x(a)
VARIABLE *a;
/*
  This finds the sum of an image.
----------------------------------------------------------------------*/
{
  VARIABLE *v;
  int i,ndim;
  FLOAT tmp1,tmp2,*f;

  ndim = a->xdim * a->ydim;
  if((a->type != TYPE_REAL && a->type != TYPE_CMPLX) || ndim == 0)
    ERR_RETURN("### Argument to sum must be an image\n",NULL);
  v = varmake(a->type,0,0);
  tmp1 = tmp2 = 0;
  f = (FLOAT *)(a->value);
  if(a->type == TYPE_REAL){
    for(i=0; i < ndim; i++) tmp1 += *f++;
    v->val[0] = tmp1;
  } else {
    for(i=0; i < ndim; i++){ tmp1 += *f++; tmp2 += *f++; }
    v->val[0] = tmp1;
    v->val[1] = tmp2;
  }
  return(v);
}
/**********************************************************************/
int abs_c(a,b) FLOAT a[2],*b; { *b = hypot(a[0],a[1]); }
int aimag_c(a,b) FLOAT a[2],*b; { *b = a[1]; }
int arg_c(a,b) FLOAT a[2],*b; { *b = atan2(a[1],a[0]); }
int real_c(a,b) FLOAT a[2],*b; { *b = a[0]; }
/**********************************************************************/
int uminus_c(a,b)
FLOAT a[2],b[2];
{
  b[0] = -a[0];
  b[1] = -a[1];
}
/**********************************************************************/
int conjg_c(a,b)
FLOAT a[2],b[2];
{
  b[0] = a[0];
  b[1] = -a[1];
}
/**********************************************************************/
int log_c(a,b)
FLOAT a[2],b[2];
{
  b[0] = log(hypot(a[1],a[0]));
  b[1] = atan2(a[1],a[0]);
}
/**********************************************************************/
int exp_c(a,b)
FLOAT a[2],b[2];
{
  FLOAT mag;
  mag = exp(a[0]);
  b[0] = mag * cos(a[1]);
  b[1] = mag * sin(a[1]);
}
/**********************************************************************/
int cmplx_c(a,b,c)
FLOAT a,b,c[2];
{
  c[0] = a;
  c[1] = b;
}
/**********************************************************************/
double uminus_r(a) double a; { return(-a); }
double gt_r(a,b) double a,b; { return(a > b); }
double ge_r(a,b) double a,b; { return(a >= b); }
double lt_r(a,b) double a,b; { return(a < b); }
double le_r(a,b) double a,b; { return(a <= b); }
double eq_r(a,b) double a,b; { return(a == b); }
double ne_r(a,b) double a,b; { return(a != b); }
double not_r(a) double a; { return((a == 0 ? 1.0 : 0.0)); }
double and_r(a,b) double a,b; { return((a == 0 || b == 0 ? 0.0 : 1.0)); }
double or_r(a,b) double a,b; { return((a != 0 || b!= 0 ? 1.0 : 0.0)); }
double eqv_r(a,b) double a,b; { return(((a == 0 && b == 0) || (a != 0 && b != 0) ? 1.0 : 0.0)); }
double neqv_r(a,b) double a,b; { return(((a != 0 && b == 0) || (a == 0 && b != 0) ? 1.0 : 0.0)); }
double abs_r(a) double a; { return((a >= 0 ? a : -a)); }
double exp_r(a) double a; { return(a < -50 ? 0 : exp(a)); }
double aint_r(a) double a; { return(a >= 0 ? floor(a) : ceil(a)); }
double max_r(a,b) double a,b; { return(a > b ? a : b); }
double min_r(a,b) double a,b; { return(a < b ? a : b); }
double dim_r(a,b) double a,b; { return(a > b ? a - b : 0); }
double anint_r(a) double a; { return(floor(a+0.5)); }
double sign_r(a,b) double a,b; { return(b >= 0 ? abs(a) : -abs(a) ); }
