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
Revision 1.1.1.1  1990/09/28 21:49:52  teuben
UIUC 15-feb-2001 w/out wip and some manuals

 * Revision 3.3  90/06/19  11:19:42  clow
 * Implemented DFGRreadref to set next rig to read in.
 * 
 * Revision 3.2  90/05/11  12:55:03  clow
 * added DFGRIrestart() for restarting files for general raster
 * 
 * Revision 3.1  90/05/04  16:26:50  clow
 * changed argument list of DFGRIsetdims
 * added DFGRIsetil
 * 
 * Revision 3.0  90/02/02  20:31:30  clow
 * *** empty log message ***
 * 
*/

/*-----------------------------------------------------------------------------
 * File:    dfgr.c
 * Purpose: read and write general raster images
 * Invokes: df.c, dfkit.c, dfcomp.c, dfgroup.c, dfgr.h
 * Contents: 
 *  DFGRgetlutdims: get dimensions of lookup table
 *  DFGRreqlutil: use this interlace when returning lookup table
 *  DFGRgetlut: read in lookup table
 *  DFGRgetimdims: get dimensions of image
 *  DFGRreqimil: use this interlace when returning image
 *  DFGRgetimage: read in image
 *  DFGRsetcomp: specify compression scheme to be used
 *  DFGRsetlutdims: set dimensions of lookup table
 *  DFGRsetlut: set lookup table to write out with subsequent images
 *  DFGRaddlut: write out lookup table
 *  DFGRsetimdims: set dimensions of image
 *  DFGRaddimage: write out image
 *
 *  DFGRgetrig: read in raster image group
 *  DFGRaddrig: write out raster image group
 *
 *  DFGRIopen: open/reopen file
 *  DFGRIriginfo: obtain info about next RIG
 *  DFGRIgetdims: get dimensions of lut/iamge
 *  DFGRIreqil: get lut/image with this interlace
 *  DFGRIgetimlut: get image/lut
 *  DFGRIsetdims: set image/lut dimensions
 *  DFGRIaddimlut: write out image/lut
 * Remarks: A RIG specifies attributes associated with an image - lookup table, 
 *          dimension, compression, color compensation etc.
 *---------------------------------------------------------------------------*/

#include "dfgr.h"

static char Grlastfile[DF_MAXFNLEN];
static DFGRrig Grread;		/* information about RIG being read */
static DFGRrig Grwrite;         /* information about RIG being written */
static int Grnewdata = 0;	/* does Grread contain fresh data? */
static int Grcompr = 0;         /* compression scheme to use */
char *Grlutdata=NULL;		/* points to lut, if in memory */
static uint16 Grrefset=0;	/* Ref of image to get next */
static uint16 Grlastref = 0;	/* Last ref read/written */
static int Grreqil[2]= {0, 0}; /* requested lut/image il */
static struct {			/* track refs of set vals written before */
    int lut;			/* -1: no vals set */
    int16 dims[2];		/* 0: vals set, not written */
    int nt;			/* non-zero: ref of val in file */
} Ref = {-1, {-1, -1}, -1 };

static DFGRrig Grzrig = {	/* empty RIG for initialization */
    { {0, 0}, {0, 0}, {0, 0}, },
    { {0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0}, },
    0, 0, 0.0, 0.0, {0.0, 0.0, 0.0}, {0.0, 0.0, 0.0},
    {0.0, 0.0, 0.0}, {0.0, 0.0, 0.0}, NULL
};

#ifndef VMS
DF *DFGRIopen();
#else /*VMS*/
DF *_DFGRIopen();
#endif

#define LUT     0
#define IMAGE   1

/*-----------------------------------------------------------------------------
 * Name:    DFGRgetlutdims
 * Purpose: get dimensions of lut from next RIG
 * Inputs:  filename: name of HDF file
 *          pxdim, pydim: pointer to locations for returning x,y dimensions
 *          pncomps: location for returning no of components
 *          pil: location for returning interlace of lut in file
 * Returns: 0 on success, -1 on failure with DFerror set
 *          *pxdim, *pydim, *pncomps, *pil set on success
 * Users:   HDF HLL (high-level library) users, utilities, other routines
 * Invokes: DFGRIgetdims
 * Remarks: none
 *---------------------------------------------------------------------------*/

int DFGRgetlutdims(filename, pxdim, pydim, pncomps, pil)
char *filename;
int32 *pxdim, *pydim;
int *pncomps, *pil;
{

    return(DFGRIgetdims(filename, pxdim, pydim, pncomps, pil, LUT));
}


/*-----------------------------------------------------------------------------
 * Name:    DFGRreqlutil
 * Purpose: get next lut with specified interlace
 * Inputs:  il: interlace to get next lut with
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL (high-level library) users, utilities, other routines
 * Invokes: DFGRIreqil
 * Remarks: none
 *---------------------------------------------------------------------------*/

int DFGRreqlutil(il)
int il;
{
    return(DFGRIreqil(il, LUT));
}


/*-----------------------------------------------------------------------------
 * Name:    DFGRgetlut
 * Purpose: get lut from next RIG
 * Inputs:  filename: name of HDF file
 *          lut: pointer to space to return lookup table
 *          xdim, ydim: dimensions of space to return lut
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL (high-level library) users, utilities, other routines
 * Invokes: DFGRIgetimlut
 * Remarks: space is assumed to be xdim * ydim * ncomps bytes
 *---------------------------------------------------------------------------*/

