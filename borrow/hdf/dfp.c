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
Revision 1.1.1.1  1990/09/28 21:49:58  teuben
UIUC 15-feb-2001 w/out wip and some manuals

 * Revision 3.1  90/07/02  11:52:10  clow
 * some cosmetic modifications
 * 
 * Revision 3.0  90/02/02  20:30:53  clow
 * *** empty log message ***
 * 
*/

/*-----------------------------------------------------------------------------
 * File:    dfp.c
 * Purpose: read and write palettes
 * Invokes: df.c
 * Contents: 
 *  DFPgetpal: retrieve next palette
 *  DFPputpal: write palette to file
 *  DFPaddpal: add palette to file
 *  DFPnpals: number of palettes in HDF file
 *  DFPreadref: get palette with this reference number next
 *  DFPwriteref: put palette with this reference number next
 *  DFPrestart: forget info about last file accessed - restart from beginning
 *  DFPlastref: return reference number of last element read or written
 *  DFPIopen: open/reopen file
 *---------------------------------------------------------------------------*/

#include "df.h"

static uint16 Readref=0;
static uint16 Writeref=0;
static uint16 Refset=0;		/* Ref of palette to get next */
static uint16 Lastref = 0;	/* Last ref read/written */

static char Lastfile[DF_MAXFNLEN]; /* last file opened */

#ifndef VMS
DF *DFPIopen();
#else /*VMS*/
DF *_DFPIopen();
#endif


/*-----------------------------------------------------------------------------
 * Name:    DFPgetpal
 * Purpose: get next palette from file
 * Inputs:  filename: name of HDF file
 *          palette: 768 byte space to read palette into
 * Returns: 0 on success, -1 on failure with DFerror set
 *          palette in pal
 * Users:   HDF HLL users, utilities, other routines
 * Invokes: DFPIopen, DFIerr, DFclose, DFgetelement
 *---------------------------------------------------------------------------*/

int DFPgetpal(filename, palette)
char *filename;
char *palette;
{
    DF *dfile;
    int cdd, ret;
    DFdle *dlep;

    DFerror = DFE_NOERROR;

    if (!palette) {
        DFerror = DFE_BADPTR;
        return(-1);
    }
    dfile = DFPIopen(filename, DFACC_READ);
    if (dfile == NULL) return(-1);

    if (Refset)
        ret = DFIfind(dfile, DFTAG_IP8, Refset, 1,(uint16) 0, (uint16) 0,
		      &dlep, &cdd);
    else
        ret = DFIfind(dfile,DFTAG_IP8,0, !Readref, DFTAG_IP8,Readref,
		      &dlep,&cdd);

    Refset = 0;
    if (ret<0) return(DFIerr(dfile)); /* on error, close file and return -1 */

    Readref = dlep->dd[cdd].ref; /* ref of element to read */

        /* read palette */
    if (DFgetelement(dfile, DFTAG_IP8, Readref, palette)<0)
            return(DFIerr(dfile));

    Lastref = Readref;

    return(DFclose(dfile));
}


/*-----------------------------------------------------------------------------
 * Name:    DFPputpal
 * Purpose: Write palette to file
 * Inputs:  filename: name of HDF file
 *          palette: palette to be written to file
 *          overwrite: if 1, overwrite last palette read or written
 *                     if 0, write it as a fresh palette
 *          filemode: if "a", append palette to file
 *                    if "w", create new file
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF users, programmers, utilities
 * Invokes: DFPIopen, DFclose, DFputelement, DFIerr
 * Remarks: To overwrite, the filename must be the same as for the previous
 *          call
 *---------------------------------------------------------------------------*/

int DFPputpal(filename, palette, overwrite, filemode)
char *filename;
char *palette;
int overwrite;
char *filemode;
{
    DF *dfile;

    DFerror = DFE_NOERROR;

    if (!palette) {
        DFerror = DFE_BADPTR;
        return(-1);
    }

    if (overwrite && strcmp(filename, Lastfile)) {
        DFerror = DFE_BADCALL;
        return(-1);
    }

    dfile = DFPIopen(filename, (*filemode=='w') ? DFACC_CREATE : DFACC_WRITE);
    if (dfile==NULL) return(-1);

        /* if we want to overwrite, Lastref is the ref to write.  If not, if
            Writeref is set, we use that ref.  If not we get a fresh ref. The
            ref to write is placed in Lastref */
    if (!overwrite) Lastref = Writeref ? Writeref : DFnewref(dfile);
    if (Lastref == 0) return(-1);

    Writeref = 0;           /* don't know ref to write after this */

        /* write out palette */
    if (DFputelement(dfile, DFTAG_IP8, Lastref, palette, (int32) 768)<0)
            return(DFIerr(dfile));

    return(DFclose(dfile));
}


