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
static char RcsId[] = "@(#)$Revision$"
#endif
/*
$Header$
$Log$
Revision 1.1  1990/09/28 21:50:05  teuben
Initial revision

 * Revision 3.6  90/06/13  16:31:00  clow
 * added DFSDreadref that will set the ref of the next SD read in.
 * 
 * Revision 3.5  90/05/25  13:01:58  mfolk
 * Added Fortran versions of DFSDlastref: dslref & dfsdlastref
 * Mike Folk
 * 
 * Revision 3.4  90/05/17  17:49:30  clow
 * fix bug with the position of include
 * 
 * Revision 3.3  90/05/14  23:09:45  clow
 * "beautify" function declaration with MACROs
 * 
*/
/*-----------------------------------------------------------------------------
 * File:    dfsdF.c
 * Purpose: C stubs for Fortran SDS routines
 * Invokes: dfsd.c dfkit.c
 * Contents: 
 *  dsgdast_:       Call DFSDgetdatastrs to get attributes of data
 *  dsgdist_:       Call DFSDgetdimstrs to get attributes of a dimension
 *  dsgdisc_:       Call DFSDgetdimscale to get scale for a dimension
 *  dsgmaxm_:       Call DFSDgetmaxmin to get max and min data values
 *  dssdims_:       Call DFSDsetdims to set dimensions for subsequent SDGs
 *  dssdisc_:       Call DFSDsetdimscale to set scale for subsequent SDGs
 *  dssmaxm_:       Call DFSDsetmaxmin to set max/min values for subsequent SDGs
 *  dsclear_:       Call DFSDclear to erase values set for subsequent SDGs
 *  dsslens_:       Call DFSDsetlengths to set maximum lengths of string
 *  dsgdiln_:       Call DFSDgetdimlen to get lengths of strings for a dimension
 *  dsgdaln_:       Call DFSDgetdatalen to get lengths of data strings
 *  dsfirst_:       Call DFSDrestart to get SDGs again from beginning of file
 *  dspslc_:        Call DFSDIputslice to write slice to file
 *  dseslc_:        Call DFSDendslice to end slice writes, write SDG to file
 *  dsstype_:       Call DFSDsettype to set data type, machine type etc for put
 *  dsigdim_:       Call DFSDgetdims to get dimensions of next SDG
 *  dsigdat_:       Call DFSDgetdata to get data values
 *  dsipdat_:       Call DFSDIputdata to write SDG to new file
 *  dsiadat_:       Call DFSDIputdata to append SDG to existing file
 *  dsigslc_:       Call DFSDIgetslice to get slice from file
 *  dsisslc_:       Call DFSDstartslice to set up to write slice
 *  dslref_:        Call DFSDlastref to get ref of last SDS accessed
 *  dfsdgetdatastrs_:Call DFSDgetdatastrs to get attributes of data
 *  dfsdgetdimstrs_:Call DFSDgetdimstrs to get attributes of a dimension
 *  dfsdgetdimscale_:Call DFSDgetdimscale to get scale for a dimension
 *  dfsdgetmaxmin_: Call DFSDgetmaxmin to get max and min data values
 *  dfsdsetdims_:   Call DFSDsetdims to set dimensions for subsequent SDGs
 *  dfsdsetdimscale_:Call DFSDsetdimscale to set scale for subsequent SDGs
 *  dfsdsetmaxmin_: Call DFSDsetmaxmin to set max/min values for subsequent SDGs
 *  dfsdclear_:     Call DFSDclear to erase values set for subsequent SDGs
 *  dfsdsetlengths_:Call DFSDsetlengths to set maximum lengths of string
 *  dfsdgetdimlen_: Call DFSDgetdimlen to get lengths of strings for a dimension
 *  dfsdgetdatalen_:Call DFSDgetdatalen to get lengths of data strings
 *  dfsdrestart_:   Call DFSDrestart to get SDGs again from beginning of file
 *  dfsdputslice_:  Call DFSDIputslice to write slice to file
 *  dfsdendslice_:  Call DFSDendslice to end slice writes, write SDG to file
 *  dfsdsettype_:   Call DFSDsettype to set data type, machine type etc for put
 *  dfsdlastref_:   Call DFSDlastref to get ref of last SDS accessed
 * Remarks: no C stubs needed for the put string routines, only Fortran stubs
 *---------------------------------------------------------------------------*/

#include "dfsd.h"