int DFGRgetlut(filename, lut, xdim, ydim)
char *filename;
char *lut;
int32 xdim, ydim;
{

    /* 0 == C */
    return(DFGRIgetimlut(filename, lut, xdim, ydim, LUT, 0));
}

/*-----------------------------------------------------------------------------
 * Name:    DFGRgetimdims
 * Purpose: get dimensions of next image RIG
 * Inputs:  filename: name of HDF file
 *          pxdim, pydim: pointer to locations for returning x,y dimensions
 *          pncomps: location for returning no of components
 *          pil: location for returning interlace of image in file
 * Returns: 0 on success, -1 on failure with DFerror set
 *          *pxdim, *pydim, *pncomps, *pil set on success
 * Users:   HDF HLL (high-level library) users, utilities, other routines
 * Invokes: DFGRIgetdims
 * Remarks: none
 *---------------------------------------------------------------------------*/

int DFGRgetimdims(filename, pxdim, pydim, pncomps, pil)
char *filename;
int32 *pxdim, *pydim;
int *pncomps, *pil;
{
    return(DFGRIgetdims(filename, pxdim, pydim, pncomps, pil, IMAGE));
}

/*-----------------------------------------------------------------------------
 * Name:    DFGRreqimil
 * Purpose: get next image with specified interlace
 * Inputs:  il: interlace to get next image with
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL (high-level library) users, utilities, other routines
 * Invokes: DFGRIreqil
 * Remarks: none
 *---------------------------------------------------------------------------*/

int DFGRreqimil(il)
int il;
{
    return(DFGRIreqil(il, IMAGE));
}

/*-----------------------------------------------------------------------------
 * Name:    DFGRgetimage
 * Purpose: get image from next RIG
 * Inputs:  filename: name of HDF file
 *          image: pointer to space to return image
 *          xdim, ydim: dimensions of space to return lut
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL (high-level library) users, utilities, other routines
 * Invokes: DFGRIgetimlut
 * Remarks: space is assumed to be xdim * ydim * ncomps bytes
 *---------------------------------------------------------------------------*/

int DFGRgetimage(filename, image, xdim, ydim)
char *filename;
char *image;
int32 xdim, ydim;
{
    /* 0 == C */
    return(DFGRIgetimlut(filename, image, xdim, ydim, IMAGE, 0));
}

/*-----------------------------------------------------------------------------
 * Name:    DFGRsetcompress
 * Purpose: set compression scheme to use
 * Inputs:  scheme: compression scheme
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL (high-level library) users, utilities, other routines
 * Invokes: none
 * Remarks: none
 *---------------------------------------------------------------------------*/

int DFGRsetcompress(scheme)
int scheme;
{
    Grcompr = scheme;
    return(0);
}

/*-----------------------------------------------------------------------------
 * Name:    DFGRsetlutdims
 * Purpose: set dimensions of lut to write next
 * Inputs:  xdim, ydim: dimensions of lut
 *          ncomps: no of components
 *          il: interlace of lut
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL (high-level library) users, utilities, other routines
 * Invokes: DFGRIsetdims
 * Remarks: none
 *---------------------------------------------------------------------------*/

int DFGRsetlutdims(xdim, ydim, ncomps, il)
int32 xdim, ydim;
int ncomps, il;
{
    if (DFGRIsetil(il, LUT) < 0) return -1;
    return(DFGRIsetdims(xdim, ydim, ncomps, LUT));
}


/*-----------------------------------------------------------------------------
 * Name:    DFGRsetlut
 * Purpose: set lut for subsequent RIGs
 * Inputs:  lut: lookup table to write
 *          xdim, ydim: dimensions of array lut
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL (high-level library) users, utilities, other routines
 * Invokes: DFGRIaddimlut
 * Remarks: array lut is assumed to be xdim * ydim * ncomps bytes
 *---------------------------------------------------------------------------*/

int DFGRsetlut(lut, xdim, ydim)
char *lut;
int32 xdim, ydim;
{
    /* 0 == C */
    return(DFGRIaddimlut((char*)NULL, lut, xdim, ydim, LUT, 0));
}


/*-----------------------------------------------------------------------------
 * Name:    DFGRaddlut
 * Purpose: write lut to file, associate it with subsequent RIGs
 * Inputs:  filename: name of HDF file
 *          lut: lookup table to write
 *          xdim, ydim: dimensions of array lut
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL (high-level library) users, utilities, other routines
 * Invokes: DFGRIaddimlut
 * Remarks: array lut is assumed to be xdim * ydim * ncomps bytes
 *---------------------------------------------------------------------------*/

int DFGRaddlut(filename, lut, xdim, ydim)
char *filename;
char *lut;
int32 xdim, ydim;
{
    /* 0 == C */
    return(DFGRIaddimlut(filename, lut, xdim, ydim, LUT, 0));
}


/*-----------------------------------------------------------------------------
 * Name:    DFGRsetimdims
 * Purpose: set dimensions of image to write next
 * Inputs:  xdim, ydim: dimensions of image
 *          ncomps: no of components
 *          il: interlace of image
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL (high-level library) users, utilities, other routines
 * Invokes: DFGRIsetdims
 * Remarks: none
 *---------------------------------------------------------------------------*/

int DFGRsetimdims(xdim, ydim, ncomps, il)
int32 xdim, ydim;
int ncomps, il;
{
    if (DFGRIsetil(il, IMAGE) < 0) return -1;
    return(DFGRIsetdims(xdim, ydim, ncomps, IMAGE));
}

