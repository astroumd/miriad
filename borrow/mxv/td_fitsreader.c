/************************************************************************/
/*                                                                      */
/*      This module consists of a number of routines to perform         */
/*      I/O on a FITS image file.                                       */
/*                                                                      */
/*	Bob Sault							*/
/*	Giant Metrewave Telescope Project, Tata Institute		*/
/*	Poona University, Pune, India.					*/
/*	bobs@gmrt.ernet.in						*/
/*									*/
/*  This should be reasonably easy adapted to any system which supports	*/
/*  a standard C compiler and UNIX-like open,read,write and close	*/
/*  system subroutines. However, note the following:			*/
/*  * Currently only machines which support FITS integers and IEEE	*/
/*    floating point data, as their host formats are supported.		*/
/*  * A #define of BSD should be inserted on Berkeley UNIX machines.	*/
/*  * A typdef FLOAT is used for the standard floating point data type.	*/
/*    This can be either "float" or "double".				*/
/*									*/
/*  History:								*/
/*    15-jul-90	rjs  Original version. rjs.				*/
/*    28-jul-90 pjt  hurah - replace wrong in NEMO. pjt.		*/
/*    30-jul-90 rjs  Fixed bug in fitsetpl. Added comments. Improved	*/
/*		     some.						*/
/*		error messages.	rjs.					*/
/*     8-aug-90 rjs  Fixed bug in fitread, when reading 4-byte integers.*/
/*    17-apr-91 rjs  Adapted for AIPS2 test.				*/
/*    2/11/92 hr	Adapted for use by MXV. Mostly just changed name
			of FITS struct and put it in mxv.h
			Instead of exiting on error, return error code.
      6/12/92		Write routines can write comments.
*/
/************************************************************************/

#define private static
#define TRUE 1
#define FALSE 0
/*
#define MAXNAX 7
*/
#include <stdio.h>
#include <ctype.h>
#define	FITS_READER
#include "fits.h"

char *malloc(),*realloc();
double atof();

/* Defines, etc, related to the i/o routines. */

#ifdef vaxc
#  define O_RDONLY 2
#  define O_RDWR   1
#  define O_WRONLY 0
#  define O_TRUNC  0
#  define O_CREAT  0
#  define open  vms_open
#  define close vms_close
#  define read(a,b,c)  vms_io((a),0,(b),(c))
#  define write(a,b,c) vms_io((a),1,(b),(c))
#  define lseek vms_lseek
#else
#  include <fcntl.h>
#endif

/* Typedefs and defines dealing with formats and conversions. */

/*typedef float FLOAT;*/

#if defined(unicos) || defined(vaxc)
# define NO_CVT 0
   typedef int INT16;
   void unpack16_c(),unpack32_c(),packr_c(),unpackr_c();
#else
#  define NO_CVT 1
   typedef short int INT16;
#endif

private int fitsrch();
private int fitpad();

/*
void fitrdhdr(),fitrdhdi(),fitwrhdr(),fitwrhdi(),fitwrhdl(),fitwrhda();
void fitwrhd(),fitrdhd();
*/

#define TYPE_FLOAT 1
#define TYPE_16INT 2
#define TYPE_32INT 3
#define STATUS_OLD 1
#define STATUS_NEW 2
#define STATUS_NEW_WRITE 3
/*
typedef struct { int ncards,naxis,axes[MAXNAX],offset,type,status,fd;
                 FLOAT bscale,bzero; } A_FITS_t;
*/
static char *buf1=NULL,*buf2=NULL;
static int maxdim=0;

