#ifdef RCSID
static char RcsId[] = "@(#)$Revision$"
#endif
/*
$Header$
$Log$
Revision 1.1.1.1  1990/09/28 21:50:00  teuben
UIUC 15-feb-2001 w/out wip and some manuals

 * Revision 3.7  90/07/06  09:39:18  clow
 * Added fortran stubs for DFR8readref:  d8rref, d8readref, and d8irref_
 * 
 * Revision 3.6  90/06/29  10:30:00  clow
 * Fixed bug in digimg_ by dereferencing the xdim ydim pointers
 * 
 * Revision 3.5  90/05/17  17:47:22  clow
 * fix bug with the position of include
 * 
 * Revision 3.4  90/05/17  15:59:25  clow
 * make the mac ls_fortran to C call *NOT* have to go through an additional
 * Fortran stub (for %ref()), so we can remove the different function names
 * for the MAC
 * 
 * Revision 3.3  90/05/14  23:09:42  clow
 * "beautify" function declaration with MACROs
 * 
*/
/*-----------------------------------------------------------------------------
 * File:    dfr8F.c
 * Purpose: C stubs for Fortran RIS routines
 * Invokes: dfr8.c dfkit.c
 * Contents: 
 *  d8spal_:    Set palette to write out with subsequent images
 *  d8first_:   Call DFR8restart to reset sequencing to first image
 *  d8igdim_:   Call DFR8getdims to get dimensions of next image
 *  d8igimg_:   Call DFR8getimage to get next image
 *  d8ipimg_:   Call DFR8putimage to write image to new file
 *  d8iaimg_:   Call DFR8putimage to add image to existing file
 *  d8irref_:   Call DFR8readref to set ref to get next
 *  dfr8setpalette_:Set palette to write out with subsequent images
 *  dfr8restart_:Call DFR8restart to reset sequencing to first image
 * Remarks: none
 *---------------------------------------------------------------------------*/

#include "dfrig.h"

#ifdef DF_CAPFNAMES
#   define d8spal_	D8SPAL
#   define d8first_	D8FIRST
#   define d8igdim_	D8IGDIM
#   define d8igimg_	D8IGIMG
#   define d8ipimg_	D8IPIMG
#   define d8iaimg_	D8IAIMG
#   define d8irref_	D8IRREF
#   define dfr8setpalette_	DFR8SETPALETTE
#   define dfr8restart_	DFR8RESTART
#endif /* DF_CAPFNAMES */


