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
Revision 1.1.1.1  1990/09/28 21:49:45  teuben
UIUC 15-feb-2001 w/out wip and some manuals

 * Revision 3.5  90/05/17  17:49:20  clow
 * fix bug with the position of include
 * 
 * Revision 3.4  90/05/17  15:56:23  clow
 * make the mac ls_fortran to C call *NOT* have to go through an additional
 * Fortran stub (for %ref()), so we can remove the different function names
 * for the MAC
 * 
 * Revision 3.3  90/05/14  23:09:13  clow
 * "beautify" function declaration with MACROs
 * 
*/
/*-----------------------------------------------------------------------------
 * File:    dfF.c
 * Purpose: C stubs for Fortran low level routines
 * Invokes: dfF.c
 * Contents: 
 *  dfiopen_:   call DFopen to open HDF file
 *  dfclose_:   call DFclose to close HDF file
 *  dfdesc_:    call DFdescriptors to get contents of DDs
 *  dfdup_: call DFdup to create additional DD for item
 *  dfdel_: call DFdel to delete DD of item
 *  dfaccess_:  call DFaccess to set up access to item
 *  dfstart_:   call DFaccess to set up access to item
 *  dfread_:    call DFread to read part of item
 *  dfseek_:    call DFseek to move to offset within item
 *  dfwrite_:   call DFwrite to write part of item
 *  dfupdate_:  call DFupdate to write out changes
 *  dfget_: call DFgetelement to read item
 *  dfput_: call DFputelement to write item
 *  dfsfind_:   call DFsetfind to set up search
 *  dffind_:    call DFfind to find next matching item
 *  dferrno_:   call DFerrno to return value of DFerror
 *---------------------------------------------------------------------------*/

#include "df.h"

#ifdef DF_CAPFNAMES
#   define dfaccess_	DFACCESS
#   define dfiopen_	DFIOPEN
#   define dfclose_	DFCLOSE
#   define dfdesc_	DFDESC
#   define dfdup_	DFDUP
#   define dfdel_	DFDEL
#   define dfaccess_	DFACCESS
#   define dfstart_	DFSTART
#   define dfread_	DFREAD
#   define dfseek_	DFSEEK
#   define dfwrite_	DFWRITE
#   define dfupdate_	DFUPDATE
#   define dfget_	DFGET
#   define dfput_	DFPUT
#   define dfsfind_	DFSFIND
#   define dffind_	DFFIND
#   define dferrno_	DFERRNO
#endif /* DF_CAPFNAMES */

/*-----------------------------------------------------------------------------
 * Name:    dfiopen_
 * Purpose: call DFopen to open HDF file
 * Inputs:  name: name of file to open
 *      access: access mode - integer with value DFACC_READ etc. 
 *      defdds: default number of DDs per header block
 *      namelen: length of name
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFopen
 * Method:  Convert filename to C string, call DFopen
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dfiopen_(name, access, defdds, namelen)

    _fcd name;
    int *access, *defdds, *namelen;
{
    char *fn;
    int ret;
    
    fn = DFIf2cstring(name, *namelen);
    ret = (int) DFopen(fn, *access, *defdds);
    (void) DFIfreespace(fn);
    return(ret);
}


/*-----------------------------------------------------------------------------
 * Name:    dfclose_
 * Purpose: Call DFclose to close HDF file
 * Inputs:  dfile: pointer to HDF file to close
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFclose
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dfclose_(dfile)
    int *dfile;
{
    return(DFclose((DF *)*dfile));
}


/*-----------------------------------------------------------------------------
 * Name:    dfdesc_
 * Purpose: Call DFdescriptors to obtain descriptors
 * Inputs:  dfile: pointer to HDF file
 *          ptr: pointer to array of size >= (4, num) to put descriptors in
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFdesc
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dfdesc_(dfile, ptr, begin, num)
    int *dfile, *begin, *num;
int ptr[][4];
{
    DFdesc *ptr1;
    int i, num_desc;

            /* allocate temporary space */
    ptr1 = (DFdesc *) DFIgetspace((unsigned)(*num * sizeof(DFdesc)));
    num_desc = DFdescriptors((DF*)*dfile, ptr1, *begin, *num);
    
    /* copy ptr1 array  ptr; note row/column inversion */
    for (i=0; i<num_desc; i++)
    {
        ptr[i][0] = ptr1[i].tag;
        ptr[i][1] = ptr1[i].ref;
        ptr[i][2] = ptr1[i].offset;
        ptr[i][3] = ptr1[i].length;
    }

    (void) DFIfreespace((char*) ptr1);

    return num_desc;
}


/*-----------------------------------------------------------------------------
 * Name:    dfdup_
 * Purpose: Call DFdup to create additional DD for item
 * Inputs:  dfile: pointer to HDF file
 *          tag, ref: attributes of new DD to add
 *          otag, oref: attributes of item to point to
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFdup
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dfdup_(dfile, tag, ref, otag, oref)
    int *dfile, *tag, *ref, *oref, *otag;
{

    return(DFdup((DF *)*dfile, (uint16)*tag,(uint16) *ref,(uint16) *otag,
		 (uint16)*oref));
}


/*-----------------------------------------------------------------------------
 * Name:    dfdel_
 * Purpose: Call DFdel to delete DD of item
 * Inputs:  dfile: pointer to HDF file
 *          tag, ref: attributes of DD to delete
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFdel
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dfdel_(dfile, tag, ref)
    int *dfile, *tag, *ref;
{
    return (DFdel((DF *)*dfile, (uint16)*tag, (uint16)*ref));
}


/*-----------------------------------------------------------------------------
 * Name:    dfaccess_
 * Purpose: Call DFaccess to set up access to item
 * Inputs:  dfile: pointer to HDF file
 *          tag, ref: attributes of item to access
 *          access: access mode
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFaccess
 *---------------------------------------------------------------------------*/
	FCALLKEYW int
