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
Revision 1.1  1990/09/28 21:49:44  teuben
Initial revision

 * Revision 3.6  90/06/19  11:20:52  clow
 * Implemented DF24readref to call DFGRreadref to set next rig to read.
 * 
 * Revision 3.5  90/06/07  15:39:34  clow
 * change the args of df24setdims_ and d2sdims_
 * 
 * Revision 3.4  90/05/17  17:49:03  clow
 * fix bug with the position of include
 * 
 * Revision 3.3  90/05/14  23:08:11  clow
 * added stubs for DF24restart and DF24setil
 * "beautify" function declaration with MACROs
 * 
 * Revision 3.2  90/05/10  13:56:29  clow
 * changed Fortran to C character array interface to use _fcd and _fcdtocp
 * 
 * Revision 3.1  90/04/19  16:36:19  clow
 * Changed interface to be more VMS compatible by
 * converting all character arrays, not just filenames
 * 
 * Revision 3.0  90/02/02  20:29:16  clow
 * *** empty log message ***
 * 
*/

/*-----------------------------------------------------------------------------
 * File:    df24F.c
 * Purpose: read and write 24-bit raster images
 * Invokes: dfgr.c df24.c
 * Contents: 
 *  d2reqil_: use this interlace when returning image
 *  df24reqil_: use this interlace when returning image
 *  d2sdims_: set dimensions of image
 *  df24setdims_: set dimensions of image
 *  d2setil_: set interlace for image
 *  df24setil_: set interlace for image
 *  d2first_: restart 24 bit raster
 *  df24restart_: restart 24 bit raster
 *  d2igdim_: get dimensions of image
 *  d2igimg_: read in image
 *  d2iaimg_: write out image
 *
 * Remarks:A RIG specifies attributes associated with an image - lookup table, 
 *          dimension, compression, color compensation etc.
 *---------------------------------------------------------------------------*/

#include "dfgr.h"

#ifdef DF_CAPFNAMES
#   define d2reqil_	D2REQIL
#   define df24reqil_	DF24REQIL
#   define d2sdims_	D2SDIMS
#   define df24setdims_	DF24SETDIMS
#   define d2setil_	D2SETIL
#   define df24setil_	DF24SETIL
#   define d2first_	D2FIRST
#   define df24restart_	DF24RESTART
#   define d2igdim_	D2IGDIM
#   define d2igimg_	D2IGIMG
#   define d2iaimg_	D2IAIMG
#   define d2irref_	D2IRREF
#endif /* DF_CAPFNAMES */

#define LUT     0
#define IMAGE   1

static int dimsset = 0;