/*-----------------------------------------------------------------------------
 * Name:    DFGRaddimage
 * Purpose: Write out image
 * Inputs:  filename: name of HDF file
 *          image: image to write
 *          xdim, ydim: dimensions of array image
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL (high-level library) users, utilities, other routines
 * Invokes: DFGRIaddimlut
 * Remarks: array image is assumed to be xdim * ydim * ncomps bytes
 *---------------------------------------------------------------------------*/

int DFGRaddimage(filename, image, xdim, ydim)
char *filename;
char *image;
int32 xdim, ydim;
{
    /* 0 == C */
    return(DFGRIaddimlut(filename, image, xdim, ydim, IMAGE, 0));
}


/*-----------------------------------------------------------------------------
 * Name:    DFGRreadref
 * Purpose: Set ref of rig to get next
 * Inputs:  filename: file to which this applies
 *          ref: reference number of next get
 * Returns: 0 on success, -1 on failure
 * Users:   HDF programmers, other routines and utilities
 * Invokes: DFGRIopen, DFIfind, DFclose
 * Remarks: checks if rig with this ref exists
 *---------------------------------------------------------------------------*/

int DFGRreadref(filename, ref)
char *filename;
uint16 ref;
{
    DF *dfile;
    int cdd;
    DFdle *dlep;

    DFerror = DFE_NOERROR;

    dfile = DFGRIopen(filename, DFACC_READ);
    if (dfile==NULL) return(-1);

    if (DFIfind(dfile, DFTAG_RIG, ref, 1, 0, 0, &dlep, &cdd)<0)
        return(DFIerr(dfile));

    Grrefset = ref;
    return(DFclose(dfile));
}


/*****************************************************************************/
/* This is the next lower layer - procedures to read in and write out a RIG. */
/*****************************************************************************/

/*-----------------------------------------------------------------------------
 * Name:    DFGRgetrig
 * Purpose: Read a RIG into memory
 * Inputs:  dfile: pointer to HDF file containing RIG
 *          ref: reference number of RIG to get
 *          rig: struct in which to place info obtained
 * Returns: 0 on success, -1 on failure with DFerror set
 *          contents of RIG in the struct rig
 * Users:   HDF programmers, utilities, DFGRIgetdims,DFGRIgetimlut,
 *          other routines
 * Invokes: DFdiget, DFdinext, DFIcheck, DFgetelement
 * Remarks: incomplete - does not support DFTAG_MA etc.
 *---------------------------------------------------------------------------*/

int DFGRgetrig(dfile, ref, rig)
DF *dfile;
uint16 ref;
DFGRrig *rig;
{
    DFdi elmt;
    char ntstring[4];
    int type;

    DFerror = DFE_NOERROR;

    if (DFIcheck(dfile))
        return( -1);
    if (!ref) {
        DFerror = DFE_BADREF;
        return(-1);
    }

    if (DFdiread(dfile, DFTAG_RIG, ref)<0) /* read RIG into memory */
        return(-1);

    *rig = Grzrig;		/* fill rig with zeroes */
    while (!DFdiget(&elmt)) {	/* get next tag/ref from RIG */
        switch (elmt.tag) {	/* process tag/ref */
            case DFTAG_CI:
            case DFTAG_RI:
            case DFTAG_LUT:
                type = (elmt.tag==DFTAG_LUT) ? LUT : IMAGE;
                rig->data[type].tag = elmt.tag;
                rig->data[type].ref = elmt.ref;
                break;
            case DFTAG_ID:          /* read description info */
            case DFTAG_LD:
                type = (elmt.tag==DFTAG_LD) ? LUT : IMAGE;
#ifdef DF_STRUCTOK
                if (DFgetelement(dfile, elmt.tag, elmt.ref,
				 &rig->datadesc[type])<0)
		    return(-1);
#else /*DF_STRUCTOK*/
		if (DFgetelement(dfile, elmt.tag, elmt.ref, DFtbuf)>0) {
                    register char *p;
                    p = DFtbuf;
                    INT32READ(p, rig->datadesc[type].xdim);
                    INT32READ(p, rig->datadesc[type].ydim);
                    UINT16READ(p, rig->datadesc[type].nt.tag);
                    UINT16READ(p, rig->datadesc[type].nt.ref);
                    INT16READ(p, rig->datadesc[type].ncomponents);
                    INT16READ(p, rig->datadesc[type].interlace);
                    UINT16READ(p, rig->datadesc[type].compr.tag);
                    UINT16READ(p, rig->datadesc[type].compr.ref);
                } else return(-1);
#endif /*DF_STRUCTOK*/
                if (rig->datadesc[type].nt.tag==0) break; /* old RIGs */

		/* read NT */
                if (DFgetelement(dfile, rig->datadesc[type].nt.tag,
				 rig->datadesc[type].nt.ref, ntstring)<0)
                    return(-1);
                if ((ntstring[2]!=8) || (ntstring[1]!=DFNT_UCHAR)) {
                    DFerror = DFE_BADCALL;
                    return(-1);
                }
                break;
            default:		/* ignore unknown tags */
                break;
        }
    }
    return(0);
}

/*-----------------------------------------------------------------------------
 * Name:    DFGRaddrig
 * Purpose: Write RIG struct out to HDF file
 * Inputs:  dfile: HDF file pointer
 *          ref: ref to write RIG with
 *          rig: struct containing RIG info to write
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF programmers, utilities, DFGRIaddimlut, other routines
 * Invokes: DFIcheck, DFdistart, DFdiadd, DFdiend, DFputelement
 * Remarks: none
 *---------------------------------------------------------------------------*/

