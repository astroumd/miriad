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
Revision 1.1.1.1  1990/09/28 21:49:54  teuben
UIUC 15-feb-2001 w/out wip and some manuals

 * Revision 3.1  90/07/02  10:13:24  clow
 * some cosmetic modifications
 * 
*/
/*-----------------------------------------------------------------------------
 * File:    dfgroup.c
 * Purpose: Low level functions for implementing groups
 * Invokes: df.c df.h
 * Contents: 
 *  DFdiread: read in the data identifier list from the group
 *  DFdiget: get next data identifier from list
 *  DFdisetup: get ready to store a list of data identifiers to write out
 *  DFdiput: add a data identifier to the list to be written out
 *  DFdiwrite: write out the list of data identifiers
 *  DFDIputgroup: write out a group (array of tag/refs)
 *  DFDIgetgroup: read in a group (array of tag/refs)
 * Remarks: A group is a way of associating data elements with each other.
 *          It is a tag whose data is a list of tag/refs
 *          Each tag/ref combination is called a data identifier (DI).
 *---------------------------------------------------------------------------*/


#include "df.h"


static DFdi *Dilist=NULL;	/* list of tag/refs constituting group */
static int Dinlist;             /* no of tag/refs in list */
static int Ndi;                 /* current position in list */

/*-----------------------------------------------------------------------------
 * Name:    DFdiread
 * Purpose: Read a list of DIs into memory
 * Inputs:  dfile: HDF file pointer
 *          tag, ref: id of group which is to be read in
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF systems programmers, DF8getrig, other routines
 * Invokes: DFIcheck, DFIfind, DFgetelement
 * Remarks: assumes tag is a group
 *---------------------------------------------------------------------------*/

int DFdiread(dfile, tag, ref)
DF *dfile;
uint16 tag, ref;		/* tag, ref of group */
{
    DFdle *dlep;
    int cdd;
    int32 length;

    if (DFIcheck(dfile))
        return(-1);

    /* find group */
    if (DFIfind(dfile, tag, ref, 1, 0, 0, &dlep, &cdd) <0) {
        DFerror = DFE_NOMATCH;
        return(-1);
    }

    /* get space for group */
    length = dlep->dd[cdd].length;
    if (Dilist) DFIfreespace((char*)Dilist); /* ensure earlier allocs freed */
    Dilist = (DFdi *) DFIgetspace((unsigned)length);
    if (!Dilist) {
        DFerror = DFE_NOSPACE;
        return(-1);
    }

    Dinlist = length / 4;	/* 4==sizeof DFdi */
    Ndi = 0;			/* no DIs returned so far */

    /* read in group */
    if (DFgetelement(dfile, tag, ref, (char*) Dilist)<0) {
        DFIfreespace((char*)Dilist);
        Dilist = NULL;		/* flag value */
        return(-1);
    }
    return(0);
}

/*-----------------------------------------------------------------------------
 * Name:    DFdiget
 * Purpose: reaturn next DI from list
 * Inputs:  di: space to return DI
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF systems programmers, DF8getrig, other routines
 * Invokes: none
 * Remarks: frees Dilist space when all DIs returned
 *---------------------------------------------------------------------------*/

int DFdiget(di)
DFdi *di;
{
    if (Ndi>=Dinlist)
	return(-1);

#ifdef DF_STRUCTOK
    *di = Dilist[Ndi++];	/* return next DI on list */
#else /*DF_STRUCTOK*/
    {
        register char *p;
	/* compute address of Ndi'th di */
        p = (char *) Dilist + 4 * Ndi++;
        UINT16READ(p, di->tag);
        UINT16READ(p, di->ref);
    }
#endif /*DF_STRUCTOK*/
    
    if (Ndi==Dinlist) {
        DFIfreespace((char*)Dilist); /* if all returned, free storage */
        Dilist = NULL;		/* flag value */
    }
    return(0);
}


/*-----------------------------------------------------------------------------
 * Name:    DFdisetup
 * Purpose: setup space for storing a list of DIs to be written out
 * Inputs:  maxsize: maximum number of DIs expected in the list
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF systems programmers, DF8putrig, other routines
 * Invokes: none
 * Remarks: This call should go away sometime.  Need better way to allocate
 *          space, possibly just use a big block of static space
 *---------------------------------------------------------------------------*/

int DFdisetup(maxsize)
int maxsize;
{
    if (Dilist) DFIfreespace((char*)Dilist);
    Dilist = (DFdi *) DFIgetspace((unsigned)(maxsize * 4));
				/* 4==sizeof(DFdi) */
    if (!Dilist) {
        DFerror = DFE_NOSPACE;
        return(-1);
    }
    Dinlist = maxsize;		/* maximum size of list */
    Ndi = 0;                    /* current size of list */
    return(0);
}

/*-----------------------------------------------------------------------------
 * Name:    DFdiput
 * Purpose: add a DI to the list to be written out
 * Inputs:  tag, ref: DI to add
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF systems programmers, DF8putrig, other routines
 * Invokes: none
 * Remarks: arg is tag/ref rather than DI for convenience
 *---------------------------------------------------------------------------*/