/**********************************************************************/
A_FITS_t *fitopen(name,status,naxis,nsize)
char *name,*status;
int naxis,nsize[];
/*
  This opens a FITS file and readies it for i/o.

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
  A_FITS_t *f;
  int n,t,i,size,bitpix;
  char keyword[9],line[80];

  f = (A_FITS_t *)malloc(sizeof(A_FITS_t));
  if(f == NULL){
    fprintf(stderr,"### Warning: Failed to allocate memory, in fitopen\n");
    return(NULL);
  }

/* Handle a new file. */

  if(!strcmp(status,"new")){
    f->status = STATUS_NEW;
    if(naxis <= 0 || naxis > MAXNAX){
      fprintf(stderr,"### Warning: Bad value of NAXIS, when opening %s\n",name);
      free((char *)f); return(NULL);
    }
    for(i=0; i < naxis; i++){
      if(nsize[i] <= 0){
	fprintf(stderr,"### Warning: Bad image dimensions for file %s\n",name);
	free((char *)f); return(NULL);
      }
    }
    f->fd = open(name,O_CREAT|O_TRUNC|O_WRONLY,0666);
    if(f->fd < 0){
      fprintf(stderr,"### Warning: Failed to open %s\n",name);
      free((char *)f); return(NULL);
    }
    f->type = TYPE_FLOAT;
    f->ncards = 0;
    fitwrhdl((char *)f,"SIMPLE",TRUE, NULL);
    fitwrhdi((char *)f,"BITPIX",-32, NULL);
    fitwrhdi((char *)f,"NAXIS",naxis, NULL);
    for(i=0; i < naxis; i++){
      sprintf(keyword,"NAXIS%d",i+1);
      fitwrhdi((char *)f,keyword,nsize[i], NULL);
    }

/* Handle an old file. */

  } else if(!strcmp(status,"old")){
    f->status = STATUS_OLD;
    f->fd = open(name,O_RDONLY,0);
    if(f->fd < 0){
      fprintf(stderr,"### Warning: Failed to open %s\n",name);
      free((char *)f); return(NULL);
    }

/* Check it has SIMPLE and END keywords. Calculate the byte offset to
   the start of the image data. */

    if(fitsrch(f,"SIMPLE  ",line) != 0 || (f->ncards = fitsrch(f,"END     ",line)) < 0){
      fprintf(stderr,"### Warning: File \'%s\' does not appear to be FITS\n",name);
      close(f->fd); free((char *)f); return(NULL);
    }
    f->offset = 2880*((80*f->ncards + 2879)/2880);

/* Determine things about the file. */

    fitrdhdi((char *)f,"BITPIX",&bitpix,0);
    if(bitpix == 16) f->type = TYPE_16INT;
    else if(bitpix == 32) f->type = TYPE_32INT;
    else if(bitpix == -32) f->type = TYPE_FLOAT;
    else {
      fprintf(stderr,"### Warning: Unsupported value of BITPIX (%d) when opening %s\n",bitpix,name);
      close(f->fd); free((char *)f); return(NULL);
    }
    fitrdhdi((char *)f,"NAXIS",&n,0);
    if(n <= 0){
      fprintf(stderr,"### Warning: Bad value of NAXIS (%d) when opening %s\n",n,name);
      close(f->fd); free((char *)f); return(NULL);
    }
    size = 1;
    for(i=0; i < n; i++){
      sprintf(keyword,"NAXIS%d",i+1);
      fitrdhdi((char *)f,keyword,&t,0);
      if(t <= 0 || (i >= naxis && t != 1)){
	fprintf(stderr,"### Warning: Cannot handle dimension %d of %s being %d\n",i+1,name,t);
	close(f->fd); free((char *)f); return(NULL);
      }
      if(i < naxis)nsize[i] = t;
      size *= t;
    }
    for(i=n; i < naxis; i++) nsize[i] = 1;
    fitrdhdr((char *)f,"BSCALE",&(f->bscale),1.0);
    fitrdhdr((char *)f,"BZERO",&(f->bzero),0.0);

/* Check that the file is of the right size. */

    if(f->type == TYPE_16INT) size *= 2;
    else		      size *= 4;
    size += f->offset;
    if(lseek(f->fd,0,2) < size){
      fprintf(stderr,"### Warning: File %s appears too small\n",name);
      close(f->fd); free((char *)f); return(NULL);
    }
/* Neither old nor new - an error. */

  } else {
    fprintf(stderr,"### Wanring: Bad status argument \'%s\', in fitopen\n",status);
    free((char *)f); return(NULL);
  }