int DFGRaddrig(dfile, ref, rig)
DF *dfile;
uint16 ref;
DFGRrig *rig;
{
    char ntstring[4];
    int lutsize;

    DFerror = DFE_NOERROR;

    if (DFIcheck(dfile))
        return( -1);
    if (!ref) {
        DFerror = DFE_BADREF;
        return(-1);
    }
    if (Ref.nt<=0) {		/* if nt not previously written to file */
				/* construct and write out NT */
        ntstring[0] = DFNT_VERSION; /* version */
        ntstring[1] = DFNT_UCHAR; /* type */
        ntstring[2] = 8;	/* width: RIG data is 8-bit chars */
        ntstring[3] = DFNTC_BYTE; /* class: data are numeric values */
        if (DFputelement(dfile, DFTAG_NT, ref,(char*)ntstring, (int32) 4) <0)
            return(-1);
        rig->datadesc[IMAGE].nt.tag = DFTAG_NT;
        rig->datadesc[IMAGE].nt.ref = ref;
        Ref.nt = ref;
    }
        
    if (Ref.dims[IMAGE]==0) {
#ifdef DF_STRUCTOK		/* write out description record */
        if (DFputelement(dfile, DFTAG_ID, ref, &rig->datadesc[IMAGE], /* ID */
			 sizeof(rig->datadesc[IMAGE]))<0)
            return(-1);
#else /*DF_STRUCTOK*/
        register char *p;
        p = DFtbuf;
        INT32WRITE(p, rig->datadesc[IMAGE].xdim);
        INT32WRITE(p, rig->datadesc[IMAGE].ydim);
        UINT16WRITE(p, rig->datadesc[IMAGE].nt.tag);
        UINT16WRITE(p, rig->datadesc[IMAGE].nt.ref);
        INT16WRITE(p, rig->datadesc[IMAGE].ncomponents);
        INT16WRITE(p, rig->datadesc[IMAGE].interlace);
        UINT16WRITE(p, rig->datadesc[IMAGE].compr.tag);
        UINT16WRITE(p, rig->datadesc[IMAGE].compr.ref);
        if (DFputelement(dfile, DFTAG_ID, ref, DFtbuf, (int32)(p-DFtbuf))<0)
            return(-1);
#endif /*DF_STRUCTOK*/
        Ref.dims[IMAGE] = ref;
    }
    if (!Ref.lut) {		/* associated lut not written to this file */
        if (Grlutdata==NULL) {	/* no lut associated */
            DFerror = DFE_BADPTR;
            return(-1);
        }
        lutsize = Grwrite.datadesc[LUT].xdim * Grwrite.datadesc[LUT].ydim *
	    Grwrite.datadesc[LUT].ncomponents;
        if (DFputelement(dfile, DFTAG_LUT, ref, Grlutdata, (int32)lutsize)<0)
	    return(-1);
        rig->data[LUT].tag = DFTAG_LUT;
        rig->data[LUT].ref = ref;
        Ref.lut = ref;
    }

    if (Ref.dims[LUT]==0) {
#ifdef DF_STRUCTOK		/* write out description record */
        if (DFputelement(dfile, DFTAG_LD, ref, &rig->datadesc[LUT], /* ID */
			 sizeof(rig->datadesc[LUT]))<0)
            return(-1);
#else /*DF_STRUCTOK*/
        register char *p;
        p = DFtbuf;
        INT32WRITE(p, rig->datadesc[LUT].xdim);
        INT32WRITE(p, rig->datadesc[LUT].ydim);
        UINT16WRITE(p, rig->datadesc[LUT].nt.tag);
        UINT16WRITE(p, rig->datadesc[LUT].nt.ref);
        INT16WRITE(p, rig->datadesc[LUT].ncomponents);
        INT16WRITE(p, rig->datadesc[LUT].interlace);
        UINT16WRITE(p, rig->datadesc[LUT].compr.tag);
        UINT16WRITE(p, rig->datadesc[LUT].compr.ref);
        if (DFputelement(dfile, DFTAG_LD, ref, DFtbuf, (int32)(p-DFtbuf))<0)
            return(-1);
#endif /*DF_STRUCTOK*/
        Ref.dims[LUT] = ref;
    }

    /* prepare to start writing rig */
    /* ### NOTE: the parameter to this call may go away */
    if (DFdisetup(10)<0) return(-1); /* max 10 tag/refs in set */
    /* add tag/ref to RIG - image description, image and lookup table */
    if (DFdiput(DFTAG_ID,(uint16)Ref.dims[IMAGE]) < 0) return(-1);

    if (DFdiput(rig->data[IMAGE].tag, rig->data[IMAGE].ref) < 0) return(-1);

    if ((Ref.dims[LUT]>0) && (DFdiput(DFTAG_LD, (uint16)Ref.dims[LUT]) < 0))
	return(-1);

    if ((Ref.lut>0) && (DFdiput(rig->data[LUT].tag, rig->data[LUT].ref) < 0))
	return(-1);

    /* write out RIG */
    return(DFdiwrite(dfile, DFTAG_RIG, ref));
}

/*****************************************************************************/
/*----------------------- Internal routines ---------------------------------*/
/*****************************************************************************/


