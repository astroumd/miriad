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
Revision 1.1.1.1  1990/09/28 21:49:59  teuben
UIUC 15-feb-2001 w/out wip and some manuals

 * Revision 3.4  90/07/02  10:12:00  clow
 * some cosmetic modifications
 * 
*/
/*-----------------------------------------------------------------------------
 * File:    dfr8.c
 * Purpose: read and write 8-bit Raster Image Groups
 * Invokes: df.c, dfcomp.c, dfgroup.c, dfrig.h
 * Contents: 
 *  DFR8getdims: retrieve information about 8-bit image dimensions
 *  DFR8getimage: retrieve 8-bit image and associated palette
 *  DFR8setpalette: specify palette to be used with subsequent 8-bit images
 *  DFR8Iputimage: internal routine that write 8-bit images to files
 *  DFR8putimage: write 8-bit image into an HDF file
 *  DFR8addimage: append another 8-bit image to an HDF file
 *  DFR8getrig: read in a raster image group for 8-bit images
 *  DFR8putrig: write out a raster image group for 8-bit images
 *  DFR8nimages: number of images in HDF file
 *  DFR8readref: get image with this reference number next
 *  DFR8writeref: put image with this reference number next
 *  DFR8restart: forget info about last file accessed - restart from beginning
 *  DFR8lastref: return reference number of last element read or written
 *  DFR8Iopen: open/reopen file
 *  DFR8Iriginfo: obtain info about next RIG/RI8 to get
 * Remarks: A RIG specifies attributes associated with an image - palette, 
 *          dimension, compression, color compensation etc.
 *          The palette for an 8-bit image is assumed to always be 768 bytes
 *          The palette is arranged as RGBRGB...
 *---------------------------------------------------------------------------*/


#include "dfrig.h"

static int foundRig = -1;	/* -1: don't know if HDF file has RIGs */
				/* 0: No RIGs, try for RI8s etc. */
				/* 1: RIGs used, ignore RI8s etc. */
static DFRrig Readrig;		/* information about RIG being read */
static DFRrig Writerig;		/* information about RIG being written */
static int Newdata = 0;		/* does Readrig contain fresh data? */
static uint16 Writeref=0;	/* ref of next image to put in this file */
static int Newpalette=(-1);	/* -1 = no palette is associated */
				/* 0 = palette already written out */
				/* 1 = new palette, not yet written out */
static char Palette[768];	/* to store palette for 8-bit images */
static uint16 Refset=0;		/* Ref of image to get next */
static uint16 Lastref = 0;	/* Last ref read/written */
static DFRrig Zrig = {		/* empty RIG for initialization */
    {0, 0}, {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0}, {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0}, {0, 0, 0, 0, 0, 0, 0, 0},
    0, 0, 0.0, 0.0, {0.0, 0.0, 0.0}, {0.0, 0.0, 0.0},
    {0.0, 0.0, 0.0}, {0.0, 0.0, 0.0}, NULL
};

#ifndef VMS
DF *DFR8Iopen();
#else /*VMS*/
DF *_DFR8Iopen();
#endif

typedef struct R8dim {
    uint16 xd;
    uint16 yd;
} R8dim;			/* dimensions of raster-8 image */


/*-----------------------------------------------------------------------------
 * Name:    DFR8getdims
 * Purpose: get dimensions of next image from RIG, also if there is a palette
 * Inputs:  filename: name of HDF file
 *          pxdim, pxdim, pointer to locations for returning x,y dimensions
 *          pispal: pointer to location for rtning whether there is a palette
 * Returns: 0 on success, -1 on failure with DFerror set
 *          *pxdim, *pydim are set to dimensions of the next image
 *          *pispal is set to 1 if a palette is associated with it, else 0
 * Users:   HDF HLL (high-level library) users, utilities, other routines
 * Invokes: DFR8Iopen, DFclose, DFR8Iriginfo, DFIerr
 * Remarks: will also handle file with just raster-8 tags: RI8, CI8, ID8, IP8
 *---------------------------------------------------------------------------*/

