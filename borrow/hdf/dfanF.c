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
Revision 1.1.1.1  1990/09/28 21:49:49  teuben
UIUC 15-feb-2001 w/out wip and some manuals

 * Revision 3.6  90/06/21  10:06:02  mfolk
 * No changes. (Mfolk)
 * 
 * Revision 3.5  90/05/25  15:29:31  mfolk
 * Added routines for file annotations:
 * 
 *     dfanaddfds_
 *     dfangetfidlen_
 *     dfangetfdslen_
 *     dfangetfid_
 *     dfangetfds_
 *     daafds_
 *     dagfidl_
 *     dagfdsl_
 *     dagfid_
 *     dagfds_
 * 
 *     daiafid_
 * 
 * Also added dfanlastref_ and dalref_
 * 
 * Mike Folk
 * 
 * Revision 3.4  90/05/17  17:49:24  clow
 * fix bug with the position of include
 * 
 * Revision 3.3  90/05/14  23:09:35  clow
 * "beautify" function declaration with MACROs
 * 
 * Revision 3.2  90/05/10  13:57:29  clow
 * changed Fortran to C character array interface to use _fcd and _fcdtocp
 * 
 * Revision 3.1  90/04/19  16:37:44  clow
 *  Changed interface to be more VMS compatible by
 * converting all character arrays, not just filenames
 * 
 * Revision 3.0  90/02/02  20:30:40  clow
 * *** empty log message ***
 * 
*/

/*-----------------------------------------------------------------------------
 * File:    dfanF.c
 * Purpose: Fortran stubs for annotation routines
 * Invokes: dfan.c dfkit.c
 * Contents: 
 *
 *  daiganl_: get length of annotation of tag/ref
 *  daigann_: get annotation of tag/ref
 *  daipann_: put annotation of tag/ref
 *  dailist_: get list of refs and labels for a given tag
 *  dalref_ : return last ref written or read
 *  dfanlastref_: return last ref written or read
 *
 *  dfanaddfds_    : add file description
 *  dfangetfidlen_ : get length of file id  
 *  dfangetfdslen_ : get length of file description  
 *  dfangetfid_    : get file id
 *  dfangetfds_    : get file description
 *  daafds_        : get file description
 *  dagfidl_       : get file id length
 *  dagfdsl_       : get file description length
 *  dagfid_        : get file id
 *  dagfds_        : get file description
 *
 *  daiafid_       : add file id (intermediate routine)
 *---------------------------------------------------------------------------*/

#include "dfan.h"

#ifdef DF_CAPFNAMES
#   define daiganl_	DAIGANL
#   define daigann_	DAIGANN
#   define daipann_	DAIPANN
#   define dailist_	DAILIST
#   define dalref_  DALREF
#   define dfanlastref_ DFANLASTREF

#   define dfanaddfds_     DFANADDFDS
#   define dfangetfidlen_  DFANGETFIDLEN
#   define dfangetfdslen_  DFANGETFDSLEN
#   define dfangetfid_     DFANGETFID
#   define dfangetfds_     DFANGETFDS
#   define daafds_         DAAFDS
#   define dagfidl_        DAGFIDL
#   define dagfdsl_        DAGFDSL
#   define dagfid_         DAGFID
#   define dagfds_         DAGFDS
#   define daiafid_        DAIAFID
#endif /* DF_CAPFNAMES */


/* conventions used in forming names of routines:
**
**    dfan: hdf annotation routine (<dfan>addfds)
**    add:  add item to file       dfan<add>fds
**    get:  get item from file     dfan<get>fds
**    f:    file                   dfanadd<f>ds
**    id:   id                     dfanaddf<id>
**    ds:   description            dfanaddf<ds>
**    len:  length                 dfanaddfid<len>
**    l:    length (short forms)   dagfid<l>
**    da:   dfan (short forms)     <da>gfid
**    a:    add (short forms)      da<a>fds
**    g:    get (short forms)      da<g>fds
**    i:    intermediate routine (not in user interface) da<i>afid
**/