#ifdef DF_CAPFNAMES
#   define dsgdast_	DSGDAST
#   define dsgdist_	DSGDIST
#   define dsgdisc_	DSGDISC
#   define dsgmaxm_	DSGMAXM
#   define dssdims_	DSSDIMS
#   define dssdisc_	DSSDISC
#   define dssmaxm_	DSSMAXM
#   define dsclear_	DSCLEAR
#   define dsslens_	DSSLENS
#   define dsgdiln_	DSGDILN
#   define dsgdaln_	DSGDALN
#   define dsfirst_	DSFIRST
#   define dspslc_	DSPSLC
#   define dseslc_	DSESLC
#   define dsstype_	DSSTYPE
#   define dsigdim_	DSIGDIM
#   define dsigdat_	DSIGDAT
#   define dsipdat_	DSIPDAT
#   define dsiadat_	DSIADAT
#   define dsigslc_	DSIGSLC
#   define dsisslc_	DSISSLC
#   define dsirref_	DSIRREF
#   define dslref_	DSLREF
#   define dfsdgetdatastrs_	DFSDGETDATASTRS
#   define dfsdgetdimstrs_	DFSDGETDIMSTRS
#   define dfsdgetdimscale_	DFSDGETDIMSCALE
#   define dfsdgetmaxmin_	DFSDGETMAXMIN
#   define dfsdsetdims_	DFSDSETDIMS
#   define dfsdsetdimscale_	DFSDSETDIMSCALE
#   define dfsdsetmaxmin_	DFSDSETMAXMIN
#   define dfsdclear_	DFSDCLEAR
#   define dfsdsetlengths_	DFSDSETLENGTHS
#   define dfsdgetdimlen_	DFSDGETDIMLEN
#   define dfsdgetdatalen_	DFSDGETDATALEN
#   define dfsdrestart_	DFSDRESTART
#   define dfsdputslice_	DFSDPUTSLICE
#   define dfsdendslice_	DFSDENDSLICE
#   define dfsdsettype_	DFSDSETTYPE
#   define dfsdlastref_     DFSDLASTREF
#endif /* DF_CAPFNAMES */

