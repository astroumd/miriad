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
Revision 1.1  1990/09/28 21:49:48  teuben
Initial revision

 * Revision 3.0  90/02/02  20:30:34  clow
 * *** empty log message ***
 * 
*/
/*------------------------------------------------------------------------------
 * File:    dfan.h
 * Purpose: header file for the Annotations set
 * Invokes: df.h
 * Contents: 
 *  Structure definitions: DFANdirentry, DFANdirhead
 *  Constant definitions: DFAN_LABEL, DFAN_DESC
 * Remarks: none
 *----------------------------------------------------------------------------*/


#ifndef DFAN                        /* avoid re-inclusion */
#define DFAN

#include "df.h"

#define DFAN_LABEL  0
#define DFAN_DESC   1

#define DFAN_DEFENTRIES 16          /* no of dir entries to add at a time */

    /* This structure stores an entry in the label/desc directory */
    /* for a label/desc in the file, it gives the ref of the label/desc,
        and the tag/ref of the data item to which the label/desc relates */

typedef struct {
        uint16 annref;                  /* ref of annotation */
        uint16 datatag, dataref;        /* tag/ref of data */
    } DFANdirentry;

    /* This structure is a head node for the directory, which is organized as
        as a linked list of arrays.  DFANdirentry is the structure of an
        array element, while DFANdirhead is the list element */
typedef struct DFANdirhead {
        int nentries;
        struct DFANdirhead *next;
        DFANdirentry entries[1];        /* actually an arbitrary size array */
    } DFANdirhead;

#ifndef VMS
int32 DFANIgetannlen();
#else
int32 _DFANIgetannlen();
#endif

#endif /*DFAN*/
