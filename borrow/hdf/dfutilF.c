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
Revision 1.1.1.1  1990/09/28 21:50:10  teuben
UIUC 15-feb-2001 w/out wip and some manuals

 * Revision 1.1  90/06/06  00:30:57  mfolk
 * Initial revision
 * 
*/
/*-----------------------------------------------------------------------------
 * File:    dfutilF.c
 * Purpose: C stubs for Fortran utility routines
 * Invokes: dfutil.c
 * Contents: 
 *  dfindnr_:       For a given tag, find the next ref after the given ref
 *---------------------------------------------------------------------------*/

#include "df.h"
#include "dfsd.h"

#ifdef DF_CAPFNAMES
#   define dfindnr_	        DFINDNR 
#   define dffindnextref_	DFFINDNEXTREF
#endif /* DF_CAPFNAMES */

/*-----------------------------------------------------------------------------
 * Name:    dfindnr
 * Purpose: For this tag, find the ref after lref
 * Inputs:  dfile: ptr to open DF file
 *          tag:   tag to look for
 *          lref:  ref after which to search
 *
 * Returns: the desired ref if successful, on failure with	DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFfindnextref
 *---------------------------------------------------------------------------*/

    FCALLKEYW int32
dfindnr_(dfile, tag, lref)
     int *dfile, 
         *tag, 
         *lref;
{
    return(DFfindnextref(*dfile, (uint16) *tag, (uint16) *lref));
}

/*
CEND7MAX
*/

/*-----------------------------------------------------------------------------
 * Name:    dffindnextref
 * Purpose: For this tag, find the ref after lref
 * Inputs:  dfile: ptr to open DF file
 *          tag:   tag to look for
 *          lref:  ref after which to search
 *
 * Returns: the desired ref if successful, on failure with	DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFfindnextref
 *---------------------------------------------------------------------------*/

    FCALLKEYW int32
dffindnextref_(dfile, tag, lref)
     int *dfile, 
         *tag, 
         *lref;
{
    return(DFfindnextref(*dfile, (uint16) *tag, (uint16) *lref));
}