/*-----------------------------------------------------------------------------
 * Name:    dsgdast_
 * Purpose: Call DFSDgetdatastrs to get the data attributes
 * Inputs:  label, unit, format, coordsys: strings to return attributes in
 * Returns: 0 on success, -1 on failure with	DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFSDgetdatastrs
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dsgdast_(label, unit, format, coordsys)
    _fcd label, *unit, *format, *coordsys;
{

    return(DFSDgetdatastrs(_fcdtocp(label), _fcdtocp(unit),
			   _fcdtocp(format), _fcdtocp(coordsys)));
}


/*-----------------------------------------------------------------------------
 * Name:    dsgdist_
 * Purpose: Call DFSDgetdimstrs to get attributes of a dimension
 * Inputs:  label, unit, format: strings to return attributes in
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFSDgetdimstrs
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dsgdist_(dim, label, unit, format)
    int *dim;
    _fcd label, *unit, *format;
{

    return(DFSDgetdimstrs(*dim, _fcdtocp(label), _fcdtocp(unit),
			  _fcdtocp(format)));
}


/*-----------------------------------------------------------------------------
 * Name:    dsgdisc_
 * Purpose: Call DFSDgetdimscale to get scale for a dimension
 * Inputs:  dim: dimension to get attributes for
 *          maxsize: size of scale array
 *          scale: array to return scale in
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFSDgetdimscale
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dsgdisc_(dim, maxsize, scale)
    int *dim;
    int *maxsize;
    float scale[];
{
    return(DFSDgetdimscale(*dim, (int32)*maxsize, scale));
}


/*-----------------------------------------------------------------------------
 * Name:    dsgmaxm_
 * Purpose: Call DFSDgetmaxmin to get maximum and minimum data values
 * Inputs:  pmax: float to return maximum in
 *          pmin: float to return minimum in
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFSDgetmaxmin
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dsgmaxm_(pmax, pmin)
    float *pmax, *pmin;
{
    return(DFSDgetmaxmin(pmax, pmin));
}


/*-----------------------------------------------------------------------------
 * Name:    dssdims_
 * Purpose: Call DFSDsetdims to set dimensions for subsequent SDGs
 * Inputs:  rank: no of dimensions of SDG
 *          dimsizes: array containing dimensions of SDG
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFSDsetdims
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dssdims_(rank, dimsizes)
    int *rank;
    int dimsizes[];
{

    return(DFSDsetdims(*rank, (int32*)dimsizes));
}


/*-----------------------------------------------------------------------------
 * Name:    dssdisc_
 * Purpose: Call DFSDsetdimscale to set scales for subsequent SDGs
 * Inputs:  dim: dimension to set scale for
 *          dimsize: size of array scale
 *          scale: array of scale values
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFSDsetdimscale
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dssdisc_(dim, dimsize, scale)
    int *dim;
    int *dimsize;
    float scale[];
{

    return(DFSDsetdimscale(*dim, (int32)*dimsize, scale));
}


/*-----------------------------------------------------------------------------
 * Name:    dssmaxm_
 * Purpose: Call DFSDsetmaxmin to set max and min values for this SDG
 * Inputs:  max, min: max and min data values
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFSDsetmaxmin
 * Remarks: Max and Min are set only for next SDG, reset to NULL after
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dssmaxm_(max, min)
    float *max, *min;
{

    return(DFSDsetmaxmin(*max, *min));
}


/*-----------------------------------------------------------------------------
 * Name:    dsclear_
 * Purpose: Call DFSDclear to erase values set for subsequent SDGs
 * Inputs:  none
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFSDclear
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dsclear_()
{

    return(DFSDclear());
}


/*-----------------------------------------------------------------------------
 * Name:    dsslens_
 * Purpose: Call DFSDsetlengths to set max lengths of strings
 * Inputs:  maxlen_label, maxlen_unit, maxlen_format, maxlen_coordsys: max lens
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFSDsetlengths
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dsslens_(maxlen_label, maxlen_unit, maxlen_format, maxlen_coordsys)
    int *maxlen_label, *maxlen_unit, *maxlen_format, *maxlen_coordsys;
{

    return(DFSDsetlengths(*maxlen_label, *maxlen_unit, *maxlen_format,
                                                        *maxlen_coordsys));
}


/*-----------------------------------------------------------------------------
 * Name:    dsgdiln_
 * Purpose: Call DFSDgetdimlen to get actual lengths of strings
 * Inputs:  dim: dimension to get lengths for
 *          llabel, lunit, lformat: integers to return lengths of each string in
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFSDgetdimlen
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dsgdiln_(dim, llabel, lunit, lformat)
    int *dim, *llabel, *lunit, *lformat;
{

    return(DFSDgetdimlen(*dim, llabel, lunit, lformat));
}


/*-----------------------------------------------------------------------------
 * Name:    dsgdaln_
 * Purpose: Call DFSDgetdatalen to get actual lengths of strings
 * Inputs:  llabel, lunit, lformat, lcoordsys: integers to return lengths in
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFSDgetdatalen
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dsgdaln_(llabel, lunit, lformat, lcoordsys)
    int *llabel, *lunit, *lformat, *lcoordsys;
{

    return(DFSDgetdatalen(llabel, lunit, lformat, lcoordsys));
}


/*-----------------------------------------------------------------------------
 * Name:    dsfirst_
 * Purpose: Call DFSDrestart to get SDGs again from the beginning
 * Inputs:  none
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFSDrestart
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dsfirst_()
{

    return(DFSDrestart());
}


/*-----------------------------------------------------------------------------
 * Name:    dspslc_
 * Purpose: Call DFSDIputslice to write slice to file
 * Inputs:  winst: array of size = rank of data, containing start of slice
 *          winend: array of size rank, containing end of slice
 *          data: array containing slice
 *          ndims: no of dims of array data
 *          dims: dimensions of array data
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFSDIputslice
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dspslc_(windims, data, dims)
    int32 windims[];
    int32 dims[];
    float32 data[];
{

    return(DFSDIputslice(windims, data, dims, 1));
}


/*-----------------------------------------------------------------------------
 * Name:    dseslc_
 * Purpose: Call DFSDendslice to finish slice writes and write out SDG
 * Inputs:  none
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFSDendslice
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dseslc_()
{

    return(DFSDendslice());
}


/*-----------------------------------------------------------------------------
 * Name:    dsstype_
 * Purpose: Call DFSDsettype to set data type, m/c type, no type and array order
 * Inputs:  datatype, mctype, numtype, arrayorder: integers specifying values
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFSDsettype
 * Remarks: 0 specifies default value
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dsstype_(datatype, mctype, numtype, arrayorder)
    int *datatype, *mctype, *numtype, *arrayorder;
{

    return(DFSDsettype(*datatype, *mctype, *numtype, *arrayorder));
}


/*-----------------------------------------------------------------------------
 * Name:    dsigdim_
 * Purpose: Call DFSDgetdims to get dimensions of next SDG
 * Inputs:  filename: name of HDF file
 *          prank: integer to return rank in
 *          sizes: array to return dimensions in
 *          maxrank: dimension of array sizes
 *          lenfn: length of filename
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   Fortran stub routine
 * Invokes: DFSDgetdims
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dsigdim_(filename, prank, sizes, maxrank, lenfn)
    _fcd filename;
    int *prank, *maxrank, *lenfn;
    int sizes[];
{
    char *fn;
    int ret;

    fn = DFIf2cstring(filename, *lenfn);
    ret = DFSDgetdims(fn, prank, (int32*)sizes, *maxrank);
    (void) DFIfreespace(fn);
    return ret;
}


/*-----------------------------------------------------------------------------
 * Name:    dsigdat_
 * Purpose: Call DFSDgetdata to get data values
 * Inputs:  filename: name of HDF file
 *          rank: no of dimensions in array data
 *          maxsizes: array containing dimensions of the array data
 *          data: array to return the data in
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFSDIgetdata
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dsigdat_(filename, rank, maxsizes, data, fnlen)
    _fcd filename;
    int *rank;
    int maxsizes[];
    float32 data[];
    int *fnlen;
{
    int ret;
    char *fn;

    fn = DFIf2cstring(filename, *fnlen);
    ret = DFSDIgetdata(fn, *rank, (int32*)maxsizes, data, 1); /* 1==FORTRAN */
    DFIfreespace(fn);
    return ret;
}


