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
Revision 1.1.1.1  1990/09/28 21:49:51  teuben
UIUC 15-feb-2001 w/out wip and some manuals

 * Revision 3.2  90/07/02  10:12:14  clow
 * some cosmetic modifications
 * 
*/
/*-----------------------------------------------------------------------------
 * File:    dfcomp.c
 * Purpose: File compression
 * Invokes: df.c dfimcomp.c df.h
 * Contents: 
 *  DFputcomp: compress image and write it to HDF file
 *  DFgetcomp: read compressed image from HDF file and decompress it
 *  DFCrle: compress string using run length encoding
 *  DFCunrle: decompress string using run length encoding
 * Remarks: DFgetcomp and DFputcomp constitute a general compression interface
 *---------------------------------------------------------------------------*/

#include "df.h"

#ifndef VMS
extern void DFCimcomp(), DFCunimcomp();
#else /*VMS*/
extern void _DFCimcomp(), _DFCunimcomp();
#endif

/*-----------------------------------------------------------------------------
 * Name:    DFputcomp
 * Purpose: Compress and write images to HDF file
 * Inputs:  dfile: pointer to HDF file
 *          tag, ref: tag, ref of compressed image for writing out
 *          image: image to be compressed
 *          xdim, ydim: dimensions of image
 *          palette: palette associated with image
 *          newpal: modified palette, produced if compression scheme is IMCOMP
 *          scheme: compression scheme to be used
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF programmers, DF8putrig, other routines
 * Invokes: DFCrle, DFCimcomp, DFaccess, DFwrite, DFIcheck
 * Remarks: IMCOMP modifies the palette associated with the image
 *          Hence the palette and newpal arguments
 *          This is a general compression interface - to be used anytime image
 *          compression is needed in HDF
 *          Note that rseq does its own compression, because that is part of
 *          the interactive color raster protocol
 *          The space needed for compression and decompression can be allocated
 *          statically or dynamically, depending on the DF_DYNAMIC flag, and
 *          for entire image or part of it (reused) depending on availability
 *          Accordingly, writing out is whole image, or row by row
 *          Note that compression is always row by row for RLE.
 *---------------------------------------------------------------------------*/