dfaccess_(dfile, tag, ref, access)
    int *dfile, *tag, *ref;
    char *access;
{

    return(DFaccess((DF *) *dfile, (uint16)*tag, (uint16)*ref, access));
}


#if 0
/*-----------------------------------------------------------------------------
 * Name:    dfstart_
 * Purpose: Call DFaccess to set up access to item
 * Inputs:  dfile: pointer to HDF file
 *          tag, ref: attributes of item to access
 *          access: access mode
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFaccess
 *---------------------------------------------------------------------------*/

#ifdef DF_CAPFNAMES
int DFSTART(dfile, tag, ref, access)
#else DF_CAPFNAMES
int dfstart_(dfile, tag, ref, access)
#endif

int *dfile, *tag, *ref;
char *access;
{

    return(DFaccess((DF *)*dfile, *tag, *ref, access));
}
#endif /* 0 */

/*-----------------------------------------------------------------------------
 * Name:    dfread_
 * Purpose: Call DFread to read part of item
 * Inputs:  dfile: pointer to HDF file
 *          ptr: pointer to space to read item into
 *          len: number of bytes to read
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFread
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dfread_(dfile, ptr, len)
    int *dfile, *len;
    _fcd ptr;
{
    return (DFread((DF *) *dfile, _fcdtocp(ptr), *len));
}

/*-----------------------------------------------------------------------------
 * Name:    dfseek_
 * Purpose: Call DFseek to move to offset within item
 * Inputs:  dfile: pointer to HDF file
 *	    offset: number of bytes from beginning of item to move to
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFseek
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dfseek_(dfile, offset)
    int *dfile, *offset;
{

    return (DFseek((DF *)*dfile, (int32)*offset));
}


/*-----------------------------------------------------------------------------
 * Name:    dfwrite_
 * Purpose: Call DFwrite to write part of item
 * Inputs:  dfile: pointer to HDF file
 *	    ptr: pointer to data to write
 *	    len: number of bytes to write
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFwrite
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dfwrite_(dfile, ptr, len)
    int *dfile, *len;
    _fcd ptr;
{

    return (DFwrite((DF *)*dfile, _fcdtocp(ptr), (int32)*len));
}

/*-----------------------------------------------------------------------------
 * Name:    dfupdate_
 * Purpose: Call DFupdate to write out changes
 * Inputs:  dfile: pointer to HDF file
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFupdate
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dfupdate_(dfile)
    int *dfile;
{

    return (DFupdate((DF *)*dfile));
}


/*-----------------------------------------------------------------------------
 * Name:    dfget_
 * Purpose: Call DFget to read an element
 * Inputs:  dfile: pointer to HDF file
 *	    tag, ref: pointer to item to read
 *	    ptr: space to read item into
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFgetelement
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dfget_(dfile, tag, ref, ptr)
    int *dfile, *tag, *ref;
    _fcd ptr;
{
    return (DFgetelement((DF *)*dfile, (uint16)*tag,
			 (uint16)*ref, _fcdtocp(ptr)));
}


/*-----------------------------------------------------------------------------
 * Name:    dfput_
 * Purpose: Call DFput to write an element
 * Inputs:  dfile: pointer to HDF file
 *	    tag, ref: attributes of item to write
 *	    ptr: item to write
 *	    len: size of item
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFputelement
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dfput_(dfile, tag, ref, ptr, len)
    int *dfile, *tag, *ref, *len;
    _fcd ptr;
{

    return (DFputelement((DF *)*dfile, (uint16)*tag, (uint16)*ref,
			 _fcdtocp(ptr), (int32)*len));
}

/*-----------------------------------------------------------------------------
 * Name:    dfsfind_
 * Purpose: Call DFsetfind to set up search
 * Inputs:  dfile: pointer to HDF file
 *	    tag, ref: attributes of item to find
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFsetfind
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dfsfind_(dfile, tag, ref)
    int *dfile, *tag, *ref;
{
    return (DFsetfind((DF *) *dfile, (uint16)*tag, (uint16)*ref));
}


/*-----------------------------------------------------------------------------
 * Name:    dffind_
 * Purpose: Call DFfind to find next match
 * Inputs:  dfile: pointer to HDF file
 *	    itag, iref: attributes of item found
 *	    len: size of item
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF Fortran programmers
 * Invokes: DFfind
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dffind_(dfile, itag, iref, len)
    int *dfile;
    int *itag, *iref, *len;
{
    DFdesc *ptr1;
    int ret;

    ptr1 = (DFdesc *) DFIgetspace(sizeof(DFdesc));
    ret = DFfind((DF *) *dfile, ptr1);

    *itag  = ptr1->tag;
    *iref = ptr1->ref;
    *len = ptr1->length;

    (void) DFIfreespace((char*)ptr1);

    return(ret);
}


/*-----------------------------------------------------------------------------
 * Name:    DFerrno_
 * Purpose: Call DFerrno to get value of DFerror
 * Inputs:  none
 * Returns: value of DFerror
 * Users:   HDF Fortran programmers
 * Invokes: DFerrno
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dferrno_()
{
    return(DFerrno());
}