/*---------------------------------------------------------------------------
** Routines for handling tag/ref (not file) annotations
/*---------------------------------------------------------------------------

/*-----------------------------------------------------------------------------
 * Name:    daiganl
 * Purpose: get length of annotation of tag/ref
 * Inputs:  filename: name of HDF file
 *          tag, ref: tag/ref of item of which we want label
 *          type: DFAN_LABEL if label, DFAN_DESC if description
 *          fnlen: length of filename
 * Returns: length of annotation on success, -1 on failure with DFerror set
 * Users:   HDF HLL users, utilities, other routines
 * Invokes: DFANIgetannlen, DFIf2cstring, DFIgetspace, DFIfreespace
 *---------------------------------------------------------------------------*/

	FCALLKEYW int32
daiganl_(filename, tag, ref, type, fnlen)
    _fcd filename;
    int *tag, *ref;
    int *fnlen, *type;
{
    char *fn;
    int ret;

    fn = DFIf2cstring(filename, *fnlen);
    ret = DFANIgetannlen(fn, (uint16)*tag, (uint16)*ref, *type);
    (void) DFIfreespace(fn);

    return(ret);
}


/*-----------------------------------------------------------------------------
 * Name:    daigann
 * Purpose: get annotation of tag/ref
 * Inputs:  filename: name of HDF file
 *          tag, ref: tag/ref of item of which we want label
 *          annotation: space to return label in
 *          maxlen: size of space to return label in
 *          type: DFAN_LABEL if label, DFAN_DESC if description
 *          fnlen: length of filename
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL users, utilities, other routines
 * Invokes: DFANIgetann
 *---------------------------------------------------------------------------*/

	FCALLKEYW int32
daigann_(filename, tag, ref, annotation, maxlen, type, fnlen)
    _fcd filename, annotation;
    int *tag, *ref;
    int *maxlen, *type, *fnlen;
{
    char *fn;
    int ret;

    fn = DFIf2cstring(filename, *fnlen);
    ret = DFANIgetann(fn, (uint16)*tag, (uint16)*ref, _fcdtocp(annotation), *maxlen, *type);
    (void) DFIfreespace(fn);

    return(ret);
}


/*-----------------------------------------------------------------------------
 * Name:    daipann
 * Purpose: put annotation of tag/ref
 * Inputs:  filename: name of HDF file
 *          tag, ref: tag/ref of item of which we want label
 *          annotation: space to return label in
 *          annlen: length of annotation
 *          type: DFAN_LABEL if label, DFAN_DESC if description
 *          fnlen: length of filename
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL users, utilities, other routines
 * Invokes: DFANIgetann
 *---------------------------------------------------------------------------*/

	FCALLKEYW int32
daipann_(filename, tag, ref, annotation, annlen, type, fnlen)
    _fcd filename, annotation;
    int *tag, *ref;
    int *annlen, *type, *fnlen;
{
    char *fn;
    int ret;

    fn = DFIf2cstring(filename, *fnlen);
    ret = DFANIputann(fn, (uint16)*tag, (uint16)*ref, _fcdtocp(annotation), 
                                                              *annlen, *type);
    (void) DFIfreespace(fn);

    return(ret);
}


/*-----------------------------------------------------------------------------
 * Name:    dailist
 * Purpose: Return list of refs and labels for a given tag
 * Inputs:  filename: name of HDF file
 *          tag: tag to get list of refs and labels for
 *          reflist: array to place refs in
 *          labellist: array of strings to place labels in
 *          listsize: size of ref and label lists
 *          maxlen: maximum length allowed for label
 *          startpos: beginning from the startpos'th entry, upto listsize
 *              entries will be returned.
 *          fnlen: length of filename
 * Returns: number of entries on success, -1 on error with DFerror set
 * Users:   HDF users, utilities, other routines
 * Invokes: DFANIlablist
 * Method:  call DFANIlablist
 * Remarks: none
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dailist_(filename, tag, reflist, labellist,listsize, maxlen,startpos,fnlen)
    _fcd filename;
    int *tag, reflist[];
    _fcd labellist;
    int *listsize;
    int *maxlen, *startpos, *fnlen;
{
    char *fn;
    int ret, i;
    uint16 *tempreflist;

    fn = DFIf2cstring(filename, *fnlen);

    /* create reflist with true uint16s to maintain compatibility
    ** with machines that allocate more than 16 bits per uint16.
    */
    tempreflist = (uint16 *) DFIgetspace( (*maxlen) * sizeof(uint16) );
                                                /* 1 for isfortran */
    ret = DFANIlablist(fn, (uint16)*tag, tempreflist, _fcdtocp(labellist),
		                                   *listsize, *maxlen, *startpos, 1);

    /* move ref numbers into caller's reflist */
    for (i=0; i < *maxlen; i++)
        reflist[i] = tempreflist[i];

    (void) DFIfreespace(fn);
    (void) DFIfreespace(tempreflist);

    return(ret);
}