/*-----------------------------------------------------------------------------
 * Name:    DFGRIopen
 * Purpose: open or reopen a file
 * Inputs:  filename: name of file to open
 *          access : access mode
 * Returns: file pointer on success, NULL on failure with DFerror set
 * Users:   HDF systems programmers, all the RIG routines 
 * Invokes: DFopen
 * Remarks: This is a hook for someday providing more efficient ways to
 *          reopen a file, to avoid re-reading all the headers
 *---------------------------------------------------------------------------*/

DF *DFGRIopen(filename, access)
char *filename;
int access;
{

    DF *dfile;

    /* use reopen if same file as last time - more efficient */
    if (strncmp(Grlastfile,filename,DF_MAXFNLEN) || (access==DFACC_CREATE)) {
	/* treat create as different file */
        if (!(dfile = DFopen(filename, access, -1))) return(NULL);
        Grrefset = 0;		/* no ref to get set for this file */
        Grnewdata = 0;
        if (Ref.lut>0) Ref.lut = 0;
        if (Grlutdata==NULL) Ref.lut = (-1); /* no LUT if not a "set" call */
        if (Ref.dims[IMAGE]>0) Ref.dims[IMAGE] = 0;
        if (Ref.dims[LUT]>0) Ref.dims[LUT] = 0;
        if (Ref.nt>0) Ref.nt = 0;
        Grread = Grzrig;        /* no rigs read yet */
    }
    else
        if (!(dfile = DFopen(filename, access, -1))) return(NULL);

    strncpy(Grlastfile, filename, DF_MAXFNLEN);
        /* remember filename, so reopen may be used next time if same file */
    return(dfile);
}

/*-----------------------------------------------------------------------------
 * Name:    DFGRIriginfo
 * Purpose: Get information about next RIG in file
 * Inputs:  dfile: pointer to DF file
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF systems programmers
 * Invokes: DFIfind, DFgetelement, DFGRgetrig
 * Remarks: if Grrefset set, gets image with that ref, if any
 *---------------------------------------------------------------------------*/

int DFGRIriginfo(dfile)
DF *dfile;
{
    DFdle *dlep;
    int cdd, i, isfirst;
    uint16 newref=0, newtag, gettag, getref;
    struct {
        uint16 xdim;
        uint16 ydim;
    } r8dims;
    char *p;

    isfirst = (Grrefset!=0) || (Grread.data[IMAGE].ref==0);
    getref = Grrefset;		/* ref if specified, else 0 */
    Grrefset = 0;		/* no longer need to remember specified ref */
    gettag = DFTAG_RIG;
    for (i=0; i<4; i++) {	/* repeat for RIG, RI8, CI8, II8 */
        if (DFIfind(dfile, gettag, getref, isfirst, gettag,
		    Grread.data[IMAGE].ref, &dlep, &cdd)<0) {
	    /* not found */
            if (gettag==DFTAG_RIG) { /* were looking for RIGs */
                if ((Grread.data[IMAGE].tag==DFTAG_RI) /* file has Rigs */
                    || (Grread.data[IMAGE].tag==DFTAG_CI)) {
                    return(-1);	/* no more to return */
                }
                gettag = DFTAG_RI8; /* if no RIGs in file, look for RI8s */
            }
            else if ((gettag==DFTAG_II8) && (!newref)) { /* no RI8/CI8/II8 */
                return(-1);
            }
            continue;		/* continue checking */
        }
	/* found */
        if (!newref || (dlep->dd[cdd].ref < newref)) { /* is it next one? */
            newref = dlep->dd[cdd].ref;	/* remember tag, ref */
            newtag = gettag;
        }
        if (gettag==DFTAG_RI8) gettag = DFTAG_CI8; /* check next */
        else if (gettag==DFTAG_CI8) gettag = DFTAG_II8;
        else break;		/* all checked, quit */
    }

    if (newtag==DFTAG_RIG) {
        if (DFGRgetrig(dfile, newref, &Grread)<0)
            return(-1);
    } else {
        Grread.data[IMAGE].ref = newref;
        Grread.data[IMAGE].tag = newtag;
        if (newtag==DFTAG_CI8) Grread.datadesc[IMAGE].compr.tag = DFTAG_RLE;
        else if (newtag==DFTAG_II8)
            Grread.datadesc[IMAGE].compr.tag = DFTAG_IMC;

        if (DFgetelement(dfile, DFTAG_ID8, newref, (char*)&r8dims)<0)
            return(-1);
#ifdef DF_STRUCTOK
        Grread.datadesc[IMAGE].xdim = r8dims.xdim;
        Grread.datadesc[IMAGE].ydim = r8dims.ydim;
#else /*DF_STRUCTOK*/
        p = (char *) &r8dims;
        UINT16READ(p, Grread.datadesc[IMAGE].xdim);
        UINT16READ(p, Grread.datadesc[IMAGE].ydim);
#endif /*DF_STRUCTOK*/

        if (DFIfind(dfile, DFTAG_IP8, newref, 0, 0, 0, &dlep, &cdd)>=0) {
            Grread.data[LUT].tag = DFTAG_IP8;
            Grread.data[LUT].ref = newref;
        }
        DFerror = DFE_NOERROR;	/* reset it, just in case! */
    }

    /* if LUT dimensions not set, set default dimensions */
    if (Grread.data[LUT].tag && Grread.datadesc[LUT].xdim==0) {
        Grread.datadesc[LUT].xdim = 256;
        Grread.datadesc[LUT].ydim = 1;
        Grread.datadesc[LUT].ncomponents = 3;
    }

    Grlastref = Grread.data[IMAGE].ref;	/* remember ref read */

    return(0);
}

