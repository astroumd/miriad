/************************************************************************/
/*									*/
/*	Routines to access and manipulate a simple ascii table		*/
/*									*/
/*      These routine assemble an ASCII version in memory, so can be    */
/*      very memory intensive                                           */
/*									*/
/*  History:								*/
/*    pjt   9aug07   Original version, only writes tables               */
/*									*/
/*  TODO:						        	*/
/*    reading?						        	*/
/*    formatting options       			        	        */
/*----------------------------------------------------------------------*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h>

#include "maxdimc.h"
#include "io.h"
#include "miriad.h"

#define OLD 1
#define NEW 2
#define MK_FLAGS 1
#define MK_RUNS  2
#define check(x) if(x)bugno_c('f',x)
#define CHECK(x,a) if(x) { bug_c('w',((void)sprintf a,message));	\
			   bugno_c('f',x);				\
			 }
#define ERROR(sev,a) bug_c(sev,((void)sprintf a,message))

static char message[132];

typedef struct datarow {
  char **row;
  struct  datarow *next;
} datarow;

static struct { 
  int nrow, ncol;      /* as initialize with */
  int maxrow, maxcol;  /* global count */
  int row;             /* current row being operated on */
  int table;           /* handle to the actual table */
  int *ncols;          /* if we need to keep track of # rows/column -- not used */
  int *nrows;          /* if we need to keep track of # cols/row    -- not used */
  char **fmt;          /* format per column -- not used */
  char ***data;        /* memory image */
  
} tables[MAXOPEN];

#define Strcpy (void)strcpy

/************************************************************************/
void tabopen_c(int *thandle,Const char *name,Const char *status,int *ncol, int *nrow)
/**tabopen -- Open an table file.					*/
/*:table-i/o								*/
/*+ FORTRAN call sequence:

	subroutine tabopen(tno,name,status,ncol,nrow)
	integer tno,ncol,nrow
	character name*(*),status*(*)

  This opens an table file. Only new files implemented now

  Input:
    name	The name of the file to be opened.
    status	Either 'old', 'new' or 'append'.

  Input or Output:
    ncol	The number of columns. Can be 0 if done dynamically.
    nrow	The number of rows. Can be 0 if done dynamically.

  Output:
    tno		The handle of the output file.				*/
/*----------------------------------------------------------------------*/
{
  int iostat,length,access,tno,i;
  char *stat,*mode;

  if(!strcmp("old",status))	   { access = OLD; mode = "read";  stat = "old";}
  else if(!strcmp("append",status)){ access = OLD; mode = "append";stat = "old";}
  else if(!strcmp("new",status))   { access = NEW; mode = "write"; stat = "new";}
  else
   ERROR('f',(message,"Unrecognised status when opening %s, in XYOPEN",name));

  /* Access the image data. */

  hopen_c(&tno,name,stat,&iostat);
  CHECK(iostat,(message,"Error opening %s, in XYOPEN",name));
  haccess_c(tno,&(tables[tno].table),"table",mode,&iostat);
  CHECK(iostat,(message,"Error accessing table data of %s, in TABOPEN",name));

  /* only writing allowed now */

  if (access == OLD) 
    bug_c('f',"Table I/O can only write for now");

  tables[tno].nrow = *nrow;
  tables[tno].ncol = *ncol;
  tables[tno].row  = 1;

  if (*ncol == 0)  bug_c('f',"Table I/O cannot deal with dynamic column setting");
  if (*nrow == 0)  bug_c('f',"Table I/O cannot deal with dynamic row setting");

  tables[tno].data = (char ***) calloc( *nrow , sizeof(char ***));
  for (i=0; i< (*nrow); i++) {
    tables[tno].data[i] = (char **) calloc( *ncol , sizeof(char **));
  }

  tables[tno].fmt = (char **) calloc( *ncol , sizeof(char **));

  *thandle = tno;
}
/************************************************************************/
void tabsetr_c(int thandle, int row)
/**tabsetr -- Set active row in a table to work on			*/
/*:image-i/o								*/
/*+ FORTRAN call sequence:

	subroutine tabsetr(tno,row)
	implicit none

This flushes any changes to an image to disk.

  Input:
    tno		The handle of the table file.				
    row		The active row (1=first)                                */
