/************************************************************************/
/*									*/
/*	Routines to access and manipulate a simple ascii table		*/
/*									*/
/*      These routine assemble an ASCII version in memory, so can be    */
/*      very memory intensive                                           */
/*									*/
/*  History:								*/
/*    pjt   9aug07   Original version, only writes tables               */
/*    pjt   1oct08   Allow bypassing all I/O if tabname blank           */
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
#define CHECK(x,a) if(x) { bug_c('w',((void)sprintf a,message));        \
                           bugno_c('f',x);                              \
                         }
#define ERROR(sev,a) bug_c(sev,((void)sprintf a,message))


static char message[132];

static struct { 
  int mode;            /* 0=fully static   1=row wise (OK)   2=col wise (not OK yet) */
  int nrow, ncol;      /* as initialize with */
  int maxrow, maxcol;  /* global count */
  int row;             /* current row being operated on */
  int table;           /* handle to the actual table */
  int *ncols;          /* if we need to keep track of # rows/column -- not used */
  int *nrows;          /* if we need to keep track of # cols/row    -- not used */
  char **fmt;          /* format per column -- not used */
  char ***data;        /* memory image of the table:  data[row][col] */
  char **datarow;      /* memory image of a single row datarow[col] */
  
} tables[MAXOPEN];

static void tab_checkcol(int thandle, int col);
static void tab_checkrow(int thandle, int row);


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
                If blank, no I/O is done.
    status	Either 'old', 'new' or 'append'.

  Input or Output:
    ncol	The number of columns. No dynamic columns allowed.
    nrow	The number of rows. Can be 0 if done dynamically
                but data must be written row wise

  Output:
    tno		The handle of the output file.				
                A negative number is passed if file is blank, no I/O done */