int DFR8getdims(filename, pxdim, pydim, pispal)
char *filename;
int32 *pxdim, *pydim;
int *pispal;
{
    DF *dfile;

    DFerror = DFE_NOERROR;

    if (!pxdim || !pydim) {	/* check for zero dimensions */
        DFerror = DFE_BADPTR;
        return(-1);
    }

    dfile = DFR8Iopen(filename, DFACC_READ);
    if (dfile == NULL) return(-1);

    if (DFR8Iriginfo(dfile)<0)	/* reads next RIG or RI8 from file */
        return(DFIerr(dfile));	/* on error, close file and return -1 */

    Newdata = 1;
    *pxdim = Readrig.descimage.xdim;
    *pydim = Readrig.descimage.ydim;
    if (pispal) *pispal = Readrig.lut.tag ? 1 : 0; /* is there a palette */

    return(DFclose(dfile));
}

/*-----------------------------------------------------------------------------
 * Name:    DFR8getimage
 * Purpose: get next image from a RIG, get palette also if desired
 * Inputs:  filename: name of HDF file
 *          image: space to read image into
 *          xdim, ydim: dimensions of space allocated by user for image
 *          pal: 768-byte space for palette, null if palette not wanted
 * Returns: 0 on success, -1 on failure with DFerror set
 *          image in image, palette in pal
 * Users:   HDF HLL users, utilities, other routines
 * Invokes: DFR8Iopen, DFR8Iriginfo, DFIerr, DFclose, DFgetelement, DFgetcomp
 * Remarks: Will also get RI8s and CI8s if no RIGs in file
 *          Normally,DFR8getdims is called first and it finds next image to get
 *          But if that is not called, DFR8getimage will itself find next image
 *          Automatically decompresses images
 *---------------------------------------------------------------------------*/

int DFR8getimage(filename, image, xdim, ydim, pal)
char *filename;
int32 xdim, ydim;
char *image;
char *pal;
{
    DF *dfile;

    DFerror = DFE_NOERROR;

    if ((xdim<=0) || (ydim<=0)) {
        DFerror = DFE_BADDIM;
        return(-1);
    }

    dfile = DFR8Iopen(filename, DFACC_READ);
    if (dfile == NULL) return(-1);

    if (!Newdata) {		/* if Readrig not fresh */
        if (DFR8Iriginfo(dfile)<0) /* reads next RIG or RI8 from file */
            return(DFIerr(dfile)); /* on error, close file and return -1 */
    }
    Newdata = 0;		/* read new RIG next time */

    if ((Readrig.descimage.xdim > xdim) || (Readrig.descimage.ydim > ydim)) {
        DFerror = DFE_NOTENOUGH; /* not enough space */
        return(DFIerr(dfile));
    }

    /* read image */
    if (Readrig.descimage.compr.tag) { /* compressed image */
        if (DFgetcomp(dfile, Readrig.image.tag, Readrig.image.ref, image,
		      Readrig.descimage.xdim, Readrig.descimage.ydim,
		      Readrig.descimage.compr.tag)<0)
            return(DFIerr(dfile));
    } else {			/* non-compressed raster image */
        if (DFgetelement(dfile, Readrig.image.tag, Readrig.image.ref, image)<0)
            return(DFIerr(dfile));
    }
    if (xdim > Readrig.descimage.xdim) {
	int off1, off2;
	int x, y;
	off1 = (Readrig.descimage.ydim - 1) * xdim;
	off2 = (Readrig.descimage.ydim - 1) * Readrig.descimage.xdim;
	for (y = Readrig.descimage.ydim - 1; y > 0; y-- ) {
	    for (x = Readrig.descimage.xdim - 1; x >= 0; x--)
		image[off1+x] = image[off2+x];
	    off1 -= xdim;
	    off2 -= Readrig.descimage.xdim;
	}
    }

    if (pal && Readrig.lut.tag) { /* read palette */
        if (DFgetelement(dfile, Readrig.lut.tag, Readrig.lut.ref, pal)<0)
            return(DFIerr(dfile));
    }
    return(DFclose(dfile));
}