/*-----------------------------------------------------------------------------
 * Name:    dsipdat_
 * Purpose: Call DFSDIputdata to write SDG to new file
 * Inputs:  filename: name of HDF file
 *          rank: no of dimensions of array data
 *          dimsizes: array containing size of each dimension of array data
 *          data: array containing data values
 *          fnlen: length of string filename
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFSDIputdata
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dsipdat_(filename, rank, dimsizes, data, fnlen)
    _fcd filename;
    int *rank;
    int dimsizes[];
    float32 *data;
    int  *fnlen;
{
    char *fn;
    int ret;

    fn = DFIf2cstring(filename, *fnlen);

    /* 0, 1 specify create mode, FORTRAN style array (column major) */
    ret = DFSDIputdata(fn, *rank, (int32*)dimsizes, data, 0, 1);
    DFIfreespace(fn);
    return(ret);
}


/*-----------------------------------------------------------------------------
 * Name:    dsiadat_
 * Purpose: Call DFSDIputdata to append SDG to existing file
 * Inputs:  filename: name of HDF file
 *          rank: no of dimensions of array data
 *          dimsizes: array containing size of each dimension of array data
 *          data: array containing data values
 *          fnlen: length of string filename
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFSDIputdata
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dsiadat_(filename, rank, dimsizes, data, fnlen)
    _fcd filename;
    int *rank;
    int dimsizes[];
    float32 *data;
    int *fnlen;
{
    char *fn;
    int ret;

    fn = DFIf2cstring(filename, *fnlen);
    /* 1, 1 specify create mode, FORTRAN style array (column major) */
    ret = DFSDIputdata(fn, *rank,(int32*)dimsizes, data, 1, 1);
    DFIfreespace(fn);
    return(ret);
}