/*-----------------------------------------------------------------------------
 * Name:    DFGRIgetdims
 * Purpose: get dimensions of next image/lut from RIG
 * Inputs:  filename: name of HDF file
 *          pxdim, pxdim: pointer to locations for returning x,y dimensions
 *          pncomps: location for returning no of components
 *          pil: location for returning interlace of image/lut in file
 *          type: LUT to get lut dims, IMAGE to get image dims
 * Returns: 0 on success, -1 on failure with DFerror set
 *          *pxdim, *pydim are set to dimensions of the next image on success
 *          *pncomps, *pil set on success
 * Users:   HDF HLL (high-level library) users, utilities, other routines
 * Invokes: DFGRIopen, DFclose, DFGRIriginfo, DFIerr
 * Remarks: none
 *---------------------------------------------------------------------------*/

int DFGRIgetdims(filename, pxdim, pydim, pncomps, pil, type)
char *filename;
int32 *pxdim, *pydim;
int *pncomps, *pil, type;
{
    DF *dfile;

    DFerror = DFE_NOERROR;

    dfile = DFGRIopen(filename, DFACC_READ);
    if (dfile == NULL) return(-1);

    if (type==IMAGE) {		/* getimdims sequences, getlutdims does not */
        if (DFGRIriginfo(dfile)<0) /* reads next RIG or RI8 from file */
            return(DFIerr(dfile)); /* on error, close file and return -1 */
        Grnewdata = 1;
    }

    if (type==LUT) if (Grread.data[LUT].ref==0) {
            DFerror = DFE_NOMATCH;
            return(-1);		/* no LUT */
    }
    if (pxdim) *pxdim = Grread.datadesc[type].xdim;
    if (pydim) *pydim = Grread.datadesc[type].ydim;
    if (pncomps) *pncomps = Grread.datadesc[type].ncomponents;
    if (pil) *pil = Grread.datadesc[type].interlace;
    return(DFclose(dfile));
}

/*-----------------------------------------------------------------------------
 * Name:    DFGRIreqil
 * Purpose: set interlace with which to get subsequent images/luts
 * Inputs:  il: interlace to get image/lut with
 *          type: LUT for luts, IMAGE for images
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF users, utilities, other routines
 * Invokes: none
 * Remarks: none
 *---------------------------------------------------------------------------*/

int DFGRIreqil(il, type)
int il, type;
{
    DFerror = DFE_NOERROR;

    Grreqil[type] = il;

    return(0);
}


/*-----------------------------------------------------------------------------
 * Name:    DFGRIgetimlut
 * Purpose: get next image/lut from a RIG
 * Inputs:  filename: name of HDF file
 *          imlut: space to read image/lut into
 *          xdim, ydim: dimensions of space allocated by user for image/lut
 *          type: LUT for luts, IMAGE for images
 *          isfortran: 0 if called from C, 1 if called from Fortran
 * Returns: 0 on success, -1 on failure with DFerror set
 *          image/lut in imlut
 * Users:   HDF HLL users, utilities, other routines
 * Invokes: DFGRIopen, DFGRIriginfo, DFIerr, DFclose, DFgetelement, DFgetcomp
 * Remarks: Will also get RI8s and CI8s if no RIGs in file
 *          Normally, DFGRgetimdims is called first and it moves to next image
 *          But if that is not called, DFGRgetimlut will itself move to next
 *          image (but not next lut!).
 *          Automatically decompresses images/luts
 *---------------------------------------------------------------------------*/