/*-----------------------------------------------------------------------------
 * Name:    DFR8setpalette
 * Purpose: set palette for subsequent images
 * Inputs:  pal: palette to set
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF users, utilities, other routines
 * Invokes: none
 * Remarks: if pal is NULL, no palette is associated with subsequent images
 *---------------------------------------------------------------------------*/

int DFR8setpalette(pal)
char *pal;
{
    int i;

    DFerror = DFE_NOERROR;

    if (!pal) {
        Newpalette = -1;	/* no palette */
        Writerig.lut.tag = 0;
        Writerig.lut.ref = 0;   /* forget tag/ref of previous palette */
        Writerig.desclut.xdim = 0;
        Writerig.desclut.ncomponents = 0;
    } else {			/* store palette */
        for (i=0; i<768; i++)
            Palette[i] = pal[i];
        Newpalette = 1;
    }
    return(0);
}

/*-----------------------------------------------------------------------------
 * Name:    DFR8Iputimage
 * Purpose: Internal routine to write RIG to file
 * Inputs:  filename: name of HDF file
 *          image: image to be written to file
 *          xdim, ydim: dimensions of image
 *          compress: compression scheme to be used on image, 0 if none
 *                    possible values are DFTAG_RLE and DFTAG_IMC
 *          op: 0 will overwrite existing file, 1 will append image to file
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF systems programmers, DFR8putimage, DFR8addimage
 * Invokes: DFR8Iopen, DFclose, DFputelement, DFdup, DFR8putrig, DFputcomp,
 *          DFIerr
 * Remarks: Palette will be associated with image is isPalette is 1
 *          Palette will be written to file if not written before (Palref=0)
 *          Creates both RIG and RI8/CI8 tags, to accomodate older programs
 *---------------------------------------------------------------------------*/

int DFR8Iputimage(filename, image, xdim, ydim, compress, op)
char *filename;
int32 xdim, ydim;
char *image;
int compress;               /* compression scheme */
int op;                     /* 0 is a put, 1 is a putnext */
{
    int access;             /* create if op 0, write if op 1 */
    DF *dfile;
    uint16 r8tag;           /* RIG and raster tags of image being written */
    char *pal;     /* pointer to palette to be written */
    char newpal[768];  /* Imcomp creates new palette to be associated*/
    int wdim;               /* have dimensions already been written out? */

    DFerror = DFE_NOERROR;

    if ((xdim<=0) || (ydim<=0)) {
        DFerror = DFE_BADDIM;
        return(-1);
    }
    if (!image) {
        DFerror = DFE_BADPTR;
        return(-1);
    }
    pal = (Newpalette>=0) ? Palette : NULL;
    access = op ? DFACC_WRITE : DFACC_CREATE;

    dfile = DFR8Iopen(filename, access);
    if (dfile==NULL) return(-1);

    if (!Writeref) Writeref = DFnewref(dfile);
    if (!Writeref) return(-1);

    /* write out image */
    if (compress) {
        if (DFputcomp(dfile, DFTAG_CI, Writeref, image, xdim, ydim,
		      pal, newpal, compress)<0)
            return(DFIerr(dfile));
        Writerig.image.tag = DFTAG_CI;
        if (compress==DFTAG_IMC) {
            pal = newpal;	/* Imcomp creates new pal */
            Newpalette = 1;	/* write out palette */
        }
    } else {			/* image need not be compressed */
        if (DFputelement(dfile, DFTAG_RI, Writeref, image, xdim*ydim)<0)
            return(DFIerr(dfile));
        Writerig.image.tag = DFTAG_RI;
    }
    Writerig.image.ref = Writeref;
    Writerig.descimage.ncomponents = 1;
    Writerig.aspectratio = 1.0;

    /* Write out Raster-8 tags for those who want it */
    r8tag = compress ?
	((compress==DFTAG_RLE) ? DFTAG_CI8 : DFTAG_II8) : DFTAG_RI8;
    if (DFdup(dfile, r8tag, Writeref, Writerig.image.tag, Writeref)<0)
        return(DFIerr(dfile));

    /* Write out palette */
    if (pal) {			/* if there is a palette */
        if (Newpalette==1) {	/* write palette */
            if (DFputelement(dfile, DFTAG_LUT, Writeref, pal, (int32) 768)<0)
                return(DFIerr(dfile));
            Writerig.lut.tag = DFTAG_LUT;
            Writerig.lut.ref = Writeref;
            Writerig.desclut.xdim = 768;
            Writerig.desclut.ncomponents = 1;
        }
        if (compress!=DFTAG_IMC) Newpalette = 0;
	/* if IMCOMP, original palette not written out */

	/* put in Raster-8 stuff also, for those who want it */
        if (DFdup(dfile, DFTAG_IP8, Writeref, Writerig.lut.tag,
		  Writerig.lut.ref)<0)
            return(DFIerr(dfile));
    }

    /* Write out RIG */
    if ((Writerig.descimage.xdim==xdim) && (Writerig.descimage.ydim==ydim) &&
	(Writerig.descimage.compr.tag==compress))
        wdim = 0;
    else {
        wdim = 1;
        Writerig.descimage.xdim = xdim;
        Writerig.descimage.ydim = ydim;
        Writerig.descimage.compr.tag = compress;
    }
    if (DFR8putrig(dfile, Writeref, &Writerig, wdim)<0) /* writes ID, NT */
        return(DFIerr(dfile));

    Lastref = Writeref;		/* remember ref written */

    Writeref = 0;               /* don't know ref to write next */

    return(DFclose(dfile));
}

