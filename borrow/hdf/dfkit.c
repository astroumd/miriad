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
static char RcsId[] = "@(#)$Revision$"
#endif
/*
$Header$
$Log$
Revision 1.1.1.1  1990/09/28 21:49:57  teuben
UIUC 15-feb-2001 w/out wip and some manuals

 * Revision 3.11  90/08/30  14:23:31  clow
 * replace DFCV ieee <-> unicos routine calls with calls to CSPK32 and SCUP32
 * 
 * Revision 3.10  90/07/02  09:37:52  clow
 * enclosed DFconvert macro and function with an #ifdef on FUNC_CONV
 * so that the selection between these is a compilation option
 * 
 * Revision 3.9  90/06/21  10:40:53  clow
 * Changes UNICOS conversion functions for non-UNICOS env to be similar
 * to the UNICOS fortran functions, and
 * "#if 0" out the DFconvert function, use macro in dfconvert.h
 * 
 * Revision 3.8  90/06/07  17:39:28  clow
 * bug fix in conversion routines
 * 
*/
/*
 * Changes:
 *	DFconvert() calls FORTRAN conversion routines if compiled with UNICOS 
 *	DFconvert() takes an array rather than a single number
 *	Register parameters have been declared
 *	Pointers are now used rather than array indexing
 */
/* Modified DFconvert so that it takes an array rather than a single number */
/* Now call FORTRAN conversion routines */
#include <ctype.h>
#include "df.h"

union fpx
{
     float f;
     long  l;
};

union float_uint_uchar {
    float32 f;
    int32 i;
    unsigned char c[4];
};

char *DFIstrncpy(dest, source, len)
register char *source, *dest;
int len;
{

    for(; (--len > 0) && (*dest++ = *source++););
    if (!len) *dest = '\0';
	return(dest);
}

#ifdef FUNC_CONV
/* function convert, otherwise, this function is done in macro (dfconvert.h) */
int DFconvert(source, dest, ntype, sourcetype, desttype, size)
char *source, *dest;
int ntype;
register int sourcetype, desttype;
int size;
{
    register char t;      /* Temporary, used in byte-swapping */
    register int i;
	int status;

    if (ntype==DFNT_FLOAT) {

	if (((sourcetype==DFNTF_IEEE) && ( desttype==DFNTF_PC)) ||
	    ((sourcetype==DFNTF_PC) && (desttype==DFNTF_IEEE))) {
            for (i=0; i<size*4; i+=4)
              {
	        dest[i  ] = source[i+3];
	        dest[i+1] = source[i+2];
	        dest[i+2] = source[i+1];
	        dest[i+3] = source[i  ];
              }
	    return(0);
	}

	/* if reversed IEEE, reverse before conversion */
	if (sourcetype==DFNTF_PC) {
	  sourcetype=DFNTF_IEEE;
          for (i=0; i<size*4; i+=4)
            {
	      t           = source[i];
	      source[i  ] = source[i+3];
              source[i+3] = t;
	      t           = source[i+1];
	      source[i+1] = source[i+2];
              source[i+2] = t;
            }
	}

        if ((sourcetype==DFNTF_IEEE) && (desttype==DFNTF_CRAY)) {
#ifdef UNICOS
            SCUP32(source, dest, &size, &status);
#else
            if (SCUP32(source,(union fpx*) dest, size)<0)
               return(-1);
#endif
        } else if ((sourcetype==DFNTF_CRAY) &&
		   ((desttype==DFNTF_IEEE) || (desttype==DFNTF_PC))) {
#ifdef UNICOS
            CSPK32(source, dest, &size, &status);
#else
            if (CSPK32((union fpx*)source, dest, size)<0) 
               return(-1);
#endif
	}

        if ((sourcetype==DFNTF_IEEE) && (desttype==DFNTF_VAX)) {
            if (DFCVieeeF2vaxF((union float_uint_uchar *) source,
			       (union float_uint_uchar *) dest, size)<0)
		return(-1);
        } else if ((sourcetype==DFNTF_VAX) &&
		   ((desttype==DFNTF_IEEE) || (desttype==DFNTF_PC))) {
            if (DFCVvaxF2ieeeF((union float_uint_uchar*) source,
			       (union float_uint_uchar*) dest, size)<0)
		return(-1);
        }

	/* if reversed IEEE, reverse result */
	if (desttype==DFNTF_PC) {
          for (i=0; i<size*4; i+=4)
            {
	      t         = dest[i+3];
	      dest[i+3] = dest[i];
	      dest[i  ] = t;
	      t         = dest[i+2];
	      dest[i+2] = dest[i+1];
	      dest[i+1] = t;
            }
	}
	return(0);
    }
        /* default */
    DFerror = DFE_BADCONV;
    return(-1);
}
#endif /* FUNC_CONV */

