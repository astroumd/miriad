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

/*
$Header$

$Log$
Revision 1.1.1.1  1990/09/28 21:50:01  teuben
UIUC 15-feb-2001 w/out wip and some manuals

 * Revision 3.1  90/07/02  10:11:54  clow
 * some cosmetic modifications
 * 
*/

/*-----------------------------------------------------------------------------
 * File:    dfrig.h
 * Purpose: header file for the Raster Image set
 * Invokes: df.h
 * Contents: 
 *  Structure definitions: DFRdr, DFRrig
 * Remarks: This is included with user programs which use RIG
 *---------------------------------------------------------------------------*/


#ifndef DFRIG			/* avoid re-inclusion */
#define DFRIG

#include "df.h"

/* description record: used to describe image data, palette data etc. */
typedef struct {
    int32 xdim, ydim;		/* dimensions of data */
    DFdi nt;			/* number type of data */
    int16 ncomponents, interlace; /* data ordering: chunky / planar etc */
    DFdi compr;			/* compression */
    /* ### Note: compression is currently uniquely described with a tag.
       No data is attached to this tag/ref.  But this capability is
       provided for future expansion, when this tag/ref might point to
       some data needed for decompression, such as the actual encodings */
} DFRdr;

/* structure to hold RIG info */
typedef struct {
    DFdi image;			/* image */
    DFRdr descimage;		/* image data description */
    DFdi lut;			/* color look-up table (palette) */
    DFRdr desclut;		/* look-up table description */
    DFdi mattechannel;
    DFRdr descmattechannel;
    int32 xpos, ypos;		/* X-Y position of image on screen */
    float aspectratio;		/* ratio of pixel height to width */
    float ccngamma, ccnred[3], ccngrren[3], ccnblue[3], ccnwhite[3];
				/* color correction parameters */
    char *cf;			/* color format */
} DFRrig;

#endif /*DFRIG*/