/*-----------------------------------------------------------------------------
 * Name:    DFR8putimage
 * Purpose: Write RIG to HDF file
 * Inputs:  filename: name of HDF file
 *          image: image to be written to file
 *          xdim, ydim: dimensions of image
 *          compress: compression scheme to be used on image, 0 if none
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL users, utilities, other routines
 * Invokes: DFR8Iputimage
 * Remarks: overwrites existing HDF file
 *---------------------------------------------------------------------------*/

int DFR8putimage(filename, image, xdim, ydim, compress)
char *filename;
int32 xdim, ydim;
char *image;
int compress;
{
    return(DFR8Iputimage(filename, image, xdim, ydim, compress, 0));
}


/*-----------------------------------------------------------------------------
 * Name:    DFR8addimage
 * Purpose: Append RIG to HDF file
 * Inputs:  filename: name of HDF file
 *          image: image to be written to file
 *          xdim, ydim: dimensions of image
 *          compress: compression scheme to be used on image, 0 if none
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF HLL users, utilities, other routines
 * Invokes: DFR8Iputimage
 * Remarks: inserts image into existing file, will create file if necessary
 *---------------------------------------------------------------------------*/

int DFR8addimage(filename, image, xdim, ydim, compress)
char *filename;
int32 xdim, ydim;
char *image;
int compress;
{
    return(DFR8Iputimage(filename, image, xdim, ydim, compress, 1));
}


/*****************************************************************************/
/* This is the next lower layer - procedures to get and put a RIG. */
/* These are specific to 8-bit */
/*****************************************************************************/

/*-----------------------------------------------------------------------------
 * Name:    DFR8getrig
 * Purpose: Read a RIG into memory
 * Inputs:  dfile: pointer to HDF file containing RIG
 *          ref: reference number of RIG to get
 *          rig: struct in which to place info obtained
 * Returns: 0 on success, -1 on failure with DFerror set
 *          contents of RIG in the struct rig
 * Users:   HDF programmers, utilities, DFR8getdims,DFR8getimage
 * Invokes: DFdiget, DFdinext, DFIcheck, DFgetelement
 * Remarks: assumes 8-bit
 *---------------------------------------------------------------------------*/

