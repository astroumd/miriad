C*****************************************************************************
C 
C			  NCSA HDF version 3.10r2
C				Sept 20, 1990
C
C NCSA HDF Version 3.10r2 source code and documentation are in the public
C domain.  Specifically, we give to the public domain all rights for future
C licensing of the source code, all resale rights, and all publishing rights.
C 
C We ask, but do not require, that the following message be included in all
C derived works:
C 
C Portions developed at the National Center for Supercomputing Applications at
C the University of Illinois at Urbana-Champaign.
C 
C THE UNIVERSITY OF ILLINOIS GIVES NO WARRANTY, EXPRESSED OR IMPLIED, FOR THE
C SOFTWARE AND/OR DOCUMENTATION PROVIDED, INCLUDING, WITHOUT LIMITATION,
C WARRANTY OF MERCHANTABILITY AND WARRANTY OF FITNESS FOR A PARTICULAR PURPOSE
C 
C*****************************************************************************

C
C $Header$
C
C $Log$
C Revision 1.1  1990/09/28 21:49:42  teuben
C Initial revision
C
c Revision 1.1  90/07/02  17:01:48  clow
c Initial revision
c 
C
C *-----------------------------------------------------------------------------
C * File: 	dfF.h
C * Purpose:	Fortran header file for HDF routines
C * Contents: 
C *     Tag definitions
C *     Error return codes
C *    	Logical constants
C * Remarks: This file can be included with user programs
C *----------------------------------------------------------------------------*


C 				Miscellaneous constants

      parameter (DFREF_WILDCARD = 0,
     *           DFTAG_WILDCARD = 0,
     *           DFTAG_NULL     = 1)


C 				HDF tags

      parameter (DFTAG_FID	 = 100,
     *           DFTAG_FD	 = 101,
     *           DFTAG_TID	 = 102,
     *           DFTAG_TD	 = 103,
     *           DFTAG_DIL	 = 104,
     *           DFTAG_DIA	 = 105,
     *           DFTAG_NT	 = 106,
     *           DFTAG_MT	 = 107,
     *
     *           DFTAG_ID8	 = 200,
     *           DFTAG_IP8	 = 201,
     *           DFTAG_RI8	 = 202,
     *           DFTAG_CI8	 = 203,
     *           DFTAG_II8	 = 204)
     *
      parameter (DFTAG_ID	 = 300,
     *           DFTAG_LUT	 = 301,
     *           DFTAG_RI	 = 302,
     *           DFTAG_CI	 = 303,
     *
     *           DFTAG_RIG	 = 306,
     *           DFTAG_LD	 = 307,
     *           DFTAG_MD	 = 308,
     *           DFTAG_MA	 = 309,
     *           DFTAG_CCN	 = 310,
     *           DFTAG_CFM	 = 311,
     *           DFTAG_AR	 = 312)

      parameter (DFTAG_DRAW	 = 400,
     *           DFTAG_RUN	 = 401,
     * 
     *           DFTAG_XYP	 = 500,
     *           DFTAG_MTO	 = 501,
     * 
     *           DFTAG_T14	 = 602,
     *           DFTAG_T105	 = 603)

      parameter (DFTAG_RLE	 = 11,
     *           DFTAG_IMCOMP = 12)


C 					Error Return Codes 

      parameter (DFE_NOERROR     	 =   0,
     *           DFE_FNF         	 =  -1,
     *           DFE_DENIED      	 =  -2,
     *           DFE_ALROPEN     	 =  -3,
     *           DFE_TOOMANY     	 =  -4,
     *           DFE_BADNAME     	 =  -5,
     *           DFE_BADACC      	 =  -6 ,
     *           DFE_NOTOPEN     	 =  -8,
     *           DFE_CANTCLOSE   	 =  -9,
     *           DFE_DFNULL        	 = -10,
     *           DFE_ILLTYPE     	 = -11,
     *           DFE_UNSUPPORTED 	 = -12,
     *           DFE_BADDDLIST   	 = -13,
     *           DFE_NOTDFFILE   	 = -14,
     *           DFE_SEEDTWICE   	 = -15,
     *           DFE_NOSPACE     	 = -16,
     *           DFE_READERROR   	 = -18,
     *           DFE_WRITEERROR  	 = -19)

      parameter (DFE_SEEKERROR   	 = -20,
     *           DFE_NOFREEDD    	 = -21,
     *           DFE_BADTAG      	 = -22,
     *           DFE_BADREF      	 = -23,
     *           DFE_RDONLY      	 = -24,
     *           DFE_BADCALL     	 = -25,
     *           DFE_BADPTR      	 = -26,
     *           DFE_BADLEN      	 = -27,
     *           DFE_BADSEEK     	 = -28,
     *           DFE_NOMATCH     	 = -29,
     *           DFE_NOTINSET    	 = -30,
     *           DFE_BADDIM      	 = -31,
     *           DFE_BADOFFSET   	 = -32,
     *           DFE_BADSCHEME   	 = -33,
     *           DFE_NODIM       	 = -34,
     *           DFE_NOTENOUGH   	 = -35)

C					Logical Constants

      parameter (DFACC_READ       	 = 1,
     *           DFACC_WRITE      	 = 2,
     *           DFACC_CREATE     	 = 4,
     *           DFACC_ALL        	 = 7)