int DFdiput(tag, ref)
uint16 tag, ref;
{
    register char *p;

    if (Ndi>=Dinlist) {
        DFerror = DFE_NOTENOUGH;
        return(-1);
    }

#ifdef DF_STRUCTOK
    Dilist[Ndi].tag = tag;
    Dilist[Ndi++].ref = ref;
#else /*DF_STRUCTOK*/
    /* compute address of Ndi'th di to put tag/ref in */
    p = (char *) Dilist + 4 * Ndi++;
    UINT16WRITE(p, tag);
    UINT16WRITE(p, ref);
#endif /*DF_STRUCTOK*/

    return(0);
}

/*-----------------------------------------------------------------------------
 * Name:    DFdiwrite
 * Purpose: Write DI list out to HDF file
 * Inputs:  dfile: HDF file pointer
 *          tag, ref: tag and ref of group whose contents is the list
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF systems programmers, DF8putrig, other routines
 * Invokes: none
 * Remarks: frees storage for Dilist
 *---------------------------------------------------------------------------*/

int DFdiwrite(dfile, tag, ref)
DF *dfile;
uint16 tag, ref;
{
    int ret;			/* return value */

    if (DFIcheck(dfile))
        return(-1);

    ret = DFputelement(dfile, tag, ref, (char*)Dilist,(int32)Ndi*4);
				/* 4==sizeof(DFdi) */
    DFIfreespace((char*)Dilist);
    Dilist = NULL;		/* flag value */
    Dinlist = Ndi = 0;
    return(ret);
}

/*-----------------------------------------------------------------------------
 * Name:    DFDIgetgroup
 * Purpose: Read array of tag/refs from file
 * Inputs:  filename: name of HDF file to read from
 *          diarray: array to put tag/refs in
 *          maxdis: maximum number of DIs that may be returned
 *          groupdi: tag/ref of group to read
 * Returns: number of DIs read on success, -1 on failure with DFerror set
 * Users:   HDF systems programmers, other routines
 * Invokes: none
 * Remarks: none
 *---------------------------------------------------------------------------*/

int DFDIgetgroup(filename, diarray, maxdis, groupdi)
char *filename;
int maxdis;
 DFdi diarray[], *groupdi;
{
    DF *dfile;
    int cdd, ret;
    DFdle *dlep;
    
    DFerror = DFE_NOERROR;

    if (!filename[0]) {
        DFerror = DFE_BADPTR;
        return(-1);
    }

    dfile = DFopen(filename, DFACC_ALL, -1);
    if (dfile==NULL) return(-1);

    if (DFIfind(dfile, groupdi->tag, groupdi->ref, 1, 0, 0, &dlep, &cdd)<0)
        return(DFIerr(dfile));

    if (DFaccess(dfile, groupdi->tag, groupdi->ref, "r")<0)
        return(DFIerr(dfile));

    ret = dlep->dd[cdd].length / 4; /* 4==sizeof(DFdi) */
    if (maxdis < ret) ret = maxdis;

#ifdef DF_STRUCTOK
    if (DFread(dfile, diarray, (int32) (ret * sizeof( DFdi)))<0)
        return(DFIerr(dfile));
#else /*DF_STRUCTOK*/
    {
        int i;
        char *p;

        p = (char *) DFtbuf;
        if (DFread(dfile, p, (int32) ret*4)<0)
            return(DFIerr(dfile));

        for (i=0; i<ret; i++) {
            UINT16READ(p, diarray[i].tag);
            UINT16READ(p, diarray[i].ref);
        }
    }
#endif /*DF_STRUCTOK*/
    
    if (ret<maxdis) {
        DFerror = DFE_NOTENOUGH;
        return(DFIerr(dfile));
    }
    return(DFclose(dfile));
}
    
/*-----------------------------------------------------------------------------
 * Name:    DFDIputgroup
 * Purpose: Write array of tag/refs to file
 * Inputs:  filename: name of HDF file to write to
 *          diarray: array of tag/refs to write out
 *          ndis: number of DIs in array
 *          groupdi: tag/ref of group to write array as
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF systems programmers, other routines
 * Invokes: none
 * Remarks: The group is always appended to an existing file
 *---------------------------------------------------------------------------*/

int DFDIputgroup(filename, diarray, ndis, groupdi)
char *filename;
int ndis;
DFdi diarray[], *groupdi;
{
    DF *dfile;
    int ret;
    
    DFerror = DFE_NOERROR;

    if (!filename[0]) {
        DFerror = DFE_BADPTR;
        return(-1);
    }

    dfile = DFopen(filename, DFACC_ALL, -1);
    if (dfile==NULL) return(-1);

#ifdef DF_STRUCTOK
    ret = DFputelement(dfile, groupdi->tag, groupdi->ref, diarray,
		       (int32) (ndis * 4));
#else /*DF_STRUCTOK*/
    {
        int i;
        char *p;

        p = (char *) DFtbuf;
        for (i=0; i<ndis; i++) {
            UINT16WRITE(p, diarray[i].tag);
            UINT16WRITE(p, diarray[i].ref);
        }
        ret = DFputelement(dfile, groupdi->tag, groupdi->ref, p,
			   (int32)ndis*sizeof(DFdi));
    }
#endif /*DF_STRUCTOK*/
    
    if (ret<0) return(DFIerr(dfile));
    return(DFclose(dfile));
}
