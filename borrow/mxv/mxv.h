/*
 *	File:		mxv.h
 *	Contents:	Global include file for all modules of mxv
 *
 */

#ifndef _MXV_H
#define	_MXV_H
#include "df.h"
#include <X11/Xlib.h>
#include <X11/Xresource.h>	/* Need Quark definition. */

#define	STRNG20			20
#ifndef MAXNAMLEN
/* Maximum length of a filename.
*/
#define	MAXNAMELEN	256
#else
#define	MAXNAMELEN	(MAXNAMLEN+1)
#endif
/* Max length of a directory path + null. This may not be the correct
size on a particular system, but MAXNAMELEN and MAXPATHLEN are for
sizing character arrays, not system structures.
*/
#ifndef MAXPATHLEN
#define	MAXPATHLEN	1024
#endif

/*
One of MXV's early problems was writing past the end of a string array.
Care should be taken in choosing string lengths that it won't happen again.
*/
#define STRNG80			80
#define	STRNG160		160
#define STRNG256		256
#define	RESERVED_COLORS	2
#define	PI				(double)3.141592654

#define MXV_GREATER(A,B)	((A) > (B) ? (A) : (B))
#define MXV_SMALLER(A,B)	((A) < (B) ? (A) : (B))

/*
 * Data to pixel conversion macros
 * Note that I reserve the 1st 2 and the last 2 color entries in the color
 * map for black and white values.
 */
#define	MXV_CNV2SPLIT(A,B,C,D,E,F)	\
	( (A <= B) ? (unsigned char) RESERVED_COLORS+D : \
	 ((A >= C) ? (unsigned char) RESERVED_COLORS+E+F : \
				 (unsigned char)(RESERVED_COLORS+F+(A-B)*D)) )

typedef struct A_Coord_t {
    int x,y,z;
} A_Coord_t;

typedef struct A_VRect_t {
	int red,green,blue;
    double  intensity;
    double  opacity;
} A_VRect_t;

typedef enum { UNKNOWN, HDF, MIRIAD, FITS } A_FileFormat_t;

/* Structure to hold 'cvalues' read from a FITS or MIRIAD file.
Rather than store the character string for ctype, its stored in the label
part of A_data_t structs anyway, ctypes are stored as Quarks. This allows
easy checking against specific values. (RA--SIN for instance).

crval, crpix and cdelt are just the values out of the FITS or MIRIAD header.
*/
typedef XrmQuark	Quark;

typedef struct {
	Quark ctype;
	float	crval, crpix,
		cdelt;
	} cvalues, *Cvalues;

/* Data Structure */
typedef struct {
	A_FileFormat_t	format;
	int		rank;
	int		scale;
	int		numSDs;
	int32	dims[3];
	float32	min,max,range,rangeFrac,rangeFracSplit;
	float32	***data,*scaleStr[3];
	char	dataName[STRNG80];
	char	dataUnit[MAXNAMELEN];
	char	dataFmt[MAXNAMELEN];
	char	label[3][MAXNAMELEN];
	char	units[3][MAXNAMELEN];
	char	fmt[3][MAXNAMELEN];
	char	pathName[STRNG160];
	cvalues	cvals[3];	/* Only support 3D datasets. */
} A_Data_t;

/* Global variables. */
char	*axesLabels[3];
char	msg[256];
/* Special 'ctypes' we know about since types with these values may require 
special treatment.
*/
XrmQuark	RA___SIN, DEC__SIN, VELO_LSR;

/* What we call the conversion routines. */
#define StringToQuark(s)        XrmStringToQuark(s)
#define QuarkToString(i)        XrmQuarkToString(i)

#ifndef __convex__
extern char *malloc(), calloc();
#endif
#endif /* ifndef _MXV_H */