/*-----------------------------------------------------------------------------
 * Name:    dalref
 * Purpose: Return last ref written or read
 * Inputs:  none
 * Globals: Lastref
 * Returns: ref on success, -1 on error with DFerror set
 * Users:   HDF users, utilities, other routines
 * Invokes: DFANlastref
 * Remarks: none
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dalref_()
{
    return(DFANlastref());
}



/*-----------------------------------------------------------------------------
 * Name:    dfanlastref
 * Purpose: Return last ref written or read
 * Inputs:  none
 * Globals: Lastref
 * Returns: ref on success, -1 on error with DFerror set
 * Users:   HDF users, utilities, other routines
 * Invokes: DFANlastref
 * Remarks: none
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dfanlastref_()
{
    return(DFANlastref());
}



/*---------------------------------------------------------------------------
** Routines for handling file annotations
/*---------------------------------------------------------------------------

/*-----------------------------------------------------------------------------
 * Name:    dfanaddfds
 * Purpose: add file description (Fortran callable C version)
 * Inputs:  dfile: pointer to HDF file
 *          desc: description to write to file
 *          desclen: length of description
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL users, utilities, other routines
 * Invokes: DFANaddfileann
 *---------------------------------------------------------------------------*/

    FCALLKEYW int32
dfanaddfds_(dfile, desc, desclen)
    int *dfile;
    _fcd  desc;
    int *desclen; 
{
    return ( DFANIaddfann(*dfile, desc, (int32) *desclen, DFAN_DESC) );
}

/*-----------------------------------------------------------------------------
 * Name:    dfangetfidlen
 * Purpose: get length of next file ID (Fortran callable C version)
 * Inputs:  dfile: pointer to HDF file
 *          isfirst: 1: start with first one; 0: get length of next one
 * Returns: On success: length of next file ID; On failure: -1, with DFerror set
 * Users:   HDF HLL users, utilities, other routines
 * Invokes: DFANIgetfannlen
 *---------------------------------------------------------------------------*/

    FCALLKEYW int32
dfangetfidlen_(dfile, isfirst)
    int *dfile;
    int *isfirst;
{
     return ( DFANIgetfannlen(*dfile, DFAN_LABEL, *isfirst) );
}


/*-----------------------------------------------------------------------------
 * Name:    dfangetfdslen
 * Purpose: get length of next file description (Fortran callable C version)
 * Inputs:  dfile: pointer to HDF file
 *          isfirst: 1: start with first one; 0: get length of next one
 * Returns: On success: length of next file ID; On failure: -1, with DFerror set
 * Users:   HDF HLL users, utilities, other routines
 * Invokes: DFANIgetfannlen
 *---------------------------------------------------------------------------*/

    FCALLKEYW int32
dfangetfdslen_(dfile, isfirst)
    int *dfile;
    int *isfirst;
{
     return ( DFANIgetfannlen(*dfile, DFAN_DESC, *isfirst) );
}


/*-----------------------------------------------------------------------------
 * Name:    dfangetfid
 * Purpose: get file ID (Fortran callable C version)
 * Inputs:  dfile: pointer to HDF file
 *          desc: description to write to file
 *          desclen: length of description
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL users, utilities, other routines
 * Invokes: DFANgetfann
 *---------------------------------------------------------------------------*/

    FCALLKEYW int32
dfangetfid_(dfile, id, maxlen, isfirst)
    int *dfile;
    _fcd  id;
    int *maxlen;
    int *isfirst;
{
    return ( DFANIgetfann(*dfile, id, (int32) *maxlen, DFAN_LABEL, *isfirst) );
}


/*-----------------------------------------------------------------------------
 * Name:    dfangetfds
 * Purpose: get file description (Fortran callable C version)
 * Inputs:  dfile: pointer to HDF file
 *          desc: description to write to file
 *          desclen: length of description
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL users, utilities, other routines
 * Invokes: DFANgetfann
 *---------------------------------------------------------------------------*/

    FCALLKEYW int32
dfangetfds_(dfile, id, maxlen, isfirst)
    int *dfile;
     _fcd  id;
    int *maxlen;
    int *isfirst;
{
    return ( DFANIgetfann(*dfile, id, (int32) *maxlen, DFAN_DESC, *isfirst) );
}