/*-----------------------------------------------------------------------------
 * Name:    dsigslc_
 * Purpose: Call DFSDIgetslice to read slice from file
 * Inputs:  filename: name of HDF file
 *          winst: array of size = rank of data, containing start of slice
 *          windims: array of size rank, containing end of slice
 *          data: array for returning slice
 *          ndims: no of dims of array data
 *          dims: dimensions of array data
 *          fnlen: length of filename
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFSDIgetslice
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dsigslc_(filename, winst, windims, data, dims, fnlen)
    _fcd filename;
    int32 winst[], windims[];
    int32 dims[];
    float32 data[];
    int *fnlen;
{
    char *fn;
    int ret;

    fn = DFIf2cstring(filename, *fnlen);
    ret = DFSDIgetslice(fn, winst, windims, data, dims, 1);
    DFIfreespace(fn);
    return(ret);
}


/*-----------------------------------------------------------------------------
 * Name:    dsisslc_
 * Purpose: Call DFSDstartslice to set up to write slice
 * Inputs:  filename: name of HDF file
 *          fnlen: length of filename
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFSDstartslice
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dsisslc_(filename, fnlen)
    _fcd filename;
    int *fnlen;
{
    char *fn;
    int ret;

    fn = DFIf2cstring(filename, *fnlen);
    ret = DFSDstartslice(fn);
    DFIfreespace(fn);
    return(ret);
}

/*-----------------------------------------------------------------------------
 * Name:    dsirref__
 * Purpose: Call DFSDreadref to set up next ref to read
 * Inputs:  filename: name of HDF file
 *	    ref: next ref to read
 *          fnlen: length of filename
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFSDstartslice
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dsirref_(filename, ref, fnlen)
    _fcd filename;
    int *ref;
    int *fnlen;
{
    char *fn;
    int ret;

    fn = DFIf2cstring(filename, *fnlen);
    ret = DFSDreadref(fn, (uint16) *ref);
    DFIfreespace(fn);
    return(ret);
}

/*-----------------------------------------------------------------------------
 * Name:    dslref
 * Purpose: Return last ref written or read
 * Inputs:  none
 * Globals: Lastref
 * Returns: ref on success, -1 on error with DFerror set
 * Users:   HDF users, utilities, other routines
 * Invokes: DFANlastref
 * Remarks: none
 *---------------------------------------------------------------------------*/

    FCALLKEYW int
dslref_()
{
    return(DFSDlastref());
}


