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
Revision 1.1.1.1  1990/09/28 21:49:51  teuben
UIUC 15-feb-2001 w/out wip and some manuals

 * Revision 3.3  90/07/02  09:40:04  clow
 * enclosed DFconvert macro and function with an #ifdef on FUNC_CONV
 * so that the selection between these is a compilation option
 * 
 * Revision 3.2  90/06/21  10:39:13  clow
 * Expanded DFconvert macro so that it is as complete as the function
 * 
 * Revision 3.1  90/05/21  08:59:15  clow
 * if it's unicos, use the fortran optimized convertsion routines
 * added macros to do above
 * 
 * Revision 3.0  90/02/19  15:22:17  pwebb
 * Macro to replace function call
 * 
*/
/* In order to speed the conversion process, eliminate a layer of function
 * calls by making DFconvert into a macro.
 * Peter Webb, Oct 11, 1989
 */
#ifndef DFCONVERT_H
#define DFCONVERT_H
#ifndef FUNC_CONV
/* This is the default */
/* using the DFconvert macro instead of function */
#define DFconvert(src,dest,ntype,stype,dtype,size,status)\
{ char *s=(src), *d=(dest);\
  int nt=(ntype), st=(stype), dt=(dtype);\
  int sz=(size);\
  if (nt==DFNT_FLOAT) {\
    if ((st==DFNTF_IEEE && dt==DFNTF_PC) ||\
        (st==DFNTF_PC && dt==DFNTF_IEEE)) {\
      register int i;\
      for (i=0;i<sz*4;i+=4) {\
        d[i] = s[i+3];\
        d[i+1] = s[i+2];\
        d[i+2] = s[i+1];\
        d[i+3] = s[i];\
      }\
      status=0;\
    } else {\
      if (st==DFNTF_PC) {\
        register int i;\
        register char t;\
        for (i=0;i<sz*4;i+=4) {\
          t = s[i];\
          s[i] = s[i+3];\
          s[i+3] = t;\
          t = s[i+1];\
          s[i+1] = s[i+2];\
          s[i+2] = t;\
        }\
        st=DFNTF_IEEE;\
      }\
      if (st==DFNTF_IEEE && dt==DFNTF_CRAY) {\
        SCUP32(s,d,&sz,&(status));\
      } else if (st==DFNTF_CRAY && (dt==DFNTF_IEEE || dt==DFNTF_PC)) {\
        CSPK32(s,d,&sz,&(status));\
      } else if (st==DFNTF_IEEE && dt==DFNTF_VAX) {\
        status = DFCVieeeF2vaxF(s,d,sz);\
      } else if (st==DFNTF_VAX && (dt==DFNTF_IEEE || dt==DFNTF_PC)) {\
        status = DFCVvaxF2ieeeF(s,d,sz);\
      } else {\
        status = -1;\
      }\
      if (dt==DFNTF_PC) {\
        register int i;\
        register char t;\
        for (i=0;i<sz*4;i+=4) {\
          t = d[i];\
          d[i] = d[i+3];\
          d[i+3] = t;\
          t = d[i+1];\
          d[i+1] = d[i+2];\
          d[i+2] = t;\
        }\
      }\
      if ((stype)==DFNTF_PC) {\
        register int i;\
        register char t;\
        for (i=0;i<sz*4;i+=4) {\
          t = s[i];\
          s[i] = s[i+3];\
          s[i+3] = t;\
          t = s[i+1];\
          s[i+1] = s[i+2];\
          s[i+2] = t;\
        }\
        st=DFNTF_IEEE;\
      }\
    }\
  } else {\
  status = -1;\
  }\
  if (status == -1) DFerror = DFE_BADCONV;\
}
#endif /* !FUNC_CONV */

#endif /* !DFCONVERT_H */
