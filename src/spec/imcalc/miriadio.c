/************************************************************************/
/*                                                                      */
/*      This module consists of a number of routines to perform         */
/*      I/O on a Miriad image file.                                     */
/*									*/
/*  This should be reasonably easy adapted to any system which supports	*/
/*  a standard C compiler and UNIX-like open,read,write and close	*/
/*  system subroutines. However, note the following:			*/
/*									*/
/*  History:								*/
/*    19-nov-91 Adapted from fitsio.c. rjs.				*/
/************************************************************************/

#include "header.h"
#include <stdio.h>
#include "io.h"

#define STATUS_NEW 0
#define STATUS_OLD 1

char *malloc(),*realloc();
private void bugout();

typedef struct { int naxis,axes[MAXNAX],tno,item,offset; } FITS;

/**********************************************************************/
char *fitopen(name,status,naxis,nsize)
char *name,*status;
int naxis,nsize[];
/*
  This opens a Miriad file and readies it for i/o.

  Inputs:
    name	A string giving the name of the file to be opened.
    status	Either "old" or "new".
    naxis	The number of dimensions of the image. When opening
		an "old" file, fitopen makes sure that the number of
		dimensions does not exceed this. For a "new" file,
		the output file is created with this many dimensions.
  Input or Output:
    nsize	This is input for a "new" file, and output for an "old"
		file. It is of size "naxis". For "new" files it gives
		the number of pixels along each dimension. For "old"
		files, it returns the number of pixels along each
		axis.
  Output:
    fitopen	This is a pointer (caste to a char pointer) to a structure
		which describes the file. This pointer is used in all
		subsequent calls to the fitsio routines.
----------------------------------------------------------------------*/
{
  FITS *f;
  char *mode,keyword[16];
  int iostat,stat,i,n,t;

  f = (FITS *)malloc(sizeof(FITS));
  if(f == NULL){
    fprintf(stderr,"### Failed to allocate memory, in fitopen\n");
    return(NULL);
  }

/* Open the item. */

  if(!strcmp(status,"new")){ stat = STATUS_NEW; mode = "read";}
  else			   { stat = STATUS_OLD; mode = "append";}

/* Check a new file. */

  if(stat == STATUS_NEW){
    if(naxis <= 0 || naxis > MAXNAX){
      fprintf(stderr,"### Bad value of NAXIS, when opening %s\n",name);
      bugout(0,f); return(NULL);
    }
    for(i=0; i < naxis; i++){
      if(nsize[i] <= 0){
	fprintf(stderr,"### Bad image dimensions for file %s\n",name);
	bugout(0,f); return(NULL);
      }
    }
  }

/* Open the file. */

  hopen_c(&(f->tno),name,status,&iostat);
  if(iostat != 0){
    fprintf(stderr,"### Failed to open %s\n",name);
    bugout(0,f);
    return(NULL);
  }
  if(stat == STATUS_NEW)wrhdr_c(f->tno,"image",0.0);
  haccess_c(f->tno,&(f->item),"image",mode,&iostat);
  if(iostat != 0){
    fprintf(stderr,"### Failed to open image item of %s\n",name);
    bugout(1,f); return(NULL);
  }

/* Handle a new file. */

  if(stat == STATUS_NEW){
    wrhdi_c(f->tno,"naxis",naxis);
    for(i=0; i < naxis; i++){
      sprintf(keyword,"naxis%d",i+1);
      wrhdi_c(f->tno,keyword,nsize[i]);
    }

/* Handle an old file. */

  } else if(stat == STATUS_OLD){
    rdhdi_c(f->tno,"naxis",&n,0);
    if(n <= 0){
      fprintf(stderr,"### Bad value of NAXIS (%d) when opening %s\n",n,name);
      bugout(2,f); return(NULL);
    }
    for(i=0; i < n; i++){
      sprintf(keyword,"naxis%d",i+1);
      rdhdi_c(f->tno,keyword,&t,0);
      if(t <= 0 || (i >= naxis && t != 1)){
	fprintf(stderr,"### Cannot handle dimension %d of %s being %d\n",i+1,name,t);
	bugout(2,f); return(NULL);
      }
      if(i < naxis)nsize[i] = t;
    }
    for(i=n; i < naxis; i++) nsize[i] = 1;
  }

/* Save dimension info. */

  f->offset = 0;
  f->naxis = naxis;
  for(i=0; i < naxis; i++)f->axes[i] = nsize[i];
  for(i=naxis; i < MAXNAX; i++) f->axes[i] = 1;

/* Return with the goodies. */

  return((char *)f);
}
/**********************************************************************/
private void bugout(n,f)
int n;
FITS *f;
/*
  Close up a file, and then free up storage.
----------------------------------------------------------------------*/
{
  int iostat;

  if(n >= 2) hdaccess_c(f->item,&iostat);
  if(n >= 1) hclose_c(f->tno);
  free((char *)f);
}
/**********************************************************************/
void fitclose(file)
char *file;
/*
  This closes a FITS file, and deletes any memory associated with it.

  Input:
    file	This is the pointer returned by fitopen.
----------------------------------------------------------------------*/
{
  FITS *f;
  int iostat;

  f = (FITS *)file;
  hdaccess_c(f->item,&iostat);
  hclose_c(f->tno);
  free((char *)f);
}
/**********************************************************************/
void fitread(file,j,data)
char *file;
int j;
FLOAT *data;
/*
  This reads a row of a FITS image.

  Input:
    file	The pointer to the data structure returned by the fitopen
		routine.
    j		The row number to be read. This varies from 0 to naxis2-1.
  Output:
    data	A FLOAT array of naxis1 elements, being the pixel values
		read.
----------------------------------------------------------------------*/
{
  int offset,length,iostat;
  FITS *f;

  f = (FITS *)file;
  length = H_REAL_SIZE * f->axes[0];
  offset = H_REAL_SIZE * f->offset + j * length + ITEM_HDR_SIZE;
  hreadr_c(f->item,data,offset,length,&iostat);
  if(iostat != 0){
    fprintf(stderr,"### Error reading file, in fitread ... aborting\n");
    exit(1);
  }
}
/**********************************************************************/
void fitwrite(file,j,data)
char *file;
int j;
FLOAT *data;
/*
  This writes a row of a FITS image. Note that this should not be called
  until the programmer is done writing to the FITS header (routines fitrdhd).

  Inputs:
    file	The pointer returned by fitopen.
    j		The row number to be written. This varies from 0 to naxis2-1.
    data	A FLOAT array of naxis1 elements, being the pixel values
		to write.
----------------------------------------------------------------------*/
{
  int offset,length,iostat;
  FITS *f;

  f = (FITS *)file;
  length = H_REAL_SIZE * f->axes[0];
  offset = H_REAL_SIZE * f->offset + j * length + ITEM_HDR_SIZE;
  hwriter_c(f->item,data,offset,length,&iostat);
  if(iostat != 0){
    fprintf(stderr,"### Error writing file, in fitwrite ... aborting\n");
    exit(1);
  }
}
/**********************************************************************/
void fitsetpl(file,n,nsize)
char *file;
int n,nsize[];
/*
  This sets the plane to be accessed in a FITS file which has more than
  two dimensions.

  Input:
    file	The pointer returned by fitopen.
    n		This gives the size of the nsize array.
    nsize	This gives the indices of the higher dimensions of the
		FITS image. They are zero-relative. nsize[0] gives the
		index along the 3rd dimension, nsize[1] is the indice along
		the 4th dimension, etc.
----------------------------------------------------------------------*/
{
  FITS *f;
  int i,offset;

  f = (FITS *)file;
  offset = 0;
  for(i=n-1; i >= 0; i--){
    if(nsize[i] >= f->axes[i+2]){
      fprintf(stderr,"### Illegal coordinate index, in fitsetpl. Aborting ...\n");
      exit(1);
    }
    offset = offset * f->axes[i+2] + nsize[i];
  }
  offset *= f->axes[0] * f->axes[1];
  f->offset = offset;
}