/*-----------------------------------------------------------------------------
 * Name:    DFPaddpal
 * Purpose: Add palette to file
 * Inputs:  filename: name of HDF file
 *          palette: palette to be written to file
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF users, programmers, utilities
 * Invokes: DFPputpal
 *---------------------------------------------------------------------------*/

int DFPaddpal(filename, palette)
char *filename;
char *palette;
{

    return(DFPputpal(filename, palette, 0, "a"));
}


/*-----------------------------------------------------------------------------
 * Name:    DFPnpals
 * Purpose: How many palettes are present in this file?
 * Inputs:  filename: name of HDF file
 * Returns: number of palettes on success, -1 on failure with DFerror set
 * Users:   HDF programmers, other routines and utilities
 * Invokes: DFPIopen, DFclose, DFnumber
 *---------------------------------------------------------------------------*/

int DFPnpals(filename)
char *filename;
{
    DF *dfile;
    int npals=0;

    DFerror = DFE_NOERROR;

    /* should use reopen if same file as last time - more efficient */
    dfile = DFPIopen(filename, DFACC_READ);
    if (dfile==NULL) return(-1);

    npals = DFnumber(dfile, DFTAG_IP8);	/* count number of IPs */
    if (npals<0) return(DFIerr(dfile));

    if (DFclose(dfile)<0) return(-1);
    return(npals);
}


/*-----------------------------------------------------------------------------
 * Name:    DFPreadref
 * Purpose: Set ref of palette to get next
 * Inputs:  filename: file to which this applies
 *          ref: reference number of next get
 * Returns: 0 on success, -1 on failure
 * Users:   HDF programmers, other routines and utilities
 * Invokes: DFPIopen, DFIfind, DFclose
 * Remarks: checks if palette with this ref exists
 *---------------------------------------------------------------------------*/

int DFPreadref(filename, ref)
char *filename;
uint16 ref;
{
    DF *dfile;
    int cdd;
    DFdle *dlep;

    DFerror = DFE_NOERROR;

    dfile = DFPIopen(filename, DFACC_READ);
    if (dfile==NULL) return(-1);

    if (DFIfind(dfile, DFTAG_IP8, ref, 1, 0, 0, &dlep, &cdd)<0)
        return(DFIerr(dfile));

    Refset = ref;
    return(DFclose(dfile));
}


/*-----------------------------------------------------------------------------
 * Name:    DFPwriteref
 * Purpose: Set ref of palette to put next
 * Inputs:  filename: file to which this applies
 *          ref: reference number of next put
 * Returns: 0 on success, -1 on failure
 * Users:   HDF programmers, other routines and utilities
 * Invokes: none
 *---------------------------------------------------------------------------*/

/* shut lint up */
/* ARGSUSED */
int DFPwriteref(filename, ref)
char *filename;
uint16 ref;
{
    DFerror = DFE_NOERROR;

    Writeref = ref;
    return(0);
}



/*-----------------------------------------------------------------------------
 * Name:    DFPrestart
 * Purpose: Do not remember info about file - get again from first palette
 * Inputs:  none
 * Returns: 0 on success
 * Users:   HDF programmers
 * Remarks: Just reset Lastfile to NULL
 *---------------------------------------------------------------------------*/

int DFPrestart()
{

    Lastfile[0] = '\0';
    return(0);
}


/*-----------------------------------------------------------------------------
 * Name:    DFPlastref
 * Purpose: Return last ref written or read
 * Inputs:  none
 * Globals: Lastref
 * Returns: ref on success, -1 on error with DFerror set
 * Users:   HDF users, utilities, other routines
 * Invokes: none
 * Method:  return Lastref
 * Remarks: none
 *---------------------------------------------------------------------------*/

int DFPlastref()
{

    return(Lastref);
}



/******************************************************************************/
/*----------------------- Internal routines ---------------------------------*/
/******************************************************************************/


/*-----------------------------------------------------------------------------
 * Name:    DFPIopen
 * Purpose: open or reopen a file
 * Inputs:  filename: name of file to open
 *          access : access mode
 * Returns: file pointer on success, NULL on failure with DFerror set
 * Users:   HDF systems programmers, other DFP routines
 * Invokes: DFopen
 * Remarks: This is a hook for someday providing more efficient ways to
 *          reopen a file, to avoid re-reading all the headers
 *---------------------------------------------------------------------------*/

DF *DFPIopen(filename, access)
char *filename;
int access;
{

    DF *dfile;

        /* use reopen if same file as last time - more efficient */
    if (strncmp(Lastfile,filename,DF_MAXFNLEN) || (access==DFACC_CREATE)) {
                                    /* treat create as different file */
        if (!(dfile = DFopen(filename, access, -1))) return(NULL);
        Refset = 0;         /* no ref to get set for this file */
        Readref = 0;
    }
    else
        if (!(dfile = DFopen(filename, access, -1))) return(NULL);

    DFIstrncpy(Lastfile, filename, DF_MAXFNLEN);
        /* remember filename, so reopen may be used next time if same file */
    return(dfile);
}