char *DFIgetspace(qty)
unsigned qty;
{
    char *p;

    p = malloc(qty);
    if (p==NULL) {
        DFerror = DFE_NOSPACE;
        return(NULL);
    }
    return(p);
}

char *DFIfreespace(ptr)
char *ptr;
{
    if (ptr!=NULL) free(ptr);
    return(NULL);
}


#ifdef UNICOS

#define MINEXP    0x3f81000000000000  /* min valid Cray masked exponent */
#define MAXEXP    0x407e000000000000  /* max valid Cray masked exponent */

#define C_FMASK   0x00007fffff000000  /* Cray fraction mask (1st 23 bits)*/
#define C_EMASK   0x7fff000000000000  /* Cray exponent mask */
#define C_SMASK   0x8000000000000000  /* Cray sign mask */
#define C_IMPLICIT 0x0000800000000000 /* Cray implicit bit */

#define I_FMASK   0x007fffff          /* IEEE fraction mask */
#define I_EMASK   0x7f800000          /* IEEE exponent mask */
#define I_SMASK   0x80000000          /* IEEE sign mask     */

#define IEEE_BIAS 0177
#define CRAY_BIAS 040000

#endif /*UNICOS*/

/* On UNICOS, this function is defined as a fortran function */
#ifndef UNICOS
    /*  convert from Cray2 floating point format to IEEE format */
/* shut lint up */
/* ARGSUSED */
CSPK32(cray_fp, ieee_fp, size, status)
char *cray_fp;
char *ieee_fp;
int *size;
int *status;
{
    DFerror = DFE_BADCONV;
    *status = -1;
}
#endif /*!UNICOS*/

#if 0
/* Old cray conversion routine */
    register int i;
    register long C2I_diff;
    long tmp;
    C2I_diff = (IEEE_BIAS - CRAY_BIAS - 1) << 48;
    for (i=0; i<size; i++, cray_fp++, ieee_fp+=4)
      {
        if (cray_fp->l == 0)
          tmp = 0;
        else {
          tmp = (C_EMASK & cray_fp->l);
          if (tmp < MINEXP || tmp > MAXEXP) {
              DFerror = DFE_BADFP;
              return(-1);
          }

          tmp = ((tmp + C2I_diff) << 7)
            | ( (cray_fp->l & C_FMASK) << 8 )
            | ( (cray_fp->l & C_SMASK));
        }
		DFmovmem((char *)&tmp, ieee_fp, 4);
      }
    return(0);
}
#endif /* 0 */

/* On UNICOS, this function is defined as a fortran function */
#ifndef UNICOS
/* Conversion from IEEE floating point format to Cray format */
/* shut lint up */
/* ARGSUSED */
SCUP32(ieee_fp, cray_fp, size, status)
char *cray_fp;
char *ieee_fp;
int *size;
int *status;
{
    DFerror = DFE_BADCONV;
    *status = -1;
}
#endif /*!UNICOS*/

#if 0
register union fpx *cray_fp;
register char *ieee_fp;
int size;
{
    long tmp;
    register int i;
    register long I2C_diff;

    I2C_diff = (CRAY_BIAS - IEEE_BIAS + 1) << 23;
    for (i=0; i<size; i++, ieee_fp+=4, cray_fp++)
      {
        tmp = 0;
        DFmovmem(ieee_fp, ((char *) &tmp) + 4, 4); 

        if ( (cray_fp->l = tmp & I_EMASK) == 0) {
          cray_fp->l = 0;
          continue;
        }

        cray_fp->l += I2C_diff;
        cray_fp->l = (cray_fp->l<< 25)
           | ( (tmp & I_FMASK) << 24)
           | ( (tmp & I_SMASK) << 32)
	   | C_IMPLICIT;
      }
    return (0);

}
#endif /* 0 */