/*-----------------------------------------------------------------------------
 * Name:    d8spal_
 * Purpose: Set palette to be written out with subsequent images
 * Inputs:  pal: palette to associate with subsequent images
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   Fortran stub routine
 * Invokes: DFR8setpalette
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
d8spal_(pal)
    _fcd pal;
{
    return (DFR8setpalette(_fcdtocp(pal)));
}


/*-----------------------------------------------------------------------------
 * Name:    d8first_
 * Purpose: Reset sequencing back to first image
 * Inputs:  none
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   Fortran stub routine
 * Invokes: DFR8restart
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
d8first_()
{
    return(DFR8restart());
}


/*-----------------------------------------------------------------------------
 * Name:    d8igdim_
 * Purpose: Get dimensions of next image using DFR8getdims
 * Inputs:  filename: name of HDF file
 *          xdim, ydim - integers to return dimensions in
 *          ispal - boolean to indicate whether the image includes a palette
 *          lenfn - length of filename
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   Fortran stub routine
 * Invokes: DFR8getdims
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
d8igdim_(filename, xdim, ydim, ispal, lenfn)
    _fcd filename;
    int *xdim, *ydim, *ispal, *lenfn;
{
    char *fn;
    int ret;

    fn = DFIf2cstring(filename, *lenfn);
    ret =  DFR8getdims(fn, (int32*)xdim, (int32*)ydim, ispal);
    (void) DFIfreespace(fn);
    return(ret);
}


/*-----------------------------------------------------------------------------
 * Name:    d8igimg_
 * Purpose: Get next image using DFR8getimage
 * Inputs:  filename: name of HDF file
 *          image: space provided for returning image
 *          xdim, ydim: dimension of space provided for image
 *          pal: space of 768 bytes for palette
 *          lenfn: length of filename
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   Fortran stub routine
 * Invokes: DFR8getimage
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
d8igimg_(filename, image, xdim, ydim, pal, lenfn)
    _fcd filename, image, pal;
    int *xdim, *ydim, *lenfn;
{
    char *fn;
    int ret;

    fn = DFIf2cstring(filename, *lenfn);
    ret =  DFR8getimage(fn, _fcdtocp(image),
			(int32)*xdim, (int32)*ydim, _fcdtocp(pal));
    (void) DFIfreespace(fn);
    return(ret);
}


/*-----------------------------------------------------------------------------
 * Name:    d8ipimg_
 * Purpose: Write out image to new file
 * Inputs:  filename: name of HDF file
 *          image: image to write out
 *          xdim, ydim: dimensions of image to write out
 *          compress: compression scheme
 *          lenfn: length of filename
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   Fortran stub routine
 * Invokes: DFR8putimage
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
d8ipimg_(filename, image, xdim, ydim, compress, lenfn)
    _fcd filename, image;
    int *xdim, *ydim, *compress, *lenfn;
{
    char *fn;
    int ret;

    fn = DFIf2cstring(filename, *lenfn);
    ret = DFR8putimage(fn, _fcdtocp(image),
		       (int32)*xdim, (int32)*ydim, *compress);
    (void) DFIfreespace(fn);
    return(ret);
}


/*-----------------------------------------------------------------------------
 * Name:    d8iaimg_
 * Purpose: Add image to existing file
 * Inputs:  filename: name of HDF file
 *          image: image to write out
 *          xdim, ydim: dimensions of image to write out
 *          compress: compression scheme
 *          lenfn: length of filename
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   Fortran stub routine
 * Invokes: DFR8addimage
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
d8iaimg_(filename, image, xdim, ydim, compress, lenfn)
    _fcd filename, image;
    int *xdim, *ydim, *compress, *lenfn;
{
    char *fn;
    int ret;

    fn = DFIf2cstring(filename, *lenfn);
    ret = DFR8addimage(fn, _fcdtocp(image),
		       (int32)*xdim, (int32)*ydim, *compress);
    (void) DFIfreespace(fn);
    return(ret);
}

/*-----------------------------------------------------------------------------
 * Name:    DFR8readref
 * Purpose: Set ref of image to get next
 * Inputs:  filename: file to which this applies
 *          ref: reference number of next get
 * Returns: 0 on success, -1 on failure
 * Users:   HDF programmers, other routines and utilities
 * Invokes: DFR8Iopen, DFIfind
 * Remarks: checks if image with this ref exists
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
d8irref_(filename, ref, fnlen)
    _fcd filename;
    int *ref, *fnlen;
{
    char *fn;
    int ret;

    fn = DFIf2cstring(filename, *fnlen);
    if (!fn) return -1;
    ret = DFR8readref(fn, (uint16)*ref);
    DFIfreespace(fn);
    return ret;
}


/*-----------------------------------------------------------------------------
 * Name:    dfr8setpalette_
 * Purpose: Set palette to be written out with subsequent images
 * Inputs:  pal: palette to associate with subsequent images
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   Fortran stub routine
 * Invokes: DFR8setpalette
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dfr8setpalette_(pal)

    _fcd pal;
{

    return (DFR8setpalette(_fcdtocp(pal)));
}

/*-----------------------------------------------------------------------------
 * Name:    dfr8restart_
 * Purpose: Reset sequencing back to first image
 * Inputs:  none
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   Fortran stub routine
 * Invokes: DFR8restart
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dfr8restart_()
{

    return(DFR8restart());
}
