/*****************************************************************************
*
*                   Data Transfer Mechanism (DTM) v. 2.3
*                           May 1, 1992
*
* UNIVERSITY OF ILLINOIS (UI), NATIONAL CENTER FOR SUPERCOMPUTING
* APPLICATIONS (NCSA), Software Distribution Policy for Public Domain
* Software
* 
* The NCSA software Data Transfer Mechanism [both binary and source (if
* released)] is in the public domain, available without fee for education,
* research, non-commercial and commercial purposes.  Users may distribute the
* binary or source code to third parties provided that this statement
* appears on all copies and that no charge is made for such copies.
* 
* UI MAKES NO REPRESENTATIONS ABOUT THE SUITABILITY OF THE SOFTWARE FOR ANY
* PURPOSE.  IT IS PROVIDED "AS IS" WITHOUT EXPRESS OR IMPLIED WARRANTY.  THE
* UI SHALL NOT BE LIABLE FOR ANY DAMAGES SUFFERED BY THE USER OF THIS
* SOFTWARE.  The software may have been developed under agreements between
* the UI and the Federal Government which entitle the Government to certain
* rights.
* 
* By copying this program, you, the user, agree to abide by the conditions
* and understandings with respect to any software which is marked with a
* public domain notice.
*
*****************************************************************************/


#define	MDDclass		"MDD"
#define MDDsize			256

#define PALclass		"PAL"
#define PALsize			64

/* MDD specific tags */
#define	MDDdims			"DIM"
#define MDDminmax		"MM"


/* MDD & PAL specific macros */
#define MDDsetClass(h)			DTMsetClass(h, MDDclass)
#define MDDcompareClass(h)		DTMcompareClass(h, MDDclass)

#define PALsetClass(h)			DTMsetClass(h, PALclass)
#define PALcompareClass(h)		DTMcompareClass(h, PALclass)

#define MDDsetPalette(h, t)		dtm_set_char(h, PALclass, t)
#define MDDgetPalette(h, t, l)		dtm_get_char(h, PALclass, t, l)

/* MDD & PAL rename macros */
#define MDDheaderLength			DTMheaderLength
#define	MDDHL				DTMheaderLength

#define PALheaderLength			DTMheaderLength
#define PALHL				DTMheaderLength

#define MDDsetTitle			DTMsetTitle
#define MDDgetTitle			DTMgetTitle

#define PALsetTitle			DTMsetTitle
#define PALgetTitle			DTMgetTitle

#define MDDsetType			DTMsetType
#define	MDDgetType			DTMgetType


/* MDD routines */
#ifdef __cplusplus
extern "C" {
#endif

extern void MDDsetDimensions PROTO((char *h, int rank, int *dims));
extern int  MDDgetDimensions PROTO((char *h, int *rank, int *dims, int len));
extern int  MDDnumElements PROTO((int rank, int *dims));
extern void MDDsetMinMax PROTO((char *h, double min, double max));
extern int  MDDgetMinMax PROTO((char *h, float *min, float *max));
extern void MDDfindMinMax PROTO((char *h, float *mdd, float *min, float *max));

#ifdef __cplusplus
};
#endif
