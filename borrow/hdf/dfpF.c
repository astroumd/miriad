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
Revision 1.1  1990/09/28 21:49:58  teuben
Initial revision

 * Revision 3.4  90/05/17  17:58:53  clow
 * fix bugs with position of include and
 * dpwref and dprref changed to dpiwref and dpirref in the #defines
 * 
 * Revision 3.4  90/05/17  17:49:26  clow
 * fix bug with the position of include
 * 
 * Revision 3.3  90/05/14  23:09:38  clow
 * "beautify" function declaration with MACROs
 * 
 * Revision 3.2  90/05/10  13:57:33  clow
 * changed Fortran to C character array interface to use _fcd and _fcdtocp
 * 
 * Revision 3.1  90/04/19  16:38:01  clow
 * Changed interface to be more VMS compatible by
 * converting all character arrays, not just filenames
 * 
 * Revision 3.0  90/02/02  20:30:59  clow
 * *** empty log message ***
 * 
*/

/*-----------------------------------------------------------------------------
 * File:    dfpF.c
 * Purpose: C stubs for Palette Fortran routines
 * Invokes: dfp.c dfkit.c
 * Contents: 
 *  dpigpal_:   Call DFPgetpal to get palette
 *  dpippal_:   Call DFPputpal to write/overwrite palette in file
 *  dpinpal_:   Call DFPnpals to get number of palettes in file
 *  dpiwref_:    Call DFPwriteref to set ref of pal to write next
 *  dpirref_:    Call DFPreadref to set ref of pal to read next
 *  dprest_:    Call DFPrestart to get palettes afresh in file
 *  dplref_:    Call DFPlastref to get ref of last pal read/written
 *  DFPrestart_:    Call DFPrestart to get palettes afresh in file
 *  DFPlastref_:    Call DFPlastref to get ref of last pal read/written
 * Remarks: none
 *---------------------------------------------------------------------------*/

#include "df.h"

#ifdef DF_CAPFNAMES
#   define dpigpal_	DPIGPAL
#   define dpippal_	DPIPPAL
#   define dpinpal_	DPINPAL
#   define dpiwref_	DPIWREF
#   define dpirref_	DPIRREF
#   define dprest_	DPREST
#   define dplref_	DPLREF
#   define dfprestart_	DFPRESTART
#   define dfplastref_	DFPLASTREF
#endif /* DF_CAPFNAMES */

/*-----------------------------------------------------------------------------
 * Name:    dpigpal_
 * Purpose: call DFPgetpal, get palette
 * Inputs:  filename, fnlen: filename, length of name
 *          pal: space to put palette
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   Fortran stub routine
 * Invokes: DFPgetpal
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dpigpal_(filename, pal, fnlen)
    _fcd filename;
    int *fnlen;
    _fcd pal;
{
    char *fn;
    int ret;

    fn = DFIf2cstring(filename, *fnlen);
    ret =  DFPgetpal(fn, _fcdtocp(pal));
    (void) DFIfreespace(fn);
    return(ret);
}


/*-----------------------------------------------------------------------------
 * Name:    dpippal_
 * Purpose: Write palette to file
 * Inputs:  filename: name of HDF file
 *          palette: palette to be written to file
 *          overwrite: if 1, overwrite last palette read or written
 *                     if 0, write it as a fresh palette
 *          filemode: if "a", append palette to file
 *                    if "w", create new file
 *          fnlen:  length of filename
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF users, programmers, utilities
 * Invokes: DFPputpal
 * Remarks: To overwrite, the filename must be the same as for the previous
 *          call
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dpippal_(filename, pal, overwrite, filemode, fnlen)
    _fcd filename;
    _fcd pal;
    int overwrite;
    _fcd filemode;
    int *fnlen;
{
    char *fn;
    int ret;

    fn = DFIf2cstring(filename, *fnlen);
    ret =  DFPputpal(fn, _fcdtocp(pal), overwrite, _fcdtocp(filemode));
    (void) DFIfreespace(fn);
    return(ret);
}


/*-----------------------------------------------------------------------------
 * Name:    dpinpal_
 * Purpose: How many palettes are present in this file?
 * Inputs:  filename, fnlen: name, length of HDF file
 * Returns: number of palettes on success, -1 on failure with DFerror set
 * Users:   HDF programmers, other routines and utilities
 * Invokes: DFPnpals
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dpinpal_(filename, fnlen)
    _fcd filename;
    int *fnlen;
{
    char *fn;
    int ret;

    fn = DFIf2cstring(filename, *fnlen);
    ret =  DFPnpals(fn);
    (void) DFIfreespace(fn);
    return(ret);
}


/*-----------------------------------------------------------------------------
 * Name:    dpirref
 * Purpose: Set ref of palette to get next
 * Inputs:  filename: file to which this applies
 *          ref: reference number of next get
 * Returns: 0 on success, -1 on failure
 * Users:   HDF programmers, other routines and utilities
 * Invokes: DFPreadref
 * Remarks: checks if palette with this ref exists
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dpirref_(filename, ref, fnlen)
    _fcd filename;
    int *fnlen;
    uint16 ref;
{
    char *fn;
    int ret;

    fn = DFIf2cstring(filename, *fnlen);
    ret =  DFPreadref(fn, ref);
    (void) DFIfreespace(fn);
    return(ret);
}


/*-----------------------------------------------------------------------------
 * Name:    dpiwref
 * Purpose: Set ref of palette to put next
 * Inputs:  filename: file to which this applies
 *          ref: reference number of next put
 *          fnlen: length of filename
 * Returns: 0 on success, -1 on failure
 * Users:   HDF programmers, other routines and utilities
 * Invokes: DFPwriteref
 *---------------------------------------------------------------------------*/


	FCALLKEYW int
dpiwref_(filename, ref, fnlen)
    _fcd filename;
    uint16 ref;
    int *fnlen;
{

    char *fn;
    int ret;

    fn = DFIf2cstring(filename, *fnlen);
    ret =  DFPreadref(fn, ref);
    (void) DFIfreespace(fn);
    return(ret);
}


/*-----------------------------------------------------------------------------
 * Name:    dprest_
 * Purpose: Do not remember info about file - get again from first palette
 * Inputs:  none
 * Returns: 0 on success
 * Users:   HDF programmers
 * Remarks: Invokes DFPrestart
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dprest_()
{

    return(DFPrestart());
}


/*-----------------------------------------------------------------------------
 * Name:    dplref
 * Purpose: Return last ref written or read
 * Inputs:  none
 * Globals: Lastref
 * Returns: ref on success, -1 on error with DFerror set
 * Users:   HDF users, utilities, other routines
 * Invokes: DFPlastref
 * Remarks: none
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dplref_()
{

    return(DFPlastref());
}


/*-----------------------------------------------------------------------------
 * Name:    dfprestart_
 * Purpose: Do not remember info about file - get again from first palette
 * Inputs:  none
 * Returns: 0 on success
 * Users:   HDF programmers
 * Remarks: Invokes DFPrestart
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dfprestart_()
{

    return(DFPrestart());
}


/*-----------------------------------------------------------------------------
 * Name:    dfplastref_
 * Purpose: Return last ref written or read
 * Inputs:  none
 * Globals: Lastref
 * Returns: ref on success, -1 on error with DFerror set
 * Users:   HDF users, utilities, other routines
 * Invokes: DFPlastref
 * Remarks: none
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dfplastref_()
{

    return(DFPlastref());
}
