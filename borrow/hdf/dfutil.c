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

#ifdef RCSID
static char RcsId[] = "@(#)$Revision$";
#endif
/*
$Header$

$Log$
Revision 1.1  1990/09/28 21:50:08  teuben
Initial revision

 * Revision 1.2  90/06/28  09:11:08  mfolk
 * Corrected some comments.  No change to code.
 * Mike Folk
 * 
 * Revision 1.1  90/06/06  00:29:37  mfolk
 * Initial revision
 * 
*/
/*-----------------------------------------------------------------------------
 * File:  dfutil.c
 *
 * Purpose:
 *    General purpose utility routines, and callable versions of hdf utilities
 *
 * Invokes:
 *    latest libdf.a
 *
 * Public functions:
 *    DFUfindnextref - For this tag, find the ref after given ref
 *
 * Lower level functions:
 *
 * Private functions:
 *
 * Remarks:
 *    This version assumes that all the values are floating point.
 *--------------------------------------------------------------------------*/

#include "df.h"

/*-----------------------------------------------------------------------------
 * Name:    DFfindnextref
 * Purpose: For this tag, find the ref after lref
 * Inputs:  
 *          dfile: ptr to open DF file
 *          tag: tag to look for
 *          lref: ref after which to search
 * Returns: The desired ref if success, and -1 on failure
 * Users:   HDF users, utilities, other routines
 * Invokes: DFIcheck, DFIfind
 * Remarks:
 *---------------------------------------------------------------------------*/

    uint16
DFfindnextref(dfile, tag, lref)
    DF *dfile;
    uint16 tag, lref;
{
    DFdle *dle;
    int index;

    if (DFIcheck(dfile))
	return (-1);

    DFerror = DFE_NOERROR;

    if (DFIfind(dfile, tag, DFREF_WILDCARD, (lref == DFREF_WILDCARD),
		tag, lref, &dle, &index) < 0)
	return (-1);

    return (dle->dd[index].ref);
}