/* Save dimension info. */

  f->naxis = naxis;
  for(i=0; i < naxis; i++)f->axes[i] = nsize[i];
  for(i=naxis; i < MAXNAX; i++) f->axes[i] = 1;

/* Make sure we have enough memory to deal with this file. */

  if(maxdim < nsize[0]){
    maxdim = nsize[0];
    buf1 = (buf1 == NULL ? malloc(sizeof(int)*nsize[0]) : realloc(buf1,sizeof(int)*nsize[0]));
	if(buf1 == NULL)
		return NULL;
    buf2 = (buf2 == NULL ? malloc(4*nsize[0]) : realloc(buf2,4*nsize[0]));
    if( buf2 == NULL){
	return(NULL);
    }
  }

/* Return with the goodies. */

  return( f);
}

/**********************************************************************/
int fitclose(file)
A_FITS_t *file;
/*
  This closes a FITS file, and deletes any memory associated with it.

  Input:
    file	This is the pointer returned by fitopen.
Returns error code or 0 for OK.
----------------------------------------------------------------------*/
{
  A_FITS_t *f;
  int i,offset, err=0;

  if(file == NULL) return FITS_ERR_OK;

  f = (A_FITS_t *)file;
  if(f->status == STATUS_NEW){
    fprintf(stderr,"### Warning: No image data written to FITS file\n");
    err = fitpad(f,80*f->ncards,' ');
  } else if(f->status == STATUS_NEW_WRITE){
    if(f->type == TYPE_16INT) offset = 2;
    else offset = 4;
    for(i=0; i < f->naxis; i++)offset *= f->axes[i];
    offset += 2880*((80*f->ncards + 2879)/2880);
    err = fitpad(f,offset,0);
  }
  close(f->fd);
  free((char *)f);
  return err;
}

/**********************************************************************/
int fitread(file,j,data)
A_FITS_t *file;
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
Return:
	0 for OK, else error code.
----------------------------------------------------------------------*/
{
  int offset,length,bytes;
  A_FITS_t *f;
  FLOAT bscale,bzero;
  int i,*idat;
  INT16 *jdat;

  f = (A_FITS_t *)file;
  bytes = (f->type == TYPE_16INT ? 2 : 4);
  offset = bytes*j*f->axes[0] + f->offset;
  length = bytes * f->axes[0];
  lseek(f->fd,offset,0);
  if(j > f->axes[1]){
	return(FITS_ERR_BNDRY);
  } else if(f->status != STATUS_OLD){
	return(FITS_ERR_IOP);
#if NO_CVT
  } else if(length != read(f->fd,
		           (f->type == TYPE_FLOAT ? (char *)data : buf2),
			   length)){
#else
  } else if(length != read(f->fd,buf2,length)){
#endif
	return(FITS_ERR_IO);
  }

/* We have the data now. Convert and scale it. */

  bscale = f->bscale; bzero = f->bzero;
  if(f->type == TYPE_16INT){
#if NO_CVT
    jdat = (INT16 *)buf2;
#else
    jdat = (INT16 *)buf1;
    unpack16_c(buf2,jdat,f->axes[0]);
#endif
    for(i=0; i < f->axes[0]; i++) data[i] = bscale * jdat[i] + bzero;
  } else if(f->type == TYPE_32INT){
#if NO_CVT
    idat = (int *)buf2;
#else
    idat = (int *)buf1;
    unpack32_c(buf2,idat,f->axes[0]);
#endif
    for(i=0; i < f->axes[0]; i++) data[i] = bscale * idat[i] + bzero;
  } else {
#if NO_CVT
#else
    unpackr_c(buf2,data,f->axes[0]);
#endif
    if(bscale != 1 || bzero != 0)
      for(i=0; i < f->axes[0]; i++) data[i] = bscale * data[i] + bzero;
  }
	return FITS_ERR_OK;
}

