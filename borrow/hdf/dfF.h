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

C
C $Header$
C

C *----------------------------------------------------------------------------
C * File:   dfF.h
C * Purpose:    Fortran header file for HDF routines
C * Contents: 
C * Tag definitions
C * Error return codes
C * Logical constants
C * Remarks: This file can be included with user programs
C *---------------------------------------------------------------------------*


#ifndef DFTAG_NULL


#define DFREF_WILDCARD 0

#define DFTAG_WILDCARD 0
#define DFTAG_NULL  1

#define DFTAG_FID   100
#define DFTAG_FD    101
#define DFTAG_TID   102
#define DFTAG_TD    103
#define DFTAG_DIL   104
#define DFTAG_DIA   105
#define DFTAG_NT    106
#define DFTAG_MT    107

#define DFTAG_ID8   200
#define DFTAG_IP8   201
#define DFTAG_RI8   202
#define DFTAG_CI8   203
#define DFTAG_II8   204

#define DFTAG_ID    300
#define DFTAG_LUT   301
#define DFTAG_RI    302
#define DFTAG_CI    303

#define DFTAG_RIG   306
#define DFTAG_LD    307
#define DFTAG_MD    308
#define DFTAG_MA    309
#define DFTAG_CCN   310
#define DFTAG_CFM   311
#define DFTAG_AR    312
    
#define DFTAG_DRAW  400
#define DFTAG_RUN   401

#define DFTAG_XYP   500
#define DFTAG_MTO   501

#define DFTAG_T14   602
#define DFTAG_T105  603

#define DFTAG_RLE   11
#define DFTAG_IMCOMP 12

C                           Error Return Codes 

#define DFE_NOERROR     0
#define DFE_FNF         -1
#define DFE_DENIED      -2
#define DFE_ALROPEN     -3
#define DFE_TOOMANY     -4
#define DFE_BADNAME     -5
#define DFE_BADACC      -6 
#define DFE_NOTOPEN     -8  
#define DFE_CANTCLOSE   -9  
#define DFE_DFNULL      -10 
#define DFE_ILLTYPE     -11 
#define DFE_UNSUPPORTED -12
#define DFE_BADDDLIST   -13
#define DFE_NOTDFFILE   -14
#define DFE_SEEDTWICE   -15
#define DFE_NOSPACE     -16
#define DFE_READERROR   -18
#define DFE_WRITEERROR  -19
#define DFE_SEEKERROR   -20
#define DFE_NOFREEDD    -21
#define DFE_BADTAG      -22
#define DFE_BADREF      -23
#define DFE_RDONLY      -24
#define DFE_BADCALL     -25
#define DFE_BADPTR      -26
#define DFE_BADLEN      -27
#define DFE_BADSEEK     -28
#define DFE_NOMATCH     -29
#define DFE_NOTINSET    -30
#define DFE_BADDIM      -31
#define DFE_BADOFFSET   -32
#define DFE_BADSCHEME   -33
#define DFE_NODIM       -34
#define DFE_NOTENOUGH   -35

C                           Logical Constants

#define DFACC_READ      1
#define DFACC_WRITE     2
#define DFACC_CREATE    4
#define DFACC_ALL       7

#endif /*DFTAG_NULL*/