/*----------------------------------------------------------------------*/
{
  int iostat,access,tno,i;
  char *stat,*mode;

  if (strlen(name) == 0 || !strcmp(name," ")){
    *thandle = -1;
    return;
  }

  if(!strcmp("old",status))	   { access = OLD; mode = "read";  stat = "old";}
  else if(!strcmp("append",status)){ access = OLD; mode = "append";stat = "old";}
  else if(!strcmp("new",status))   { access = NEW; mode = "write"; stat = "new";}
  else
   ERROR('f',(message,"Unrecognised status when opening %s, in XYOPEN",name));

  /* Access the table data. */

  hopen_c(&tno,name,stat,&iostat);
  CHECK(iostat,(message,"Error opening %s, in XYOPEN",name));
  haccess_c(tno,&(tables[tno].table),"table",mode,&iostat);
  CHECK(iostat,(message,"Error accessing table data of %s, in TABOPEN",name));

  /* only writing allowed now */

  if (access == OLD) 
    bug_c('f',"Table I/O can only write for now");

  tables[tno].nrow = *nrow;
  tables[tno].ncol = *ncol;
  tables[tno].maxrow = 0;
  tables[tno].maxcol = 0;
  tables[tno].row  = 0;
  tables[tno].mode = 0;

  if (*ncol == 0)  {
    bug_c('f',"Table I/O cannot deal with dynamic column setting");
    tables[tno].mode = 2;
  }
  if (*nrow == 0)  {
    tables[tno].mode = 1;
  }

  if (tables[tno].mode == 0) {    
    /* allocate a full table for random access */
    tables[tno].data = (char ***) calloc( *nrow , sizeof(char ***));
    for (i=0; i< (*nrow); i++) {
      tables[tno].data[i] = (char **) calloc( *ncol , sizeof(char **));
    }
  } else if (tables[tno].mode == 1) {
    /* allocate a single row, for row wise access */
    tables[tno].datarow = (char **) calloc( *ncol , sizeof(char **));
  } else {
    /* not implemented */
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

This sets the current row number. It not usesd, the row number might be
0 and illegal.

  Input:
    tno		The handle of the table file.				
    row		The active row (1=first). Use 0 to auto-increment       
                if you don't know the row number                        */
/*----------------------------------------------------------------------*/
{
  int iostat,i,j;
  char *p;
  char *space = " ";
  char *newline = "\n";

  if (thandle<0) return;

  if (row != 0) tab_checkrow(thandle,row);

  if (tables[thandle].mode == 0) {
    if (row == 0) 
      tables[thandle].row = tables[thandle].row + 1;
    else
      tables[thandle].row = row;
  } else if (tables[thandle].mode == 1) {

    if (tables[thandle].datarow[0] == 0) return;   /* first time no data? */

    if (row == 0)
      tables[thandle].row = tables[thandle].row + 1;
    i = tables[thandle].row;

    for (j=0; j<tables[thandle].ncol; j++) {
	p = tables[thandle].datarow[j];
	if (p==0) bugv_c('f',"TableRow missing value row %d col %d",i,j+1);
	hwritea_c(tables[thandle].table,p,strlen(p),&iostat);   
	check(iostat);
	hwritea_c(tables[thandle].table,space,strlen(space),&iostat);   
	check(iostat);
    }
    hwritea_c(tables[thandle].table,newline,strlen(newline),&iostat);   
    check(iostat);
  }
}

static void tab_checkrow(int thandle, int row)
{
  if (thandle<0) return;
  if (row < 1) bugv_c('f',"tabio: row=%d illegal",row);
  if (row > tables[thandle].maxrow) tables[thandle].maxrow = row;
}

static void tab_checkcol(int thandle, int col)
{
  if (thandle<0) return;
  if (col < 1) bugv_c('f',"tabio: col=%d illegal",col);
  if (col > tables[thandle].maxcol) tables[thandle].maxcol = col;
}


/************************************************************************/
void tabfmtc_c(int thandle, int col, char *fmt)
/**tabfmtc -- Set formatting style for a column 		        */
/*:image-i/o								*/
/*+ FORTRAN call sequence:

	subroutine tabfmtc(tno,col,fmt)
	implicit none

This sets the format for a particular column

  Input:
    tno		The handle of the table file.				
    col		The column (1=first)                                    
    fmt		C-style formatting directive                            */
/*----------------------------------------------------------------------*/
{
  if (thandle<0) return;
  tables[thandle].fmt[col-1] = strdup(fmt);
}


/************************************************************************/
void tabclose_c(int thandle)
/**tablose -- Close up a table file.					*/
/*:image-i/o								*/
/*+ FORTRAN call sequence:

	subroutine tablose(tno)
	integer tno

  This closes a table file.

  Input:
    tno		The handle of the table file.				*/
/*----------------------------------------------------------------------*/
{
  int iostat, i, j;
  char *p;
  char *space = " ";
  char *newline = "\n";

  if (thandle<0) return;

  /* write table */

  if (tables[thandle].mode == 0) {

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

  } else if (tables[thandle].mode == 1) {

    /* check if the last row needed to written */
    tabsetr_c(thandle,0);

    for (j=0; j<tables[thandle].ncol; j++)
      free(tables[thandle].datarow[j]);   
    free(tables[thandle].datarow);     
  }

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
    tno		The table file handle, returned by tabopen.
    col   	The column to write  (1=first)
    value       The real value                                          */
/*----------------------------------------------------------------------*/
{
  char temp[64];
  if (thandle<0) return;

  tab_checkcol(thandle,col);

  if (tables[thandle].fmt[col-1])
    sprintf(temp,tables[thandle].fmt[col-1],value);
  else
    sprintf(temp,"%g",value);

  if (tables[thandle].mode == 0)
    tables[thandle].data[tables[thandle].row - 1][col-1] = strdup(temp);
  else if (tables[thandle].mode == 1)
    tables[thandle].datarow[col-1] = strdup(temp);
}

void tabwcd_c(int thandle,int col,double value)
{
  char temp[64];
  if (thandle<0) return;

  tab_checkcol(thandle,col);

  if (tables[thandle].fmt[col-1])
    sprintf(temp,tables[thandle].fmt[col-1],value);
  else
    sprintf(temp,"%g",value);
  if (tables[thandle].mode == 0)
    tables[thandle].data[tables[thandle].row - 1][col-1] = strdup(temp);
  else if (tables[thandle].mode == 1)
    tables[thandle].datarow[col-1] = strdup(temp);
}

void tabwci_c(int thandle,int col,int value)
{
  char temp[64];
  if (thandle<0) return;

  tab_checkcol(thandle,col);

  if (tables[thandle].fmt[col-1])
    sprintf(temp,tables[thandle].fmt[col-1],value);
  else
    sprintf(temp,"%d",value);
  if (tables[thandle].mode == 0)
    tables[thandle].data[tables[thandle].row - 1][col-1] = strdup(temp);
  else if (tables[thandle].mode == 1)
    tables[thandle].datarow[col-1] = strdup(temp);
}

void tabwca_c(int thandle,int col,char *value)
{
  if (thandle<0) return;

  if (tables[thandle].mode == 0)
    tables[thandle].data[tables[thandle].row - 1][col-1] = strdup(value);
  else if (tables[thandle].mode == 1)
    tables[thandle].datarow[col-1] = strdup(value);
}


void tabcmt_c(int thandle,char *comment)
{
  int iostat;
  char *cmt="#";
  char *nwl="\n";
  if (thandle<0) return;

  hwritea_c(tables[thandle].table,cmt,strlen(cmt),&iostat);   
  check(iostat);
  hwritea_c(tables[thandle].table,comment,strlen(comment),&iostat);   
  check(iostat);
  hwritea_c(tables[thandle].table,nwl,strlen(nwl),&iostat);   
  check(iostat);
}