/* shut lint up */
/* ARGSUSED */
int DFGRIgetimlut(filename, imlut, xdim, ydim, type, isfortran)
char *filename;
int32 xdim, ydim;
char *imlut;
int type, isfortran;
{
    DF *dfile;
    int32 currpos[3], currmax[3], destsize[3], bufsize, i, j;
    char *buf, *destp;

    DFerror = DFE_NOERROR;

    dfile = DFGRIopen(filename, DFACC_READ);
    if (dfile == NULL) return(-1);

    if ((type==IMAGE) && (Grnewdata!=1)) { /* if Grread not fresh */
        if (DFGRIriginfo(dfile)<0) /* reads next RIG or RI8 from file */
            return(DFIerr(dfile)); /* on error, close file and return -1 */
    }
    if (Grnewdata==0) {
        DFerror = DFE_BADCALL;
        return(-1);
    }
    Grnewdata = 0;		/* read new RIG next time */

    if ((xdim!=Grread.datadesc[type].xdim) ||
	(ydim!=Grread.datadesc[type].ydim)) {
        DFerror = DFE_BADDIM;
        return(-1);
    }

    /* read image/lut */
    if (Grread.datadesc[type].compr.tag) { /* compressed image/lut */
        if ((Grreqil[type] >= 0) &&
	    (Grreqil[type] != Grread.datadesc[type].interlace)) {
            DFerror = DFE_NOTIMPL;
            return(-1);
        }
        if (DFgetcomp(dfile, Grread.data[type].tag, Grread.data[type].ref,
		      imlut, Grread.datadesc[type].xdim,
		      Grread.datadesc[type].ydim,
		      Grread.datadesc[type].compr.tag)<0)
            return(DFIerr(dfile));
    } else {			/* non-compressed raster image/lut */
        if (Grreqil[type]>=0) {
            if (Grreqil[type]>=Grread.datadesc[type].ncomponents) {
                DFerror = DFE_BADDIM;
                return(-1);
            }
            else if (Grreqil[type]!=Grread.datadesc[type].interlace) {

                if (DFaccess(dfile, Grread.data[type].tag,
			     Grread.data[type].ref, "r")<0)
                    return(DFIerr(dfile));
		/* current position in data */
                currpos[0] = currpos[1] = currpos[2] = 0;
                currmax[0] = Grread.datadesc[type].ncomponents;
                currmax[1] = Grread.datadesc[type].ydim;
                currmax[2] = Grread.datadesc[type].xdim;

		/* compute size of each dim of dest array */
                destsize[0] = destsize[1] = 1;
                destsize[2] = currmax[1]; /* xdim is more sig than ydim */
                if (Grreqil[type]==0) {
                    destsize[1] *= currmax[0];
                    destsize[2] *= currmax[0];
                }
                else if (Grreqil[type]==1) {
                    destsize[0] *= currmax[1];
                    destsize[2] *= currmax[0];
                }
                else if (Grreqil[type]==2) {
                    destsize[0] *= currmax[1] * currmax[2];
                }

                bufsize = Grread.datadesc[type].ydim *
		    Grread.datadesc[type].ncomponents;
                buf = DFIgetspace((unsigned)bufsize);
                if (buf==NULL) return(DFIerr(dfile));

		/* read byte by byte and copy */
                for (i=0; i<Grread.datadesc[type].xdim; i++) {
                    if (DFread(dfile, buf, bufsize)<0)
			return(DFIerr(dfile));
                    for (j=0; j<bufsize; j++) {
                        destp = imlut + destsize[0] * currpos[0] +
			    destsize[1] * currpos[1] +
				destsize[2] * currpos[2];
                        *destp = buf[j];
                        if (Grread.datadesc[type].interlace==0) {
                            if (++currpos[0] == currmax[0]) {
                                currpos[0] = 0;
                                if (++currpos[1] == currmax[1]) {
                                    currpos[1] = 0;
                                    if (++currpos[2] == currmax[2]) break;
                                }
                            }
                        } else if (++currpos[1]==currmax[1]) {
                            currpos[1] = 0;
                            if (Grread.datadesc[type].interlace==1) {
                                if (++currpos[0] == currmax[0]) {
                                    currpos[0] = 0;
                                    if (++currpos[2] == currmax[2]) break;
                                }
                            } else {
                                if (++currpos[2] == currmax[2]) {
                                    currpos[2] = 0;
                                    if (++currpos[0] == currmax[0]) break;
                                }
                            }
                        }
                    }
                }
                return(0);
            }
        }
        if (DFgetelement(dfile, Grread.data[type].tag, Grread.data[type].ref,
			 imlut)<0)
            return(DFIerr(dfile));
    }

    return(DFclose(dfile));
}

/*-----------------------------------------------------------------------------
 * Name:    DFGRIsetdims
 * Purpose: set dimensions of image/lut
 * Inputs:  xdim, ydim: dimensions of lut
 *          ncomps: no of components
 *          il: interlace of lut
 *          type: LUT if lut, IMAGE if image
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL (high-level library) users, utilities, other routines
 * Invokes: none
 * Remarks: none
 *---------------------------------------------------------------------------*/

int DFGRIsetdims(xdim, ydim, ncomps, type)
int32 xdim, ydim;
int ncomps;
int type;
{

    if ((xdim<=0) || (ydim<=0)) {
        DFerror = DFE_BADDIM;
        return(-1);
    }
    if (ncomps<0) {
        DFerror = DFE_BADDIM;
        return(-1);
    }
    Grwrite.datadesc[type].xdim = xdim;
    Grwrite.datadesc[type].ydim = ydim;
    Grwrite.datadesc[type].ncomponents = ncomps;

    Ref.dims[type] = 0;

    return(0);
}

/*-----------------------------------------------------------------------------
 * Name:    DFGRIsetil
 * Purpose: set interlace of image/lut
 * Inputs:  il: interlace of lut
 *          type: LUT if lut, IMAGE if image
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL (high-level library) users, utilities, other routines
 * Invokes: none
 * Remarks: none
 *---------------------------------------------------------------------------*/

int DFGRIsetil(il, type)
int il;
int type;
{

    if (il<0) {
        DFerror = DFE_BADDIM;
        return(-1);
    }
    Grwrite.datadesc[type].interlace = il;

    return(0);
}
/*-----------------------------------------------------------------------------
 * Name:    DFGRIrestart
 * Purpose: restart file
 * Inputs: 
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL (high-level library) users, utilities, other routines
 * Invokes: none
 * Remarks: none
 *---------------------------------------------------------------------------*/
	int
DFGRIrestart()
{
    Grlastfile[0] = '\0';
    Grrefset = 0;
    return 0;
}


/*-----------------------------------------------------------------------------
 * Name:    DFGRIaddimlut
 * Purpose: Internal routine to write RIG to file
 * Inputs:  filename: name of HDF file
 *          imlut: image/lut to be written to file
 *          xdim, ydim: dimensions of image/lut
 *          type: LUT if lut, IMAGE if image
 *          isfortran: 0 if called from C, 1 if called from Fortran
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF systems programmers, DFGRaddimage, DFGRaddlut, DFGRsetlut
 * Invokes: DFGRIopen, DFclose, DFputelement, DFdup, DFGRaddrig, DFputcomp,
 *          DFIerr
 * Remarks: Creates both RIG and RI8/CI8 tags, to accomodate older programs
 *          LUT will be associated with image if set previously
 *---------------------------------------------------------------------------*/