int DFR8getrig(dfile, ref, rig)
DF *dfile;
uint16 ref;
DFRrig *rig;
{
    DFdi elmt;
    char ntstring[4];

    DFerror = DFE_NOERROR;

    if (DFIcheck(dfile))
        return( -1);
    if (!ref) {
        DFerror = DFE_BADREF;
        return(-1);
    }

    if (DFdiread(dfile, DFTAG_RIG, ref)<0) /* read RIG into memory */
        return(-1);

    *rig = Zrig;		/* fill rig with zeroes */
    while (!DFdiget(&elmt)) {	/* get next tag/ref from RIG */
        switch (elmt.tag) {	/* process tag/ref */
            case DFTAG_CI:
            case DFTAG_RI:
                rig->image.tag = elmt.tag; /* put tag/ref in struct */
                rig->image.ref = elmt.ref;
                break;
            case DFTAG_LUT:
                rig->lut.tag = elmt.tag;
                rig->lut.ref = elmt.ref;
                break;
            case DFTAG_ID:	/* read description info */
#ifdef DF_STRUCTOK
                if (DFgetelement(dfile, elmt.tag, elmt.ref, &rig->descimage)<0)
                    return(-1);
#else /*DF_STRUCTOK*/
                if (DFgetelement(dfile, elmt.tag, elmt.ref, DFtbuf)>0) {
                    register char *p;
                    p = DFtbuf;
                    INT32READ(p, rig->descimage.xdim);
                    INT32READ(p, rig->descimage.ydim);
                    UINT16READ(p, rig->descimage.nt.tag);
                    UINT16READ(p, rig->descimage.nt.ref);
                    INT16READ(p, rig->descimage.ncomponents);
                    INT16READ(p, rig->descimage.interlace);
                    UINT16READ(p, rig->descimage.compr.tag);
                    UINT16READ(p, rig->descimage.compr.ref);
                } else
                    return(-1);
#endif /*DF_STRUCTOK*/
                if (rig->descimage.ncomponents!=1) {
                    DFerror = DFE_BADCALL;
                    return(-1);
                }
                if (rig->descimage.nt.tag==0) break; /* old RIGs */

		/* read NT */
                if (DFgetelement(dfile, rig->descimage.nt.tag,
				 rig->descimage.nt.ref, ntstring)<0)
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
 * Name:    DFR8putrig
 * Purpose: Write RIG struct out to HDF file
 * Inputs:  dfile: HDF file pointer
 *          ref: ref to put RIG with
 *          rig: struct containing RIG info to put
 *          wdim: if 1, write out new description records. if 0 already written
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF programmers, utilities, DFR8Iputimage, other routines
 * Invokes: DFIcheck, DFdistart, DFdiadd, DFdiend, DFputelement
 * Remarks: assumes 8-bit.  Writes out NT if necessary, ID, ID8 if told to
 *---------------------------------------------------------------------------*/

int DFR8putrig(dfile, ref, rig, wdim)
DF *dfile;
uint16 ref;
DFRrig *rig;
int wdim;
{
    static uint16 prevdimref=0; /*ref of previous dimension record, to reuse */
    R8dim im8dim;
    char ntstring[4];

    DFerror = DFE_NOERROR;

    if (DFIcheck(dfile))
        return( -1);
    if (!ref) {
        DFerror = DFE_BADREF;
        return(-1);
    }

    if (!rig->descimage.nt.tag) {
	/* construct and write out NT */
        ntstring[0] = DFNT_VERSION; /* version */
        ntstring[1] = DFNT_UCHAR; /* type */
        ntstring[2] = 8;	/* width: RIG data is 8-bit chars */
        ntstring[3] = DFNTC_BYTE; /* class: data are numeric values */
        if (DFputelement(dfile, DFTAG_NT, ref, ntstring, (int32) 4) <0)
            return(-1);
        rig->descimage.nt.tag = DFTAG_NT;
        rig->descimage.nt.ref = ref;
    }
        
    im8dim.xd = rig->descimage.xdim;
    im8dim.yd = rig->descimage.ydim;
    if (wdim) {
#ifdef DF_STRUCTOK		/* write out description record */
        if (DFputelement(dfile, DFTAG_ID8, ref, &im8dim, (int32) 4)<0) /*ID8 */
            return(-1);
        if (DFputelement(dfile, DFTAG_ID, ref, &rig->descimage,	/* ID */
			 sizeof(rig->descimage))<0)
            return(-1);
#else /*DF_STRUCTOK*/
        register char *p;
        p = DFtbuf;
        INT32WRITE(p, rig->descimage.xdim);
        INT32WRITE(p, rig->descimage.ydim);
        UINT16WRITE(p, rig->descimage.nt.tag);
        UINT16WRITE(p, rig->descimage.nt.ref);
        INT16WRITE(p, rig->descimage.ncomponents);
        INT16WRITE(p, rig->descimage.interlace);
        UINT16WRITE(p, rig->descimage.compr.tag);
        UINT16WRITE(p, rig->descimage.compr.ref);
        if (DFputelement(dfile, DFTAG_ID, ref, DFtbuf,(int32)(p-DFtbuf))<0)
            return(-1);
	/* write out ID8 */
        p = DFtbuf;
        UINT16WRITE(p, im8dim.xd);
        UINT16WRITE(p, im8dim.yd);
        if (DFputelement(dfile, DFTAG_ID8, ref, DFtbuf, (int32) 4)<0)
            return(-1);
#endif /*DF_STRUCTOK*/
        prevdimref = ref;
    }
    if (!prevdimref) {
        DFerror = DFE_BADDIM;
        return(-1);
    }

    /* prepare to start writing rig */
    /* ### NOTE: the second parameter to this call may go away */
    if (DFdisetup(10)<0) return(-1); /* max 10 tag/refs in set */

    /* add tag/ref to RIG - image description, image and palette */
    if (DFdiput(DFTAG_ID, prevdimref) < 0) return(-1);

    if (DFdiput(rig->image.tag, rig->image.ref) < 0) return(-1);

    if (rig->lut.ref)
        if (DFdiput(rig->lut.tag, rig->lut.ref) < 0) return(-1);

        /* write out RIG */
    return(DFdiwrite(dfile, DFTAG_RIG, ref));
}


/*-----------------------------------------------------------------------------
 * Name:    DFR8nimages
 * Purpose: How many images are present in this file?
 * Inputs:  filename: name of HDF file
 * Returns: number of images  on success, -1 on failure with DFerror set
 * Users:   HDF programmers, other routines and utilities
 * Invokes: DFR8Iopen, DFclose, DFnumber
 * Remarks: the number is the number of RIGs if RIGs are present
 *          If not, it is the number of RI8s + number of CI8s
 *---------------------------------------------------------------------------*/

int DFR8nimages(filename)
char *filename;
{
    DF *dfile;
    int nimages=0;

    DFerror = DFE_NOERROR;

    /* should use reopen if same file as last time - more efficient */
    dfile = DFR8Iopen(filename, DFACC_READ);
    if (dfile==NULL) return(-1);

    /* find next rig */
    if (foundRig) {		/* either RIGs present or don't know */
        nimages = DFnumber(dfile, DFTAG_RIG); /* count number of RIGs */
        if (nimages>0) {
            foundRig = 1;
            if (DFclose(dfile)<0) return(-1);
            return(nimages);
        }
        foundRig = 0;
    }
    nimages = DFnumber(dfile, DFTAG_RI8);
    nimages += DFnumber(dfile, DFTAG_CI8);
    if (DFclose(dfile)<0) return(-1);
    return(nimages);
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

int DFR8readref(filename, ref)
char *filename;
uint16 ref;
{
    DF *dfile;
    int cdd;
    DFdle *dlep;

    DFerror = DFE_NOERROR;

    dfile = DFR8Iopen(filename, DFACC_READ);
    if (dfile==NULL) return(-1);
    if (DFIfind(dfile, DFTAG_RIG, ref, 1, 0, 0, &dlep, &cdd)<0)
        if (DFIfind(dfile, DFTAG_RI8, ref, 1, 0, 0, &dlep, &cdd)<0)
            if (DFIfind(dfile, DFTAG_CI8, ref, 1, 0, 0, &dlep, &cdd)<0)
                return(DFIerr(dfile));
    Refset = ref;
    Newdata = 0;
    return(DFclose(dfile));
}

/*-----------------------------------------------------------------------------
 * Name:    DFR8writeref
 * Purpose: Set ref of image to put next
 * Inputs:  filename: file to which this applies
 *          ref: reference number of next put
 * Returns: 0 on success, -1 on failure
 * Users:   HDF programmers, other routines and utilities
 * Invokes: DFR8Iopen, DFIfind
 * Remarks: none
 *---------------------------------------------------------------------------*/

/* shut lint up */
/* ARGSUSED */
int DFR8writeref(filename, ref)
char *filename;
uint16 ref;
{
    DFerror = DFE_NOERROR;

    Writeref = ref;
    return(0);
}

static char Lastfile[DF_MAXFNLEN];          /* last file opened */

/*-----------------------------------------------------------------------------
 * Name:    DFR8restart
 * Purpose: Do not remember info about file - get again from first image
 * Inputs:  none
 * Returns: 0 on success
 * Users:   HDF programmers
 * Remarks: Just reset Lastfile to NULL
 *---------------------------------------------------------------------------*/

int DFR8restart()
{
    Lastfile[0] = '\0';
    return(0);
}


/*-----------------------------------------------------------------------------
 * Name:    DFR8lastref
 * Purpose: Return last ref written or read
 * Inputs:  none
 * Globals: Lastref
 * Returns: ref on success, -1 on error with DFerror set
 * Users:   HDF users, utilities, other routines
 * Invokes: none
 * Method:  return Lastref
 * Remarks: none
 *---------------------------------------------------------------------------*/

int DFR8lastref()
{
    return((int) Lastref);
}



/******************************************************************************/
/*----------------------- Internal routines ---------------------------------*/
/******************************************************************************/


/*-----------------------------------------------------------------------------
 * Name:    DFR8Iopen
 * Purpose: open or reopen a file
 * Inputs:  filename: name of file to open
 *          access : access mode
 * Returns: file pointer on success, NULL on failure with DFerror set
 * Users:   HDF systems programmers, all the RIG routines 
 * Invokes: DFopen
 * Remarks: This is a hook for someday providing more efficient ways to
 *          reopen a file, to avoid re-reading all the headers
 *---------------------------------------------------------------------------*/

DF *DFR8Iopen(filename, access)
char *filename;
int access;
{

    DF *dfile;

    /* use reopen if same file as last time - more efficient */
    if (strncmp(Lastfile,filename,DF_MAXFNLEN) || (access==DFACC_CREATE)) {
				/* treat create as different file */
        if (!(dfile = DFopen(filename, access, -1))) return(NULL);
        foundRig = -1;		/* don't know if any RIGs in file */
        Refset = 0;		/* no ref to get set for this file */
        Newdata = 0;
        Readrig = Zrig;		/* blank out read/write RIGs */
        Writerig = Zrig;
        if (Newpalette!=(-1)) Newpalette = 1; /* need to write out palette */
    } else
        if (!(dfile = DFopen(filename, access, -1))) return(NULL);

    strncpy(Lastfile, filename, DF_MAXFNLEN);
    /* remember filename, so reopen may be used next time if same file */
    return(dfile);
}

/*-----------------------------------------------------------------------------
 * Name:    DFR8Iriginfo
 * Purpose: Getinformation about next RIG or Raster-8 in file
 * Inputs:  dfile: pointer to DF file
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF systems programmers
 * Invokes: DFIfind, DFgetelement
 * Remarks: checks for RIGs first, then RI8s
 *          if Refset set, gets image with that ref, if any
 *---------------------------------------------------------------------------*/

int DFR8Iriginfo(dfile)
DF *dfile;
{
    DFdle *dlep;
    int cdd;
    uint16 riref=0, ciref=0;

#ifdef DF_STRUCTOK
    R8dim im8dim;
#endif /*DF_STRUCTOK*/

    /* find next rig */
    if (foundRig) {		/* either RIGs present or don't know */
	do {
	    DFerror = DFE_NOERROR;
	    if (Refset &&
		DFIfind(dfile, DFTAG_RIG, Refset, 1,0,0, &dlep, &cdd)<0) {
		/* try for RI8 and CI8s */
	    }
            /* in next line, !ref is passed for isfirst.  If we have found
	       a ref before, ref is non-zero, hence isfirst is 0.  If
	       we have not found anything yet, ref is 0 and isfirst is 1 */
	    else if (!Refset && DFIfind(dfile, DFTAG_RIG, DFREF_WILDCARD,
					!Readrig.image.ref, Readrig.image.tag,
                                        Readrig.image.ref, &dlep, &cdd) <0) {
		if (foundRig==1) { /* RIGs present, but no more to return */
		    DFerror = DFE_NOMATCH;
		    return(-1);
		}
		foundRig = 0;	/* No RIGs present in file */
	    }
	    else {		/* RIG found */
		if (DFR8getrig(dfile, dlep->dd[cdd].ref, &Readrig)<0) {
		    if (Refset || (DFerror != DFE_BADCALL)) {
			Refset = 0;
			return(-1);
		    }
		    Readrig.image.ref = dlep->dd[cdd].ref; /*to get next one */
		} else { foundRig = 1; Refset = 0; }
	    }
	} while (DFerror==DFE_BADCALL);
    }
    if (Refset || !foundRig) {	/* No RIGs present, look for RI8 and CI8 */
	/* look for Refset if DFR8ref called, else look for next ref */
        if ((Refset &&
	     (DFIfind(dfile, DFTAG_RI8, Refset, 1, 0, 0, &dlep, &cdd)==0)) ||
	    (!Refset &&
	     (DFIfind(dfile, DFTAG_RI8, DFREF_WILDCARD, !Readrig.image.ref,
		      Readrig.image.tag, Readrig.image.ref, &dlep, &cdd)==0)))
            riref = dlep->dd[cdd].ref;

        if ((Refset &&
	     (DFIfind(dfile, DFTAG_CI8, Refset, 1, 0, 0, &dlep, &cdd)==0)) ||
	    (!Refset &&
	     (DFIfind(dfile, DFTAG_CI8, DFREF_WILDCARD, !Readrig.image.ref,
		      Readrig.image.tag, Readrig.image.ref, &dlep, &cdd)==0)))
            ciref = dlep->dd[cdd].ref;

        Refset = 0;
        if (!riref && !ciref) {
            DFerror = DFE_NOMATCH;
            return(-1);
        }
        if ((!ciref) || (riref && (riref<ciref))) { /* next image is RI8 */
            Readrig.image.ref = riref;
            Readrig.image.tag = DFTAG_RI8;
        }
        else {			/* next image is CI8 */
            Readrig.image.ref = ciref;
            Readrig.image.tag = DFTAG_CI8;
            Readrig.descimage.compr.tag = DFTAG_RLE;
        }

#ifdef DF_STRUCTOK		/* read in dimensions */
        if (DFgetelement(dfile, DFTAG_ID8, Readrig.image.ref, &im8dim)>=0) {
            Readrig.descimage.xdim = im8dim.xd;
            Readrig.descimage.ydim = im8dim.yd;
        }
#else /*DF_STRUCTOK*/
        if (DFgetelement(dfile, DFTAG_ID8, Readrig.image.ref, DFtbuf)>=0) {
            register char *p;
            p = DFtbuf;
            UINT16READ(p, Readrig.descimage.xdim);
            UINT16READ(p, Readrig.descimage.ydim);
        }
#endif /*DF_STRUCTOK*/
        else return(-1);

        if (DFIfind(dfile, DFTAG_IP8, Readrig.image.ref, 1, 0, 0, &dlep,
		    &cdd)==0) {
            Readrig.lut.tag = DFTAG_IP8;
            Readrig.lut.ref = Readrig.image.ref;
        }
    }
    Lastref = Readrig.image.ref; /* remember ref read */
    return(0);
}
