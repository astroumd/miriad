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
Revision 1.1.1.1  1990/09/28 21:49:44  teuben
UIUC 15-feb-2001 w/out wip and some manuals

 * Revision 3.5  90/06/19  12:35:03  clow
 * Implemented DF24readref to call DFGRreadref to set next rig to read.
 * 
 * Revision 3.5  90/06/19  11:20:17  clow
 * Implemented DF24readref to call DFGRreadref to set next rig to read.
 * 
 * Revision 3.4  90/06/07  15:55:43  clow
 * fix minor syntax error
 * 
 * Revision 3.3  90/06/07  15:38:07  clow
 * redid DF24setdims with the correct args
 * 
 * Revision 3.2  90/05/11  12:55:43  clow
 * added DF24restart
 * 
 * Revision 3.1  90/04/18  10:47:17  clow
 * Changed interface to be consistent with documentation
 * -- Added DF24setil
 * -- Changed arg list of DFGRIsetdims
 * 
 * Revision 3.0  90/02/02  20:27:02  clow
 * *** empty log message ***
 * 
*/

/*-----------------------------------------------------------------------------
 * File:    df24.c
 * Purpose: read and write 24-bit raster images
 * Invokes: dfgr.c
 * Contents: 
 *  DF24getdims: get dimensions of image
 *  DF24reqil: use this interlace when returning image
 *  DF24getimage: read in image
 *  DF24setdims: set dimensions of image
 *  DF24addimage: write out image
 *
 * Remarks: A RIG specifies attributes associated with an image- lookup table, 
 *          dimension, compression, color compensation etc.
 *---------------------------------------------------------------------------*/


#include "dfgr.h"

static int Newdata = 0;		/* does Readrig contain fresh data? */
static int dimsset = 0;		/* have dimensions been set? */

#define LUT     0
#define IMAGE   1


/*-----------------------------------------------------------------------------
 * Name:    DF24getdims
 * Purpose: get dimensions of next image RIG
 * Inputs:  filename: name of HDF file
 *          pxdim, pydim: pointer to locations for returning x,y dimensions
 *          pil: location for returning interlace of image in file
 * Returns: 0 on success, -1 on failure with DFerror set
 *          *pxdim, *pydim, *pil set on success
 * Users:   HDF HLL (high-level library) users, utilities, other routines
 * Invokes: DFGRIgetdims
 * Remarks: none
 *---------------------------------------------------------------------------*/

int DF24getdims(filename, pxdim, pydim, pil)
char *filename;
int32 *pxdim, *pydim;
int *pil;
{
    int ncomps;

    do {
        if (DFGRIgetdims(filename, pxdim, pydim, &ncomps, pil, IMAGE)<0)
            return(-1);
    } while (ncomps!=3);

    Newdata = 1;
    return(0);
}

/*-----------------------------------------------------------------------------
 * Name:    DF24reqil
 * Purpose: get next image with specified interlace
 * Inputs:  il: interlace to get next image with
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL (high-level library) users, utilities, other routines
 * Invokes: DFGRIreqil
 * Remarks: none
 *---------------------------------------------------------------------------*/

int DF24reqil(il)
int il;
{
    return(DFGRIreqil(il, IMAGE));
}

/*-----------------------------------------------------------------------------
 * Name:    DF24getimage
 * Purpose: get image from next RIG
 * Inputs:  filename: name of HDF file
 *          image: pointer to space to return image
 *          xdim, ydim: dimensions of space to return lut
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL (high-level library) users, utilities, other routines
 * Invokes: DFGRIgetimlut
 * Remarks: space is assumed to be xdim * ydim * 3 bytes
 *---------------------------------------------------------------------------*/

int DF24getimage(filename, image, xdim, ydim)
char *filename;
char *image;
int32 xdim, ydim;
{
    int ret, il;
    int32 tx, ty;

    if (!Newdata)
        if (DF24getdims(filename, &tx, &ty, &il)<0) return(-1);
    ret = DFGRIgetimlut(filename, image, xdim, ydim, IMAGE, 0);
    Newdata = 0;
    return(ret);
}

/*-----------------------------------------------------------------------------
 * Name:    DF24setdims
 * Purpose: set dimensions of image to write next
 * Inputs:  xdim, ydim: dimensions of image
 *          il: interlace of image
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL (high-level library) users, utilities, other routines
 * Invokes: DFGRIsetdims
 * Remarks: none
 *---------------------------------------------------------------------------*/

int DF24setdims(xdim, ydim)
    int32 xdim, ydim;
{
    dimsset = 1;
    return(DFGRIsetdims(xdim, ydim, 3, IMAGE));
}

/*-----------------------------------------------------------------------------
 * Name:    DF24setil
 * Purpose: set interlace of image to write next
 * Inputs:  il: interlace of image
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL (high-level library) users, utilities, other routines
 * Invokes: DFGRIsetil
 * Remarks: none
 *---------------------------------------------------------------------------*/

int DF24setil(il)
int il;
{
    return(DFGRIsetil(il, IMAGE));
}

/*-----------------------------------------------------------------------------
 * Name:    DF24restart
 * Purpose: restart file
 * Inputs:  
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL (high-level library) users, utilities, other routines
 * Invokes: DFGRIrestart
 * Remarks: none
 *---------------------------------------------------------------------------*/
	int
DF24restart()
{
    return DFGRIrestart();
}

/*-----------------------------------------------------------------------------
 * Name:    DF24addimage
 * Purpose: Write out image
 * Inputs:  filename: name of HDF file
 *          image: image to write
 *          xdim, ydim: dimensions of array image
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL (high-level library) users, utilities, other routines
 * Invokes: DFGRIaddimlut
 * Remarks: array image is assumed to be xdim * ydim * 3 bytes
 *---------------------------------------------------------------------------*/

int DF24addimage(filename, image, xdim, ydim)
char *filename;
char *image;
int32 xdim, ydim;
{
    /* 0 == C */
    if (!dimsset)
        if (DFGRIsetdims(xdim, ydim, 3, IMAGE)<0) return(-1);
    dimsset = 1;

    return(DFGRIaddimlut(filename, image, xdim, ydim, IMAGE, 0));
}



/*-----------------------------------------------------------------------------
 * Name:    DF24readref
 * Purpose: Set ref of 24-rig to get next
 * Inputs:  filename: file to which this applies
 *          ref: reference number of next get
 * Returns: 0 on success, -1 on failure
 * Users:   HDF programmers, other routines and utilities
 * Invokes: DFGRreadref
 * Remarks: checks if 24-rig with this ref exists
 *---------------------------------------------------------------------------*/

int DF24readref(filename, ref)
char *filename;
uint16 ref;
{
    return (DFGRreadref(filename, ref));
}