int DFputcomp(dfile, tag, ref, image, xdim, ydim, palette, newpal, scheme)
DF *dfile;
uint16 tag, ref;
char *image;
int32 xdim, ydim;
char *palette, *newpal;
int16 scheme;
{
    char *buffer;		/* buffer to hold compressed image */
    char *in;			/* pointer to input for compression */
    char *out;			/* pointer to space for compressed output */
    int32 cisize;		/* maximum size of compressed image */
    int32 crowsize;		/* maximum size of compressed row */
    int32 buftype;		/* buftype = 1: buffer enough for whole image*/
				/* buftype = 2: buffer holds 1 row */
    int32 n;			/* number of compressed bytes produced */
    int32 total;		/* total compressed bytes produced so far */
    int i, ret=0;

    if (DFIcheck(dfile)<0) return(-1);
    if (!tag) {
        DFerror = DFE_BADTAG;
        return(-1);
    }
    if (!ref) {
        DFerror = DFE_BADREF;
        return(-1);
    }
    if ((xdim<=0) || (ydim<=0)) {
        DFerror = DFE_BADDIM;
        return(-1);
    }
    if (!image) {
        DFerror = DFE_BADPTR;
        return(-1);
    }

    if (DFaccess(dfile, tag, ref, "w")<0) return(-1); /* setup to write CI */

    switch (scheme) {
      case DFTAG_RLE:
	cisize = ydim*(xdim*121/120+1);	/* 120 chars can compress to 121! */
	crowsize = xdim*121/120 + 128;

	/* allocate buffer for compression */
#ifdef DF_DYNAMIC		/* large mallocs OK */
	buffer = (char *) DFIgetspace((unsigned)cisize);
	if (!buffer) {
	    buffer = (char *) DFIgetspace((unsigned)crowsize);
	    if (!buffer) {
		DFerror = DFE_NOSPACE;
		return(-1);
	    }
	    buftype = 2;	/* compress and write out row by row */
	}
	else buftype = 1;       /* can hold whole image, then write */

#else /*DF_DYNAMIC                    use static buffers */
	buffer = DFtbuf;
	if (DF_TBUFSZ>=cisize) buftype = 1;
	else if (DF_TBUFSZ>crowsize) buftype = 2;
	else {
	    DFerror = DFE_NOSPACE;
	    return(-1);
	}
#endif /*DF_DYNAMIC*/

	in = image;
	out = buffer;
	n = total = 0;		/* no bytes compressed so far */

	/* compress row by row */
	for (i=0; i<ydim; i++) {
	    n = DFCrle(in, out, xdim); /* compress row */
	    in += xdim;		/* move input pointer */
	    total += n;		/* keep running total */
	    if (buftype==1)	/* can hold whole image */
		out = &buffer[total]; /* move out buffer pointer */
	    else {		/* buffer too small, */
				/* write out what was produced */
		if (DFwrite(dfile, buffer, n)<0) {
		    ret = -1;	/* flag value */
		    break;
		}
		out = buffer;	/* reset output pointer */
	    }
	}

	if (buftype==1)		/* write out entire image */
                ret = DFwrite(dfile, buffer, total);
	break;

      case DFTAG_IMC:
        if (!palette || !newpal) { /* need palette and newpal */
            DFerror = DFE_BADPTR;
            return(-1);
        }
        cisize = xdim*ydim/4;	/* IMCOMP always cuts to 1/4 */

#ifdef DF_DYNAMIC
        buffer = (char *) DFIgetspace((unsigned)cisize);
        if (!buffer) {
            DFerror = DFE_NOSPACE;
            return(-1);
        }
#else /*DF_DYNAMIC*/
        if (DF_TBUFSZ<cisize) {
            DFerror = DFE_NOSPACE;
            return(-1);
        }
        buffer = DFtbuf;
#endif /*DF_DYNAMIC*/

        DFCimcomp(xdim, ydim, image, buffer, palette, newpal, 0);
        ret = DFwrite(dfile, buffer, cisize);
        break;

    default:			/* unknown compression scheme */
        DFerror = DFE_BADSCHEME;
        return(-1);
        break;
    }
#ifdef DF_DYNAMIC
    DFIfreespace((char*)buffer);
#endif /*DF_DYNAMIC*/
    return(ret);
}

/*-----------------------------------------------------------------------------
 * Name:    DFgetcomp
 * Purpose: Read compressed image and decompress it
 * Inputs:  dfile: HDF file pointer
 *          tag, ref: id of image to be decompressed
 *          image: space to return decompressed image in
 *          xdim, ydim: dimensions of decompressed image
 *          scheme: compression scheme used
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF programmers, DF8getrig, other routines
 * Invokes: DFIcheck, DFIfind, DFaccess, DFread, DFCunrle, DFCunimcomp
 * Remarks: Will use dynamic/static memory allocation for buffer
 *          will read in image in parts if memory insufficient
 *          Decompression of rle is not necessarily row by row
 *          Other encodings can also be decoded with this
 *---------------------------------------------------------------------------*/

