/*****************************************************************************
* 
*			  NCSA HDF version 3.10r2
*				Sept 20, 1990
*
* NCSA HDF Version 3.10r2 source code and documentation are in the public
* domain.  Specifically, we give to the public domain all rights for future
* licensing of the source code, all resale rights, and all publishing rights.
* 
* We ask, but do not require, that the following message be included in all
* derived works:
* 
* Portions developed at the National Center for Supercomputing Applications at
* the University of Illinois at Urbana-Champaign.
* 
* THE UNIVERSITY OF ILLINOIS GIVES NO WARRANTY, EXPRESSED OR IMPLIED, FOR THE
* SOFTWARE AND/OR DOCUMENTATION PROVIDED, INCLUDING, WITHOUT LIMITATION,
* WARRANTY OF MERCHANTABILITY AND WARRANTY OF FITNESS FOR A PARTICULAR PURPOSE
* 
*****************************************************************************/

/*
$Header$

$Log$
Revision 1.1.1.1  1990/09/28 21:50:04  teuben
UIUC 15-feb-2001 w/out wip and some manuals

 * Revision 3.1  90/07/02  10:11:52  clow
 * some cosmetic modifications
 * 
*/
/*-----------------------------------------------------------------------------
 * File:    dfsdg.h
 * Purpose: header file for the Scientific Data set
 * Invokes: dfrig.h
 * Contents: 
 *  Structure definitions: DFSsdg
 *  Constant definitions: DFS_MAXLEN
 * Remarks: This is included with user programs which use SDG
 *          Currently defined to be 2-D.  Will later be increased to
 *          multiple dimensions
 *---------------------------------------------------------------------------*/


#ifndef DFSDG                       /* avoid re-inclusion */
#define DFSDG

#include "df.h"

#define DFS_MAXLEN 255		/*  Max length of label/unit/format strings */

/* structure to hold SDG info */
typedef struct {
    DFdi    data;		/* tag/ref of data in file */
    int16   rank;		/* number of dimensions */
    int32   *dimsizes;		/* dimensions of data */
    char    *coordsys;
    char    *dataluf[3];	/* label/unit/format of data */
    char    **dimluf[3];	/* label/unit/format for each dim */
    float32 **dimscales;	/* scales for each dimension */
    float32 max_data, min_data;	/* max, min values of data */
} DFSsdg;

#ifndef VMS
DF* DFSDIopen();
#else /*VMS*/
DF* _DFSDIopen();
#endif

#endif /*DFSDG*/