/*-----------------------------------------------------------------------------
 * Name:    dfsdgetdatastrs_
 * Purpose: Call DFSDgetdatastrs to get the data attributes
 * Inputs:  label, unit, format, coordsys: strings to return attributes in
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFSDgetdatastrs
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dfsdgetdatastrs_(label, unit, format, coordsys)
    _fcd label, unit, format, coordsys;
{

    return(DFSDgetdatastrs(_fcdtocp(label), _fcdtocp(unit),
			   _fcdtocp(format), _fcdtocp(coordsys)));
}


/*-----------------------------------------------------------------------------
 * Name:    dfsdgetdimstrs_
 * Purpose: Call DFSDgetdimstrs to get attributes of a dimension
 * Inputs:  label, unit, format: strings to return attributes in
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFSDgetdimstrs
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dfsdgetdimstrs_(dim, label, unit, format)
    int *dim;
    _fcd label, unit, format;
{

    return(DFSDgetdimstrs(*dim, _fcdtocp(label),
			  _fcdtocp(unit), _fcdtocp(format)));
}


/*-----------------------------------------------------------------------------
 * Name:    dfsdgetdimscale_
 * Purpose: Call DFSDgetdimscale to get scale for a dimension
 * Inputs:  dim: dimension to get attributes for
 *          maxsize: size of scale array
 *          scale: array to return scale in
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFSDgetdimscale
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dfsdgetdimscale_(dim, maxsize, scale)
    int *dim;
    int *maxsize;
    float scale[];
{

    return(DFSDgetdimscale(*dim, (int32)*maxsize, scale));
}


/*-----------------------------------------------------------------------------
 * Name:    dfsdgetmaxmin_
 * Purpose: Call DFSDgetmaxmin to get maximum and minimum data values
 * Inputs:  pmax: float to return maximum in
 *          pmin: float to return minimum in
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFSDgetmaxmin
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dfsdgetmaxmin_(pmax, pmin)
    float *pmax, *pmin;
{
    return(DFSDgetmaxmin(pmax, pmin));
}


/*-----------------------------------------------------------------------------
 * Name:    dfsdsetdims_
 * Purpose: Call DFSDsetdims to set dimensions for subsequent SDGs
 * Inputs:  rank: no of dimensions of SDG
 *          dimsizes: array containing dimensions of SDG
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFSDsetdims
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dfsdsetdims_(rank, dimsizes)
    int *rank;
    int dimsizes[];
{

    return(DFSDsetdims(*rank, (int32*)dimsizes));
}


/*-----------------------------------------------------------------------------
 * Name:    dfsdsetdimscale_
 * Purpose: Call DFSDsetdimscale to set scales for subsequent SDGs
 * Inputs:  dim: dimension to set scale for
 *          dimsize: size of array scale
 *          scale: array of scale values
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFSDsetdimscale
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dfsdsetdimscale_(dim, dimsize, scale)
    int *dim;
    int *dimsize;
    float scale[];
{

    return(DFSDsetdimscale(*dim, (int32)*dimsize, scale));
}


/*-----------------------------------------------------------------------------
 * Name:    dfsdsetmaxmin_
 * Purpose: Call DFSDsetmaxmin to set max and min values for this SDG
 * Inputs:  max, min: max and min data values
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFSDsetmaxmin
 * Remarks: Max and Min are set only for next SDG, reset to NULL after
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dfsdsetmaxmin_(max, min)
    float *max, *min;
{

    return(DFSDsetmaxmin(*max, *min));
}


/*-----------------------------------------------------------------------------
 * Name:    dfsdclear_
 * Purpose: Call DFSDclear to erase values set for subsequent SDGs
 * Inputs:  none
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFSDclear
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dfsdclear_()
{

    return(DFSDclear());
}


/*-----------------------------------------------------------------------------
 * Name:    dfsdsetlengths_
 * Purpose: Call DFSDsetlengths to set max lengths of strings
 * Inputs:  maxlen_label, maxlen_unit, maxlen_format, maxlen_coordsys: max lens
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFSDsetlengths
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dfsdsetlengths_(maxlen_label, maxlen_unit, maxlen_format, maxlen_coordsys)
    int *maxlen_label, *maxlen_unit, *maxlen_format, *maxlen_coordsys;
{

    return(DFSDsetlengths(*maxlen_label, *maxlen_unit, *maxlen_format,
                                                        *maxlen_coordsys));
}


/*-----------------------------------------------------------------------------
 * Name:    dfsdgetdimlen_
 * Purpose: Call DFSDgetdimlen to get actual lengths of strings
 * Inputs:  dim: dimension to get lengths for
 *         llabel, lunit, lformat: integers to return lengths of each string in
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFSDgetdimlen
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dfsdgetdimlen_(dim, llabel, lunit, lformat)
    int *dim, *llabel, *lunit, *lformat;
{

    return(DFSDgetdimlen(*dim, llabel, lunit, lformat));
}


/*-----------------------------------------------------------------------------
 * Name:    dfsdgetdatalen_
 * Purpose: Call DFSDgetdatalen to get actual lengths of strings
 * Inputs:  llabel, lunit, lformat, lcoordsys: integers to return lengths in
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFSDgetdatalen
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dfsdgetdatalen_(llabel, lunit, lformat, lcoordsys)
    int *llabel, *lunit, *lformat, *lcoordsys;
{

    return(DFSDgetdatalen(llabel, lunit, lformat, lcoordsys));
}


/*-----------------------------------------------------------------------------
 * Name:    dfsdrestart_
 * Purpose: Call DFSDrestart to get SDGs again from the beginning
 * Inputs:  none
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFSDrestart
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dfsdrestart_()
{

    return(DFSDrestart());
}


/*-----------------------------------------------------------------------------
 * Name:    dfsdputslice_
 * Purpose: Call DFSDIputslice to write slice to file
 * Inputs:  winst: array of size = rank of data, containing start of slice
 *          windims: array of size rank, containing end of slice
 *          data: array containing slice
 *          ndims: no of dims of array data
 *          dims: dimensions of array data
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFSDIputslice
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dfsdputslice_(windims, data, dims)
    int32 windims[];
    int32 dims[];
    float32 data[];
{

    return(DFSDIputslice(windims, data, dims, 1));
}


/*-----------------------------------------------------------------------------
 * Name:    dfsdendslice_
 * Purpose: Call DFSDendslice to finish slice writes and write out SDG
 * Inputs:  none
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFSDendslice
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dfsdendslice_()
{

    return(DFSDendslice());
}


/*-----------------------------------------------------------------------------
 * Name:    DFSDsettype_
 * Purpose: Call DFSDsettype to set data type, m/c type, no type and array order
 * Inputs:  datatype, mctype, numtype, arrayorder: integers specifying values
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFSDsettype
 * Remarks: 0 specifies default value
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dfsdsettype_(datatype, mctype, numtype, arrayorder)
    int *datatype, *mctype, *numtype, *arrayorder;
{

    return(DFSDsettype(*datatype, *mctype, *numtype, *arrayorder));
}


/*-----------------------------------------------------------------------------
 * Name:    dfsdlastref
 * Purpose: Return last ref written or read
 * Inputs:  none
 * Globals: Lastref
 * Returns: ref on success, -1 on error with DFerror set
 * Users:   HDF users, utilities, other routines
 * Invokes: DFANlastref
 * Remarks: none
 *---------------------------------------------------------------------------*/

    FCALLKEYW int
dfsdlastref_()
{
    return(DFSDlastref());
}