int DFgetcomp(dfile, tag, ref, image, xdim, ydim, scheme)
DF *dfile;
uint16 tag, ref;
char *image;
int32 xdim, ydim;
uint16 scheme;
{
    char *buffer, *in, *out;
    int32 cisize, crowsize, buflen, bufleft; /* bufleft: bytes left in buffer*/
    DFdle *dlep;
    int cdd, i, n, totalread;

    if (DFIcheck(dfile)<0) return(-1);
    if (!tag) {
        DFerror = DFE_BADTAG;
        return(-1);
    }
    if (!ref) {
        DFerror = DFE_BADREF;
        return(-1);
    }
    if (!image) {
        DFerror = DFE_BADPTR;
        return(-1);
    }
    if ((xdim<=0) || (ydim<=0)) {
        DFerror = DFE_BADDIM;
        return(-1);
    }

    if (DFIfind(dfile, tag, ref, 1, 0, 0, &dlep, &cdd)<0) {
        DFerror = DFE_NOMATCH;
        return(-1);
    }
    cisize = dlep->dd[cdd].length;

    if (DFaccess(dfile, tag, ref, "r")<0) return(-1);
    switch (scheme) {
      case DFTAG_RLE:
	crowsize = xdim*121/120 + 128; /* max size of a row */

#ifdef DF_DYNAMIC
	buffer = (char *) DFIgetspace((unsigned)cisize);
	if (!buffer) {
	    buffer = (char *) DFIgetspace((unsigned)crowsize);
	    if (!buffer) {
		DFerror = DFE_NOSPACE;
		return(-1);
	    }
	    buflen = crowsize;
	}
	else buflen = cisize;
#else /*DF_DYNAMIC*/
	if (DF_TBUFSZ<crowsize) {
	    DFerror = DFE_NOSPACE;
	    return(-1);
	}
	buffer = DFtbuf;	/* static compression buffer */
	buflen = DF_TBUFSZ;
#endif /*DF_DYNAMIC*/

	in = buffer;
	out = image;
	if ((n=DFread(dfile, in, buflen))<0) {
#ifdef DF_DYNAMIC
	    DFIfreespace((char*)buffer);
#endif /*DF_DYNAMIC*/
	    return(-1);
	}
	totalread = n;
	bufleft = n;
	for (i=0; i<ydim; i++) {
	    n = DFCunrle(in, out, xdim, !i); /* no of bytes used up */
	    /* last arg=TRUE if i=0 - resets decompress */
	    in += n;
	    out += xdim;
	    bufleft -= n;
	    /* check if more bytes may be needed for next read */
	    if ((bufleft<crowsize) && (totalread<cisize)) {
		DFmovmem(in, buffer, (int)bufleft);
		in = buffer;
		if ((n=DFread(dfile,&in[bufleft],buflen-bufleft))<0) {
#ifdef DF_DYNAMIC
		    DFIfreespace((char*)buffer);
#endif /*DF_DYNAMIC   */
		    return(-1);
		}
		totalread += n;
		bufleft += n;
	    }
	}
	break;

      case DFTAG_IMC:
	crowsize = xdim;	/* size of compressed row */

#ifdef DF_DYNAMIC
	buffer = (char *) DFIgetspace((unsigned)cisize);
	if (!buffer) {
	    buffer = (char *) DFIgetspace((unsigned)crowsize);
	    if (!buffer) {
		DFerror = DFE_NOSPACE;
		return(-1);
	    }
	    buflen = crowsize;
	}
	else buflen = cisize;
#else /*DF_DYNAMIC*/
	buffer = DFtbuf;	/* static compression buffer */
	if (DF_TBUFSZ<crowsize) {
	    DFerror = DFE_NOSPACE;
	    return(-1);
	}
	buflen = DF_TBUFSZ;
#endif /*DF_DYNAMIC*/
	if (buflen>=cisize) {
	    if (DFread(dfile, buffer, cisize)<cisize) {
#ifdef DF_DYNAMIC
		DFIfreespace((char*)buffer);
#endif /*DF_DYNAMIC*/
		return(-1);
	    }
	    DFCunimcomp(xdim, ydim, buffer, image);
	    break;		/* go to end of switch */
	}

	in = buffer;		/* if can only read piecemeal */
	out = image;
	if ((n=DFread(dfile, in, buflen))<0) {
#ifdef DF_DYNAMIC
	    DFIfreespace((char*)buffer);
#endif /*DF_DYNAMIC*/
	    return(-1);
	}
	totalread = n;
	bufleft = n;
	for (i=0; i<ydim; i+=4) {
	    DFCunimcomp(xdim, (int32)4, in, out);
	    in += xdim;
	    out += 4*xdim;
	    bufleft -= xdim;
	    if ((bufleft<crowsize) && (totalread<cisize)) {
		DFmovmem(in, buffer, (int)bufleft);
		in = buffer;
		if ((n=DFread(dfile,&in[bufleft],buflen-bufleft))<0) {
#ifdef DF_DYNAMIC
		    DFIfreespace((char*)buffer);
#endif /*DF_DYNAMIC*/
		    return(-1);
		}
		totalread += n;
		bufleft += n;
	    }
	}
	break;

      default:			/* unknown scheme */
	DFerror = DFE_BADSCHEME;
	return(-1);
	break;
    }
#ifdef DF_DYNAMIC
    DFIfreespace((char*)buffer);
#endif /*DF_DYNAMIC*/
    return(0);
}