/**********************************************************************/
int fitwrite(file,j,data)
A_FITS_t *file;
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
Returns:
	error code or 0 for OK.
----------------------------------------------------------------------*/
{
  int offset,length, err=FITS_ERR_OK;
  A_FITS_t *f;

  f = (A_FITS_t *)file;

/* Finish off the header, if this is the first write. */

  if(f->status == STATUS_NEW){
    fitwrhd((char *)f,"END", NULL);
    err = fitpad(f,80*f->ncards,' ');
    f->offset = 2880*((80*f->ncards + 2879)/2880);
    f->status = STATUS_NEW_WRITE;
  } else if(f->status != STATUS_NEW_WRITE){
	return(FITS_ERR_IOP);
  } if(j >= f->axes[1]){
	return(FITS_ERR_BNDRY);
  }
  offset = 4 * j *f->axes[0] + f->offset;
  length = 4 * f->axes[0];
  lseek(f->fd,offset,0);

/* Convert the data, and check if the i/o is OK. */

#if NO_CVT
  if(length != write(f->fd,(char *)data,length)){
#else
  packr_c(data,buf2,f->axes[0]);
  if(length != write(f->fd,buf2,length)){
#endif
	return(FITS_ERR_IO);
  }
	return FITS_ERR_OK;
}

/**********************************************************************/
int fitsetpl(file,n,nsize)
A_FITS_t *file;
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
  A_FITS_t *f;
  int i,offset, err = FITS_ERR_OK;

  f = (A_FITS_t *)file;
  if(f->status == STATUS_NEW){
    fitwrhd((char *)f,"END", NULL);
    err = fitpad(f,80*f->ncards,' ');
    f->status = STATUS_NEW_WRITE;
  }
  offset = 0;
  for(i=n-1; i >= 0; i--){
    if(nsize[i] >= f->axes[i+2]){
	return(FITS_ERR_INDX);
    }
    offset = offset * f->axes[i+2] + nsize[i];
  }
  offset *= (f->type == TYPE_16INT ? 2 : 4) * f->axes[0] * f->axes[1];
  offset += 2880*((80*f->ncards + 2879)/2880);
  f->offset = offset;
  return err;
}

/**********************************************************************/
/* The positions here differ from the standard since C uses 0 as first index.*/
#define	QUOTE	'\''	/* What a quote mark is.		*/
#define	QUOTE1P	(11-1)	/* Where the first quote mark is.	*/
#define	QUOTE2P	(20-1)	/* 2nd quote mark is here or later.	*/
#define	EQUALS	'='
#define	EQUALP	(9-1)	/* Equals must be in column 9.		*/

char *fitrdhda(file,keyword, value, def)
A_FITS_t *file;
char *keyword, *value, *def;
/*
  This reads the value of a real-valued FITS keyword from the file header.

  Input:
    file	The pointer returned by fitopen.
    keyword	The keyword to search for.
    def		If the keyword is not found, this "default value" is
		returned.
  Output:	If value is not NULL, the value string is copied to here.
		It is assumed it will be long enough.
  Return:
		The value read from the FITS header.
		This is a pointer to the string. The string is statically
		allocated and should be copied if necessary.
		If the value is not a valid string, everything after the
		"= " will be returned (or '=' if no blank after the '=').
		This is not a valid quote, but could be useful in finding
		out what when wrong.
----------------------------------------------------------------------*/
{
static char card[81], *start, *s;
int	ch;

	if(fitsrch((A_FITS_t *)file,keyword,card) < 0)
		start = def;	/* No keyword, return default. */
	else
	{	/* Break out quoted string. */
		card[80] = 0;
		/* Find start of string. */
		if( card[QUOTE1P] == QUOTE)
			start = &card[QUOTE1P+1];
		else
		/* Not valid string, get pointer to char after '=' or '= '*/
		{	if(card[EQUALP+1] != ' ')
				start = &card[EQUALP+1];
			else
				start = &card[EQUALP+2];
		}

		/* Search for trailing quote. */
		s = &card[QUOTE2P]; /* Earliest place for trailing quote. */
		while( ((ch = *s) != QUOTE) && (ch != '\0')) s++;
		/* Now back up over any trailing blanks. */
		while( *(--s) == ' ');
		/* Null terminate string. */
		*(s+1) = '\0';
	}

	if(value != NULL)
	{	if(start != NULL)
			strcpy(value, start);
		else
			*value = '\0';
	}
	return start;
}