DFIc2fstr(str, len)
char* str;
int len;
{
    int i;

    for(i=0; (str[i]); i++);
    for(; i<len; i++) str[i] = ' ';
}

char *DFIf2cstring(fdesc, len)
    _fcd fdesc;
    int len;
{
    char *cstr, *str;
    int i;

    str = _fcdtocp(fdesc);
    for(i=len-1;i>=0 && (!isascii(str[i]) || !isgraph(str[i])); i--)
	/*EMPTY*/;
    cstr = DFIgetspace(i+2);
    cstr[i+1] = '\0';
    for (; i>=0; i--) cstr[i] = str[i];
    return cstr;
}

int DFCVvaxF2ieeeF(in, out, size)
union float_uint_uchar in[], out[];
int size;
{
    register unsigned char exp;
    int i;

    for (i=0; i<size; i++)
      {
        exp = (in[i].c[1] << 1) | (in[i].c[0] >> 7);  /* extract exponent */
        if (!exp && !in[i].c[1]) out[i].i = 0;        /* zero value */
        else if (exp>2) {                               /* normal value */
            out[i].c[0] = in[i].c[1] - 1; /* subtracts 2 from exponent */
                /* copy mantissa, LSB of exponent */
            out[i].c[1] = in[i].c[0];
            out[i].c[2] = in[i].c[3];
            out[i].c[3] = in[i].c[2];
        }
        else if (exp) {                          /* denormalized number */
            register int shft;

            out[i].c[0] = in[i].c[1] & 0x80;   /* keep sign, zero exponent */
            shft = 3 - exp;
            /* shift original mant by 1 or 2 to get denormalized mant */
            /* prefix mantissa with '1'b or '01'b as appropriate */
            out[i].c[1] = ((in[i].c[0] & 0x7f) >> shft) | (0x10 << exp);
            out[i].c[2] = (in[i].c[0] << (8-shft)) | (in[i].c[3] >> shft);
            out[i].c[3] = (in[i].c[3] << (8-shft)) | (in[i].c[2] >> shft);
        }
        else {                                  /* sign=1 -> infinity or NaN */
            out[i].c[0] = 0xff;                /* set exp to 255 */
                /* copy mantissa */
            out[i].c[1] = in[i].c[0] | 0x80;  /* LSB of exp = 1 */
            out[i].c[2] = in[i].c[3];
            out[i].c[3] = in[i].c[2];
        }
      }
    return(0);
}


int DFCVieeeF2vaxF(in, out, size)
union float_uint_uchar in[], out[];
int size;
{
    register unsigned char exp;
    int i;

    for (i=0; i<size; i++)
      {
         exp = (in[i].c[0] << 1) | (in[i].c[1] >> 7); /* extract exponent */
         if (exp) {                                  /* non-zero exponent */
            /* copy mantissa, last bit of exponent */
           out[i].c[0] = in[i].c[1];
           out[i].c[2] = in[i].c[3];
           out[i].c[3] = in[i].c[2];
           if (exp<254)                        /* normal value */
             out[i].c[1] = in[i].c[0] + 1;   /* actually adds two to exp */
           else {                              /* infinity or NaN */
             if (exp==254)                     /* unrepresentable - OFL */
               out[i].i = 0;                  /* set mant=0 for overflow */
            out[i].c[0] &= 0x7f;              /* set last bit of exp to 0 */
            out[i].c[1] = 0x80;               /* sign=1 exp=0 -> OFL or NaN */
          }
        }
        else if (in[i].c[1] & 0x60) {               /* denormalized value */
          register int shft;
    
          shft = (in[i].c[1] & 0x40) ? 1 : 2;  /* shift needed to normalize */
            /* shift mantissa */
            /* note last bit of exp set to 1 implicitly */
          out[i].c[0] = (in[i].c[1] << shft) & (in[i].c[2] >> (8-shft));
          out[i].c[3] = (in[i].c[2] << shft) & (in[i].c[3] >> (8-shft));
          out[i].c[2] = in[i].c[3] << shft;
          out[i].c[1] = (in[i].c[0] & 0x80);          /* sign */
          if (shft==1) {                          /* set exp to 2 */
            out[i].c[1] |= 0x01;
            out[i].c[0] &= 0x7f;                  /* set LSB of exp to 0 */
          }
        }
        else out[i].i = 0;                            /* zero */
      }
    return(0);
}