/*-----------------------------------------------------------------------------
 * Name:    DFCrle
 * Purpose: compress a string of bytes
 * Inputs:  buf: buffer containing data to be compressed
 *          bufto: space for compressed data - assumed big enough
 *          len: number of bytes to compress
 * Returns: number of compressed bytes on success, -1 on failure
 * Users:   HDF programmers, DFputcomp, other routines
 * Invokes: none
 * Remarks: Written for efficiency
 *---------------------------------------------------------------------------*/

int DFCrle(buf,bufto,len)
int32 len;
char *buf,*bufto;
{
    register char *p,*q,*cfoll,*clead;
    char *begp;
    int32 i;

    p = buf;
    cfoll = bufto;		/* place to copy to */
    clead = cfoll + 1;
    
    begp = p;
    while (len > 0) {           /* encode stuff until gone */

        q = p + 1;
        i = len-1;
        while (i && i+120 > len && *p == *q) {
            q++;
            i--;
        }
        
        if (q > p + 2) {        /* three in a row */
            if (p > begp) {
                *cfoll = p - begp;
                cfoll = clead;
            }
            *cfoll++ = 128 | (q-p); /* len of seq */
            *cfoll++ = *p;      /* char of seq */
            len -= q-p;         /* subtract len of seq */
            p = q;
            clead = cfoll+1;
            begp = p;
        }
        else {
            *clead++ = *p++;    /* copy one char */
            len--;
            if (p > begp + 120) {
                *cfoll = p - begp;
                cfoll = clead++;
                begp = p;
            }
        }
        
    }
/*
 *  fill in last bytecount
 */
    if (p > begp) 
        *cfoll = (p - begp);
    else
        clead--;                    /* don't need count position */
    
    return((int)(clead - bufto));   /* how many stored as encoded */
}

/*-----------------------------------------------------------------------------
 * Name:    DFCunrle
 * Purpose: decompress run length encoding
 * Inputs:  buf: buffer containing compressed data
 *          bufto: space for returning decompressed data
 *          outlen: number of *decompressed* bytes desired.
 *          resetsave: don't use any stored state info - used for fresh image
 * Returns: number of compressed bytes used up on success, -1 on failure
 * Users:   HDF programmers, DFgetcomp, other routines
 * Invokes: none
 * Remarks: has been modified so it will decompress even non-rowwise compression
 *          Hence the static storage stuff
 *---------------------------------------------------------------------------*/

int DFCunrle(buf,bufto,outlen, resetsave)
int32 outlen;
char *buf,*bufto;
int resetsave;
{
    register int cnt;
    register char *p,*q;
    char *endp;
    static char save[255], *savestart=NULL, *saveend=NULL;
    /* save has a list of decompressed bytes not returned in
       previous call.  savestart and saveend specify the position
       at which this list starts and ends in the array save */
    
    p = buf;
    endp = bufto + outlen;
    q = bufto;
    if (resetsave) savestart = saveend = save; /* forget saved state */
    while ((saveend>savestart) && (q<endp)) /* copy saved stuff */
        *q++ = *savestart++;
    if (savestart>=saveend) savestart = saveend = save;	/* all copied */
    while (q < endp) {
        cnt = *p++;		/* count field */
        if (!(cnt & 128)) {	/* is set of uniques */
            while (cnt--) {
                if (q<endp)
                    *q++ = *p++; /* copy unmodified */
                else
                    *saveend++ = *p++;
            }
        }
        else {
            cnt &= 127;		/* strip high bit */
            while (cnt--) {
                if (q<endp)
                    *q++ = *p;  /* copy unmodified */
                else
                    *saveend++ = *p;
            }
            p++;                /* skip that character */
        }
    }
    return((int)(p-buf));
}