/*-----------------------------------------------------------------------------
** Versions with short names
**---------------------------------------------------------------------------*/

/*-----------------------------------------------------------------------------
 * Name:    daafds
 * Purpose: add file description (short form of DFANaddfds; Fortran callable)
 * Inputs:  dfile: pointer to HDF file
 *          desc: description to write to file
 *          desclen: length of description
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL users, utilities, other routines
 * Invokes: DFANaddfileann
 *---------------------------------------------------------------------------*/

    FCALLKEYW int32
daafds_(dfile, desc, desclen)
    int *dfile;
    _fcd  desc;
    int *desclen;
{
    return ( DFANIaddfann(*dfile, desc, (int32) *desclen, DFAN_DESC) );
}


/*-----------------------------------------------------------------------------
 * Name:    dagfidl
 * Purpose: get length of next file ID
 * Inputs:  dfile: pointer to HDF file
 *          isfirst: 1: start with first one; 0: get length of next one
 * Returns: On success: length of next file ID; On failure: -1, with DFerror set
 * Users:   HDF HLL users, utilities, other routines
 * Invokes: DFANIgetfannlen
 *---------------------------------------------------------------------------*/

    FCALLKEYW int32
dagfidl_(dfile, isfirst)
    int *dfile;
    int *isfirst;
{
     return ( DFANIgetfannlen(*dfile, DFAN_LABEL, *isfirst) );
}


/*-----------------------------------------------------------------------------
 * Name:    dagfdsl 
 * Purpose: get length of next file description (Fortran callable C version) 
 * Inputs:  dfile: pointer to HDF file
 *          isfirst: 1: start with first one; 0: get length of next one
 * Returns: On success: length of next file ID; On failure: -1, with DFerror set
 * Users:   HDF HLL users, utilities, other routines
 * Invokes: DFANIgetfannlen
 *---------------------------------------------------------------------------*/

    FCALLKEYW int32
dagfdsl_(dfile, isfirst)
    int *dfile;
    int *isfirst;
{
     return ( DFANIgetfannlen(*dfile, DFAN_DESC, *isfirst) );
}


/*-----------------------------------------------------------------------------
 * Name:    dagfid
 * Purpose: get file ID (short form of DFANgetfid; Fortran callable version)
 * Inputs:  dfile: pointer to HDF file
 *          desc: description to write to file
 *          desclen: length of description
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL users, utilities, other routines
 * Invokes: DFANIgetfann
 *---------------------------------------------------------------------------*/

    FCALLKEYW int32
dagfid_(dfile, id, maxlen, isfirst)
    int *dfile;
    _fcd  id;
    int *maxlen;
    int *isfirst;
{
    return ( DFANIgetfann(*dfile, id, (int32) *maxlen, DFAN_LABEL, *isfirst) );
}


/*-----------------------------------------------------------------------------
 * Name:    dagfds
 * Purpose: get file description 
 *          (short form of DFANgetfds; Fortran callable C version)
 * Inputs:  dfile: pointer to HDF file
 *          desc: description to write to file
 *          desclen: length of description
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL users, utilities, other routines
 * Invokes: DFANgetfann
 *---------------------------------------------------------------------------*/

    FCALLKEYW int32
dagfds_(dfile, id, maxlen, isfirst)
    int *dfile;
    _fcd  id;
    int *maxlen;
    int *isfirst;
{
    return ( DFANIgetfann(*dfile, id, (int32) *maxlen, DFAN_DESC, *isfirst) );
}



/*-----------------------------------------------------------------------------
** Intermediate routines called from user's fortran routines
**---------------------------------------------------------------------------*/

/*-----------------------------------------------------------------------------
 * Name:    daiafid
 * Purpose: intermediate routine to add file ID (Fortran callable C version)
 * Inputs:  dfile: pointer to HDF file
 *          id: ID to write to file
 *          idlen: length of ID string
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   Fortran user routines DFANaddfid and daafid
 * Invokes: DFANaddfann
 *---------------------------------------------------------------------------*/

    FCALLKEYW int32 
daiafid_(dfile, id, idlen)
    int *dfile;
    _fcd  id;
    int *idlen;
{
    return(DFANIaddfann( (DF *)*dfile, _fcdtocp(id),*idlen, DFAN_LABEL));
}