/**********************************************************************/
void fitrdhdr(file,keyword,value,def)
A_FITS_t *file;
char *keyword;
FLOAT *value,def;
/*
  This reads the value of a real-valued FITS keyword from the file header.

  Input:
    file	The pointer returned by fitopen.
    keyword	The keyword to search for.
    def		If the keyword is not found, this "default value" is
		returned.
  Output:
    value	The value read from the FITS header.
----------------------------------------------------------------------*/
{
  char card[81],*s,*s1;
  if(fitsrch((A_FITS_t *)file,keyword,card) < 0) *value = def;
  else {
    card[80] = 0;
    s = card + strlen(keyword);
    while(*s == ' ' && *s != 0)s++;
    while(*s == '=' && *s != 0)s++;
    while(*s == ' ' && *s != 0)s++;
    s1 = s;
    while(isdigit(*s) || *s == '+' || *s == '-' || *s == '.' || *s == 'E' ||
      *s == 'D' || *s == 'e' || *s == 'd')s++;
    *s = 0;
    *value = atof(s1);
  }
}

/**********************************************************************/
void fitrdhdi(file,keyword,value,def)
A_FITS_t *file;
char *keyword;
int *value,def;
/*
  This reads the value of a integer-valued FITS keyword from the file header.

  Input:
    file	The pointer returned by fitopen.
    keyword	The keyword to search for.
    def		If the keyword is not found, this "default value" is
		returned.
  Output:
    value	The value read from the FITS header.
----------------------------------------------------------------------*/
{
  FLOAT temp;
  fitrdhdr(file,keyword,&temp,(FLOAT)def);
  *value = temp;
}


/* Add a comment to a card. It is assumed the card already has the trailing
  '/' (or '/ ') and that the card has room for 80 chars + a trailing NULL.
  The card must already be NULL terminated.
*/
static void addcomment( card, comment)
char *card, *comment;
{
int cmntlen, len;

	/* Return if nothing to do. */
	if( (card == NULL) || (comment == NULL))
		return;

	len = strlen(card);
	/* Copy as much as there is room for. */
	strncpy(card+len, comment, 80 - len);
	card[80] = '\0';	/* Make sure its terminated. */
}

/**********************************************************************/
int fitwrhdr(file,keyword,value, comment)
A_FITS_t *file;
char *keyword, *comment;
FLOAT value;
/*
  This writes the value of a real-valued FITS keyword to the file header.

  Input:
    file	The pointer returned by the fitopen routine.
    keyword	The name of the keyword to write.
    value	The value of the keyword.
    comment	An optional comment.
----------------------------------------------------------------------*/
{
  char line[81];	/* 80 chars + null */

  sprintf(line,"%-8s= %20.9E /",keyword,value);
  addcomment(line, comment);
  fitwrhd(file,line);
}

/**********************************************************************/
void fitwrhdi(file,keyword,value, comment)
A_FITS_t *file;
char *keyword, *comment;
int value;
/*
  This writes the value of a integer-valued FITS keyword to the file header.

  Input:
    file	The pointer returned by the fitopen routine.
    keyword	The name of the keyword to write.
    value	The value of the keyword.
    comment	Optional comment.
----------------------------------------------------------------------*/
{
  char line[81];
  sprintf(line,"%-8s= %20d /",keyword,value);
  addcomment(line, comment);
  fitwrhd(file,line);
}