/*----------------------------------------------------------------------*/
{
  tables[thandle].row = row;
}

/************************************************************************/
void tabfmtc_c(int thandle, int col, char *fmt)
/**tabfmtc -- Set formatting style for a column 		        */
/*:image-i/o								*/
/*+ FORTRAN call sequence:

	subroutine tabfmtc(tno,col,fmt)
	implicit none

This flushes any changes to an image to disk.

  Input:
    tno		The handle of the table file.				
    col		The column (1=first)                                    
    fmt		C-style formatting directive                            */
/*----------------------------------------------------------------------*/
{
  tables[thandle].fmt[col-1] = strdup(fmt);
}


/************************************************************************/
void tabclose_c(int thandle)
/**tablose -- Close up a table file.					*/
/*:image-i/o								*/
/*+ FORTRAN call sequence:

	subroutine tablose(tno)
	integer tno

  This closes an image file.

  Input:
    tno		The handle of the table file.				*/
/*----------------------------------------------------------------------*/
{
  int iostat, i, j;
  char *p;
  char *space = " ";
  char *newline = "\n";

  /* write table */

  for (i=0; i<tables[thandle].nrow; i++) {
    for (j=0; j<tables[thandle].ncol; j++) {
      p = tables[thandle].data[i][j];
      if (p==0) bugv_c('f',"Table missing value row %d col %d",i+1,j+1);
      hwritea_c(tables[thandle].table,p,strlen(p),&iostat);   
      check(iostat);
      hwritea_c(tables[thandle].table,space,strlen(space),&iostat);   
      check(iostat);
    }
    hwritea_c(tables[thandle].table,newline,strlen(newline),&iostat);   
    check(iostat);
  }

  /* free table */

  for (i=0; i<tables[thandle].nrow; i++) {
    for (j=0; j<tables[thandle].ncol; j++)
      free(tables[thandle].data[i][j]);
    free(tables[thandle].data[i]); 
  }
  free(tables[thandle].data);
    
  hdaccess_c(tables[thandle].table,&iostat);			check(iostat);
  hclose_c(thandle);


}
/************************************************************************/
void tabwcr_c(int thandle,int col,float value)
/**xyread -- Write a real value to a column in a table             	*/
/*:image-i/o								*/
/*+ FORTRAN call sequence:

	subroutine tabwcr(tno,col,value)
	integer tno,col
	real value

  This writes a real value into a column of the active row. See
  TABSETR to set the row (1=first)_

  Input:
    tno		The image file handle, returned by tabopen.
    col   	The column to write  (1=first)
    value       The real value                                          */
/*----------------------------------------------------------------------*/
{
  char temp[64];
  int iostat;

  if (tables[thandle].fmt[col-1])
    sprintf(temp,tables[thandle].fmt[col-1],value);
  else
    sprintf(temp,"%g",value);
  tables[thandle].data[tables[thandle].row - 1][col-1] = strdup(temp);
}

void tabwcd_c(int thandle,int col,double value)
{
  char temp[64];
  int iostat;

  sprintf(temp,"%g",value);
  tables[thandle].data[tables[thandle].row - 1][col-1] = strdup(temp);
}

void tabwci_c(int thandle,int col,int value)
{
  char temp[64];
  int iostat;

  sprintf(temp,"%d",value);
  tables[thandle].data[tables[thandle].row - 1][col-1] = strdup(temp);
}

void tabwca_c(int thandle,int col,char *value)
{
  char temp[64];
  int iostat;

  sprintf(temp,"%s",value);
  tables[thandle].data[tables[thandle].row - 1][col-1] = strdup(temp);
}