/*-----------------------------------------------------------------------------
 * Name:    d2reqil_
 * Purpose: get next image with specified interlace
 * Inputs:  il: interlace to get next image with
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL (high-level library) users, utilities, other routines
 * Invokes: DFGRIreqil
 * Remarks: none
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
d2reqil_(il)
    int *il;
{
    return(DFGRIreqil(*il, IMAGE));
}

/*-----------------------------------------------------------------------------
 * Name:    d2sdims_
 * Purpose: set dimensions of image to write next
 * Inputs:  xdim, ydim: dimensions of image
 *          il: interlace of image
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL (high-level library) users, utilities, other routines
 * Invokes: DFGRIsetdims
 * Remarks: none
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
d2sdims_(xdim, ydim)
    int32 *xdim, *ydim;
{
    dimsset = 1;
    return(DFGRIsetdims(*xdim, *ydim, 3, IMAGE));
}


/*-----------------------------------------------------------------------------
 * Name:    d2igdim_
 * Purpose: get dimensions of next image RIG
 * Inputs:  filename: name of HDF file
 *          pxdim, pydim: pointer to locations for returning x,y dimensions
 *          pil: location for returning interlace of image in file
 *          fnlen: length of filename
 * Returns: 0 on success, -1 on failure with DFerror set
 *          *pxdim, *pydim, *pil set on success
 * Users:   HDF HLL (high-level library) users, utilities, other routines
 * Invokes: DF24getdims
 * Remarks: none
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
d2igdim_(filename, pxdim, pydim, pil, fnlen)
    _fcd filename;
    int32 *pxdim, *pydim;
    int *pil, *fnlen;
{
    char *fn;
    int ret;

    fn = DFIf2cstring(filename, *fnlen);
    ret =  DF24getdims(fn, pxdim, pydim, pil);
    (void) DFIfreespace(fn);
    return(ret);
}


/*-----------------------------------------------------------------------------
 * Name:    d2igimg_
 * Purpose: get image from next RIG
 * Inputs:  filename: name of HDF file
 *          image: pointer to space to return image
 *          xdim, ydim: dimensions of space to return image
 *          fnlen: length of filename
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL (high-level library) users, utilities, other routines
 * Invokes: DFGRIgetimlut
 * Remarks: space is assumed to be xdim * ydim * 3 bytes
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
d2igimg_(filename, image, xdim, ydim, fnlen)
    _fcd filename;
    _fcd image;
    int32 *xdim, *ydim;
    int *fnlen;
{
    char *fn;
    int ret;

    fn = DFIf2cstring(filename, *fnlen);
    ret =  DF24getimage(fn, _fcdtocp(image), *xdim, *ydim);
    (void) DFIfreespace(fn);
    return(ret);
}


/*-----------------------------------------------------------------------------
 * Name:    d2iaimg_
 * Purpose: Write out image
 * Inputs:  filename: name of HDF file
 *          image: image to write
 *          xdim, ydim: dimensions of array image
 *          fnlen: length of filename
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL (high-level library) users, utilities, other routines
 * Invokes: DFGRIaddimlut
 * Remarks: array image is assumed to be xdim * ydim * ncomps bytes
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
d2iaimg_(filename, image, xdim, ydim, fnlen)
    _fcd filename;
    _fcd image;
    int32 *xdim, *ydim;
    int *fnlen;
{
    char *fn;
    int ret;

    if (!dimsset)
        if (DFGRIsetdims(*xdim, *ydim, 3, IMAGE)<0) return(-1);

    fn = DFIf2cstring(filename, *fnlen);
    ret = DFGRIaddimlut(fn, _fcdtocp(image), *xdim, *ydim, IMAGE, 1);
    (void) DFIfreespace(fn);
    return(ret);
}
/*-----------------------------------------------------------------------------
 * Name:    d2setil_
 * Purpose: set interlace store with following images
 * Inputs:  il: interlace to set
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL (high-level library) users, utilities, other routines
 * Invokes: DFGRIsetil
 * Remarks: none
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
d2setil_(il)
    int *il;
{
    return (DFGRIsetil(*il, IMAGE));
}

/*-----------------------------------------------------------------------------
 * Name:    df24first_
 * Purpose: restart 24 bit raster file
 * Inputs:  
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL (high-level library) users, utilities, other routines
 * Invokes: DFGRIrestart
 * Remarks: none
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
d2first_()
{
    return (DFGRIrestart());
}


/*-----------------------------------------------------------------------------
 * Name:    df24reqil_
 * Purpose: get next image with specified interlace
 * Inputs:  il: interlace to get next image with
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL (high-level library) users, utilities, other routines
 * Invokes: DFGRIreqil
 * Remarks: none
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
df24reqil_(il)
    int *il;
{
    return(DFGRIreqil(*il, IMAGE));
}

/*-----------------------------------------------------------------------------
 * Name:    df24setdims_
 * Purpose: set dimensions of image to write next
 * Inputs:  xdim, ydim: dimensions of image
 *          il: interlace of image
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL (high-level library) users, utilities, other routines
 * Invokes: DFGRIsetdims
 * Remarks: none
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
df24setdims_(xdim, ydim)
    int32 *xdim, *ydim;
{
    dimsset = 1;
    return(DFGRIsetdims(*xdim, *ydim, 3, IMAGE));
}

/*-----------------------------------------------------------------------------
 * Name:    df24setil_
 * Purpose: set interlace store with following images
 * Inputs:  il: interlace to set
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL (high-level library) users, utilities, other routines
 * Invokes: DFGRIsetil
 * Remarks: none
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
df24setil_(il)
    int *il;
{
    return (DFGRIsetil(*il, IMAGE));
}

/*-----------------------------------------------------------------------------
 * Name:    df24restart_
 * Purpose: restart 24 bit raster file
 * Inputs:  
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL (high-level library) users, utilities, other routines
 * Invokes: DFGRIrestart
 * Remarks: none
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
df24restart_()
{
    return (DFGRIrestart());
}
/*-----------------------------------------------------------------------------
 * Name:    d2irref_
 * Purpose: Internal stub for setting ref of rig to read next
 * Inputs:  filename: name of HDF file
 *          ref: reference
 *          fnlen: length of filename
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL (high-level library) users, utilities, other routines
 * Invokes: DFGRreadref
 * Remarks: 
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
d2irref_(filename, ref, fnlen)
    _fcd filename;
    int *ref;
    int *fnlen;
{
    char *fn;
    int ret;

    fn = DFIf2cstring(filename, *fnlen);
    ret = DFGRreadref(fn, *ref);
    (void) DFIfreespace(fn);
    return(ret);
}