/**********************************************************************/
void fitwrhda(file,keyword,value, comment)
A_FITS_t *file;
char *keyword;
char *value, *comment;
/*
  This writes the value of a string-valued FITS keyword to the file header.

  Input:
    file	The pointer returned by the fitopen routine.
    keyword	The name of the keyword to write.
    value	The value of the keyword.
    comment	Optional comment
----------------------------------------------------------------------*/
{
  char line[81];
  sprintf(line,"%-8s= '%-8s'",keyword,value);
  addcomment(line, comment);
  fitwrhd(file,line);
}

/**********************************************************************/
void fitwrhdl(file,keyword,value, comment)
A_FITS_t *file;
char *keyword, *comment;
int value;
/*
  This writes the value of a logical-valued FITS keyword to the file header.

  Input:
    file	The pointer returned by the fitopen routine.
    keyword	The name of the keyword to write.
    value	The value of the keyword.
    comment	Optional comment
----------------------------------------------------------------------*/
{
  char line[81];
  sprintf(line,"%-8s=                    %c /",keyword,(value ? 'T' : 'F'));
  addcomment(line, comment);
  fitwrhd(file,line);
}

/**********************************************************************/
private int fitpad(f,offset,pad)
A_FITS_t *f;
char pad;
/*
  This pads a FITS file up to the next 2880 block boundary.
----------------------------------------------------------------------*/
{
#define MAXLEN 512
  char buf[MAXLEN];
  int k,ktot,i,length;
  for(i=0; i < MAXLEN; i++) buf[i] = pad;
  k = offset;
  ktot = 2880*((k + 2879)/2880);
  lseek(f->fd,k,0);
  while(k < ktot){
    length = ktot - k;
    if(length > MAXLEN) length = MAXLEN;
    if(length != write(f->fd,buf,length)){
	return(FITS_ERR_IOPAD);
    }
    k += length;
  }
  return FITS_ERR_OK;
}

/**********************************************************************/
int fitwrhd(file,card)
A_FITS_t *file;
char *card;
/*
  This adds a FITS card to the header.
----------------------------------------------------------------------*/
{
  A_FITS_t *f;
  int i;
  char line[80],*s;

  f = (A_FITS_t *)file;
  if(f->status != STATUS_NEW){
	return(FITS_ERR_IOP);
  }
  s = line;
  while(*card != 0)*s++ = *card++;
  for(i = s - line; i < 80; i++) *s++ = ' ';
  lseek(f->fd,80*(f->ncards++),0);
  if(80 != write(f->fd,line,80)){
	return(FITS_ERR_CARD);
  }
	return FITS_ERR_OK;
}

/**********************************************************************/
int fitrdhd(file,n,card)
A_FITS_t *file;
int n;
char card[81];
/*
  This reads a FITS card. No check is made that the request is valid,
  and it bombs out if an i/o error is detected.
----------------------------------------------------------------------*/
{
  A_FITS_t *f;
  int offset;

  f = (A_FITS_t *)file;
  offset = 80*n;
  lseek(f->fd,offset,0);
  if(80 != read(f->fd,card,80)){
	return(FITS_ERR_CARD);
  }
  card[80] = 0;
  return FITS_ERR_OK;
}

/**********************************************************************/
private int fitsrch(f,keyword,card)
A_FITS_t *f;
char *keyword,card[80];
/*
  This searches for a FITS keyword in a file.
----------------------------------------------------------------------*/
{
  int length,ncard;

  length = strlen(keyword);
  ncard = 0;
  lseek(f->fd,0,0);
  while(read(f->fd,card,80) == 80){
    if((card[length] == ' ' || card[length] == '=') &&
       !strncmp(card,keyword,length))return(ncard);
    else if(!strncmp(card,"END     ",8)) return(-1);
/*    else if(!strcmp(card,"END     ",8)) return(-1);*/
    ncard++;
  }
  return(-1);
}

/* Return a pointer to a character string describing the fits error code. */
char *fits_error(err)
int	err;
{
	if( (err <0) || (err >= NUM_FITS_ERRORS))
		return "Unknown FITS error.";
	else
		return fits_errors[err];
}