/* shut lint up */
/* ARGSUSED */
int DFGRIaddimlut(filename, imlut, xdim, ydim, type, isfortran)
char *filename;
int32 xdim, ydim;
char *imlut;
int type, isfortran;
{
    DF *dfile;
    uint16 wtag, wref;		/* tag of image/lut being written */
    char *newlut;
    int32 lutsize;
    int is8bit;
    struct {
        uint16 xdim;
        uint16 ydim;
    } r8dims;
    char *p;

    DFerror = DFE_NOERROR;

    if ((Ref.dims[type]==0) && ((xdim!=Grwrite.datadesc[type].xdim) ||
				(ydim!=Grwrite.datadesc[type].ydim))) {
        DFerror = DFE_BADDIM;
        return(-1);
    }

    if (!imlut) {
        DFerror = DFE_BADPTR;
        return(-1);
    }

    if (Ref.dims[type]<0)	/* if dims not set, set dimensions */
        if (DFGRIsetdims(xdim, ydim, 1, type)<0) return(-1);
				/* default: ncomps=1, il=0 */

    if ((type==LUT) && (filename==NULL)) { /* set call */
        if (Grlutdata) Grlutdata = (char *) DFIfreespace(Grlutdata);
        Ref.lut = -1;
        if (imlut==NULL) return(0);
        lutsize = Grwrite.datadesc[LUT].xdim * Grwrite.datadesc[LUT].ydim *
	    Grwrite.datadesc[LUT].ncomponents;
        Grlutdata = (char *) DFIgetspace((unsigned)lutsize);
        DFmovmem(imlut, Grlutdata, (int)lutsize);
        Ref.lut = 0;
        return(0);
    }
    dfile = DFGRIopen(filename, DFACC_ALL);
    if (dfile==NULL) return(-1);

    wref = DFnewref(dfile);
    if (!wref) return(DFIerr(dfile));

    wtag = (type==LUT) ? DFTAG_LUT : Grcompr ? DFTAG_CI : DFTAG_RI;
    Grwrite.data[type].tag = wtag;

    is8bit = (Grwrite.datadesc[IMAGE].ncomponents == 1);

    /* write out image/lut */
    if ((type==IMAGE) && Grcompr) {
        if (Grwrite.datadesc[IMAGE].ncomponents>1) {
            DFerror = DFE_NOTIMPL;
            return(DFIerr(dfile));
        }
        lutsize = Grwrite.datadesc[LUT].xdim * Grwrite.datadesc[LUT].ydim *
	    Grwrite.datadesc[LUT].ncomponents;
        if (Grcompr=DFTAG_IMC) {
            if (Grlutdata==NULL) {
                DFerror = DFE_BADCALL;
                return(DFIerr(dfile));
            }
            newlut = (char *) DFIgetspace((unsigned)lutsize);
        }
        if (DFputcomp(dfile, wtag, wref, imlut, xdim, ydim,
		      Grlutdata, newlut, Grcompr)<0)
            return(DFIerr(dfile));
    } else {			/* image need not be compressed */
        if (DFputelement(dfile, wtag, wref, imlut,
			 xdim*ydim*Grwrite.datadesc[type].ncomponents)<0)
            return(DFIerr(dfile));
    }
    Grwrite.data[type].ref = wref;
    Grwrite.aspectratio = 1.0;

    wtag = (type==LUT) ? DFTAG_IP8 : Grcompr ?
	((Grcompr==DFTAG_RLE) ? DFTAG_CI8 : DFTAG_II8) : DFTAG_RI8;
    /* Write out Raster-8 tags for those who want it */
    if (is8bit && (DFdup(dfile, wtag, wref, Grwrite.data[type].tag, wref)<0))
        return(DFIerr(dfile));

    if (type==IMAGE) Grwrite.datadesc[IMAGE].compr.tag = Grcompr;

    if (Grcompr==DFTAG_IMC) {
        if (DFputelement(dfile, DFTAG_LUT, wref, newlut, lutsize)<0)
            return(DFIerr(dfile));
        Ref.lut = wref;
    }

    if (DFGRaddrig(dfile, wref, &Grwrite)<0) /* writes ID, NT */
        return(DFIerr(dfile));

    if (is8bit) {
	/* put in Raster-8 stuff also, for those who want it */
        if ((Ref.lut>=0) && DFdup(dfile, DFTAG_IP8, wref, DFTAG_LUT, wref)<0)
            return(DFIerr(dfile));
#ifdef DF_STRUCTOK
        r8dims.xdim = Grwrite.datadesc[IMAGE].xdim;
        r8dims.ydim = Grwrite.datadesc[IMAGE].ydim;
#else /*DF_STRUCTOK*/
        p = (char *) &r8dims.xdim;
        UINT16WRITE(p, Grwrite.datadesc[IMAGE].xdim);
        UINT16WRITE(p, Grwrite.datadesc[IMAGE].ydim);
#endif /*DF_STRUCTOK*/
        if (DFputelement(dfile, DFTAG_ID8, wref, (char*)&r8dims, (int32) 4)<0)
            return(DFIerr(dfile));
    }

    if (Grcompr==DFTAG_IMC) {
        Ref.lut = 0;
        newlut = (char *) DFIfreespace(newlut);
    }

    Grlastref = wref;		/* remember ref written */
    
    wref = 0;			/* don't know ref to write next */

    return(DFclose(dfile));
}
